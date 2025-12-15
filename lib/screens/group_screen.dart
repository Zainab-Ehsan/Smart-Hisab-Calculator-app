import 'package:flutter/material.dart';
import '../data/db_helper.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  // Logic fields remain unchanged
  final groupNameCtrl = TextEditingController();
  int? selectedUser;
  int? createdGroupId;
  List<Map<String, dynamic>> users = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // --- LOGIC METHODS (Unchanged) ---
  Future<void> _loadUsers() async {
    final data = await DBHelper.instance.fetchUsers();
    if (!mounted) return;
    setState(() {
      users = List<Map<String, dynamic>>.from(data);
      loading = false;
    });
  }

  Future<void> _createGroup() async {
    final name = groupNameCtrl.text.trim();
    if (name.isEmpty) {
      _showSnackbar(context, 'Please enter a group name.', Colors.red);
      return;
    }

    final gid = await DBHelper.instance.insertGroup(name);
    setState(() => createdGroupId = gid);

    _showSnackbar(context, 'Group "${name}" successfully created!', Colors.green);
  }

  Future<void> _addMember() async {
    if (createdGroupId == null) {
      _showSnackbar(context, 'You must create the group first.', Colors.red);
      return;
    }
    if (selectedUser == null) {
      _showSnackbar(context, 'Please select a user to add.', Colors.red);
      return;
    }

    await DBHelper.instance.insertGroupMember(createdGroupId!, selectedUser!);

    _showSnackbar(context, 'Member successfully added to the group!', Colors.blue);
    setState(() {
      // Clear the selection after adding
      selectedUser = null;
    });
  }

  void _showSnackbar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    groupNameCtrl.dispose();
    super.dispose();
  }
  // ---------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 1,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- STEP 1: CREATE GROUP ---
                  _buildSectionHeader(context, '1. Group Information', createdGroupId != null),
                  const SizedBox(height: 10),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: createdGroupId != null
                          ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                          : BorderSide.none,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: groupNameCtrl,
                            enabled: createdGroupId == null, // Disable editing after creation
                            decoration: InputDecoration(
                              labelText: 'Group Name',
                              hintText: 'e.g., Weekend Trip, Flatmates, Gym Buddies',
                              prefixIcon: const Icon(Icons.people_alt_outlined),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),

                          ElevatedButton.icon(
                            onPressed: createdGroupId == null ? _createGroup : null,
                            icon: Icon(createdGroupId == null ? Icons.add_circle : Icons.check_circle),
                            label: Text(createdGroupId == null ? 'Create Group' : 'Group Created (ID: $createdGroupId)'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              backgroundColor: createdGroupId == null 
                                ? Theme.of(context).colorScheme.primary 
                                : Colors.green, // Color change when created
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  
                  // --- STEP 2: ADD MEMBERS ---
                  _buildSectionHeader(context, '2. Add Members', false),
                  const SizedBox(height: 10),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: createdGroupId == null ? Colors.grey.shade100 : Colors.white, // Visual hint that this section is locked
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: createdGroupId == null
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text(
                                  '🔒 Complete Step 1 to add members.',
                                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                                ),
                              ),
                            )
                          : (users.isEmpty
                              ? const Text('No users found. Please add users on the Users screen first.', style: TextStyle(color: Colors.red))
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    DropdownButtonFormField<int>(
                                      decoration: const InputDecoration(
                                        labelText: 'Select User to Add',
                                        prefixIcon: Icon(Icons.person_add),
                                        border: OutlineInputBorder(),
                                      ),
                                      value: selectedUser,
                                      items: users.map((u) {
                                        return DropdownMenuItem<int>(
                                          value: u['id'] as int,
                                          child: Text('${u['username']} (ID: ${u['id']})'),
                                        );
                                      }).toList(),
                                      onChanged: (v) => setState(() => selectedUser = v),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      onPressed: _addMember,
                                      icon: const Icon(Icons.group_add),
                                      label: const Text('Add Selected Member'),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(double.infinity, 50),
                                        backgroundColor: Theme.of(context).colorScheme.secondary,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                )),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Helper widget for section headers
  Widget _buildSectionHeader(BuildContext context, String title, bool completed) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 8),
        if (completed)
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
      ],
    );
  }
}