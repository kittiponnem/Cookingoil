import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/advanced_config_service.dart';
import '../../models/advanced_config_models.dart';

/// Workflow Template Builder Screen
/// Visual editor for creating and managing multi-step approval workflows
class WorkflowTemplatesScreen extends StatefulWidget {
  const WorkflowTemplatesScreen({Key? key}) : super(key: key);

  @override
  State<WorkflowTemplatesScreen> createState() =>
      _WorkflowTemplatesScreenState();
}

class _WorkflowTemplatesScreenState extends State<WorkflowTemplatesScreen> {
  final AdvancedConfigService _configService = AdvancedConfigService();
  List<WorkflowTemplate> _templates = [];
  bool _isLoading = true;
  String? _error;
  String _domainFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final templates = await _configService.getAllWorkflowTemplates();
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<WorkflowTemplate> get _filteredTemplates {
    if (_domainFilter == 'all') return _templates;
    return _templates.where((t) => t.domain == _domainFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workflow Templates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadTemplates,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTemplateBuilder(null),
            tooltip: 'Create Template',
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
                    : _filteredTemplates.isEmpty
                        ? _buildEmptyState()
                        : _buildTemplatesList(),
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
      child: SingleChildScrollView(
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
    );
  }

  Widget _buildTemplatesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = _filteredTemplates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildTemplateCard(WorkflowTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(
          template.isActive ? Icons.check_circle : Icons.cancel,
          color: template.isActive ? Colors.green : Colors.grey,
        ),
        title: Text(
          template.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            _buildDomainChip(template.domain),
            const SizedBox(width: 8),
            Text('v${template.version} • ${template.steps.length} steps'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: template.isActive,
              onChanged: (value) => _toggleTemplateStatus(template, value),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      Icon(Icons.content_copy, size: 18),
                      SizedBox(width: 8),
                      Text('Duplicate'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showTemplateBuilder(template);
                    break;
                  case 'duplicate':
                    _duplicateTemplate(template);
                    break;
                  case 'delete':
                    _confirmDelete(template);
                    break;
                }
              },
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Workflow Steps:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...template.steps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  return _buildStepItem(index + 1, step);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepNumber, WorkflowTemplateStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                stepNumber.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
                  '${step.approverType.toUpperCase()}: ${step.approverValue}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'SLA: ${step.slaHours}h',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (step.escalationRole != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.escalator_warning,
                          size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Escalate to: ${step.escalationRole}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ],
                  ],
                ),
                if (step.conditions.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Conditions: ${step.conditions.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),
        ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_tree_outlined,
              size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No templates found',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Create your first workflow template',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create Template'),
            onPressed: () => _showTemplateBuilder(null),
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
          Text('Error loading templates',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: _loadTemplates,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTemplateStatus(
      WorkflowTemplate template, bool isActive) async {
    try {
      final updated = WorkflowTemplate(
        id: template.id,
        templateId: template.templateId,
        name: template.name,
        domain: template.domain,
        version: template.version,
        isActive: isActive,
        steps: template.steps,
        createdAt: template.createdAt,
        updatedAt: DateTime.now(),
      );
      await _configService.updateWorkflowTemplate(updated);
      _loadTemplates();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isActive
              ? 'Template activated'
              : 'Template deactivated'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating template: $e')),
      );
    }
  }

  void _showTemplateBuilder(WorkflowTemplate? template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkflowTemplateBuilderPage(
          template: template,
          onSave: _loadTemplates,
        ),
      ),
    );
  }

  void _duplicateTemplate(WorkflowTemplate template) async {
    try {
      final duplicated = WorkflowTemplate(
        id: 'template_${DateTime.now().millisecondsSinceEpoch}',
        templateId: 'template_${DateTime.now().millisecondsSinceEpoch}',
        name: '${template.name} (Copy)',
        domain: template.domain,
        version: 1,
        isActive: false,
        steps: template.steps,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _configService.createWorkflowTemplate(duplicated);
      _loadTemplates();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template duplicated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error duplicating template: $e')),
      );
    }
  }

  void _confirmDelete(WorkflowTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _configService.deleteWorkflowTemplate(template.templateId);
                Navigator.pop(context);
                _loadTemplates();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Template deleted successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting template: $e')),
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

/// Workflow Template Builder Page - Full-screen editor
class WorkflowTemplateBuilderPage extends StatefulWidget {
  final WorkflowTemplate? template;
  final VoidCallback onSave;

  const WorkflowTemplateBuilderPage({
    Key? key,
    this.template,
    required this.onSave,
  }) : super(key: key);

  @override
  State<WorkflowTemplateBuilderPage> createState() =>
      _WorkflowTemplateBuilderPageState();
}

class _WorkflowTemplateBuilderPageState
    extends State<WorkflowTemplateBuilderPage> {
  final AdvancedConfigService _configService = AdvancedConfigService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late String _domain;
  late bool _isActive;
  late List<WorkflowTemplateStep> _steps;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.template?.name ?? '');
    _domain = widget.template?.domain ?? 'sales';
    _isActive = widget.template?.isActive ?? true;
    _steps = widget.template?.steps.map((s) => s).toList() ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template == null
            ? 'Create Workflow Template'
            : 'Edit Workflow Template'),
        actions: [
          TextButton(
            onPressed: _saveTemplate,
            child: const Text(
              'SAVE',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Template Name',
                hintText: 'e.g., Standard Sales Order Approval',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _domain,
              decoration: const InputDecoration(labelText: 'Domain'),
              items: const [
                DropdownMenuItem(value: 'sales', child: Text('Sales Orders')),
                DropdownMenuItem(value: 'pickup', child: Text('UCO Pickups')),
                DropdownMenuItem(value: 'return', child: Text('Returns')),
                DropdownMenuItem(value: 'approval', child: Text('General Approval')),
              ],
              onChanged: (value) {
                setState(() {
                  _domain = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Enable this template for new workflows'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Workflow Steps',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Step'),
                  onPressed: _addStep,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_steps.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.linear_scale, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No steps defined',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Step'),
                        onPressed: _addStep,
                      ),
                    ],
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final step = _steps.removeAt(oldIndex);
                    _steps.insert(newIndex, step);
                    // Update step numbers
                    for (int i = 0; i < _steps.length; i++) {
                      _steps[i] = WorkflowTemplateStep(
                        stepNo: i + 1,
                        approverType: _steps[i].approverType,
                        approverValue: _steps[i].approverValue,
                        slaHours: _steps[i].slaHours,
                        escalationRole: _steps[i].escalationRole,
                        conditions: _steps[i].conditions,
                      );
                    }
                  });
                },
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return _buildStepCard(key: ValueKey(index), index: index, step: step);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({required Key key, required int index, required WorkflowTemplateStep step}) {
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
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Step ${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _editStep(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => _deleteStep(index),
                ),
              ],
            ),
            const Divider(height: 24),
            Text('Approver: ${step.approverType} - ${step.approverValue}'),
            const SizedBox(height: 4),
            Text('SLA: ${step.slaHours} hours'),
            if (step.escalationRole != null)
              Text('Escalates to: ${step.escalationRole}'),
            if (step.conditions.isNotEmpty)
              Text('Conditions: ${step.conditions.length} rule(s)'),
          ],
        ),
      ),
    );
  }

  void _addStep() {
    _showStepEditor(null);
  }

  void _editStep(int index) {
    _showStepEditor(index);
  }

  void _deleteStep(int index) {
    setState(() {
      _steps.removeAt(index);
      // Renumber steps
      for (int i = 0; i < _steps.length; i++) {
        _steps[i] = WorkflowTemplateStep(
          stepNo: i + 1,
          approverType: _steps[i].approverType,
          approverValue: _steps[i].approverValue,
          slaHours: _steps[i].slaHours,
          escalationRole: _steps[i].escalationRole,
          conditions: _steps[i].conditions,
        );
      }
    });
  }

  void _showStepEditor(int? index) {
    final isEditing = index != null;
    final step = isEditing ? _steps[index] : null;

    String approverType = step?.approverType ?? 'role';
    final approverValueController =
        TextEditingController(text: step?.approverValue ?? '');
    final slaController =
        TextEditingController(text: step?.slaHours.toString() ?? '24');
    final escalationController =
        TextEditingController(text: step?.escalationRole ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Step' : 'Add Step'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: approverType,
                  decoration: const InputDecoration(labelText: 'Approver Type'),
                  items: const [
                    DropdownMenuItem(value: 'role', child: Text('Role')),
                    DropdownMenuItem(value: 'user', child: Text('Specific User')),
                    DropdownMenuItem(value: 'manager', child: Text('Manager')),
                    DropdownMenuItem(value: 'conditional', child: Text('Conditional')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      approverType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: approverValueController,
                  decoration: const InputDecoration(
                    labelText: 'Approver Value',
                    hintText: 'e.g., finance_manager, user123',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: slaController,
                  decoration: const InputDecoration(
                    labelText: 'SLA (hours)',
                    hintText: '24',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: escalationController,
                  decoration: const InputDecoration(
                    labelText: 'Escalation Role (optional)',
                    hintText: 'e.g., admin',
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
              onPressed: () {
                final newStep = WorkflowTemplateStep(
                  stepNo: isEditing ? step!.stepNo : _steps.length + 1,
                  approverType: approverType,
                  approverValue: approverValueController.text.trim(),
                  slaHours: int.tryParse(slaController.text) ?? 24,
                  escalationRole: escalationController.text.trim().isEmpty
                      ? null
                      : escalationController.text.trim(),
                  conditions: step?.conditions ?? {},
                );

                setState(() {
                  if (isEditing) {
                    _steps[index] = newStep;
                  } else {
                    _steps.add(newStep);
                  }
                });

                Navigator.pop(context);
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTemplate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one workflow step')),
      );
      return;
    }

    try {
      final templateId = widget.template?.templateId ??
          'template_${DateTime.now().millisecondsSinceEpoch}';
      final template = WorkflowTemplate(
        id: widget.template?.id ?? templateId,
        templateId: templateId,
        name: _nameController.text.trim(),
        domain: _domain,
        version: widget.template != null
            ? widget.template!.version + 1
            : 1,
        isActive: _isActive,
        steps: _steps,
        createdAt: widget.template?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.template == null) {
        await _configService.createWorkflowTemplate(template);
      } else {
        await _configService.updateWorkflowTemplate(template);
      }

      widget.onSave();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.template == null
              ? 'Template created successfully'
              : 'Template updated successfully'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving template: $e')),
      );
    }
  }
}
