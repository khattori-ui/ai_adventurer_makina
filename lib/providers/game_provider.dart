import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/makina.dart';
import '../models/item.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../data/quest_data.dart';
import '../data/achievement_data.dart';

class QuestResult {
  final bool isSuccess;
  final String questName;
  final int expGained;
  final Equipment? drop;
  final String message;
  QuestResult({
    required this.isSuccess,
    required this.questName,
    required this.expGained,
    this.drop,
    required this.message,
  });
}

class GameProvider extends ChangeNotifier {
  Makina _makina = Makina();
  bool _isLoading = false;
  String? _currentMessage;
  Timer? _questTimer;
  Equipment? _droppedEquipment;
  List<Achievement> _achievements = [];
  Achievement? _newlyUnlockedAchievement;
  bool _hasRankedUp = false;
  QuestResult? _questResult;

  static const int maxDailyConversations = 50;

  Makina get makina => _makina;
  bool get isLoading => _isLoading;
  String? get currentMessage => _currentMessage;
  Equipment? get droppedEquipment => _droppedEquipment;
  bool get hasSeenPrologue => _makina.hasSeenPrologue;
  bool get hasSeenTutorial => _makina.hasSeenTutorial;
  List<Achievement> get achievements => _achievements;
  Achievement? get newlyUnlockedAchievement => _newlyUnlockedAchievement;
  bool get isOnQuest => _makina.currentQuest != null;
  bool get hasRankedUp => _hasRankedUp;
  QuestResult? get questResult => _questResult;
  List<String> get clearedQuestIds => _makina.clearedQuestIds;

  int get remainingConversations =>
      maxDailyConversations - _makina.dailyConversationCount;

