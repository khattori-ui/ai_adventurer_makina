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

class GameProvider extends ChangeNotifier {
  Makina _makina = Makina();
  bool _isLoading = false;
  String? _currentMessage;
  Timer? _questTimer;
  Equipment? _droppedEquipment; // ドロップした装備
  bool _hasSeenPrologue = false; // プロローグを見たか
  bool _hasSeenTutorial = false; // チュートリアルを見たか
  int _questCompletedCount = 0; // クリアしたクエスト数
  int _consecutiveSuccess = 0; // 連続成功回数
  int _consecutiveFail = 0; // 連続失敗回数
  List<String> _clearedQuestIds = []; // クリアしたクエストID
  List<Achievement> _achievements = []; // 実績リスト
  Achievement? _newlyUnlockedAchievement; // 新しく解放された実績
  
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
  
  // 残り時間を計算
  Duration? get remainingTime {
    if (_makina.currentQuest == null || _makina.questStartTime == null) {
      return null;
    }
    
    final endTime = _makina.questStartTime!.add(
      Duration(minutes: _makina.currentQuest!.durationMinutes)
    );
    final remaining = endTime.difference(DateTime.now());
    
    return remaining.isNegative ? Duration.zero : remaining;
  }
  
  GameProvider() {
    _initialize();
  }
  
  // 初期化
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    
    final savedMakina = await StorageService.loadMakina();
    if (savedMakina != null) {
      _makina = savedMakina;
      
      // クエスト中だった場合、タイマーを再開
      if (_makina.currentQuest != null && _makina.questStartTime != null) {
        _startQuestTimer();
      }
    }
    
    // ストーリーフラグを読み込み
    _hasSeenPrologue = prefs.getBool('hasSeenPrologue') ?? false;
    _hasSeenTutorial = prefs.getBool('hasSeenTutorial') ?? false;
    _questCompletedCount = prefs.getInt('questCompletedCount') ?? 0;
    _consecutiveSuccess = prefs.getInt('consecutiveSuccess') ?? 0;
    _consecutiveFail = prefs.getInt('consecutiveFail') ?? 0;
    
    // クリア済みクエストIDを読み込み
    final clearedQuestsJson = prefs.getString('clearedQuests');
    if (clearedQuestsJson != null) {
      _clearedQuestIds = List<String>.from(jsonDecode(clearedQuestsJson));
    }
    
    // 実績を読み込み
    _loadAchievements(prefs);
    
