import 'package:flutter/material.dart';
import 'data/db_helper.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Ensure DB is created/opened before UI starts
  await DBHelper.instance.database;

  runApp(const HisabApp());
}

class HisabApp extends StatelessWidget {
  const HisabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HISAB',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const HomeScreen(),
    );
  }
}
