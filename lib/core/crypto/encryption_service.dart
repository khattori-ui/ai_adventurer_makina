import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 会話メモリの暗号化・改ざん検知
class EncryptionService {
  static const int _memoriesVersion = 1;

  static String get _secretKey => dotenv.env['SAVE_DATA_SECRET_KEY'] ?? '';

  static bool get hasEncryptionKey => _secretKey.isNotEmpty;

  static encrypt_lib.Key _deriveKey(String uid) {
    final material = utf8.encode('$_secretKey|$uid|makina-memories-v$_memoriesVersion');
    final digest = sha256.convert(material);
    return encrypt_lib.Key(Uint8List.fromList(digest.bytes));
  }

  /// 会話メモリJSON（配列）を暗号化してFirestore保存用Mapを返す
  static Map<String, dynamic>? encryptMemoriesPayload(
      String memoriesJson, String uid) {
    if (!hasEncryptionKey) return null;
    try {
      final key = _deriveKey(uid);
      final iv = encrypt_lib.IV.fromSecureRandom(12);
      final encrypter =
          encrypt_lib.Encrypter(encrypt_lib.AES(key, mode: encrypt_lib.AESMode.gcm));
      final encrypted = encrypter.encrypt(memoriesJson, iv: iv);
      return {
        'ciphertext': encrypted.base64,
        'iv': iv.base64,
        'v': _memoriesVersion,
      };
    } catch (e) {
      if (kDebugMode) debugPrint('encryptMemoriesPayload error: $e');
      return null;
    }
  }

  /// 暗号化ペイロードを会話メモリJSON文字列に復号
  static String? decryptMemoriesPayload(
      Map<String, dynamic> payload, String uid) {
    if (!hasEncryptionKey) return null;
    try {
      final ciphertext = payload['ciphertext'];
      final ivStr = payload['iv'];
      if (ciphertext is! String || ivStr is! String) return null;

      final key = _deriveKey(uid);
      final iv = encrypt_lib.IV.fromBase64(ivStr);
      final encrypter =
          encrypt_lib.Encrypter(encrypt_lib.AES(key, mode: encrypt_lib.AESMode.gcm));
      return encrypter.decrypt(
          encrypt_lib.Encrypted.fromBase64(ciphertext), iv: iv);
    } catch (e) {
      if (kDebugMode) debugPrint('decryptMemoriesPayload error: $e');
      return null;
    }
  }

  /// データから「指紋（ハッシュ値）」を作成します
  static String generateHash(String data) {
    var bytes = utf8.encode(data + _secretKey);
    return sha256.convert(bytes).toString();
  }

  /// 読み込んだデータと保存されていた指紋が一致するか確認します
  static bool verifyData(String data, String hash) {
    if (_secretKey.isEmpty) return true;
    return generateHash(data) == hash;
  }
}
