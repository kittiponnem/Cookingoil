import 'package:flutter/material.dart';

class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Icon(
                Icons.local_shipping,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'Oil Manager',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Demo Mode - Select Your Role',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              
              // Customer Role
              _RoleCard(
                title: 'Customer',
                description: 'Shop for cooking oil and request UCO pickups',
                icon: Icons.person,
                color: Colors.blue,
                onTap: () => Navigator.pushReplacementNamed(context, '/customer/home'),
              ),
              
              const SizedBox(height: 16),
              
              // Driver Role
              _RoleCard(
                title: 'Driver',
                description: 'Execute deliveries and pickups with proof capture',
                icon: Icons.local_shipping,
                color: Colors.green,
                onTap: () => Navigator.pushReplacementNamed(context, '/driver/home'),
              ),
              
              const SizedBox(height: 16),
              
              // Operations Role
              _RoleCard(
                title: 'Operations',
                description: 'Manage orders, approvals, and daily operations',
                icon: Icons.business_center,
                color: Colors.orange,
                onTap: () => Navigator.pushReplacementNamed(context, '/backoffice/dashboard'),
              ),
              
              const SizedBox(height: 16),
              
              // Warehouse Role
              _RoleCard(
                title: 'Warehouse',
                description: 'Inventory management and fulfillment operations',
                icon: Icons.inventory_2,
                color: Colors.teal,
                onTap: () => Navigator.pushReplacementNamed(context, '/backoffice/dashboard'),
              ),
              
              const SizedBox(height: 16),
              
              // Fleet Role
              _RoleCard(
                title: 'Fleet Manager',
                description: 'Dispatch operations and driver assignment',
                icon: Icons.map,
                color: Colors.deepOrange,
                onTap: () => Navigator.pushReplacementNamed(context, '/backoffice/dashboard'),
              ),
              
              const SizedBox(height: 16),
              
              // Finance Role
              _RoleCard(
                title: 'Finance',
                description: 'Payment approvals and financial operations',
                icon: Icons.account_balance,
                color: Colors.purple,
                onTap: () => Navigator.pushReplacementNamed(context, '/backoffice/dashboard'),
              ),
              
              const SizedBox(height: 16),
              
              // Admin Role
              _RoleCard(
                title: 'Administrator',
                description: 'System administration and configuration',
                icon: Icons.admin_panel_settings,
                color: Colors.red,
                onTap: () => Navigator.pushReplacementNamed(context, '/backoffice/dashboard'),
              ),
              
              const SizedBox(height: 32),
              
              // Info card
              Card(
                color: Colors.amber.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade800),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Authentication temporarily disabled for demo purposes',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
