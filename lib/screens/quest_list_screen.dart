import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/makina.dart';
import '../data/quest_data.dart';

class QuestListScreen extends StatelessWidget {
  const QuestListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('クエスト選択'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Consumer<GameProvider>(
        builder: (context, provider, child) {
          // ★変更: 受託可能なクエストのみをフィルタリング
          final availableQuests = provider.getAvailableQuests();
          final currentRank = provider.makina.guildRank;

          return Column(
            children: [
              // ランク情報カード
              _buildRankInfoCard(provider),

              // クエストリスト
              Expanded(
                child: availableQuests.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '受託可能なクエストがありません',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: availableQuests.length,
                        itemBuilder: (context, index) {
                          final quest = availableQuests[index];
                          final successRate =
                              quest.calculateSuccessRate(provider.makina);

                          return _buildQuestCard(
                            context,
                            provider,
                            quest,
                            successRate,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRankInfoCard(GameProvider provider) {
    final makina = provider.makina;
    final rankName = QuestData.getGuildRankName(makina.guildRank);
    final questsRequired =
        QuestData.getQuestsRequiredForRankUp(makina.guildRank);
    final progress = makina.questSuccessCountForCurrentRank;
    final nextRankName = makina.guildRank < 6
        ? QuestData.getGuildRankName(makina.guildRank + 1)
        : 'MAX';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.purple.shade300],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '現在のランク',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '$rankName ランク',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (makina.guildRank < 6)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      '次のランクまで',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$progress / $questsRequired',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (makina.guildRank < 6) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress / questsRequired,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
            const SizedBox(height: 8),
            Text(
              '$rankName ランクのクエストをクリアしよう!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text(
              '最高ランク到達!',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestCard(
    BuildContext context,
    GameProvider provider,
    Quest quest,
    double successRate,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showQuestDetail(context, provider, quest, successRate),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      quest.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildDifficultyChip(quest.difficulty),
                ],
              ),
              const SizedBox(height: 4),
              _buildRankRequirementChip(quest.requiredGuildRank),
              const SizedBox(height: 8),
              Text(
                quest.description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('${quest.durationMinutes}分'),
                  const SizedBox(width: 16),
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text('${quest.experienceReward} EXP'),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: successRate,
                backgroundColor: Colors.red.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getSuccessRateColor(successRate),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '成功率: ${(successRate * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: _getSuccessRateColor(successRate),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankRequirementChip(int requiredRank) {
    final rankName = QuestData.getGuildRankName(requiredRank);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.deepPurple,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.military_tech,
            size: 14,
            color: Colors.deepPurple,
          ),
          const SizedBox(width: 4),
          Text(
            '$rankName ランク',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(int difficulty) {
    Color color;
    String label;

    if (difficulty <= 2) {
      color = Colors.green;
      label = '初級';
    } else if (difficulty <= 4) {
      color = Colors.orange;
      label = '中級';
    } else if (difficulty <= 7) {
      color = Colors.red;
      label = '上級';
    } else if (difficulty <= 15) {
      color = Colors.purple;
      label = '超級';
    } else if (difficulty <= 30) {
      color = Colors.deepPurple;
      label = '極限';
    } else {
      color = Colors.black;
      label = '絶対';
    }

    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }

  Color _getSuccessRateColor(double rate) {
    if (rate >= 0.7) return Colors.green;
    if (rate >= 0.4) return Colors.orange;
    return Colors.red;
  }

  void _showQuestDetail(
    BuildContext context,
    GameProvider provider,
    Quest quest,
    double successRate,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(quest.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(quest.description),
              const SizedBox(height: 16),
              const Text(
                '必要ステータス',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildRequirementRow(
                'こうげき',
                quest.targetAttack,
                provider.makina.effectiveAttack,
              ),
              _buildRequirementRow(
                'まほう',
                quest.targetMagic,
                provider.makina.effectiveMagic,
              ),
              _buildRequirementRow(
                'すばやさ',
                quest.targetSpeed,
                provider.makina.effectiveSpeed,
              ),
              _buildRequirementRow(
                'かしこさ',
                quest.targetIntelligence,
                provider.makina.effectiveIntelligence,
              ),
              _buildRequirementRow(
                'ぼうぎょ',
                quest.targetDefense,
                provider.makina.effectiveDefense,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getSuccessRateColor(successRate).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '成功率: ${(successRate * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getSuccessRateColor(successRate),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('所要時間: ${quest.durationMinutes}分'),
                    Text('報酬: ${quest.experienceReward} EXP'),
                    Text('失敗時: ${quest.failureExperience} EXP'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.startQuest(quest);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('クエスト開始'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String name, int required, int current) {
    final isSufficient = current >= required;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name),
          Row(
            children: [
              Text(
                '$current / $required',
                style: TextStyle(
                  color: isSufficient ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isSufficient ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: isSufficient ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
