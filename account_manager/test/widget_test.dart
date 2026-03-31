import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:account_manager/main.dart';
import 'package:account_manager/providers/transaction_provider.dart';

void main() {
  testWidgets('Account Manager App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ],
        child: const AccountManagerApp(),
      ),
    );

    // Verify that the 'Total Balance' text is present on the dashboard.
    expect(find.text('Total Balance'), findsOneWidget);
  });
}
