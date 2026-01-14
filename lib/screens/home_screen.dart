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
              errorBuilder: (context, error, stackTrace) =>
                  const Text('AI冒険者マキナ'),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AchievementScreen())),
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
            if (provider.questResult != null) {
              _showQuestResultDialog(context, provider);
            } else if (provider.hasRankedUp) {
              _showRankUpDialog(context, provider);
            } else if (provider.newlyUnlockedAchievement != null) {
              _showAchievementUnlockedDialog(context, provider);
            }
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

// ★リザルトダイアログ（見切れ修正版）
  void _showQuestResultDialog(BuildContext context, GameProvider provider) {
    final result = provider.questResult!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 10),
        child: Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // 画像表示エリア
                    Container(
                      width: double.infinity,
                      // ★高さを350に広げ、見切れにくくしました
                      height: 350,
                      color: Colors.black, // 画像の横に余白が出る場合は黒で埋める
                      child: Image.asset(
                        result.isSuccess
                            ? 'assets/images/quest_success_bg.png'
                            : 'assets/images/quest_failure_bg.png',
                        // ★ここを BoxFit.contain に変更！
                        // これで画像全体が枠の中に収まるようになります
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: Colors.grey,
                          child: const Center(child: Text('画像読み込み失敗')),
                        ),
                      ),
                    ),
                    // グラデーション（文字を読みやすくするため）
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                            stops: const [0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // クエスト完了テキスト
                    Positioned(
                      bottom: 20,
                      child: Text(
                        result.isSuccess ? 'QUEST CLEAR!' : 'QUEST FAILED...',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: result.isSuccess
                              ? Colors.orangeAccent
                              : Colors.white70,
                          shadows: const [
                            Shadow(blurRadius: 10, color: Colors.black)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        result.questName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '獲得経験値: +${result.expGained}',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.blue),
                      ),
                      if (result.drop != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          '入手: ${result.drop!.name}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange),
                        ),
                      ],
                      const Divider(height: 30),
                      Text(
                        result.message,
                        style: const TextStyle(
                            fontSize: 14, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            provider.clearQuestResult();
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('戻る'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
                  color: Colors.blue.shade50),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset('assets/images/makina.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, size: 100)),
              ),
            ),
            const SizedBox(height: 12),
            Text('マキナ',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, color: Colors.pink, size: 20),
                const SizedBox(width: 4),
                Text('親密度: ${makina.intimacy.toStringAsFixed(0)}'),
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
                        const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
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
    final m = provider.makina;
    final rankName = QuestData.getGuildRankName(m.guildRank);
    final req = QuestData.getQuestsRequiredForRankUp(m.guildRank);
    return Card(
      color: Colors.deepPurple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ギルドランク',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(rankName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (m.guildRank < 6) ...[
              const SizedBox(height: 12),
              Text('昇格まで: ${m.questSuccessCountForCurrentRank} / $req'),
              LinearProgressIndicator(
                  value: m.questSuccessCountForCurrentRank / req,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation(Colors.amber)),
            ],
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
            const Text('ステータス',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildStatRow('こうげき', m.effectiveAttack, Colors.red),
            _buildStatRow('まほう', m.effectiveMagic, Colors.blue),
            _buildStatRow('すばやさ', m.effectiveSpeed, Colors.green),
            _buildStatRow('かしこさ', m.effectiveIntelligence, Colors.purple),
            _buildStatRow('ぼうぎょ', m.effectiveDefense, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String name, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(name)),
          Expanded(
              child: LinearProgressIndicator(
                  value: value / 100,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation(color))),
          const SizedBox(width: 8),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPersonalityCard(GameProvider provider) {
    final m = provider.makina;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('性格',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildPersonalityBar('勇敢', '慎重', m.brave, Colors.red, Colors.blue),
            const SizedBox(height: 8),
            _buildPersonalityBar(
                '甘え', '自立', m.dependent, Colors.pink, Colors.teal),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalityBar(
      String l, String r, double v, Color lc, Color rc) {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l, style: const TextStyle(fontSize: 12)),
          Text(r, style: const TextStyle(fontSize: 12))
        ]),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
                height: 20,
                decoration: BoxDecoration(
                    gradient:
                        LinearGradient(colors: [lc, Colors.grey.shade300, rc]),
                    borderRadius: BorderRadius.circular(10))),
            Positioned(
                left: ((v + 100) / 200) * 200,
                top: 2,
                child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle))),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, GameProvider provider) {
    if (provider.isOnQuest) {
      final rem = provider.remainingTime;
      return Card(
        color: Colors.orange.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.access_time, size: 48, color: Colors.orange),
              Text('クエスト中: ${provider.makina.currentQuest?.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('残り時間: ${rem?.inSeconds}秒',
                  style: const TextStyle(fontSize: 20)),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const QuestListScreen())),
          icon: const Icon(Icons.map),
          label: const Text('クエストを選ぶ'),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50)),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const EquipmentScreen())),
          icon: const Icon(Icons.shield),
          label: const Text('装備管理'),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50)),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AchievementScreen())),
          icon: const Icon(Icons.emoji_events),
          label: const Text('実績'),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: provider.currentMessage == null
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ConversationScreen())),
          icon: const Icon(Icons.chat),
          label: const Text('マキナと話す'),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50)),
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
            const Text('マキナからのメッセージ',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(provider.currentMessage!),
            Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ConversationScreen())),
                    child: const Text('返事をする'))),
          ],
        ),
      ),
    );
  }

  Widget _buildDropCard(BuildContext context, GameProvider provider) {
    final e = provider.droppedEquipment!;
    return Card(
      color: Colors.amber.shade50,
      child: ListTile(
        leading: const Icon(Icons.star, color: Colors.amber, size: 32),
        title: const Text('アイテムゲット！',
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(e.name),
        trailing: TextButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const EquipmentScreen())),
            child: const Text('管理')),
      ),
    );
  }

  void _showRankUpDialog(BuildContext context, GameProvider provider) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
                title: const Text('ランクアップ！'),
                content: Text(
                    '${QuestData.getGuildRankName(provider.makina.guildRank)}ランクに昇格しました！'),
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
                content: const Text('データをリセットしますか？'),
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
