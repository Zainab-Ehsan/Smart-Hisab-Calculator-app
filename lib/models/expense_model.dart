class ExpenseModel {
  final int groupId;
  final int paidBy;
  final double amount;
  final String description;

  ExpenseModel({
    required this.groupId,
    required this.paidBy,
    required this.amount,
    required this.description,
  });
}
