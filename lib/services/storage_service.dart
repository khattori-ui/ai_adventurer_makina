import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/makina.dart';
import 'encryption_service.dart'; // 👈 ステップ1で作ったファイルを読み込む

class StorageService {
  static const String _makinaKey = 'makina_data';
  static const String _hashKey = 'makina_data_hash'; // 👈 指紋保存用の新しい場所

  // マキナのデータを保存する
  static Future<void> saveMakina(Makina makina) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(makina.toJson());

    // 🛡️ 保存する直前に「指紋」を作成
    final hash = EncryptionService.generateHash(jsonString);

    await prefs.setString(_makinaKey, jsonString);
    await prefs.setString(_hashKey, hash); // 指紋もセットで保存！
  }

  // マキナのデータを読み込む
  static Future<Makina?> loadMakina() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_makinaKey);
    final savedHash = prefs.getString(_hashKey); // 保存されていた指紋

    if (jsonString == null) return null;

    // 🕵️ 抜き打ち検査：データが指紋と一致するか？
    if (savedHash == null ||
        !EncryptionService.verifyData(jsonString, savedHash)) {
      if (kDebugMode) {
        print('🚨 セキュリティ警告: セーブデータが改ざんされています！');
      }
      // 指紋が合わなければ、ズルしたとみなして読み込まない！
      return null;
    }

    try {
      final json = jsonDecode(jsonString);
      return Makina.fromJson(json);
    } catch (e) {
      if (kDebugMode) print('Error loading Makina data: $e');
      return null;
    }
  }

  // データをリセットする
  static Future<void> resetMakina() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_makinaKey);
    await prefs.remove(_hashKey); // 指紋も消す
  }
}
