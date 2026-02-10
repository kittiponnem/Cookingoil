import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model_enhanced.dart';

/// Authentication gate service for role-based access control
class AuthGateService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check authentication status and route accordingly
  Future<AuthGateResult> checkAuthStatus() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;

      // A) No authenticated user -> Auth Landing
      if (firebaseUser == null) {
        return AuthGateResult(
          status: AuthStatus.unauthenticated,
          route: '/auth/landing',
        );
      }

      // B) Fetch user document from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      // User document doesn't exist
      if (!userDoc.exists) {
        // Check if this is a new customer sign-up
        final isNewCustomerSignup = await _isNewCustomerSignup(firebaseUser);
        
        if (isNewCustomerSignup) {
          // Create user document with active customer role
          await _createCustomerUser(firebaseUser);
          return AuthGateResult(
            status: AuthStatus.authenticated,
            route: '/customer/home',
            userRole: UserRole.customer,
          );
        } else {
          // Create inactive user document (requires admin approval)
          await _createInactiveUser(firebaseUser);
          return AuthGateResult(
            status: AuthStatus.pendingActivation,
            route: '/auth/access-pending',
          );
        }
      }

      // Parse user data
      final userData = UserModel.fromFirestore(userDoc.data()!, userDoc.id);

      // Check if user is active
      if (!userData.isActive) {
        return AuthGateResult(
          status: AuthStatus.pendingActivation,
          route: '/auth/access-pending',
          user: userData,
        );
      }

      // C) Route by role
      final route = _getHomeRouteForRole(userData.role);
      
      // Update last login timestamp
      await _updateLastLogin(firebaseUser.uid);

      return AuthGateResult(
        status: AuthStatus.authenticated,
        route: route,
        user: userData,
        userRole: userData.role,
      );

    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthGateService error: $e');
      }
      return AuthGateResult(
        status: AuthStatus.error,
        route: '/auth/landing',
        error: e.toString(),
      );
    }
  }

  /// Check if user has permission to access page
  Future<bool> canAccessPage(String pageName, UserModel? user) async {
    if (user == null) return false;
    if (!user.isActive) return false;

    // Admin has access to everything
    if (user.isAdmin) return true;

    // Page-level permission checks
    switch (pageName.toLowerCase()) {
      // Administration pages - admin only
      case 'administration':
      case 'admin':
      case 'config':
        return user.canAccessAdministration;

      // Finance pages - finance & admin
      case 'finance':
      case 'payments':
      case 'refunds':
      case 'accounting':
        return user.canAccessFinance;

      // Inventory pages - warehouse & admin
      case 'inventory':
      case 'warehouse':
      case 'stock':
        return user.canAccessInventory;

      // Dispatch pages - fleet & admin
      case 'dispatch':
      case 'fleet':
      case 'dispatch-board':
        return user.canAccessDispatch;

      // Sales order pages - ops, warehouse, fleet, finance, admin
      case 'sales-orders':
      case 'orders':
        return user.canManageSalesOrders;

      // UCO order pages - ops, warehouse, fleet, finance, driver, admin
      case 'uco-orders':
      case 'pickups':
        return user.canManageUCOOrders;

      // Audit logs - admin & finance (read)
      case 'audit-logs':
      case 'audit':
        return user.canViewAuditLogs;

      // Reports - finance, ops, admin
      case 'reports':
      case 'analytics':
        return user.canExportReports;

      // Customer pages - customers only
      case 'shop':
      case 'catalog':
      case 'cart':
      case 'checkout':
        return user.isCustomer;

      // Driver pages - drivers only
      case 'driver-route':
      case 'driver-stops':
      case 'todays-route':
        return user.isDriver;

      // Universal pages (everyone can access)
      case 'dashboard':
      case 'home':
      case 'profile':
      case 'notifications':
        return true;

      default:
        // Default: backoffice staff can access
        return user.isBackoffice;
    }
  }

  /// Check if driver has access to specific record
  bool driverCanAccessRecord(UserModel user, String? assignedDriverUid) {
    if (!user.isDriver) return false;
    if (user.isAdmin) return true;
    return user.uid == assignedDriverUid;
  }

  /// Get home route for role
  String _getHomeRouteForRole(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return '/customer/home';
      case UserRole.driver:
        return '/driver/home';
      case UserRole.admin:
      case UserRole.ops:
      case UserRole.warehouse:
      case UserRole.fleet:
      case UserRole.finance:
        return '/backoffice/dashboard';
    }
  }

  /// Check if this is a new customer sign-up
  Future<bool> _isNewCustomerSignup(firebase_auth.User firebaseUser) async {
    // Check if user signed up with email/password (customer flow)
    // vs. admin-created users (backoffice flow)
    
    // For now, assume email-verified users are customers
    return firebaseUser.emailVerified || firebaseUser.email != null;
  }

  /// Create customer user document
  Future<void> _createCustomerUser(firebase_auth.User firebaseUser) async {
    final userData = UserModel(
      uid: firebaseUser.uid,
      role: UserRole.customer,
      displayName: firebaseUser.displayName ?? 'Customer',
      phone: firebaseUser.phoneNumber ?? '',
      email: firebaseUser.email ?? '',
      isActive: true,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .set(userData.toFirestore());

    if (kDebugMode) {
      debugPrint('Created new customer user: ${firebaseUser.uid}');
    }
  }

  /// Create inactive user document (requires admin approval)
  Future<void> _createInactiveUser(firebase_auth.User firebaseUser) async {
    final userData = UserModel(
      uid: firebaseUser.uid,
      role: UserRole.customer,
      displayName: firebaseUser.displayName ?? 'Pending User',
      phone: firebaseUser.phoneNumber ?? '',
      email: firebaseUser.email ?? '',
      isActive: false,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .set(userData.toFirestore());

    if (kDebugMode) {
      debugPrint('Created inactive user: ${firebaseUser.uid}');
    }
  }

  /// Update last login timestamp
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to update lastLogin: $e');
      }
    }
  }
}

/// Authentication status
enum AuthStatus {
  authenticated,
  unauthenticated,
  pendingActivation,
  error,
}

/// Authentication gate result
class AuthGateResult {
  final AuthStatus status;
  final String route;
  final UserModel? user;
  final UserRole? userRole;
  final String? error;

  AuthGateResult({
    required this.status,
    required this.route,
    this.user,
    this.userRole,
    this.error,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get needsActivation => status == AuthStatus.pendingActivation;
  bool get hasError => status == AuthStatus.error;
}
