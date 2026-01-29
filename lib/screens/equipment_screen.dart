import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/makina.dart';

class EquipmentScreen extends StatelessWidget {
  const EquipmentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('装備管理'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Consumer<GameProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEquippedSection(context, provider),
                  const SizedBox(height: 24),
                  _buildInventorySection(context, provider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEquippedSection(BuildContext context, GameProvider provider) {
    final makina = provider.makina;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '装備中',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildEquipmentSlot(
                context, provider, '武器', 'weapon', makina.weapon),
            _buildEquipmentSlot(context, provider, '防具', 'armor', makina.armor),
            _buildEquipmentSlot(
                context, provider, '盾', 'shield', makina.shield),
            _buildEquipmentSlot(
                context, provider, '腕輪', 'bracelet', makina.bracelet),
            _buildEquipmentSlot(context, provider, '靴', 'boots', makina.boots),
            const SizedBox(height: 16),
            _buildTotalBonus(makina),
          ],
        ),
      ),
    );
  }

  // ✨ 武器とそれ以外でサイズ感を分ける決定版
  Widget _buildEquipmentIcon(String slotId, int? rarity, {double size = 80}) {
    String imagePath = 'assets/images/$slotId.png';

    // 👈 武器は横長なのでそのまま(1.1倍)、それ以外は余白を埋めるために大きく(2.0倍)します
    double scale = (slotId == 'weapon') ? 1.1 : 2.0;

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Transform.scale(
          scale: scale, // 👈 ここで種類ごとに大きさを変えます
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                _getSlotIcon(slotId),
                color: rarity != null
                    ? _getRarityColor(rarity)
                    : Colors.deepPurple,
                size: size * 0.5,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentSlot(
    BuildContext context,
    GameProvider provider,
    String slotName,
    String slotId,
    Equipment? equipment,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey.shade100,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: _buildEquipmentIcon(slotId, equipment?.rarity, size: 80),
        title: Text(slotName, style: const TextStyle(fontSize: 18)),
        subtitle: equipment != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    equipment.name,
                    style: TextStyle(
                      color: _getRarityColor(equipment.rarity),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_getEquipmentBonus(equipment),
                      style: const TextStyle(fontSize: 14)),
                ],
              )
            : const Text('未装備', style: TextStyle(fontSize: 16)),
        trailing: equipment != null
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => provider.unequipItem(slotId),
                tooltip: '装備を外す',
                iconSize: 32,
              )
            : null,
        onTap: () => _showEquipmentSelectDialog(context, provider, slotId),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      ),
    );
  }

  Widget _buildTotalBonus(Makina makina) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '装備ボーナス合計',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('こうげき: +${makina.effectiveAttack - makina.attack}'),
          Text('まほう: +${makina.effectiveMagic - makina.magic}'),
          Text('すばやさ: +${makina.effectiveSpeed - makina.speed}'),
          Text('かしこさ: +${makina.effectiveIntelligence - makina.intelligence}'),
          Text('ぼうぎょ: +${makina.effectiveDefense - makina.defense}'),
        ],
      ),
    );
  }

  Widget _buildInventorySection(BuildContext context, GameProvider provider) {
    final inventory = provider.makina.inventory;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '所持品 (${inventory.length}個)',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (inventory.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('所持品がありません'),
                ),
              )
            else
              ...inventory.map((equipment) =>
                  _buildInventoryItem(context, provider, equipment)),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryItem(
    BuildContext context,
    GameProvider provider,
    Equipment equipment,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading:
            _buildEquipmentIcon(equipment.slot, equipment.rarity, size: 60),
        title: Text(
          equipment.name,
          style: TextStyle(
            color: _getRarityColor(equipment.rarity),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(_getEquipmentBonus(equipment),
            style: const TextStyle(fontSize: 14)),
        trailing: ElevatedButton(
          onPressed: () => provider.equipItem(equipment),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: const Text('装備'),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      ),
    );
  }

  void _showEquipmentSelectDialog(
    BuildContext context,
    GameProvider provider,
    String slotId,
  ) {
    final availableEquipment =
        provider.makina.inventory.where((e) => e.slot == slotId).toList();

    if (availableEquipment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('装備できるアイテムがありません')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('装備を選択'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableEquipment.map((equipment) {
              return ListTile(
                leading: _buildEquipmentIcon(equipment.slot, equipment.rarity,
                    size: 80),
                title: Text(
                  equipment.name,
                  style: TextStyle(
                    color: _getRarityColor(equipment.rarity),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(_getEquipmentBonus(equipment),
                    style: const TextStyle(fontSize: 14)),
                onTap: () {
                  provider.equipItem(equipment);
                  Navigator.pop(context);
                },
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  IconData _getSlotIcon(String slot) {
    switch (slot) {
      case 'weapon':
        return Icons.sports_martial_arts;
      case 'armor':
        return Icons.shield;
      case 'shield':
        return Icons.security;
      case 'bracelet':
        return Icons.circle;
      case 'boots':
        return Icons.directions_run;
      default:
        return Icons.help;
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

  String _getEquipmentBonus(Equipment equipment) {
    List<String> bonuses = [];
    if (equipment.attackBonus > 0) bonuses.add('攻撃+${equipment.attackBonus}');
    if (equipment.magicBonus > 0) bonuses.add('魔法+${equipment.magicBonus}');
    if (equipment.speedBonus > 0) bonuses.add('速さ+${equipment.speedBonus}');
    if (equipment.intelligenceBonus > 0)
      bonuses.add('賢さ+${equipment.intelligenceBonus}');
    if (equipment.defenseBonus > 0) bonuses.add('防御+${equipment.defenseBonus}');
    return bonuses.join(', ');
  }
}
