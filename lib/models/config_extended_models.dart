import 'package:cloud_firestore/cloud_firestore.dart';

/// Delivery/Collection slot configuration
class DeliverySlot {
  final String slotName;
  final String startTime;  // HH:mm format
  final String endTime;    // HH:mm format
  final int maxCapacity;

  DeliverySlot({
    required this.slotName,
    required this.startTime,
    required this.endTime,
    required this.maxCapacity,
  });

  factory DeliverySlot.fromMap(Map<String, dynamic> data) {
    return DeliverySlot(
      slotName: data['slotName'] as String? ?? '',
      startTime: data['startTime'] as String? ?? '09:00',
      endTime: data['endTime'] as String? ?? '17:00',
      maxCapacity: data['maxCapacity'] as int? ?? 10,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'slotName': slotName,
      'startTime': startTime,
      'endTime': endTime,
      'maxCapacity': maxCapacity,
    };
  }
}

/// Service area definition
class ServiceArea {
  final String areaCode;
  final String areaName;
  final List<String> provinces;
  final List<String> cities;
  final bool isActive;

  ServiceArea({
    required this.areaCode,
    required this.areaName,
    required this.provinces,
    required this.cities,
    required this.isActive,
  });

  factory ServiceArea.fromMap(Map<String, dynamic> data) {
    return ServiceArea(
      areaCode: data['areaCode'] as String? ?? '',
      areaName: data['areaName'] as String? ?? '',
      provinces: List<String>.from(data['provinces'] as List? ?? []),
      cities: List<String>.from(data['cities'] as List? ?? []),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'areaCode': areaCode,
      'areaName': areaName,
      'provinces': provinces,
      'cities': cities,
      'isActive': isActive,
    };
  }
}

/// Fulfillment settings configuration
class ConfigFulfillmentSettings {
  final String id;
  final List<DeliverySlot> deliverySlots;
  final List<DeliverySlot> collectionSlots;
  final List<ServiceArea> serviceAreas;
  final double minOrderAmount;
  final double deliveryFee;
  final double freeDeliveryThreshold;
  final int leadTimeDays;
  final bool allowSameDayDelivery;
  final Map<String, dynamic>? additionalSettings;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ConfigFulfillmentSettings({
    required this.id,
    required this.deliverySlots,
    required this.collectionSlots,
    required this.serviceAreas,
    required this.minOrderAmount,
    required this.deliveryFee,
    required this.freeDeliveryThreshold,
    required this.leadTimeDays,
    required this.allowSameDayDelivery,
    this.additionalSettings,
    required this.createdAt,
    this.updatedAt,
  });

