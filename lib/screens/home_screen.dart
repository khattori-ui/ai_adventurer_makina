import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../data/quest_data.dart';
import 'quest_list_screen.dart';
import 'conversation_screen.dart';
import 'equipment_screen.dart';
import 'achievement_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return const Text('AI冒険者マキナ');
              },
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AchievementScreen(),
                ),
              );
            },
            tooltip: '実績',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _showResetDialog(context),
          ),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, provider, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (provider.hasRankedUp) {
              _showRankUpDialog(context, provider);
            } else if (provider.newlyUnlockedAchievement != null) {
              _showAchievementUnlockedDialog(context, provider);
            }
          });

          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMakinaCard(context, provider),
                  const SizedBox(height: 20),
                  _buildGuildRankCard(provider),
                  const SizedBox(height: 20),
                  _buildStatusCard(provider),
                  const SizedBox(height: 20),
                  _buildPersonalityCard(provider),
                  const SizedBox(height: 20),
                  _buildActionButtons(context, provider),
                  if (provider.currentMessage != null) ...[
                    const SizedBox(height: 20),
                    _buildMessageCard(context, provider),
                  ],
                  if (provider.droppedEquipment != null) ...[
                    const SizedBox(height: 20),
                    _buildDropCard(context, provider),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMakinaCard(BuildContext context, GameProvider provider) {
    final makina = provider.makina;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.lightBlue.shade100,
                    Colors.green.shade100,
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/makina.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 100,
                        color: Colors.deepPurple,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'マキナ',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, color: Colors.pink, size: 20),
                const SizedBox(width: 4),
                Text(
                  '親密度: ${makina.intimacy.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Lv.${makina.level}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: makina.experience / makina.experienceToNextLevel,
                    backgroundColor: Colors.grey.shade300,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${makina.experience}/${makina.experienceToNextLevel}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuildRankCard(GameProvider provider) {
    final makina = provider.makina;
    final rankName = QuestData.getGuildRankName(makina.guildRank);
    final questsRequired =
        QuestData.getQuestsRequiredForRankUp(makina.guildRank);
    final progress = makina.questSuccessCountForCurrentRank;
    final nextRankName = makina.guildRank < 6
        ? QuestData.getGuildRankName(makina.guildRank + 1)
        : 'MAX';

    return Card(
      elevation: 2,
      color: Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.military_tech, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    const Text(
                      'ギルドランク',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    rankName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (makina.guildRank < 6) ...[
              const SizedBox(height: 12),
              Text(
                '$rankName ランクのクエストをクリア: $progress / $questsRequired',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress / questsRequired,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
              const SizedBox(height: 8),
              Text(
                '次のランク: $nextRankName',
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
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
      ),
    );
  }

  Widget _buildStatusCard(GameProvider provider) {
    final makina = provider.makina;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ステータス',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatRow('こうげき', makina.effectiveAttack, Colors.red),
            _buildStatRow('まほう', makina.effectiveMagic, Colors.blue),
            _buildStatRow('すばやさ', makina.effectiveSpeed, Colors.green),
            _buildStatRow('かしこさ', makina.effectiveIntelligence, Colors.purple),
            _buildStatRow('ぼうぎょ', makina.effectiveDefense, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String name, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(name, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              value.toString(),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalityCard(GameProvider provider) {
    final makina = provider.makina;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '性格',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildPersonalityBar(
              '勇敢',
              '慎重',
              makina.brave,
              Colors.red,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildPersonalityBar(
              '甘え',
              '自立',
              makina.dependent,
              Colors.pink,
              Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalityBar(
    String leftLabel,
    String rightLabel,
    double value,
    Color leftColor,
    Color rightColor,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(leftLabel, style: const TextStyle(fontSize: 12)),
            Text(rightLabel, style: const TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            final position = ((value + 100) / 200) * barWidth;

            return Stack(
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [leftColor, Colors.grey.shade300, rightColor],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Positioned(
                  left: position - 8,
                  top: 2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, GameProvider provider) {
    if (provider.isOnQuest) {
      final remaining = provider.remainingTime;
      final minutes = remaining?.inMinutes ?? 0;
      final seconds = (remaining?.inSeconds ?? 0) % 60;

      return Card(
        color: Colors.orange.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.access_time, size: 48, color: Colors.orange),
              const SizedBox(height: 8),
              Text(
                'クエスト中: ${provider.makina.currentQuest?.name}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '残り時間: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const QuestListScreen(),
              ),
            );
          },
          icon: const Icon(Icons.map),
          label: const Text('クエストを選ぶ'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EquipmentScreen(),
              ),
            );
          },
          icon: const Icon(Icons.shield),
          label: const Text('装備管理'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AchievementScreen(),
              ),
            );
          },
          icon: const Icon(Icons.emoji_events),
          label: const Text('実績'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: provider.currentMessage == null
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConversationScreen(),
                    ),
                  );
                },
          icon: const Icon(Icons.chat),
          label: const Text('マキナと話す'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageCard(BuildContext context, GameProvider provider) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.message, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'マキナからのメッセージ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              provider.currentMessage!,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConversationScreen(),
                    ),
                  );
                },
                child: const Text('返事をする'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropCard(BuildContext context, GameProvider provider) {
    final equipment = provider.droppedEquipment!;
    Color rarityColor;
    String rarityText;

    switch (equipment.rarity) {
      case 1:
        rarityColor = Colors.grey.shade700;
        rarityText = 'コモン';
        break;
      case 2:
        rarityColor = Colors.blue;
        rarityText = 'レア';
        break;
      case 3:
        rarityColor = Colors.purple;
        rarityText = 'エピック';
        break;
      default:
        rarityColor = Colors.black;
        rarityText = '不明';
    }

    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 32),
                const SizedBox(width: 8),
                const Text(
                  'アイテムをゲット!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: rarityColor, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        equipment.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: rarityColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          rarityText,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                        ),
                        backgroundColor: rarityColor,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildEquipmentBonus(equipment),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EquipmentScreen(),
                    ),
                  );
                },
                child: const Text('装備管理を開く'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentBonus(equipment) {
    List<Widget> bonuses = [];
    if (equipment.attackBonus > 0) {
      bonuses.add(_buildBonusChip('攻撃+${equipment.attackBonus}', Colors.red));
    }
    if (equipment.magicBonus > 0) {
      bonuses.add(_buildBonusChip('魔法+${equipment.magicBonus}', Colors.blue));
    }
    if (equipment.speedBonus > 0) {
      bonuses.add(_buildBonusChip('速さ+${equipment.speedBonus}', Colors.green));
    }
    if (equipment.intelligenceBonus > 0) {
      bonuses.add(
          _buildBonusChip('賢さ+${equipment.intelligenceBonus}', Colors.purple));
    }
    if (equipment.defenseBonus > 0) {
      bonuses
          .add(_buildBonusChip('防御+${equipment.defenseBonus}', Colors.orange));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: bonuses,
    );
  }

  Widget _buildBonusChip(String text, Color color) {
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withOpacity(0.2),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showRankUpDialog(BuildContext context, GameProvider provider) {
    final rankName = QuestData.getGuildRankName(provider.makina.guildRank);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.amber.shade50,
        title: Row(
          children: [
            const Icon(Icons.military_tech, color: Colors.amber, size: 32),
            const SizedBox(width: 8),
            const Text('ランクアップ!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎉',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              '$rankName ランクに昇格!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              '新しいクエストに挑戦できるようになりました!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.clearMessage();
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAchievementUnlockedDialog(
      BuildContext context, GameProvider provider) {
    final achievement = provider.newlyUnlockedAchievement!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.amber.shade50,
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            const SizedBox(width: 8),
            const Text('実績解放!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              achievement.icon,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              achievement.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.clearNewAchievement();
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ゲームをリセット'),
        content: const Text('本当にゲームをリセットしますか?すべてのデータが削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<GameProvider>(context, listen: false).resetGame();
              Navigator.pop(context);
            },
            child: const Text('リセット', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
