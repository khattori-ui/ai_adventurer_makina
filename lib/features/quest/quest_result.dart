import '../../shared/models/makina.dart';

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
