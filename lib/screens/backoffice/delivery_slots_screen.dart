import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/advanced_config_service.dart';
import '../../models/advanced_config_models.dart';

/// Delivery Slots Management Screen
/// Time window and capacity management for delivery scheduling
class DeliverySlotsScreen extends StatefulWidget {
  const DeliverySlotsScreen({Key? key}) : super(key: key);

  @override
  State<DeliverySlotsScreen> createState() => _DeliverySlotsScreenState();
}

class _DeliverySlotsScreenState extends State<DeliverySlotsScreen> {
  final AdvancedConfigService _configService = AdvancedConfigService();
  List<DeliverySlot> _slots = [];
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
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final slots = await _configService.getAllDeliverySlots();
      setState(() {
        _slots = slots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<DeliverySlot> get _filteredSlots {
    if (_zoneFilter == 'all') return _slots;
    return _slots.where((s) => s.zone == _zoneFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Slots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadSlots,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditDialog(null),
            tooltip: 'Add Slot',
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
                    : _filteredSlots.isEmpty
                        ? _buildEmptyState()
                        : _buildSlotsList(),
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
          Text('Filter by Zone', style: Theme.of(context).textTheme.titleSmall),
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

  Widget _buildSlotsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSlots.length,
      itemBuilder: (context, index) {
        final slot = _filteredSlots[index];
        return _buildSlotCard(slot);
      },
    );
  }

  Widget _buildSlotCard(DeliverySlot slot) {
    final startTime = slot.timeWindowStart;
    final endTime = slot.timeWindowEnd;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue[700], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$startTime - $endTime',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(slot.zone,
                              style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: slot.isActive
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              slot.isActive ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    slot.isActive ? Colors.green : Colors.grey,
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
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                      onPressed: () => _showEditDialog(slot),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _confirmDelete(slot),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2,
                            color: Colors.orange[700], size: 24),
                        const SizedBox(height: 8),
                        Text(
                          '${slot.maxCapacity}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Max Capacity',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.schedule, color: Colors.blue[700], size: 24),
                        const SizedBox(height: 8),
                        Text(
                          '${slot.bufferMinutes}m',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Buffer Time',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined,
              size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No delivery slots found',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Create your first delivery slot',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Slot'),
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
          Text('Error loading slots',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: _loadSlots,
          ),
        ],
      ),
    );
  }

  void _showEditDialog(DeliverySlot? slot) {
    final isEditing = slot != null;
    
    String selectedZone = slot?.zone ?? 'Bangkok Central';
    final startTimeController =
        TextEditingController(text: slot?.timeWindowStart ?? '08:00');
    final endTimeController =
        TextEditingController(text: slot?.timeWindowEnd ?? '12:00');
    final capacityController =
        TextEditingController(text: slot?.maxCapacity.toString() ?? '20');
    final bufferController =
        TextEditingController(text: slot?.bufferMinutes.toString() ?? '30');
    bool isActive = slot?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Slot' : 'Add Slot'),
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
                TextField(
                  controller: startTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Start Time',
                    hintText: '08:00',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: endTimeController,
                  decoration: const InputDecoration(
                    labelText: 'End Time',
                    hintText: '12:00',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: capacityController,
                  decoration: const InputDecoration(
                    labelText: 'Max Capacity',
                    hintText: '20',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bufferController,
                  decoration: const InputDecoration(
                    labelText: 'Buffer Minutes',
                    hintText: '30',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Enable this slot'),
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
                final startTime = startTimeController.text.trim();
                final endTime = endTimeController.text.trim();
                final capacity = int.tryParse(capacityController.text) ?? 20;
                final buffer = int.tryParse(bufferController.text) ?? 30;

                if (startTime.isEmpty || endTime.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                final newSlot = DeliverySlot(
                  id: slot?.id ?? '',
                  zone: selectedZone,
                  timeWindowStart: startTime,
                  timeWindowEnd: endTime,
                  maxCapacity: capacity,
                  bufferMinutes: buffer,
                  isActive: isActive,
                  updatedAt: DateTime.now(),
                );

                try {
                  await _configService.saveDeliverySlot(newSlot);
                  Navigator.pop(context);
                  _loadSlots();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(isEditing
                            ? 'Slot updated successfully'
                            : 'Slot created successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving slot: $e')),
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

  void _confirmDelete(DeliverySlot slot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Slot'),
        content: Text(
            'Are you sure you want to delete slot "${slot.zone} ${slot.timeWindowStart}-${slot.timeWindowEnd}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _configService.deleteDeliverySlot(slot.id);
                Navigator.pop(context);
                _loadSlots();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Slot deleted successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting slot: $e')),
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
