import 'package:cloud_firestore/cloud_firestore.dart';

/// Workflow Instance - Tracks the lifecycle of a workflow execution
class WorkflowInstance {
  final String id;
  final String workflowType; // 'sales_order', 'uco_pickup', 'return_request'
  final String entityId; // ID of the related entity (order ID, pickup ID, etc.)
  final String entityType; // 'sales_order', 'uco_pickup', 'return_request'
  final String currentStatus;
  final String currentStepId;
  final String initiatedBy; // User ID who started the workflow
  final DateTime initiatedAt;
  final DateTime? completedAt;
  final bool isCompleted;
  final bool hasException;
  final String? exceptionReason;
  final Map<String, dynamic> metadata; // Additional context data
  final DateTime? slaDeadline;
  final bool isOverdue;
  
  WorkflowInstance({
    required this.id,
    required this.workflowType,
    required this.entityId,
    required this.entityType,
    required this.currentStatus,
    required this.currentStepId,
    required this.initiatedBy,
    required this.initiatedAt,
    this.completedAt,
    this.isCompleted = false,
    this.hasException = false,
    this.exceptionReason,
    this.metadata = const {},
    this.slaDeadline,
    this.isOverdue = false,
  });

  factory WorkflowInstance.fromFirestore(Map<String, dynamic> data, String docId) {
    return WorkflowInstance(
      id: docId,
      workflowType: data['workflowType'] ?? '',
      entityId: data['entityId'] ?? '',
      entityType: data['entityType'] ?? '',
      currentStatus: data['currentStatus'] ?? '',
      currentStepId: data['currentStepId'] ?? '',
      initiatedBy: data['initiatedBy'] ?? '',
      initiatedAt: (data['initiatedAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate() 
          : null,
      isCompleted: data['isCompleted'] ?? false,
      hasException: data['hasException'] ?? false,
      exceptionReason: data['exceptionReason'],
      metadata: data['metadata'] ?? {},
      slaDeadline: data['slaDeadline'] != null
          ? (data['slaDeadline'] as Timestamp).toDate()
          : null,
      isOverdue: data['isOverdue'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'workflowType': workflowType,
      'entityId': entityId,
      'entityType': entityType,
      'currentStatus': currentStatus,
      'currentStepId': currentStepId,
      'initiatedBy': initiatedBy,
      'initiatedAt': Timestamp.fromDate(initiatedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'isCompleted': isCompleted,
      'hasException': hasException,
      'exceptionReason': exceptionReason,
      'metadata': metadata,
      'slaDeadline': slaDeadline != null ? Timestamp.fromDate(slaDeadline!) : null,
      'isOverdue': isOverdue,
    };
  }

  String get displayName {
    switch (workflowType) {
      case 'sales_order':
        return 'Sales Order #${entityId.substring(0, 8)}';
      case 'uco_pickup':
        return 'UCO Pickup #${entityId.substring(0, 8)}';
      case 'return_request':
        return 'Return Request #${entityId.substring(0, 8)}';
      default:
        return 'Workflow #${entityId.substring(0, 8)}';
    }
  }
}

/// Workflow Step - Individual step in a workflow execution
class WorkflowStep {
  final String id;
  final String workflowInstanceId;
  final String stepName;
  final String status; // 'pending', 'in_progress', 'completed', 'rejected', 'skipped'
  final String? assignedTo; // User ID
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? completedBy; // User ID
  final String? notes;
  final Map<String, dynamic> data; // Step-specific data
  final DateTime? slaDeadline;
  final bool requiresApproval;
  
  WorkflowStep({
    required this.id,
    required this.workflowInstanceId,
    required this.stepName,
    required this.status,
    this.assignedTo,
    this.startedAt,
    this.completedAt,
    this.completedBy,
    this.notes,
    this.data = const {},
    this.slaDeadline,
    this.requiresApproval = false,
  });

  factory WorkflowStep.fromFirestore(Map<String, dynamic> data, String docId) {
    return WorkflowStep(
      id: docId,
      workflowInstanceId: data['workflowInstanceId'] ?? '',
      stepName: data['stepName'] ?? '',
      status: data['status'] ?? 'pending',
      assignedTo: data['assignedTo'],
      startedAt: data['startedAt'] != null
          ? (data['startedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      completedBy: data['completedBy'],
      notes: data['notes'],
      data: data['data'] ?? {},
      slaDeadline: data['slaDeadline'] != null
          ? (data['slaDeadline'] as Timestamp).toDate()
          : null,
      requiresApproval: data['requiresApproval'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'workflowInstanceId': workflowInstanceId,
      'stepName': stepName,
      'status': status,
      'assignedTo': assignedTo,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completedBy': completedBy,
      'notes': notes,
      'data': data,
      'slaDeadline': slaDeadline != null ? Timestamp.fromDate(slaDeadline!) : null,
      'requiresApproval': requiresApproval,
    };
  }
}

/// Approval Request - Pending approval for a workflow step
class ApprovalRequest {
  final String id;
  final String workflowInstanceId;
  final String workflowStepId;
  final String workflowType;
  final String entityId;
  final String requestType; // 'order_approval', 'uco_approval', 'return_approval', 'price_override', 'credit_limit'
  final String requestedBy;
  final DateTime requestedAt;
  final String? assignedTo; // Specific approver, null for role-based
  final String? assignedToRole; // Role that can approve (e.g., 'operations_manager', 'finance_manager')
  final String status; // 'pending', 'approved', 'rejected'
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final Map<String, dynamic> requestData; // Context data for approval decision
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final DateTime? slaDeadline;
  
  ApprovalRequest({
    required this.id,
    required this.workflowInstanceId,
    required this.workflowStepId,
    required this.workflowType,
    required this.entityId,
    required this.requestType,
    required this.requestedBy,
    required this.requestedAt,
    this.assignedTo,
    this.assignedToRole,
    this.status = 'pending',
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.requestData = const {},
    this.priority = 'medium',
    this.slaDeadline,
  });

  factory ApprovalRequest.fromFirestore(Map<String, dynamic> data, String docId) {
    return ApprovalRequest(
      id: docId,
      workflowInstanceId: data['workflowInstanceId'] ?? '',
      workflowStepId: data['workflowStepId'] ?? '',
      workflowType: data['workflowType'] ?? '',
      entityId: data['entityId'] ?? '',
      requestType: data['requestType'] ?? '',
      requestedBy: data['requestedBy'] ?? '',
      requestedAt: (data['requestedAt'] as Timestamp).toDate(),
      assignedTo: data['assignedTo'],
      assignedToRole: data['assignedToRole'],
      status: data['status'] ?? 'pending',
      approvedBy: data['approvedBy'],
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      rejectionReason: data['rejectionReason'],
      requestData: data['requestData'] ?? {},
      priority: data['priority'] ?? 'medium',
      slaDeadline: data['slaDeadline'] != null
          ? (data['slaDeadline'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'workflowInstanceId': workflowInstanceId,
      'workflowStepId': workflowStepId,
      'workflowType': workflowType,
      'entityId': entityId,
      'requestType': requestType,
      'requestedBy': requestedBy,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'assignedTo': assignedTo,
      'assignedToRole': assignedToRole,
      'status': status,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectionReason': rejectionReason,
      'requestData': requestData,
      'priority': priority,
      'slaDeadline': slaDeadline != null ? Timestamp.fromDate(slaDeadline!) : null,
    };
  }

  String get displayTitle {
    switch (requestType) {
      case 'order_approval':
        return 'Order Approval Required';
      case 'uco_approval':
        return 'UCO Pickup Approval';
      case 'return_approval':
        return 'Return Request Approval';
      case 'price_override':
        return 'Price Override Approval';
      case 'credit_limit':
        return 'Credit Limit Approval';
      default:
        return 'Approval Required';
    }
  }

  bool get isOverdue {
    if (slaDeadline == null || status != 'pending') return false;
    return DateTime.now().isAfter(slaDeadline!);
  }
}

/// Exception Record - Tracks workflow exceptions and issues
class ExceptionRecord {
  final String id;
  final String workflowInstanceId;
  final String entityType;
  final String entityId;
  final String exceptionType; // 'payment_failed', 'stock_unavailable', 'address_invalid', 'quality_issue', 'other'
  final String severity; // 'low', 'medium', 'high', 'critical'
  final String description;
  final DateTime occurredAt;
  final String? assignedTo; // User ID responsible for resolution
  final String status; // 'open', 'in_progress', 'resolved', 'escalated'
  final String? resolution;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final Map<String, dynamic> metadata;
  
  ExceptionRecord({
    required this.id,
    required this.workflowInstanceId,
    required this.entityType,
    required this.entityId,
    required this.exceptionType,
    required this.severity,
    required this.description,
    required this.occurredAt,
    this.assignedTo,
    this.status = 'open',
    this.resolution,
    this.resolvedAt,
    this.resolvedBy,
    this.metadata = const {},
  });

  factory ExceptionRecord.fromFirestore(Map<String, dynamic> data, String docId) {
    return ExceptionRecord(
      id: docId,
      workflowInstanceId: data['workflowInstanceId'] ?? '',
      entityType: data['entityType'] ?? '',
      entityId: data['entityId'] ?? '',
      exceptionType: data['exceptionType'] ?? '',
      severity: data['severity'] ?? 'medium',
      description: data['description'] ?? '',
      occurredAt: (data['occurredAt'] as Timestamp).toDate(),
      assignedTo: data['assignedTo'],
      status: data['status'] ?? 'open',
      resolution: data['resolution'],
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      resolvedBy: data['resolvedBy'],
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'workflowInstanceId': workflowInstanceId,
      'entityType': entityType,
      'entityId': entityId,
      'exceptionType': exceptionType,
      'severity': severity,
      'description': description,
      'occurredAt': Timestamp.fromDate(occurredAt),
      'assignedTo': assignedTo,
      'status': status,
      'resolution': resolution,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
      'metadata': metadata,
    };
  }

  String get displayTitle {
    switch (exceptionType) {
      case 'payment_failed':
        return 'Payment Processing Failed';
      case 'stock_unavailable':
        return 'Product Out of Stock';
      case 'address_invalid':
        return 'Invalid Delivery Address';
      case 'quality_issue':
        return 'Quality Check Failed';
      default:
        return 'Exception Occurred';
    }
  }
}

/// Audit Log Entry - Tracks all workflow actions
class AuditLogEntry {
  final String id;
  final String workflowInstanceId;
  final String entityType;
  final String entityId;
  final String action; // 'created', 'approved', 'rejected', 'status_changed', 'assigned', 'exception_raised', etc.
  final String performedBy;
  final DateTime performedAt;
  final String? fromStatus;
  final String? toStatus;
  final String? notes;
  final Map<String, dynamic> changes; // Before/after values
  
  AuditLogEntry({
    required this.id,
    required this.workflowInstanceId,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.performedBy,
    required this.performedAt,
    this.fromStatus,
    this.toStatus,
    this.notes,
    this.changes = const {},
  });

  factory AuditLogEntry.fromFirestore(Map<String, dynamic> data, String docId) {
    return AuditLogEntry(
      id: docId,
      workflowInstanceId: data['workflowInstanceId'] ?? '',
      entityType: data['entityType'] ?? '',
      entityId: data['entityId'] ?? '',
      action: data['action'] ?? '',
      performedBy: data['performedBy'] ?? '',
      performedAt: (data['performedAt'] as Timestamp).toDate(),
      fromStatus: data['fromStatus'],
      toStatus: data['toStatus'],
      notes: data['notes'],
      changes: data['changes'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'workflowInstanceId': workflowInstanceId,
      'entityType': entityType,
      'entityId': entityId,
      'action': action,
      'performedBy': performedBy,
      'performedAt': Timestamp.fromDate(performedAt),
      'fromStatus': fromStatus,
      'toStatus': toStatus,
      'notes': notes,
      'changes': changes,
    };
  }

  String get displayAction {
    switch (action) {
      case 'created':
        return 'Created';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'status_changed':
        return 'Status Changed';
      case 'assigned':
        return 'Assigned';
      case 'exception_raised':
        return 'Exception Raised';
      case 'exception_resolved':
        return 'Exception Resolved';
      default:
        return action;
    }
  }
}
