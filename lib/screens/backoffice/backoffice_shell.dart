import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'approval_inbox_screen.dart';
import 'exception_queue_screen.dart';
import 'audit_log_screen.dart';

/// Backoffice shell with drawer navigation for admin, ops, warehouse, fleet, finance
class BackofficeShell extends StatefulWidget {
  const BackofficeShell({super.key});

  @override
  State<BackofficeShell> createState() => _BackofficeShellState();
}

class _BackofficeShellState extends State<BackofficeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle()),
        actions: [
          // Notifications
          IconButton(
            icon: const Badge(
              label: Text('3'),
              child: Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          
          // Profile
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              icon: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  (user?.displayName ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              onSelected: (value) {
                if (value == 'profile') {
                  // TODO: Navigate to profile
                } else if (value == 'logout') {
                  authProvider.signOut();
                  Navigator.of(context).pushReplacementNamed('/auth/landing');
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(user?.displayName ?? 'User'),
                          Text(
                            _getRoleDisplay(user),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 12),
                      Text('Sign Out'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context, user),
      body: _buildBody(),
    );
  }

  Widget _buildDrawer(BuildContext context, dynamic user) {
    if (user == null) return const SizedBox.shrink();
    
    // Temporary: Show all menus in demo mode
    // TODO: Implement role-based visibility with enhanced user model
    final canAccessDispatch = true;  // user.canAccessDispatch
    final canAccessInventory = true;  // user.canAccessInventory
    final canAccessFinance = true;    // user.canAccessFinance
    final canAccessAdministration = true;  // user.canAccessAdministration
    final canViewAuditLogs = true;    // user.canViewAuditLogs

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer header
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.local_shipping,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  'Oil Manager',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Backoffice Portal',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),

          // Dashboard
          _buildDrawerItem(
            context,
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            title: 'Dashboard',
            index: 0,
          ),

          // My Tasks
          _buildDrawerItem(
            context,
            icon: Icons.task_outlined,
            selectedIcon: Icons.task,
            title: 'My Tasks',
            index: 1,
            badge: '5',
          ),

          const Divider(),

          // Sales Orders
          _buildDrawerItem(
            context,
            icon: Icons.shopping_cart_outlined,
            selectedIcon: Icons.shopping_cart,
            title: 'Sales Orders',
            index: 2,
          ),

          // UCO Orders
          _buildDrawerItem(
            context,
            icon: Icons.oil_barrel_outlined,
            selectedIcon: Icons.oil_barrel,
            title: 'UCO Orders',
            index: 3,
          ),

          // Returns & Refunds
          _buildDrawerItem(
            context,
            icon: Icons.assignment_return_outlined,
            selectedIcon: Icons.assignment_return,
            title: 'Returns & Refunds',
            index: 4,
          ),

          const Divider(),

          // Dispatch & Fleet (fleet/admin only)
          if (canAccessDispatch)
            _buildDrawerItem(
              context,
              icon: Icons.local_shipping_outlined,
              selectedIcon: Icons.local_shipping,
              title: 'Dispatch & Fleet',
              index: 5,
            ),

          // Inventory (warehouse/admin only)
          if (canAccessInventory)
            _buildDrawerItem(
              context,
              icon: Icons.inventory_2_outlined,
              selectedIcon: Icons.inventory_2,
              title: 'Inventory',
              index: 6,
            ),

          const Divider(),

          // Customers
          _buildDrawerItem(
            context,
            icon: Icons.people_outline,
            selectedIcon: Icons.people,
            title: 'Customers',
            index: 7,
          ),

          // Finance (finance/admin only)
          if (canAccessFinance)
            _buildDrawerItem(
              context,
              icon: Icons.account_balance_outlined,
              selectedIcon: Icons.account_balance,
              title: 'Finance',
              index: 8,
            ),

          // Reports
          _buildDrawerItem(
            context,
            icon: Icons.bar_chart_outlined,
            selectedIcon: Icons.bar_chart,
            title: 'Reports',
            index: 9,
          ),

          const Divider(),

          // Approval Inbox (Workflow Engine)
          _buildDrawerItem(
            context,
            icon: Icons.approval_outlined,
            selectedIcon: Icons.approval,
            title: 'Approval Inbox',
            index: 13,
            badge: '5', // Dynamic count from workflow service
          ),

          // Administration (admin only)
          if (canAccessAdministration)
            _buildDrawerItem(
              context,
              icon: Icons.admin_panel_settings_outlined,
              selectedIcon: Icons.admin_panel_settings,
              title: 'Administration',
              index: 10,
            ),

          // Exception Queue
          _buildDrawerItem(
            context,
            icon: Icons.error_outline,
            selectedIcon: Icons.error,
            title: 'Exception Queue',
            index: 11,
            badge: '2',
          ),

          // Audit Log (admin/finance read)
          if (canViewAuditLogs)
            _buildDrawerItem(
              context,
              icon: Icons.history,
              selectedIcon: Icons.history,
              title: 'Audit Log',
              index: 12,
            ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    required int index,
    String? badge,
  }) {
    final isSelected = _selectedIndex == index;

    return ListTile(
      leading: Icon(
        isSelected ? selectedIcon : icon,
        color: isSelected ? Theme.of(context).primaryColor : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      trailing: badge != null
          ? Badge(
              label: Text(badge),
              backgroundColor: Colors.red,
            )
          : null,
      selected: isSelected,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
        
        // Navigate to specific pages based on index
        if (index == 10) {
          // Administration - navigate to admin hub
          Navigator.pushNamed(context, '/backoffice/admin/hub');
        }
      },
    );
  }

  Widget _buildBody() {
    // Show appropriate screen based on selected index
    switch (_selectedIndex) {
      case 11: // Exception Queue
        return const ExceptionQueueScreen();
      case 12: // Audit Log
        return const AuditLogScreen();
      case 13: // Approval Inbox
        return const ApprovalInboxScreen();
      default:
        // Default placeholder for other screens
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction_outlined,
                size: 64,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                _getPageTitle(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
    }
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'My Tasks';
      case 2:
        return 'Sales Orders';
      case 3:
        return 'UCO Orders';
      case 4:
        return 'Returns & Refunds';
      case 5:
        return 'Dispatch & Fleet';
      case 6:
        return 'Inventory';
      case 7:
        return 'Customers';
      case 8:
        return 'Finance';
      case 9:
        return 'Reports';
      case 10:
        return 'Administration';
      case 11:
        return 'Exception Queue';
      case 12:
        return 'Audit Log';
      case 13:
        return 'Approval Inbox';
      default:
        return 'Oil Manager';
    }
  }
  
  String _getRoleDisplay(dynamic user) {
    if (user == null) return '';
    // Temporary role display - will use user.roleDisplayName with enhanced model
    return 'Backoffice Staff';
  }
}
