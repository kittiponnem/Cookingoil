import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/workflow_models.dart';

/// Workflow Service - Manages workflow instances, approvals, and exceptions
class WorkflowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== WORKFLOW INSTANCES ====================

  /// Get all workflow instances with optional filtering
  Stream<List<WorkflowInstance>> getWorkflowInstances({
    String? workflowType,
    bool? isCompleted,
    bool? hasException,
    bool? isOverdue,
  }) {
    Query query = _firestore.collection('workflow_instances');

    if (workflowType != null) {
      query = query.where('workflowType', isEqualTo: workflowType);
    }
    if (isCompleted != null) {
      query = query.where('isCompleted', isEqualTo: isCompleted);
    }
    if (hasException != null) {
      query = query.where('hasException', isEqualTo: hasException);
    }
    if (isOverdue != null) {
      query = query.where('isOverdue', isEqualTo: isOverdue);
    }

    return query.orderBy('initiatedAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => WorkflowInstance.fromFirestore(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  /// Get a single workflow instance by ID
  Future<WorkflowInstance?> getWorkflowInstance(String instanceId) async {
    try {
      final doc = await _firestore
          .collection('workflow_instances')
          .doc(instanceId)
          .get();
      if (doc.exists) {
        return WorkflowInstance.fromFirestore(
            doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting workflow instance: $e');
      }
      return null;
    }
  }

  /// Start a new workflow instance
  Future<String> startWorkflow({
    required String workflowType,
    required String entityId,
    required String entityType,
    required String initiatedBy,
    Map<String, dynamic> metadata = const {},
    int? slaHours,
  }) async {
    try {
      final now = DateTime.now();
      final instance = WorkflowInstance(
        id: '', // Firestore will generate
        workflowType: workflowType,
        entityId: entityId,
        entityType: entityType,
        currentStatus: 'pending',
        currentStepId: 'step_1',
        initiatedBy: initiatedBy,
        initiatedAt: now,
        metadata: metadata,
        slaDeadline: slaHours != null ? now.add(Duration(hours: slaHours)) : null,
      );

      final docRef = await _firestore
          .collection('workflow_instances')
          .add(instance.toFirestore());

      // Create audit log entry
      await _createAuditLog(
        workflowInstanceId: docRef.id,
        entityType: entityType,
        entityId: entityId,
        action: 'created',
        performedBy: initiatedBy,
        toStatus: 'pending',
        notes: 'Workflow initiated',
      );

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error starting workflow: $e');
      }
      rethrow;
    }
  }

  /// Update workflow status
  Future<void> updateWorkflowStatus({
    required String instanceId,
    required String newStatus,
    required String performedBy,
    String? notes,
  }) async {
    try {
      final instance = await getWorkflowInstance(instanceId);
      if (instance == null) return;

      await _firestore.collection('workflow_instances').doc(instanceId).update({
        'currentStatus': newStatus,
        'isCompleted': newStatus == 'completed' || newStatus == 'cancelled',
        'completedAt': newStatus == 'completed'
            ? Timestamp.fromDate(DateTime.now())
            : null,
      });

      // Create audit log
      await _createAuditLog(
        workflowInstanceId: instanceId,
        entityType: instance.entityType,
        entityId: instance.entityId,
        action: 'status_changed',
        performedBy: performedBy,
        fromStatus: instance.currentStatus,
        toStatus: newStatus,
        notes: notes,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating workflow status: $e');
      }
      rethrow;
    }
  }

  // ==================== APPROVAL REQUESTS ====================

  /// Get pending approval requests for a user or role
  Stream<List<ApprovalRequest>> getPendingApprovals({
    String? userId,
    String? userRole,
    String? workflowType,
  }) {
    Query query = _firestore
        .collection('approval_requests')
        .where('status', isEqualTo: 'pending');

    if (userId != null) {
      query = query.where('assignedTo', isEqualTo: userId);
    }
    if (userRole != null && userId == null) {
      query = query.where('assignedToRole', isEqualTo: userRole);
    }
    if (workflowType != null) {
      query = query.where('workflowType', isEqualTo: workflowType);
    }

    return query.orderBy('requestedAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ApprovalRequest.fromFirestore(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  /// Create a new approval request
  Future<String> createApprovalRequest({
    required String workflowInstanceId,
    required String workflowStepId,
    required String workflowType,
    required String entityId,
    required String requestType,
    required String requestedBy,
    String? assignedTo,
    String? assignedToRole,
    Map<String, dynamic> requestData = const {},
    String priority = 'medium',
    int? slaHours,
  }) async {
    try {
      final now = DateTime.now();
      final request = ApprovalRequest(
        id: '',
        workflowInstanceId: workflowInstanceId,
        workflowStepId: workflowStepId,
        workflowType: workflowType,
        entityId: entityId,
        requestType: requestType,
        requestedBy: requestedBy,
        requestedAt: now,
        assignedTo: assignedTo,
        assignedToRole: assignedToRole,
        requestData: requestData,
        priority: priority,
        slaDeadline: slaHours != null ? now.add(Duration(hours: slaHours)) : null,
      );

      final docRef = await _firestore
          .collection('approval_requests')
          .add(request.toFirestore());

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating approval request: $e');
      }
      rethrow;
    }
  }

  /// Approve a request
  Future<void> approveRequest({
    required String requestId,
    required String approvedBy,
    String? notes,
  }) async {
    try {
      final requestDoc = await _firestore
          .collection('approval_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Approval request not found');
      }

      final request = ApprovalRequest.fromFirestore(
          requestDoc.data() as Map<String, dynamic>, requestDoc.id);

      // Update approval request
      await _firestore.collection('approval_requests').doc(requestId).update({
        'status': 'approved',
        'approvedBy': approvedBy,
        'approvedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update workflow instance
      await updateWorkflowStatus(
        instanceId: request.workflowInstanceId,
        newStatus: 'approved',
        performedBy: approvedBy,
        notes: notes,
      );

      // Create audit log
      await _createAuditLog(
        workflowInstanceId: request.workflowInstanceId,
        entityType: request.workflowType,
        entityId: request.entityId,
        action: 'approved',
        performedBy: approvedBy,
        toStatus: 'approved',
        notes: notes,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error approving request: $e');
      }
      rethrow;
    }
  }

  /// Reject a request
  Future<void> rejectRequest({
    required String requestId,
    required String rejectedBy,
    required String reason,
  }) async {
    try {
      final requestDoc = await _firestore
          .collection('approval_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Approval request not found');
      }

      final request = ApprovalRequest.fromFirestore(
          requestDoc.data() as Map<String, dynamic>, requestDoc.id);

      // Update approval request
      await _firestore.collection('approval_requests').doc(requestId).update({
        'status': 'rejected',
        'approvedBy': rejectedBy,
        'approvedAt': Timestamp.fromDate(DateTime.now()),
        'rejectionReason': reason,
      });

      // Update workflow instance
      await updateWorkflowStatus(
        instanceId: request.workflowInstanceId,
        newStatus: 'rejected',
        performedBy: rejectedBy,
        notes: 'Rejected: $reason',
      );

      // Create audit log
      await _createAuditLog(
        workflowInstanceId: request.workflowInstanceId,
        entityType: request.workflowType,
        entityId: request.entityId,
        action: 'rejected',
        performedBy: rejectedBy,
        toStatus: 'rejected',
        notes: reason,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error rejecting request: $e');
      }
      rethrow;
    }
  }

  // ==================== EXCEPTIONS ====================

  /// Get exception records with filtering
  Stream<List<ExceptionRecord>> getExceptions({
    String? status,
    String? severity,
    String? entityType,
  }) {
    Query query = _firestore.collection('exceptions');

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (severity != null) {
      query = query.where('severity', isEqualTo: severity);
    }
    if (entityType != null) {
      query = query.where('entityType', isEqualTo: entityType);
    }

    return query.orderBy('occurredAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ExceptionRecord.fromFirestore(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  /// Create a new exception
  Future<String> createException({
    required String workflowInstanceId,
    required String entityType,
    required String entityId,
    required String exceptionType,
    required String severity,
    required String description,
    String? assignedTo,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final exception = ExceptionRecord(
        id: '',
        workflowInstanceId: workflowInstanceId,
        entityType: entityType,
        entityId: entityId,
        exceptionType: exceptionType,
        severity: severity,
        description: description,
        occurredAt: DateTime.now(),
        assignedTo: assignedTo,
        metadata: metadata,
      );

      final docRef =
          await _firestore.collection('exceptions').add(exception.toFirestore());

      // Mark workflow instance as having exception
      await _firestore
          .collection('workflow_instances')
          .doc(workflowInstanceId)
          .update({
        'hasException': true,
        'exceptionReason': description,
      });

      // Create audit log
      await _createAuditLog(
        workflowInstanceId: workflowInstanceId,
        entityType: entityType,
        entityId: entityId,
        action: 'exception_raised',
        performedBy: 'system',
        notes: description,
      );

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating exception: $e');
      }
      rethrow;
    }
  }

  /// Resolve an exception
  Future<void> resolveException({
    required String exceptionId,
    required String resolvedBy,
    required String resolution,
  }) async {
    try {
      final exceptionDoc =
          await _firestore.collection('exceptions').doc(exceptionId).get();

      if (!exceptionDoc.exists) {
        throw Exception('Exception not found');
      }

      final exception = ExceptionRecord.fromFirestore(
          exceptionDoc.data() as Map<String, dynamic>, exceptionDoc.id);

      // Update exception
      await _firestore.collection('exceptions').doc(exceptionId).update({
        'status': 'resolved',
        'resolution': resolution,
        'resolvedAt': Timestamp.fromDate(DateTime.now()),
        'resolvedBy': resolvedBy,
      });

      // Check if all exceptions are resolved for this workflow
      final openExceptions = await _firestore
          .collection('exceptions')
          .where('workflowInstanceId', isEqualTo: exception.workflowInstanceId)
          .where('status', isEqualTo: 'open')
          .get();

      if (openExceptions.docs.isEmpty) {
        // Clear exception flag on workflow instance
        await _firestore
            .collection('workflow_instances')
            .doc(exception.workflowInstanceId)
            .update({
          'hasException': false,
          'exceptionReason': null,
        });
      }

      // Create audit log
      await _createAuditLog(
        workflowInstanceId: exception.workflowInstanceId,
        entityType: exception.entityType,
        entityId: exception.entityId,
        action: 'exception_resolved',
        performedBy: resolvedBy,
        notes: resolution,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error resolving exception: $e');
      }
      rethrow;
    }
  }

  // ==================== AUDIT LOG ====================

  /// Get audit log entries
  Stream<List<AuditLogEntry>> getAuditLog({
    String? workflowInstanceId,
    String? entityType,
    String? entityId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore.collection('audit_log');

    if (workflowInstanceId != null) {
      query = query.where('workflowInstanceId', isEqualTo: workflowInstanceId);
    }
    if (entityType != null) {
      query = query.where('entityType', isEqualTo: entityType);
    }
    if (entityId != null) {
      query = query.where('entityId', isEqualTo: entityId);
    }

    return query.orderBy('performedAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => AuditLogEntry.fromFirestore(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
  }

  /// Create audit log entry (internal helper)
  Future<void> _createAuditLog({
    required String workflowInstanceId,
    required String entityType,
    required String entityId,
    required String action,
    required String performedBy,
    String? fromStatus,
    String? toStatus,
    String? notes,
    Map<String, dynamic> changes = const {},
  }) async {
    try {
      final entry = AuditLogEntry(
        id: '',
        workflowInstanceId: workflowInstanceId,
        entityType: entityType,
        entityId: entityId,
        action: action,
        performedBy: performedBy,
        performedAt: DateTime.now(),
        fromStatus: fromStatus,
        toStatus: toStatus,
        notes: notes,
        changes: changes,
      );

      await _firestore.collection('audit_log').add(entry.toFirestore());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating audit log: $e');
      }
      // Don't rethrow - audit log failures shouldn't break main operations
    }
  }

  // ==================== SLA TRACKING ====================

  /// Check for overdue workflows and update flags
  Future<void> checkOverdueWorkflows() async {
    try {
      final now = DateTime.now();
      final overdueWorkflows = await _firestore
          .collection('workflow_instances')
          .where('isCompleted', isEqualTo: false)
          .where('slaDeadline', isLessThan: Timestamp.fromDate(now))
          .get();

      for (var doc in overdueWorkflows.docs) {
        await _firestore
            .collection('workflow_instances')
            .doc(doc.id)
            .update({'isOverdue': true});
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking overdue workflows: $e');
      }
    }
  }

  /// Get statistics for dashboard
  Future<Map<String, int>> getWorkflowStatistics() async {
    try {
      final stats = <String, int>{};

      // Total active workflows
      final activeWorkflows = await _firestore
          .collection('workflow_instances')
          .where('isCompleted', isEqualTo: false)
          .get();
      stats['active_workflows'] = activeWorkflows.docs.length;

      // Pending approvals
      final pendingApprovals = await _firestore
          .collection('approval_requests')
          .where('status', isEqualTo: 'pending')
          .get();
      stats['pending_approvals'] = pendingApprovals.docs.length;

      // Open exceptions
      final openExceptions = await _firestore
          .collection('exceptions')
          .where('status', isEqualTo: 'open')
          .get();
      stats['open_exceptions'] = openExceptions.docs.length;

      // Overdue workflows
      final overdueWorkflows = await _firestore
          .collection('workflow_instances')
          .where('isOverdue', isEqualTo: true)
          .get();
      stats['overdue_workflows'] = overdueWorkflows.docs.length;

      return stats;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting workflow statistics: $e');
      }
      return {};
    }
  }
}
