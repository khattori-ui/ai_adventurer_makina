import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/ai/ai_service.dart';
import '../../core/game/game_session.dart';
import '../../shared/data/quest_data.dart';
import '../../shared/models/makina.dart';
import '../achievement/achievement_logic.dart';
import 'quest_result.dart';

class QuestLogic {
  QuestLogic(this._session, this._notify, this._save, this._achievements);

  final GameSession _session;
  final VoidCallback _notify;
  final Future<void> Function() _save;
  final AchievementLogic _achievements;

  // TODO(test): テスト用の固定時間。本番前に false に戻すこと。
  static const bool useTestQuestDuration = true;
  static const Duration testQuestDuration = Duration(milliseconds: 500);

  bool get isOnQuest => _session.makina.currentQuest != null;

  Duration? get remainingTime {
    if (_session.makina.currentQuest == null ||
        _session.makina.questStartTime == null) {
      return null;
    }
    final baseDuration = useTestQuestDuration
        ? testQuestDuration
        : Duration(minutes: _session.makina.currentQuest!.durationMinutes);
    double reduction = 1.0;
    for (final buff in _session.makina.activeBuffs) {
      if (!buff.isExpired && buff.timeReductionRate > 0) {
        reduction = min(reduction, 1.0 - buff.timeReductionRate);
      }
    }
    final actualDuration = useTestQuestDuration
        ? baseDuration
        : Duration(seconds: (baseDuration.inSeconds * reduction).toInt());
    final endTime = _session.makina.questStartTime!.add(actualDuration);
    final remaining = endTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  List<Quest> getAvailableQuests() => QuestData.getAllQuests()
      .where((q) => q.requiredGuildRank <= _session.makina.guildRank)
      .toList();

  Future<void> startQuest(Quest quest) async {
    if (isOnQuest) return;
    if (_session.makina.guildRank < quest.requiredGuildRank) return;
    _session.makina.currentQuest = quest;
    _session.makina.questStartTime = DateTime.now();
    await _save();
    startTimer();
    _notify();
  }

  void startTimer() {
    _session.questTimer?.cancel();
    _session.questTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime == Duration.zero) {
        timer.cancel();
        completeQuest();
      }
      _notify();
    });
  }

  void clearQuestResult() {
    _session.questResult = null;
    _notify();
  }

  void dispose() {
    _session.questTimer?.cancel();
  }

  Future<void> completeQuest() async {
    if (_session.makina.currentQuest == null) return;
    _session.isLoading = true;
    _session.hasRankedUp = false;
    _notify();

    final quest = _session.makina.currentQuest!;
    var success = false;
    var exp = 0;
    Equipment? drop;
    var report = '';

    try {
      final isCleared = _session.makina.clearedQuestIds.contains(quest.id);
      final successRate =
          quest.calculateSuccessRate(_session.makina, isCleared);
      final random = Random();
      success = random.nextDouble() < successRate;
      exp = success ? quest.experienceReward : quest.failureExperience;

      _session.makina.addExperience(exp);
      _session.droppedEquipment = null;

      if (success &&
          quest.possibleDrops.isNotEmpty &&
          random.nextDouble() < quest.dropRate) {
        final availableDrops = quest.possibleDrops
            .where((id) => !_session.makina.hasEquipment(id))
            .toList();
        if (availableDrops.isNotEmpty) {
          final dropId = availableDrops[random.nextInt(availableDrops.length)];
          final equipment = QuestData.getEquipmentById(dropId);
          if (equipment != null) {
            drop = equipment;
            _session.droppedEquipment = equipment;
            _session.makina.addToInventory(equipment);
          }
        }
      }

      double reduction = 1.0;
      for (final buff in _session.makina.activeBuffs) {
        if (!buff.isExpired && buff.timeReductionRate > 0) {
          reduction = min(reduction, 1.0 - buff.timeReductionRate);
        }
      }
      _session.makina.totalQuestPlaySeconds +=
          (quest.durationMinutes * 60 * reduction).toInt();

      if (success) {
        _session.makina.totalQuestSuccessCount++;
        _session.makina.consecutiveSuccessCount++;
        _session.makina.consecutiveFailCount = 0;
        final today = DateTime.now().toIso8601String().substring(0, 10);
        if (_session.makina.lastQuestClearDate != today) {
          _session.makina.dailyQuestClearCount = 0;
          _session.makina.lastQuestClearDate = today;
        }
        _session.makina.dailyQuestClearCount++;
        if (quest.requiredGuildRank == _session.makina.guildRank) {
          _session.makina.recordQuestSuccess();
          if (_session.makina.tryRankUp(
              QuestData.getQuestsRequiredForRankUp(_session.makina.guildRank))) {
            _session.hasRankedUp = true;
          }
        }
        if (!_session.makina.clearedQuestIds.contains(quest.id)) {
          _session.makina.clearedQuestIds.add(quest.id);
        }
      } else {
        _session.makina.consecutiveFailCount++;
        _session.makina.consecutiveSuccessCount = 0;
      }

      await _achievements.checkAfterQuest(quest, success, successRate);

      try {
        report = await AIService.generateQuestReport(
          makina: _session.makina,
          quest: quest,
          success: success,
          provider: _session.aiProvider,
        );
      } catch (e) {
        debugPrint('AIレポート生成エラー: $e');
        report = success
            ? 'マキナ：${quest.name}、クリアしたよ！やったね！'
            : 'マキナ：${quest.name}、今回は上手くいかなかったけど…次は頑張るね！';
      }
      _session.currentMessage = report;
      await _save();
    } catch (e) {
      debugPrint('クエスト完了エラー: $e');
      report = success
          ? 'マキナ：クエストクリアしたよ！'
          : 'マキナ：今回はダメだったけど、また挑戦しよう！';
      _session.currentMessage = report;
    } finally {
      _session.makina.currentQuest = null;
      _session.makina.questStartTime = null;
      _session.questResult = QuestResult(
        isSuccess: success,
        questName: quest.name,
        expGained: exp,
        drop: drop,
        message: report,
      );
      _session.isLoading = false;
      _notify();
    }
  }
}
