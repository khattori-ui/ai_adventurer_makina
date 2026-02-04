import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/item.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ショップに並べる有償アイテムのリスト
    final List<ShopItem> paidItems = [
      ShopItem(
          id: 'remove_ads',
          name: '広告除去パック',
          category: ItemCategory.growth,
          priceLabel: '¥1,200',
          effectDescription: 'すべての広告を非表示にします。'),
      ShopItem(
          id: 'starter_pack',
          name: '初心者応援セット',
          category: ItemCategory.statBoost,
          priceLabel: '¥480',
          statMultiplier: 1.5,
          duration: const Duration(days: 7),
          effectDescription: '7日間、マキナの全ステータスが1.5倍になります。'),
      ShopItem(
          id: 'memory_crystal',
          name: '記憶の結晶',
          category: ItemCategory.growth,
          priceLabel: '¥240',
          effectDescription: 'マキナがより昔のことを覚えられるようになります。'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ギルドショップ'),
        backgroundColor: Colors.amber.shade700,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: paidItems.length,
        itemBuilder: (context, index) {
          final item = paidItems[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(item.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(item.effectDescription),
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white),
                onPressed: () => _showPurchaseDialog(context, item),
                child: Text(item.priceLabel),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPurchaseDialog(BuildContext context, ShopItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('購入の確認'),
        content:
            Text('${item.name} (${item.priceLabel}) を購入しますか？\n※現在はテストモードです。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              // 本来はここでApple/Googleの決済画面を呼び出します
              Provider.of<GameProvider>(context, listen: false).useItem(item);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.name}を購入しました！')));
            },
            child: const Text('購入する'),
          ),
        ],
      ),
    );
  }
}
