import 'dart:convert';
import 'package:flutter/foundation.dart'; // 1. インポートを追加
import 'package:shared_preferences/shared_preferences.dart';
import '../models/makina.dart';

class StorageService {
  static const String _makinaKey = 'makina_data';

  // マキナのデータを保存
  static Future<void> saveMakina(Makina makina) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(makina.toJson());
    await prefs.setString(_makinaKey, jsonString);
  }

  // マキナのデータを読み込み
  static Future<Makina?> loadMakina() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_makinaKey);

    if (jsonString == null) {
      return null;
    }

    try {
      final json = jsonDecode(jsonString);
      return Makina.fromJson(json);
    } catch (e) {
      // 2. デバッグモードの時だけログを出すように修正
      if (kDebugMode) {
        print('Error loading Makina data: $e');
      }
      return null;
    }
  }

  // データをリセット
  static Future<void> resetMakina() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_makinaKey);
  }
}
