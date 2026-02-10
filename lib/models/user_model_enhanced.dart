import 'package:cloud_firestore/cloud_firestore.dart';

/// Enhanced RBAC with 7 roles for enterprise operations
enum UserRole {
  admin,        // Full system access
  ops,          // Operations management
  warehouse,    // Inventory & fulfillment
  fleet,        // Dispatch & logistics
  finance,      // Financial operations
  driver,       // Field operations
  customer,     // Customer portal
}

/// Optional read-only roles
enum ReadOnlyRole {
  auditor,
  viewer,
}

/// Enhanced user model with business unit scoping and granular permissions
class UserModel {
  final String uid;
  final UserRole role;
  final String displayName;
  final String phone;
  final String email;
  final bool isActive;
  
  // Customer-specific fields
  final String? customerId;  // Reference to customers collection
  
  // Business unit scoping (multi-tenant support)
  final String? businessUnitId;  // Primary business unit
  final List<String> allowedBusinessUnitIds;  // Multiple BU access
  
  // Legacy fields for backward compatibility
  final String? customerAccountId;
  final List<String> branchIds;
  
  // Metadata
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? createdByUid;
  final Map<String, dynamic>? metadata;

  UserModel({
    required this.uid,
    required this.role,
    required this.displayName,
    required this.phone,
    required this.email,
    required this.isActive,
    this.customerId,
    this.businessUnitId,
    List<String>? allowedBusinessUnitIds,
    this.customerAccountId,
    List<String>? branchIds,
    required this.createdAt,
    this.lastLoginAt,
    this.createdByUid,
    this.metadata,
  })  : allowedBusinessUnitIds = allowedBusinessUnitIds ?? [],
        branchIds = branchIds ?? [];

  /// Create from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return UserModel(
      uid: docId,
      role: _parseUserRole(data['role'] as String? ?? 'customer'),
      displayName: data['displayName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      customerId: data['customerId'] as String?,
      businessUnitId: data['businessUnitId'] as String?,
      allowedBusinessUnitIds: List<String>.from(data['allowedBusinessUnitIds'] as List? ?? []),
      customerAccountId: data['customerAccountId'] as String?,
      branchIds: List<String>.from(data['branchIds'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      createdByUid: data['createdByUid'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'role': _roleToString(role),
      'displayName': displayName,
      'phone': phone,
      'email': email,
      'isActive': isActive,
      'customerId': customerId,
      'businessUnitId': businessUnitId,
      'allowedBusinessUnitIds': allowedBusinessUnitIds,
      'customerAccountId': customerAccountId,
      'branchIds': branchIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'createdByUid': createdByUid,
      'metadata': metadata,
    };
  }

  /// Parse role from string
  static UserRole _parseUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'ops':
      case 'operations':
        return UserRole.ops;
      case 'warehouse':
      case 'inventory':
        return UserRole.warehouse;
      case 'fleet':
      case 'dispatch':
      case 'dispatcher':
        return UserRole.fleet;
      case 'finance':
      case 'accounting':
        return UserRole.finance;
      case 'driver':
        return UserRole.driver;
      case 'customer':
      case 'customer_b2c':
      case 'customer_b2b_user':
      case 'customer_b2b_admin':
        return UserRole.customer;
      default:
        return UserRole.customer;
    }
  }

  /// Convert role to string
  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.ops:
        return 'ops';
      case UserRole.warehouse:
        return 'warehouse';
      case UserRole.fleet:
        return 'fleet';
      case UserRole.finance:
        return 'finance';
      case UserRole.driver:
        return 'driver';
      case UserRole.customer:
        return 'customer';
    }
  }

  /// Role display name
  String get roleDisplayName {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.ops:
        return 'Operations';
      case UserRole.warehouse:
        return 'Warehouse';
      case UserRole.fleet:
        return 'Fleet Manager';
      case UserRole.finance:
        return 'Finance';
      case UserRole.driver:
        return 'Driver';
      case UserRole.customer:
        return 'Customer';
    }
  }

  // ============================================================
  // PERMISSION CHECKS
  // ============================================================

  /// Check if user is a customer
  bool get isCustomer => role == UserRole.customer;

  /// Check if user is a driver
  bool get isDriver => role == UserRole.driver;

  /// Check if user is backoffice staff
  bool get isBackoffice => !isCustomer && !isDriver;

  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if user can access administration
  bool get canAccessAdministration => role == UserRole.admin;

  /// Check if user can access finance
  bool get canAccessFinance => role == UserRole.finance || role == UserRole.admin;

  /// Check if user can access inventory
  bool get canAccessInventory => role == UserRole.warehouse || role == UserRole.admin;

  /// Check if user can access dispatch
  bool get canAccessDispatch => role == UserRole.fleet || role == UserRole.admin;

  /// Check if user can manage sales orders
  bool get canManageSalesOrders =>
      role == UserRole.ops ||
      role == UserRole.warehouse ||
      role == UserRole.fleet ||
      role == UserRole.finance ||
      role == UserRole.admin;

  /// Check if user can manage UCO orders
  bool get canManageUCOOrders =>
      role == UserRole.ops ||
      role == UserRole.warehouse ||
      role == UserRole.fleet ||
      role == UserRole.finance ||
      role == UserRole.driver ||
      role == UserRole.admin;

  /// Check if user can approve workflows
  bool get canApproveWorkflows =>
      role == UserRole.ops ||
      role == UserRole.finance ||
      role == UserRole.admin;

  /// Check if user can view audit logs
  bool get canViewAuditLogs =>
      role == UserRole.admin || role == UserRole.finance;

  /// Check if user can export reports
  bool get canExportReports =>
      role == UserRole.finance ||
      role == UserRole.ops ||
      role == UserRole.admin;

  // ============================================================
  // BUSINESS UNIT SCOPING
  // ============================================================

  /// Check if user has access to specific business unit
  bool hasAccessToBusinessUnit(String buId) {
    if (role == UserRole.admin) return true;
    if (businessUnitId == buId) return true;
    return allowedBusinessUnitIds.contains(buId);
  }

  /// Get all accessible business unit IDs
  List<String> get accessibleBusinessUnitIds {
    if (role == UserRole.admin) return [];  // Admin sees all
    final ids = <String>{};
    if (businessUnitId != null) ids.add(businessUnitId!);
    ids.addAll(allowedBusinessUnitIds);
    return ids.toList();
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Create a copy with updated fields
  UserModel copyWith({
    String? displayName,
    String? phone,
    String? email,
    bool? isActive,
    String? customerId,
    String? businessUnitId,
    List<String>? allowedBusinessUnitIds,
    DateTime? lastLoginAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      uid: uid,
      role: role,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      customerId: customerId ?? this.customerId,
      businessUnitId: businessUnitId ?? this.businessUnitId,
      allowedBusinessUnitIds: allowedBusinessUnitIds ?? this.allowedBusinessUnitIds,
      customerAccountId: customerAccountId,
      branchIds: branchIds,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdByUid: createdByUid,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Update last login timestamp
  UserModel updateLastLogin() {
    return copyWith(lastLoginAt: DateTime.now());
  }
}
