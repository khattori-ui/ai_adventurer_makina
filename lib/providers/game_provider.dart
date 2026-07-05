import 'package:flutter/foundation.dart';

import '../core/game/game_persistence.dart';
import '../core/game/game_session.dart';
import '../features/achievement/achievement_logic.dart';
import '../features/admin/admin_logic.dart';
import '../features/conversation/conversation_logic.dart';
import '../features/debug/debug_game_logic.dart';
import '../features/equipment/equipment_logic.dart';
import '../features/quest/quest_logic.dart';
import '../features/quest/quest_result.dart';
import '../features/shop/shop_logic.dart';
import '../shared/data/achievement_data.dart';
import '../shared/models/item.dart';
import '../shared/models/makina.dart';
import '../core/ai/ai_service.dart';

export '../features/quest/quest_result.dart';

/// 画面から使うゲーム状態の窓口（内部は機能別ロジックに委譲）
class GameProvider extends ChangeNotifier {
  final GameSession _session = GameSession();
  late final AchievementLogic _achievementLogic;
  late final GamePersistence _persistence;
  late final QuestLogic _questLogic;
  late final ConversationLogic _conversationLogic;
  late final AdminLogic _adminLogic;
  late final EquipmentLogic _equipmentLogic;
  late final ShopLogic _shopLogic;
  late final DebugGameLogic _debugLogic;

  GameProvider() {
    Future<void> save() => _persistence.save();

    _achievementLogic = AchievementLogic(_session, notifyListeners, save);
    _persistence = GamePersistence(_session, _achievementLogic);
    _questLogic =
        QuestLogic(_session, notifyListeners, save, _achievementLogic);
    _conversationLogic =
        ConversationLogic(_session, notifyListeners, save);
    _adminLogic = AdminLogic(_session, notifyListeners);
    _equipmentLogic = EquipmentLogic(_session, notifyListeners, save);
    _shopLogic = ShopLogic(_session, notifyListeners, save);
    _debugLogic = DebugGameLogic(_session, notifyListeners, save);
    _initialize();
  }

  Makina get makina => _session.makina;
  bool get isLoading => _session.isLoading;
  String? get currentMessage => _session.currentMessage;
  Equipment? get droppedEquipment => _session.droppedEquipment;
  bool get hasSeenPrologue => _session.makina.hasSeenPrologue;
  bool get hasSeenTutorial => _session.makina.hasSeenTutorial;
  List<Achievement> get achievements => _session.achievements;
  Achievement? get newlyUnlockedAchievement =>
      _session.newlyUnlockedAchievement;
  bool get isOnQuest => _questLogic.isOnQuest;
  bool get hasRankedUp => _session.hasRankedUp;
  QuestResult? get questResult => _session.questResult;
  List<String> get clearedQuestIds => _session.makina.clearedQuestIds;
  AiProvider get aiProvider => _session.aiProvider;
  bool get isAdmin => _session.isAdmin;
  int get remainingConversations => _conversationLogic.remainingConversations;
  Duration? get remainingTime => _questLogic.remainingTime;

  Future<void> _initialize() async {
    _session.isLoading = true;
    notifyListeners();
    _achievementLogic.loadFromMakina();

    try {
      await _persistence.loadLocalAndCloud();
      _achievementLogic.loadFromMakina();
      if (_session.makina.currentQuest != null &&
          _session.makina.questStartTime != null) {
        _questLogic.startTimer();
      }
      await _adminLogic.setup();
    } catch (e) {
      debugPrint('初期化エラー: $e');
    } finally {
      _session.isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSystemAiProvider(AiProvider provider) =>
      _adminLogic.setSystemAiProvider(provider);

  Future<void> reincarnate() async {
    if (_session.makina.level < 30) return;
    _session.makina.reincarnate();
    await _persistence.save();
    _session.currentMessage = '師匠、転生完了だよ！';
    notifyListeners();
  }

  Future<void> useItem(ShopItem item) => _shopLogic.useItem(item);
  Future<void> startQuest(Quest quest) => _questLogic.startQuest(quest);
  Future<void> respondToPlayer(String msg) =>
      _conversationLogic.respondToPlayer(msg);

  Future<void> markPrologueSeen() async {
    _session.makina.hasSeenPrologue = true;
    await _persistence.save();
    notifyListeners();
  }

  Future<void> markTutorialSeen() async {
    _session.makina.hasSeenTutorial = true;
    await _persistence.save();
    notifyListeners();
  }

  void clearMessage() {
    _session.currentMessage = null;
    _session.droppedEquipment = null;
    _session.hasRankedUp = false;
    notifyListeners();
  }

  void clearQuestResult() => _questLogic.clearQuestResult();
  void clearNewAchievement() => _achievementLogic.clearNewAchievement();
  Future<void> equipItem(Equipment e) => _equipmentLogic.equipItem(e);
  Future<void> unequipItem(EquipmentSlot s) =>
      _equipmentLogic.unequipItem(s);
  List<Quest> getAvailableQuests() => _questLogic.getAvailableQuests();

  Future<void> resetGame() async {
    await _persistence.resetAll();
    notifyListeners();
  }

  Future<void> debugSetStats({
    int? level,
    int? attack,
    int? magic,
    int? speed,
    int? intelligence,
    int? defense,
    int? guildRank,
  }) =>
      _debugLogic.setStats(
        level: level,
        attack: attack,
        magic: magic,
        speed: speed,
        intelligence: intelligence,
        defense: defense,
        guildRank: guildRank,
      );

  Future<void> debugResetDailyCounters() =>
      _debugLogic.resetDailyCounters();

  @override
  void dispose() {
    _questLogic.dispose();
    _adminLogic.dispose();
    super.dispose();
  }
}
