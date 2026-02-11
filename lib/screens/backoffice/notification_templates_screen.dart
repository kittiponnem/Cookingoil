import 'package:flutter/material.dart';
import '../../services/advanced_config_service.dart';
import '../../models/advanced_config_models.dart';

/// Notification Templates Management Screen
/// Rich text editor with variable placeholder support
class NotificationTemplatesScreen extends StatefulWidget {
  const NotificationTemplatesScreen({Key? key}) : super(key: key);

  @override
  State<NotificationTemplatesScreen> createState() =>
      _NotificationTemplatesScreenState();
}

class _NotificationTemplatesScreenState
    extends State<NotificationTemplatesScreen> {
  final AdvancedConfigService _configService = AdvancedConfigService();
  List<NotificationTemplate> _templates = [];
  bool _isLoading = true;
  String? _error;
  String _channelFilter = 'all';

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
      final templates = await _configService.getAllNotificationTemplates();
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

  List<NotificationTemplate> get _filteredTemplates {
    if (_channelFilter == 'all') return _templates;
    return _templates.where((t) => t.channel == _channelFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Templates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadTemplates,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditDialog(null),
            tooltip: 'Add Template',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildChannelFilter(),
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

  Widget _buildChannelFilter() {
    final channels = ['all', 'email', 'push', 'inApp'];
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter by Channel',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: channels.map((channel) {
                final isSelected = _channelFilter == channel;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(channel.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _channelFilter = channel;
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

  Widget _buildTemplateCard(NotificationTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: _buildChannelIcon(template.channel),
        title: Text(
          template.templateKey,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            _buildChannelChip(template.channel),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: template.isActive
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                template.isActive ? 'ACTIVE' : 'INACTIVE',
                style: TextStyle(
                  fontSize: 10,
                  color: template.isActive ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: () => _showEditDialog(template),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _confirmDelete(template),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (template.subjectTemplate != null) ...[
                  const Text(
                    'Subject:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                    ),
                    child: Text(template.subjectTemplate!),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Body Template:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(template.bodyTemplate),
                ),
                const SizedBox(height: 16),
                _buildVariablesChips(template.bodyTemplate),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelIcon(String channel) {
    final icons = {
      'email': Icons.email,
      'push': Icons.notifications,
      'inApp': Icons.message,
    };
    final colors = {
      'email': Colors.blue,
      'push': Colors.orange,
      'inApp': Colors.purple,
    };

    return Icon(
      icons[channel] ?? Icons.message,
      color: colors[channel] ?? Colors.grey,
    );
  }

  Widget _buildChannelChip(String channel) {
    final colors = {
      'email': Colors.blue,
      'push': Colors.orange,
      'inApp': Colors.purple,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (colors[channel] ?? Colors.grey).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        channel.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: colors[channel] ?? Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildVariablesChips(String template) {
    final regex = RegExp(r'\{\{(\w+)\}\}');
    final matches = regex.allMatches(template);
    final variables = matches.map((m) => m.group(1)!).toSet().toList();

    if (variables.isEmpty) {
      return Text(
        'No variables used',
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Variables:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: variables.map((variable) {
            return Chip(
              label: Text(
                '{{$variable}}',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              backgroundColor: Colors.green.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(4),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_outlined,
              size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No templates found',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Create your first notification template',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Template'),
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

  void _showEditDialog(NotificationTemplate? template) {
    final isEditing = template != null;
    
    final keyController =
        TextEditingController(text: template?.templateKey ?? '');
    String selectedChannel = template?.channel ?? 'email';
    final subjectController =
        TextEditingController(text: template?.subjectTemplate ?? '');
    final bodyController =
        TextEditingController(text: template?.bodyTemplate ?? '');
    bool isActive = template?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Template' : 'Add Template'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: keyController,
                    decoration: const InputDecoration(
                      labelText: 'Template Key',
                      hintText: 'approval_pending',
                    ),
                    enabled: !isEditing,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedChannel,
                    decoration: const InputDecoration(labelText: 'Channel'),
                    items: const [
                      DropdownMenuItem(value: 'email', child: Text('Email')),
                      DropdownMenuItem(value: 'push', child: Text('Push')),
                      DropdownMenuItem(value: 'inApp', child: Text('In-App')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedChannel = value!;
                      });
                    },
                  ),
                  if (selectedChannel == 'email') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject Template',
                        hintText: 'Approval Required: {{requestId}}',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: bodyController,
                    decoration: const InputDecoration(
                      labelText: 'Body Template',
                      hintText:
                          'Dear {{approverName}}, please review request {{requestId}}...',
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
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
                          'Available Variables:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            Chip(
                                label: Text('{{requestId}}',
                                    style: TextStyle(fontSize: 10))),
                            Chip(
                                label: Text('{{amount}}',
                                    style: TextStyle(fontSize: 10))),
                            Chip(
                                label: Text('{{approverName}}',
                                    style: TextStyle(fontSize: 10))),
                            Chip(
                                label: Text('{{dueDate}}',
                                    style: TextStyle(fontSize: 10))),
                            Chip(
                                label: Text('{{customerName}}',
                                    style: TextStyle(fontSize: 10))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Active'),
                    subtitle: const Text('Enable this template'),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final key = keyController.text.trim();
                final body = bodyController.text.trim();

                if (key.isEmpty || body.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please fill required fields')),
                  );
                  return;
                }

                String? subjectValue;
                if (selectedChannel == 'email') {
                  final subject = subjectController.text.trim();
                  subjectValue = subject.isEmpty ? null : subject;
                }

                final newTemplate = NotificationTemplate(
                  id: template?.id ?? '',
                  templateKey: key,
                  channel: selectedChannel,
                  subjectTemplate: subjectValue,
                  bodyTemplate: body,
                  isActive: isActive,
                  updatedAt: DateTime.now(),
                );

                try {
                  await _configService.saveNotificationTemplate(newTemplate);
                  Navigator.pop(context);
                  _loadTemplates();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(isEditing
                            ? 'Template updated successfully'
                            : 'Template created successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving template: $e')),
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

  void _confirmDelete(NotificationTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text(
            'Are you sure you want to delete template "${template.templateKey}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _configService.deleteNotificationTemplate(template.id);
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
