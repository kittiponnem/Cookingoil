import 'package:cloud_firestore/cloud_firestore.dart';

/// System Settings - Global configuration parameters
class SystemSetting {
  final String key;
  final String? valueString;
  final double? valueNumber;
  final bool? valueBool;
  final String description;
  final String category; // general, security, workflow, logistics, uco, notification
  final DateTime updatedAt;
  final String updatedBy;

  SystemSetting({
    required this.key,
    this.valueString,
    this.valueNumber,
    this.valueBool,
    required this.description,
    required this.category,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory SystemSetting.fromFirestore(Map<String, dynamic> data, String docId) {
    return SystemSetting(
      key: data['key'] ?? docId,
      valueString: data['valueString'],
      valueNumber: data['valueNumber']?.toDouble(),
      valueBool: data['valueBool'],
      description: data['description'] ?? '',
      category: data['category'] ?? 'general',
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      updatedBy: data['updatedBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'key': key,
      'valueString': valueString,
      'valueNumber': valueNumber,
      'valueBool': valueBool,
      'description': description,
      'category': category,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
    };
  }

  dynamic get value {
    if (valueString != null) return valueString;
    if (valueNumber != null) return valueNumber;
    if (valueBool != null) return valueBool;
    return null;
  }

  String get displayValue {
    if (valueString != null) return valueString!;
    if (valueNumber != null) return valueNumber.toString();
    if (valueBool != null) return valueBool! ? 'Yes' : 'No';
    return 'Not Set';
  }
}

/// Workflow Template Step
class WorkflowTemplateStep {
  final int stepNo;
  final String approverType; // role, user, manager, conditional
  final String approverValue;
  final int slaHours;
  final String? escalationRole;
  final Map<String, dynamic> conditions;

  WorkflowTemplateStep({
    required this.stepNo,
    required this.approverType,
    required this.approverValue,
    required this.slaHours,
    this.escalationRole,
    this.conditions = const {},
  });

  factory WorkflowTemplateStep.fromMap(Map<String, dynamic> data) {
    return WorkflowTemplateStep(
      stepNo: data['stepNo'] ?? 0,
      approverType: data['approverType'] ?? 'role',
      approverValue: data['approverValue'] ?? '',
      slaHours: data['slaHours'] ?? 24,
      escalationRole: data['escalationRole'],
      conditions: data['conditions'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stepNo': stepNo,
      'approverType': approverType,
      'approverValue': approverValue,
      'slaHours': slaHours,
      'escalationRole': escalationRole,
      'conditions': conditions,
    };
  }
}

/// Workflow Template - Versioned workflow definitions
class WorkflowTemplate {
  final String id;
  final String templateId;
  final String name;
  final String domain; // sales, pickup, return, approval
  final int version;
  final bool isActive;
  final List<WorkflowTemplateStep> steps;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkflowTemplate({
    required this.id,
    required this.templateId,
    required this.name,
    required this.domain,
    required this.version,
    required this.isActive,
    required this.steps,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkflowTemplate.fromFirestore(Map<String, dynamic> data, String docId) {
    final stepsList = (data['steps'] as List<dynamic>? ?? [])
        .map((step) => WorkflowTemplateStep.fromMap(step as Map<String, dynamic>))
        .toList();

    return WorkflowTemplate(
      id: docId,
      templateId: data['templateId'] ?? '',
      name: data['name'] ?? '',
      domain: data['domain'] ?? '',
      version: data['version'] ?? 1,
      isActive: data['isActive'] ?? false,
      steps: stepsList,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'templateId': templateId,
      'name': name,
      'domain': domain,
      'version': version,
      'isActive': isActive,
      'steps': steps.map((step) => step.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String get displayName => '$name v$version';
}

/// Routing Rule - Conditional routing for workflows
class RoutingRule {
  final String id;
  final String ruleId;
  final String domain;
  final int priority;
  final Map<String, dynamic> conditions;
  final String? assignToRole;
  final String? assignToUser;
  final bool isActive;
  final DateTime updatedAt;

  RoutingRule({
    required this.id,
    required this.ruleId,
    required this.domain,
    required this.priority,
    required this.conditions,
    this.assignToRole,
    this.assignToUser,
    required this.isActive,
    required this.updatedAt,
  });

  factory RoutingRule.fromFirestore(Map<String, dynamic> data, String docId) {
    return RoutingRule(
      id: docId,
      ruleId: data['ruleId'] ?? '',
      domain: data['domain'] ?? '',
      priority: data['priority'] ?? 0,
      conditions: data['conditions'] ?? {},
      assignToRole: data['assignToRole'],
      assignToUser: data['assignToUser'],
      isActive: data['isActive'] ?? false,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ruleId': ruleId,
      'domain': domain,
      'priority': priority,
      'conditions': conditions,
      'assignToRole': assignToRole,
      'assignToUser': assignToUser,
      'isActive': isActive,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String get conditionsDisplay {
    return conditions.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
  }
}

/// UCO Incentive - Zone-based UCO pricing and rewards
class UCOIncentive {
  final String id;
  final String zone;
  final String customerType; // B2B, B2C
  final double minQty;
  final double cashRatePerKg;
  final double creditRatePerKg;
  final double pointsPerKg;
  final Map<String, double> qualityMultipliers;
  final bool isActive;
  final DateTime updatedAt;

  UCOIncentive({
    required this.id,
    required this.zone,
    required this.customerType,
    required this.minQty,
    required this.cashRatePerKg,
    required this.creditRatePerKg,
    required this.pointsPerKg,
    required this.qualityMultipliers,
    required this.isActive,
    required this.updatedAt,
  });

  factory UCOIncentive.fromFirestore(Map<String, dynamic> data, String docId) {
    final qualityMult = <String, double>{};
    (data['qualityMultipliers'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      qualityMult[k] = (v as num).toDouble();
    });

    return UCOIncentive(
      id: docId,
      zone: data['zone'] ?? '',
      customerType: data['customerType'] ?? 'B2C',
      minQty: (data['minQty'] as num?)?.toDouble() ?? 0.0,
      cashRatePerKg: (data['cashRatePerKg'] as num?)?.toDouble() ?? 0.0,
      creditRatePerKg: (data['creditRatePerKg'] as num?)?.toDouble() ?? 0.0,
      pointsPerKg: (data['pointsPerKg'] as num?)?.toDouble() ?? 0.0,
      qualityMultipliers: qualityMult,
      isActive: data['isActive'] ?? false,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'zone': zone,
      'customerType': customerType,
      'minQty': minQty,
      'cashRatePerKg': cashRatePerKg,
      'creditRatePerKg': creditRatePerKg,
      'pointsPerKg': pointsPerKg,
      'qualityMultipliers': qualityMultipliers,
      'isActive': isActive,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String get displayName => '$zone - $customerType (≥${minQty}kg)';
}

/// Delivery Slot - Zone-based delivery capacity management
class DeliverySlot {
  final String id;
  final String zone;
  final int maxCapacity;
  final String timeWindowStart; // HH:mm format
  final String timeWindowEnd; // HH:mm format
  final bool isActive;
  final int bufferMinutes;
  final DateTime updatedAt;

  DeliverySlot({
    required this.id,
    required this.zone,
    required this.maxCapacity,
    required this.timeWindowStart,
    required this.timeWindowEnd,
    required this.isActive,
    required this.bufferMinutes,
    required this.updatedAt,
  });

  factory DeliverySlot.fromFirestore(Map<String, dynamic> data, String docId) {
    return DeliverySlot(
      id: docId,
      zone: data['zone'] ?? '',
      maxCapacity: data['maxCapacity'] ?? 10,
      timeWindowStart: data['timeWindowStart'] ?? '08:00',
      timeWindowEnd: data['timeWindowEnd'] ?? '17:00',
      isActive: data['isActive'] ?? false,
      bufferMinutes: data['bufferMinutes'] ?? 30,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'zone': zone,
      'maxCapacity': maxCapacity,
      'timeWindowStart': timeWindowStart,
      'timeWindowEnd': timeWindowEnd,
      'isActive': isActive,
      'bufferMinutes': bufferMinutes,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String get displayName => '$zone: $timeWindowStart - $timeWindowEnd';
  String get timeWindow => '$timeWindowStart - $timeWindowEnd';
}

/// Notification Template - Multi-channel notification templates
class NotificationTemplate {
  final String id;
  final String templateKey;
  final String channel; // email, push, inApp
  final String? subjectTemplate;
  final String bodyTemplate;
  final bool isActive;
  final DateTime updatedAt;

  NotificationTemplate({
    required this.id,
    required this.templateKey,
    required this.channel,
    this.subjectTemplate,
    required this.bodyTemplate,
    required this.isActive,
    required this.updatedAt,
  });

  factory NotificationTemplate.fromFirestore(Map<String, dynamic> data, String docId) {
    return NotificationTemplate(
      id: docId,
      templateKey: data['templateKey'] ?? '',
      channel: data['channel'] ?? 'email',
      subjectTemplate: data['subjectTemplate'],
      bodyTemplate: data['bodyTemplate'] ?? '',
      isActive: data['isActive'] ?? false,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'templateKey': templateKey,
      'channel': channel,
      'subjectTemplate': subjectTemplate,
      'bodyTemplate': bodyTemplate,
      'isActive': isActive,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String get displayName => '$templateKey ($channel)';

  /// Replace placeholders in template
  String? renderSubject(Map<String, String> variables) {
    if (subjectTemplate == null) return null;
    String result = subjectTemplate!;
    variables.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value);
    });
    return result;
  }

  /// Replace placeholders in body
  String renderBody(Map<String, String> variables) {
    String result = bodyTemplate;
    variables.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value);
    });
    return result;
  }
}

/// Status Sequence - Domain-specific status flow definitions
class StatusSequence {
  final String id;
  final String domain;
  final List<String> statuses;
  final bool allowReopen;
  final List<String> terminalStatuses;
  final DateTime updatedAt;

  StatusSequence({
    required this.id,
    required this.domain,
    required this.statuses,
    required this.allowReopen,
    required this.terminalStatuses,
    required this.updatedAt,
  });

  factory StatusSequence.fromFirestore(Map<String, dynamic> data, String docId) {
    return StatusSequence(
      id: docId,
      domain: data['domain'] ?? '',
      statuses: List<String>.from(data['statuses'] ?? []),
      allowReopen: data['allowReopen'] ?? false,
      terminalStatuses: List<String>.from(data['terminalStatuses'] ?? []),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'domain': domain,
      'statuses': statuses,
      'allowReopen': allowReopen,
      'terminalStatuses': terminalStatuses,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool isTerminal(String status) => terminalStatuses.contains(status);

  String? getNextStatus(String currentStatus) {
    final index = statuses.indexOf(currentStatus);
    if (index == -1 || index >= statuses.length - 1) return null;
    return statuses[index + 1];
  }

  bool canTransition(String from, String to) {
    if (isTerminal(from) && !allowReopen) return false;
    return statuses.contains(to);
  }
}
