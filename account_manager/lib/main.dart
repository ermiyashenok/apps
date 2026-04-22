import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/transaction_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/main_dashboard.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const AccountManagerApp(),
    ),
  );
}

class AccountManagerApp extends StatelessWidget {
  const AccountManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Account Manager',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED), // Subtle Purple seed
          primary: const Color(0xFF111827), // Keep primary dark for premium feel
          secondary: const Color(0xFF7C3AED), // Main purple accent
          secondaryContainer: const Color(0xFFF5F3FF), // Very subtle purple for button backgrounds
          onSecondaryContainer: const Color(0xFF7C3AED), // Purple text/icons on subtle background
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFFCFCFD), // Ultra crisp almost-white
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Color(0xFF111827)),
          titleTextStyle: TextStyle(
            color: Color(0xFF111827),
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: const MainDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}
