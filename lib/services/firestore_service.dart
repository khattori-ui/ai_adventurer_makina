import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/makina.dart';

class FirestoreService {
  // コレクション名の定義
  static const String _collectionPath = 'users';

  // Firestoreのインスタンス（シングルトン的なアクセス）
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ---------------------------------------------------------
  /// 📥 データの読み込み (Load)
  /// ---------------------------------------------------------
  static Future<Makina?> getUserData(String uid) async {
    try {
      final docRef = _db.collection(_collectionPath).doc(uid);
      final snapshot = await docRef.get();

      if (snapshot.exists && snapshot.data() != null) {
        // FirestoreのデータをMakinaオブジェクトに変換
        return Makina.fromJson(snapshot.data()!);
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

      // toJson()を使ってMap形式に変換し、保存
      // SetOptions(merge: true) にすることで、フィールドが増えても既存データを壊しにくい
      await docRef.set(makina.toJson(), SetOptions(merge: true));

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
