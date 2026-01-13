import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/makina.dart';

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
          final quests = provider.getAvailableQuests();
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: quests.length,
            itemBuilder: (context, index) {
              final quest = quests[index];
              final successRate = quest.calculateSuccessRate(provider.makina);
              
              return _buildQuestCard(
                context, 
                provider, 
                quest, 
                successRate,
              );
            },
          );
        },
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
              const SizedBox(height: 8),
              Text(
                quest.description,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('${quest.durationMinutes}分'),
                  const SizedBox(width: 16),
                  Icon(Icons.star, size: 16, color: Colors.amber),
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
    } else {
      color = Colors.purple;
      label = '超級';
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
                provider.makina.attack,
              ),
              _buildRequirementRow(
                'まほう', 
                quest.targetMagic, 
                provider.makina.magic,
              ),
              _buildRequirementRow(
                'すばやさ', 
                quest.targetSpeed, 
                provider.makina.speed,
              ),
              _buildRequirementRow(
                'かしこさ', 
                quest.targetIntelligence, 
                provider.makina.intelligence,
              ),
              _buildRequirementRow(
                'ぼうぎょ', 
                quest.targetDefense, 
                provider.makina.defense,
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