    _isLoading = false;
    notifyListeners();
  }
  
  // クエストを開始
  Future<void> startQuest(Quest quest) async {
    _makina.currentQuest = quest;
    _makina.questStartTime = DateTime.now();
    await _saveMakina();
    
    _startQuestTimer();
    notifyListeners();
  }
  
  // クエストタイマーを開始
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
  
  // クエスト完了処理
  Future<void> _completeQuest() async {
    if (_makina.currentQuest == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    final quest = _makina.currentQuest!;
    
    // 成功判定
    final successRate = quest.calculateSuccessRate(_makina);
    final random = Random();
    final success = random.nextDouble() < successRate;
    
    // 経験値付与
    final exp = success ? quest.experienceReward : quest.failureExperience;
    _makina.addExperience(exp);
    
    // ドロップ判定（成功時のみ）
    _droppedEquipment = null;
    if (success && quest.possibleDrops.isNotEmpty) {
      final random = Random();
      if (random.nextDouble() < quest.dropRate) {
        // ドロップ成功！ランダムに1つ選択
        final dropId = quest.possibleDrops[random.nextInt(quest.possibleDrops.length)];
        final equipment = QuestData.getEquipmentById(dropId);
        if (equipment != null) {
          _droppedEquipment = equipment;
          _makina.addToInventory(equipment);
        }
      }
    }
    
    // AI生成で報告メッセージを取得
    try {
      final report = await AIService.generateQuestReport(
        makina: _makina,
        quest: quest,
        success: success,
      );
      _currentMessage = report;
    } catch (e) {
      print('Error generating quest report: $e');
      if (success) {
        _currentMessage = 'クエスト「${quest.name}」を成功させたよ！';
      } else {
        _currentMessage = 'クエスト「${quest.name}」失敗しちゃった...';
      }
    }
    
    // クエスト情報をクリア
    _makina.currentQuest = null;
    _makina.questStartTime = null;
    
    // クエストクリア数をカウント
    if (success) {
      _questCompletedCount++;
      _consecutiveSuccess++;
      _consecutiveFail = 0;
      
      // クリアしたクエストIDを記録
      if (!_clearedQuestIds.contains(quest.id)) {
        _clearedQuestIds.add(quest.id);
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('questCompletedCount', _questCompletedCount);
      await prefs.setInt('consecutiveSuccess', _consecutiveSuccess);
      await prefs.setInt('consecutiveFail', 0);
      await prefs.setString('clearedQuests', jsonEncode(_clearedQuestIds));
    } else {
      _consecutiveFail++;
      _consecutiveSuccess = 0;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('consecutiveFail', _consecutiveFail);
      await prefs.setInt('consecutiveSuccess', 0);
    }
    
    // 実績チェック
    await _checkAchievements(quest, success, successRate);
    
    await _saveMakina();
    _isLoading = false;
    notifyListeners();
  }
  
  // プレイヤーの返答を処理
  Future<void> respondToPlayer(String playerMessage) async {
    if (playerMessage.trim().isEmpty) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // AI応答を生成
      final result = await AIService.generateResponse(
        makina: _makina,
        playerMessage: playerMessage,
        lastQuest: null,
        lastQuestSuccess: null,
      );
      
      final response = result['response'] as String;
      
      // 親密度と性格を更新
      _makina.changeIntimacy(result['intimacyChange'] as double);
      _makina.changePersonality(
        result['braveChange'] as double,
        result['dependentChange'] as double,
      );
      
      // 会話記憶を追加
      _makina.addMemory(playerMessage, response);
      
      _currentMessage = response;
      
      await _saveMakina();
    } catch (e) {
      print('Error responding to player: $e');
      _currentMessage = 'ごめんね...うまく答えられなかった...';
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  // メッセージをクリア
  void clearMessage() {
    _currentMessage = null;
    _droppedEquipment = null;
    notifyListeners();
  }
  
  // 装備を装着
  void equipItem(Equipment equipment) {
    _makina.equipItem(equipment);
    _saveMakina();
    notifyListeners();
  }
  
  // 装備を外す
  void unequipItem(String slot) {
    _makina.unequipItem(slot);
    _saveMakina();
    notifyListeners();
  }
  
  // クエスト一覧を取得
  List<Quest> getAvailableQuests() {
    return QuestData.getAllQuests();
  }
  
  // データを保存
  Future<void> _saveMakina() async {
    await StorageService.saveMakina(_makina);
  }
  
  // データをリセット
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
    _questTimer?.cancel();
    notifyListeners();
  }
  
  // ストーリーフラグを設定
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
  
  // 実績を読み込み
  void _loadAchievements(SharedPreferences prefs) {
    final allAchievements = AchievementData.getAllAchievements();
    final savedJson = prefs.getString('achievements');
    
    if (savedJson != null) {
      final Map<String, dynamic> savedData = jsonDecode(savedJson);
      _achievements = allAchievements.map((template) {
        final saved = savedData[template.id];
        if (saved != null) {
          return Achievement.fromJson(saved, template);
        }
        return template;
      }).toList();
    } else {
      _achievements = allAchievements;
    }
  }
  
  // 実績を保存
  Future<void> _saveAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> data = {};
    
    for (var achievement in _achievements) {
      data[achievement.id] = achievement.toJson();
    }
    
    await prefs.setString('achievements', jsonEncode(data));
  }
  
  // 実績を解放
  Future<void> _unlockAchievement(String id) async {
    final achievement = _achievements.firstWhere(
      (a) => a.id == id,
      orElse: () => _achievements.first,
    );
    
    if (!achievement.unlocked) {
      achievement.unlocked = true;
      achievement.unlockedAt = DateTime.now();
      _newlyUnlockedAchievement = achievement;
      await _saveAchievements();
      notifyListeners();
    }
  }
  
  // 新しく解放された実績をクリア
  void clearNewAchievement() {
    _newlyUnlockedAchievement = null;
    notifyListeners();
  }
  
  // 実績チェック
  Future<void> _checkAchievements(Quest quest, bool success, double successRate) async {
    // 初めてのクエスト成功
    if (success && _questCompletedCount == 1) {
      await _unlockAchievement('first_quest');
    }
    
    // クエスト成功数
    if (success) {
      if (_questCompletedCount >= 10) await _unlockAchievement('quest_10');
      if (_questCompletedCount >= 50) await _unlockAchievement('quest_50');
      if (_questCompletedCount >= 100) await _unlockAchievement('quest_100');
    }
    
    // レベル到達
    if (_makina.level >= 5) await _unlockAchievement('level_5');
    if (_makina.level >= 10) await _unlockAchievement('level_10');
    if (_makina.level >= 20) await _unlockAchievement('level_20');
    if (_makina.level >= 30) await _unlockAchievement('level_30');
    
    // 装備
    if (_makina.inventory.isNotEmpty || 
        _makina.weapon != null || 
        _makina.armor != null ||
        _makina.shield != null ||
        _makina.bracelet != null ||
        _makina.boots != null) {
      await _unlockAchievement('first_equipment');
    }
    
    // 完全武装
    if (_makina.weapon != null &&
        _makina.armor != null &&
        _makina.shield != null &&
        _makina.bracelet != null &&
        _makina.boots != null) {
      await _unlockAchievement('full_equipment');
    }
    
    // エピック装備
    bool hasEpic = false;
    if (_makina.weapon?.rarity == 3) hasEpic = true;
    if (_makina.armor?.rarity == 3) hasEpic = true;
    if (_makina.shield?.rarity == 3) hasEpic = true;
    if (_makina.bracelet?.rarity == 3) hasEpic = true;
    if (_makina.boots?.rarity == 3) hasEpic = true;
    for (var item in _makina.inventory) {
      if (item.rarity == 3) hasEpic = true;
    }
    if (hasEpic) await _unlockAchievement('legendary_equipment');
    
    // 親密度
    if (_makina.intimacy >= 80) await _unlockAchievement('intimacy_80');
    if (_makina.intimacy >= 100) await _unlockAchievement('intimacy_100');
    
    // 魔王討伐
    if (success && quest.id == 'quest_020') {
      await _unlockAchievement('maou_clear');
    }
    
    // 全クエストクリア
    if (_clearedQuestIds.length >= 20) {
      await _unlockAchievement('all_quest_clear');
    }
    
    // 面白い実績
    // レベル20以上で薬草採取失敗
    if (!success && quest.id == 'quest_001' && _makina.level >= 20) {
      await _unlockAchievement('high_level_herb_fail');
    }
    
    // 成功率5%以下で成功
    if (success && successRate <= 0.05) {
      await _unlockAchievement('impossible_success');
    }
    
    // 10連続失敗
    if (_consecutiveFail >= 10) {
      await _unlockAchievement('ten_fail_streak');
    }
    
    // 10連続成功
    if (_consecutiveSuccess >= 10) {
      await _unlockAchievement('ten_success_streak');
    }
  }
  
  @override
  void dispose() {
    _questTimer?.cancel();
    super.dispose();
  }
}