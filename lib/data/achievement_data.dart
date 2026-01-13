class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int rarity; // 1=普通, 2=レア, 3=激レア
  bool unlocked;
  DateTime? unlockedAt;
  
  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.rarity = 1,
    this.unlocked = false,
    this.unlockedAt,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unlocked': unlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }
  
  factory Achievement.fromJson(Map<String, dynamic> json, Achievement template) {
    return Achievement(
      id: template.id,
      name: template.name,
      description: template.description,
      icon: template.icon,
      rarity: template.rarity,
      unlocked: json['unlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.parse(json['unlockedAt'])
          : null,
    );
  }
}

class AchievementData {
  static List<Achievement> getAllAchievements() {
    return [
      // ★基本的な実績
      Achievement(
        id: 'first_quest',
        name: '冒険者デビュー',
        description: '初めてのクエストに成功する',
        icon: '🎉',
        rarity: 1,
      ),
      Achievement(
        id: 'quest_10',
        name: 'ベテラン冒険者',
        description: 'クエストを10回成功させる',
        icon: '⭐',
        rarity: 1,
      ),
      Achievement(
        id: 'quest_50',
        name: '熟練の冒険者',
        description: 'クエストを50回成功させる',
        icon: '🌟',
        rarity: 2,
      ),
      Achievement(
        id: 'quest_100',
        name: '伝説の冒険者',
        description: 'クエストを100回成功させる',
        icon: '💫',
        rarity: 3,
      ),
      
      // ★レベル系
      Achievement(
        id: 'level_5',
        name: '駆け出し',
        description: 'レベル5に到達する',
        icon: '📈',
        rarity: 1,
      ),
      Achievement(
        id: 'level_10',
        name: '中堅冒険者',
        description: 'レベル10に到達する',
        icon: '📊',
        rarity: 1,
      ),
      Achievement(
        id: 'level_20',
        name: '一流冒険者',
        description: 'レベル20に到達する',
        icon: '🔥',
        rarity: 2,
      ),
      Achievement(
        id: 'level_30',
        name: '英雄',
        description: 'レベル30に到達する',
        icon: '👑',
        rarity: 3,
      ),
      
      // ★装備系
      Achievement(
        id: 'first_equipment',
        name: '初めての装備',
        description: '初めて装備を入手する',
        icon: '⚔️',
        rarity: 1,
      ),
      Achievement(
        id: 'full_equipment',
        name: '完全武装',
        description: '全ての装備スロットを埋める',
        icon: '🛡️',
        rarity: 2,
      ),
      Achievement(
        id: 'legendary_equipment',
        name: '伝説の装備',
        description: 'エピック装備を入手する',
        icon: '💎',
        rarity: 3,
      ),
      
      // ★親密度系
      Achievement(
        id: 'intimacy_80',
        name: 'マキナの信頼',
        description: '親密度80に到達する',
        icon: '💕',
        rarity: 2,
      ),
      Achievement(
        id: 'intimacy_100',
        name: '最高の相棒',
        description: '親密度100に到達する',
        icon: '💖',
        rarity: 3,
      ),
      
      // ★特殊な実績
      Achievement(
        id: 'maou_clear',
        name: '世界を救いし者',
        description: '魔王を討伐する',
        icon: '🏆',
        rarity: 3,
      ),
      Achievement(
        id: 'all_quest_clear',
        name: 'クエストマスター',
        description: '全てのクエストを成功させる',
        icon: '✨',
        rarity: 3,
      ),
      
      // ★面白い実績
      Achievement(
        id: 'high_level_herb_fail',
        name: '油断大敵',
        description: 'レベル20以上で薬草採取に失敗する',
        icon: '🤦',
        rarity: 2,
      ),
      Achievement(
        id: 'impossible_success',
        name: '奇跡',
        description: '成功率5%以下のクエストに成功する',
        icon: '🎲',
        rarity: 3,
      ),
      Achievement(
        id: 'ten_fail_streak',
        name: '不運の星の下に',
        description: 'クエストに10回連続で失敗する',
        icon: '😭',
        rarity: 2,
      ),
      Achievement(
        id: 'ten_success_streak',
        name: '無双',
        description: 'クエストに10回連続で成功する',
        icon: '🔥',
        rarity: 2,
      ),
      Achievement(
        id: 'speed_runner',
        name: 'スピードランナー',
        description: '1日で10回以上クエストをクリアする',
        icon: '⚡',
        rarity: 2,
      ),
    ];
  }
  
  static Achievement? getAchievementById(String id) {
    try {
      return getAllAchievements().firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }
}