import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/workflow_models.dart';
import '../../services/workflow_service.dart';
import '../../providers/auth_provider.dart';

/// Exception Queue Screen - Handle problematic workflow items
class ExceptionQueueScreen extends StatefulWidget {
  const ExceptionQueueScreen({super.key});

  @override
  State<ExceptionQueueScreen> createState() => _ExceptionQueueScreenState();
}

class _ExceptionQueueScreenState extends State<ExceptionQueueScreen> {
  final WorkflowService _workflowService = WorkflowService();
  String _selectedStatus = 'open'; // 'open', 'in_progress', 'resolved', 'all'
  String _selectedSeverity = 'all'; // 'critical', 'high', 'medium', 'low', 'all'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exception Queue'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.tune),
            onSelected: (value) {
              setState(() {
                _selectedSeverity = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Severities')),
              const PopupMenuItem(value: 'critical', child: Text('🔴 Critical')),
              const PopupMenuItem(value: 'high', child: Text('🟠 High')),
              const PopupMenuItem(value: 'medium', child: Text('🟡 Medium')),
              const PopupMenuItem(value: 'low', child: Text('🟢 Low')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Status filter tabs
          _buildStatusTabs(),
          
          // Exception list
          Expanded(
            child: _buildExceptionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildStatusChip('Open', 'open', Icons.warning_amber),
            const SizedBox(width: 8),
            _buildStatusChip('In Progress', 'in_progress', Icons.engineering),
            const SizedBox(width: 8),
            _buildStatusChip('Resolved', 'resolved', Icons.check_circle_outline),
            const SizedBox(width: 8),
            _buildStatusChip('All', 'all', Icons.list),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, IconData icon) {
    final isSelected = _selectedStatus == value;
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
          _selectedStatus = value;
        });
      },
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
    );
  }

  Widget _buildExceptionList() {
    return StreamBuilder<List<ExceptionRecord>>(
      stream: _workflowService.getExceptions(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        severity: _selectedSeverity == 'all' ? null : _selectedSeverity,
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
                Text('Error loading exceptions: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final exceptions = snapshot.data ?? [];

        if (exceptions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sentiment_satisfied_alt,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No exceptions found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Everything is running smoothly! ✨',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: exceptions.length,
          itemBuilder: (context, index) {
            return _buildExceptionCard(exceptions[index]);
          },
        );
      },
    );
  }

  Widget _buildExceptionCard(ExceptionRecord exception) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showExceptionDetails(exception),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with severity and status
              Row(
                children: [
                  _buildSeverityBadge(exception.severity),
                  const SizedBox(width: 8),
                  _buildStatusBadge(exception.status),
                  const Spacer(),
                  _buildTypeBadge(exception.entityType),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                exception.displayTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                exception.description,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Entity ID
              Text(
                'Entity: ${exception.entityId.substring(0, 8)}...',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 12),

              // Footer with timestamp and action
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimestamp(exception.occurredAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const Spacer(),
                  if (exception.status == 'open')
                    TextButton.icon(
                      onPressed: () => _assignToMe(exception),
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Assign to Me'),
                    ),
                  if (exception.status == 'in_progress')
                    ElevatedButton.icon(
                      onPressed: () => _resolveException(exception),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Resolve'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    Color color;
    String emoji;
    switch (severity) {
      case 'critical':
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
        '$emoji ${severity.toUpperCase()}',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'open':
        color = Colors.red;
        icon = Icons.warning_amber;
        break;
      case 'in_progress':
        color = Colors.blue;
        icon = Icons.engineering;
        break;
      case 'resolved':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String entityType) {
    String label;
    IconData icon;
    switch (entityType) {
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
        label = entityType;
        icon = Icons.work;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey[700], fontSize: 12),
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

  void _showExceptionDetails(ExceptionRecord exception) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.5,
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
                          exception.displayTitle,
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

                  // Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSeverityBadge(exception.severity),
                      _buildStatusBadge(exception.status),
                      _buildTypeBadge(exception.entityType),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(exception.description, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 24),

                  // Details
                  const Text(
                    'Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Entity ID', exception.entityId),
                  _buildDetailRow('Exception Type', exception.exceptionType),
                  _buildDetailRow('Occurred At',
                      '${exception.occurredAt.toString().substring(0, 19)}'),
                  if (exception.assignedTo != null)
                    _buildDetailRow('Assigned To', exception.assignedTo!),
                  if (exception.resolvedAt != null)
                    _buildDetailRow('Resolved At',
                        '${exception.resolvedAt!.toString().substring(0, 19)}'),
                  if (exception.resolution != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Resolution',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Text(exception.resolution!),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Action buttons
                  if (exception.status == 'open')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _assignToMe(exception);
                        },
                        icon: const Icon(Icons.person_add),
                        label: const Text('Assign to Me'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  if (exception.status == 'in_progress')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _resolveException(exception);
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Mark as Resolved'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.green,
                        ),
                      ),
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

  Future<void> _assignToMe(ExceptionRecord exception) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.currentUser?.uid ?? 'unknown';

      await FirebaseFirestore.instance
          .collection('exceptions')
          .doc(exception.id)
          .update({
        'assignedTo': currentUserId,
        'status': 'in_progress',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Exception assigned to you'),
              ],
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning exception: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resolveException(ExceptionRecord exception) async {
    final resolutionController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Exception'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mark this exception as resolved?'),
            const SizedBox(height: 16),
            TextField(
              controller: resolutionController,
              decoration: const InputDecoration(
                labelText: 'Resolution Details *',
                hintText: 'Describe how the issue was resolved',
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
              if (resolutionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter resolution details')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );

    if (confirmed == true && resolutionController.text.trim().isNotEmpty) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUserId = authProvider.currentUser?.uid ?? 'unknown';

        await _workflowService.resolveException(
          exceptionId: exception.id,
          resolvedBy: currentUserId,
          resolution: resolutionController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Exception resolved successfully'),
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
              content: Text('Error resolving exception: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    resolutionController.dispose();
  }
}
