import 'package:flutter/material.dart';

/// Central hub for all administration and configuration screens
class AdministrationHub extends StatelessWidget {
  const AdministrationHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        backgroundColor: Colors.red,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildAdminCard(
            context,
            title: 'Products',
            icon: Icons.inventory_2,
            color: Colors.blue,
            route: '/backoffice/admin/products',
            description: 'Manage product catalog',
          ),
          _buildAdminCard(
            context,
            title: 'UCO Grades',
            icon: Icons.grade,
            color: Colors.green,
            route: '/backoffice/admin/uco-grades',
            description: 'Manage UCO quality grades',
          ),
          _buildAdminCard(
            context,
            title: 'Payment Methods',
            icon: Icons.payment,
            color: Colors.purple,
            route: '/backoffice/admin/payment-methods',
            description: 'Configure payment options',
          ),
          _buildAdminCard(
            context,
            title: 'Order Statuses',
            icon: Icons.toggle_on,
            color: Colors.orange,
            route: '/backoffice/admin/order-statuses',
            description: 'Define order workflows',
          ),
          _buildAdminCard(
            context,
            title: 'Users & Roles',
            icon: Icons.people,
            color: Colors.teal,
            route: '/backoffice/admin/users',
            description: 'Manage user accounts',
          ),
          _buildAdminCard(
            context,
            title: 'Settings',
            icon: Icons.settings,
            color: Colors.grey,
            route: '/backoffice/admin/settings',
            description: 'System configuration',
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String route,
    required String description,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          if (route == '/backoffice/admin/users' || route == '/backoffice/admin/settings') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title - Coming soon!'),
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            Navigator.pushNamed(context, route);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
