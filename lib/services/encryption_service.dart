import 'dart:convert';
import 'package:crypto/crypto.dart';

// データの整合性をチェックするためのクラス
class EncryptionService {
  // 🔑 秘密の鍵（これを変えると古いセーブデータが読み込めなくなるので注意！）
  static const String _secretKey = "makina-security-key-2026-accel";

  /// データから「指紋（ハッシュ値）」を作成します
  static String generateHash(String data) {
    var bytes = utf8.encode(data + _secretKey);
    return sha256.convert(bytes).toString();
  }

  /// 読み込んだデータと保存されていた指紋が一致するか確認します
  static bool verifyData(String data, String hash) {
    return generateHash(data) == hash;
  }
}
