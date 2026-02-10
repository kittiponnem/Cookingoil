import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_branch_model.dart';

enum PickupStatus {
  submitted,
  approved,
  scheduled,
  driverAssigned,
  collected,
  settled,
  rejected,
  cancelled,
}

enum IncentiveType {
  cash,
  creditNote,
  points,
  all,
}

class QualityFlags {
  final bool hasWater;
  final bool hasSolid;
  final bool hasOdor;
  final String? otherNotes;

  QualityFlags({
    this.hasWater = false,
    this.hasSolid = false,
    this.hasOdor = false,
    this.otherNotes,
  });

  factory QualityFlags.fromMap(Map<String, dynamic> map) {
    return QualityFlags(
      hasWater: map['water'] as bool? ?? false,
      hasSolid: map['solid'] as bool? ?? false,
      hasOdor: map['odor'] as bool? ?? false,
      otherNotes: map['otherNotes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'water': hasWater,
      'solid': hasSolid,
      'odor': hasOdor,
      'otherNotes': otherNotes,
    };
  }
}

class PickupRequest {
  final String pickupId;
  final String customerType;
  final String customerAccountId;
  final String? branchId;
  final AddressModel pickupAddress;
  final double estimatedQty;
  final String estimatedUom;
  final String containerType;
  final List<String> photos;
  final DateTime preferredWindowStart;
  final DateTime preferredWindowEnd;
  final IncentiveType incentiveType;
  final PickupStatus status;
  final QualityFlags? qualityFlags;
  final String createdByUid;
  final DateTime createdAt;
  final DateTime lastStatusAt;

  PickupRequest({
    required this.pickupId,
    required this.customerType,
    required this.customerAccountId,
    this.branchId,
    required this.pickupAddress,
    required this.estimatedQty,
    required this.estimatedUom,
    required this.containerType,
    required this.photos,
    required this.preferredWindowStart,
    required this.preferredWindowEnd,
    required this.incentiveType,
    required this.status,
    this.qualityFlags,
    required this.createdByUid,
    required this.createdAt,
    required this.lastStatusAt,
  });

  factory PickupRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PickupRequest(
      pickupId: doc.id,
      customerType: data['customerType'] as String? ?? 'B2C',
      customerAccountId: data['customerAccountId'] as String? ?? '',
      branchId: data['branchId'] as String?,
      pickupAddress: AddressModel.fromMap(
          data['pickupAddress'] as Map<String, dynamic>? ?? {}),
      estimatedQty: (data['estimatedQty'] as num?)?.toDouble() ?? 0.0,
      estimatedUom: data['estimatedUom'] as String? ?? 'liter',
      containerType: data['containerType'] as String? ?? '',
      photos: List<String>.from(data['photos'] as List? ?? []),
      preferredWindowStart:
          (data['preferredWindowStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      preferredWindowEnd:
          (data['preferredWindowEnd'] as Timestamp?)?.toDate() ?? DateTime.now(),
      incentiveType: _parseIncentiveType(data['incentiveType'] as String? ?? 'Cash'),
      status: _parsePickupStatus(data['status'] as String? ?? 'Submitted'),
      qualityFlags: data['qualityFlags'] != null
          ? QualityFlags.fromMap(data['qualityFlags'] as Map<String, dynamic>)
          : null,
      createdByUid: data['createdByUid'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastStatusAt: (data['lastStatusAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerType': customerType,
      'customerAccountId': customerAccountId,
      'branchId': branchId,
      'pickupAddress': pickupAddress.toMap(),
      'estimatedQty': estimatedQty,
      'estimatedUom': estimatedUom,
      'containerType': containerType,
      'photos': photos,
      'preferredWindowStart': Timestamp.fromDate(preferredWindowStart),
      'preferredWindowEnd': Timestamp.fromDate(preferredWindowEnd),
      'incentiveType': _incentiveTypeToString(incentiveType),
      'status': _pickupStatusToString(status),
      'qualityFlags': qualityFlags?.toMap(),
      'createdByUid': createdByUid,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastStatusAt': Timestamp.fromDate(lastStatusAt),
    };
  }

  static PickupStatus _parsePickupStatus(String status) {
    switch (status) {
      case 'Submitted':
        return PickupStatus.submitted;
      case 'Approved':
        return PickupStatus.approved;
      case 'Scheduled':
        return PickupStatus.scheduled;
      case 'DriverAssigned':
        return PickupStatus.driverAssigned;
      case 'Collected':
        return PickupStatus.collected;
      case 'Settled':
        return PickupStatus.settled;
      case 'Rejected':
        return PickupStatus.rejected;
      case 'Cancelled':
        return PickupStatus.cancelled;
      default:
        return PickupStatus.submitted;
    }
  }

  static String _pickupStatusToString(PickupStatus status) {
    switch (status) {
      case PickupStatus.submitted:
        return 'Submitted';
      case PickupStatus.approved:
        return 'Approved';
      case PickupStatus.scheduled:
        return 'Scheduled';
      case PickupStatus.driverAssigned:
        return 'DriverAssigned';
      case PickupStatus.collected:
        return 'Collected';
      case PickupStatus.settled:
        return 'Settled';
      case PickupStatus.rejected:
        return 'Rejected';
      case PickupStatus.cancelled:
        return 'Cancelled';
    }
  }

  static IncentiveType _parseIncentiveType(String type) {
    switch (type) {
      case 'Cash':
        return IncentiveType.cash;
      case 'CreditNote':
        return IncentiveType.creditNote;
      case 'Points':
        return IncentiveType.points;
      case 'All':
        return IncentiveType.all;
      default:
        return IncentiveType.cash;
    }
  }

  static String _incentiveTypeToString(IncentiveType type) {
    switch (type) {
      case IncentiveType.cash:
        return 'Cash';
      case IncentiveType.creditNote:
        return 'CreditNote';
      case IncentiveType.points:
        return 'Points';
      case IncentiveType.all:
        return 'All';
    }
  }
}
