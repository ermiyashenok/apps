import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class TransactionProvider with ChangeNotifier {
  List<Transaction> _transactions = [];
  String _selectedCurrency = '\$';

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

  static IconData getCategoryIcon(String category) {
    for (var cat in incomeCategories) {
      if (cat['name'] == category) return cat['icon'];
    }
    for (var cat in expenseCategories) {
      if (cat['name'] == category) return cat['icon'];
    }
    return Icons.more_horiz;
  }

  TransactionProvider() {
    _loadTransactions();
    _loadCurrency();
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

  /// Returns a status message for the UI to display.
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
      // Try cached location first (instant)
      Position? position = await Geolocator.getLastKnownPosition();
      
      // Fall back to fresh GPS fix if no cached position
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

  // Full country code -> currency symbol map
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

  // Full country code -> country name map
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

  /// Returns list of {code, name, symbol} maps for the search UI.
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


  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? transactionsString = prefs.getString('transactions');
    if (transactionsString != null) {
      final List<dynamic> jsonList = json.decode(transactionsString);
      _transactions = jsonList.map((jsonItem) => Transaction.fromJson(jsonItem)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String transactionsString = json.encode(
      _transactions.map((tx) => tx.toJson()).toList(),
    );
    await prefs.setString('transactions', transactionsString);
  }

  List<Transaction> get transactions {
    // Return a sorted list, newest first
    var sortedList = [..._transactions];
    sortedList.sort((a, b) => b.date.compareTo(a.date));
    return sortedList;
  }

  double get totalBalance {
    return totalIncome - totalExpense;
  }

  double get totalIncome {
    return _transactions
        .where((tx) => tx.isIncome)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get totalExpense {
    return _transactions
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
    _transactions.add(tx);
    _saveTransactions();
    notifyListeners();
  }

  void deleteTransaction(String id) {
    _transactions.removeWhere((tx) => tx.id == id);
    _saveTransactions();
    notifyListeners();
  }

  Map<String, double> getCategoryBreakdown({required bool isIncome}) {
    final Map<String, double> breakdown = {};
    for (var tx in _transactions.where((tx) => tx.isIncome == isIncome)) {
      breakdown[tx.category] = (breakdown[tx.category] ?? 0) + tx.amount;
    }
    return breakdown;
  }
}
