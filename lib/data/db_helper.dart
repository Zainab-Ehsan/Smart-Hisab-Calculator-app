import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _db;

  DBHelper._init();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'hisab.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // USERS
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT
      )
    ''');

    // GROUPS
    await db.execute('''
      CREATE TABLE groups_table(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // GROUP MEMBERS
    await db.execute('''
      CREATE TABLE group_members(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL
      )
    ''');

    // EXPENSES
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        paid_by INTEGER NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // TRANSACTIONS (WHO OWES WHOM) + STATUS
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        from_user INTEGER NOT NULL,
        to_user INTEGER NOT NULL,
        amount REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL
      )
    ''');

    // NOTIFICATIONS (LOG)
    await db.execute('''
      CREATE TABLE notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        message TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // ===================== USERS =====================

  Future<void> insertUser(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'users',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final db = await database;
    return db.query('users', orderBy: 'id DESC');
  }

  // ===================== GROUPS =====================

  Future<int> insertGroup(String name) async {
    final db = await database;
    return db.insert('groups_table', {
      'name': name,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> fetchGroups() async {
    final db = await database;
    return db.query('groups_table', orderBy: 'id DESC');
  }

  Future<void> insertGroupMember(int groupId, int userId) async {
    final db = await database;

    final existing = await db.query(
      'group_members',
      where: 'group_id = ? AND user_id = ?',
      whereArgs: [groupId, userId],
      limit: 1,
    );
    if (existing.isNotEmpty) return;

    await db.insert('group_members', {
      'group_id': groupId,
      'user_id': userId,
    });
  }

  Future<List<Map<String, dynamic>>> fetchGroupMembers(int groupId) async {
    final db = await database;
    return db.query(
      'group_members',
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
  }

  Future<List<Map<String, dynamic>>> fetchGroupMembersWithNames(int groupId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT gm.user_id, u.username, u.email
      FROM group_members gm
      JOIN users u ON u.id = gm.user_id
      WHERE gm.group_id = ?
      ORDER BY u.username ASC
    ''', [groupId]);
  }

  // ===================== EXPENSES =====================

  Future<int> insertExpense({
    required int groupId,
    required int paidBy,
    required String description,
    required double amount,
  }) async {
    final db = await database;
    return db.insert('expenses', {
      'group_id': groupId,
      'paid_by': paidBy,
      'description': description,
      'amount': amount,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> fetchGroupExpenses(int groupId) async {
    final db = await database;
    return db.query(
      'expenses',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> fetchGroupExpensesWithPayerName(int groupId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT e.id, e.description, e.amount, e.created_at, e.paid_by,
             u.username as payer_name
      FROM expenses e
      JOIN users u ON u.id = e.paid_by
      WHERE e.group_id = ?
      ORDER BY e.id DESC
    ''', [groupId]);
  }

  // ===================== TRANSACTIONS =====================

  Future<void> insertTransaction({
    required int groupId,
    required int fromUser,
    required int toUser,
    required double amount,
  }) async {
    final db = await database;
    await db.insert('transactions', {
      'group_id': groupId,
      'from_user': fromUser,
      'to_user': toUser,
      'amount': amount,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> fetchGroupTransactions(int groupId) async {
    final db = await database;
    return db.query(
      'transactions',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> fetchGroupTransactionsWithNames(int groupId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT t.id, t.group_id, t.amount, t.status, t.created_at,
             t.from_user, fu.username as from_name,
             t.to_user, tu.username as to_name
      FROM transactions t
      JOIN users fu ON fu.id = t.from_user
      JOIN users tu ON tu.id = t.to_user
      WHERE t.group_id = ?
      ORDER BY t.id DESC
    ''', [groupId]);
  }

  Future<List<Map<String, dynamic>>> fetchAllTransactionsWithNames() async {
    final db = await database;
    return db.rawQuery('''
      SELECT t.id, t.group_id, t.amount, t.status, t.created_at,
             t.from_user, fu.username as from_name,
             t.to_user, tu.username as to_name
      FROM transactions t
      JOIN users fu ON fu.id = t.from_user
      JOIN users tu ON tu.id = t.to_user
      ORDER BY t.id DESC
    ''');
  }

  Future<void> settleTransaction(int transactionId) async {
    final db = await database;
    await db.update(
      'transactions',
      {'status': 'settled'},
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  // ===================== NOTIFICATIONS =====================

  Future<void> addNotification(int userId, String message) async {
    final db = await database;
    await db.insert('notifications', {
      'user_id': userId,
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> fetchNotifications(int userId) async {
    final db = await database;
    return db.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
  }

  // ===================== BALANCE HELPERS =====================

  Future<double> _sumByStatus({
    required int userId,
    required String status,
  }) async {
    final db = await database;

    double total = 0.0;

    final out = await db.query(
      'transactions',
      where: 'from_user = ? AND status = ?',
      whereArgs: [userId, status],
    );

    final inc = await db.query(
      'transactions',
      where: 'to_user = ? AND status = ?',
      whereArgs: [userId, status],
    );

    for (final t in out) {
      total -= (t['amount'] as num?)?.toDouble() ?? 0.0;
    }
    for (final t in inc) {
      total += (t['amount'] as num?)?.toDouble() ?? 0.0;
    }

    return total;
  }

  /// Pending net balance (what is still due)
  Future<double> getBalance(int userId) async {
    return _sumByStatus(userId: userId, status: 'pending');
  }

  /// Settled net (what has already been paid/received)
  Future<double> getSettledNet(int userId) async {
    return _sumByStatus(userId: userId, status: 'settled');
  }

  /// Lifetime net = pending + settled
  Future<double> getLifetimeNet(int userId) async {
    final pending = await getBalance(userId);
    final settled = await getSettledNet(userId);
    return pending + settled;
  }

  // ===================== UTIL =====================

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
