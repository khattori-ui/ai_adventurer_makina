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
  bool _hasSeenPrologue = false;
  bool _hasSeenTutorial = false;
  int _questCompletedCount = 0;
  int _consecutiveSuccess = 0;
  int _consecutiveFail = 0;
  List<String> _clearedQuestIds = [];
  List<Achievement> _achievements = [];
  Achievement? _newlyUnlockedAchievement;
  bool _hasRankedUp = false;
  QuestResult? _questResult;

  Makina get makina => _makina;
  bool get isLoading => _isLoading;
  String? get currentMessage => _currentMessage;
  Equipment? get droppedEquipment => _droppedEquipment;
  bool get hasSeenPrologue => _hasSeenPrologue;
  bool get hasSeenTutorial => _hasSeenTutorial;
  List<Achievement> get achievements => _achievements;
  Achievement? get newlyUnlockedAchievement => _newlyUnlockedAchievement;
  bool get isOnQuest => _makina.currentQuest != null;
  bool get hasRankedUp => _hasRankedUp;
  QuestResult? get questResult => _questResult;

  Duration? get remainingTime {
    if (_makina.currentQuest == null || _makina.questStartTime == null)
      return null;
    final duration = const Duration(seconds: 3); // テスト用3秒
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
      if (_makina.currentQuest != null && _makina.questStartTime != null)
        _startQuestTimer();
    }
    _hasSeenPrologue = prefs.getBool('hasSeenPrologue') ?? false;
    _hasSeenTutorial = prefs.getBool('hasSeenTutorial') ?? false;
    _questCompletedCount = prefs.getInt('questCompletedCount') ?? 0;
    _consecutiveSuccess = prefs.getInt('consecutiveSuccess') ?? 0;
    _consecutiveFail = prefs.getInt('consecutiveFail') ?? 0;
    final clearedQuestsJson = prefs.getString('clearedQuests');
    if (clearedQuestsJson != null)
      _clearedQuestIds = List<String>.from(jsonDecode(clearedQuestsJson));
    _loadAchievements(prefs);
    _isLoading = false;
    notifyListeners();
  }

  // 転生処理の更新
  Future<void> reincarnate() async {
    if (_makina.level < 30) return;
    _makina.reincarnate();
    await _saveMakina();
    _currentMessage = "師匠、転生完了だよ！体が軽くなって、前より早く成長できそう！一度クリアしたクエストなら、あたしに任せて！";
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

    // クリア済み判定を渡して成功率を計算
    final isCleared = _clearedQuestIds.contains(quest.id);
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
      _questCompletedCount++;
      _consecutiveSuccess++;
      _consecutiveFail = 0;
      if (quest.requiredGuildRank == _makina.guildRank) {
        _makina.recordQuestSuccess();
        if (_makina
            .tryRankUp(QuestData.getQuestsRequiredForRankUp(_makina.guildRank)))
          _hasRankedUp = true;
      }
      if (!_clearedQuestIds.contains(quest.id)) {
        _clearedQuestIds.add(quest.id);
        (await SharedPreferences.getInstance())
            .setString('clearedQuests', jsonEncode(_clearedQuestIds));
      }
    } else {
      _consecutiveFail++;
      _consecutiveSuccess = 0;
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

  void clearQuestResult() {
    _questResult = null;
    notifyListeners();
  }

  Future<void> respondToPlayer(String msg) async {
    if (msg.trim().isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      final res = await AIService.generateResponse(
          makina: _makina,
          playerMessage: msg,
          lastQuest: null,
          lastQuestSuccess: null);
      _makina.changeIntimacy(res['intimacyChange'] as double);
      _makina.changePersonality(
          res['braveChange'] as double, res['dependentChange'] as double);
      _makina.addMemory(msg, res['response'] as String);
      _currentMessage = res['response'] as String;
      await _saveMakina();
    } catch (e) {
      _currentMessage = 'うまく話せないみたい...';
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
  Future<void> _saveMakina() async => await StorageService.saveMakina(_makina);
  Future<void> resetGame() async {
    await StorageService.resetMakina();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenPrologue', false);
    await prefs.setBool('hasSeenTutorial', false);
    await prefs.remove('clearedQuests');
    _makina = Makina();
    _currentMessage = null;
    _droppedEquipment = null;
    _questCompletedCount = 0;
    _clearedQuestIds = [];
    _questResult = null;
    notifyListeners();
  }

  Future<void> markPrologueSeen() async {
    _hasSeenPrologue = true;
    (await SharedPreferences.getInstance()).setBool('hasSeenPrologue', true);
    notifyListeners();
  }

  Future<void> markTutorialSeen() async {
    _hasSeenTutorial = true;
    (await SharedPreferences.getInstance()).setBool('hasSeenTutorial', true);
    notifyListeners();
  }

  void _loadAchievements(SharedPreferences p) {
    final templates = AchievementData.getAllAchievements();
    final saved = p.getString('achievements');
    if (saved != null) {
      final data = jsonDecode(saved);
      _achievements = templates
          .map((t) =>
              data[t.id] != null ? Achievement.fromJson(data[t.id], t) : t)
          .toList();
    } else {
      _achievements = templates;
    }
  }

  Future<void> _saveAchievements() async {
    final Map<String, dynamic> data = {};
    for (var a in _achievements) data[a.id] = a.toJson();
    (await SharedPreferences.getInstance())
        .setString('achievements', jsonEncode(data));
  }

  Future<void> _unlockAchievement(String id) async {
    final a = _achievements.firstWhere((a) => a.id == id);
    if (!a.unlocked) {
      a.unlocked = true;
      a.unlockedAt = DateTime.now();
      _newlyUnlockedAchievement = a;
      await _saveAchievements();
      notifyListeners();
    }
  }

  void clearNewAchievement() {
    _newlyUnlockedAchievement = null;
    notifyListeners();
  }

  Future<void> _unlockAchievementById(String id) async =>
      await _unlockAchievement(id);

  Future<void> _checkAchievements(Quest q, bool s, double rate) async {
    if (s && _questCompletedCount == 1) await _unlockAchievement('first_quest');
    if (_makina.level >= 30) await _unlockAchievement('level_30');
    if (s && rate <= 0.05) await _unlockAchievement('impossible_success');
  }

  @override
  void dispose() {
    _questTimer?.cancel();
    super.dispose();
  }
}
