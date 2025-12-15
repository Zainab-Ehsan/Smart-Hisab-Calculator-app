import 'package:flutter/material.dart';

import 'users_screen.dart';
import 'groups_list_screen.dart';
import 'balances_screen.dart';
import 'transactions_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // For lab demo: pick a user to view notifications.
  // You can later replace this with "current logged-in user".
  final int demoUserId = 1;

  @override
  Widget build(BuildContext context) {
    // Define the list of menu items
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Groups',
        'subtitle': 'Create, join, and manage shared expenses',
        'icon': Icons.groups_2_outlined, // More modern icon
        'screen': const GroupsListScreen(),
        'color': Colors.blue.shade100,
      },
      {
        'title': 'Balances',
        'subtitle': 'Settle up with friends and view who owes what',
        'icon': Icons.account_balance_wallet_outlined,
        'screen': const BalancesScreen(),
        'color': Colors.green.shade100,
      },
      {
        'title': 'Transactions',
        'subtitle': 'Detailed history of all your past expenses',
        'icon': Icons.receipt_long_outlined,
        'screen': const TransactionsScreen(),
        'color': Colors.orange.shade100,
      },
      {
        'title': 'Users',
        'subtitle': 'Add and manage registered members',
        'icon': Icons.person_add_alt_1_outlined,
        'screen': const UsersScreen(),
        'color': Colors.purple.shade100,
      },
      {
        'title': 'Notifications',
        'subtitle': 'View your alerts and activity log',
        'icon': Icons.notifications_active_outlined,
        'screen': NotificationsScreen(userId: demoUserId),
        'color': Colors.red.shade100,
      },
    ];

    // --- Build the UI ---
    return Scaffold(
      appBar: AppBar(
        title: const Text('HISAB', style: TextStyle(fontWeight: FontWeight.bold)),
        // Adding a subtle elevation and background color for contrast
        elevation: 4,
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.9),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner/Overview Card
              const Card(
                elevation: 4,
                margin: EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to HISAB!',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Manage your shared expenses and keep track of who owes whom.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 12),
                      // Could add a small summary/stat here in a real app
                      // Example: Text('Total pending: \$150.00', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              // Main Menu Grid
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 16),
                child: Text(
                  'Quick Access',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              
              // Using GridView for a visual, dashboard-like look
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // Important for nested scroll views
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 items per row
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 1.0, // Control the height/width ratio of the tiles
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return _buildMenuItemCard(context, item);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Extracted function to build a single card item
  Widget _buildMenuItemCard(BuildContext context, Map<String, dynamic> item) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15.0),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => item['screen'] as Widget),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: item['color'] as Color, // Use the color from the map
            borderRadius: BorderRadius.circular(15.0),
          ),
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                item['icon'] as IconData,
                size: 40,
                color: Theme.of(context).colorScheme.primary, // Theming the icon
              ),
              const SizedBox(height: 10),
              Text(
                item['title'] as String,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item['subtitle'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
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