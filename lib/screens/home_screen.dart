import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../data/quest_data.dart';
import 'quest_list_screen.dart';
import 'conversation_screen.dart';
import 'equipment_screen.dart';
import 'achievement_screen.dart';
import 'debug_item_screen.dart';
import 'debug_time_estimator_screen.dart';
import 'debug_stats_screen.dart';
import 'admin_system_screen.dart';
import 'reincarnation_screen.dart';
import 'active_buff_screen.dart';
import 'costume_screen.dart';
import 'collection_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isShowingDialog = false;
  GameProvider? _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newProvider = context.read<GameProvider>();
    if (_provider != newProvider) {
      _provider?.removeListener(_onProviderChanged);
      _provider = newProvider;
      _provider!.addListener(_onProviderChanged);
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_onProviderChanged);
    super.dispose();
  }

  void _onProviderChanged() {
    if (_isShowingDialog || !mounted) return;
    final provider = _provider!;

    if (provider.questResult != null) {
      _isShowingDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) { _isShowingDialog = false; return; }
        _showQuestResultDialog(context, provider).then((_) => _isShowingDialog = false);
      });
    } else if (provider.hasRankedUp) {
      _isShowingDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) { _isShowingDialog = false; return; }
        _showRankUpDialog(context, provider).then((_) => _isShowingDialog = false);
      });
    } else if (provider.newlyUnlockedAchievement != null) {
      _isShowingDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) { _isShowingDialog = false; return; }
        _showAchievementUnlockedDialog(context, provider).then((_) => _isShowingDialog = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/logo.png',
            height: 40, errorBuilder: (_, __, ___) => const Text('AI冒険者マキナ')),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        actions: [
          Consumer<GameProvider>(builder: (context, provider, _) {
            if (!provider.isAdmin) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.admin_panel_settings,
                  color: Colors.white),
              tooltip: 'システム管理（管理者専用）',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminSystemScreen()),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.timer_outlined, color: Colors.cyanAccent),
            tooltip: 'プレイ時間シミュレーター',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const DebugTimeEstimatorScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.pinkAccent),
            tooltip: 'デバッグ：ステータス変更',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const DebugStatsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.orangeAccent),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DebugItemScreen())),
          ),
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _showResetDialog(context)),
        ],
      ),
      body: Consumer<GameProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMakinaCard(context, provider),
                  const SizedBox(height: 16),
                  _buildGuildRankCard(provider),
                  const SizedBox(height: 8),
                  _buildStatusCard(provider),
                  if (provider.makina.activeBuffs.any((b) => !b.isExpired)) ...[
                    const SizedBox(height: 8),
                    _buildActiveBuffsCard(context, provider),
                  ],
                  if (provider.makina.level >= 30) ...[
                    const SizedBox(height: 8),
                    _buildReincarnationButton(context, provider),
                  ],
                  const SizedBox(height: 24),
                  _buildMessageCard(context, provider),
                  const SizedBox(height: 16),
                  _buildActionButtons(context, provider),
                  const SizedBox(height: 32),
                  _buildBottomMenu(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomMenu(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMenuIcon(context, Icons.shopping_cart, 'ショップ', Colors.amber,
                const ShopScreen()),
            _buildMenuIcon(context, Icons.checkroom, '更衣室', Colors.pink,
                const CostumeScreen()),
            _buildMenuIcon(context, Icons.menu_book, '図鑑', Colors.teal,
                const CollectionScreen()),
            _buildMenuIcon(context, Icons.emoji_events, '実績', Colors.deepPurple,
                const AchievementScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuIcon(BuildContext context, IconData icon, String label,
      Color color, Widget screen) {
    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(label,
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMessageCard(BuildContext context, GameProvider provider) {
    final message = provider.currentMessage ?? "師匠、あたしと一緒に頑張ろうね！";
    return Card(
        elevation: 6,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.blue.shade100, width: 2),
        ),
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text('マキナ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800)),
                ],
              ),
              const SizedBox(height: 12),
              Text(message, style: const TextStyle(fontSize: 16, height: 1.5)),
              const SizedBox(height: 8),
              Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ConversationScreen())),
                      icon: const Icon(Icons.forum),
                      label: const Text('返事をする'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      )))
            ])));
  }

  Widget _buildActionButtons(BuildContext context, GameProvider provider) {
    if (provider.isOnQuest) {
      return Card(
          color: Colors.orange.shade50,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.orange)),
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.orange)),
                  const SizedBox(width: 16),
                  Text('進行中: ${provider.remainingTime?.inSeconds ?? 0}秒',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange))
                ],
              )));
    }
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const QuestListScreen())),
              icon: const Icon(Icons.map),
              label: const Text('クエスト'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EquipmentScreen())),
              icon: const Icon(Icons.shield),
              label: const Text('装備'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)))),
        ),
      ],
    );
  }

  Widget _buildMakinaCard(BuildContext context, GameProvider provider) {
    final m = provider.makina;
    String imagePath = 'assets/images/makina.png';
    if (m.currentOutfitId != null && m.currentOutfitId != 'default') {
      imagePath =
          'assets/images/costume_${m.currentOutfitId!.replaceAll('costume_', '')}.png';
    }
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(imagePath,
                    height: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.person,
                        size: 100, color: Colors.grey))),
            const SizedBox(height: 12),
            Text(
                'マキナ ${m.reincarnationCount > 0 ? '(転生:${m.reincarnationCount})' : ''}',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
              Text('Lv.${m.level}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                  child: LinearProgressIndicator(
                      value: m.experience / m.experienceToNextLevel,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.deepPurple),
                      minHeight: 8)),
              const SizedBox(width: 8),
              Text('${m.experience}')
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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildStatRow('こうげき', m.effectiveAttack, Colors.red, 1000),
            _buildStatRow('まほう', m.effectiveMagic, Colors.blue, 1000),
            _buildStatRow('ぼうぎょ', m.effectiveDefense, Colors.orange, 1000),
            const Divider(),
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(
            width: 60, child: Text(name, style: const TextStyle(fontSize: 12))),
        Expanded(
            child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation(col),
                minHeight: 6)),
        const SizedBox(width: 12),
        Text('$val',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
      ]),
    );
  }

  Widget _buildGuildRankCard(GameProvider provider) {
    final m = provider.makina;
    return Card(
        color: Colors.deepPurple.shade50,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('冒険者ランク',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(QuestData.getGuildRankName(m.guildRank),
                      style: const TextStyle(
                          color: Colors.deepPurple,
                          fontSize: 24,
                          fontWeight: FontWeight.bold))
                ])));
  }

  Widget _buildActiveBuffsCard(BuildContext context, GameProvider provider) {
    return ListTile(
      tileColor: Colors.purple.shade50,
      leading: const Icon(Icons.auto_awesome, color: Colors.purple),
      title: const Text('バフ発動中'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ActiveBuffScreen())),
    );
  }

  Widget _buildReincarnationButton(
      BuildContext context, GameProvider provider) {
    return ElevatedButton(
      onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ReincarnationScreen())),
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade100,
          foregroundColor: Colors.orange,
          minimumSize: const Size(double.infinity, 40)),
      child: const Text('転生の祭壇へ'),
    );
  }

  Future<void> _showQuestResultDialog(
      BuildContext context, GameProvider provider) async {
    final res = provider.questResult!;
    final drop = res.drop;
    final String imagePath = res.isSuccess
        ? 'assets/images/quest_success_bg.png'
        : 'assets/images/quest_failure_bg.png';

    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
              title: Text(res.isSuccess ? 'クエスト成功！' : '失敗...'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: Image.asset(imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image_not_supported, size: 100)),
                    ),
                    const SizedBox(height: 16),
                    Text(res.message),
                    if (drop != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome,
                                color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('装備ドロップ！',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.amber,
                                          fontWeight: FontWeight.bold)),
                                  Text(drop.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      provider.clearQuestResult();
                      Navigator.pop(context);
                    },
                    child: const Text('OK'))
              ],
            ));
  }

  Future<void> _showRankUpDialog(
      BuildContext context, GameProvider provider) async {
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
                title: const Text('ランクアップ！'),
                content: Text(
                    'ランクが ${QuestData.getGuildRankName(provider.makina.guildRank)} になりました！'),
                actions: [
                  TextButton(
                      onPressed: () {
                        provider.clearMessage();
                        Navigator.pop(context);
                      },
                      child: const Text('OK'))
                ]));
  }

  Future<void> _showAchievementUnlockedDialog(
      BuildContext context, GameProvider provider) async {
    final a = provider.newlyUnlockedAchievement!;
    await showDialog(
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
                content: const Text('全データを消去して最初からやり直しますか？'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('キャンセル')),
                  TextButton(
                      onPressed: () {
                        Provider.of<GameProvider>(context, listen: false)
                            .resetGame();
                        Navigator.pop(context);
                      },
                      child: const Text('はい',
                          style: TextStyle(color: Colors.red))),
                ]));
  }
}
