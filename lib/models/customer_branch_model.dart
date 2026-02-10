import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String label;
  final String addressText;
  final double lat;
  final double lng;
  final String? notes;

  AddressModel({
    required this.label,
    required this.addressText,
    required this.lat,
    required this.lng,
    this.notes,
  });

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      label: map['label'] as String? ?? '',
      addressText: map['addressText'] as String? ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'addressText': addressText,
      'lat': lat,
      'lng': lng,
      'notes': notes,
    };
  }
}

class CustomerBranch {
  final String branchId;
  final String customerAccountId;
  final String branchName;
  final List<AddressModel> addresses;
  final AddressModel? defaultAddress;
  final DateTime createdAt;

  CustomerBranch({
    required this.branchId,
    required this.customerAccountId,
    required this.branchName,
    required this.addresses,
    this.defaultAddress,
    required this.createdAt,
  });

  factory CustomerBranch.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomerBranch(
      branchId: doc.id,
      customerAccountId: data['customerAccountId'] as String? ?? '',
      branchName: data['branchName'] as String? ?? '',
      addresses: (data['addresses'] as List?)
              ?.map((addr) => AddressModel.fromMap(addr as Map<String, dynamic>))
              .toList() ??
          [],
      defaultAddress: data['defaultAddress'] != null
          ? AddressModel.fromMap(data['defaultAddress'] as Map<String, dynamic>)
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerAccountId': customerAccountId,
      'branchName': branchName,
      'addresses': addresses.map((addr) => addr.toMap()).toList(),
      'defaultAddress': defaultAddress?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
