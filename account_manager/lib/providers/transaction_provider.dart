import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  List<Account> _accounts = [
    Account(id: 'Personal', name: 'Personal', colorValue: 0xFF3B82F6),
    Account(id: 'Business', name: 'Business', colorValue: 0xFFF97316),
  ];
  String _selectedCurrency = '\$';
  String _selectedAccountType = 'All'; // 'All', or Account id

  static const List<Map<String, dynamic>> incomeCategories = [
    {'name': 'Salary', 'icon': Icons.payments},
    {'name': 'Gift', 'icon': Icons.card_giftcard},
    {'name': 'Investment', 'icon': Icons.trending_up},
    {'name': 'Freelance', 'icon': Icons.work},
    {'name': 'Other', 'icon': Icons.more_horiz},
  ];

  static const List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Transport', 'icon': Icons.directions_car},
    {'name': 'Rent', 'icon': Icons.home},
    {'name': 'Shopping', 'icon': Icons.shopping_bag},
    {'name': 'Entertainment', 'icon': Icons.movie},
    {'name': 'Health', 'icon': Icons.medical_services},
    {'name': 'Utilities', 'icon': Icons.lightbulb},
    {'name': 'Other', 'icon': Icons.more_horiz},
  ];

  String get selectedCurrency => _selectedCurrency;
  String get selectedAccountType => _selectedAccountType;
  List<Account> get accounts => _accounts;

  void setAccountType(String type) {
    if (_selectedAccountType != type) {
      _selectedAccountType = type;
      notifyListeners();
    }
  }

  static IconData getCategoryIcon(String category) {
    for (var cat in incomeCategories) {
      if (cat['name'] == category) return cat['icon'];
    }
    for (var cat in expenseCategories) {
      if (cat['name'] == category) return cat['icon'];
    }
    return Icons.more_horiz;
  }

  StreamSubscription? _txSubscription;
  StreamSubscription? _authSubscription;

  TransactionProvider() {
    _loadCurrency();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _listenToTransactions(user.uid);
        _listenToAccounts(user.uid);
      } else {
        _txSubscription?.cancel();
        _accountSubscription?.cancel();
        _transactions = [];
        _loadGuestTransactions();
        _loadGuestAccounts();
        notifyListeners();
      }
    });
  }

  StreamSubscription? _accountSubscription;

  @override
  void dispose() {
    _authSubscription?.cancel();
    _txSubscription?.cancel();
    _accountSubscription?.cancel();
    super.dispose();
  }

  void _listenToAccounts(String userId) {
    _accountSubscription?.cancel();
    _accountSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('accounts')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        _accounts = snapshot.docs.map((doc) => Account.fromJson(doc.data())).toList();
        notifyListeners();
      }
    });
  }

  void _listenToTransactions(String userId) {
    _txSubscription?.cancel();
    _txSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .snapshots()
        .listen((snapshot) {
      _transactions = snapshot.docs.map((doc) => Transaction.fromJson(doc.data())).toList();
      notifyListeners();
    });
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCurrency = prefs.getString('currency') ?? '\$';
    notifyListeners();
  }

  Future<void> updateCurrency(String symbol) async {
    _selectedCurrency = symbol;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', symbol);
    notifyListeners();
  }

  Future<String> detectCurrencyFromLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return 'Location services are disabled. Please enable them in Settings.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'Location permission denied. Please allow location access.';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return 'Location permission permanently denied. Please enable in app settings.';
      }
      Position? position = await Geolocator.getLastKnownPosition();
      
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 30),
        ),
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        String? countryCode = placemarks.first.isoCountryCode;
        String? country = placemarks.first.country;
        if (countryCode != null) {
          String symbol = _getCurrencySymbolForCountry(countryCode);
          await updateCurrency(symbol);
          return 'Currency set to $symbol (${country ?? countryCode})';
        }
      }
      return 'Could not determine country from location.';
    } catch (e) {
      debugPrint('Error detecting currency: $e');
      return 'Error detecting location: ${e.toString()}';
    }
  }

  static const Map<String, String> _countryCurrencyMap = {
    'US': '\$', 'CA': 'C\$', 'AU': 'A\$', 'NZ': 'NZ\$', 'SG': 'S\$', 'HK': 'HK\$',
    'GB': '£',
    'JP': '¥', 'CN': '¥',
    'IN': '₹',
    'ET': 'Br',
    'RU': '₽',
    'TR': '₺',
    'BR': 'R\$',
    'ZA': 'R',
    'KR': '₩',
    'MX': 'MX\$',
    'AT': '€', 'BE': '€', 'CY': '€', 'EE': '€', 'FI': '€', 'FR': '€',
    'DE': '€', 'GR': '€', 'IE': '€', 'IT': '€', 'LV': '€', 'LT': '€',
    'LU': '€', 'MT': '€', 'NL': '€', 'PT': '€', 'SK': '€', 'SI': '€', 'ES': '€',
    'CH': 'CHF', 'SE': 'kr', 'NO': 'kr', 'DK': 'kr',
    'PL': 'zł', 'CZ': 'Kč', 'HU': 'Ft', 'RO': 'lei',
    'TH': '฿', 'MY': 'RM', 'ID': 'Rp', 'PH': '₱', 'VN': '₫',
    'AE': 'د.إ', 'SA': '﷼', 'EG': 'E£', 'NG': '₦', 'KE': 'KSh',
    'PK': '₨', 'BD': '৳', 'LK': '₨',
    'AR': 'AR\$', 'CL': 'CL\$', 'CO': 'CO\$', 'PE': 'S/.',
    'IL': '₪', 'TW': 'NT\$', 'UA': '₴',
  };

  static const Map<String, String> _countryNameMap = {
    'US': 'United States', 'CA': 'Canada', 'AU': 'Australia', 'NZ': 'New Zealand',
    'SG': 'Singapore', 'HK': 'Hong Kong', 'GB': 'United Kingdom',
    'JP': 'Japan', 'CN': 'China', 'IN': 'India', 'ET': 'Ethiopia',
    'RU': 'Russia', 'TR': 'Turkey', 'BR': 'Brazil', 'ZA': 'South Africa',
    'KR': 'South Korea', 'MX': 'Mexico',
    'AT': 'Austria', 'BE': 'Belgium', 'CY': 'Cyprus', 'EE': 'Estonia',
    'FI': 'Finland', 'FR': 'France', 'DE': 'Germany', 'GR': 'Greece',
    'IE': 'Ireland', 'IT': 'Italy', 'LV': 'Latvia', 'LT': 'Lithuania',
    'LU': 'Luxembourg', 'MT': 'Malta', 'NL': 'Netherlands', 'PT': 'Portugal',
    'SK': 'Slovakia', 'SI': 'Slovenia', 'ES': 'Spain',
    'CH': 'Switzerland', 'SE': 'Sweden', 'NO': 'Norway', 'DK': 'Denmark',
    'PL': 'Poland', 'CZ': 'Czech Republic', 'HU': 'Hungary', 'RO': 'Romania',
    'TH': 'Thailand', 'MY': 'Malaysia', 'ID': 'Indonesia', 'PH': 'Philippines',
    'VN': 'Vietnam', 'AE': 'UAE', 'SA': 'Saudi Arabia', 'EG': 'Egypt',
    'NG': 'Nigeria', 'KE': 'Kenya', 'PK': 'Pakistan', 'BD': 'Bangladesh',
    'LK': 'Sri Lanka', 'AR': 'Argentina', 'CL': 'Chile', 'CO': 'Colombia',
    'PE': 'Peru', 'IL': 'Israel', 'TW': 'Taiwan', 'UA': 'Ukraine',
  };

  List<Map<String, String>> get searchableCountries {
    final list = <Map<String, String>>[];
    for (final entry in _countryNameMap.entries) {
      list.add({
        'code': entry.key,
        'name': entry.value,
        'symbol': _countryCurrencyMap[entry.key] ?? '\$',
      });
    }
    list.sort((a, b) => a['name']!.compareTo(b['name']!));
    return list;
  }

  String _getCurrencySymbolForCountry(String countryCode) {
    return _countryCurrencyMap[countryCode] ?? '\$';
  }

  Future<void> _loadGuestTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? transactionsString = prefs.getString('transactions');
    if (transactionsString != null) {
      final List<dynamic> jsonList = json.decode(transactionsString);
      _transactions = jsonList.map((jsonItem) => Transaction.fromJson(jsonItem)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveGuestTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String transactionsString = json.encode(
      _transactions.map((tx) => tx.toJson()).toList(),
    );
    await prefs.setString('transactions', transactionsString);
  }

  Future<void> _loadGuestAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accountsString = prefs.getString('accounts');
    if (accountsString != null) {
      final List<dynamic> jsonList = json.decode(accountsString);
      _accounts = jsonList.map((jsonItem) => Account.fromJson(jsonItem)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveGuestAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final String accountsString = json.encode(
      _accounts.map((acc) => acc.toJson()).toList(),
    );
    await prefs.setString('accounts', accountsString);
  }

  void addAccount(Account acc) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('accounts')
          .doc(acc.id)
          .set({
             ...acc.toJson(),
             'userId': user.uid,
          });
    } else {
      _accounts.add(acc);
      _saveGuestAccounts();
      notifyListeners();
    }
  }

  void updateAccount(Account acc) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('accounts')
          .doc(acc.id)
          .update(acc.toJson());
    } else {
      final index = _accounts.indexWhere((a) => a.id == acc.id);
      if (index != -1) {
        _accounts[index] = acc;
        _saveGuestAccounts();
        notifyListeners();
      }
    }
  }

  void deleteAccount(String id) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('accounts')
          .doc(id)
          .delete();
    } else {
      _accounts.removeWhere((acc) => acc.id == id);
      if (_selectedAccountType == id) _selectedAccountType = 'All';
      _saveGuestAccounts();
      notifyListeners();
    }
  }

  List<Transaction> get transactions {
    var filteredList = _transactions.where((tx) => _selectedAccountType == 'All' || tx.accountType == _selectedAccountType).toList();
    filteredList.sort((a, b) => b.date.compareTo(a.date));
    return filteredList;
  }

  double get totalBalance {
    return totalIncome - totalExpense;
  }

  double getBalanceForAccount(String accountId) {
    if (accountId == 'All') {
      return _transactions.fold(0.0, (sum, tx) => sum + (tx.isIncome ? tx.amount : -tx.amount));
    }
    return _transactions
        .where((tx) => tx.accountType == accountId)
        .fold(0.0, (sum, tx) => sum + (tx.isIncome ? tx.amount : -tx.amount));
  }

  double get totalIncome {
    return transactions
        .where((tx) => tx.isIncome)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get totalExpense {
    return transactions
        .where((tx) => !tx.isIncome)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  List<Transaction> getTransactionsForDay(DateTime day) {
    return _transactions.where((tx) {
      return tx.date.year == day.year &&
             tx.date.month == day.month &&
             tx.date.day == day.day;
    }).toList();
  }

  double getDailyIncome(DateTime day) {
    return getTransactionsForDay(day)
        .where((tx) => tx.isIncome)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double getDailyExpense(DateTime day) {
    return getTransactionsForDay(day)
        .where((tx) => !tx.isIncome)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  void addTransaction(Transaction tx) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(tx.id)
          .set({
             ...tx.toJson(),
             'userId': user.uid,
          });
    } else {
      _transactions.add(tx);
      _saveGuestTransactions();
      notifyListeners();
    }
  }

  void deleteTransaction(String id) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(id)
          .delete();
    } else {
      _transactions.removeWhere((tx) => tx.id == id);
      _saveGuestTransactions();
      notifyListeners();
    }
  }

  Map<String, double> getCategoryBreakdown({required bool isIncome}) {
    final Map<String, double> breakdown = {};
    for (var tx in transactions.where((tx) => tx.isIncome == isIncome)) {
      breakdown[tx.category] = (breakdown[tx.category] ?? 0) + tx.amount;
    }
    return breakdown;
  }
}
