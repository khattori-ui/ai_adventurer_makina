import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/ai/ai_service.dart';
import '../../core/firebase/firestore_service.dart';
import '../../core/game/game_session.dart';

class AdminLogic {
  AdminLogic(this._session, this._notify);

  final GameSession _session;
  final VoidCallback _notify;

  Future<void> setup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _session.isAdmin = await FirestoreService.isAdmin(user.uid);

    final initial = await FirestoreService.getSystemAiProvider();
    _session.aiProvider = _parseAiProvider(initial) ?? AiProvider.gemini;

    await _session.aiProviderSub?.cancel();
    _session.aiProviderSub = FirestoreService.watchSystemAiProvider().listen((v) {
      final parsed = _parseAiProvider(v);
      if (parsed != null && parsed != _session.aiProvider) {
        _session.aiProvider = parsed;
        _notify();
      }
    });
  }

  Future<void> setSystemAiProvider(AiProvider provider) async {
    if (!_session.isAdmin) return;
    await FirestoreService.setSystemAiProvider(
      provider == AiProvider.gemini ? 'gemini' : 'haiku',
    );
    _session.aiProvider = provider;
    _notify();
  }

  AiProvider? _parseAiProvider(String? v) {
    if (v == null) return null;
    switch (v) {
      case 'gemini':
        return AiProvider.gemini;
      case 'haiku':
        return AiProvider.haiku;
      default:
        return null;
    }
  }

  void dispose() {
    _session.aiProviderSub?.cancel();
  }
}
