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
          final availableQuests = provider.getAvailableQuests();
          return Column(
            children: [
              _buildRankInfoCard(provider),
              Expanded(
                child: availableQuests.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: availableQuests.length,
                        itemBuilder: (context, index) {
                          final quest = availableQuests[index];
                          final isCleared =
                              provider.makina.level > 1; // 簡易的なクリア判定
                          final successRate = quest.calculateSuccessRate(
                              provider.makina,
                              provider.makina.reincarnationCount > 0);

                          // バフを考慮した実際の所要時間を計算
                          double reduction = 1.0;
                          for (var buff in provider.makina.activeBuffs) {
                            if (!buff.isExpired && buff.timeReductionRate > 0) {
                              reduction = 1.0 - buff.timeReductionRate;
                            }
                          }
                          final actualDuration =
                              (quest.durationMinutes * reduction).toInt();

                          return _buildQuestCard(context, provider, quest,
                              successRate, actualDuration);
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
    final m = provider.makina;
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '現在のランク: ${QuestData.getGuildRankName(m.guildRank)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (m.reincarnationCount > 0)
              Chip(
                label: Text('転生回数: ${m.reincarnationCount}'),
                backgroundColor: Colors.amber.shade200,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('挑戦できるクエストがありません'));
  }

  Widget _buildQuestCard(BuildContext context, GameProvider provider,
      Quest quest, double rate, int duration) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(quest.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quest.description),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildDifficultyChip(quest.difficulty),
                const SizedBox(width: 8),
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('$duration分',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)), // 所要時間を追加
                const SizedBox(width: 8),
                Text(
                  '成功率: ${(rate * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                      color: _getSuccessRateColor(rate),
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showQuestDetail(context, provider, quest, rate, duration),
      ),
    );
  }

  Widget _buildDifficultyChip(int d) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: Text('難易度 $d', style: const TextStyle(fontSize: 12)),
    );
  }

  Color _getSuccessRateColor(double r) {
    if (r >= 0.8) return Colors.green;
    if (r >= 0.5) return Colors.orange;
    return Colors.red;
  }

  void _showQuestDetail(
    BuildContext context,
    GameProvider provider,
    Quest quest,
    double successRate,
    int duration,
  ) {
    bool isStarting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text(quest.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(quest.description),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('報酬経験値:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${quest.experienceReward} EXP',
                        style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold)), // 経験値量を追加
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('所要時間:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('$duration 分',
                        style: const TextStyle(color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('必要ステータス目安',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                _buildRequirementRow('こうげき', quest.targetAttack,
                    provider.makina.effectiveAttack),
                _buildRequirementRow(
                    'まほう', quest.targetMagic, provider.makina.effectiveMagic),
                _buildRequirementRow(
                    'すばやさ', quest.targetSpeed, provider.makina.effectiveSpeed),
                const SizedBox(height: 16),
                Text(
                  '予測成功率: ${(successRate * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getSuccessRateColor(successRate)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: isStarting ? null : () => Navigator.pop(context),
                child: const Text('キャンセル')),
            ElevatedButton(
              onPressed: isStarting
                  ? null
                  : () async {
                      setState(() => isStarting = true);
                      await provider.startQuest(quest);
                      if (context.mounted) {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white),
              child: isStarting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('クエスト開始'),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildRequirementRow(String n, int r, int c) {
    final isMet = c >= r;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(n, style: const TextStyle(fontSize: 13)),
          Text('$c / $r',
              style: TextStyle(
                  fontSize: 13,
                  color: isMet ? Colors.green : Colors.red,
                  fontWeight: isMet ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
