import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  String? _currentUserEmail;
  String? _displayName;
  bool _isGuest = false;
  bool _notificationsEnabled = true;
  
  String? get userEmail => _currentUserEmail;
  String? get displayName => _displayName ?? (_currentUserEmail?.split('@')[0] ?? 'User');
  bool get isGuest => _isGuest;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isAuthenticated => _currentUserEmail != null || _isGuest;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserEmail = prefs.getString('current_user');
    _displayName = prefs.getString('display_name');
    _isGuest = prefs.getBool('is_guest') ?? false;
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    notifyListeners();
  }

  Future<void> updateDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    _displayName = name;
    await prefs.setString('display_name', name);
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = value;
    await prefs.setBool('notifications_enabled', value);
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('local_users') ?? '{}';
    final Map<String, dynamic> users = json.decode(usersJson);

    if (users.containsKey(email)) {
      if (users[email] == password) {
        _currentUserEmail = email;
        _isGuest = false;
        await prefs.setString('current_user', email);
        await prefs.setBool('is_guest', false);
        notifyListeners();
        return null;
      }
      return 'Incorrect password';
    }
    return 'Account not found. Please Sign Up first.';
  }

  Future<String?> register(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('local_users') ?? '{}';
    final Map<String, dynamic> users = json.decode(usersJson);

    if (users.containsKey(email)) return 'An account already exists';

    users[email] = password;
    await prefs.setString('local_users', json.encode(users));
    
    _currentUserEmail = email;
    _isGuest = false;
    await prefs.setString('current_user', email);
    await prefs.setBool('is_guest', false);
    notifyListeners();
    return null;
  }

  void continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuest = true;
    _currentUserEmail = null;
    await prefs.remove('current_user');
    await prefs.setBool('is_guest', true);
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    await prefs.remove('is_guest');
    await prefs.remove('display_name');
    _currentUserEmail = null;
    _displayName = null;
    _isGuest = false;
    notifyListeners();
  }
}
