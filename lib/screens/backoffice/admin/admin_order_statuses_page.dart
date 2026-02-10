import 'package:flutter/material.dart';
import '../../../models/config_models.dart';
import '../../../services/config_service.dart';

/// Admin screen for managing order statuses
class AdminOrderStatusesPage extends StatefulWidget {
  const AdminOrderStatusesPage({super.key});

  @override
  State<AdminOrderStatusesPage> createState() => _AdminOrderStatusesPageState();
}

class _AdminOrderStatusesPageState extends State<AdminOrderStatusesPage>
    with SingleTickerProviderStateMixin {
  final ConfigService _configService = ConfigService();
  late TabController _tabController;

  final Map<String, List<ConfigOrderStatus>> _statusesByType = {
    'sales': [],
    'uco': [],
    'return': [],
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllStatuses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllStatuses() async {
    setState(() => _isLoading = true);
    try {
      for (final type in ['sales', 'uco', 'return']) {
        final statuses =
            await _configService.getOrderStatuses(type, forceRefresh: true);
        _statusesByType[type] = statuses;
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load statuses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAddEditDialog(String type,
      {ConfigOrderStatus? status}) async {
    final isEdit = status != null;
    final nameController = TextEditingController(text: status?.name ?? '');
    final codeController = TextEditingController(text: status?.code ?? '');
    final descController = TextEditingController(text: status?.description ?? '');
    final sequenceController =
        TextEditingController(text: status?.sequence.toString() ?? '0');
    bool isTerminal = status?.isTerminal ?? false;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Status' : 'Add Status'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Status Name *',
                      hintText: 'e.g., Pending',
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Status Code *',
                      hintText: 'e.g., PENDING',
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Optional description',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: sequenceController,
                    decoration: const InputDecoration(
                      labelText: 'Sequence *',
                      hintText: 'Display order',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (int.tryParse(value) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Terminal Status'),
                    subtitle: const Text('This is a final/end state'),
                    value: isTerminal,
                    onChanged: (value) {
                      setDialogState(() => isTerminal = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final newStatus = ConfigOrderStatus(
                      id: status?.id ?? '',
                      type: type,
                      name: nameController.text.trim(),
                      code: codeController.text.trim(),
                      description: descController.text.trim().isEmpty
                          ? ''
                          : descController.text.trim(),
                      sequence: int.parse(sequenceController.text),
                      isTerminal: isTerminal,
                      isActive: status?.isActive ?? true,
                      createdAt: status?.createdAt ?? DateTime.now(),
                    );

                    if (isEdit) {
                      await _configService.updateOrderStatus(newStatus);
                    } else {
                      await _configService.addOrderStatus(newStatus);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEdit
                                ? 'Status updated successfully'
                                : 'Status added successfully',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadAllStatuses();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save status: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteStatus(ConfigOrderStatus status) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Status'),
        content: Text(
          'Delete "${status.name}"?\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _configService.deleteOrderStatus(status.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Status deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAllStatuses();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete status: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildStatusList(String type) {
    final statuses = _statusesByType[type] ?? [];
    
    if (statuses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.toggle_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No $type statuses found',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Tap + to add a status',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: statuses.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final status = statuses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: status.isTerminal ? Colors.red : Colors.blue,
              child: Text('${status.sequence}'),
            ),
            title: Text(status.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Code: ${status.code}'),
                if (status.isTerminal)
                  const Row(
                    children: [
                      Icon(Icons.flag, size: 14, color: Colors.red),
                      SizedBox(width: 4),
                      Text('Terminal Status',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showAddEditDialog(type, status: status);
                } else if (value == 'delete') {
                  _deleteStatus(status);
                }
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Statuses Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sales Orders'),
            Tab(text: 'UCO Orders'),
            Tab(text: 'Returns'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllStatuses,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStatusList('sales'),
                _buildStatusList('uco'),
                _buildStatusList('return'),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final type = ['sales', 'uco', 'return'][_tabController.index];
          _showAddEditDialog(type);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Status'),
      ),
    );
  }
}
