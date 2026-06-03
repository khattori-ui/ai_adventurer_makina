import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/makina.dart';
import 'encryption_service.dart';

/// users ドキュメント / ローカルセーブ向けの会話メモリ暗号化
class UserDataCrypto {
  static const int memoriesEncryptionVersion = 1;

  /// 保存用Map（recentMemories → recentMemoriesEnc）
  static Map<String, dynamic> encodeForStorage(Makina makina) {
    final json = Map<String, dynamic>.from(makina.toJson());
    final uid = (json['uid'] as String?) ?? 'local_user';
    final memories = json.remove('recentMemories');
    json.remove('memoriesEncryptionVersion');

    final memoriesJson = jsonEncode(memories ?? []);
    final enc =
        EncryptionService.encryptMemoriesPayload(memoriesJson, uid);

    if (enc != null) {
      json['recentMemoriesEnc'] = enc;
      json['memoriesEncryptionVersion'] = memoriesEncryptionVersion;
    } else {
      // 鍵未設定時は開発用に平文のまま（後方互換）
      json['recentMemories'] = memories ?? [];
      if (kDebugMode) {
        debugPrint(
            'UserDataCrypto: SAVE_DATA_SECRET_KEY未設定のため会話メモリは平文保存');
      }
    }
    return json;
  }

  /// 読み込み用Map（recentMemoriesEnc → recentMemories）
  static Map<String, dynamic> decodeFromStorage(Map<String, dynamic> json) {
    final copy = Map<String, dynamic>.from(json);
    final uid = (copy['uid'] as String?) ?? 'local_user';

    final enc = copy['recentMemoriesEnc'];
    if (enc is Map) {
      final encMap = Map<String, dynamic>.from(enc);
      final plain =
          EncryptionService.decryptMemoriesPayload(encMap, uid);
      if (plain != null) {
        final decoded = jsonDecode(plain);
        if (decoded is List) {
          copy['recentMemories'] = decoded;
        }
      }
      copy.remove('recentMemoriesEnc');
      copy.remove('memoriesEncryptionVersion');
    }
    // 旧データ: recentMemories が平文のまま残っている場合はそのまま fromJson へ

    return copy;
  }
}
