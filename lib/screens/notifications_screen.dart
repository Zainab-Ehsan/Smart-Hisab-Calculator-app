import 'package:flutter/material.dart';
import '../data/db_helper.dart';

class NotificationsScreen extends StatefulWidget {
  final int userId;
  const NotificationsScreen({super.key, required this.userId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Logic fields remain unchanged
  bool loading = true;
  List<Map<String, dynamic>> notes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // --- LOGIC METHOD (Unchanged) ---
  Future<void> _load() async {
    final data = await DBHelper.instance.fetchNotifications(widget.userId);
    if (!mounted) return;
    setState(() {
      notes = List<Map<String, dynamic>>.from(data);
      loading = false;
    });
  }
  // ---------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications (User ID: ${widget.userId})',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 1,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : notes.isEmpty
              ? _buildEmptyState(context)
              : _buildNotificationList(),
    );
  }

  // Helper for Empty State
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'All Clear!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'No new notifications or alerts for this user. Check back after recording more expenses.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            // Add a refresh button for user convenience
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              onPressed: () {
                setState(() => loading = true);
                _load();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Notification List
  Widget _buildNotificationList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      itemCount: notes.length,
      itemBuilder: (_, i) {
        final note = notes[i];
        return _buildNotificationCard(
          message: note['message'],
          timestamp: note['created_at'],
        );
      },
    );
  }

  // Helper for individual Notification Card
  Widget _buildNotificationCard({required String message, required String timestamp}) {
    // Simple logic to try and assign an icon based on message content
    IconData icon;
    Color iconColor;

    if (message.toLowerCase().contains('settled') || message.toLowerCase().contains('paid')) {
      icon = Icons.check_circle_outline;
      iconColor = Colors.green;
    } else if (message.toLowerCase().contains('expense added')) {
      icon = Icons.receipt_long;
      iconColor = Colors.blue;
    } else if (message.toLowerCase().contains('owes')) {
      icon = Icons.warning_amber;
      iconColor = Colors.orange;
    } else {
      icon = Icons.info_outline;
      iconColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Icon(
            icon,
            color: iconColor,
            size: 30,
          ),
          title: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
          subtitle: Text(
            // Improve timestamp formatting (assuming created_at is a string)
            'Time: $timestamp',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          // Adding a subtle trailing icon for a standard log entry look
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
          onTap: () {
            // Future logic to dismiss or navigate to related expense/group
          },
        ),
      ),
    );
  }
}