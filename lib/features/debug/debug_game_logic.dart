import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/game/game_session.dart';

class DebugGameLogic {
  DebugGameLogic(this._session, this._notify, this._save);

  final GameSession _session;
  final VoidCallback _notify;
  final Future<void> Function() _save;

  Future<void> setStats({
    int? level,
    int? attack,
    int? magic,
    int? speed,
    int? intelligence,
    int? defense,
    int? guildRank,
  }) async {
    if (level != null) {
      _session.makina.level = level;
      _session.makina.experience = 0;
      _session.makina.experienceToNextLevel = (100 * pow(level, 2.9)).round();
    }
    if (attack != null) _session.makina.attack = attack;
    if (magic != null) _session.makina.magic = magic;
    if (speed != null) _session.makina.speed = speed;
    if (intelligence != null) _session.makina.intelligence = intelligence;
    if (defense != null) _session.makina.defense = defense;
    if (guildRank != null) {
      _session.makina.guildRank = guildRank;
      _session.makina.questSuccessCountForCurrentRank = 0;
    }
    await _save();
    _notify();
  }

  Future<void> resetDailyCounters() async {
    _session.makina.dailyConversationCount = 0;
    _session.makina.lastConversationDate = '';
    _session.makina.dailyQuestClearCount = 0;
    _session.makina.lastQuestClearDate = '';
    await _save();
    _notify();
  }
}
