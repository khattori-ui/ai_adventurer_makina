import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../data/quest_data.dart';
import 'quest_list_screen.dart';
import 'conversation_screen.dart';
import 'equipment_screen.dart';
import 'achievement_screen.dart';
import 'debug_item_screen.dart';
import 'reincarnation_screen.dart';
import 'active_buff_screen.dart';
import 'costume_screen.dart';
import 'collection_screen.dart'; // ★追加

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo.png',
            height: 40, errorBuilder: (_, __, ___) => const Text('AI冒険者マキナ')),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.orangeAccent),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DebugItemScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.checkroom, color: Colors.pink),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CostumeScreen()),
            ),
          ),
          // ★図鑑ボタンを追加
          IconButton(
            icon: const Icon(Icons.menu_book, color: Colors.teal),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CollectionScreen()),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.emoji_events),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AchievementScreen()))),
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _showResetDialog(context)),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, provider, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (provider.questResult != null)
              _showQuestResultDialog(context, provider);
            else if (provider.hasRankedUp)
              _showRankUpDialog(context, provider);
            else if (provider.newlyUnlockedAchievement != null)
              _showAchievementUnlockedDialog(context, provider);
          });
          if (provider.isLoading)
            return const Center(child: CircularProgressIndicator());
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMakinaCard(context, provider),
                  const SizedBox(height: 20),
                  if (provider.makina.activeBuffs.any((b) => !b.isExpired))
                    _buildActiveBuffsCard(context, provider),
                  if (provider.makina.activeBuffs.any((b) => !b.isExpired))
                    const SizedBox(height: 20),
                  if (provider.makina.level >= 30)
                    _buildReincarnationButton(context, provider),
                  const SizedBox(height: 20),
                  _buildGuildRankCard(provider),
                  const SizedBox(height: 20),
                  _buildStatusCard(provider),
                  const SizedBox(height: 20),
                  _buildActionButtons(context, provider),
                  if (provider.currentMessage != null) ...[
                    const SizedBox(height: 20),
                    _buildMessageCard(context, provider)
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getCostumeImagePath(String? costumeId) {
    switch (costumeId) {
      case 'school_uniform':
        return 'assets/images/costume_school.png';
      case 'knight_armor':
        return 'assets/images/costume_knight.png';
      case 'mage_robe':
        return 'assets/images/costume_mage.png';
      case 'casual':
        return 'assets/images/costume_casual.png';
      case 'swimsuit':
        return 'assets/images/costume_swim.png';
      case 'dress':
        return 'assets/images/costume_dress.png';
      case 'default':
      default:
        return 'assets/images/makina.png';
    }
  }

  Widget _buildActiveBuffsCard(BuildContext context, GameProvider provider) {
    final activeBuffs =
        provider.makina.activeBuffs.where((b) => !b.isExpired).toList();

    return Card(
      color: Colors.purple.shade50,
      elevation: 4,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ActiveBuffScreen()),
        ),
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
                      const Icon(Icons.auto_awesome,
                          color: Colors.purple, size: 28),
                      const SizedBox(width: 8),
                      const Text(
                        'アクティブバフ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${activeBuffs.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...activeBuffs.take(2).map((buff) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            buff.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          _formatShortTime(
                              buff.expiry.difference(DateTime.now())),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )),
              if (activeBuffs.length > 2)
                Text(
                  '他${activeBuffs.length - 2}件...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '詳細を見る',
                    style: TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, color: Colors.purple, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatShortTime(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}日';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}時間';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分';
    } else {
      return '${duration.inSeconds}秒';
    }
  }

  Widget _buildReincarnationButton(
      BuildContext context, GameProvider provider) {
    return Card(
      color: Colors.amber.shade100,
      elevation: 6,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.amber, width: 2)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReincarnationScreen()),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber, size: 32),
              SizedBox(width: 12),
              Text('転生の祭壇へ',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMakinaCard(BuildContext context, GameProvider provider) {
    final m = provider.makina;
    final imagePath = _getCostumeImagePath(m.currentOutfitId);

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
                    color: Colors.blue.shade50),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person, size: 100)))),
            const SizedBox(height: 12),
            Text(
                'マキナ ${m.reincarnationCount > 0 ? '(転生回数: ${m.reincarnationCount})' : ''}',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text('親密度: ${m.intimacy.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            Row(children: [
              Text('Lv.${m.level}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                  child: LinearProgressIndicator(
                      value: m.experience / m.experienceToNextLevel,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.deepPurple))),
              const SizedBox(width: 8),
              Text('${m.experience}/${m.experienceToNextLevel}')
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(GameProvider provider) {
    final m = provider.makina;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ステータス (バフ適用済み)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildStatRow('こうげき', m.effectiveAttack, Colors.red, 1000),
            _buildStatRow('まほう', m.effectiveMagic, Colors.blue, 1000),
            _buildStatRow('ぼうぎょ', m.effectiveDefense, Colors.orange, 1000),
            const Divider(height: 32),
            const Text('性格パラメータ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildStatRow('勇敢さ', m.brave.toInt(), Colors.deepOrange, 100,
                isPersonality: true),
            _buildStatRow('依存度', m.dependent.toInt(), Colors.pinkAccent, 100,
                isPersonality: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String name, int val, Color col, int maxVal,
      {bool isPersonality = false}) {
    double progress =
        isPersonality ? (val + 100) / 200 : (val / maxVal).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(name)),
          Expanded(
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(col),
              minHeight: 8,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text('$val',
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right),
          )
        ],
      ),
    );
  }

  void _showQuestResultDialog(BuildContext context, GameProvider provider) {
    final res = provider.questResult!;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
                child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
              Image.asset(
                  res.isSuccess
                      ? 'assets/images/quest_success_bg.png'
                      : 'assets/images/quest_failure_bg.png',
                  height: 300,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                      height: 300,
                      color: res.isSuccess ? Colors.green : Colors.red,
                      child: Icon(
                          res.isSuccess ? Icons.check_circle : Icons.cancel,
                          size: 100,
                          color: Colors.white))),
              Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    Text(res.questName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text('獲得EXP: +${res.expGained}',
                        style: const TextStyle(color: Colors.blue)),
                    if (res.drop != null)
                      Text('入手: ${res.drop!.name}',
                          style: const TextStyle(color: Colors.orange)),
                    const Divider(),
                    Text(res.message, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: () {
                          provider.clearQuestResult();
                          Navigator.pop(context);
                        },
                        child: const Text('閉じる'))
                  ]))
            ]))));
  }

  Widget _buildGuildRankCard(GameProvider provider) {
    final m = provider.makina;
    final name = QuestData.getGuildRankName(m.guildRank);
    final req = QuestData.getQuestsRequiredForRankUp(m.guildRank);
    return Card(
        color: Colors.deepPurple.shade50,
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('ランク',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)))
              ]),
              if (m.guildRank < 6) ...[
                const SizedBox(height: 12),
                Text('昇格まで: ${m.questSuccessCountForCurrentRank} / $req'),
                LinearProgressIndicator(
                    value: m.questSuccessCountForCurrentRank / req,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: const AlwaysStoppedAnimation(Colors.amber))
              ]
            ])));
  }

  Widget _buildActionButtons(BuildContext context, GameProvider provider) {
    if (provider.isOnQuest)
      return Card(
          color: Colors.orange.shade100,
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(children: [
                const Icon(Icons.access_time, size: 48, color: Colors.orange),
                Text('残り: ${provider.remainingTime?.inSeconds}秒',
                    style: const TextStyle(fontSize: 24))
              ])));
    return Column(children: [
      ElevatedButton.icon(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const QuestListScreen())),
          icon: const Icon(Icons.map),
          label: const Text('クエスト'),
          style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white)),
      const SizedBox(height: 12),
      ElevatedButton.icon(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const EquipmentScreen())),
          icon: const Icon(Icons.shield),
          label: const Text('装備'),
          style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white)),
    ]);
  }

  Widget _buildMessageCard(BuildContext context, GameProvider provider) {
    return Card(
        color: Colors.blue.shade50,
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('マキナの言葉',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(provider.currentMessage!),
              Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ConversationScreen())),
                      child: const Text('返事をする')))
            ])));
  }

  void _showRankUpDialog(BuildContext context, GameProvider provider) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
                title: const Text('ランクアップ！'),
                content: Text(
                    '${QuestData.getGuildRankName(provider.makina.guildRank)}ランクになったよ！'),
                actions: [
                  TextButton(
                      onPressed: () {
                        provider.clearMessage();
                        Navigator.pop(context);
                      },
                      child: const Text('OK'))
                ]));
  }

  void _showAchievementUnlockedDialog(
      BuildContext context, GameProvider provider) {
    final a = provider.newlyUnlockedAchievement!;
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
                title: const Text('実績解除！'),
                content: Text('${a.icon} ${a.name}'),
                actions: [
                  TextButton(
                      onPressed: () {
                        provider.clearNewAchievement();
                        Navigator.pop(context);
                      },
                      child: const Text('OK'))
                ]));
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
                title: const Text('リセット'),
                content: const Text('全データを消去しますか?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('いいえ')),
                  TextButton(
                      onPressed: () {
                        Provider.of<GameProvider>(context, listen: false)
                            .resetGame();
                        Navigator.pop(context);
                      },
                      child: const Text('はい'))
                ]));
  }
}
