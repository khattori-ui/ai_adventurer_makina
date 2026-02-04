import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/item.dart';

// コスチュームデータ
class Costume {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final int unlockLevel;
  final bool isDefault;

  Costume({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    this.unlockLevel = 1,
    this.isDefault = false,
  });
}

class CostumeScreen extends StatelessWidget {
  const CostumeScreen({super.key});

  // 利用可能なコスチュームリスト
  static final List<Costume> allCostumes = [
    Costume(
      id: 'default',
      name: 'デフォルト衣装',
      description: '冒険者ギルドの制服。動きやすさを重視したデザイン。',
      imagePath: 'assets/images/makina.png',
      isDefault: true,
    ),
    Costume(
      id: 'school_uniform',
      name: '学校制服',
      description: '王立ドキドキ南高校の制服。懐かしい学生時代を思い出す。',
      imagePath: 'assets/images/costume_school.png',
      unlockLevel: 5,
    ),
    Costume(
      id: 'knight_armor',
      name: '騎士の鎧',
      description: '本格的な騎士の鎧。重厚感があり、防御力が高そう。',
      imagePath: 'assets/images/costume_knight.png',
      unlockLevel: 10,
    ),
    Costume(
      id: 'mage_robe',
      name: '魔法使いのローブ',
      description: '魔力を高める不思議なローブ。星の模様が美しい。',
      imagePath: 'assets/images/costume_mage.png',
      unlockLevel: 15,
    ),
    Costume(
      id: 'casual',
      name: 'カジュアル',
      description: 'オフの日の私服。リラックスした雰囲気。',
      imagePath: 'assets/images/costume_casual.png',
      unlockLevel: 20,
    ),
    Costume(
      id: 'swimsuit',
      name: '水着',
      description: '夏の海を満喫！爽やかなブルーの水着。',
      imagePath: 'assets/images/costume_swim.png',
      unlockLevel: 25,
    ),
    Costume(
      id: 'dress',
      name: 'パーティードレス',
      description: '舞踏会用の豪華なドレス。特別な日に。',
      imagePath: 'assets/images/costume_dress.png',
      unlockLevel: 30,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('更衣室'),
        backgroundColor: Colors.pink.shade400,
      ),
      body: Consumer<GameProvider>(
        builder: (context, provider, child) {
          final currentCostumeId = provider.makina.currentOutfitId ?? 'default';
          final playerLevel = provider.makina.level;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.pink.shade50,
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              children: [
                // 現在の衣装プレビュー
                _buildCurrentCostumePreview(
                  context,
                  provider,
                  currentCostumeId,
                ),
                const SizedBox(height: 16),
                // コスチュームグリッド
                Expanded(
                  child: _buildCostumeGrid(
                    context,
                    provider,
                    playerLevel,
                    currentCostumeId,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentCostumePreview(
    BuildContext context,
    GameProvider provider,
    String currentCostumeId,
  ) {
    final currentCostume = allCostumes.firstWhere(
      (c) => c.id == currentCostumeId,
      orElse: () => allCostumes[0],
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.shade200,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.checkroom, color: Colors.pink),
              SizedBox(width: 8),
              Text(
                '現在の衣装',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.pink.shade200, width: 3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                currentCostume.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  size: 80,
                  color: Colors.pink,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            currentCostume.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.pink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currentCostume.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostumeGrid(
    BuildContext context,
    GameProvider provider,
    int playerLevel,
    String currentCostumeId,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: allCostumes.length,
      itemBuilder: (context, index) {
        final costume = allCostumes[index];
        final isUnlocked = playerLevel >= costume.unlockLevel;
        final isCurrent = costume.id == currentCostumeId;

        return _buildCostumeCard(
          context,
          provider,
          costume,
          isUnlocked,
          isCurrent,
          playerLevel,
        );
      },
    );
  }

  Widget _buildCostumeCard(
    BuildContext context,
    GameProvider provider,
    Costume costume,
    bool isUnlocked,
    bool isCurrent,
    int playerLevel,
  ) {
    return Card(
      elevation: isCurrent ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrent
            ? const BorderSide(color: Colors.pink, width: 3)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isUnlocked
            ? () => _showCostumeDetail(context, provider, costume, isCurrent)
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? Colors.pink.shade50
                          : Colors.grey.shade200,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            costume.imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              size: 80,
                              color: isUnlocked
                                  ? Colors.pink.shade200
                                  : Colors.grey,
                            ),
                            color: isUnlocked ? null : Colors.grey,
                            colorBlendMode:
                                isUnlocked ? null : BlendMode.saturation,
                          ),
                          if (!isUnlocked)
                            Container(
                              color: Colors.black45,
                              child: const Center(
                                child: Icon(
                                  Icons.lock,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrent ? Colors.pink.shade100 : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        costume.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? Colors.black : Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (isUnlocked)
                        Text(
                          isCurrent ? '着用中' : 'タップで着替える',
                          style: TextStyle(
                            fontSize: 12,
                            color: isCurrent ? Colors.pink : Colors.grey,
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        )
                      else
                        Text(
                          'Lv.${costume.unlockLevel}で解放',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (isCurrent)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.pink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '着用中',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (!isUnlocked)
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.black54,
                  child: Text(
                    'あと${costume.unlockLevel - playerLevel}レベル',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCostumeDetail(
    BuildContext context,
    GameProvider provider,
    Costume costume,
    bool isCurrent,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.checkroom, color: Colors.pink),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                costume.name,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.pink.shade200, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    costume.imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.person,
                      size: 100,
                      color: Colors.pink,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                costume.description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (!costume.isDefault)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '解放レベル: ${costume.unlockLevel}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
          if (!isCurrent)
            ElevatedButton(
              onPressed: () async {
                // コスチューム変更処理
                final item = ShopItem(
                  id: costume.id,
                  name: costume.name,
                  category: ItemCategory.outfit,
                  effectDescription: '衣装を変更',
                );
                await provider.useItem(item);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${costume.name}に着替えました！'),
                      backgroundColor: Colors.pink,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
              ),
              child: const Text('着替える'),
            ),
        ],
      ),
    );
  }
}
