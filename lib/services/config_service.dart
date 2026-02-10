import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/config_models.dart';
import '../models/config_extended_models.dart';

/// Config service for loading and caching configuration data
class ConfigService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cached config data
  List<ConfigProduct>? _products;
  List<ConfigUCOGrade>? _ucoGrades;
  List<ConfigUCOBuybackRate>? _buybackRates;
  List<ConfigPaymentMethod>? _paymentMethods;
  Map<String, List<ConfigOrderStatus>>? _orderStatuses;
  Map<String, List<ConfigReason>>? _reasons;
  ConfigFulfillmentSettings? _fulfillmentSettings;
  List<ConfigWorkflowTemplate>? _workflowTemplates;
  List<ConfigPriceList>? _priceLists;

  // ============================================================
  // PRODUCTS
  // ============================================================

  /// Get all active products
  Future<List<ConfigProduct>> getProducts({bool forceRefresh = false}) async {
    if (_products != null && !forceRefresh) return _products!;

    try {
      final snapshot = await _firestore
          .collection('config_products')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      _products = snapshot.docs
          .map((doc) => ConfigProduct.fromFirestore(doc.data(), doc.id))
          .toList();

      return _products!;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading products: $e');
      }
      return [];
    }
  }

  /// Get product by ID
  Future<ConfigProduct?> getProductById(String productId) async {
    try {
      final doc = await _firestore
          .collection('config_products')
          .doc(productId)
          .get();

      if (!doc.exists) return null;
      return ConfigProduct.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading product: $e');
      }
      return null;
    }
  }

  /// Get products by category
  Future<List<ConfigProduct>> getProductsByCategory(String category) async {
    final products = await getProducts();
    return products.where((p) => p.category == category).toList();
  }

  // ============================================================
  // UCO GRADES & BUYBACK RATES
  // ============================================================

  /// Get all UCO grades (admin view shows all, not just active)
  Future<List<ConfigUCOGrade>> getUCOGrades({bool forceRefresh = false}) async {
    if (_ucoGrades != null && !forceRefresh) return _ucoGrades!;

    try {
      final snapshot = await _firestore
          .collection('config_uco_grades')
          .orderBy('gradeCode')
          .get();

      _ucoGrades = snapshot.docs
          .map((doc) => ConfigUCOGrade.fromFirestore(doc.data(), doc.id))
          .toList();

      return _ucoGrades!;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading UCO grades: $e');
      }
      return [];
    }
  }

  /// Add new UCO grade
  Future<String> addUCOGrade(ConfigUCOGrade grade) async {
    final docRef = await _firestore.collection('config_uco_grades').add(grade.toFirestore());
    _ucoGrades = null; // Clear cache
    return docRef.id;
  }

  /// Update UCO grade
  Future<void> updateUCOGrade(ConfigUCOGrade grade) async {
    await _firestore.collection('config_uco_grades').doc(grade.id).update(grade.toFirestore());
    _ucoGrades = null; // Clear cache
  }

  /// Delete UCO grade
  Future<void> deleteUCOGrade(String gradeId) async {
    await _firestore.collection('config_uco_grades').doc(gradeId).delete();
    _ucoGrades = null; // Clear cache
  }

  /// Get active buyback rates
  Future<List<ConfigUCOBuybackRate>> getBuybackRates({bool forceRefresh = false}) async {
    if (_buybackRates != null && !forceRefresh) return _buybackRates!;

    try {
      final snapshot = await _firestore
          .collection('config_uco_buyback_rates')
          .where('isActive', isEqualTo: true)
          .get();

      _buybackRates = snapshot.docs
          .map((doc) => ConfigUCOBuybackRate.fromFirestore(doc.data(), doc.id))
          .toList();

      return _buybackRates!;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading buyback rates: $e');
      }
      return [];
    }
  }

  /// Get current buyback rate for grade
  Future<double> getBuybackRateForGrade(String gradeId) async {
    final rates = await getBuybackRates();
    
    for (final rate in rates) {
      if (rate.gradeId == gradeId && rate.isValidNow()) {
        return rate.ratePerKg;
      }
    }
    
    return 0.0;
  }

  // ============================================================
  // PAYMENT METHODS
  // ============================================================

  /// Get all payment methods (admin view shows all, not just active)
  Future<List<ConfigPaymentMethod>> getPaymentMethods({bool forceRefresh = false}) async {
    if (_paymentMethods != null && !forceRefresh) return _paymentMethods!;

    try {
      final snapshot = await _firestore
          .collection('config_payment_methods')
          .get();

      _paymentMethods = snapshot.docs
          .map((doc) => ConfigPaymentMethod.fromFirestore(doc.data(), doc.id))
          .toList();

      return _paymentMethods!;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading payment methods: $e');
      }
      return [];
    }
  }

  /// Add new payment method
  Future<String> addPaymentMethod(ConfigPaymentMethod method) async {
    final docRef = await _firestore.collection('config_payment_methods').add(method.toFirestore());
    _paymentMethods = null; // Clear cache
    return docRef.id;
  }

  /// Update payment method
  Future<void> updatePaymentMethod(ConfigPaymentMethod method) async {
    await _firestore.collection('config_payment_methods').doc(method.id).update(method.toFirestore());
    _paymentMethods = null; // Clear cache
  }

  /// Delete payment method
  Future<void> deletePaymentMethod(String methodId) async {
    await _firestore.collection('config_payment_methods').doc(methodId).delete();
    _paymentMethods = null; // Clear cache
  }

  // ============================================================
  // ORDER STATUSES
  // ============================================================

  /// Get order statuses by type (sales | uco | return)
  Future<List<ConfigOrderStatus>> getOrderStatuses(
    String type, {
    bool forceRefresh = false,
  }) async {
    if (_orderStatuses != null && 
        _orderStatuses!.containsKey(type) && 
        !forceRefresh) {
      return _orderStatuses![type]!;
    }

    try {
      final snapshot = await _firestore
          .collection('config_order_statuses')
          .where('type', isEqualTo: type)
          .orderBy('sequence')
          .get();

      final statuses = snapshot.docs
          .map((doc) => ConfigOrderStatus.fromFirestore(doc.data(), doc.id))
          .toList();

      _orderStatuses ??= {};
      _orderStatuses![type] = statuses;

      return statuses;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading order statuses: $e');
      }
      return [];
    }
  }

  /// Add new order status
  Future<String> addOrderStatus(ConfigOrderStatus status) async {
    final docRef = await _firestore.collection('config_order_statuses').add(status.toFirestore());
    _orderStatuses = null; // Clear cache
    return docRef.id;
  }

  /// Update order status
  Future<void> updateOrderStatus(ConfigOrderStatus status) async {
    await _firestore.collection('config_order_statuses').doc(status.id).update(status.toFirestore());
    _orderStatuses = null; // Clear cache
  }

  /// Delete order status
  Future<void> deleteOrderStatus(String statusId) async {
    await _firestore.collection('config_order_statuses').doc(statusId).delete();
    _orderStatuses = null; // Clear cache
  }

  // ============================================================
  // REASONS
  // ============================================================

  /// Get reasons by type (cancel | return | reject_uco)
  Future<List<ConfigReason>> getReasons(
    String type, {
    bool forceRefresh = false,
  }) async {
    if (_reasons != null && 
        _reasons!.containsKey(type) && 
        !forceRefresh) {
      return _reasons![type]!;
    }

    try {
      final snapshot = await _firestore
          .collection('config_reasons')
          .where('type', isEqualTo: type)
          .where('isActive', isEqualTo: true)
          .orderBy('displayOrder')
          .get();

      final reasons = snapshot.docs
          .map((doc) => ConfigReason.fromFirestore(doc.data(), doc.id))
          .toList();

      _reasons ??= {};
      _reasons![type] = reasons;

      return reasons;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading reasons: $e');
      }
      return [];
    }
  }

  // ============================================================
  // FULFILLMENT SETTINGS
  // ============================================================

  /// Get fulfillment settings
  Future<ConfigFulfillmentSettings?> getFulfillmentSettings({bool forceRefresh = false}) async {
    if (_fulfillmentSettings != null && !forceRefresh) {
      return _fulfillmentSettings;
    }

    try {
      // Get the default/primary settings document
      final snapshot = await _firestore
          .collection('config_fulfillment_settings')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      _fulfillmentSettings = ConfigFulfillmentSettings.fromFirestore(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );

      return _fulfillmentSettings;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading fulfillment settings: $e');
      }
      return null;
    }
  }

  // ============================================================
  // WORKFLOW TEMPLATES
  // ============================================================

  /// Get workflow templates by domain
  Future<List<ConfigWorkflowTemplate>> getWorkflowTemplates(
    String domain, {
    bool forceRefresh = false,
  }) async {
    if (_workflowTemplates != null && !forceRefresh) {
      return _workflowTemplates!.where((t) => t.domain == domain).toList();
    }

    try {
      final snapshot = await _firestore
          .collection('config_workflow_templates')
          .where('domain', isEqualTo: domain)
          .where('isActive', isEqualTo: true)
          .get();

      final templates = snapshot.docs
          .map((doc) => ConfigWorkflowTemplate.fromFirestore(doc.data(), doc.id))
          .toList();

      _workflowTemplates ??= [];
      _workflowTemplates!.addAll(templates);

      return templates;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading workflow templates: $e');
      }
      return [];
    }
  }

  /// Get matching workflow template for order
  Future<ConfigWorkflowTemplate?> getMatchingWorkflowTemplate(
    String domain,
    Map<String, dynamic> orderData,
  ) async {
    final templates = await getWorkflowTemplates(domain);

    // Try to find matching template
    for (final template in templates) {
      if (template.matchesConditions(orderData)) {
        return template;
      }
    }

    // Fallback to default template
    try {
      return templates.firstWhere((t) => t.isDefault);
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // PRICE LISTS
  // ============================================================

  /// Get active price lists
  Future<List<ConfigPriceList>> getPriceLists({bool forceRefresh = false}) async {
    if (_priceLists != null && !forceRefresh) return _priceLists!;

    try {
      final snapshot = await _firestore
          .collection('config_price_lists')
          .where('isActive', isEqualTo: true)
          .get();

      _priceLists = snapshot.docs
          .map((doc) => ConfigPriceList.fromFirestore(doc.data(), doc.id))
          .toList();

      return _priceLists!;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading price lists: $e');
      }
      return [];
    }
  }

  /// Get price list for customer type
  Future<ConfigPriceList?> getPriceListForCustomerType(
    String customerType,
  ) async {
    final priceLists = await getPriceLists();

    // Find matching valid price list
    final validLists = priceLists
        .where((pl) => pl.customerType == customerType && pl.isValidNow())
        .toList();

    if (validLists.isEmpty) return null;

    // Return default first, or first valid
    try {
      return validLists.firstWhere((pl) => pl.isDefault);
    } catch (e) {
      return validLists.first;
    }
  }

  /// Get price for product
  Future<double> getProductPrice(
    String productId,
    String priceListId,
    double quantity,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('config_price_list_items')
          .where('priceListId', isEqualTo: priceListId)
          .where('productId', isEqualTo: productId)
          .get();

      for (final doc in snapshot.docs) {
        final item = ConfigPriceListItem.fromFirestore(doc.data(), doc.id);
        if (item.appliesToQuantity(quantity)) {
          return item.unitPrice;
        }
      }

      return 0.0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting product price: $e');
      }
      return 0.0;
    }
  }

  // ============================================================
  // CACHE MANAGEMENT
  // ============================================================

  /// Clear all cached config data
  void clearCache() {
    _products = null;
    _ucoGrades = null;
    _buybackRates = null;
    _paymentMethods = null;
    _orderStatuses = null;
    _reasons = null;
    _fulfillmentSettings = null;
    _workflowTemplates = null;
    _priceLists = null;
  }

  /// Refresh all config data
  Future<void> refreshAll() async {
    clearCache();
    await Future.wait([
      getProducts(forceRefresh: true),
      getUCOGrades(forceRefresh: true),
      getBuybackRates(forceRefresh: true),
      getPaymentMethods(forceRefresh: true),
      getFulfillmentSettings(forceRefresh: true),
      getPriceLists(forceRefresh: true),
    ]);
  }
}
