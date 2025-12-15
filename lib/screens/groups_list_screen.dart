import 'package:flutter/material.dart';
import '../data/db_helper.dart'; // Assuming this provides group data
import 'group_details_screen.dart';
import 'group_screen.dart';

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({super.key});

  @override
  State<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends State<GroupsListScreen> {
  bool loading = true;
  List<Map<String, dynamic>> groups = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // --- LOGIC REMAINS UNCHANGED ---
  Future<void> _load() async {
    final data = await DBHelper.instance.fetchGroups();
    if (!mounted) return;
    setState(() {
      groups = List<Map<String, dynamic>>.from(data);
      loading = false;
    });
  }
  // ---------------------------------

  @override
  Widget build(BuildContext context) {
    // Determine the color scheme
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Groups',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 1, // Add a subtle shadow
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Group'), // Extended FAB is more descriptive
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GroupScreen()),
          );
          // Reload the list after returning from the group creation screen
          setState(() => loading = true);
          _load();
        },
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : groups.isEmpty
              ? _buildEmptyState(context)
              : _buildGroupList(context, colorScheme),
    );
  }

  // Helper method for improved empty state UI
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_alt_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 20),
            const Text(
              'No groups yet!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a new group to start sharing expenses with friends, family, or flatmates.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            // Suggesting the action clearly
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Group'),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GroupScreen()),
                );
                setState(() => loading = true);
                _load();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for building the group list with Card widgets
  Widget _buildGroupList(BuildContext context, ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: groups.length,
      itemBuilder: (_, i) {
        final g = groups[i];
        
        // Use a Card or Container for visual separation and depth
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              // Use a CircleAvatar or custom icon for a better visual cue
              leading: CircleAvatar(
                backgroundColor: colorScheme.secondary.withOpacity(0.1),
                child: Icon(Icons.group, color: colorScheme.secondary),
              ),
              title: Text(
                g['name'],
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              // Subtitle (If you can add a member count or total balance, that would be great here!
              // For now, using a placeholder/static text to not change logic)
              subtitle: const Text('Tap to view expenses and members'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () async {
                // Navigating to details screen
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupDetailsScreen(groupId: g['id']),
                  ),
                );
                // Reload data upon returning from the details screen
                setState(() => loading = true);
                _load();
              },
            ),
          ),
        );
      },
    );
  }
}