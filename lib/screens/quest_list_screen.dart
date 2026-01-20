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
                          // ★修正ポイント：第2引数にクリア済み判定を渡す
                          final isCleared = provider.makina.currentQuest?.id ==
                                  quest.id ||
                              provider.makina.level > 1; // 簡易判定。本来はproviderから取得
                          final successRate = quest.calculateSuccessRate(
                              provider.makina,
                              provider.makina.reincarnationCount >
                                  0 // 転生済みならクリア判定チェックを有効化
                              );
                          return _buildQuestCard(
                              context, provider, quest, successRate);
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
    return const Center(
      child: Text('挑戦できるクエストがありません'),
    );
  }

  Widget _buildQuestCard(
      BuildContext context, GameProvider provider, Quest quest, double rate) {
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
                Text(
                  '成功率: ${(rate * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: _getSuccessRateColor(rate),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showQuestDetail(context, provider, quest, rate),
      ),
    );
  }

  Widget _buildDifficultyChip(int d) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
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
                const SizedBox(height: 16),
                const Text('必要ステータス',
                    style: TextStyle(fontWeight: FontWeight.bold)),
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
                    color: _getSuccessRateColor(successRate),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isStarting ? null : () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
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
                foregroundColor: Colors.white,
              ),
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
          Text(n),
          Text(
            '$c / $r',
            style: TextStyle(
              color: isMet ? Colors.green : Colors.red,
              fontWeight: isMet ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
