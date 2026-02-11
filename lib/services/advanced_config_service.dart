import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/advanced_config_models.dart';

/// Advanced Config Service - Manages enterprise configuration with caching
class AdvancedConfigService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Caches
  Map<String, SystemSetting>? _systemSettings;
  List<WorkflowTemplate>? _workflowTemplates;
  List<RoutingRule>? _routingRules;
  List<UCOIncentive>? _ucoIncentives;
  List<DeliverySlot>? _deliverySlots;
  List<NotificationTemplate>? _notificationTemplates;
  List<StatusSequence>? _statusSequences;

  DateTime? _lastRefresh;
  Timer? _autoRefreshTimer;

  // Auto-refresh every 5 minutes
  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      refreshAllConfig();
    });
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
  }

  // ==================== SYSTEM SETTINGS ====================

  Future<Map<String, SystemSetting>> getSystemSettings({bool forceRefresh = false}) async {
    if (_systemSettings != null && !forceRefresh) return _systemSettings!;

    try {
      final snapshot = await _firestore.collection('config_system_settings').get();
      _systemSettings = {};
      for (var doc in snapshot.docs) {
        final setting = SystemSetting.fromFirestore(doc.data(), doc.id);
        _systemSettings![setting.key] = setting;
      }
      _lastRefresh = DateTime.now();
      return _systemSettings!;
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading system settings: $e');
      return {};
    }
  }

  // Convenience method to get all settings as a list
  Future<List<SystemSetting>> getAllSystemSettings({bool forceRefresh = false}) async {
    final settingsMap = await getSystemSettings(forceRefresh: forceRefresh);
    return settingsMap.values.toList();
  }

  Future<SystemSetting?> getSystemSetting(String key) async {
    final settings = await getSystemSettings();
    return settings[key];
  }

  Future<void> updateSystemSetting(SystemSetting setting) async {
    try {
      await _firestore
          .collection('config_system_settings')
          .doc(setting.key)
          .set(setting.toFirestore());
      _systemSettings = null; // Invalidate cache
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating system setting: $e');
      rethrow;
    }
  }

  Future<void> saveSystemSetting(SystemSetting setting) async {
    try {
      await _firestore
          .collection('config_system_settings')
          .doc(setting.key)
          .set(setting.toFirestore());
      _systemSettings = null; // Invalidate cache
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving system setting: $e');
      rethrow;
    }
  }

  Future<void> deleteSystemSetting(String key) async {
    try {
      await _firestore.collection('config_system_settings').doc(key).delete();
      _systemSettings = null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting system setting: $e');
      rethrow;
    }
  }

  // ==================== WORKFLOW TEMPLATES ====================

  // ==================== WORKFLOW TEMPLATES ====================

  Future<List<WorkflowTemplate>> getAllWorkflowTemplates({bool forceRefresh = false}) async {
    return await getWorkflowTemplates(forceRefresh: forceRefresh);
  }

  Future<List<WorkflowTemplate>> getWorkflowTemplates({bool forceRefresh = false}) async {
    if (_workflowTemplates != null && !forceRefresh) return _workflowTemplates!;

    try {
      final snapshot = await _firestore
          .collection('config_workflow_templates')
          .orderBy('domain')
          .orderBy('version', descending: true)
          .get();

      _workflowTemplates = snapshot.docs
          .map((doc) => WorkflowTemplate.fromFirestore(doc.data(), doc.id))
          .toList();
      _lastRefresh = DateTime.now();
      return _workflowTemplates!;
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading workflow templates: $e');
      return [];
    }
  }

  Future<WorkflowTemplate?> getActiveTemplateForDomain(String domain) async {
    final templates = await getWorkflowTemplates();
    try {
      return templates.firstWhere(
        (t) => t.domain == domain && t.isActive,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> createWorkflowTemplate(WorkflowTemplate template) async {
    try {
      await _firestore.collection('config_workflow_templates').doc(template.templateId).set(template.toFirestore());
      _workflowTemplates = null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error creating workflow template: $e');
      rethrow;
    }
  }

  Future<void> updateWorkflowTemplate(WorkflowTemplate template) async {
    try {
      await _firestore
          .collection('config_workflow_templates')
          .doc(template.templateId)
          .set(template.toFirestore());
      _workflowTemplates = null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating workflow template: $e');
      rethrow;
    }
  }

  Future<void> saveWorkflowTemplate(WorkflowTemplate template) async {
    try {
      if (template.id.isEmpty) {
        // New template
        await _firestore.collection('config_workflow_templates').add(template.toFirestore());
      } else {
        // Update existing
        await _firestore
            .collection('config_workflow_templates')
            .doc(template.id)
            .set(template.toFirestore());
      }
      _workflowTemplates = null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving workflow template: $e');
      rethrow;
    }
  }

  Future<void> deleteWorkflowTemplate(String id) async {
    try {
      await _firestore.collection('config_workflow_templates').doc(id).delete();
      _workflowTemplates = null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting workflow template: $e');
      rethrow;
    }
  }

  // ==================== ROUTING RULES ====================

  Future<List<RoutingRule>> getAllRoutingRules({bool forceRefresh = false}) async {
    // Get all routing rules (not just active ones)
    if (_routingRules != null && !forceRefresh) return _routingRules!;

    try {
      final snapshot = await _firestore
          .collection('config_routing_rules')
          .orderBy('priority')
          .get();

      _routingRules = snapshot.docs
          .map((doc) => RoutingRule.fromFirestore(doc.data(), doc.id))
          .toList();
      _lastRefresh = DateTime.now();
      return _routingRules!;
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading routing rules: $e');
      return [];
    }
  }

  Future<List<RoutingRule>> getRoutingRules({bool forceRefresh = false}) async {
    if (_routingRules != null && !forceRefresh) return _routingRules!;

    try {
      final snapshot = await _firestore
          .collection('config_routing_rules')
          .where('isActive', isEqualTo: true)
          .orderBy('priority')
          .get();

      _routingRules = snapshot.docs
          .map((doc) => RoutingRule.fromFirestore(doc.data(), doc.id))
          .toList();
      _lastRefresh = DateTime.now();
      return _routingRules!;
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading routing rules: $e');
      return [];
    }
  }

  Future<RoutingRule?> matchRoutingRule(String domain, Map<String, dynamic> data) async {
    final rules = await getRoutingRules();
    for (var rule in rules) {
      if (rule.domain == domain && _evaluateConditions(rule.conditions, data)) {
        return rule;
      }
    }
    return null;
  }

  bool _evaluateConditions(Map<String, dynamic> conditions, Map<String, dynamic> data) {
    for (var entry in conditions.entries) {
      final key = entry.key;
      final condition = entry.value.toString();

      if (condition.contains('>')) {
        final parts = condition.split('>');
        final threshold = double.tryParse(parts[1].trim()) ?? 0;
        final value = (data[key] as num?)?.toDouble() ?? 0;
        if (value <= threshold) return false;
      } else if (condition.contains('==')) {
        final parts = condition.split('==');
        final expected = parts[1].trim().replaceAll('"', '');
        if (data[key]?.toString() != expected) return false;
      }
    }
    return true;
  }

  Future<void> saveRoutingRule(RoutingRule rule) async {
    try {
      if (rule.id.isEmpty) {
        await _firestore.collection('config_routing_rules').add(rule.toFirestore());
      } else {
        await _firestore
            .collection('config_routing_rules')
            .doc(rule.id)
            .set(rule.toFirestore());
      }
      _routingRules = null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving routing rule: $e');
      rethrow;
    }
  }

  Future<void> deleteRoutingRule(String id) async {
    try {
      await _firestore.collection('config_routing_rules').doc(id).delete();
      _routingRules = null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting routing rule: $e');
      rethrow;
    }
  }

  // ==================== UCO INCENTIVES ====================

  Future<List<UCOIncentive>> getAllUCOIncentives({bool forceRefresh = false}) async {
    // Get all UCO incentives (not just active ones)
    if (_ucoIncentives != null && !forceRefresh) return _ucoIncentives!;

    try {
      final snapshot = await _firestore
          .collection('config_uco_incentives')
          .orderBy('zone')
          .get();

      _ucoIncentives = snapshot.docs
          .map((doc) => UCOIncentive.fromFirestore(doc.data(), doc.id))
          .toList();
      _lastRefresh = DateTime.now();
      return _ucoIncentives!;
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading UCO incentives: $e');
      return [];
    }
  }

  Future<List<UCOIncentive>> getUCOIncentives({bool forceRefresh = false}) async {
    if (_ucoIncentives != null && !forceRefresh) return _ucoIncentives!;

    try {
      final snapshot = await _firestore
          .collection('config_uco_incentives')
          .where('isActive', isEqualTo: true)
          .orderBy('zone')
          .get();

      _ucoIncentives = snapshot.docs
          .map((doc) => UCOIncentive.fromFirestore(doc.data(), doc.id))
          .toList();
      _lastRefresh = DateTime.now();
      return _ucoIncentives!;
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading UCO incentives: $e');
      return [];
    }
  }

  Future<UCOIncentive?> getIncentiveForZone(
      String zone, String customerType, double quantity) async {
    final incentives = await getUCOIncentives();
    try {
      return incentives.firstWhere(
        (i) => i.zone == zone && i.customerType == customerType && quantity >= i.minQty,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> saveUCOIncentive(UCOIncentive incentive) async {
    try {
      if (incentive.id.isEmpty) {
        await _firestore.collection('config_uco_incentives').add(incentive.toFirestore());
      } else {
        await _firestore
            .collection('config_uco_incentives')
            .doc(incentive.id)
            .set(incentive.toFirestore());
      }
      _ucoIncentives = null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving UCO incentive: $e');
      rethrow;
    }
  }

  Future<void> deleteUCOIncentive(String id) async {
    try {
      await _firestore.collection('config_uco_incentives').doc(id).delete();
      _ucoIncentives = null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting UCO incentive: $e');
      rethrow;
    }
  }

  // ==================== DELIVERY SLOTS ====================

  Future<List<DeliverySlot>> getAllDeliverySlots({bool forceRefresh = false}) async {
    // Get all delivery slots (not just active ones)
    if (_deliverySlots != null && !forceRefresh) return _deliverySlots!;

    try {
      final snapshot = await _firestore
          .collection('config_delivery_slots')
          .orderBy('zone')
          .get();

      _deliverySlots = snapshot.docs
          .map((doc) => DeliverySlot.fromFirestore(doc.data(), doc.id))
          .toList();
      _lastRefresh = DateTime.now();
      return _deliverySlots!;
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading delivery slots: $e');
      return [];
    }
  }

  Future<List<DeliverySlot>> getDeliverySlots({bool forceRefresh = false}) async {
    if (_deliverySlots != null && !forceRefresh) return _deliverySlots!;

    try {
      final snapshot = await _firestore
          .collection('config_delivery_slots')
          .where('isActive', isEqualTo: true)
          .orderBy('zone')
          .get();

      _deliverySlots = snapshot.docs
          .map((doc) => DeliverySlot.fromFirestore(doc.data(), doc.id))
          .toList();
      _lastRefresh = DateTime.now();
      return _deliverySlots!;
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading delivery slots: $e');
      return [];
    }
  }

  Future<List<DeliverySlot>> getSlotsForZone(String zone) async {
    final slots = await getDeliverySlots();
    return slots.where((s) => s.zone == zone).toList();
  }

  Future<void> saveDeliverySlot(DeliverySlot slot) async {
    try {
      if (slot.id.isEmpty) {
        await _firestore.collection('config_delivery_slots').add(slot.toFirestore());
      } else {
        await _firestore
            .collection('config_delivery_slots')
            .doc(slot.id)
            .set(slot.toFirestore());
      }
      _deliverySlots = null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving delivery slot: $e');
      rethrow;
    }
  }

  Future<void> deleteDeliverySlot(String id) async {
    try {
      await _firestore.collection('config_delivery_slots').doc(id).delete();
      _deliverySlots = null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting delivery slot: $e');
      rethrow;
    }
  }

  // ==================== NOTIFICATION TEMPLATES ====================

  Future<List<NotificationTemplate>> getAllNotificationTemplates(
      {bool forceRefresh = false}) async {
    // Get all notification templates (not just active ones)
    if (_notificationTemplates != null && !forceRefresh) return _notificationTemplates!;

    try {
      final snapshot = await _firestore
          .collection('config_notification_templates')
          .get();

      _notificationTemplates = snapshot.docs
          .map((doc) => NotificationTemplate.fromFirestore(doc.data(), doc.id))
          .toList();
      _lastRefresh = DateTime.now();
      return _notificationTemplates!;
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading notification templates: $e');
      return [];
    }
  }

  Future<List<NotificationTemplate>> getNotificationTemplates(
      {bool forceRefresh = false}) async {
    if (_notificationTemplates != null && !forceRefresh) return _notificationTemplates!;

    try {
      final snapshot = await _firestore
          .collection('config_notification_templates')
          .where('isActive', isEqualTo: true)
          .get();

      _notificationTemplates = snapshot.docs
          .map((doc) => NotificationTemplate.fromFirestore(doc.data(), doc.id))
          .toList();
      _lastRefresh = DateTime.now();
      return _notificationTemplates!;
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading notification templates: $e');
      return [];
    }
  }

  Future<NotificationTemplate?> getTemplateByKey(String templateKey) async {
    final templates = await getNotificationTemplates();
    try {
      return templates.firstWhere((t) => t.templateKey == templateKey);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveNotificationTemplate(NotificationTemplate template) async {
    try {
      if (template.id.isEmpty) {
        await _firestore
            .collection('config_notification_templates')
            .add(template.toFirestore());
      } else {
        await _firestore
            .collection('config_notification_templates')
            .doc(template.id)
            .set(template.toFirestore());
      }
      _notificationTemplates = null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving notification template: $e');
      rethrow;
    }
  }

  Future<void> deleteNotificationTemplate(String id) async {
    try {
      await _firestore.collection('config_notification_templates').doc(id).delete();
      _notificationTemplates = null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting notification template: $e');
      rethrow;
    }
  }

  // ==================== STATUS SEQUENCES ====================

  Future<List<StatusSequence>> getAllStatusSequences({bool forceRefresh = false}) async {
    return await getStatusSequences(forceRefresh: forceRefresh);
  }

  Future<List<StatusSequence>> getStatusSequences({bool forceRefresh = false}) async {
    if (_statusSequences != null && !forceRefresh) return _statusSequences!;

    try {
      final snapshot = await _firestore.collection('config_status_sequences').get();

      _statusSequences = snapshot.docs
          .map((doc) => StatusSequence.fromFirestore(doc.data(), doc.id))
          .toList();
      _lastRefresh = DateTime.now();
      return _statusSequences!;
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading status sequences: $e');
      return [];
    }
  }

  Future<StatusSequence?> getSequenceForDomain(String domain) async {
    final sequences = await getStatusSequences();
    try {
      return sequences.firstWhere((s) => s.domain == domain);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveStatusSequence(StatusSequence sequence) async {
    try {
      if (sequence.id.isEmpty) {
        await _firestore.collection('config_status_sequences').add(sequence.toFirestore());
      } else {
        await _firestore
            .collection('config_status_sequences')
            .doc(sequence.id)
            .set(sequence.toFirestore());
      }
      _statusSequences = null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving status sequence: $e');
      rethrow;
    }
  }

  Future<void> deleteStatusSequence(String id) async {
    try {
      await _firestore.collection('config_status_sequences').doc(id).delete();
      _statusSequences = null;
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting status sequence: $e');
      rethrow;
    }
  }

  // ==================== UTILITY ====================

  Future<void> refreshAllConfig() async {
    try {
      await Future.wait([
        getSystemSettings(forceRefresh: true),
        getWorkflowTemplates(forceRefresh: true),
        getRoutingRules(forceRefresh: true),
        getUCOIncentives(forceRefresh: true),
        getDeliverySlots(forceRefresh: true),
        getNotificationTemplates(forceRefresh: true),
        getStatusSequences(forceRefresh: true),
      ]);
      if (kDebugMode) debugPrint('✅ All config refreshed successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('Error refreshing config: $e');
    }
  }

  void clearCache() {
    _systemSettings = null;
    _workflowTemplates = null;
    _routingRules = null;
    _ucoIncentives = null;
    _deliverySlots = null;
    _notificationTemplates = null;
    _statusSequences = null;
    _lastRefresh = null;
  }

  Map<String, dynamic> getCacheStats() {
    return {
      'systemSettings': _systemSettings?.length ?? 0,
      'workflowTemplates': _workflowTemplates?.length ?? 0,
      'routingRules': _routingRules?.length ?? 0,
      'ucoIncentives': _ucoIncentives?.length ?? 0,
      'deliverySlots': _deliverySlots?.length ?? 0,
      'notificationTemplates': _notificationTemplates?.length ?? 0,
      'statusSequences': _statusSequences?.length ?? 0,
      'lastRefresh': _lastRefresh,
    };
  }

  Map<String, dynamic> getCacheStatistics() {
    final now = DateTime.now();
    final lastRefresh = _lastRefresh ?? now;
    final refreshAge = now.difference(lastRefresh);
    
    return {
      'systemSettings': _systemSettings?.length ?? 0,
      'workflowTemplates': _workflowTemplates?.length ?? 0,
      'routingRules': _routingRules?.length ?? 0,
      'ucoIncentives': _ucoIncentives?.length ?? 0,
      'deliverySlots': _deliverySlots?.length ?? 0,
      'notificationTemplates': _notificationTemplates?.length ?? 0,
      'statusSequences': _statusSequences?.length ?? 0,
      'lastRefresh': lastRefresh,
      'refreshAgeSeconds': refreshAge.inSeconds,
      'hitRate': 0.95, // Placeholder - implement actual hit rate tracking if needed
    };
  }
}
