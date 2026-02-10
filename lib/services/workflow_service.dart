import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/workflow_models.dart';
import '../models/config_extended_models.dart';
import '../models/user_model_enhanced.dart';
import 'config_service.dart';

/// Workflow engine service for managing workflow execution
class WorkflowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ConfigService _configService = ConfigService();

  // ============================================================
  // WORKFLOW INSTANCE MANAGEMENT
  // ============================================================

  /// Start workflow for order
  Future<WorkflowInstance> startWorkflow({
    required String domain,
    required String orderType,
    required String orderId,
    required String startedByUserId,
    required Map<String, dynamic> orderData,
  }) async {
    try {
      // Get matching workflow template
      final template = await _configService.getMatchingWorkflowTemplate(
        domain,
        orderData,
      );

      if (template == null) {
        throw Exception('No workflow template found for $domain');
      }

      // Calculate initial SLA
      final firstStep = template.steps.isNotEmpty ? template.steps.first : null;
      final slaDueAt = firstStep?.slaDays != null
          ? DateTime.now().add(Duration(days: firstStep!.slaDays!))
          : null;

      // Create workflow instance
      final instance = WorkflowInstance(
        id: '',
        domain: domain,
        orderType: orderType,
        orderId: orderId,
        templateId: template.id,
        status: WorkflowStatus.inProgress,
        currentStep: 1,
        slaDueAt: slaDueAt,
        startedByUserId: startedByUserId,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('workflow_instances')
          .add(instance.toFirestore());

      // Create workflow steps from template
      for (final stepConfig in template.steps) {
        await _createWorkflowStep(
          workflowInstanceId: docRef.id,
          stepConfig: stepConfig,
          template: template,
        );
      }

      return instance.copyWith().copyWith();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error starting workflow: $e');
      }
      rethrow;
    }
  }

  /// Create workflow step from config
  Future<void> _createWorkflowStep({
    required String workflowInstanceId,
    required WorkflowStepConfig stepConfig,
    required ConfigWorkflowTemplate template,
  }) async {
    final slaDueAt = stepConfig.slaDays != null
        ? DateTime.now().add(Duration(days: stepConfig.slaDays!))
        : null;

    final step = WorkflowStep(
      id: '',
      workflowInstanceId: workflowInstanceId,
      stepNumber: stepConfig.stepNumber,
      stepName: stepConfig.stepName,
      stepType: stepConfig.stepType,
      assignedRole: stepConfig.assignedRole,
      decision: StepDecision.pending,
      slaDueAt: slaDueAt,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('workflow_steps').add(step.toFirestore());
  }

  /// Get workflow instance
  Future<WorkflowInstance?> getWorkflowInstance(String instanceId) async {
    try {
      final doc = await _firestore
          .collection('workflow_instances')
          .doc(instanceId)
          .get();

      if (!doc.exists) return null;
      return WorkflowInstance.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting workflow instance: $e');
      }
      return null;
    }
  }

  /// Get workflow by order
  Future<WorkflowInstance?> getWorkflowByOrder(String orderId) async {
    try {
      final snapshot = await _firestore
          .collection('workflow_instances')
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return WorkflowInstance.fromFirestore(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting workflow by order: $e');
      }
      return null;
    }
  }

  // ============================================================
  // WORKFLOW STEP MANAGEMENT
  // ============================================================

  /// Get workflow steps
  Future<List<WorkflowStep>> getWorkflowSteps(String instanceId) async {
    try {
      final snapshot = await _firestore
          .collection('workflow_steps')
          .where('workflowInstanceId', isEqualTo: instanceId)
          .orderBy('stepNumber')
          .get();

      return snapshot.docs
          .map((doc) => WorkflowStep.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting workflow steps: $e');
      }
      return [];
    }
  }

  /// Get current step
  Future<WorkflowStep?> getCurrentStep(String instanceId) async {
    try {
      final instance = await getWorkflowInstance(instanceId);
      if (instance == null) return null;

      final snapshot = await _firestore
          .collection('workflow_steps')
          .where('workflowInstanceId', isEqualTo: instanceId)
          .where('stepNumber', isEqualTo: instance.currentStep)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return WorkflowStep.fromFirestore(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting current step: $e');
      }
      return null;
    }
  }

  /// Get pending steps for user
  Future<List<WorkflowStep>> getPendingStepsForUser(
    String userId,
    String userRole,
  ) async {
    try {
      // Get steps assigned to user
      final userSteps = await _firestore
          .collection('workflow_steps')
          .where('assignedUserId', isEqualTo: userId)
          .where('decision', isEqualTo: 'pending')
          .get();

      // Get steps assigned to user's role
      final roleSteps = await _firestore
          .collection('workflow_steps')
          .where('assignedRole', isEqualTo: userRole)
          .where('decision', isEqualTo: 'pending')
          .get();

      final allSteps = <WorkflowStep>[];
      
      for (final doc in userSteps.docs) {
        allSteps.add(WorkflowStep.fromFirestore(doc.data(), doc.id));
      }
      
      for (final doc in roleSteps.docs) {
        final step = WorkflowStep.fromFirestore(doc.data(), doc.id);
        if (step.assignedUserId == null) {
          allSteps.add(step);
        }
      }

      return allSteps;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting pending steps: $e');
      }
      return [];
    }
  }

  // ============================================================
  // APPROVAL ACTIONS
  // ============================================================

  /// Check if user can approve/reject step
  bool canUserTakeAction(WorkflowStep step, UserModel user) {
    if (!step.isPending) return false;

    // Specific user assignment
    if (step.assignedUserId != null) {
      return step.assignedUserId == user.uid;
    }

    // Role-based assignment
    if (step.assignedRole != null) {
      final roleString = _userRoleToString(user.role);
      return step.assignedRole == roleString;
    }

    return false;
  }

  /// Approve workflow step
  Future<bool> approveStep({
    required String stepId,
    required String userId,
    required UserModel user,
    String? comments,
    List<String>? attachments,
  }) async {
    try {
      final stepDoc = await _firestore.collection('workflow_steps').doc(stepId).get();
      
      if (!stepDoc.exists) {
        throw Exception('Step not found');
      }

      final step = WorkflowStep.fromFirestore(stepDoc.data()!, stepDoc.id);

      // Check permission
      if (!canUserTakeAction(step, user)) {
        throw Exception('User does not have permission to approve this step');
      }

      // Update step
      await _firestore.collection('workflow_steps').doc(stepId).update({
        'decision': 'approved',
        'decisionByUserId': userId,
        'decisionAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
        'comments': comments,
        'attachments': attachments ?? step.attachments,
      });

      // Advance workflow
      await _advanceWorkflow(step.workflowInstanceId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error approving step: $e');
      }
      return false;
    }
  }

  /// Reject workflow step
  Future<bool> rejectStep({
    required String stepId,
    required String userId,
    required UserModel user,
    required String comments,
    List<String>? attachments,
  }) async {
    try {
      final stepDoc = await _firestore.collection('workflow_steps').doc(stepId).get();
      
      if (!stepDoc.exists) {
        throw Exception('Step not found');
      }

      final step = WorkflowStep.fromFirestore(stepDoc.data()!, stepDoc.id);

      // Check permission
      if (!canUserTakeAction(step, user)) {
        throw Exception('User does not have permission to reject this step');
      }

      // Update step
      await _firestore.collection('workflow_steps').doc(stepId).update({
        'decision': 'rejected',
        'decisionByUserId': userId,
        'decisionAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
        'comments': comments,
        'attachments': attachments ?? step.attachments,
      });

      // Fail workflow
      await _firestore
          .collection('workflow_instances')
          .doc(step.workflowInstanceId)
          .update({
        'status': 'failed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error rejecting step: $e');
      }
      return false;
    }
  }

  /// Advance workflow to next step
  Future<void> _advanceWorkflow(String instanceId) async {
    try {
      final instance = await getWorkflowInstance(instanceId);
      if (instance == null) return;

      final steps = await getWorkflowSteps(instanceId);
      final nextStep = instance.currentStep + 1;

      // Check if workflow is complete
      if (nextStep > steps.length) {
        await _firestore.collection('workflow_instances').doc(instanceId).update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      // Find next step SLA
      final nextStepConfig = steps.firstWhere((s) => s.stepNumber == nextStep);
      final slaDueAt = nextStepConfig.slaDueAt;

      // Update to next step
      await _firestore.collection('workflow_instances').doc(instanceId).update({
        'currentStep': nextStep,
        'slaDueAt': slaDueAt != null ? Timestamp.fromDate(slaDueAt) : null,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error advancing workflow: $e');
      }
    }
  }

  /// Cancel workflow
  Future<bool> cancelWorkflow({
    required String instanceId,
    required String userId,
    required String reason,
  }) async {
    try {
      await _firestore.collection('workflow_instances').doc(instanceId).update({
        'status': 'cancelled',
        'completedAt': FieldValue.serverTimestamp(),
        'metadata': {
          'cancelledByUserId': userId,
          'cancelReason': reason,
          'cancelledAt': FieldValue.serverTimestamp(),
        },
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error cancelling workflow: $e');
      }
      return false;
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  String _userRoleToString(UserRole role) {
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

  /// Get workflow statistics
  Future<Map<String, int>> getWorkflowStats() async {
    try {
      final snapshot = await _firestore.collection('workflow_instances').get();
      
      final stats = <String, int>{
        'total': snapshot.docs.length,
        'pending': 0,
        'in_progress': 0,
        'completed': 0,
        'overdue': 0,
      };

      for (final doc in snapshot.docs) {
        final instance = WorkflowInstance.fromFirestore(doc.data(), doc.id);
        
        if (instance.status == WorkflowStatus.pending) {
          stats['pending'] = (stats['pending'] ?? 0) + 1;
        } else if (instance.status == WorkflowStatus.inProgress) {
          stats['in_progress'] = (stats['in_progress'] ?? 0) + 1;
        } else if (instance.status == WorkflowStatus.completed) {
          stats['completed'] = (stats['completed'] ?? 0) + 1;
        }
        
        if (instance.isOverdue) {
          stats['overdue'] = (stats['overdue'] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting workflow stats: $e');
      }
      return {};
    }
  }
}
