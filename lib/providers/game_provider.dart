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

    double reduction = 1.0;
    for (var buff in _makina.activeBuffs) {
      if (!buff.isExpired && buff.timeReductionRate > 0) {
        reduction = min(reduction, 1.0 - buff.timeReductionRate);
      }
    }

    // ⚠️ 本番用：questのdurationMinutesを使用
    final baseDuration =
        Duration(minutes: _makina.currentQuest!.durationMinutes);

    // 🧪 テスト用：3秒に変更する場合はこちらをコメント解除
    // final baseDuration = const Duration(seconds: 3);

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

  // ★アイテム使用ロジック（テスト用は無限）
  Future<void> useItem(ShopItem item, {bool isDebug = false}) async {
    if (item.category == ItemCategory.personality) {
      _makina.applyPersonalityChange(item.braveChange, item.dependentChange);
      _currentMessage = "マキナ：${item.name}、ありがとう！なんだか新しい自分になれた気がするよ。";
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
      _makina.applyPersonalityChange(
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

  Future<void> _checkAchievements(Quest q, bool s, double rate) async {
    // クエスト成功回数
    if (s && _questCompletedCount == 1) {
      await _unlockAchievement('first_quest');
    }
    if (s && _questCompletedCount >= 10) {
      await _unlockAchievement('quest_10');
    }
    if (s && _questCompletedCount >= 50) {
      await _unlockAchievement('quest_50');
    }
    if (s && _questCompletedCount >= 100) {
      await _unlockAchievement('quest_100');
    }

    // レベル到達
    if (_makina.level >= 5) await _unlockAchievement('level_5');
    if (_makina.level >= 10) await _unlockAchievement('level_10');
    if (_makina.level >= 20) await _unlockAchievement('level_20');
    if (_makina.level >= 30) await _unlockAchievement('level_30');

    // 装備関連
    final totalEquipment = _makina.inventory.length +
        (_makina.weapon != null ? 1 : 0) +
        (_makina.armor != null ? 1 : 0) +
        (_makina.shield != null ? 1 : 0) +
        (_makina.bracelet != null ? 1 : 0) +
        (_makina.boots != null ? 1 : 0);

    if (totalEquipment >= 1) {
      await _unlockAchievement('first_equipment');
    }

    if (_makina.weapon != null &&
        _makina.armor != null &&
        _makina.shield != null &&
        _makina.bracelet != null &&
        _makina.boots != null) {
      await _unlockAchievement('full_equipment');
    }

    // エピック装備（rarity 3）
    if (_makina.weapon?.rarity == 3 ||
        _makina.armor?.rarity == 3 ||
        _makina.shield?.rarity == 3 ||
        _makina.bracelet?.rarity == 3 ||
        _makina.boots?.rarity == 3 ||
        _makina.inventory.any((e) => e.rarity == 3)) {
      await _unlockAchievement('legendary_equipment');
    }

    // 親密度
    if (_makina.intimacy >= 80) {
      await _unlockAchievement('intimacy_80');
    }
    if (_makina.intimacy >= 100) {
      await _unlockAchievement('intimacy_100');
    }

    // 特殊なクエスト（quest_data.dartのIDを確認して調整）
    if (s && q.id == 'maou_quest') {
      await _unlockAchievement('maou_clear');
    }
    if (s && q.id == 'true_maou_quest') {
      await _unlockAchievement('true_maou_clear');
    }
    if (s && q.id == 'god_quest') {
      await _unlockAchievement('god_slayer');
    }

    // 全クエストクリア
    final allQuests = QuestData.getAllQuests();
    if (_clearedQuestIds.length >= allQuests.length) {
      await _unlockAchievement('all_quest_clear');
    }

    // 面白い実績
    if (!s && _makina.level >= 20 && q.id == 'herb_gathering') {
      await _unlockAchievement('high_level_herb_fail');
    }

    if (s && rate <= 0.05) {
      await _unlockAchievement('impossible_success');
    }

    // 連続失敗
    if (_consecutiveFail >= 10) {
      await _unlockAchievement('ten_fail_streak');
    }

    // 連続成功
    if (_consecutiveSuccess >= 10) {
      await _unlockAchievement('ten_success_streak');
    }

    // スピードランナー（1日で10回クリア）
    // これには追加のトラッキングが必要
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final todayKey = 'quests_today_$today';
    final todayCount = prefs.getInt(todayKey) ?? 0;

    if (s) {
      final newCount = todayCount + 1;
      await prefs.setInt(todayKey, newCount);

      if (newCount >= 10) {
        await _unlockAchievement('speed_runner');
      }
    }
  }

  @override
  void dispose() {
    _questTimer?.cancel();
    super.dispose();
  }
}
