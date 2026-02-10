import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  customerB2c,
  customerB2bUser,
  customerB2bAdmin,
  driver,
  dispatcher,
  admin,
}

class UserModel {
  final String uid;
  final UserRole role;
  final String displayName;
  final String phone;
  final String email;
  final String? customerAccountId;
  final List<String> branchIds;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.role,
    required this.displayName,
    required this.phone,
    required this.email,
    this.customerAccountId,
    required this.branchIds,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      role: _parseUserRole(data['role'] as String? ?? 'customer_b2c'),
      displayName: data['displayName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      customerAccountId: data['customerAccountId'] as String?,
      branchIds: List<String>.from(data['branchIds'] as List? ?? []),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'role': _roleToString(role),
      'displayName': displayName,
      'phone': phone,
      'email': email,
      'customerAccountId': customerAccountId,
      'branchIds': branchIds,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static UserRole _parseUserRole(String role) {
    switch (role) {
      case 'customer_b2c':
        return UserRole.customerB2c;
      case 'customer_b2b_user':
        return UserRole.customerB2bUser;
      case 'customer_b2b_admin':
        return UserRole.customerB2bAdmin;
      case 'driver':
        return UserRole.driver;
      case 'dispatcher':
        return UserRole.dispatcher;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.customerB2c;
    }
  }

  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.customerB2c:
        return 'customer_b2c';
      case UserRole.customerB2bUser:
        return 'customer_b2b_user';
      case UserRole.customerB2bAdmin:
        return 'customer_b2b_admin';
      case UserRole.driver:
        return 'driver';
      case UserRole.dispatcher:
        return 'dispatcher';
      case UserRole.admin:
        return 'admin';
    }
  }

  bool get isCustomer => role == UserRole.customerB2c || 
                         role == UserRole.customerB2bUser || 
                         role == UserRole.customerB2bAdmin;
  
  bool get isB2BCustomer => role == UserRole.customerB2bUser || 
                            role == UserRole.customerB2bAdmin;
}
