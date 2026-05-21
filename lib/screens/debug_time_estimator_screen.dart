import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/makina.dart';
import '../data/quest_data.dart';

class DebugTimeEstimatorScreen extends StatelessWidget {
  const DebugTimeEstimatorScreen({super.key});

  // 分を「○時間○分」または「○分」の文字列に変換（整数版）
  static String _formatInt(int minutes) => _formatDuration(minutes.toDouble());

  // 時間を「○日○時間○分」の文字列に変換
  static String _formatDuration(double minutes) {
    if (minutes >= 1440) {
      final days = (minutes / 1440).floor();
      final hours = ((minutes % 1440) / 60).floor();
      final mins = (minutes % 60).floor();
      if (hours == 0 && mins == 0) return '$days日';
      if (mins == 0) return '$days日$hours時間';
      return '$days日$hours時間$mins分';
    } else if (minutes >= 60) {
      final hours = (minutes / 60).floor();
      final mins = (minutes % 60).floor();
      return mins == 0 ? '$hours時間' : '$hours時間$mins分';
    } else {
      return '${minutes.floor()}分';
    }
  }

  // ランクアップグラインドの推定時間（分）を計算
  static double _calcRankUpGrindMinutes(Makina makina) {
    double total = 0;
    final allQuests = QuestData.getAllQuests();

    for (int rank = makina.guildRank; rank < 6; rank++) {
      final required = QuestData.getQuestsRequiredForRankUp(rank);
      final rankQuests = allQuests
          .where((q) => q.requiredGuildRank == rank)
          .toList()
        ..sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
      if (rankQuests.isEmpty) continue;

      int alreadySucceeded = 0;
      if (rank == makina.guildRank) {
        alreadySucceeded = makina.questSuccessCountForCurrentRank;
      }
      final remaining = (required - alreadySucceeded).clamp(0, required);

      // ユニーク分 + 繰り返し分（最短クエストで補う）
      int uniqueCount = rankQuests.length;
      final uniqueMin = rankQuests.take(uniqueCount).fold(0, (s, q) => s + q.durationMinutes);
      final repeatCount = (remaining - uniqueCount).clamp(0, remaining);
      final repeatMin = repeatCount * rankQuests.first.durationMinutes;

      // 成功率で補正（ランクがちょうどのクエストを平均65%想定）
      const avgSuccessRate = 0.65;
      final adjustedMin = (uniqueMin + repeatMin) / avgSuccessRate;
      total += adjustedMin;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final makina = context.read<GameProvider>().makina;
    final allQuests = QuestData.getAllQuests();
    final rankNames = {0: 'F', 1: 'E', 2: 'D', 3: 'C', 4: 'B', 5: 'A', 6: 'S'};

    // 各クエストの推定情報を計算
    final questEstimates = allQuests.map((q) {
      final isCleared = makina.clearedQuestIds.contains(q.id);
      final rate = q.calculateSuccessRate(makina, isCleared).clamp(0.05, 0.99);
      final expectedAttempts = 1.0 / rate;
      final expectedMinutes = q.durationMinutes * expectedAttempts;
      final canAccess = makina.guildRank >= q.requiredGuildRank;
      return _QuestEstimate(
        quest: q,
        successRate: rate,
        expectedAttempts: expectedAttempts,
        expectedMinutes: expectedMinutes,
        isCleared: isCleared,
        canAccess: canAccess,
      );
    }).toList();

    // 集計
    final accessibleEstimates = questEstimates.where((e) => e.canAccess).toList();
    final totalUniqueMinutes = accessibleEstimates.fold(0.0, (s, e) => s + e.expectedMinutes);
    final grindMinutes = _calcRankUpGrindMinutes(makina);
    final grandTotal = totalUniqueMinutes + grindMinutes;

    // 最終クエスト（quest_040）
    final finalQuestEst = questEstimates.last;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('⏱ プレイ時間シミュレーター'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ── 実績累計プレイ時間 ────────────────────────────
          _SectionCard(
            title: '⏱ 実績累計プレイ時間',
            color: Colors.teal.shade50,
            child: _buildActualPlayTime(makina),
          ),

          // ── 現在のステータス ──────────────────────────────
          _SectionCard(
            title: '現在のマキナ',
            color: Colors.deepPurple.shade50,
            child: _buildCurrentStats(makina, rankNames),
          ),

          // ── サマリー（推定） ──────────────────────────────
          _SectionCard(
            title: '📊 クリア時間サマリー（推定）',
            color: Colors.orange.shade50,
            child: _buildSummary(
              accessibleEstimates: accessibleEstimates,
              totalUniqueMinutes: totalUniqueMinutes,
              grindMinutes: grindMinutes,
              grandTotal: grandTotal,
              finalQuestEst: finalQuestEst,
              makina: makina,
            ),
          ),

          // ── ランク別内訳 ──────────────────────────────────
          _SectionCard(
            title: '🏆 ランクアップグラインド内訳',
            color: Colors.blue.shade50,
            child: _buildRankBreakdown(makina, rankNames),
          ),

          // ── クエスト別詳細 ────────────────────────────────
          _SectionCard(
            title: '📋 クエスト別詳細（現在アクセス可能）',
            color: Colors.green.shade50,
            child: _buildQuestTable(accessibleEstimates, rankNames),
          ),

          // アクセス不可クエストも折りたたみで表示
          _LockedQuestsSection(
            locked: questEstimates.where((e) => !e.canAccess).toList(),
            rankNames: rankNames,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActualPlayTime(Makina m) {
    final totalMinutes = m.totalQuestPlaySeconds / 60.0;
    final total = totalMinutes.floor();
    final allQuests = QuestData.getAllQuests();
    final totalPossibleMinutes =
        allQuests.fold(0, (s, q) => s + q.durationMinutes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Text(
                _formatInt(total),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              Text(
                'クエストに費やした累計時間',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: totalPossibleMinutes > 0
                ? (total / totalPossibleMinutes).clamp(0.0, 1.0)
                : 0.0,
            minHeight: 8,
            backgroundColor: Colors.teal.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade400),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '全クエスト1周分の合計時間: ${_formatInt(totalPossibleMinutes)}',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        _summaryRow('クリア済みクエスト数',
            '${m.clearedQuestIds.length} / ${allQuests.length}本'),
        _summaryRow('合計クエスト挑戦回数',
            '${m.totalQuestSuccessCount + m.consecutiveFailCount}回以上'),
      ],
    );
  }

  Widget _buildCurrentStats(Makina m, Map<int, String> rankNames) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _statChip('Lv.${m.level}', Colors.deepPurple),
          const SizedBox(width: 8),
          _statChip('Rank ${rankNames[m.guildRank]}', Colors.indigo),
          const SizedBox(width: 8),
          if (m.reincarnationCount > 0)
            _statChip('転生${m.reincarnationCount}回', Colors.amber.shade700),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 4, children: [
          _statChip('攻撃 ${m.effectiveAttack}', Colors.red.shade400),
          _statChip('魔法 ${m.effectiveMagic}', Colors.blue.shade400),
          _statChip('速さ ${m.effectiveSpeed}', Colors.green.shade400),
          _statChip('賢さ ${m.effectiveIntelligence}', Colors.purple.shade400),
          _statChip('防御 ${m.effectiveDefense}', Colors.orange.shade400),
        ]),
      ],
    );
  }

