import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/transaction.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  ChatProvider() {
    _loadChatHistory();
  }

  /// Load saved chat history from SharedPreferences.
  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString('chat_history');
    if (historyString != null) {
      final List<dynamic> jsonList = json.decode(historyString);
      _messages =
          jsonList.map((item) => ChatMessage.fromJson(item)).toList();
      notifyListeners();
    }
  }

  /// Save current chat history to SharedPreferences.
  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String historyString = json.encode(
      _messages.map((msg) => msg.toJson()).toList(),
    );
    await prefs.setString('chat_history', historyString);
  }

  /// Send a message and get AI response.
  Future<void> sendMessage({
    required String text,
    required List<Transaction> transactions,
    required double totalBalance,
    required double totalIncome,
    required double totalExpense,
    required String currency,
  }) async {
    // Add user message
    final userMessage = ChatMessage(
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    _isLoading = true;
    notifyListeners();
    await _saveChatHistory();

    // Build conversation history for API context
    final conversationHistory = _messages
        .map((msg) => {
              'role': msg.role,
              'content': msg.content,
            })
        .toList();

    // Remove the last user message since we pass it separately
    if (conversationHistory.isNotEmpty) {
      conversationHistory.removeLast();
    }

    debugPrint('DEBUG: Provider starting sendMessage API call...');
    // Call the API
    final response = await ChatService.sendMessage(
      userMessage: text,
      conversationHistory: conversationHistory,
      transactions: transactions,
      totalBalance: totalBalance,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      currency: currency,
    );
    debugPrint('DEBUG: API call finished.');

    // Add assistant response
    final assistantMessage = ChatMessage(
      role: 'assistant',
      content: response,
      timestamp: DateTime.now(),
    );
    _messages.add(assistantMessage);
    _isLoading = false;
    notifyListeners();
    
    // IMPORTANT: Only save history if it wasn't an API error
    // This prevents error messages from showing up "everytime" the app opens
    if (!response.startsWith('API Error') && !response.startsWith('Connection error')) {
      await _saveChatHistory();
    } else {
      debugPrint('DEBUG: Response was an error, skipping persistence.');
    }
  }

  /// Clear all chat history.
  Future<void> clearHistory() async {
    _messages.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history');
  }
}
