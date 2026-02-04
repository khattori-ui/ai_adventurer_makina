import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EncryptionService {
  // .envからのみ読み込む（キーがない場合は空文字を返し、セーブデータの不整合を防ぐ）
  static String get _secretKey => dotenv.env['SAVE_DATA_SECRET_KEY'] ?? "";

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
