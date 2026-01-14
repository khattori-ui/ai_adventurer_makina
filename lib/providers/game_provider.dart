import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/makina.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../data/quest_data.dart';
import '../data/achievement_data.dart';

// クエスト結果をまとめて保持するクラス
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
  bool _hasSeenPrologue = false;
  bool _hasSeenTutorial = false;
  int _questCompletedCount = 0;
  int _consecutiveSuccess = 0;
  int _consecutiveFail = 0;
  List<String> _clearedQuestIds = [];
  List<Achievement> _achievements = [];
  Achievement? _newlyUnlockedAchievement;
  bool _hasRankedUp = false;

  // リザルト表示用のデータ
  QuestResult? _questResult;

  Makina get makina => _makina;
  bool get isLoading => _isLoading;
  String? get currentMessage => _currentMessage;
  Equipment? get droppedEquipment => _droppedEquipment;
  bool get hasSeenPrologue => _hasSeenPrologue;
  bool get hasSeenTutorial => _hasSeenTutorial;
  int get questCompletedCount => _questCompletedCount;
  List<Achievement> get achievements => _achievements;
  Achievement? get newlyUnlockedAchievement => _newlyUnlockedAchievement;
  bool get isOnQuest => _makina.currentQuest != null;
  bool get hasRankedUp => _hasRankedUp;
  QuestResult? get questResult => _questResult;

  Duration? get remainingTime {
    if (_makina.currentQuest == null || _makina.questStartTime == null)
      return null;
    // テスト用: 3秒設定。本番はコメントアウトを切り替えてください
    final duration = const Duration(seconds: 3);
    // final duration = Duration(minutes: _makina.currentQuest!.durationMinutes);
    final endTime = _makina.questStartTime!.add(duration);
    final remaining = endTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  GameProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final savedMakina = await StorageService.loadMakina();
    if (savedMakina != null) {
      _makina = savedMakina;
      if (_makina.currentQuest != null && _makina.questStartTime != null) {
        _startQuestTimer();
      }
    }
    _hasSeenPrologue = prefs.getBool('hasSeenPrologue') ?? false;
    _hasSeenTutorial = prefs.getBool('hasSeenTutorial') ?? false;
    _questCompletedCount = prefs.getInt('questCompletedCount') ?? 0;
    _consecutiveSuccess = prefs.getInt('consecutiveSuccess') ?? 0;
    _consecutiveFail = prefs.getInt('consecutiveFail') ?? 0;
    final clearedQuestsJson = prefs.getString('clearedQuests');
    if (clearedQuestsJson != null) {
      _clearedQuestIds = List<String>.from(jsonDecode(clearedQuestsJson));
    }
    _loadAchievements(prefs);
    _isLoading = false;
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
      final remaining = remainingTime;
      if (remaining == null || remaining == Duration.zero) {
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
    _questResult = null;
    notifyListeners();

    final quest = _makina.currentQuest!;
    final successRate = quest.calculateSuccessRate(_makina);
    final random = Random();
    final success = random.nextDouble() < successRate;
    final exp = success ? quest.experienceReward : quest.failureExperience;
    _makina.addExperience(exp);

    _droppedEquipment = null;
    if (success && quest.possibleDrops.isNotEmpty) {
      if (random.nextDouble() < quest.dropRate) {
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
    }

    String reportMessage = '';
    try {
      reportMessage = await AIService.generateQuestReport(
        makina: _makina,
        quest: quest,
        success: success,
      );
    } catch (e) {
      reportMessage = success ? 'クエスト成功！' : 'クエスト失敗...';
    }
    _currentMessage = reportMessage;
    _makina.currentQuest = null;
    _makina.questStartTime = null;

    if (success) {
      _questCompletedCount++;
      _consecutiveSuccess++;
      _consecutiveFail = 0;
      if (quest.requiredGuildRank == _makina.guildRank) {
        _makina.recordQuestSuccess();
        final questsRequired =
            QuestData.getQuestsRequiredForRankUp(_makina.guildRank);
        if (_makina.tryRankUp(questsRequired)) _hasRankedUp = true;
      }
      if (!_clearedQuestIds.contains(quest.id)) _clearedQuestIds.add(quest.id);
    } else {
      _consecutiveFail++;
      _consecutiveSuccess = 0;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('questCompletedCount', _questCompletedCount);
    await prefs.setInt('consecutiveSuccess', _consecutiveSuccess);
    await prefs.setInt('consecutiveFail', _consecutiveFail);
    await prefs.setString('clearedQuests', jsonEncode(_clearedQuestIds));

    await _checkAchievements(quest, success, successRate);

    _questResult = QuestResult(
      isSuccess: success,
      questName: quest.name,
      expGained: exp,
      drop: _droppedEquipment,
      message: reportMessage,
    );

    await _saveMakina();
    _isLoading = false;
    notifyListeners();
  }

  void clearQuestResult() {
    _questResult = null;
    notifyListeners();
  }

  // 以下、既存のロジック（respondToPlayer, equipItem, unequipItem等）はすべて維持
  Future<void> respondToPlayer(String playerMessage) async {
    if (playerMessage.trim().isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      final result = await AIService.generateResponse(
        makina: _makina,
        playerMessage: playerMessage,
        lastQuest: null,
        lastQuestSuccess: null,
      );
      final response = result['response'] as String;
      _makina.changeIntimacy(result['intimacyChange'] as double);
      _makina.changePersonality(
          result['braveChange'] as double, result['dependentChange'] as double);
      _makina.addMemory(playerMessage, response);
      _currentMessage = response;
      await _saveMakina();
    } catch (e) {
      _currentMessage = 'ごめんね...うまく話せないみたい...';
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearMessage() {
    _currentMessage = null;
    _droppedEquipment = null;
    _hasRankedUp = false;
    notifyListeners();
  }

  void equipItem(Equipment equipment) {
    _makina.equipItem(equipment);
    _saveMakina();
    notifyListeners();
  }

  void unequipItem(String slot) {
    _makina.unequipItem(slot);
    _saveMakina();
    notifyListeners();
  }

  List<Quest> getAvailableQuests() {
    return QuestData.getAllQuests()
        .where((quest) => quest.requiredGuildRank <= _makina.guildRank)
        .toList();
  }

  Future<void> _saveMakina() async => await StorageService.saveMakina(_makina);

  Future<void> resetGame() async {
    await StorageService.resetMakina();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenPrologue', false);
    await prefs.setBool('hasSeenTutorial', false);
    await prefs.setInt('questCompletedCount', 0);
    _makina = Makina();
    _currentMessage = null;
    _droppedEquipment = null;
    _hasSeenPrologue = false;
    _hasSeenTutorial = false;
    _questCompletedCount = 0;
    _hasRankedUp = false;
    _questTimer?.cancel();
    _questResult = null;
    notifyListeners();
  }

  Future<void> markPrologueSeen() async {
    _hasSeenPrologue = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenPrologue', true);
    notifyListeners();
  }

  Future<void> markTutorialSeen() async {
    _hasSeenTutorial = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenTutorial', true);
    notifyListeners();
  }

  void _loadAchievements(SharedPreferences prefs) {
    final allAchievements = AchievementData.getAllAchievements();
    final savedJson = prefs.getString('achievements');
    if (savedJson != null) {
      final Map<String, dynamic> savedData = jsonDecode(savedJson);
      _achievements = allAchievements.map((template) {
        final saved = savedData[template.id];
        return saved != null ? Achievement.fromJson(saved, template) : template;
      }).toList();
    } else {
      _achievements = allAchievements;
    }
  }

  Future<void> _saveAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> data = {};
    for (var a in _achievements) data[a.id] = a.toJson();
    await prefs.setString('achievements', jsonEncode(data));
  }

  Future<void> _unlockAchievement(String id) async {
    final achievement = _achievements.firstWhere((a) => a.id == id,
        orElse: () => _achievements.first);
    if (!achievement.unlocked) {
      achievement.unlocked = true;
      achievement.unlockedAt = DateTime.now();
      _newlyUnlockedAchievement = achievement;
      await _saveAchievements();
      notifyListeners();
    }
  }

  void clearNewAchievement() {
    _newlyUnlockedAchievement = null;
    notifyListeners();
  }

  Future<void> _checkAchievements(
      Quest quest, bool success, double successRate) async {
    if (success && _questCompletedCount == 1)
      await _unlockAchievement('first_quest');
    if (success) {
      if (_questCompletedCount >= 10) await _unlockAchievement('quest_10');
      if (_questCompletedCount >= 50) await _unlockAchievement('quest_50');
      if (_questCompletedCount >= 100) await _unlockAchievement('quest_100');
    }
    if (_makina.level >= 5) await _unlockAchievement('level_5');
    if (_makina.level >= 10) await _unlockAchievement('level_10');
    if (_makina.level >= 20) await _unlockAchievement('level_20');
    if (_makina.level >= 30) await _unlockAchievement('level_30');
    if (_makina.inventory.isNotEmpty ||
        _makina.weapon != null ||
        _makina.armor != null ||
        _makina.shield != null ||
        _makina.bracelet != null ||
        _makina.boots != null) await _unlockAchievement('first_equipment');
    if (_makina.weapon != null &&
        _makina.armor != null &&
        _makina.shield != null &&
        _makina.bracelet != null &&
        _makina.boots != null) await _unlockAchievement('full_equipment');
    bool hasEpic = _makina.inventory.any((i) => i.rarity == 3) ||
        (_makina.weapon?.rarity == 3) ||
        (_makina.armor?.rarity == 3) ||
        (_makina.shield?.rarity == 3) ||
        (_makina.bracelet?.rarity == 3) ||
        (_makina.boots?.rarity == 3);
    if (hasEpic) await _unlockAchievement('legendary_equipment');
    if (_makina.intimacy >= 80) await _unlockAchievement('intimacy_80');
    if (_makina.intimacy >= 100) await _unlockAchievement('intimacy_100');
    if (success && quest.id == 'quest_020')
      await _unlockAchievement('maou_clear');
    if (_clearedQuestIds.length >= 20)
      await _unlockAchievement('all_quest_clear');
    if (!success && quest.id == 'quest_001' && _makina.level >= 20)
      await _unlockAchievement('high_level_herb_fail');
    if (success && successRate <= 0.05)
      await _unlockAchievement('impossible_success');
    if (_consecutiveFail >= 10) await _unlockAchievement('ten_fail_streak');
    if (_consecutiveSuccess >= 10)
      await _unlockAchievement('ten_success_streak');
  }

  @override
  void dispose() {
    _questTimer?.cancel();
    super.dispose();
  }
}
