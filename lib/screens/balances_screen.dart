import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../data/db_helper.dart';
import '../models/user_model.dart';

class BalancesScreen extends StatefulWidget {
  const BalancesScreen({super.key});

  @override
  State<BalancesScreen> createState() => _BalancesScreenState();
}

class _BalancesScreenState extends State<BalancesScreen> {
  late Future<List<UserModel>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = UserService.getUsers();
  }

  String _money(double v) => v.abs().toStringAsFixed(2);

  Widget _pendingChip(double pending) {
    if (pending > 0) {
      return Chip(
        label: Text('To Receive: \$ ${_money(pending)}'),
        backgroundColor: Colors.green.shade100,
        labelStyle: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.w700),
      );
    } else if (pending < 0) {
      return Chip(
        label: Text('To Pay: \$ ${_money(pending)}'),
        backgroundColor: Colors.red.shade100,
        labelStyle: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.w700),
      );
    }
    return Chip(
      label: const Text('Settled (Pending = 0)'),
      backgroundColor: Colors.grey.shade200,
      labelStyle: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Overall Balances',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 1,
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading users: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No users found. Please add users on the Users screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
            itemCount: users.length,
            itemBuilder: (_, i) {
              final user = users[i];

              return FutureBuilder<List<double>>(
                // ✅ pending, settled, lifetime
                future: Future.wait([
                  DBHelper.instance.getBalance(user.id!),       // pending net
                  DBHelper.instance.getSettledNet(user.id!),    // settled net
                  DBHelper.instance.getLifetimeNet(user.id!),   // lifetime net
                ]),
                builder: (_, snap) {
                  final waiting = snap.connectionState == ConnectionState.waiting;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                          child: Text(
                            user.username.isEmpty ? '?' : user.username[0].toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        title: Text(
                          user.username,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        subtitle: Text('User ID: ${user.id}'),
                        trailing: waiting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : (snap.hasData
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _pendingChip(snap.data![0]),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Settled net: \$ ${_money(snap.data![1])}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        'Lifetime net: \$ ${_money(snap.data![2])}',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.grey.shade600,
                                            ),
                                      ),
                                    ],
                                  )
                                : const Text('Error', style: TextStyle(color: Colors.red))),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
