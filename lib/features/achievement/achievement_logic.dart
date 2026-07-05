import 'package:flutter/foundation.dart';

import '../../core/game/game_session.dart';
import '../../shared/data/achievement_data.dart';
import '../../shared/models/makina.dart';

class AchievementLogic {
  AchievementLogic(this._session, this._notify, this._save);

  final GameSession _session;
  final VoidCallback _notify;
  final Future<void> Function() _save;

  void loadFromMakina() {
    final templates = AchievementData.getAllAchievements();
    _session.achievements = templates.map((t) {
      final saved = _session.makina.achievementData[t.id];
      return saved != null ? Achievement.fromJson(saved, t) : t;
    }).toList();
  }

  void syncToMakina() {
    final data = <String, dynamic>{};
    for (final a in _session.achievements) {
      data[a.id] = a.toJson();
    }
    _session.makina.achievementData = data;
  }

  Future<void> unlock(String id) async {
    if (_session.achievements.isEmpty) return;
    try {
      final a = _session.achievements.firstWhere((a) => a.id == id);
      if (!a.unlocked) {
        a.unlocked = true;
        a.unlockedAt = DateTime.now();
        _session.newlyUnlockedAchievement = a;
        await _save();
        _notify();
      }
    } catch (e) {
      debugPrint('Achievement unlock error: $e');
    }
  }

  void clearNewAchievement() {
    _session.newlyUnlockedAchievement = null;
    _notify();
  }

  Future<void> checkAfterQuest(Quest quest, bool success, double rate) async {
    final m = _session.makina;
    final drop = _session.droppedEquipment;

    if (success) {
      await unlock('first_quest');
      if (m.totalQuestSuccessCount >= 10) await unlock('quest_10');
      if (m.totalQuestSuccessCount >= 50) await unlock('quest_50');
      if (m.totalQuestSuccessCount >= 100) await unlock('quest_100');
      if (quest.id == 'quest_020') await unlock('maou_clear');
      if (quest.id == 'quest_021') await unlock('true_maou_clear');
      if (quest.id == 'quest_039') await unlock('god_slayer');
      if (rate <= 0.05) await unlock('impossible_success');
      const totalQuestCount = 40;
      if (m.clearedQuestIds.length >= totalQuestCount) {
        await unlock('all_quest_clear');
      }
    }

    if (!success && m.level >= 20 && quest.id == 'quest_001') {
      await unlock('high_level_herb_fail');
    }

    if (m.consecutiveSuccessCount >= 10) await unlock('ten_success_streak');
    if (m.consecutiveFailCount >= 10) await unlock('ten_fail_streak');
    if (m.dailyQuestClearCount >= 10) await unlock('speed_runner');

    if (m.level >= 5) await unlock('level_5');
    if (m.level >= 10) await unlock('level_10');
    if (m.level >= 20) await unlock('level_20');
    if (m.level >= 30) await unlock('level_30');

    if (drop != null) {
      await unlock('first_equipment');
      if (drop.rarity >= 3) await unlock('legendary_equipment');
    }

    final allEquip = [
      m.weapon,
      m.armor,
      m.shield,
      m.bracelet,
      m.boots,
      ...m.inventory,
    ].whereType<Equipment>();
    if (allEquip.any((e) => e.rarity >= 3)) {
      await unlock('legendary_equipment');
    }
    if (allEquip.isNotEmpty) await unlock('first_equipment');

    if (m.weapon != null &&
        m.armor != null &&
        m.shield != null &&
        m.bracelet != null &&
        m.boots != null) {
      await unlock('full_equipment');
    }

    if (m.intimacy >= 80) await unlock('intimacy_80');
    if (m.intimacy >= 100) await unlock('intimacy_100');
  }
}
