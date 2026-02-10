import 'package:cloud_firestore/cloud_firestore.dart';

/// Workflow instance status
enum WorkflowStatus {
  pending,
  inProgress,
  completed,
  cancelled,
  failed,
}

/// Workflow instance - tracks workflow execution for orders
class WorkflowInstance {
  final String id;
  final String domain;  // sales | uco | return | refund
  final String orderType;
  final String orderId;
  final String templateId;
  final WorkflowStatus status;
  final int currentStep;
  final DateTime? slaDueAt;
  final String startedByUserId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  WorkflowInstance({
    required this.id,
    required this.domain,
    required this.orderType,
    required this.orderId,
    required this.templateId,
    required this.status,
    required this.currentStep,
    this.slaDueAt,
    required this.startedByUserId,
    required this.createdAt,
    this.completedAt,
    this.metadata,
  });

  factory WorkflowInstance.fromFirestore(Map<String, dynamic> data, String docId) {
    return WorkflowInstance(
      id: docId,
      domain: data['domain'] as String? ?? '',
      orderType: data['orderType'] as String? ?? '',
      orderId: data['orderId'] as String? ?? '',
      templateId: data['templateId'] as String? ?? '',
      status: _parseStatus(data['status'] as String?),
      currentStep: data['currentStep'] as int? ?? 1,
      slaDueAt: (data['slaDueAt'] as Timestamp?)?.toDate(),
      startedByUserId: data['startedByUserId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'domain': domain,
      'orderType': orderType,
      'orderId': orderId,
      'templateId': templateId,
      'status': _statusToString(status),
      'currentStep': currentStep,
      'slaDueAt': slaDueAt != null ? Timestamp.fromDate(slaDueAt!) : null,
      'startedByUserId': startedByUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'metadata': metadata,
    };
  }

  static WorkflowStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return WorkflowStatus.pending;
      case 'in_progress':
      case 'inprogress':
        return WorkflowStatus.inProgress;
      case 'completed':
        return WorkflowStatus.completed;
      case 'cancelled':
        return WorkflowStatus.cancelled;
      case 'failed':
        return WorkflowStatus.failed;
      default:
        return WorkflowStatus.pending;
    }
  }

  static String _statusToString(WorkflowStatus status) {
    switch (status) {
      case WorkflowStatus.pending:
        return 'pending';
      case WorkflowStatus.inProgress:
        return 'in_progress';
      case WorkflowStatus.completed:
        return 'completed';
      case WorkflowStatus.cancelled:
        return 'cancelled';
      case WorkflowStatus.failed:
        return 'failed';
    }
  }

  bool get isActive => status == WorkflowStatus.pending || status == WorkflowStatus.inProgress;
  bool get isTerminal => status == WorkflowStatus.completed || 
                         status == WorkflowStatus.cancelled || 
                         status == WorkflowStatus.failed;
  bool get isOverdue => slaDueAt != null && DateTime.now().isAfter(slaDueAt!);

  WorkflowInstance copyWith({
    WorkflowStatus? status,
    int? currentStep,
    DateTime? slaDueAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return WorkflowInstance(
      id: id,
      domain: domain,
      orderType: orderType,
      orderId: orderId,
      templateId: templateId,
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      slaDueAt: slaDueAt ?? this.slaDueAt,
      startedByUserId: startedByUserId,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Workflow step decision
enum StepDecision {
  pending,
  approved,
  rejected,
  skipped,
  failed,
}

/// Workflow step - individual step in workflow execution
class WorkflowStep {
  final String id;
  final String workflowInstanceId;
  final int stepNumber;
  final String stepName;
  final String stepType;  // Approval | Task | SystemCheck
  final String? assignedRole;
  final String? assignedUserId;
  final StepDecision decision;
  final String? decisionByUserId;
  final DateTime? decisionAt;
  final String? comments;
  final List<String> attachments;
  final DateTime? slaDueAt;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  WorkflowStep({
    required this.id,
    required this.workflowInstanceId,
    required this.stepNumber,
    required this.stepName,
    required this.stepType,
    this.assignedRole,
    this.assignedUserId,
    required this.decision,
    this.decisionByUserId,
    this.decisionAt,
    this.comments,
    List<String>? attachments,
    this.slaDueAt,
    required this.createdAt,
    this.completedAt,
    this.metadata,
  }) : attachments = attachments ?? [];

  factory WorkflowStep.fromFirestore(Map<String, dynamic> data, String docId) {
    return WorkflowStep(
      id: docId,
      workflowInstanceId: data['workflowInstanceId'] as String? ?? '',
      stepNumber: data['stepNumber'] as int? ?? 1,
      stepName: data['stepName'] as String? ?? '',
      stepType: data['stepType'] as String? ?? 'Task',
      assignedRole: data['assignedRole'] as String?,
      assignedUserId: data['assignedUserId'] as String?,
      decision: _parseDecision(data['decision'] as String?),
      decisionByUserId: data['decisionByUserId'] as String?,
      decisionAt: (data['decisionAt'] as Timestamp?)?.toDate(),
      comments: data['comments'] as String?,
      attachments: List<String>.from(data['attachments'] as List? ?? []),
      slaDueAt: (data['slaDueAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'workflowInstanceId': workflowInstanceId,
      'stepNumber': stepNumber,
      'stepName': stepName,
      'stepType': stepType,
      'assignedRole': assignedRole,
      'assignedUserId': assignedUserId,
      'decision': _decisionToString(decision),
      'decisionByUserId': decisionByUserId,
      'decisionAt': decisionAt != null ? Timestamp.fromDate(decisionAt!) : null,
      'comments': comments,
      'attachments': attachments,
      'slaDueAt': slaDueAt != null ? Timestamp.fromDate(slaDueAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'metadata': metadata,
    };
  }

  static StepDecision _parseDecision(String? decision) {
    switch (decision?.toLowerCase()) {
      case 'pending':
        return StepDecision.pending;
      case 'approved':
        return StepDecision.approved;
      case 'rejected':
        return StepDecision.rejected;
      case 'skipped':
        return StepDecision.skipped;
      case 'failed':
        return StepDecision.failed;
      default:
        return StepDecision.pending;
    }
  }

  static String _decisionToString(StepDecision decision) {
    switch (decision) {
      case StepDecision.pending:
        return 'pending';
      case StepDecision.approved:
        return 'approved';
      case StepDecision.rejected:
        return 'rejected';
      case StepDecision.skipped:
        return 'skipped';
      case StepDecision.failed:
        return 'failed';
    }
  }

  bool get isPending => decision == StepDecision.pending;
  bool get isCompleted => decision != StepDecision.pending;
  bool get isApproved => decision == StepDecision.approved;
  bool get isRejected => decision == StepDecision.rejected;
  bool get isOverdue => slaDueAt != null && DateTime.now().isAfter(slaDueAt!);

  /// Check if user can take action on this step
  bool canUserTakeAction(String userId, String userRole) {
    if (!isPending) return false;
    
    // Specific user assignment
    if (assignedUserId != null) {
      return assignedUserId == userId;
    }
    
    // Role-based assignment
    if (assignedRole != null) {
      return assignedRole == userRole;
    }
    
    return false;
  }

  WorkflowStep copyWith({
    StepDecision? decision,
    String? decisionByUserId,
    DateTime? decisionAt,
    String? comments,
    List<String>? attachments,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return WorkflowStep(
      id: id,
      workflowInstanceId: workflowInstanceId,
      stepNumber: stepNumber,
      stepName: stepName,
      stepType: stepType,
      assignedRole: assignedRole,
      assignedUserId: assignedUserId,
      decision: decision ?? this.decision,
      decisionByUserId: decisionByUserId ?? this.decisionByUserId,
      decisionAt: decisionAt ?? this.decisionAt,
      comments: comments ?? this.comments,
      attachments: attachments ?? this.attachments,
      slaDueAt: slaDueAt,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Return/Refund request model
class ReturnRequest {
  final String id;
  final String salesOrderId;
  final String customerId;
  final String requestType;  // Return | Refund | Replace
  final String reasonId;
  final String description;
  final String status;
  final List<ReturnItem> items;
  final String? workflowInstanceId;
  final DateTime createdAt;
  final DateTime? completedAt;

  ReturnRequest({
    required this.id,
    required this.salesOrderId,
    required this.customerId,
    required this.requestType,
    required this.reasonId,
    required this.description,
    required this.status,
    required this.items,
    this.workflowInstanceId,
    required this.createdAt,
    this.completedAt,
  });

  factory ReturnRequest.fromFirestore(Map<String, dynamic> data, String docId) {
    return ReturnRequest(
      id: docId,
      salesOrderId: data['salesOrderId'] as String? ?? '',
      customerId: data['customerId'] as String? ?? '',
      requestType: data['requestType'] as String? ?? 'Return',
      reasonId: data['reasonId'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      items: (data['items'] as List?)
              ?.map((e) => ReturnItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      workflowInstanceId: data['workflowInstanceId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'salesOrderId': salesOrderId,
      'customerId': customerId,
      'requestType': requestType,
      'reasonId': reasonId,
      'description': description,
      'status': status,
      'items': items.map((i) => i.toMap()).toList(),
      'workflowInstanceId': workflowInstanceId,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}

/// Return item
class ReturnItem {
  final String productId;
  final int quantity;
  final String condition;
  final List<String> photos;

  ReturnItem({
    required this.productId,
    required this.quantity,
    required this.condition,
    List<String>? photos,
  }) : photos = photos ?? [];

  factory ReturnItem.fromMap(Map<String, dynamic> data) {
    return ReturnItem(
      productId: data['productId'] as String? ?? '',
      quantity: data['quantity'] as int? ?? 0,
      condition: data['condition'] as String? ?? '',
      photos: List<String>.from(data['photos'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'quantity': quantity,
      'condition': condition,
      'photos': photos,
    };
  }
}
