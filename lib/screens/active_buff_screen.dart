import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/game_provider.dart';
import '../models/item.dart';

class ActiveBuffScreen extends StatelessWidget {
  const ActiveBuffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アクティブバフ'),
        backgroundColor: Colors.purple,
      ),
      body: Consumer<GameProvider>(
        builder: (context, provider, child) {
          final activeBuffs = provider.makina.activeBuffs;
          final validBuffs = activeBuffs.where((b) => !b.isExpired).toList();
          final expiredBuffs = activeBuffs.where((b) => b.isExpired).toList();

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.purple.shade50,
                  Colors.white,
                ],
              ),
            ),
            child: validBuffs.isEmpty && expiredBuffs.isEmpty
                ? _buildEmptyState()
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (validBuffs.isNotEmpty) ...[
                            _buildSectionHeader('有効なバフ', validBuffs.length),
                            const SizedBox(height: 12),
                            ...validBuffs
                                .map((buff) => _buildBuffCard(buff, true)),
                          ],
                          if (expiredBuffs.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildSectionHeader('期限切れ', expiredBuffs.length),
                            const SizedBox(height: 12),
                            ...expiredBuffs
                                .map((buff) => _buildBuffCard(buff, false)),
                          ],
                          const SizedBox(height: 16),
                          _buildInfoCard(),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, size: 100, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            '現在有効なバフはありません',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'アイテムを使用してバフを獲得しよう！',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.purple.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuffCard(ActiveBuff buff, bool isActive) {
    final now = DateTime.now();
    final remaining = buff.expiry.difference(now);
    final totalDuration = buff.expiry.difference(
      buff.expiry.subtract(Duration(days: 7)), // 仮の開始時間
    );
    final progress = isActive
        ? (remaining.inSeconds / totalDuration.inSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isActive ? 4 : 1,
      color: isActive ? Colors.white : Colors.grey.shade200,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.purple.shade100
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getBuffIcon(buff),
                    color: isActive ? Colors.purple : Colors.grey,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        buff.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.black : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isActive)
                        Text(
                          _formatRemainingTime(remaining),
                          style: TextStyle(
                            fontSize: 14,
                            color: remaining.inHours < 1
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        const Text(
                          '期限切れ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isActive)
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 28,
                  )
                else
                  Icon(
                    Icons.cancel,
                    color: Colors.grey,
                    size: 28,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (isActive)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation(
                      remaining.inHours < 1 ? Colors.red : Colors.purple,
                    ),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            _buildEffectDetails(buff, isActive),
            const Divider(height: 24),
            _buildExpiryInfo(buff, isActive),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectDetails(ActiveBuff buff, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? Colors.purple.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '効果',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (buff.statMultiplier > 1.0)
            _buildEffectRow(
              Icons.trending_up,
              'ステータス倍率',
              '×${buff.statMultiplier.toStringAsFixed(1)}',
              Colors.green,
              isActive,
            ),
          if (buff.timeReductionRate > 0)
            _buildEffectRow(
              Icons.speed,
              'クエスト時間短縮',
              '${(buff.timeReductionRate * 100).toInt()}%',
              Colors.blue,
              isActive,
            ),
        ],
      ),
    );
  }

  Widget _buildEffectRow(
    IconData icon,
    String label,
    String value,
    Color color,
    bool isActive,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isActive ? color : Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isActive ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isActive ? color : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryInfo(ActiveBuff buff, bool isActive) {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 16,
          color: isActive ? Colors.grey.shade600 : Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          '期限: ${DateFormat('yyyy/MM/dd HH:mm').format(buff.expiry)}',
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.grey.shade600 : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'バフについて',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem('バフは時間経過で自動的に期限切れになります'),
            _buildInfoItem('複数のバフが有効な場合、最も効果の高いものが適用されます'),
            _buildInfoItem('デバッグ画面からアイテムを使用してバフを獲得できます'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getBuffIcon(ActiveBuff buff) {
    if (buff.statMultiplier > 1.0) {
      return Icons.flash_on;
    } else if (buff.timeReductionRate > 0) {
      return Icons.speed;
    }
    return Icons.star;
  }

  String _formatRemainingTime(Duration duration) {
    if (duration.inDays > 0) {
      return '残り ${duration.inDays}日 ${duration.inHours % 24}時間';
    } else if (duration.inHours > 0) {
      return '残り ${duration.inHours}時間 ${duration.inMinutes % 60}分';
    } else if (duration.inMinutes > 0) {
      return '残り ${duration.inMinutes}分';
    } else {
      return '残り ${duration.inSeconds}秒';
    }
  }
}
