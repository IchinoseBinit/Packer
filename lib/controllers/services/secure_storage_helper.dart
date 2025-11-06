import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageHelper {
  static final SecureStorageHelper instance = SecureStorageHelper._internal();

  late FlutterSecureStorage flutterSecureStorage;

  factory SecureStorageHelper() {
    return instance;
  }

  SecureStorageHelper._internal() {
    flutterSecureStorage = const FlutterSecureStorage();
  }

  Future<String?> readKey({required String key}) async {
    return await flutterSecureStorage.read(key: key);
  }

  write({required String key, required String value}) async {
    await flutterSecureStorage.write(key: key, value: value);
  }

  Future<List<String>?> readList({required String key}) async {
    String? encodedList = await flutterSecureStorage.read(key: key);
    if (encodedList != null) {
      List<dynamic> decodedList = jsonDecode(encodedList);
      return decodedList.cast<String>();
    }
    return null;
  }

  writeList({required String key, required List<String> value}) async {
    String encodedList = jsonEncode(value);
    await flutterSecureStorage.write(key: key, value: encodedList);
  }

  remove({required String key}) async {
    await flutterSecureStorage.delete(key: key);
  }

  removeAll() async {
    debugPrint('>> checkpoint! CLEARING VARIABLES');
    await flutterSecureStorage.deleteAll();
  }
}
