import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  QuestResult(
      {required this.isSuccess,
      required this.questName,
      required this.expGained,
      this.drop,
      required this.message});
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

  // 👈 1. 1日の上限設定（とりあえず50回）
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

  // 👈 2. 残り会話回数を教える
  int get remainingConversations =>
      maxDailyConversations - _makina.dailyConversationCount;

  // クエストの残り時間を計算する命令
  Duration? get remainingTime {
    if (_makina.currentQuest == null || _makina.questStartTime == null)
      return null;

    // --- 🧪 テスト設定：ここを書き換えます ---

    // 【本番用】本来の時間（分）を使う場合はこちら
    // final baseDuration = Duration(minutes: _makina.currentQuest!.durationMinutes);

    // 【テスト用】一律「3秒」で終わらせる場合はこちら
    final baseDuration = const Duration(seconds: 3);

    // ------------------------------------

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
    final savedMakina = await StorageService.loadMakina();
    if (savedMakina != null) {
      _makina = savedMakina;
      _loadAchievementsFromMakina();
      if (_makina.currentQuest != null && _makina.questStartTime != null)
        _startQuestTimer();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> reincarnate() async {
    if (_makina.level < 30) return;
    _makina.reincarnate();
    await _saveMakina();
    _currentMessage = "師匠、転生完了だよ！";
    notifyListeners();
  }

  Future<void> useItem(ShopItem item) async {
    if (item.category == ItemCategory.personality) {
      _makina.applyPersonalityChange(item.braveChange, item.dependentChange);
      _currentMessage = "マキナ：${item.name}、ありがとう！";
    } else if (item.duration != null) {
      _makina.activeBuffs.add(ActiveBuff(
        id: item.id,
        name: item.name,
        statMultiplier: item.statMultiplier,
        timeReductionRate: item.timeReductionRate,
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
      final availableDrops =
          quest.possibleDrops.where((id) => !_makina.hasEquipment(id)).toList();
      if (availableDrops.isNotEmpty) {
        final dropId = availableDrops[random.nextInt(availableDrops.length)];
        final equipment = QuestData.getEquipmentById(dropId);
        if (equipment != null) {
          _droppedEquipment = equipment;
          _makina.addToInventory(equipment);
        }
      }
    }
    String report = '';
    try {
      report = await AIService.generateQuestReport(
          makina: _makina, quest: quest, success: success);
    } catch (e) {
      report = success ? '成功したよ！' : '失敗しちゃった...';
    }
    _currentMessage = report;
    _makina.currentQuest = null;
    _makina.questStartTime = null;
    if (success) {
      if (quest.requiredGuildRank == _makina.guildRank) {
        _makina.recordQuestSuccess();
        if (_makina
            .tryRankUp(QuestData.getQuestsRequiredForRankUp(_makina.guildRank)))
          _hasRankedUp = true;
      }
      if (!_makina.clearedQuestIds.contains(quest.id))
        _makina.clearedQuestIds.add(quest.id);
    }
    await _checkAchievements(quest, success, successRate);
    _questResult = QuestResult(
        isSuccess: success,
        questName: quest.name,
        expGained: exp,
        drop: _droppedEquipment,
        message: report);
    await _saveMakina();
    _isLoading = false;
    notifyListeners();
  }

  // 👈 3. 会話制限のロジックを組み込む
  Future<void> respondToPlayer(String msg) async {
    if (msg.trim().isEmpty) return;

    // 日付チェック（1日経っていたらリセット）
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_makina.lastConversationDate != today) {
      _makina.dailyConversationCount = 0;
      _makina.lastConversationDate = today;
    }

    // 制限チェック
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
      _makina.changeIntimacy(res['intimacyChange'] as double);
      _makina.applyPersonalityChange(
          res['braveChange'] as double, res['dependentChange'] as double);
      _makina.addMemory(msg, res['response'] as String);

      // 回数を増やす！
      _makina.dailyConversationCount++;

      _currentMessage = res['response'] as String;
      await _saveMakina();
    } catch (e) {
      _currentMessage = 'うまく話せないみたい...';
    }
    _isLoading = false;
    notifyListeners();
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
    for (var a in _achievements) data[a.id] = a.toJson();
    _makina.achievementData = data;
  }

  Future<void> _unlockAchievement(String id) async {
    final a = _achievements.firstWhere((a) => a.id == id);
    if (!a.unlocked) {
      a.unlocked = true;
      a.unlockedAt = DateTime.now();
      _newlyUnlockedAchievement = a;
      await _saveMakina();
      notifyListeners();
    }
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
    if (s && _makina.clearedQuestIds.length == 1)
      await _unlockAchievement('first_quest');
    if (_makina.level >= 5) await _unlockAchievement('level_5');
  }

  @override
  void dispose() {
    _questTimer?.cancel();
    super.dispose();
  }
}
