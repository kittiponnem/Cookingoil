import 'package:cloud_firestore/cloud_firestore.dart';

enum JobType {
  delivery,
  pickup,
}

enum JobStatus {
  assigned,
  enRoute,
  arrived,
  completed,
  failed,
  rescheduled,
}

class Job {
  final String jobId;
  final JobType jobType;
  final String refId;
  final int stopSequence;
  final String assignedDriverUid;
  final String assignedVehicleId;
  final DateTime scheduledDate;
  final DateTime windowStart;
  final DateTime windowEnd;
  final JobStatus status;
  final String dispatcherUid;
  final DateTime createdAt;

  Job({
    required this.jobId,
    required this.jobType,
    required this.refId,
    required this.stopSequence,
    required this.assignedDriverUid,
    required this.assignedVehicleId,
    required this.scheduledDate,
    required this.windowStart,
    required this.windowEnd,
    required this.status,
    required this.dispatcherUid,
    required this.createdAt,
  });

  factory Job.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Job(
      jobId: doc.id,
      jobType: _parseJobType(data['jobType'] as String? ?? 'Delivery'),
      refId: data['refId'] as String? ?? '',
      stopSequence: data['stopSequence'] as int? ?? 0,
      assignedDriverUid: data['assignedDriverUid'] as String? ?? '',
      assignedVehicleId: data['assignedVehicleId'] as String? ?? '',
      scheduledDate:
          (data['scheduledDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      windowStart: (data['windowStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      windowEnd: (data['windowEnd'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _parseJobStatus(data['status'] as String? ?? 'Assigned'),
      dispatcherUid: data['dispatcherUid'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'jobType': _jobTypeToString(jobType),
      'refId': refId,
      'stopSequence': stopSequence,
      'assignedDriverUid': assignedDriverUid,
      'assignedVehicleId': assignedVehicleId,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'windowStart': Timestamp.fromDate(windowStart),
      'windowEnd': Timestamp.fromDate(windowEnd),
      'status': _jobStatusToString(status),
      'dispatcherUid': dispatcherUid,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static JobType _parseJobType(String type) {
    switch (type) {
      case 'Delivery':
        return JobType.delivery;
      case 'Pickup':
        return JobType.pickup;
      default:
        return JobType.delivery;
    }
  }

  static String _jobTypeToString(JobType type) {
    switch (type) {
      case JobType.delivery:
        return 'Delivery';
      case JobType.pickup:
        return 'Pickup';
    }
  }

  static JobStatus _parseJobStatus(String status) {
    switch (status) {
      case 'Assigned':
        return JobStatus.assigned;
      case 'EnRoute':
        return JobStatus.enRoute;
      case 'Arrived':
        return JobStatus.arrived;
      case 'Completed':
        return JobStatus.completed;
      case 'Failed':
        return JobStatus.failed;
      case 'Rescheduled':
        return JobStatus.rescheduled;
      default:
        return JobStatus.assigned;
    }
  }

  static String _jobStatusToString(JobStatus status) {
    switch (status) {
      case JobStatus.assigned:
        return 'Assigned';
      case JobStatus.enRoute:
        return 'EnRoute';
      case JobStatus.arrived:
        return 'Arrived';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.failed:
        return 'Failed';
      case JobStatus.rescheduled:
        return 'Rescheduled';
    }
  }
}

enum JobEventType {
  statusChange,
  podUploaded,
  pickupProof,
  note,
}

class JobEvent {
  final String jobId;
  final JobEventType eventType;
  final String? statusFrom;
  final String? statusTo;
  final String? note;
  final List<String> photoUrls;
  final String? signatureUrl;
  final double? actualQty;
  final String? actualUom;
  final double? lat;
  final double? lng;
  final String createdByUid;
  final DateTime createdAt;

  JobEvent({
    required this.jobId,
    required this.eventType,
    this.statusFrom,
    this.statusTo,
    this.note,
    required this.photoUrls,
    this.signatureUrl,
    this.actualQty,
    this.actualUom,
    this.lat,
    this.lng,
    required this.createdByUid,
    required this.createdAt,
  });

  factory JobEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobEvent(
      jobId: data['jobId'] as String? ?? '',
      eventType: _parseEventType(data['eventType'] as String? ?? 'StatusChange'),
      statusFrom: data['statusFrom'] as String?,
      statusTo: data['statusTo'] as String?,
      note: data['note'] as String?,
      photoUrls: List<String>.from(data['photoUrls'] as List? ?? []),
      signatureUrl: data['signatureUrl'] as String?,
      actualQty: (data['actualQty'] as num?)?.toDouble(),
      actualUom: data['actualUom'] as String?,
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      createdByUid: data['createdByUid'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'jobId': jobId,
      'eventType': _eventTypeToString(eventType),
      'statusFrom': statusFrom,
      'statusTo': statusTo,
      'note': note,
      'photoUrls': photoUrls,
      'signatureUrl': signatureUrl,
      'actualQty': actualQty,
      'actualUom': actualUom,
      'lat': lat,
      'lng': lng,
      'createdByUid': createdByUid,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static JobEventType _parseEventType(String type) {
    switch (type) {
      case 'StatusChange':
        return JobEventType.statusChange;
      case 'PODUploaded':
        return JobEventType.podUploaded;
      case 'PickupProof':
        return JobEventType.pickupProof;
      case 'Note':
        return JobEventType.note;
      default:
        return JobEventType.statusChange;
    }
  }

  static String _eventTypeToString(JobEventType type) {
    switch (type) {
      case JobEventType.statusChange:
        return 'StatusChange';
      case JobEventType.podUploaded:
        return 'PODUploaded';
      case JobEventType.pickupProof:
        return 'PickupProof';
      case JobEventType.note:
        return 'Note';
    }
  }
}
