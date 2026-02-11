import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/advanced_config_service.dart';
import '../../models/advanced_config_models.dart';

/// UCO Incentives Management Screen
/// Zone-based pricing grid for used cooking oil buyback rates
class UCOIncentivesScreen extends StatefulWidget {
  const UCOIncentivesScreen({Key? key}) : super(key: key);

  @override
  State<UCOIncentivesScreen> createState() => _UCOIncentivesScreenState();
}

class _UCOIncentivesScreenState extends State<UCOIncentivesScreen> {
  final AdvancedConfigService _configService = AdvancedConfigService();
  List<UCOIncentive> _incentives = [];
  bool _isLoading = true;
  String? _error;
  String _zoneFilter = 'all';

  final List<String> _zones = [
    'all',
    'Bangkok Central',
    'Bangkok Suburbs',
    'Provinces',
  ];

  @override
  void initState() {
    super.initState();
    _loadIncentives();
  }

  Future<void> _loadIncentives() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final incentives = await _configService.getAllUCOIncentives();
      setState(() {
        _incentives = incentives;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<UCOIncentive> get _filteredIncentives {
    if (_zoneFilter == 'all') return _incentives;
    return _incentives.where((i) => i.zone == _zoneFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UCO Incentives'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadIncentives,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditDialog(null),
            tooltip: 'Add Incentive',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildZoneFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _filteredIncentives.isEmpty
                        ? _buildEmptyState()
                        : _buildIncentivesGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Zone',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _zones.map((zone) {
                final isSelected = _zoneFilter == zone;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(zone.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _zoneFilter = zone;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncentivesGrid() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredIncentives.length,
      itemBuilder: (context, index) {
        final incentive = _filteredIncentives[index];
        return _buildIncentiveCard(incentive);
      },
    );
  }

  Widget _buildIncentiveCard(UCOIncentive incentive) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 20, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            incentive.zone,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildCustomerTypeChip(incentive.customerType),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: incentive.isActive
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              incentive.isActive ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                color: incentive.isActive
                                    ? Colors.green
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditDialog(incentive),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(incentive),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildRateCard(
                    'Cash Rate',
                    '฿${incentive.cashRatePerKg.toStringAsFixed(2)}/kg',
                    Icons.payments,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRateCard(
                    'Credit Rate',
                    '฿${incentive.creditRatePerKg.toStringAsFixed(2)}/kg',
                    Icons.credit_card,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRateCard(
                    'Points',
                    '${incentive.pointsPerKg.toStringAsFixed(0)} pts/kg',
                    Icons.stars,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.inventory_2, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Minimum Quantity: ${incentive.minQty.toStringAsFixed(1)} kg',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (incentive.qualityMultipliers.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Quality Multipliers:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: incentive.qualityMultipliers.entries.map((entry) {
                  return Chip(
                    label: Text(
                      '${entry.key}: ${entry.value}x',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRateCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerTypeChip(String customerType) {
    final color = customerType == 'B2B' ? Colors.purple : Colors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        customerType,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No incentives found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first UCO incentive',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Incentive'),
            onPressed: () => _showEditDialog(null),
          ),
        ],
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
          Text('Error loading incentives',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: _loadIncentives,
          ),
        ],
      ),
    );
  }

  void _showEditDialog(UCOIncentive? incentive) {
    final isEditing = incentive != null;
    
    String selectedZone = incentive?.zone ?? 'Bangkok Central';
    String selectedCustomerType = incentive?.customerType ?? 'B2B';
    final minQtyController =
        TextEditingController(text: incentive?.minQty.toString() ?? '50');
    final cashRateController = TextEditingController(
        text: incentive?.cashRatePerKg.toString() ?? '45');
    final creditRateController = TextEditingController(
        text: incentive?.creditRatePerKg.toString() ?? '50');
    final pointsController =
        TextEditingController(text: incentive?.pointsPerKg.toString() ?? '10');
    bool isActive = incentive?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Incentive' : 'Add Incentive'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedZone,
                  decoration: const InputDecoration(labelText: 'Zone'),
                  items: _zones
                      .where((z) => z != 'all')
                      .map((zone) => DropdownMenuItem(
                            value: zone,
                            child: Text(zone),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedZone = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCustomerType,
                  decoration: const InputDecoration(labelText: 'Customer Type'),
                  items: const [
                    DropdownMenuItem(value: 'B2B', child: Text('B2B')),
                    DropdownMenuItem(value: 'B2C', child: Text('B2C')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCustomerType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: minQtyController,
                  decoration: const InputDecoration(
                    labelText: 'Minimum Quantity (kg)',
                    hintText: '50',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: cashRateController,
                  decoration: const InputDecoration(
                    labelText: 'Cash Rate (฿/kg)',
                    hintText: '45.00',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: creditRateController,
                  decoration: const InputDecoration(
                    labelText: 'Credit Rate (฿/kg)',
                    hintText: '50.00',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pointsController,
                  decoration: const InputDecoration(
                    labelText: 'Points per kg',
                    hintText: '10',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Enable this incentive'),
                  value: isActive,
                  onChanged: (value) {
                    setDialogState(() {
                      isActive = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final minQty = double.tryParse(minQtyController.text) ?? 50.0;
                final cashRate =
                    double.tryParse(cashRateController.text) ?? 45.0;
                final creditRate =
                    double.tryParse(creditRateController.text) ?? 50.0;
                final points = double.tryParse(pointsController.text) ?? 10.0;

                final newIncentive = UCOIncentive(
                  id: incentive?.id ?? '',
                  zone: selectedZone,
                  customerType: selectedCustomerType,
                  minQty: minQty,
                  cashRatePerKg: cashRate,
                  creditRatePerKg: creditRate,
                  pointsPerKg: points,
                  qualityMultipliers: incentive?.qualityMultipliers ?? {},
                  isActive: isActive,
                  updatedAt: DateTime.now(),
                );

                try {
                  await _configService.saveUCOIncentive(newIncentive);
                  Navigator.pop(context);
                  _loadIncentives();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(isEditing
                            ? 'Incentive updated successfully'
                            : 'Incentive created successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving incentive: $e')),
                  );
                }
              },
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(UCOIncentive incentive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Incentive'),
        content: Text(
            'Are you sure you want to delete incentive for "${incentive.zone} - ${incentive.customerType}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _configService.deleteUCOIncentive(incentive.id);
                Navigator.pop(context);
                _loadIncentives();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Incentive deleted successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting incentive: $e')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
