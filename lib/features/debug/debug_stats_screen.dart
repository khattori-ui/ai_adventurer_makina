import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';

class DebugStatsScreen extends StatefulWidget {
  const DebugStatsScreen({super.key});

  @override
  State<DebugStatsScreen> createState() => _DebugStatsScreenState();
}

class _DebugStatsScreenState extends State<DebugStatsScreen> {
  static const List<String> _rankNames = ['F', 'E', 'D', 'C', 'B', 'A', 'S'];

  late int _level;
  late int _guildRank;
  late int _attack;
  late int _magic;
  late int _speed;
  late int _intelligence;
  late int _defense;

  @override
  void initState() {
    super.initState();
    final m = context.read<GameProvider>().makina;
    _level = m.level;
    _guildRank = m.guildRank.clamp(0, 6);
    _attack = m.attack;
    _magic = m.magic;
    _speed = m.speed;
    _intelligence = m.intelligence;
    _defense = m.defense;
  }

  Widget _buildSlider({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
    Color color = Colors.purpleAccent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Text('$value',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            thumbColor: color,
            inactiveTrackColor: color.withValues(alpha: 0.2),
            overlayColor: color.withValues(alpha: 0.1),
            trackHeight: 3,
          ),
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }

  Future<void> _applyStats(BuildContext context) async {
    await context.read<GameProvider>().debugSetStats(
          level: _level,
          attack: _attack,
          magic: _magic,
          speed: _speed,
          intelligence: _intelligence,
          defense: _defense,
          guildRank: _guildRank,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ステータスを更新しました'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _resetDaily(BuildContext context) async {
    await context.read<GameProvider>().debugResetDailyCounters();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('日次カウンターをリセットしました'),
          backgroundColor: Colors.blueAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final m = provider.makina;
        return Scaffold(
          backgroundColor: const Color(0xFF1A0A2E),
          appBar: AppBar(
            title: const Text('デバッグ：ステータス変更'),
            backgroundColor: Colors.deepPurple,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── ステータス変更セクション ──
              _sectionHeader('ステータス直接変更', Icons.tune, Colors.purpleAccent),
              const SizedBox(height: 12),
              _card([
                // レベル
                _buildSlider(
                  label: 'レベル',
                  value: _level,
                  min: 1,
                  max: 30,
                  color: Colors.amberAccent,
                  onChanged: (v) => setState(() => _level = v),
                ),
                const Divider(color: Colors.white12),
                // ギルドランク
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ギルドランク',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: List.generate(
                        7,
                        (i) => ButtonSegment(
                          value: i,
                          label: Text('Rank ${_rankNames[i]}',
                              style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                      selected: {_guildRank},
                      onSelectionChanged: (s) =>
                          setState(() => _guildRank = s.first),
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith((s) {
                          if (s.contains(WidgetState.selected)) {
                            return Colors.deepPurple;
                          }
                          return Colors.transparent;
                        }),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12),
                // 各ステータス
                _buildSlider(
                  label: '攻撃力',
                  value: _attack,
                  min: 10,
                  max: 1000,
                  color: Colors.redAccent,
                  onChanged: (v) => setState(() => _attack = v),
                ),
                _buildSlider(
                  label: '魔法力',
                  value: _magic,
                  min: 10,
                  max: 1000,
                  color: Colors.purpleAccent,
                  onChanged: (v) => setState(() => _magic = v),
                ),
                _buildSlider(
                  label: '素早さ',
                  value: _speed,
                  min: 10,
                  max: 1000,
                  color: Colors.cyanAccent,
                  onChanged: (v) => setState(() => _speed = v),
                ),
                _buildSlider(
                  label: '賢さ',
                  value: _intelligence,
                  min: 10,
                  max: 1000,
                  color: Colors.greenAccent,
                  onChanged: (v) => setState(() => _intelligence = v),
                ),
                _buildSlider(
                  label: '防御力',
                  value: _defense,
                  min: 10,
                  max: 1000,
                  color: Colors.orangeAccent,
                  onChanged: (v) => setState(() => _defense = v),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('適用する'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _applyStats(context),
                  ),
                ),
              ]),

              const SizedBox(height: 24),

              // ── 日次カウンターリセットセクション ──
              _sectionHeader(
                  '日次カウンターリセット', Icons.restart_alt, Colors.blueAccent),
              const SizedBox(height: 12),
              _card([
                _counterRow(
                  Icons.chat_bubble_outline,
                  '本日の会話回数',
                  '${m.dailyConversationCount} / 50',
                  Colors.greenAccent,
                ),
                const SizedBox(height: 8),
                _counterRow(
                  Icons.assignment_turned_in_outlined,
                  '本日のクエストクリア数',
                  '${m.dailyQuestClearCount} 回',
                  Colors.orangeAccent,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, color: Colors.blueAccent),
                    label: const Text('日次カウンターをリセット',
                        style: TextStyle(color: Colors.blueAccent)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blueAccent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _resetDaily(context),
                  ),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _counterRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13))),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
