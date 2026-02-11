import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/advanced_config_service.dart';
import '../../models/advanced_config_models.dart';

/// System Settings Management Screen
/// Allows admins to view and edit global system configuration
class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({Key? key}) : super(key: key);

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final AdvancedConfigService _configService = AdvancedConfigService();
  List<SystemSetting> _settings = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _categoryFilter = 'all';

  final List<String> _categories = [
    'all',
    'general',
    'security',
    'workflow',
    'logistics',
    'uco',
    'notification',
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final settings = await _configService.getAllSystemSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<SystemSetting> get _filteredSettings {
    return _settings.where((setting) {
      final matchesSearch = setting.key
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          setting.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _categoryFilter == 'all' || setting.category == _categoryFilter;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadSettings,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditDialog(null),
            tooltip: 'Add Setting',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _filteredSettings.isEmpty
                        ? _buildEmptyState()
                        : _buildSettingsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search settings...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final isSelected = _categoryFilter == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _categoryFilter = category;
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

  Widget _buildSettingsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSettings.length,
      itemBuilder: (context, index) {
        final setting = _filteredSettings[index];
        return _buildSettingCard(setting);
      },
    );
  }

  Widget _buildSettingCard(SystemSetting setting) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          setting.key,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(setting.description),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildCategoryChip(setting.category),
                const SizedBox(width: 8),
                _buildValueDisplay(setting),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEditDialog(setting),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(setting),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final colors = {
      'general': Colors.blue,
      'security': Colors.red,
      'workflow': Colors.purple,
      'logistics': Colors.orange,
      'uco': Colors.green,
      'notification': Colors.pink,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (colors[category] ?? Colors.grey).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: colors[category] ?? Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildValueDisplay(SystemSetting setting) {
    String displayValue;
    Icon icon;

    if (setting.valueBool != null) {
      displayValue = setting.valueBool! ? 'TRUE' : 'FALSE';
      icon = Icon(
        setting.valueBool! ? Icons.check_circle : Icons.cancel,
        color: setting.valueBool! ? Colors.green : Colors.red,
        size: 16,
      );
    } else if (setting.valueNumber != null) {
      displayValue = setting.valueNumber.toString();
      icon = const Icon(Icons.numbers, color: Colors.blue, size: 16);
    } else {
      displayValue = setting.valueString ?? 'NULL';
      icon = const Icon(Icons.text_fields, color: Colors.grey, size: 16);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 4),
        Text(
          displayValue,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No settings found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter',
            style: TextStyle(color: Colors.grey[600]),
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
          Text('Error loading settings',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: _loadSettings,
          ),
        ],
      ),
    );
  }

  void _showEditDialog(SystemSetting? setting) {
    final isEditing = setting != null;
    final keyController = TextEditingController(text: setting?.key ?? '');
    final descriptionController =
        TextEditingController(text: setting?.description ?? '');
    String selectedCategory = setting?.category ?? 'general';
    String valueType = setting?.valueBool != null
        ? 'boolean'
        : setting?.valueNumber != null
            ? 'number'
            : 'string';

    final stringController =
        TextEditingController(text: setting?.valueString ?? '');
    final numberController = TextEditingController(
        text: setting?.valueNumber?.toString() ?? '');
    bool boolValue = setting?.valueBool ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Setting' : 'Add Setting'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: keyController,
                  decoration: const InputDecoration(
                    labelText: 'Key',
                    hintText: 'SETTING_KEY',
                  ),
                  enabled: !isEditing,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Brief description of this setting',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories
                      .where((c) => c != 'all')
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: valueType,
                  decoration: const InputDecoration(labelText: 'Value Type'),
                  items: const [
                    DropdownMenuItem(value: 'string', child: Text('String')),
                    DropdownMenuItem(value: 'number', child: Text('Number')),
                    DropdownMenuItem(value: 'boolean', child: Text('Boolean')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      valueType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (valueType == 'string')
                  TextField(
                    controller: stringController,
                    decoration: const InputDecoration(
                      labelText: 'Value',
                      hintText: 'String value',
                    ),
                  ),
                if (valueType == 'number')
                  TextField(
                    controller: numberController,
                    decoration: const InputDecoration(
                      labelText: 'Value',
                      hintText: 'Numeric value',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                  ),
                if (valueType == 'boolean')
                  SwitchListTile(
                    title: const Text('Value'),
                    value: boolValue,
                    onChanged: (value) {
                      setDialogState(() {
                        boolValue = value;
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
                final key = keyController.text.trim();
                final description = descriptionController.text.trim();

                if (key.isEmpty || description.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                final newSetting = SystemSetting(
                  key: key,
                  description: description,
                  category: selectedCategory,
                  valueString: valueType == 'string' ? stringController.text : null,
                  valueNumber: valueType == 'number'
                      ? double.tryParse(numberController.text)
                      : null,
                  valueBool: valueType == 'boolean' ? boolValue : null,
                  updatedAt: DateTime.now(),
                  updatedBy: 'current_user', // TODO: Get from AuthProvider
                );

                try {
                  await _configService.updateSystemSetting(newSetting);
                  Navigator.pop(context);
                  _loadSettings();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(isEditing
                            ? 'Setting updated successfully'
                            : 'Setting created successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving setting: $e')),
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

  void _confirmDelete(SystemSetting setting) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Setting'),
        content: Text('Are you sure you want to delete "${setting.key}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _configService.deleteSystemSetting(setting.key);
                Navigator.pop(context);
                _loadSettings();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Setting deleted successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting setting: $e')),
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
