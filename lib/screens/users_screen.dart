import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'add_user.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  // Logic fields remain unchanged
  List<UserModel> users = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // --- LOGIC METHOD (Unchanged) ---
  Future<void> _loadUsers() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final data = await UserService.getUsers();

      if (!mounted) return;
      setState(() {
        users = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  // Helper method to navigate and reload
  Future<void> _navigateToAddUser() async {
    final ok = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddUserScreen()),
    );

    if (ok == true) {
      _loadUsers();
    }
  }
  // ---------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 1,
      ),
      // Use Extended FAB for better visibility and description
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add New User'),
        onPressed: _navigateToAddUser,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return _buildErrorState();
    }

    if (users.isEmpty) {
      return _buildEmptyState();
    }

    // List View with improved UI
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      itemCount: users.length,
      itemBuilder: (_, i) => _buildUserCard(users[i], context),
    );
  }

  // Helper for Error State with Reload button
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 15),
            Text(
              'Failed to load users!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_off_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'No registered users.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your friends, family, or colleagues to start tracking expenses.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            // Call the same navigation logic as the FAB
            OutlinedButton.icon(
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add First User'),
              onPressed: _navigateToAddUser,
            ),
          ],
        ),
      ),
    );
  }

  // Helper for individual user card
  Widget _buildUserCard(UserModel user, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: 4, // Higher elevation for better pop-out effect
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              user.username[0].toUpperCase(), // Use first letter of name
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            user.username,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                user.email,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              Text(
                'User ID: ${user.id}',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          // Add a trailing indicator, though it doesn't navigate anywhere in the current logic
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () {
            // Can add future logic here like editing the user, but keeping it empty to maintain current logic
          },
        ),
      ),
    );
  }
}