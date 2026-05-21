import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/makina.dart';
import '../data/quest_data.dart';

class QuestListScreen extends StatelessWidget {
  const QuestListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('クエスト選択'), backgroundColor: Colors.deepPurple),
      body: Consumer<GameProvider>(
        builder: (context, provider, child) {
          final availableQuests = provider.getAvailableQuests();
          return Column(
            children: [
              _buildRankInfoCard(provider),
              Expanded(
                child: availableQuests.isEmpty
                    ? const Center(child: Text('挑戦できるクエストがありません'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: availableQuests.length,
                        itemBuilder: (context, index) {
                          final quest = availableQuests[index];
                          final isCleared =
                              provider.clearedQuestIds.contains(quest.id);
                          final successRate = quest.calculateSuccessRate(
                              provider.makina, isCleared);
                          double reduction = 1.0;
                          for (var buff in provider.makina.activeBuffs) {
                            if (!buff.isExpired && buff.timeReductionRate > 0)
                              reduction = 1.0 - buff.timeReductionRate;
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
            Text('ランク: ${QuestData.getGuildRankName(m.guildRank)}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (m.reincarnationCount > 0)
              Chip(
                  label: Text('転生:${m.reincarnationCount}'),
                  backgroundColor: Colors.amber.shade200),
          ],
        ),
      ),
    );
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
            Row(children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text('難易度 ${quest.difficulty}',
                      style: const TextStyle(fontSize: 12))),
              const SizedBox(width: 8),
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text('$duration分',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 8),
              Text('成功率: ${(rate * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                      color: rate >= 0.8
                          ? Colors.green
                          : (rate >= 0.5 ? Colors.orange : Colors.red),
                      fontWeight: FontWeight.bold)),
            ]),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showQuestDetail(context, provider, quest, rate, duration),
      ),
    );
  }

  void _showQuestDetail(BuildContext context, GameProvider provider,
      Quest quest, double successRate, int duration) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(quest.name),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(quest.description),
            const Divider(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('報酬:'),
              Text('${quest.experienceReward} EXP',
                  style: const TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold))
            ]),
            const SizedBox(height: 16),
            const Text('必要ステータス目安',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            _buildReqRow(
                '攻撃', quest.targetAttack, provider.makina.effectiveAttack),
            _buildReqRow(
                '魔法', quest.targetMagic, provider.makina.effectiveMagic),
            const SizedBox(height: 16),
            Text('予測成功率: ${(successRate * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: successRate >= 0.8 ? Colors.green : Colors.orange)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () async {
              await provider.startQuest(quest);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white),
            child: const Text('クエスト開始'),
          ),
        ],
      ),
    );
  }

  Widget _buildReqRow(String n, int r, int c) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(n, style: const TextStyle(fontSize: 13)),
      Text('$c / $r',
          style: TextStyle(
              fontSize: 13, color: c >= r ? Colors.green : Colors.red))
    ]);
  }
}
