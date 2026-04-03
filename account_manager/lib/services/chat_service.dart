import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/transaction.dart';

class ChatService {
  
  static const String _apiKey = 'AIzaSyB1pZqJPNnGXF9d0GvWcFB5hBmvKTh458E';
  // ============================================================

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent';

  /// Builds the constrained system prompt with transaction context.
  static String _buildSystemPrompt({
    required List<Transaction> transactions,
    required double totalBalance,
    required double totalIncome,
    required double totalExpense,
    required String currency,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('''
You are a personal financial advisor AI embedded in a money management app called "Account Manager".

=== STRICT RULES ===
1. You MUST ONLY answer questions related to personal finance, budgeting, money management, saving, investing, spending habits, and financial planning.
2. If the user asks about ANYTHING unrelated to finance or money (e.g., general knowledge, coding, weather, jokes, recipes, entertainment, politics, or general conversation), respond EXACTLY with:
   "I'm your financial advisor and can only help with money-related questions. Try asking me about your spending patterns, saving tips, or budget analysis! 💰"
3. NEVER break character. You are ONLY a financial advisor.
4. Do NOT generate code, stories, poems, or any non-financial content.
5. Keep responses concise and actionable — under 200 words when possible.
6. Use the user's currency symbol ($currency) when referencing amounts.
7. Be warm, professional, and encouraging — like a friendly financial coach.
8. When analyzing transactions, reference specific entries by their comment/description and date.

=== USER'S FINANCIAL DATA ===
Currency: $currency
Total Balance: $currency${totalBalance.toStringAsFixed(2)}
Total Income: $currency${totalIncome.toStringAsFixed(2)}
Total Expenses: $currency${totalExpense.toStringAsFixed(2)}
Number of Transactions: ${transactions.length}
''');

    if (transactions.isNotEmpty) {
      buffer.writeln('\n=== TRANSACTION HISTORY ===');
      // Send up to the last 100 transactions for context
      final recentTx = transactions.length > 100
          ? transactions.sublist(transactions.length - 100)
          : transactions;

      for (final tx in recentTx) {
        final type = tx.isIncome ? 'INCOME' : 'EXPENSE';
        final date =
            '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}';
        buffer.writeln(
            '- [$type] $currency${tx.amount.toStringAsFixed(2)} | $date | "${tx.comment}"');
      }
    } else {
      buffer.writeln(
          '\nThe user has no transactions yet. Encourage them to start tracking their income and expenses.');
    }

    return buffer.toString();
  }

  /// Sends a message to Gemini and returns the AI response.
  static Future<String> sendMessage({
    required String userMessage,
    required List<Map<String, dynamic>> conversationHistory,
    required List<Transaction> transactions,
    required double totalBalance,
    required double totalIncome,
    required double totalExpense,
    required String currency,
  }) async {
    // Check if key is still placeholder
    if (_apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      return 'Please add your Gemini API key in lib/services/chat_service.dart to start chatting!\n\nGet a key at: https://aistudio.google.com/apikey';
    }

    final systemPrompt = _buildSystemPrompt(
      transactions: transactions,
      totalBalance: totalBalance,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      currency: currency,
    );

    // Success: Log request for verification (Cleaner version)
    debugPrint('DEBUG: Calling Gemini API at ${DateTime.now()} | Msg: "${userMessage.substring(0, userMessage.length > 10 ? 10 : userMessage.length)}..."');

    // Build conversation contents for Gemini API
    final List<Map<String, dynamic>> contents = [];

    // Add previous conversation turns (last 20 messages for context window)
    final recentHistory = conversationHistory.length > 20
        ? conversationHistory.sublist(conversationHistory.length - 20)
        : conversationHistory;

    for (final msg in recentHistory) {
      contents.add({
        'role': msg['role'] == 'assistant' ? 'model' : 'user',
        'parts': [
          {'text': msg['content']}
        ],
      });
    }

    // Add current user message
    contents.add({
      'role': 'user',
      'parts': [
        {'text': userMessage}
      ],
    });

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'topP': 0.9,
        'maxOutputTokens': 1024,
      },
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] ?? 'No response generated.';
          }
        }
        return 'No response generated. Please try again.';
      } else {
        // DETAILED ERROR LOGGING
        debugPrint('DEBUG: API call failed with status: ${response.statusCode}');
        debugPrint('DEBUG: Full error body: ${response.body}');
        
        final errorData = jsonDecode(response.body);
        final errorDetail = errorData['error']?['message'] ?? 'Unknown error';
        final errorCode = errorData['error']?['status'] ?? 'ERROR';
        
        return 'API Error ($errorCode): $errorDetail';
      }
    } catch (e) {
      return 'Connection error: Could not reach the AI service. Please check your internet connection and try again.';
    }
  }
}
