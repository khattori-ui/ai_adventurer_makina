import 'package:flutter/foundation.dart';

import '../../core/ai/ai_service.dart';
import '../../core/game/game_session.dart';

class ConversationLogic {
  ConversationLogic(this._session, this._notify, this._save);

  final GameSession _session;
  final VoidCallback _notify;
  final Future<void> Function() _save;

  int get remainingConversations =>
      GameSession.maxDailyConversations -
      _session.makina.dailyConversationCount;

  Future<void> respondToPlayer(String msg) async {
    if (msg.trim().isEmpty) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_session.makina.lastConversationDate != today) {
      _session.makina.dailyConversationCount = 0;
      _session.makina.lastConversationDate = today;
    }

    if (_session.makina.dailyConversationCount >=
        GameSession.maxDailyConversations) {
      _session.currentMessage =
          'マキナ：ごめんね、魔力を使いすぎちゃって疲れちゃったみたい…。また明日になったら、元気にお話ししようね！';
      _notify();
      return;
    }

    _session.isLoading = true;
    _notify();
    try {
      final res = await AIService.generateResponse(
        makina: _session.makina,
        playerMessage: msg,
        lastQuest: null,
        lastQuestSuccess: null,
        provider: _session.aiProvider,
      );
      _session.makina.changeIntimacy((res['intimacyChange'] ?? 0.0).toDouble());
      _session.makina.applyPersonalityChange(
        (res['braveChange'] ?? 0.0).toDouble(),
        (res['dependentChange'] ?? 0.0).toDouble(),
      );
      _session.makina.addMemory(msg, res['response'] as String);
      _session.makina.dailyConversationCount++;
      _session.currentMessage = res['response'] as String;
      await _save();
    } catch (e) {
      _session.currentMessage = 'マキナ：うう、頭の中がこんがらがっちゃった…（エラー）';
    } finally {
      _session.isLoading = false;
      _notify();
    }
  }
}
