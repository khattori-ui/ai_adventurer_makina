import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 認証用
import '../shared/models/makina.dart';
import '../shared/models/item.dart';
import '../core/storage/storage_service.dart';
import '../core/firebase/firestore_service.dart';
import '../core/ai/ai_service.dart';
import '../shared/data/quest_data.dart';
import '../shared/data/achievement_data.dart';

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
  StreamSubscription<String?>? _aiProviderSub;
  Equipment? _droppedEquipment;
  List<Achievement> _achievements = [];
  Achievement? _newlyUnlockedAchievement;
  bool _hasRankedUp = false;
  QuestResult? _questResult;
  AiProvider _aiProvider = AiProvider.gemini;
  bool _isAdmin = false;

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
  AiProvider get aiProvider => _aiProvider;
  bool get isAdmin => _isAdmin;

  int get remainingConversations =>
      maxDailyConversations - _makina.dailyConversationCount;

  // -------------------------------------------------------
  // TODO(test): テスト用の固定時間。本番前に false に戻すこと。
  static const bool _useTestQuestDuration = true;
  static const Duration _testQuestDuration = Duration(milliseconds: 500);
  // -------------------------------------------------------

  Duration? get remainingTime {
    if (_makina.currentQuest == null || _makina.questStartTime == null) {
      return null;
    }
    final baseDuration = _useTestQuestDuration
        ? _testQuestDuration
        : Duration(minutes: _makina.currentQuest!.durationMinutes);
    double reduction = 1.0;
    for (var buff in _makina.activeBuffs) {
      if (!buff.isExpired && buff.timeReductionRate > 0) {
        reduction = min(reduction, 1.0 - buff.timeReductionRate);
      }
    }
    final actualDuration = _useTestQuestDuration
        ? baseDuration
        : Duration(
            seconds: (baseDuration.inSeconds * reduction).toInt(),
          );
    final endTime = _makina.questStartTime!.add(actualDuration);
    final remaining = endTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  GameProvider() {
    _initialize();
  }

  // ■■■ 初期化ロジックの修正 ■■■
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();
    _loadAchievementsFromMakina();

    try {
      // 1. まずローカルデータをロード（表示を早くするため）
      final localMakina = await StorageService.loadMakina();
      if (localMakina != null) {
        _makina = localMakina;
      }

      // 2. ログイン中なら、Firestoreから最新データを取得して同期
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final cloudMakina = await FirestoreService.getUserData(user.uid);
        if (cloudMakina != null) {
          // クラウドデータがあれば、それを正として上書き採用する
          _makina = cloudMakina;
          if (kDebugMode) print("☁️ クラウドデータをロードしました: ${_makina.level}");
        } else {
          // クラウドにデータがない（初回ログイン時など）は、今のデータをクラウドに登録
          _makina.uid = user.uid;
          await FirestoreService.saveUserData(_makina);
          if (kDebugMode) print("☁️ 新規データをクラウドに作成しました");
        }
      }

      // 3. データロード後のセットアップ
      _loadAchievementsFromMakina();
      if (_makina.currentQuest != null && _makina.questStartTime != null) {
        _startQuestTimer();
      }

      // 4. 共有AI設定と管理者判定
      await _setupAdminAndAiProvider();
    } catch (e) {
      debugPrint("初期化エラー: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _setupAdminAndAiProvider() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isAdmin = await FirestoreService.isAdmin(user.uid);

    final initial = await FirestoreService.getSystemAiProvider();
    _aiProvider = _parseAiProvider(initial) ?? AiProvider.gemini;

    await _aiProviderSub?.cancel();
    _aiProviderSub = FirestoreService.watchSystemAiProvider().listen((v) {
      final parsed = _parseAiProvider(v);
      if (parsed != null && parsed != _aiProvider) {
        _aiProvider = parsed;
        notifyListeners();
      }
    });
  }

  AiProvider? _parseAiProvider(String? v) {
    if (v == null) return null;
    switch (v) {
      case 'gemini':
        return AiProvider.gemini;
      case 'haiku':
        return AiProvider.haiku;
      default:
        return null;
    }
  }

  Future<void> setSystemAiProvider(AiProvider provider) async {
    if (!_isAdmin) return;
    await FirestoreService.setSystemAiProvider(
        provider == AiProvider.gemini ? 'gemini' : 'haiku');
    _aiProvider = provider;
    notifyListeners();
  }

  // ■■■ セーブロジックの修正 ■■■
  Future<void> _saveMakina() async {
    _updateAchievementDataInMakina();

    // 1. ローカルに保存
    await StorageService.saveMakina(_makina);

    // 2. ログイン中ならFirestoreにも保存（バックアップ）
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // UIDが未設定なら設定しておく
      if (_makina.uid == 'local_user') {
        _makina.uid = user.uid;
      }
      // バックグラウンドで保存（awaitしないことでアプリの動作を止めない手もあるが、今回は安全のためawait）
      await FirestoreService.saveUserData(_makina);
    }
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
    if (isOnQuest) return;
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
    bool success = false;
    int exp = 0;
    Equipment? drop;
    String report = '';

    try {
      final isCleared = _makina.clearedQuestIds.contains(quest.id);
      final successRate = quest.calculateSuccessRate(_makina, isCleared);
      final random = Random();
      success = random.nextDouble() < successRate;
      exp = success ? quest.experienceReward : quest.failureExperience;

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
            drop = equipment;
            _droppedEquipment = equipment;
            _makina.addToInventory(equipment);
          }
        }
      }

      // クエスト実時間を秒単位で累計に加算（バフによる短縮を反映、成功・失敗問わず）
      {
        double reduction = 1.0;
        for (var buff in _makina.activeBuffs) {
          if (!buff.isExpired && buff.timeReductionRate > 0) {
            reduction = min(reduction, 1.0 - buff.timeReductionRate);
          }
        }
        _makina.totalQuestPlaySeconds +=
            (quest.durationMinutes * 60 * reduction).toInt();
      }

      // 連続成功/失敗カウンター更新
      if (success) {
        _makina.totalQuestSuccessCount++;
        _makina.consecutiveSuccessCount++;
        _makina.consecutiveFailCount = 0;
        final today = DateTime.now().toIso8601String().substring(0, 10);
        if (_makina.lastQuestClearDate != today) {
          _makina.dailyQuestClearCount = 0;
          _makina.lastQuestClearDate = today;
        }
        _makina.dailyQuestClearCount++;
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
      } else {
        _makina.consecutiveFailCount++;
        _makina.consecutiveSuccessCount = 0;
      }

      await _checkAchievements(quest, success, successRate);

      // AIレポート（失敗してもデフォルト文言で続行）
      try {
        report = await AIService.generateQuestReport(
            makina: _makina, quest: quest, success: success, provider: _aiProvider);
      } catch (e) {
        debugPrint('AIレポート生成エラー: $e');
        report = success
            ? 'マキナ：${quest.name}、クリアしたよ！やったね！'
            : 'マキナ：${quest.name}、今回は上手くいかなかったけど…次は頑張るね！';
      }
      _currentMessage = report;

      await _saveMakina();
    } catch (e) {
      debugPrint('クエスト完了エラー: $e');
      report = success
          ? 'マキナ：クエストクリアしたよ！'
          : 'マキナ：今回はダメだったけど、また挑戦しよう！';
      _currentMessage = report;
    } finally {
      // 例外時も必ずクエスト状態をクリアして画面を進める
      _makina.currentQuest = null;
      _makina.questStartTime = null;
      _questResult = QuestResult(
          isSuccess: success,
          questName: quest.name,
          expGained: exp,
          drop: drop,
          message: report);
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
          lastQuestSuccess: null,
          provider: _aiProvider);
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
    } catch (e) {
      debugPrint('Achievement unlock error: $e');
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

  Future<void> equipItem(Equipment e) async {
    _makina.equipItem(e);
    await _saveMakina();
    notifyListeners();
  }

  Future<void> unequipItem(EquipmentSlot s) async {
    _makina.unequipItem(s);
    await _saveMakina();
    notifyListeners();
  }

  List<Quest> getAvailableQuests() => QuestData.getAllQuests()
      .where((q) => q.requiredGuildRank <= _makina.guildRank)
      .toList();

  // ■■■ リセットロジックの修正 ■■■
  Future<void> resetGame() async {
    // 1. ローカル削除
    await StorageService.resetMakina();

    // 2. クラウド削除（ログイン中なら）
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirestoreService.deleteUserData(user.uid);
    }

    // 3. メモリ上のデータもリセット
    _makina = Makina();
    _currentMessage = null;
    _questResult = null;
    _loadAchievementsFromMakina();
    notifyListeners();
  }

  Future<void> _checkAchievements(Quest quest, bool success, double rate) async {
    // ── クエスト成功系 ──────────────────────────────
    if (success) {
      await _unlockAchievement('first_quest');

      if (_makina.totalQuestSuccessCount >= 10)  await _unlockAchievement('quest_10');
      if (_makina.totalQuestSuccessCount >= 50)  await _unlockAchievement('quest_50');
      if (_makina.totalQuestSuccessCount >= 100) await _unlockAchievement('quest_100');

      // 特定クエスト
      if (quest.id == 'quest_020') await _unlockAchievement('maou_clear');
      if (quest.id == 'quest_021') await _unlockAchievement('true_maou_clear');
      if (quest.id == 'quest_039') await _unlockAchievement('god_slayer');

      // 奇跡（成功率5%以下で成功）
      if (rate <= 0.05) await _unlockAchievement('impossible_success');

      // 全クエストクリア
      const int totalQuestCount = 40;
      if (_makina.clearedQuestIds.length >= totalQuestCount) {
        await _unlockAchievement('all_quest_clear');
      }
    }

    // ── 失敗系 ──────────────────────────────────────
    if (!success) {
      // 高レベルで薬草採取に失敗
      if (_makina.level >= 20 && quest.id == 'quest_001') {
        await _unlockAchievement('high_level_herb_fail');
      }
    }

    // ── 連続記録 ─────────────────────────────────────
    if (_makina.consecutiveSuccessCount >= 10) await _unlockAchievement('ten_success_streak');
    if (_makina.consecutiveFailCount >= 10)    await _unlockAchievement('ten_fail_streak');

    // ── スピードランナー ──────────────────────────────
    if (_makina.dailyQuestClearCount >= 10) await _unlockAchievement('speed_runner');

    // ── レベル系 ──────────────────────────────────────
    if (_makina.level >= 5)  await _unlockAchievement('level_5');
    if (_makina.level >= 10) await _unlockAchievement('level_10');
    if (_makina.level >= 20) await _unlockAchievement('level_20');
    if (_makina.level >= 30) await _unlockAchievement('level_30');

    // ── 装備系 ────────────────────────────────────────
    if (_droppedEquipment != null) {
      await _unlockAchievement('first_equipment');
      if (_droppedEquipment!.rarity >= 3) await _unlockAchievement('legendary_equipment');
    }
    // インベントリ含め激レア装備を既に持っている場合も判定
    final allEquip = [
      _makina.weapon, _makina.armor, _makina.shield,
      _makina.bracelet, _makina.boots,
      ..._makina.inventory,
    ].whereType<Equipment>();
    if (allEquip.any((e) => e.rarity >= 3)) await _unlockAchievement('legendary_equipment');
    if (allEquip.isNotEmpty) await _unlockAchievement('first_equipment');

    // 全スロット装備
    if (_makina.weapon != null &&
        _makina.armor != null &&
        _makina.shield != null &&
        _makina.bracelet != null &&
        _makina.boots != null) {
      await _unlockAchievement('full_equipment');
    }

    // ── 親密度系 ──────────────────────────────────────
    if (_makina.intimacy >= 80)  await _unlockAchievement('intimacy_80');
    if (_makina.intimacy >= 100) await _unlockAchievement('intimacy_100');
  }

  // ■■■ デバッグ用メソッド ■■■

  /// ステータスを直接書き換える（デバッグ用）
  Future<void> debugSetStats({
    int? level,
    int? attack,
    int? magic,
    int? speed,
    int? intelligence,
    int? defense,
    int? guildRank,
  }) async {
    if (level != null) {
      _makina.level = level;
      _makina.experience = 0;
      _makina.experienceToNextLevel = (100 * pow(level, 2.9)).round();
    }
    if (attack != null) _makina.attack = attack;
    if (magic != null) _makina.magic = magic;
    if (speed != null) _makina.speed = speed;
    if (intelligence != null) _makina.intelligence = intelligence;
    if (defense != null) _makina.defense = defense;
    if (guildRank != null) {
      _makina.guildRank = guildRank;
      _makina.questSuccessCountForCurrentRank = 0;
    }
    await _saveMakina();
    notifyListeners();
  }

  /// 日次カウンターをリセットする（デバッグ用）
  Future<void> debugResetDailyCounters() async {
    _makina.dailyConversationCount = 0;
    _makina.lastConversationDate = '';
    _makina.dailyQuestClearCount = 0;
    _makina.lastQuestClearDate = '';
    await _saveMakina();
    notifyListeners();
  }

  @override
  void dispose() {
    _questTimer?.cancel();
    _aiProviderSub?.cancel();
    super.dispose();
  }
}
