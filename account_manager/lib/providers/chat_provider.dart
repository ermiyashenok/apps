import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';
import '../models/transaction.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;

  StreamSubscription? _chatSubscription;
  StreamSubscription? _authSubscription;

  List<ChatMessage> get messages {
    var sortedList = [..._messages];
    sortedList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return sortedList;
  }
  
  bool get isLoading => _isLoading;

  ChatProvider() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _listenToChatHistory(user.uid);
      } else {
        _chatSubscription?.cancel();
        _messages = [];
        _loadGuestChatHistory();
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _chatSubscription?.cancel();
    super.dispose();
  }

  void _listenToChatHistory(String userId) {
    _chatSubscription?.cancel();
    _chatSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('chats')
        .snapshots()
        .listen((snapshot) {
      _messages = snapshot.docs.map((doc) => ChatMessage.fromJson(doc.data())).toList();
      notifyListeners();
    });
  }

  Future<void> _loadGuestChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString('chat_history');
    if (historyString != null) {
      final List<dynamic> jsonList = json.decode(historyString);
      _messages = jsonList.map((item) => ChatMessage.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveGuestChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String historyString = json.encode(
      _messages.map((msg) => msg.toJson()).toList(),
    );
    await prefs.setString('chat_history', historyString);
  }

  Future<void> _addMessage(ChatMessage message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .doc(message.id)
          .set({
             ...message.toJson(),
             'userId': user.uid,
          });
    } else {
      _messages.add(message);
      await _saveGuestChatHistory();
      notifyListeners();
    }
  }

  Future<void> sendMessage({
    required String text,
    required List<Transaction> transactions,
    required double totalBalance,
    required double totalIncome,
    required double totalExpense,
    required String currency,
  }) async {
    if (_isSending) return;
    
    _isSending = true;
    final userMessage = ChatMessage(
      role: MessageRole.user,
      content: text,
      timestamp: DateTime.now(),
    );
    _isLoading = true;
    
    if (FirebaseAuth.instance.currentUser == null) {
      _messages.add(userMessage);
      notifyListeners();
    }
    await _addMessage(userMessage);

    final conversationHistory = messages
        .map((msg) => {
              'role': msg.role.name,
              'content': msg.content,
            })
        .toList();

    if (conversationHistory.isNotEmpty) {
      conversationHistory.removeLast();
    }

    final response = await ChatService.sendMessage(
      userMessage: text,
      conversationHistory: conversationHistory,
      transactions: transactions,
      totalBalance: totalBalance,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      currency: currency,
    );

    final assistantMessage = ChatMessage(
      role: MessageRole.assistant,
      content: response,
      timestamp: DateTime.now(),
    );
    
    _isLoading = false;
    _isSending = false;
    
    if (FirebaseAuth.instance.currentUser == null) {
      _messages.add(assistantMessage);
      notifyListeners();
    }

    if (!response.startsWith('API Error') && !response.startsWith('Connection error')) {
      await _addMessage(assistantMessage);
    }
  }

  Future<void> clearHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } else {
      _messages.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_history');
      notifyListeners();
    }
  }
}
