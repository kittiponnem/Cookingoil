import 'package:flutter/material.dart';
import '../../services/advanced_config_service.dart';
import '../../models/advanced_config_models.dart';

/// Routing Rules Management Screen
/// Priority-ordered auto-assignment rules with condition builder
class RoutingRulesScreen extends StatefulWidget {
  const RoutingRulesScreen({Key? key}) : super(key: key);

  @override
  State<RoutingRulesScreen> createState() => _RoutingRulesScreenState();
}

class _RoutingRulesScreenState extends State<RoutingRulesScreen> {
  final AdvancedConfigService _configService = AdvancedConfigService();
  List<RoutingRule> _rules = [];
  bool _isLoading = true;
  String? _error;
  String _domainFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rules = await _configService.getAllRoutingRules();
      // Sort by priority
      rules.sort((a, b) => a.priority.compareTo(b.priority));
      setState(() {
        _rules = rules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<RoutingRule> get _filteredRules {
    if (_domainFilter == 'all') return _rules;
    return _rules.where((r) => r.domain == _domainFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routing Rules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadRules,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditDialog(null),
            tooltip: 'Add Rule',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDomainFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _filteredRules.isEmpty
                        ? _buildEmptyState()
                        : _buildRulesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDomainFilter() {
    final domains = ['all', 'sales', 'pickup', 'return', 'approval'];
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filter by Domain',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              Text(
                '${_filteredRules.length} rules',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: domains.map((domain) {
                final isSelected = _domainFilter == domain;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(domain.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _domainFilter = domain;
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

  Widget _buildRulesList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredRules.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final rule = _filteredRules.removeAt(oldIndex);
          _filteredRules.insert(newIndex, rule);
          
          // Update priorities
          for (int i = 0; i < _filteredRules.length; i++) {
            _filteredRules[i] = RoutingRule(
              id: _filteredRules[i].id,
              ruleId: _filteredRules[i].ruleId,
              domain: _filteredRules[i].domain,
              priority: i + 1,
              conditions: _filteredRules[i].conditions,
              assignToRole: _filteredRules[i].assignToRole,
              assignToUser: _filteredRules[i].assignToUser,
              isActive: _filteredRules[i].isActive,
              updatedAt: DateTime.now(),
            );
            // Save updated priority
            _configService.saveRoutingRule(_filteredRules[i]);
          }
        });
      },
      itemBuilder: (context, index) {
        final rule = _filteredRules[index];
        return _buildRuleCard(key: ValueKey(rule.ruleId), rule: rule, index: index);
      },
    );
  }

  Widget _buildRuleCard({required Key key, required RoutingRule rule, required int index}) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.ruleId,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildDomainChip(rule.domain),
                          const SizedBox(width: 8),
                          _buildPriorityChip(rule.priority),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: rule.isActive
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              rule.isActive ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    rule.isActive ? Colors.green : Colors.grey,
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
                      onPressed: () => _showEditDialog(rule),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _confirmDelete(rule),
                    ),
                    const Icon(Icons.drag_handle, color: Colors.grey),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.rule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Conditions: ${rule.conditions.length} rule(s)',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (rule.conditions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: rule.conditions.entries.map((entry) {
                  return Chip(
                    label: Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.orange.withValues(alpha: 0.1),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_forward, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Assign to: ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    rule.assignToRole ?? rule.assignToUser ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainChip(String domain) {
    final colors = {
      'sales': Colors.blue,
      'pickup': Colors.green,
      'return': Colors.orange,
      'approval': Colors.purple,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (colors[domain] ?? Colors.grey).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        domain.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: colors[domain] ?? Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(int priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'P$priority',
        style: const TextStyle(
          fontSize: 10,
          color: Colors.red,
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
          Icon(Icons.route_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No routing rules found',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Create your first routing rule',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Rule'),
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
          Text('Error loading rules',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: _loadRules,
          ),
        ],
      ),
    );
  }

  void _showEditDialog(RoutingRule? rule) {
    final isEditing = rule != null;
    
    final ruleIdController = TextEditingController(text: rule?.ruleId ?? '');
    String selectedDomain = rule?.domain ?? 'sales';
    final priorityController =
        TextEditingController(text: rule?.priority.toString() ?? '1');
    final assignToController =
        TextEditingController(text: rule?.assignToRole ?? 'admin');
    bool isActive = rule?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Rule' : 'Add Rule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ruleIdController,
                  decoration: const InputDecoration(
                    labelText: 'Rule ID',
                    hintText: 'high_value_order',
                  ),
                  enabled: !isEditing,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedDomain,
                  decoration: const InputDecoration(labelText: 'Domain'),
                  items: const [
                    DropdownMenuItem(value: 'sales', child: Text('Sales')),
                    DropdownMenuItem(value: 'pickup', child: Text('Pickup')),
                    DropdownMenuItem(value: 'return', child: Text('Return')),
                    DropdownMenuItem(value: 'approval', child: Text('Approval')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedDomain = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priorityController,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    hintText: '1 (lower = higher priority)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: assignToController,
                  decoration: const InputDecoration(
                    labelText: 'Assign To (Role)',
                    hintText: 'admin, finance_manager, etc.',
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text('Enable this rule'),
                  value: isActive,
                  onChanged: (value) {
                    setDialogState(() {
                      isActive = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Note: Conditions',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Conditions can be edited in advanced mode. Example: {{"amount": "> 500000"}}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
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
                final ruleId = ruleIdController.text.trim();
                final priority = int.tryParse(priorityController.text) ?? 1;
                final assignTo = assignToController.text.trim();

                if (ruleId.isEmpty || assignTo.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                final newRule = RoutingRule(
                  id: rule?.id ?? '',
                  ruleId: ruleId,
                  domain: selectedDomain,
                  priority: priority,
                  conditions: rule?.conditions ?? {},
                  assignToRole: assignTo,
                  assignToUser: null,
                  isActive: isActive,
                  updatedAt: DateTime.now(),
                );

                try {
                  await _configService.saveRoutingRule(newRule);
                  Navigator.pop(context);
                  _loadRules();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(isEditing
                            ? 'Rule updated successfully'
                            : 'Rule created successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving rule: $e')),
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

  void _confirmDelete(RoutingRule rule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rule'),
        content: Text('Are you sure you want to delete rule "${rule.ruleId}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _configService.deleteRoutingRule(rule.id);
                Navigator.pop(context);
                _loadRules();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rule deleted successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting rule: $e')),
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
