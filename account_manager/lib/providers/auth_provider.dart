import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isGuest = false;
  bool _notificationsEnabled = true;

  String? get userEmail => _user?.email;
  String? get displayName => _user?.displayName ?? (_user?.email?.split('@')[0] ?? 'User');
  bool get isGuest => _isGuest;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isAuthenticated => _user != null || _isGuest;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool('is_guest') ?? false;
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    notifyListeners();
  }

  Future<void> updateDisplayName(String name) async {
    if (_user != null) {
      await _user!.updateDisplayName(name);
      await _user!.reload();
      _user = _auth.currentUser;
      notifyListeners();
    }
  }

  Future<void> toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = value;
    await prefs.setBool('notifications_enabled', value);
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest', false);
      _isGuest = false;
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'Account not found. Please Sign Up first.';
      if (e.code == 'wrong-password') return 'Incorrect password';
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest', false);
      _isGuest = false;
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'An account already exists';
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  void continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuest = true;
    await prefs.setBool('is_guest', true);
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', false);
    _isGuest = false;
    notifyListeners();
  }
}