  Widget _buildSummary({
    required List<_QuestEstimate> accessibleEstimates,
    required double totalUniqueMinutes,
    required double grindMinutes,
    required double grandTotal,
    required _QuestEstimate finalQuestEst,
    required Makina makina,
  }) {
    final clearedCount = makina.clearedQuestIds.length;
    final totalCount = QuestData.getAllQuests().length;

    return Column(
      children: [
        _summaryRow('アクセス可能クエスト数',
            '${accessibleEstimates.length} / $totalCount本'),
        _summaryRow('クリア済みクエスト数', '$clearedCount本'),
        const Divider(),
        _summaryRow(
          'ユニーククリア推定時間',
          _formatDuration(totalUniqueMinutes),
          sub: '（各クエスト1回、成功率で補正）',
        ),
        _summaryRow(
          'ランクアップグラインド推定',
          _formatDuration(grindMinutes),
          sub: '（成功率65%想定）',
        ),
        const Divider(),
        _summaryRow(
          '合計推定プレイ時間',
          _formatDuration(grandTotal),
          highlight: true,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.deepPurple.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🎯 最終クエスト「${finalQuestEst.quest.name}」',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                '成功率: ${(finalQuestEst.successRate * 100).toStringAsFixed(1)}%'
                ' → 期待${finalQuestEst.expectedAttempts.toStringAsFixed(1)}回'
                ' × ${_formatDuration(finalQuestEst.quest.durationMinutes.toDouble())}'
                ' ≈ ${_formatDuration(finalQuestEst.expectedMinutes)}',
                style: TextStyle(fontSize: 12, color: Colors.deepPurple.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankBreakdown(Makina makina, Map<int, String> rankNames) {
    final allQuests = QuestData.getAllQuests();
    final rows = <Widget>[];

    for (int rank = 0; rank < 6; rank++) {
      final required = QuestData.getQuestsRequiredForRankUp(rank);
      final rankQuests = allQuests
          .where((q) => q.requiredGuildRank == rank)
          .toList()
        ..sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
      if (rankQuests.isEmpty) continue;

      int alreadySucceeded =
          rank == makina.guildRank ? makina.questSuccessCountForCurrentRank : 0;
      final remaining = (required - alreadySucceeded).clamp(0, required);
      final uniqueCount = rankQuests.length;
      final repeatCount = (remaining - uniqueCount).clamp(0, remaining);
      final rawMin = rankQuests.fold(0, (s, q) => s + q.durationMinutes) +
          repeatCount * rankQuests.first.durationMinutes;
      final adjustedMin = rawMin / 0.65;

      final isDone = makina.guildRank > rank;
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(
            width: 60,
            child: Text(
              'Rank ${rankNames[rank]}→${rankNames[rank + 1]}',
              style: TextStyle(
                fontSize: 11,
                color: isDone ? Colors.grey : Colors.black87,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isDone
                  ? '完了'
                  : '必要$required回（残$remaining回）× '
                      '${_formatDuration(rankQuests.first.durationMinutes.toDouble())}最短'
                      ' ≈ ${_formatDuration(adjustedMin)}',
              style: TextStyle(
                fontSize: 11,
                color: isDone ? Colors.grey : Colors.black87,
              ),
            ),
          ),
        ]),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _buildQuestTable(
      List<_QuestEstimate> estimates, Map<int, String> rankNames) {
    return Column(
      children: estimates.map((e) {
        final rateColor = e.successRate >= 0.7
            ? Colors.green.shade700
            : e.successRate >= 0.4
                ? Colors.orange.shade700
                : Colors.red.shade700;
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: e.isCleared
                ? Colors.grey.shade100
                : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(children: [
            // クリア済みチェック
            Icon(
              e.isCleared ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 14,
              color: e.isCleared ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 6),
            // クエスト名
            Expanded(
              flex: 3,
              child: Text(
                e.quest.name,
                style: TextStyle(
                  fontSize: 11,
                  color: e.isCleared ? Colors.grey : Colors.black87,
                  decoration: e.isCleared ? TextDecoration.lineThrough : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 実時間
            SizedBox(
              width: 50,
              child: Text(
                _formatDuration(e.quest.durationMinutes.toDouble()),
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 4),
            // 成功率
            SizedBox(
              width: 38,
              child: Text(
                '${(e.successRate * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 11,
                    color: rateColor,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 4),
            // 期待時間
            SizedBox(
              width: 56,
              child: Text(
                '≈${_formatDuration(e.expectedMinutes)}',
                style: TextStyle(fontSize: 10, color: Colors.deepPurple.shade600),
                textAlign: TextAlign.right,
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }

  Widget _statChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _summaryRow(String label, String value,
      {String? sub, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        highlight ? FontWeight.bold : FontWeight.normal)),
            if (sub != null)
              Text(sub,
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade600)),
          ]),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 16 : 13,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.deepPurple : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ── ロック中クエスト折りたたみセクション ────────────────────────────────────
class _LockedQuestsSection extends StatefulWidget {
  final List<_QuestEstimate> locked;
  final Map<int, String> rankNames;
  const _LockedQuestsSection(
      {required this.locked, required this.rankNames});

  @override
  State<_LockedQuestsSection> createState() => _LockedQuestsSectionState();
}

class _LockedQuestsSectionState extends State<_LockedQuestsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.locked.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading:
                const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
            title: Text('未解放クエスト（${widget.locked.length}本）',
                style: const TextStyle(fontSize: 13)),
            trailing: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: widget.locked.map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      const Icon(Icons.lock, size: 12, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(e.quest.name,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey))),
                      Text(
                        '必要Rank ${widget.rankNames[e.quest.requiredGuildRank]}  '
                        '${DebugTimeEstimatorScreen._formatDuration(e.quest.durationMinutes.toDouble())}',
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ]),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ── セクションカード ──────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Color color;
  final Widget child;
  const _SectionCard(
      {required this.title, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

// ── データクラス ──────────────────────────────────────────────────────────────
class _QuestEstimate {
  final Quest quest;
  final double successRate;
  final double expectedAttempts;
  final double expectedMinutes;
  final bool isCleared;
  final bool canAccess;
  const _QuestEstimate({
    required this.quest,
    required this.successRate,
    required this.expectedAttempts,
    required this.expectedMinutes,
    required this.isCleared,
    required this.canAccess,
  });
}
