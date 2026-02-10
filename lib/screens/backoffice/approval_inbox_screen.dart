import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/workflow_models.dart';
import '../../services/workflow_service.dart';
import '../../providers/auth_provider.dart';

/// Approval Inbox Screen - Centralized approval queue for all workflows
class ApprovalInboxScreen extends StatefulWidget {
  const ApprovalInboxScreen({super.key});

  @override
  State<ApprovalInboxScreen> createState() => _ApprovalInboxScreenState();
}

class _ApprovalInboxScreenState extends State<ApprovalInboxScreen> {
  final WorkflowService _workflowService = WorkflowService();
  String _selectedFilter = 'all'; // 'all', 'sales_order', 'uco_pickup', 'return_request'
  String _selectedPriority = 'all'; // 'all', 'urgent', 'high', 'medium', 'low'

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.currentUser?.role?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Inbox'),
        actions: [
          // Priority filter
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedPriority = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Priorities')),
              const PopupMenuItem(value: 'urgent', child: Text('🔴 Urgent')),
              const PopupMenuItem(value: 'high', child: Text('🟠 High')),
              const PopupMenuItem(value: 'medium', child: Text('🟡 Medium')),
              const PopupMenuItem(value: 'low', child: Text('🟢 Low')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Workflow type filter tabs
          _buildFilterTabs(),
          
          // Statistics summary
          _buildStatisticsSummary(userRole),
          
          // Approval list
          Expanded(
            child: _buildApprovalList(userRole),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildFilterChip('All', 'all', Icons.inbox),
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
    final isSelected = _selectedFilter == value;
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
          _selectedFilter = value;
        });
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
    );
  }

  Widget _buildStatisticsSummary(String userRole) {
    return FutureBuilder<Map<String, int>>(
      future: _workflowService.getWorkflowStatistics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildStatCard(
                'Pending',
                stats['pending_approvals'] ?? 0,
                Icons.pending_actions,
                Colors.orange,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Overdue',
                stats['overdue_workflows'] ?? 0,
                Icons.alarm,
                Colors.red,
              ),
              const SizedBox(width: 12),
              _buildStatCard(
                'Active',
                stats['active_workflows'] ?? 0,
                Icons.work_outline,
                Colors.blue,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalList(String userRole) {
    return StreamBuilder<List<ApprovalRequest>>(
      stream: _workflowService.getPendingApprovals(
        userRole: userRole,
        workflowType: _selectedFilter == 'all' ? null : _selectedFilter,
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
                Text('Error loading approvals: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        var approvals = snapshot.data ?? [];

        // Filter by priority
        if (_selectedPriority != 'all') {
          approvals = approvals.where((a) => a.priority == _selectedPriority).toList();
        }

        if (approvals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No pending approvals',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'All caught up! 🎉',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: approvals.length,
          itemBuilder: (context, index) {
            return _buildApprovalCard(approvals[index]);
          },
        );
      },
    );
  }

  Widget _buildApprovalCard(ApprovalRequest approval) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showApprovalDetails(approval),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with priority and type
              Row(
                children: [
                  _buildPriorityBadge(approval.priority),
                  const SizedBox(width: 8),
                  _buildTypeBadge(approval.workflowType),
                  const Spacer(),
                  if (approval.isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.alarm, size: 14, color: Colors.red),
                          SizedBox(width: 4),
                          Text(
                            'Overdue',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                approval.displayTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Entity ID
              Text(
                'ID: ${approval.entityId.substring(0, 8)}...',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 8),

              // Request data preview
              if (approval.requestData.isNotEmpty)
                _buildRequestDataPreview(approval.requestData),

              const SizedBox(height: 12),

              // Footer with timestamp and actions
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimestamp(approval.requestedAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _rejectApproval(approval),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _approveRequest(approval),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    String emoji;
    switch (priority) {
      case 'urgent':
        color = Colors.red;
        emoji = '🔴';
        break;
      case 'high':
        color = Colors.orange;
        emoji = '🟠';
        break;
      case 'medium':
        color = Colors.amber;
        emoji = '🟡';
        break;
      case 'low':
        color = Colors.green;
        emoji = '🟢';
        break;
      default:
        color = Colors.grey;
        emoji = '⚪';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$emoji ${priority.toUpperCase()}',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String workflowType) {
    String label;
    IconData icon;
    switch (workflowType) {
      case 'sales_order':
        label = 'Sales Order';
        icon = Icons.shopping_cart;
        break;
      case 'uco_pickup':
        label = 'UCO Pickup';
        icon = Icons.recycling;
        break;
      case 'return_request':
        label = 'Return';
        icon = Icons.keyboard_return;
        break;
      default:
        label = workflowType;
        icon = Icons.work;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.blue, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestDataPreview(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...data.entries.take(3).map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text(
                    '${entry.key}: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${entry.value}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (data.entries.length > 3)
            Text(
              '+${data.entries.length - 3} more...',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showApprovalDetails(ApprovalRequest approval) {
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
                      Expanded(
                        child: Text(
                          approval.displayTitle,
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
                  const SizedBox(height: 16),

                  // Status badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPriorityBadge(approval.priority),
                      _buildTypeBadge(approval.workflowType),
                      if (approval.isOverdue)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '⚠️ OVERDUE',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Details
                  _buildDetailRow('Entity ID', approval.entityId),
                  _buildDetailRow('Request Type', approval.requestType),
                  _buildDetailRow('Requested At',
                      '${approval.requestedAt.toString().substring(0, 19)}'),
                  if (approval.slaDeadline != null)
                    _buildDetailRow('SLA Deadline',
                        '${approval.slaDeadline!.toString().substring(0, 19)}'),
                  const SizedBox(height: 16),

                  // Request data
                  const Text(
                    'Request Details',
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
                      children: approval.requestData.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.key}: ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${entry.value}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _rejectApproval(approval);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _approveRequest(approval);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
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
            width: 120,
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

  Future<void> _approveRequest(ApprovalRequest approval) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.uid ?? 'unknown';

      await _workflowService.approveRequest(
        requestId: approval.id,
        approvedBy: currentUserId,
        notes: 'Approved via Approval Inbox',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Approval request approved successfully'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectApproval(ApprovalRequest approval) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Approval Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject this ${approval.requestType}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason *',
                hintText: 'Enter reason for rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a rejection reason')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUserId = authProvider.currentUser?.uid ?? 'unknown';

        await _workflowService.rejectRequest(
          requestId: approval.id,
          rejectedBy: currentUserId,
          reason: reasonController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.cancel, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Approval request rejected'),
                ],
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error rejecting request: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    reasonController.dispose();
  }
}
