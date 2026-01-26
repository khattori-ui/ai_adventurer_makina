import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/item.dart';

class DebugItemScreen extends StatelessWidget {
  const DebugItemScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<ShopItem> testItems = [
      ShopItem(
          id: 'bouquet',
          name: '情熱のブーケ',
          category: ItemCategory.personality,
          dependentChange: 30,
          effectDescription: '依存度+30'),
      ShopItem(
          id: 'apple',
          name: 'ドクロの毒リンゴ',
          category: ItemCategory.personality,
          dependentChange: -30,
          effectDescription: '依存度-30'),
      ShopItem(
          id: 'talisman',
          name: '師匠の特製お守り',
          category: ItemCategory.personality,
          braveChange: 30,
          effectDescription: '勇敢さ+30'),
      ShopItem(
          id: 'dictionary',
          name: '賢者の辞典',
          category: ItemCategory.personality,
          braveChange: -30,
          effectDescription: '勇敢さ-30'),
      ShopItem(
          id: 'potion_1.5',
          name: '勇者の秘薬',
          category: ItemCategory.statBoost,
          statMultiplier: 1.5,
          duration: const Duration(days: 3),
          effectDescription: '3日間全ステータス1.5倍'),
      ShopItem(
          id: 'potion_2.0',
          name: '覇者の霊薬',
          category: ItemCategory.statBoost,
          statMultiplier: 2.0,
          duration: const Duration(days: 1),
          effectDescription: '1日間全ステータス2.0倍'),
      ShopItem(
          id: 'hourglass',
          name: '時空の砂時計',
          category: ItemCategory.growth,
          timeReductionRate: 0.5,
          duration: const Duration(days: 7),
          effectDescription: '7日間クエスト時間50%短縮'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('デバッグ：無限アイテム'),
        backgroundColor: Colors.redAccent,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: testItems.length,
        itemBuilder: (context, index) {
          final item = testItems[index];
          return Card(
            child: ListTile(
              title: Text(item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(item.effectDescription),
              trailing: ElevatedButton(
                onPressed: () {
                  context.read<GameProvider>().useItem(item);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${item.name}を適用しました！'),
                        duration: const Duration(seconds: 1)),
                  );
                },
                child: const Text('試す'),
              ),
            ),
          );
        },
      ),
    );
  }
}
