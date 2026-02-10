import 'package:flutter/material.dart';
import '../../models/workflow_models.dart';
import '../../services/workflow_service.dart';

/// Audit Log Screen - View all workflow actions and changes
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final WorkflowService _workflowService = WorkflowService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedEntityType = 'all'; // 'all', 'sales_order', 'uco_pickup', 'return_request'
  String? _searchQuery;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by entity ID or action...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = null;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.isEmpty ? null : value;
                });
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Entity type filter
          _buildEntityTypeFilter(),
          
          // Audit log list
          Expanded(
            child: _buildAuditLogList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEntityTypeFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildFilterChip('All', 'all', Icons.list),
            const SizedBox(width: 8),
            _buildFilterChip('Sales Orders', 'sales_order', Icons.shopping_cart),
            const SizedBox(width: 8),
            _buildFilterChip('UCO Pickups', 'uco_pickup', Icons.recycling),
            const SizedBox(width: 8),
            _buildFilterChip('Returns', 'return_request', Icons.keyboard_return),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedEntityType == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedEntityType = value;
        });
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
    );
  }

  Widget _buildAuditLogList() {
    return StreamBuilder<List<AuditLogEntry>>(
      stream: _workflowService.getAuditLog(
        entityType: _selectedEntityType == 'all' ? null : _selectedEntityType,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading audit log: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        var entries = snapshot.data ?? [];

        // Apply search filter
        if (_searchQuery != null && _searchQuery!.isNotEmpty) {
          entries = entries.where((entry) {
            return entry.entityId.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
                   entry.action.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
                   (entry.notes?.toLowerCase().contains(_searchQuery!.toLowerCase()) ?? false);
          }).toList();
        }

        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No audit log entries',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery != null
                      ? 'No results matching your search'
                      : 'No activity recorded yet',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        // Group entries by date
        final groupedEntries = <String, List<AuditLogEntry>>{};
        for (var entry in entries) {
          final dateKey = _formatDate(entry.performedAt);
          groupedEntries.putIfAbsent(dateKey, () => []);
          groupedEntries[dateKey]!.add(entry);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groupedEntries.length,
          itemBuilder: (context, index) {
            final dateKey = groupedEntries.keys.elementAt(index);
            final dateEntries = groupedEntries[dateKey]!;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    dateKey,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                
                // Entries for this date
                ...dateEntries.map((entry) => _buildAuditLogEntry(entry)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAuditLogEntry(AuditLogEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showEntryDetails(entry),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Action icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getActionColor(entry.action).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getActionIcon(entry.action),
                  size: 20,
                  color: _getActionColor(entry.action),
                ),
              ),
              const SizedBox(width: 12),
              
              // Entry details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.displayAction,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(entry.performedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.entityType.replaceAll('_', ' ').toUpperCase()} • ${entry.entityId.substring(0, 8)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.notes!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (entry.fromStatus != null || entry.toStatus != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (entry.fromStatus != null) ...[
                            _buildStatusChip(entry.fromStatus!),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward, size: 12),
                            const SizedBox(width: 4),
                          ],
                          if (entry.toStatus != null)
                            _buildStatusChip(entry.toStatus!),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Chevron
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'created':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'status_changed':
        return Colors.orange;
      case 'assigned':
        return Colors.purple;
      case 'exception_raised':
        return Colors.red;
      case 'exception_resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'created':
        return Icons.add_circle_outline;
      case 'approved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'status_changed':
        return Icons.sync;
      case 'assigned':
        return Icons.person_add_outlined;
      case 'exception_raised':
        return Icons.warning_amber_outlined;
      case 'exception_resolved':
        return Icons.check_circle_outline;
      default:
        return Icons.info_outline;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      return 'Today';
    } else if (entryDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showEntryDetails(AuditLogEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getActionColor(entry.action).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getActionIcon(entry.action),
                          size: 24,
                          color: _getActionColor(entry.action),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.displayAction,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Details
                  _buildDetailRow('Entity Type', entry.entityType),
                  _buildDetailRow('Entity ID', entry.entityId),
                  _buildDetailRow('Workflow Instance', entry.workflowInstanceId),
                  _buildDetailRow('Performed By', entry.performedBy),
                  _buildDetailRow('Performed At',
                      '${entry.performedAt.toString().substring(0, 19)}'),
                  
                  if (entry.fromStatus != null)
                    _buildDetailRow('From Status', entry.fromStatus!),
                  if (entry.toStatus != null)
                    _buildDetailRow('To Status', entry.toStatus!),
                  
                  if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Notes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(entry.notes!),
                    ),
                  ],
                  
                  if (entry.changes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Changes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: entry.changes.entries.map((change) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${change.key}: ',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Expanded(
                                  child: Text('${change.value}'),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
