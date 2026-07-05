import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../shared/models/makina.dart';

class ReincarnationScreen extends StatelessWidget {
  const ReincarnationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('転生の祭壇'),
        backgroundColor: Colors.amber.shade700,
      ),
      body: Consumer<GameProvider>(
        builder: (context, provider, child) {
          final makina = provider.makina;
          final canReincarnate = makina.level >= 30;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.amber.shade100,
                  Colors.orange.shade50,
                ],
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAltarImage(),
                    const SizedBox(height: 24),
                    _buildCurrentStatusCard(makina),
                    const SizedBox(height: 24),
                    _buildReincarnationBenefitsCard(),
                    const SizedBox(height: 24),
                    if (makina.reincarnationCount > 0) ...[
                      _buildReincarnationHistory(makina),
                      const SizedBox(height: 24),
                    ],
                    _buildReincarnationButton(
                        context, provider, canReincarnate),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAltarImage() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: RadialGradient(
          colors: [
            Colors.amber.shade300,
            Colors.orange.shade400,
            Colors.deepOrange.shade600,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 80, color: Colors.white),
            SizedBox(height: 8),
            Text(
              '転生の祭壇',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard(Makina makina) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('現在の状態',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            _buildStatusRow('現在のレベル', 'Lv.${makina.level}',
                makina.level >= 30 ? Colors.green : Colors.grey),
            const SizedBox(height: 8),
            _buildStatusRow(
                '転生回数', '${makina.reincarnationCount}回', Colors.amber),
            const SizedBox(height: 8),
            _buildStatusRow('現在の攻撃力', '${makina.effectiveAttack}', Colors.red),
            const SizedBox(height: 8),
            _buildStatusRow('現在の魔法力', '${makina.effectiveMagic}', Colors.blue),
            const SizedBox(height: 8),
            _buildStatusRow(
                '現在の防御力', '${makina.effectiveDefense}', Colors.orange),
            const SizedBox(height: 16),
            if (makina.level < 30)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '転生にはレベル30が必要です\n(あと${30 - makina.level}レベル)',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildReincarnationBenefitsCard() {
    return Card(
      elevation: 4,
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                const Text('転生の特典',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            _buildBenefitItem(Icons.trending_up, 'ステータス成長率アップ',
                'レベルアップ時の成長率が永久に上昇', Colors.green),
            const SizedBox(height: 12),
            _buildBenefitItem(Icons.published_with_changes, 'クリア済みクエスト補正',
                '一度クリアしたクエストの成功率が最大10%上昇', Colors.blue),
            const SizedBox(height: 12),
            _buildBenefitItem(Icons.inventory_2, '装備品のリセット（再入手可能）', '一度ドロップした装備も再び入手できるようになる',
                Colors.purple),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '注意：レベルは1に戻り、親密度とギルドランクはリセットされます',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(
      IconData icon, String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReincarnationHistory(Makina makina) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text('転生の記録',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHistoryStat('転生回数', '${makina.reincarnationCount}',
                      Icons.refresh, Colors.amber),
                  _buildHistoryStat(
                      '成長ボーナス',
                      '+${makina.reincarnationCount * 2}',
                      Icons.arrow_upward,
                      Colors.green),
                  _buildHistoryStat(
                      '成功率補正',
                      '+${(makina.reincarnationCount * 5).clamp(0, 10)}%',
                      Icons.trending_up,
                      Colors.blue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryStat(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildReincarnationButton(
      BuildContext context, GameProvider provider, bool canReincarnate) {
    return ElevatedButton(
      onPressed: canReincarnate
          ? () => _showReincarnationConfirmDialog(context, provider)
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canReincarnate ? Colors.amber : Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: canReincarnate ? 8 : 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(canReincarnate ? Icons.auto_awesome : Icons.lock, size: 32),
          const SizedBox(width: 12),
          Text(canReincarnate ? '転生する' : 'レベル30で転生可能',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showReincarnationConfirmDialog(
      BuildContext context, GameProvider provider) {
    final currentCount = provider.makina.reincarnationCount;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber),
            SizedBox(width: 8),
            Text('転生の確認'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('本当に転生しますか?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('【獲得できるもの】'),
              const SizedBox(height: 8),
              _buildDialogBenefit('✨ ステータス成長率の永久アップ'),
              _buildDialogBenefit('✨ クリア済みクエストの成功率補正'),
              _buildDialogBenefit('🔄 装備品のリセット（再入手可能になる）'),
              const SizedBox(height: 16),
              const Text('【失うもの】'),
              const SizedBox(height: 8),
              _buildDialogLoss('❌ レベル（1に戻る）'),
              _buildDialogLoss('❌ 経験値'),
              _buildDialogLoss('❌ 親密度（50に戻る）'),
              _buildDialogLoss('❌ ギルドランク（Fに戻る）'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '転生回数: $currentCount回 → ${currentCount + 1}回',
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
            onPressed: () async {
              await provider.reincarnate();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('転生しました！新たな冒険の始まりです！'),
                    backgroundColor: Colors.amber,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
            child: const Text('転生する！'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(color: Colors.green)),
    );
  }

  Widget _buildDialogLoss(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(color: Colors.red)),
    );
  }
}
