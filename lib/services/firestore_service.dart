import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/makina.dart';
import 'user_data_crypto.dart';

class FirestoreService {
  // コレクション名の定義
  static const String _collectionPath = 'users';

  // Firestoreのインスタンス（シングルトン的なアクセス）
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 共有設定のドキュメント
  static final DocumentReference<Map<String, dynamic>> _aiSettingDoc =
      _db.collection('system_settings').doc('ai');

  /// ---------------------------------------------------------
  /// 📥 データの読み込み (Load)
  /// ---------------------------------------------------------
  static Future<Makina?> getUserData(String uid) async {
    try {
      final docRef = _db.collection(_collectionPath).doc(uid);
      final snapshot = await docRef.get();

      if (snapshot.exists && snapshot.data() != null) {
        // FirestoreのデータをMakinaオブジェクトに変換
        return Makina.fromJson(
            UserDataCrypto.decodeFromStorage(snapshot.data()!));
      } else {
        // データがない場合はnullを返す（新規ユーザーなど）
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔥 Firestore Load Error: $e');
      }
      // エラー時はnullを返して、ローカルデータ等の使用を検討させる
      return null;
    }
  }

  /// ---------------------------------------------------------
  /// 📤 データの保存 (Save / Update)
  /// ---------------------------------------------------------
  static Future<void> saveUserData(Makina makina) async {
    try {
      final docRef = _db.collection(_collectionPath).doc(makina.uid);

      final data = UserDataCrypto.encodeForStorage(makina);
      // 暗号化移行後は平文 recentMemories を残さない
      if (data.containsKey('recentMemoriesEnc')) {
        data['recentMemories'] = FieldValue.delete();
      }
      await docRef.set(data, SetOptions(merge: true));

      if (kDebugMode) {
        print('🔥 Firestore Save Success: ${makina.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🔥 Firestore Save Error: $e');
      }
      rethrow; // エラー処理は呼び出し元（Providerなど）に任せる
    }
  }

  /// ---------------------------------------------------------
  /// 🚩 不適切コンテンツの通報 (Report)
  /// ---------------------------------------------------------
  static Future<void> saveReport(String reportedText) async {
    final user = FirebaseAuth.instance.currentUser;
    try {
      await _db.collection('reports').add({
        'reporterUid': user?.uid ?? 'anonymous',
        'reportedText': reportedText,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) print('🚩 Report saved: $reportedText');
    } catch (e) {
      if (kDebugMode) print('🚩 Report Save Error: $e');
      rethrow;
    }
  }

  /// ---------------------------------------------------------
  /// 🛡️ 管理者判定 (Admin)
  /// ---------------------------------------------------------
  static Future<bool> isAdmin(String uid) async {
    try {
      final doc = await _db.collection('admins').doc(uid).get();
      return doc.exists;
    } catch (e) {
      if (kDebugMode) print('🛡️ Admin check error: $e');
      return false;
    }
  }

  /// ---------------------------------------------------------
  /// ⚙️ 共有AI設定 (system_settings/ai)
  /// ---------------------------------------------------------
  static Stream<String?> watchSystemAiProvider() {
    return _aiSettingDoc.snapshots().map((snap) {
      final data = snap.data();
      final v = data?['aiProvider'];
      return v is String ? v : null;
    });
  }

  static Future<String?> getSystemAiProvider() async {
    try {
      final snap = await _aiSettingDoc.get();
      final v = snap.data()?['aiProvider'];
      return v is String ? v : null;
    } catch (e) {
      if (kDebugMode) print('⚙️ Get aiProvider error: $e');
      return null;
    }
  }

  static Future<void> setSystemAiProvider(String aiProvider) async {
    final user = FirebaseAuth.instance.currentUser;
    await _aiSettingDoc.set({
      'aiProvider': aiProvider,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': user?.uid,
    }, SetOptions(merge: true));
  }

  /// ---------------------------------------------------------
  /// 🗑️ データの削除 (Reset / Delete)
  /// ---------------------------------------------------------
  static Future<void> deleteUserData(String uid) async {
    try {
      await _db.collection(_collectionPath).doc(uid).delete();
    } catch (e) {
      if (kDebugMode) {
        print('🔥 Firestore Delete Error: $e');
      }
    }
  }
}
