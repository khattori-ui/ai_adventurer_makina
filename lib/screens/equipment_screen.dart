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
            _buildEquipmentSlot(context, provider, '武器', 'weapon', makina.weapon),
            _buildEquipmentSlot(context, provider, '防具', 'armor', makina.armor),
            _buildEquipmentSlot(context, provider, '盾', 'shield', makina.shield),
            _buildEquipmentSlot(context, provider, '腕輪', 'bracelet', makina.bracelet),
            _buildEquipmentSlot(context, provider, '靴', 'boots', makina.boots),
            const SizedBox(height: 16),
            _buildTotalBonus(makina),
          ],
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
      child: ListTile(
        leading: Icon(
          _getSlotIcon(slotId),
          color: Colors.deepPurple,
        ),
        title: Text(slotName),
        subtitle: equipment != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment.name,
                    style: TextStyle(
                      color: _getRarityColor(equipment.rarity),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(_getEquipmentBonus(equipment), style: const TextStyle(fontSize: 12)),
                ],
              )
            : const Text('未装備'),
        trailing: equipment != null
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => provider.unequipItem(slotId),
                tooltip: '装備を外す',
              )
            : null,
        onTap: () => _showEquipmentSelectDialog(context, provider, slotId),
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
              ...inventory.map((equipment) => _buildInventoryItem(context, provider, equipment)),
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
      child: ListTile(
        leading: Icon(
          _getSlotIcon(equipment.slot),
          color: _getRarityColor(equipment.rarity),
        ),
        title: Text(
          equipment.name,
          style: TextStyle(
            color: _getRarityColor(equipment.rarity),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(_getEquipmentBonus(equipment)),
        trailing: ElevatedButton(
          onPressed: () => provider.equipItem(equipment),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: const Text('装備'),
        ),
      ),
    );
  }

  void _showEquipmentSelectDialog(
    BuildContext context,
    GameProvider provider,
    String slotId,
  ) {
    final availableEquipment = provider.makina.inventory
        .where((e) => e.slot == slotId)
        .toList();

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
                leading: Icon(
                  _getSlotIcon(equipment.slot),
                  color: _getRarityColor(equipment.rarity),
                ),
                title: Text(
                  equipment.name,
                  style: TextStyle(
                    color: _getRarityColor(equipment.rarity),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(_getEquipmentBonus(equipment)),
                onTap: () {
                  provider.equipItem(equipment);
                  Navigator.pop(context);
                },
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
    if (equipment.intelligenceBonus > 0) bonuses.add('賢さ+${equipment.intelligenceBonus}');
    if (equipment.defenseBonus > 0) bonuses.add('防御+${equipment.defenseBonus}');
    return bonuses.join(', ');
  }
}