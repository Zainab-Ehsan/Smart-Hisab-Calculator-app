import 'package:flutter/material.dart';
import '../data/db_helper.dart';
import 'add_expense_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final int groupId;
  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  bool loading = true;
  String? error;

  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      // ✅ Use the "WITH NAMES" queries from your updated DBHelper
      final ex = await DBHelper.instance.fetchGroupExpensesWithPayerName(widget.groupId);
      final tx = await DBHelper.instance.fetchGroupTransactionsWithNames(widget.groupId);

      if (!mounted) return;
      setState(() {
        expenses = List<Map<String, dynamic>>.from(ex);
        transactions = List<Map<String, dynamic>>.from(tx);
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

  Future<void> _settle(int transactionId) async {
    await DBHelper.instance.settleTransaction(transactionId);
    await _load();
  }

  String _money(dynamic v) {
    final n = (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
    return n.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Group #${widget.groupId}')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(groupId: widget.groupId),
            ),
          );
          await _load();
        },
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'DB Error:\n$error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Expenses',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...expenses.map((e) {
                      final desc = (e['description'] ?? '').toString();
                      final payerName = (e['payer_name'] ?? 'Unknown').toString();
                      final createdAt = (e['created_at'] ?? '').toString();
                      final amount = e['amount'];

                      return ListTile(
                        title: Text(desc.isEmpty ? 'No description' : desc),
                        subtitle: Text('Paid by: $payerName • $createdAt'),
                        trailing: Text('Rs ${_money(amount)}'),
                      );
                    }),

                    const Divider(),

                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Transactions (Who owes whom)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...transactions.map((t) {
                      final fromName = (t['from_name'] ?? 'User').toString();
                      final toName = (t['to_name'] ?? 'User').toString();
                      final status = (t['status'] ?? 'pending').toString();
                      final id = t['id'] as int;
                      final amount = t['amount'];

                      return ListTile(
                        title: Text('$fromName → $toName'),
                        subtitle: Text('Rs ${_money(amount)} • Status: $status'),
                        trailing: status == 'pending'
                            ? TextButton(
                                onPressed: () => _settle(id),
                                child: const Text('Settle'),
                              )
                            : const Text('Settled'),
                      );
                    }),
                  ],
                ),
    );
  }
}
