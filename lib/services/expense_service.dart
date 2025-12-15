import '../data/db_helper.dart';
import '../models/expense_model.dart';

class ExpenseService {
  static Future<void> addExpense({
    required ExpenseModel expense,
    required List<int> memberIds,
  }) async {
    // Save expense record
    await DBHelper.instance.insertExpense(
      groupId: expense.groupId,
      paidBy: expense.paidBy,
      description: expense.description,
      amount: expense.amount,
    );

    if (memberIds.isEmpty) return;

    final split = expense.amount / memberIds.length;

    // Create transactions (who owes whom)
    for (final uid in memberIds) {
      if (uid == expense.paidBy) continue;

      await DBHelper.instance.insertTransaction(
        groupId: expense.groupId,
        fromUser: uid,
        toUser: expense.paidBy,
        amount: split,
      );

      // Notification log
      await DBHelper.instance.addNotification(
        uid,
        'You owe Rs ${split.toStringAsFixed(2)} to user ${expense.paidBy} (Group ${expense.groupId})',
      );
    }
  }
}
