import 'package:flutter/material.dart';
import '../data/db_helper.dart';
import '../models/expense_model.dart';
import '../models/user_model.dart';
import '../services/expense_service.dart';
import '../services/user_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final int groupId;
  const AddExpenseScreen({super.key, required this.groupId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  // Use a GlobalKey for form validation
  final _formKey = GlobalKey<FormState>();

  // Logic fields remain unchanged
  final descCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  int? paidBy;
  bool loading = true;
  bool saving = false;
  List<UserModel> users = [];
  List<int> memberIds = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // --- LOGIC METHOD (Unchanged) ---
  Future<void> _load() async {
    try {
      final allUsers = await UserService.getUsers();
      final members = await DBHelper.instance.fetchGroupMembers(widget.groupId);

      // group_members rows: {id, group_id, user_id}
      final ids = members.map((m) => m['user_id'] as int).toList();

      if (!mounted) return;
      setState(() {
        users = allUsers;
        memberIds = ids;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _showSnackbar(context, 'Load failed: $e', Colors.red);
    }
  }

  @override
  void dispose() {
    descCtrl.dispose();
    amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    final desc = descCtrl.text.trim();
    final amount = double.tryParse(amountCtrl.text.trim());

    if (!_formKey.currentState!.validate() || paidBy == null) {
      _showSnackbar(context, 'Please fill all required fields.', Colors.orange);
      return;
    }

    if (memberIds.isEmpty) {
      _showSnackbar(context, 'No members in this group. Add members first.', Colors.red);
      return;
    }

    if (!memberIds.contains(paidBy)) {
      _showSnackbar(context, 'Payer must be a member of this group.', Colors.red);
      return;
    }

    try {
      setState(() => saving = true);

      await ExpenseService.addExpense(
        expense: ExpenseModel(
          groupId: widget.groupId,
          description: desc,
          paidBy: paidBy!,
          amount: amount!,
        ),
        memberIds: memberIds, // ✅ split among group members only
      );

      if (!mounted) return;
      _showSnackbar(context, 'Expense saved successfully!', Colors.green);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnackbar(context, 'Save failed: $e', Colors.red);
    } finally {
      if (mounted) setState(() => saving = false);
    }
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
  // ---------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group Expense', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 1,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Expense Details Card ---
                    const Text(
                      'What was spent?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Description Field
                            TextFormField(
                              controller: descCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                hintText: 'e.g., Dinner, Groceries, Movie Tickets',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.receipt_long),
                              ),
                              validator: (value) => value!.trim().isEmpty ? 'Description is required' : null,
                            ),
                            const SizedBox(height: 20),

                            // Amount Field
                            TextFormField(
                              controller: amountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Amount',
                                hintText: '0.00',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                              validator: (value) {
                                final amount = double.tryParse(value ?? '');
                                if (amount == null || amount <= 0) {
                                  return 'Enter a valid amount';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- Payer Selection Card ---
                    const Text(
                      'Who paid?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Payer',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                            hintText: 'Select group member',
                          ),
                          value: paidBy,
                          items: users
                              .where((u) => u.id != null && memberIds.contains(u.id))
                              .map((u) => DropdownMenuItem<int>(
                                    value: u.id!,
                                    child: Text(u.username),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => paidBy = v),
                          validator: (value) => value == null ? 'Payer selection is required' : null,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),

                    // --- Save Button ---
                    ElevatedButton.icon(
                      onPressed: saving ? null : _saveExpense,
                      icon: saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.done_all),
                      label: Text(
                        saving ? 'Saving Expense...' : 'Record Expense',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Hint about splitting
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Text(
                        'Note: This expense will be split equally among ${memberIds.length} group members.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}