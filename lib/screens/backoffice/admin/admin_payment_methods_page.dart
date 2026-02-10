import 'package:flutter/material.dart';
import '../../../models/config_models.dart';
import '../../../services/config_service.dart';

/// Admin screen for managing payment methods
class AdminPaymentMethodsPage extends StatefulWidget {
  const AdminPaymentMethodsPage({super.key});

  @override
  State<AdminPaymentMethodsPage> createState() =>
      _AdminPaymentMethodsPageState();
}

class _AdminPaymentMethodsPageState extends State<AdminPaymentMethodsPage> {
  final ConfigService _configService = ConfigService();
  final TextEditingController _searchController = TextEditingController();

  List<ConfigPaymentMethod> _methods = [];
  List<ConfigPaymentMethod> _filteredMethods = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMethods();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterMethods();
    });
  }

  void _filterMethods() {
    if (_searchQuery.isEmpty) {
      _filteredMethods = List.from(_methods);
    } else {
      _filteredMethods = _methods.where((method) {
        return method.name.toLowerCase().contains(_searchQuery) ||
            method.code.toLowerCase().contains(_searchQuery) ||
            method.description.toLowerCase().contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _loadMethods() async {
    setState(() => _isLoading = true);
    try {
      final methods =
          await _configService.getPaymentMethods(forceRefresh: true);
      setState(() {
        _methods = methods;
        _filterMethods();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load payment methods: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAddEditDialog({ConfigPaymentMethod? method}) async {
    final isEdit = method != null;
    final nameController = TextEditingController(text: method?.name ?? '');
    final codeController = TextEditingController(text: method?.code ?? '');
    final descController =
        TextEditingController(text: method?.description ?? '');
    bool isActive = method?.isActive ?? true;
    bool requiresApproval = method?.requiresApproval ?? false;
    bool isOnlinePayment = method?.isOnlinePayment ?? false;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Payment Method' : 'Add Payment Method'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Method Name *',
                      hintText: 'e.g., Cash on Delivery',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter method name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Method Code *',
                      hintText: 'e.g., COD',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter method code';
                      }
                      return null;
                    },
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
                  SwitchListTile(
                    title: const Text('Requires Approval'),
                    subtitle: const Text('Payment needs manual approval'),
                    value: requiresApproval,
                    onChanged: (value) {
                      setDialogState(() => requiresApproval = value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Online Payment'),
                    subtitle: const Text('Payment processed online'),
                    value: isOnlinePayment,
                    onChanged: (value) {
                      setDialogState(() => isOnlinePayment = value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Active'),
                    subtitle:
                        const Text('Method is available for selection'),
                    value: isActive,
                    onChanged: (value) {
                      setDialogState(() => isActive = value);
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
                    final newMethod = ConfigPaymentMethod(
                      id: method?.id ?? '',
                      name: nameController.text.trim(),
                      code: codeController.text.trim(),
                      description: descController.text.trim().isEmpty
                          ? ''
                          : descController.text.trim(),
                      requiresApproval: requiresApproval,
                      isOnlinePayment: isOnlinePayment,
                      displayOrder: method?.displayOrder ?? 0,
                      isActive: isActive,
                      createdAt: method?.createdAt ?? DateTime.now(),
                    );

                    if (isEdit) {
                      await _configService.updatePaymentMethod(newMethod);
                    } else {
                      await _configService.addPaymentMethod(newMethod);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEdit
                                ? 'Payment method updated successfully'
                                : 'Payment method added successfully',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadMethods();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to save payment method: $e'),
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

  Future<void> _deleteMethod(ConfigPaymentMethod method) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text(
          'Are you sure you want to delete "${method.name}"?\n\n'
          'This action cannot be undone.',
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
        await _configService.deletePaymentMethod(method.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment method deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadMethods();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete payment method: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  IconData _getPaymentIcon(String code) {
    switch (code.toUpperCase()) {
      case 'COD':
        return Icons.money;
      case 'BANK_TRANSFER':
        return Icons.account_balance;
      case 'CARD':
        return Icons.credit_card;
      case 'EWALLET':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMethods,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search payment methods...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Methods list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMethods.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payment_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No payment methods found'
                                  : 'No methods match your search',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Tap + to add your first payment method'
                                  : 'Try a different search term',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredMethods.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final method = _filteredMethods[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: method.isActive
                                    ? Colors.blue
                                    : Colors.grey,
                                child: Icon(
                                  _getPaymentIcon(method.code),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                method.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Code: ${method.code}'),
                                  if (method.description.isNotEmpty)
                                    Text(
                                      method.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  if (method.requiresApproval)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.verified_user,
                                          size: 14,
                                          color: Colors.orange[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Requires Approval',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (method.isOnlinePayment)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.cloud_done,
                                          size: 14,
                                          color: Colors.blue[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Online Payment',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Chip(
                                    label: Text(
                                      method.isActive ? 'Active' : 'Inactive',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: method.isActive
                                        ? Colors.green[100]
                                        : Colors.grey[300],
                                  ),
                                  PopupMenuButton(
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
                                            Icon(Icons.delete,
                                                size: 20, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showAddEditDialog(method: method);
                                      } else if (value == 'delete') {
                                        _deleteMethod(method);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Method'),
      ),
    );
  }
}
