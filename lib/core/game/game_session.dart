import 'dart:async';

import '../../core/ai/ai_service.dart';
import '../../features/quest/quest_result.dart';
import '../../shared/data/achievement_data.dart';
import '../../shared/models/makina.dart';

/// ゲーム全体の mutable 状態（ChangeNotifier 以外で共有）
class GameSession {
  Makina makina = Makina();
  bool isLoading = false;
  String? currentMessage;
  Equipment? droppedEquipment;
  List<Achievement> achievements = [];
  Achievement? newlyUnlockedAchievement;
  bool hasRankedUp = false;
  QuestResult? questResult;
  AiProvider aiProvider = AiProvider.gemini;
  bool isAdmin = false;
  Timer? questTimer;
  StreamSubscription<String?>? aiProviderSub;

  static const int maxDailyConversations = 50;
}
