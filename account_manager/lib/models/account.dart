import 'package:flutter/material.dart';

class Account {
  final String id;
  final String name;
  final int colorValue;
  final String? userId; // For Firestore syncing

  Account({
    required this.id,
    required this.name,
    required this.colorValue,
    this.userId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'userId': userId,
      };

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id']?.toString() ?? DateTime.now().toString(),
      name: json['name']?.toString() ?? 'Unknown Account',
      colorValue: int.tryParse(json['colorValue']?.toString() ?? '') ?? Colors.blue.value,
      userId: json['userId']?.toString(),
    );
  }
}