  Duration? get remainingTime {
    if (_makina.currentQuest == null || _makina.questStartTime == null) {
      return null;
    }
    // ★ ここを10秒から3秒に戻しました
    final baseDuration = const Duration(seconds: 3);
    double reduction = 1.0;
    for (var buff in _makina.activeBuffs) {
      if (!buff.isExpired && buff.timeReductionRate > 0) {
        reduction = min(reduction, 1.0 - buff.timeReductionRate);
      }
    }
    final actualDuration =
        Duration(seconds: (baseDuration.inSeconds * reduction).toInt());
    final endTime = _makina.questStartTime!.add(actualDuration);
    final remaining = endTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  GameProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();
    _loadAchievementsFromMakina();

    try {
      final savedMakina = await StorageService.loadMakina();
      if (savedMakina != null) {
        _makina = savedMakina;
        _loadAchievementsFromMakina();
        if (_makina.currentQuest != null && _makina.questStartTime != null) {
          _startQuestTimer();
        }
      }
    } catch (e) {
      debugPrint("初期化エラー: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reincarnate() async {
    if (_makina.level < 30) return; // 1. レベル30以上かチェック
    _makina.reincarnate(); // 2. マキナ本体のステータスをリセット
    await _saveMakina(); // 3. データを保存（Firestore/ローカル）
    _currentMessage = "師匠、転生完了だよ！"; // 4. メッセージを更新
    notifyListeners(); // 5. 画面に反映
  }

  Future<void> useItem(ShopItem item) async {
    if (item.category == ItemCategory.personality) {
      _makina.applyPersonalityChange(
          item.braveChange.toDouble(), item.dependentChange.toDouble());
      _currentMessage = "マキナ：${item.name}、ありがとう！";
    } else if (item.duration != null) {
      _makina.activeBuffs.add(ActiveBuff(
        id: item.id,
        name: item.name,
        statMultiplier: item.statMultiplier.toDouble(),
        timeReductionRate: item.timeReductionRate.toDouble(),
        expiry: DateTime.now().add(item.duration!),
      ));
      _currentMessage = "マキナ：${item.name}のおかげで、力が湧いてきたよ！";
    } else if (item.category == ItemCategory.outfit) {
      _makina.currentOutfitId = item.id;
      _currentMessage = "マキナ：わあ、素敵な服！似合ってるかな？";
    }
    await _saveMakina();
    notifyListeners();
  }

  Future<void> startQuest(Quest quest) async {
    if (_makina.guildRank < quest.requiredGuildRank) return;
    _makina.currentQuest = quest;
    _makina.questStartTime = DateTime.now();
    await _saveMakina();
    _startQuestTimer();
    notifyListeners();
  }

  void _startQuestTimer() {
    _questTimer?.cancel();
    _questTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime == Duration.zero) {
        timer.cancel();
        _completeQuest();
      }
      notifyListeners();
    });
  }

  Future<void> _completeQuest() async {
    if (_makina.currentQuest == null) return;
    _isLoading = true;
    _hasRankedUp = false;
    notifyListeners();

    try {
      final quest = _makina.currentQuest!;
      final isCleared = _makina.clearedQuestIds.contains(quest.id);
      final successRate = quest.calculateSuccessRate(_makina, isCleared);
      final random = Random();
      final success = random.nextDouble() < successRate;
      final exp = success ? quest.experienceReward : quest.failureExperience;

      _makina.addExperience(exp);
      _droppedEquipment = null;

      if (success &&
          quest.possibleDrops.isNotEmpty &&
          random.nextDouble() < quest.dropRate) {
        final availableDrops = quest.possibleDrops
            .where((id) => !_makina.hasEquipment(id))
            .toList();
        if (availableDrops.isNotEmpty) {
          final dropId = availableDrops[random.nextInt(availableDrops.length)];
          final equipment = QuestData.getEquipmentById(dropId);
          if (equipment != null) {
            _droppedEquipment = equipment;
            _makina.addToInventory(equipment);
          }
        }
      }

      String report = await AIService.generateQuestReport(
          makina: _makina, quest: quest, success: success);
      _currentMessage = report;
      _makina.currentQuest = null;
      _makina.questStartTime = null;

      if (success) {
        if (quest.requiredGuildRank == _makina.guildRank) {
          _makina.recordQuestSuccess();
          if (_makina.tryRankUp(
              QuestData.getQuestsRequiredForRankUp(_makina.guildRank))) {
            _hasRankedUp = true;
          }
        }
        if (!_makina.clearedQuestIds.contains(quest.id)) {
          _makina.clearedQuestIds.add(quest.id);
        }
      }

      await _checkAchievements(quest, success, successRate);

      // ★ 画面に結果を表示するために結果をセットします
      _questResult = QuestResult(
          isSuccess: success,
          questName: quest.name,
          expGained: exp,
          drop: _droppedEquipment,
          message: report);

      await _saveMakina();
    } catch (e) {
      debugPrint("クエスト完了エラー: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> respondToPlayer(String msg) async {
    if (msg.trim().isEmpty) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_makina.lastConversationDate != today) {
      _makina.dailyConversationCount = 0;
      _makina.lastConversationDate = today;
    }

    if (_makina.dailyConversationCount >= maxDailyConversations) {
      _currentMessage = 'マキナ：ごめんね、魔力を使いすぎちゃって疲れちゃったみたい…。また明日になったら、元気にお話ししようね！';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      final res = await AIService.generateResponse(
          makina: _makina,
          playerMessage: msg,
          lastQuest: null,
          lastQuestSuccess: null);
      _makina.changeIntimacy((res['intimacyChange'] ?? 0.0).toDouble());
      _makina.applyPersonalityChange((res['braveChange'] ?? 0.0).toDouble(),
          (res['dependentChange'] ?? 0.0).toDouble());
      _makina.addMemory(msg, res['response'] as String);
      _makina.dailyConversationCount++;
      _currentMessage = res['response'] as String;
      await _saveMakina();
    } catch (e) {
      _currentMessage = 'マキナ：うう、頭の中がこんがらがっちゃった…（エラー）';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveMakina() async {
    _updateAchievementDataInMakina();
    await StorageService.saveMakina(_makina);
  }

  Future<void> markPrologueSeen() async {
    _makina.hasSeenPrologue = true;
    await _saveMakina();
    notifyListeners();
  }

  Future<void> markTutorialSeen() async {
    _makina.hasSeenTutorial = true;
    await _saveMakina();
    notifyListeners();
  }

  void _loadAchievementsFromMakina() {
    final templates = AchievementData.getAllAchievements();
    _achievements = templates.map((t) {
      final saved = _makina.achievementData[t.id];
      return saved != null ? Achievement.fromJson(saved, t) : t;
    }).toList();
  }

  void _updateAchievementDataInMakina() {
    final Map<String, dynamic> data = {};
    for (var a in _achievements) {
      data[a.id] = a.toJson();
    }
    _makina.achievementData = data;
  }

  Future<void> _unlockAchievement(String id) async {
    if (_achievements.isEmpty) return;
    try {
      final a = _achievements.firstWhere((a) => a.id == id);
      if (!a.unlocked) {
        a.unlocked = true;
        a.unlockedAt = DateTime.now();
        _newlyUnlockedAchievement = a;
        await _saveMakina();
        notifyListeners();
      }
    } catch (e) {}
  }

  void clearMessage() {
    _currentMessage = null;
    _droppedEquipment = null;
    _hasRankedUp = false;
    notifyListeners();
  }

  void clearQuestResult() {
    _questResult = null;
    notifyListeners();
  }

  void clearNewAchievement() {
    _newlyUnlockedAchievement = null;
    notifyListeners();
  }

  void equipItem(Equipment e) {
    _makina.equipItem(e);
    _saveMakina();
    notifyListeners();
  }

  void unequipItem(String s) {
    _makina.unequipItem(s);
    _saveMakina();
    notifyListeners();
  }

  List<Quest> getAvailableQuests() => QuestData.getAllQuests()
      .where((q) => q.requiredGuildRank <= _makina.guildRank)
      .toList();

  Future<void> resetGame() async {
    await StorageService.resetMakina();
    _makina = Makina();
    _currentMessage = null;
    _questResult = null;
    _loadAchievementsFromMakina();
    notifyListeners();
  }

  Future<void> _checkAchievements(Quest q, bool s, double rate) async {
    if (s) await _unlockAchievement('first_quest');
    if (_makina.level >= 5) await _unlockAchievement('level_5');
  }

  @override
  void dispose() {
    _questTimer?.cancel();
    super.dispose();
  }
}
