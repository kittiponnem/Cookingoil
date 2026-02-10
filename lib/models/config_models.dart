import 'package:cloud_firestore/cloud_firestore.dart';

/// Product catalog master data configuration
class ConfigProduct {
  final String id;
  final String sku;
  final String name;
  final String description;
  final String category;
  final String uom;  // Unit of measure (L, kg, bottle, etc.)
  final double packSize;
  final String? imageUrl;
  final bool isActive;
  final Map<String, dynamic>? specifications;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdByUid;

  ConfigProduct({
    required this.id,
    required this.sku,
    required this.name,
    required this.description,
    required this.category,
    required this.uom,
    required this.packSize,
    this.imageUrl,
    required this.isActive,
    this.specifications,
    List<String>? tags,
    required this.createdAt,
    this.updatedAt,
    this.createdByUid,
  }) : tags = tags ?? [];

  factory ConfigProduct.fromFirestore(Map<String, dynamic> data, String docId) {
    return ConfigProduct(
      id: docId,
      sku: data['sku'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      uom: data['uom'] as String? ?? 'L',
      packSize: (data['packSize'] as num?)?.toDouble() ?? 1.0,
      imageUrl: data['imageUrl'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      specifications: data['specifications'] as Map<String, dynamic>?,
      tags: List<String>.from(data['tags'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdByUid: data['createdByUid'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sku': sku,
      'name': name,
      'description': description,
      'category': category,
      'uom': uom,
      'packSize': packSize,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'specifications': specifications,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdByUid': createdByUid,
    };
  }

  String get displayName => '$name ($packSize$uom)';
}

/// UCO (Used Cooking Oil) grade configuration
class ConfigUCOGrade {
  final String id;
  final String gradeCode;
  final String gradeName;
  final String description;
  final double minQualityScore;
  final double maxQualityScore;
  final String? colorRange;
  final bool isActive;
  final DateTime createdAt;

  ConfigUCOGrade({
    required this.id,
    required this.gradeCode,
    required this.gradeName,
    required this.description,
    required this.minQualityScore,
    required this.maxQualityScore,
    this.colorRange,
    required this.isActive,
    required this.createdAt,
  });

  factory ConfigUCOGrade.fromFirestore(Map<String, dynamic> data, String docId) {
    return ConfigUCOGrade(
      id: docId,
      gradeCode: data['gradeCode'] as String? ?? '',
      gradeName: data['gradeName'] as String? ?? '',
      description: data['description'] as String? ?? '',
      minQualityScore: (data['minQualityScore'] as num?)?.toDouble() ?? 0.0,
      maxQualityScore: (data['maxQualityScore'] as num?)?.toDouble() ?? 100.0,
      colorRange: data['colorRange'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'gradeCode': gradeCode,
      'gradeName': gradeName,
      'description': description,
      'minQualityScore': minQualityScore,
      'maxQualityScore': maxQualityScore,
      'colorRange': colorRange,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// UCO buyback rate configuration
class ConfigUCOBuybackRate {
  final String id;
  final String gradeId;
  final double ratePerKg;
  final String currency;
  final String? locationId;
  final DateTime validFrom;
  final DateTime? validUntil;
  final bool isActive;
  final DateTime createdAt;

  ConfigUCOBuybackRate({
    required this.id,
    required this.gradeId,
    required this.ratePerKg,
    required this.currency,
    this.locationId,
    required this.validFrom,
    this.validUntil,
    required this.isActive,
    required this.createdAt,
  });

  factory ConfigUCOBuybackRate.fromFirestore(Map<String, dynamic> data, String docId) {
    return ConfigUCOBuybackRate(
      id: docId,
      gradeId: data['gradeId'] as String? ?? '',
      ratePerKg: (data['ratePerKg'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'USD',
      locationId: data['locationId'] as String?,
      validFrom: (data['validFrom'] as Timestamp?)?.toDate() ?? DateTime.now(),
      validUntil: (data['validUntil'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'gradeId': gradeId,
      'ratePerKg': ratePerKg,
      'currency': currency,
      'locationId': locationId,
      'validFrom': Timestamp.fromDate(validFrom),
      'validUntil': validUntil != null ? Timestamp.fromDate(validUntil!) : null,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool isValidNow() {
    final now = DateTime.now();
    return now.isAfter(validFrom) && 
           (validUntil == null || now.isBefore(validUntil!));
  }
}

/// Payment method configuration
class ConfigPaymentMethod {
  final String id;
  final String code;
  final String name;
  final String description;
  final bool requiresApproval;
  final bool isOnlinePayment;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;

  ConfigPaymentMethod({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.requiresApproval,
    required this.isOnlinePayment,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
  });

  factory ConfigPaymentMethod.fromFirestore(Map<String, dynamic> data, String docId) {
    return ConfigPaymentMethod(
      id: docId,
      code: data['code'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      requiresApproval: data['requiresApproval'] as bool? ?? false,
      isOnlinePayment: data['isOnlinePayment'] as bool? ?? false,
      displayOrder: data['displayOrder'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'requiresApproval': requiresApproval,
      'isOnlinePayment': isOnlinePayment,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Order status configuration
class ConfigOrderStatus {
  final String id;
  final String type;  // sales | uco | return
  final String code;
  final String name;
  final String description;
  final int sequence;
  final bool isTerminal;
  final String? color;
  final String? icon;
  final bool isActive;
  final DateTime createdAt;

  ConfigOrderStatus({
    required this.id,
    required this.type,
    required this.code,
    required this.name,
    required this.description,
    required this.sequence,
    required this.isTerminal,
    this.color,
    this.icon,
    required this.isActive,
    required this.createdAt,
  });

  factory ConfigOrderStatus.fromFirestore(Map<String, dynamic> data, String docId) {
    return ConfigOrderStatus(
      id: docId,
      type: data['type'] as String? ?? 'sales',
      code: data['code'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      sequence: data['sequence'] as int? ?? 0,
      isTerminal: data['isTerminal'] as bool? ?? false,
      color: data['color'] as String?,
      icon: data['icon'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'code': code,
      'name': name,
      'description': description,
      'sequence': sequence,
      'isTerminal': isTerminal,
      'color': color,
      'icon': icon,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Reason codes for cancellations, returns, rejections
class ConfigReason {
  final String id;
  final String type;  // cancel | return | reject_uco
  final String code;
  final String name;
  final String description;
  final bool requiresEvidence;
  final bool requiresComment;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;

  ConfigReason({
    required this.id,
    required this.type,
    required this.code,
    required this.name,
    required this.description,
    required this.requiresEvidence,
    required this.requiresComment,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
  });

  factory ConfigReason.fromFirestore(Map<String, dynamic> data, String docId) {
    return ConfigReason(
      id: docId,
      type: data['type'] as String? ?? '',
      code: data['code'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      requiresEvidence: data['requiresEvidence'] as bool? ?? false,
      requiresComment: data['requiresComment'] as bool? ?? true,
      displayOrder: data['displayOrder'] as int? ?? 0,
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'code': code,
      'name': name,
      'description': description,
      'requiresEvidence': requiresEvidence,
      'requiresComment': requiresComment,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
