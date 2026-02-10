import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String sku;
  final String name;
  final String uom;
  final String packSize;
  final String? imageUrl;
  final String category;
  final bool isActive;
  final DateTime updatedAt;

  Product({
    required this.sku,
    required this.name,
    required this.uom,
    required this.packSize,
    this.imageUrl,
    required this.category,
    required this.isActive,
    required this.updatedAt,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      sku: data['sku'] as String? ?? '',
      name: data['name'] as String? ?? '',
      uom: data['uom'] as String? ?? 'L',
      packSize: data['packSize'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      category: data['category'] as String? ?? 'General',
      isActive: data['isActive'] as bool? ?? true,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sku': sku,
      'name': name,
      'uom': uom,
      'packSize': packSize,
      'imageUrl': imageUrl,
      'category': category,
      'isActive': isActive,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
