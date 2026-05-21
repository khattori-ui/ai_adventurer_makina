import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../data/quest_data.dart';
import '../models/makina.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('図鑑・ログ'),
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.book), text: 'クエスト図鑑'),
            Tab(icon: Icon(Icons.inventory), text: '装備図鑑'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          QuestCollectionTab(),
          EquipmentCollectionTab(),
        ],
      ),
    );
  }
}

// クエスト図鑑タブ
class QuestCollectionTab extends StatelessWidget {
  const QuestCollectionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, child) {
        final allQuests = QuestData.getAllQuests();
        final clearedQuests =
            allQuests.where((q) => _isQuestCleared(provider, q.id)).toList();
        final availableQuests = allQuests
            .where((q) => q.requiredGuildRank <= provider.makina.guildRank)
            .toList();

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.teal.shade50, Colors.white],
            ),
          ),
          child: Column(
            children: [
              _buildQuestStats(clearedQuests.length, allQuests.length,
                  availableQuests.length),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: allQuests.length,
                  itemBuilder: (context, index) {
                    final quest = allQuests[index];
                    final isCleared = _isQuestCleared(provider, quest.id);
                    final isAvailable =
                        quest.requiredGuildRank <= provider.makina.guildRank;
                    return _buildQuestCard(
                        context, quest, isCleared, isAvailable);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 実際のクリア履歴（provider）をチェックする仕組みにアップデート！
  bool _isQuestCleared(GameProvider provider, String questId) {
    return provider.clearedQuestIds.contains(questId);
  }

  Widget _buildQuestStats(int cleared, int total, int available) {
    final clearRate = (cleared / total * 100).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('クリア', '$cleared', Colors.green),
              _buildStatItem('利用可能', '$available', Colors.blue),
              _buildStatItem('合計', '$total', Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: cleared / total,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation(Colors.green),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            '図鑑達成率: $clearRate%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestCard(
      BuildContext context, Quest quest, bool isCleared, bool isAvailable) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isCleared ? Colors.white : Colors.grey.shade200,
      child: ExpansionTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isCleared ? Colors.green.shade100 : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCleared ? Icons.check_circle : Icons.help_outline,
            color: isCleared ? Colors.green : Colors.grey,
            size: 30,
          ),
        ),
        title: Text(
          isAvailable ? quest.name : '???',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isCleared ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Text(
          isAvailable
              ? '難易度: ${quest.difficulty} | Rank ${QuestData.getGuildRankName(quest.requiredGuildRank)}'
              : 'ランク ${QuestData.getGuildRankName(quest.requiredGuildRank)} で解放',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        children: [
          if (isAvailable)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.description,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Divider(height: 24),
                  _buildQuestDetail('所要時間', '${quest.durationMinutes}分'),
                  _buildQuestDetail('報酬経験値', '${quest.experienceReward} EXP'),
                  _buildQuestDetail('失敗時経験値', '${quest.failureExperience} EXP'),
                  if (quest.possibleDrops.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'ドロップ装備:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...quest.possibleDrops.map((dropId) {
                      final equipment = QuestData.getEquipmentById(dropId);
                      return Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Text(
                          '• ${equipment?.name ?? dropId}',
                          style: TextStyle(
                            fontSize: 13,
                            color: _getRarityColor(equipment?.rarity ?? 1),
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(int rarity) {
    switch (rarity) {
      case 1:
        return Colors.grey.shade700;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.purple;
      default:
        return Colors.black;
    }
  }
}

// 装備図鑑タブ
class EquipmentCollectionTab extends StatelessWidget {
  const EquipmentCollectionTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, child) {
        final allEquipment = QuestData.equipmentDatabase.values.toList();
        final discoveredEquipment =
            allEquipment.where((e) => _hasDiscovered(provider, e.id)).toList();

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.teal.shade50, Colors.white],
            ),
          ),
          child: Column(
            children: [
              _buildEquipmentStats(
                  discoveredEquipment.length, allEquipment.length),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: allEquipment.length,
                  itemBuilder: (context, index) {
                    final equipment = allEquipment[index];
                    final isDiscovered = _hasDiscovered(provider, equipment.id);
                    return _buildEquipmentCard(
                        context, equipment, isDiscovered);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _hasDiscovered(GameProvider provider, String equipmentId) {
    return provider.makina.hasEquipment(equipmentId);
  }

  Widget _buildEquipmentStats(int discovered, int total) {
    final rate = (discovered / total * 100).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '$discovered',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const Text(
                    '発見',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const Text(
                '/',
                style: TextStyle(fontSize: 32, color: Colors.grey),
              ),
              Column(
                children: [
                  Text(
                    '$total',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Text(
                    '合計',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: discovered / total,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation(Colors.orange),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            '図鑑達成率: $rate%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(
      BuildContext context, Equipment equipment, bool isDiscovered) {
    return Card(
      elevation: isDiscovered ? 4 : 1,
      color: isDiscovered ? Colors.white : Colors.grey.shade200,
      child: InkWell(
        onTap: isDiscovered
            ? () => _showEquipmentDetail(context, equipment)
            : null,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDiscovered
                          ? _getRarityColor(equipment.rarity).withValues(alpha: 0.1)
                          : Colors.grey.shade300,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _getSlotIcon(equipment.slot),
                        size: 60,
                        color: isDiscovered
                            ? _getRarityColor(equipment.rarity)
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDiscovered ? equipment.name : '???',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDiscovered
                                ? _getRarityColor(equipment.rarity)
                                : Colors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (isDiscovered)
                          _buildRarityBadge(equipment.rarity)
                        else
                          const Text(
                            '未発見',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (!isDiscovered)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.help_outline,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRarityBadge(int rarity) {
    String text;
    Color color;

    switch (rarity) {
      case 1:
        text = '普通';
        color = Colors.grey;
        break;
      case 2:
        text = 'レア';
        color = Colors.blue;
        break;
      case 3:
        text = '激レア';
        color = Colors.purple;
        break;
      default:
        text = '';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _showEquipmentDetail(BuildContext context, Equipment equipment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          equipment.name,
          style: TextStyle(color: _getRarityColor(equipment.rarity)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getSlotIcon(equipment.slot),
                size: 80,
                color: _getRarityColor(equipment.rarity),
              ),
              const SizedBox(height: 16),
              _buildRarityBadge(equipment.rarity),
              const SizedBox(height: 16),
              _buildEquipmentStat('部位', _getSlotName(equipment.slot)),
              if (equipment.attackBonus > 0)
                _buildEquipmentStat('攻撃力', '+${equipment.attackBonus}'),
              if (equipment.magicBonus > 0)
                _buildEquipmentStat('魔法力', '+${equipment.magicBonus}'),
              if (equipment.speedBonus > 0)
                _buildEquipmentStat('速さ', '+${equipment.speedBonus}'),
              if (equipment.intelligenceBonus > 0)
                _buildEquipmentStat('賢さ', '+${equipment.intelligenceBonus}'),
              if (equipment.defenseBonus > 0)
                _buildEquipmentStat('防御力', '+${equipment.defenseBonus}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSlotIcon(EquipmentSlot slot) {
    switch (slot) {
      case EquipmentSlot.weapon:
        return Icons.sports_martial_arts;
      case EquipmentSlot.armor:
        return Icons.shield;
      case EquipmentSlot.shield:
        return Icons.security;
      case EquipmentSlot.bracelet:
        return Icons.circle;
      case EquipmentSlot.boots:
        return Icons.directions_run;
    }
  }

  String _getSlotName(EquipmentSlot slot) {
    switch (slot) {
      case EquipmentSlot.weapon:
        return '武器';
      case EquipmentSlot.armor:
        return '防具';
      case EquipmentSlot.shield:
        return '盾';
      case EquipmentSlot.bracelet:
        return '腕輪';
      case EquipmentSlot.boots:
        return '靴';
    }
  }

  Color _getRarityColor(int rarity) {
    switch (rarity) {
      case 1:
        return Colors.grey.shade700;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.purple;
      default:
        return Colors.black;
    }
  }
}
