import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../features/achievement/achievement_logic.dart';
import '../../shared/models/makina.dart';
import '../firebase/firestore_service.dart';
import '../storage/storage_service.dart';
import 'game_session.dart';

class GamePersistence {
  GamePersistence(this._session, this._achievements);

  final GameSession _session;
  final AchievementLogic _achievements;

  Future<void> save() async {
    _achievements.syncToMakina();
    await StorageService.saveMakina(_session.makina);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (_session.makina.uid == 'local_user') {
        _session.makina.uid = user.uid;
      }
      await FirestoreService.saveUserData(_session.makina);
    }
  }

  Future<void> loadLocalAndCloud() async {
    final localMakina = await StorageService.loadMakina();
    if (localMakina != null) {
      _session.makina = localMakina;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cloudMakina = await FirestoreService.getUserData(user.uid);
    if (cloudMakina != null) {
      _session.makina = cloudMakina;
      if (kDebugMode) {
        print('☁️ クラウドデータをロードしました: ${_session.makina.level}');
      }
    } else {
      _session.makina.uid = user.uid;
      await FirestoreService.saveUserData(_session.makina);
      if (kDebugMode) print('☁️ 新規データをクラウドに作成しました');
    }
  }

  Future<void> resetAll() async {
    await StorageService.resetMakina();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirestoreService.deleteUserData(user.uid);
    }
    _session.makina = Makina();
    _session.currentMessage = null;
    _session.questResult = null;
    _achievements.loadFromMakina();
  }
}
