//main.dart
import 'package:flutter/material.dart';
import 'pages/login_page.dart'; // Import the new login page
import 'services/database_helper.dart';

void main() async {
  // Ensure that Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the database
  await DatabaseHelper.instance.database;
  runApp(const IncomeApp());
}

class IncomeApp extends StatelessWidget {
  const IncomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Income Calculator",
      theme: ThemeData(
        primaryColor: const Color(0xFF38E07B),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.green,
        ).copyWith(
          secondary: const Color(0xFF10B981),
        ),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      // The home is now LoginPage
      home: const LoginPage(),
    );
  }
}
