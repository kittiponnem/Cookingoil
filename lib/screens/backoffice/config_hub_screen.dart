import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/advanced_config_service.dart';
import '../../providers/auth_provider.dart';

/// Config Management Hub - Central dashboard for all configuration management
/// Provides quick access to all 7 config collections with statistics
class ConfigHubScreen extends StatefulWidget {
  const ConfigHubScreen({Key? key}) : super(key: key);

  @override
  State<ConfigHubScreen> createState() => _ConfigHubScreenState();
}

class _ConfigHubScreenState extends State<ConfigHubScreen> {
  final AdvancedConfigService _configService = AdvancedConfigService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get cache statistics
      final cacheStats = _configService.getCacheStatistics();
      
      // Load counts for each collection
      final systemSettings = await _configService.getAllSystemSettings();
      final workflowTemplates = await _configService.getAllWorkflowTemplates();
      final routingRules = await _configService.getAllRoutingRules();
      final ucoIncentives = await _configService.getAllUCOIncentives();
      final deliverySlots = await _configService.getAllDeliverySlots();
      final notificationTemplates = await _configService.getAllNotificationTemplates();
      final statusSequences = await _configService.getAllStatusSequences();

      setState(() {
        _stats = {
          'systemSettings': systemSettings.length,
          'workflowTemplates': workflowTemplates.where((t) => t.isActive).length,
          'routingRules': routingRules.where((r) => r.isActive).length,
          'ucoIncentives': ucoIncentives.where((i) => i.isActive).length,
          'deliverySlots': deliverySlots.where((s) => s.isActive).length,
          'notificationTemplates': notificationTemplates.where((t) => t.isActive).length,
          'statusSequences': statusSequences.length,
          'cacheHitRate': cacheStats['hitRate'] ?? 0.0,
          'lastRefresh': cacheStats['lastRefresh'] ?? DateTime.now(),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadStatistics,
            tooltip: 'Refresh Statistics',
          ),
          IconButton(
            icon: const Icon(Icons.cached),
            onPressed: () {
              _configService.clearCache();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
              _loadStatistics();
            },
            tooltip: 'Clear Cache',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSystemOverview(),
                      const SizedBox(height: 24),
                      _buildConfigGrid(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error loading configuration',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: _loadStatistics,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemOverview() {
    final lastRefresh = _stats['lastRefresh'] as DateTime;
    final hitRate = (_stats['cacheHitRate'] as double) * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_system_daydream,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('System Overview',
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Configs',
                    '${_stats.values.whereType<int>().reduce((a, b) => a + b)}',
                    Icons.folder_open,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Cache Hit Rate',
                    '${hitRate.toStringAsFixed(1)}%',
                    Icons.speed,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Last Refresh',
                    _formatTime(lastRefresh),
                    Icons.update,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildConfigGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildConfigCard(
          title: 'System Settings',
          icon: Icons.settings,
          color: Colors.blue,
          count: _stats['systemSettings'] ?? 0,
          description: 'Global system configuration',
          route: '/backoffice/config/system-settings',
        ),
        _buildConfigCard(
          title: 'Workflow Templates',
          icon: Icons.account_tree,
          color: Colors.purple,
          count: _stats['workflowTemplates'] ?? 0,
          description: 'Approval workflow definitions',
          route: '/backoffice/config/workflow-templates',
        ),
        _buildConfigCard(
          title: 'Routing Rules',
          icon: Icons.route,
          color: Colors.orange,
          count: _stats['routingRules'] ?? 0,
          description: 'Auto-assignment rules',
          route: '/backoffice/config/routing-rules',
        ),
        _buildConfigCard(
          title: 'UCO Incentives',
          icon: Icons.local_offer,
          color: Colors.green,
          count: _stats['ucoIncentives'] ?? 0,
          description: 'Used cooking oil pricing',
          route: '/backoffice/config/uco-incentives',
        ),
        _buildConfigCard(
          title: 'Delivery Slots',
          icon: Icons.local_shipping,
          color: Colors.teal,
          count: _stats['deliverySlots'] ?? 0,
          description: 'Delivery time windows',
          route: '/backoffice/config/delivery-slots',
        ),
        _buildConfigCard(
          title: 'Notifications',
          icon: Icons.notifications,
          color: Colors.pink,
          count: _stats['notificationTemplates'] ?? 0,
          description: 'Email & push templates',
          route: '/backoffice/config/notification-templates',
        ),
        _buildConfigCard(
          title: 'Status Sequences',
          icon: Icons.timeline,
          color: Colors.indigo,
          count: _stats['statusSequences'] ?? 0,
          description: 'Order lifecycle states',
          route: '/backoffice/config/status-sequences',
        ),
      ],
    );
  }

  Widget _buildConfigCard({
    required String title,
    required IconData icon,
    required Color color,
    required int count,
    required String description,
    required String route,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 32),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
