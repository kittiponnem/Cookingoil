import 'package:flutter/material.dart';

class DispatcherHomeScreen extends StatefulWidget {
  const DispatcherHomeScreen({super.key});

  @override
  State<DispatcherHomeScreen> createState() => _DispatcherHomeScreenState();
}

class _DispatcherHomeScreenState extends State<DispatcherHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatch Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Deliveries',
          ),
          NavigationDestination(
            icon: Icon(Icons.recycling_outlined),
            selectedIcon: Icon(Icons.recycling),
            label: 'Pickups',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Live Map',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildDeliveries();
      case 2:
        return _buildPickups();
      case 3:
        return _buildLiveMap();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                icon: Icons.pending_actions,
                label: 'Pending Orders',
                value: '12',
                color: Colors.orange,
              ),
              _buildStatCard(
                icon: Icons.local_shipping,
                label: 'In Transit',
                value: '8',
                color: Colors.blue,
              ),
              _buildStatCard(
                icon: Icons.check_circle,
                label: 'Completed Today',
                value: '24',
                color: Colors.green,
              ),
              _buildStatCard(
                icon: Icons.recycling,
                label: 'Pickups Pending',
                value: '5',
                color: Colors.purple,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Active Drivers Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Drivers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedIndex = 3),
                child: const Text('View Map'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          _buildDriverCard(
            name: 'John Smith',
            vehicle: 'TRUCK-001',
            status: 'En Route',
            activeJobs: 3,
            completedJobs: 2,
          ),
          _buildDriverCard(
            name: 'Sarah Johnson',
            vehicle: 'TRUCK-002',
            status: 'Available',
            activeJobs: 0,
            completedJobs: 5,
          ),

          const SizedBox(height: 24),

          // Exceptions Section
          const Text(
            'Exceptions & Alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            child: ListTile(
              leading: Icon(Icons.info_outline, color: Colors.orange.shade700),
              title: const Text('No critical alerts'),
              subtitle: const Text('All operations running smoothly'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard({
    required String name,
    required String vehicle,
    required String status,
    required int activeJobs,
    required int completedJobs,
  }) {
    final statusColor = status == 'Available' ? Colors.green : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.2),
          child: Icon(Icons.person, color: statusColor),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Vehicle: $vehicle'),
            const SizedBox(height: 2),
            Text('Active: $activeJobs | Completed: $completedJobs'),
          ],
        ),
        trailing: Chip(
          label: Text(
            status,
            style: const TextStyle(fontSize: 11),
          ),
          backgroundColor: statusColor.withValues(alpha: 0.2),
          labelStyle: TextStyle(color: statusColor),
        ),
        onTap: () {
          // View driver details
        },
      ),
    );
  }

  Widget _buildDeliveries() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'pending', label: Text('Pending')),
                    ButtonSegment(value: 'assigned', label: Text('Assigned')),
                    ButtonSegment(value: 'transit', label: Text('In Transit')),
                  ],
                  selected: const {'pending'},
                  onSelectionChanged: (Set<String> selection) {},
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildOrderCard(
                orderNumber: 'SO-2024-001',
                customer: 'ABC Restaurant',
                address: '123 Main Street',
                timeWindow: '09:00 AM - 12:00 PM',
                status: 'Pending',
                onAssign: () {
                  // Show driver assignment dialog
                },
              ),
              _buildOrderCard(
                orderNumber: 'SO-2024-002',
                customer: 'XYZ Hotel',
                address: '456 Oak Avenue',
                timeWindow: '01:00 PM - 03:00 PM',
                status: 'Pending',
                onAssign: () {
                  // Show driver assignment dialog
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard({
    required String orderNumber,
    required String customer,
    required String address,
    required String timeWindow,
    required String status,
    required VoidCallback onAssign,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  orderNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Chip(
                  label: Text(status, style: const TextStyle(fontSize: 11)),
                  backgroundColor: Colors.orange.withValues(alpha: 0.2),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              customer,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  timeWindow,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('View Details'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onAssign,
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Assign Driver'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickups() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.recycling, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'UCO Pickup Requests',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Manage pickup requests and assignments',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMap() {
    return Stack(
      children: [
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Live Driver Map',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Real-time driver location tracking',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}