  factory ConfigFulfillmentSettings.fromFirestore(Map<String, dynamic> data, String docId) {
    return ConfigFulfillmentSettings(
      id: docId,
      deliverySlots: (data['deliverySlots'] as List?)
              ?.map((e) => DeliverySlot.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      collectionSlots: (data['collectionSlots'] as List?)
              ?.map((e) => DeliverySlot.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      serviceAreas: (data['serviceAreas'] as List?)
              ?.map((e) => ServiceArea.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      minOrderAmount: (data['minOrderAmount'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (data['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      freeDeliveryThreshold: (data['freeDeliveryThreshold'] as num?)?.toDouble() ?? 100.0,
      leadTimeDays: data['leadTimeDays'] as int? ?? 1,
      allowSameDayDelivery: data['allowSameDayDelivery'] as bool? ?? false,
      additionalSettings: data['additionalSettings'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'deliverySlots': deliverySlots.map((s) => s.toMap()).toList(),
      'collectionSlots': collectionSlots.map((s) => s.toMap()).toList(),
      'serviceAreas': serviceAreas.map((a) => a.toMap()).toList(),
      'minOrderAmount': minOrderAmount,
      'deliveryFee': deliveryFee,
      'freeDeliveryThreshold': freeDeliveryThreshold,
      'leadTimeDays': leadTimeDays,
      'allowSameDayDelivery': allowSameDayDelivery,
      'additionalSettings': additionalSettings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  bool isServiceAreaActive(String province) {
    return serviceAreas.any(
      (area) => area.isActive && area.provinces.contains(province),
    );
  }

  ServiceArea? getServiceAreaForProvince(String province) {
    try {
      return serviceAreas.firstWhere(
        (area) => area.isActive && area.provinces.contains(province),
      );
    } catch (e) {
      return null;
    }
  }
}

/// Workflow step configuration
class WorkflowStepConfig {
  final int stepNumber;
  final String stepName;
  final String stepType;  // Approval | Task | SystemCheck
  final String? assignedRole;
  final bool autoAdvance;
  final List<String> requiredAttachments;
  final int? slaDays;

  WorkflowStepConfig({
    required this.stepNumber,
    required this.stepName,
    required this.stepType,
    this.assignedRole,
    required this.autoAdvance,
    required this.requiredAttachments,
    this.slaDays,
  });

  factory WorkflowStepConfig.fromMap(Map<String, dynamic> data) {
    return WorkflowStepConfig(
      stepNumber: data['stepNumber'] as int? ?? 0,
      stepName: data['stepName'] as String? ?? '',
      stepType: data['stepType'] as String? ?? 'Task',
      assignedRole: data['assignedRole'] as String?,
      autoAdvance: data['autoAdvance'] as bool? ?? false,
      requiredAttachments: List<String>.from(data['requiredAttachments'] as List? ?? []),
      slaDays: data['slaDays'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stepNumber': stepNumber,
      'stepName': stepName,
      'stepType': stepType,
      'assignedRole': assignedRole,
      'autoAdvance': autoAdvance,
      'requiredAttachments': requiredAttachments,
      'slaDays': slaDays,
    };
  }
}

/// Workflow template configuration
class ConfigWorkflowTemplate {
  final String id;
  final String domain;  // sales | uco | return | refund
  final String templateName;
  final String description;
  final Map<String, dynamic>? conditions;  // Matching criteria
  final List<WorkflowStepConfig> steps;
  final bool isActive;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ConfigWorkflowTemplate({
    required this.id,
    required this.domain,
    required this.templateName,
    required this.description,
    this.conditions,
    required this.steps,
    required this.isActive,
    required this.isDefault,
    required this.createdAt,
    this.updatedAt,
  });

  factory ConfigWorkflowTemplate.fromFirestore(Map<String, dynamic> data, String docId) {
    return ConfigWorkflowTemplate(
      id: docId,
      domain: data['domain'] as String? ?? '',
      templateName: data['templateName'] as String? ?? '',
      description: data['description'] as String? ?? '',
      conditions: data['conditions'] as Map<String, dynamic>?,
      steps: (data['steps'] as List?)
              ?.map((e) => WorkflowStepConfig.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      isActive: data['isActive'] as bool? ?? true,
      isDefault: data['isDefault'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'domain': domain,
      'templateName': templateName,
      'description': description,
      'conditions': conditions,
      'steps': steps.map((s) => s.toMap()).toList(),
      'isActive': isActive,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  bool matchesConditions(Map<String, dynamic> orderData) {
    if (conditions == null || conditions!.isEmpty) return isDefault;

    // Check customer type
    if (conditions!.containsKey('customerTypeIn')) {
      final allowedTypes = List<String>.from(conditions!['customerTypeIn'] as List);
      if (!allowedTypes.contains(orderData['customerType'])) {
        return false;
      }
    }

    // Check minimum amount
    if (conditions!.containsKey('minTotalAmount')) {
      final minAmount = conditions!['minTotalAmount'] as double;
      final orderAmount = orderData['totalAmount'] as double? ?? 0.0;
      if (orderAmount < minAmount) return false;
    }

    // Check payment method
    if (conditions!.containsKey('requiresCOD')) {
      final requiresCOD = conditions!['requiresCOD'] as bool;
      final isCOD = orderData['paymentMethod'] == 'COD';
      if (requiresCOD != isCOD) return false;
    }

    // Check service area
    if (conditions!.containsKey('serviceAreaIn')) {
      final allowedAreas = List<String>.from(conditions!['serviceAreaIn'] as List);
      if (!allowedAreas.contains(orderData['serviceArea'])) {
        return false;
      }
    }

    return true;
  }
}

/// Price list configuration
class ConfigPriceList {
  final String id;
  final String code;
  final String name;
  final String description;
  final String customerType;  // B2C | B2B
  final DateTime validFrom;
  final DateTime? validUntil;
  final bool isActive;
  final bool isDefault;
  final DateTime createdAt;

  ConfigPriceList({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.customerType,
    required this.validFrom,
    this.validUntil,
    required this.isActive,
    required this.isDefault,
    required this.createdAt,
  });

  factory ConfigPriceList.fromFirestore(Map<String, dynamic> data, String docId) {
    return ConfigPriceList(
      id: docId,
      code: data['code'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      customerType: data['customerType'] as String? ?? 'B2C',
      validFrom: (data['validFrom'] as Timestamp?)?.toDate() ?? DateTime.now(),
      validUntil: (data['validUntil'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] as bool? ?? true,
      isDefault: data['isDefault'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'customerType': customerType,
      'validFrom': Timestamp.fromDate(validFrom),
      'validUntil': validUntil != null ? Timestamp.fromDate(validUntil!) : null,
      'isActive': isActive,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool isValidNow() {
    final now = DateTime.now();
    return now.isAfter(validFrom) && 
           (validUntil == null || now.isBefore(validUntil!));
  }
}

/// Price list item configuration
class ConfigPriceListItem {
  final String id;
  final String priceListId;
  final String productId;
  final double unitPrice;
  final String currency;
  final double? minQuantity;
  final double? maxQuantity;
  final DateTime createdAt;

  ConfigPriceListItem({
    required this.id,
    required this.priceListId,
    required this.productId,
    required this.unitPrice,
    required this.currency,
    this.minQuantity,
    this.maxQuantity,
    required this.createdAt,
  });

  factory ConfigPriceListItem.fromFirestore(Map<String, dynamic> data, String docId) {
    return ConfigPriceListItem(
      id: docId,
      priceListId: data['priceListId'] as String? ?? '',
      productId: data['productId'] as String? ?? '',
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'USD',
      minQuantity: (data['minQuantity'] as num?)?.toDouble(),
      maxQuantity: (data['maxQuantity'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'priceListId': priceListId,
      'productId': productId,
      'unitPrice': unitPrice,
      'currency': currency,
      'minQuantity': minQuantity,
      'maxQuantity': maxQuantity,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool appliesToQuantity(double quantity) {
    if (minQuantity != null && quantity < minQuantity!) return false;
    if (maxQuantity != null && quantity > maxQuantity!) return false;
    return true;
  }
}
