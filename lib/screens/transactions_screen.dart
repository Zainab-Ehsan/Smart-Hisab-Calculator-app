import 'package:flutter/material.dart';
import '../data/db_helper.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  // Logic fields remain unchanged
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> tx = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // --- LOGIC METHODS (Unchanged) ---
  Future<void> _load() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final data = await DBHelper.instance.fetchAllTransactionsWithNames();

      if (!mounted) return;
      setState(() {
        tx = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
      _showSnackbar('Failed to load transactions: $e', Colors.red);
    }
  }

  Future<void> _settle(int id, String from, String to, dynamic amount) async {
    // Show confirmation dialog before settling
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Settlement'),
        content: Text('Confirm that $from has paid ₹ ${_money(amount)} to $to?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DBHelper.instance.settleTransaction(id);
        _showSnackbar('Transaction settled successfully!', Colors.green);
        await _load();
      } catch (e) {
        _showSnackbar('Settlement failed: $e', Colors.red);
      }
    }
  }

  String _money(dynamic v) {
    final n = (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
    // Using a currency symbol (e.g., Rupee symbol) for local clarity
    return n.toStringAsFixed(2);
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  // ---------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Transactions',
            onPressed: _load,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _buildErrorState()
              : tx.isEmpty
                  ? _buildEmptyState()
                  : _buildTransactionList(),
    );
  }

  // Helper method for error state
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber, color: Colors.red, size: 60),
            const SizedBox(height: 15),
            const Text(
              'Failed to load transactions!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Error: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Reloading'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Transactions Yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Transactions are generated when expenses are added to groups.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method for the transaction list
  Widget _buildTransactionList() {
    // Separate pending items from settled items
    final pendingTx = tx.where((t) => t['status'] == 'pending').toList();
    final settledTx = tx.where((t) => t['status'] != 'pending').toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      children: [
        // --- Pending Transactions ---
        if (pendingTx.isNotEmpty) ...[
          _buildSectionHeader(context, 'Pending Settlements (${pendingTx.length})', Colors.orange),
          ...pendingTx.map((t) => _buildTransactionCard(t, isPending: true)).toList(),
          const Divider(height: 30),
        ],
        
        // --- Settled Transactions ---
        _buildSectionHeader(context, 'Settled History (${settledTx.length})', Colors.green),
        ...settledTx.map((t) => _buildTransactionCard(t, isPending: false)).toList(),
      ],
    );
  }

  // Helper for Section Headers
  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // Helper for individual transaction card
  Widget _buildTransactionCard(Map<String, dynamic> t, {required bool isPending}) {
    final id = t['id'] as int;
    final fromName = (t['from_name'] ?? 'User').toString();
    final toName = (t['to_name'] ?? 'User').toString();
    final amount = t['amount'];
    final groupId = t['group_id'];
    final createdAt = (t['created_at'] ?? '').toString().split(' ')[0]; // Use date only

    Color statusColor = isPending ? Colors.orange.shade800 : Colors.green.shade600;
    IconData icon = isPending ? Icons.pending_actions : Icons.check_circle_outline;
    
    // The key visual improvement: a Card with a structured flow
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        elevation: isPending ? 4 : 1, // Higher elevation for pending items
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: isPending ? BorderSide(color: Colors.orange.shade200, width: 1.5) : BorderSide.none,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Icon(icon, color: statusColor, size: 30),
          title: Text(
            '$fromName pays $toName',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              // Main amount display
              Text(
                '₹ ${_money(amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isPending ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 4),
              // Contextual details
              Text(
                'Group: $groupId • Date: $createdAt',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          trailing: isPending
              ? ElevatedButton(
                  onPressed: () => _settle(id, fromName, toName, amount), // Call modified settle with context
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text('Settle', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              : Text(
                  'Settled',
                  style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}