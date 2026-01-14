import '../models/makina.dart';

class QuestData {
  static List<Quest> getAllQuests() {
    return [
      // Fランク (0)
      Quest(
        id: 'quest_001',
        name: '薬草採取',
        description: '森で薬草を集めてくる簡単な仕事です',
        durationMinutes: 5,
        difficulty: 1,
        requiredGuildRank: 0, // Fランク
        targetAttack: 5,
        targetMagic: 0,
        targetSpeed: 8,
        targetIntelligence: 5,
        targetDefense: 5,
        experienceReward: 75,
        failureExperience: 15,
        dropRate: 0.1,
        possibleDrops: const ['iron_sword', 'leather_armor'],
      ),
      Quest(
        id: 'quest_002',
        name: 'きのこ狩り',
        description: '森で食用きのこを採集する',
        durationMinutes: 5,
        difficulty: 1,
        requiredGuildRank: 0, // Fランク
        targetAttack: 0,
        targetMagic: 0,
        targetSpeed: 10,
        targetIntelligence: 8,
        targetDefense: 3,
        experienceReward: 75,
        failureExperience: 15,
        dropRate: 0.1,
        possibleDrops: const ['leather_boots', 'magic_bracelet'],
      ),
      Quest(
        id: 'quest_003',
        name: '荷物運び',
        description: '商人の荷物を隣町まで運ぶ',
        durationMinutes: 8,
        difficulty: 1,
        requiredGuildRank: 0, // Fランク
        targetAttack: 3,
        targetMagic: 0,
        targetSpeed: 5,
        targetIntelligence: 5,
        targetDefense: 10,
        experienceReward: 100,
        failureExperience: 20,
        dropRate: 0.12,
        possibleDrops: const ['iron_sword', 'leather_armor', 'leather_boots'],
      ),
      
      // Eランク (1)
      Quest(
        id: 'quest_004',
        name: 'スライム退治',
        description: '畑を荒らすスライムを倒してほしい',
        durationMinutes: 10,
        difficulty: 2,
        requiredGuildRank: 1, // Eランク
        targetAttack: 12,
        targetMagic: 8,
        targetSpeed: 10,
        targetIntelligence: 8,
        targetDefense: 10,
        experienceReward: 150,
        failureExperience: 30,
        dropRate: 0.15,
        possibleDrops: const ['steel_sword', 'magic_staff', 'leather_boots'],
      ),
      Quest(
        id: 'quest_005',
        name: '迷子の子供探し',
        description: '森で迷子になった子供を探す',
        durationMinutes: 15,
        difficulty: 2,
        requiredGuildRank: 1, // Eランク
        targetAttack: 8,
        targetMagic: 5,
        targetSpeed: 15,
        targetIntelligence: 15,
        targetDefense: 8,
        experienceReward: 225,
        failureExperience: 45,
        dropRate: 0.2,
        possibleDrops: const ['magic_bracelet', 'speed_boots'],
      ),
      Quest(
        id: 'quest_006',
        name: 'オオカミの群れ退治',
        description: '村を襲うオオカミの群れを撃退する',
        durationMinutes: 15,
        difficulty: 2,
        requiredGuildRank: 1, // Eランク
        targetAttack: 15,
        targetMagic: 0,
        targetSpeed: 12,
        targetIntelligence: 8,
        targetDefense: 12,
        experienceReward: 225,
        failureExperience: 45,
        dropRate: 0.18,
        possibleDrops: const ['steel_sword', 'chain_armor'],
      ),
      
      // Dランク (2)
      Quest(
        id: 'quest_007',
        name: '盗賊団の追跡',
        description: '商隊を襲った盗賊団を追跡する',
        durationMinutes: 20,
        difficulty: 3,
        requiredGuildRank: 2, // Dランク
        targetAttack: 18,
        targetMagic: 10,
        targetSpeed: 18,
        targetIntelligence: 12,
        targetDefense: 15,
        experienceReward: 300,
        failureExperience: 60,
        dropRate: 0.22,
        possibleDrops: const ['steel_sword', 'chain_armor', 'speed_boots'],
      ),
      Quest(
        id: 'quest_008',
        name: '地下水路の調査',
        description: '異変が報告された地下水路を調査する',
        durationMinutes: 20,
        difficulty: 3,
        requiredGuildRank: 2, // Dランク
        targetAttack: 15,
        targetMagic: 15,
        targetSpeed: 10,
        targetIntelligence: 18,
        targetDefense: 12,
        experienceReward: 300,
        failureExperience: 60,
        dropRate: 0.2,
        possibleDrops: const ['magic_staff', 'wisdom_bracelet'],
      ),
      Quest(
        id: 'quest_009',
        name: 'ゴブリンの巣退治',
        description: '近隣を脅かすゴブリンの巣を壊滅させる',
        durationMinutes: 30,
        difficulty: 3,
        requiredGuildRank: 2, // Dランク
        targetAttack: 20,
        targetMagic: 15,
        targetSpeed: 18,
        targetIntelligence: 15,
        targetDefense: 18,
        experienceReward: 450,
        failureExperience: 90,
        dropRate: 0.25,
        possibleDrops: const ['mithril_sword', 'iron_shield', 'chain_armor'],
      ),
      
      // Cランク (3)
      Quest(
        id: 'quest_010',
        name: '呪われた館の調査',
        description: '幽霊が出ると噂の館を調査する',
        durationMinutes: 30,
        difficulty: 4,
        requiredGuildRank: 3, // Cランク
        targetAttack: 12,
        targetMagic: 25,
        targetSpeed: 15,
        targetIntelligence: 22,
        targetDefense: 15,
        experienceReward: 450,
        failureExperience: 90,
        dropRate: 0.25,
        possibleDrops: const ['magic_staff', 'ancient_staff', 'wisdom_bracelet'],
      ),
      Quest(
        id: 'quest_011',
        name: '古代遺跡の調査',
        description: '謎に包まれた古代遺跡を調査する',
        durationMinutes: 45,
        difficulty: 4,
        requiredGuildRank: 3, // Cランク
        targetAttack: 15,
        targetMagic: 25,
        targetSpeed: 15,
        targetIntelligence: 30,
        targetDefense: 20,
        experienceReward: 675,
        failureExperience: 135,
        dropRate: 0.3,
        possibleDrops: const ['ancient_staff', 'wisdom_bracelet', 'scholar_boots'],
      ),
      Quest(
        id: 'quest_012',
        name: 'トロール討伐',
        description: '橋を占拠する凶暴なトロールを倒す',
        durationMinutes: 45,
        difficulty: 4,
        requiredGuildRank: 3, // Cランク
        targetAttack: 28,
        targetMagic: 15,
        targetSpeed: 18,
        targetIntelligence: 12,
        targetDefense: 25,
        experienceReward: 675,
        failureExperience: 135,
        dropRate: 0.28,
        possibleDrops: const ['mithril_sword', 'iron_shield', 'chain_armor'],
      ),
      
      // Bランク (4)
      Quest(
        id: 'quest_013',
        name: 'ワイバーン討伐',
        description: '空を飛ぶ魔獣ワイバーンを討伐する',
        durationMinutes: 50,
        difficulty: 5,
        requiredGuildRank: 4, // Bランク
        targetAttack: 30,
        targetMagic: 25,
        targetSpeed: 28,
        targetIntelligence: 20,
        targetDefense: 28,
        experienceReward: 750,
        failureExperience: 150,
        dropRate: 0.35,
        possibleDrops: const ['mithril_sword', 'chain_armor', 'iron_shield', 'speed_boots'],
      ),
      Quest(
        id: 'quest_014',
        name: '魔法使いの塔',
        description: '暴走した魔法使いの塔を攻略する',
        durationMinutes: 50,
        difficulty: 5,
        requiredGuildRank: 4, // Bランク
        targetAttack: 20,
        targetMagic: 35,
        targetSpeed: 22,
        targetIntelligence: 32,
        targetDefense: 25,
        experienceReward: 750,
        failureExperience: 150,
        dropRate: 0.35,
        possibleDrops: const ['ancient_staff', 'wisdom_bracelet', 'scholar_boots'],
      ),
      Quest(
        id: 'quest_015',
        name: 'ドラゴン討伐',
        description: '山に住み着いた凶暴なドラゴンを倒す',
        durationMinutes: 60,
        difficulty: 5,
        requiredGuildRank: 4, // Bランク
        targetAttack: 35,
        targetMagic: 30,
        targetSpeed: 25,
        targetIntelligence: 25,
        targetDefense: 35,
        experienceReward: 900,
        failureExperience: 180,
        dropRate: 0.4,
        possibleDrops: const ['dragon_slayer', 'dragon_scale_armor', 'flame_shield'],
      ),
      
      // Aランク (5)
      Quest(
        id: 'quest_016',
        name: '魔獣の森制圧',
        description: '魔獣が跋扈する危険な森を制圧する',
        durationMinutes: 70,
        difficulty: 6,
        requiredGuildRank: 5, // Aランク
        targetAttack: 38,
        targetMagic: 35,
        targetSpeed: 32,
        targetIntelligence: 30,
        targetDefense: 35,
        experienceReward: 1050,
        failureExperience: 210,
        dropRate: 0.45,
        possibleDrops: const ['dragon_slayer', 'dragon_scale_armor', 'flame_shield', 'shadow_boots'],
      ),
      Quest(
        id: 'quest_017',
        name: '闇の教団壊滅',
        description: '邪悪な闇の教団のアジトを壊滅させる',
        durationMinutes: 80,
        difficulty: 6,
        requiredGuildRank: 5, // Aランク
        targetAttack: 40,
        targetMagic: 38,
        targetSpeed: 30,
        targetIntelligence: 35,
        targetDefense: 38,
        experienceReward: 1200,
        failureExperience: 240,
        dropRate: 0.48,
        possibleDrops: const ['demon_blade', 'dark_armor', 'cursed_shield'],
      ),
      Quest(
        id: 'quest_018',
        name: '魔王軍の幹部撃破',
        description: '魔王軍の幹部が率いる軍勢を撃破する',
        durationMinutes: 90,
        difficulty: 6,
        requiredGuildRank: 5, // Aランク
        targetAttack: 45,
        targetMagic: 40,
        targetSpeed: 35,
        targetIntelligence: 35,
        targetDefense: 40,
        experienceReward: 1350,
        failureExperience: 270,
        dropRate: 0.5,
        possibleDrops: const ['demon_blade', 'dark_armor', 'cursed_shield', 'shadow_boots'],
      ),
      
      // Sランク (6)
      Quest(
        id: 'quest_019',
        name: '古代竜討伐',
        description: '伝説の古代竜を討伐する究極の挑戦',
        durationMinutes: 100,
        difficulty: 8,
        requiredGuildRank: 6, // Sランク
        targetAttack: 55,
        targetMagic: 55,
        targetSpeed: 45,
        targetIntelligence: 45,
        targetDefense: 55,
        experienceReward: 1500,
        failureExperience: 300,
        dropRate: 0.7,
        possibleDrops: const ['legendary_sword', 'divine_armor', 'holy_shield', 'god_bracelet'],
      ),
      Quest(
        id: 'quest_020',
        name: '魔王討伐',
        description: '世界を脅かす魔王を討伐する最終決戦',
        durationMinutes: 120,
        difficulty: 10,
        requiredGuildRank: 6, // Sランク
        targetAttack: 60,
        targetMagic: 60,
        targetSpeed: 50,
        targetIntelligence: 50,
        targetDefense: 60,
        experienceReward: 1800,
        failureExperience: 360,
        dropRate: 0.8,
        possibleDrops: const ['legendary_sword', 'divine_armor', 'holy_shield', 'god_bracelet', 'angel_boots'],
      ),
    ];
  }
  
  static Quest? getQuestById(String id) {
    try {
      return getAllQuests().firstWhere((q) => q.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // ギルドランク名を取得
  static String getGuildRankName(int rank) {
    switch (rank) {
      case 0: return 'F';
      case 1: return 'E';
      case 2: return 'D';
      case 3: return 'C';
      case 4: return 'B';
      case 5: return 'A';
      case 6: return 'S';
      default: return 'F';
    }
  }
  
  // 次のランクに必要なクエスト成功数を取得
  static int getQuestsRequiredForRankUp(int currentRank) {
    switch (currentRank) {
      case 0: return 3;  // F→E: 3回
      case 1: return 5;  // E→D: 5回
      case 2: return 7;  // D→C: 7回
      case 3: return 10; // C→B: 10回
      case 4: return 15; // B→A: 15回
      case 5: return 20; // A→S: 20回
      default: return 999; // Sランクは最高ランク
    }
  }
  
  static final Map<String, Equipment> equipmentDatabase = {
    'iron_sword': Equipment(id: 'iron_sword', name: '鉄の剣', slot: 'weapon', attackBonus: 5, rarity: 1),
    'steel_sword': Equipment(id: 'steel_sword', name: '鋼の剣', slot: 'weapon', attackBonus: 10, rarity: 1),
    'mithril_sword': Equipment(id: 'mithril_sword', name: 'ミスリルソード', slot: 'weapon', attackBonus: 20, speedBonus: 5, rarity: 2),
    'dragon_slayer': Equipment(id: 'dragon_slayer', name: 'ドラゴンスレイヤー', slot: 'weapon', attackBonus: 35, defenseBonus: 10, rarity: 3),
    'demon_blade': Equipment(id: 'demon_blade', name: '魔剣', slot: 'weapon', attackBonus: 40, magicBonus: 20, rarity: 3),
    'legendary_sword': Equipment(id: 'legendary_sword', name: '伝説の剣', slot: 'weapon', attackBonus: 50, magicBonus: 30, speedBonus: 20, rarity: 3),
    'true_demon_blade': Equipment(id: 'true_demon_blade', name: '真・魔剣', slot: 'weapon', attackBonus: 80, magicBonus: 60, speedBonus: 40, rarity: 3),
    'magic_staff': Equipment(id: 'magic_staff', name: '魔法の杖', slot: 'weapon', magicBonus: 15, intelligenceBonus: 5, rarity: 1),
    'ancient_staff': Equipment(id: 'ancient_staff', name: '古代の杖', slot: 'weapon', magicBonus: 30, intelligenceBonus: 15, rarity: 2),
    'chaos_staff': Equipment(id: 'chaos_staff', name: '混沌の杖', slot: 'weapon', magicBonus: 100, intelligenceBonus: 60, attackBonus: 20, rarity: 3),
    'leather_armor': Equipment(id: 'leather_armor', name: '革の鎧', slot: 'armor', defenseBonus: 5, speedBonus: 2, rarity: 1),
    'chain_armor': Equipment(id: 'chain_armor', name: '鎖帷子', slot: 'armor', defenseBonus: 15, rarity: 2),
    'dragon_scale_armor': Equipment(id: 'dragon_scale_armor', name: 'ドラゴン鱗の鎧', slot: 'armor', defenseBonus: 30, magicBonus: 10, rarity: 3),
    'dark_armor': Equipment(id: 'dark_armor', name: '闇の鎧', slot: 'armor', defenseBonus: 35, attackBonus: 15, rarity: 3),
    'divine_armor': Equipment(id: 'divine_armor', name: '神聖なる鎧', slot: 'armor', defenseBonus: 45, magicBonus: 25, intelligenceBonus: 15, rarity: 3),
    'abyssal_armor': Equipment(id: 'abyssal_armor', name: '深淵の鎧', slot: 'armor', defenseBonus: 80, magicBonus: 50, attackBonus: 40, rarity: 3),
    'iron_shield': Equipment(id: 'iron_shield', name: '鉄の盾', slot: 'shield', defenseBonus: 10, rarity: 2),
    'flame_shield': Equipment(id: 'flame_shield', name: '炎の盾', slot: 'shield', defenseBonus: 20, magicBonus: 15, rarity: 3),
    'cursed_shield': Equipment(id: 'cursed_shield', name: '呪いの盾', slot: 'shield', defenseBonus: 25, attackBonus: 10, rarity: 3),
    'holy_shield': Equipment(id: 'holy_shield', name: '聖なる盾', slot: 'shield', defenseBonus: 35, magicBonus: 20, rarity: 3),
    'true_holy_shield': Equipment(id: 'true_holy_shield', name: '真・聖盾', slot: 'shield', defenseBonus: 70, magicBonus: 40, speedBonus: 30, rarity: 3),
    'magic_bracelet': Equipment(id: 'magic_bracelet', name: '魔力の腕輪', slot: 'bracelet', magicBonus: 10, rarity: 1),
    'wisdom_bracelet': Equipment(id: 'wisdom_bracelet', name: '賢者の腕輪', slot: 'bracelet', intelligenceBonus: 20, magicBonus: 10, rarity: 2),
    'god_bracelet': Equipment(id: 'god_bracelet', name: '神の腕輪', slot: 'bracelet', attackBonus: 20, magicBonus: 20, intelligenceBonus: 20, rarity: 3),
    'demon_king_bracelet': Equipment(id: 'demon_king_bracelet', name: '魔王の腕輪', slot: 'bracelet', attackBonus: 50, magicBonus: 50, intelligenceBonus: 50, defenseBonus: 30, rarity: 3),
    'leather_boots': Equipment(id: 'leather_boots', name: '革の靴', slot: 'boots', speedBonus: 5, rarity: 1),
    'speed_boots': Equipment(id: 'speed_boots', name: '俊足のブーツ', slot: 'boots', speedBonus: 15, rarity: 2),
    'scholar_boots': Equipment(id: 'scholar_boots', name: '学者のブーツ', slot: 'boots', speedBonus: 10, intelligenceBonus: 15, rarity: 2),
    'shadow_boots': Equipment(id: 'shadow_boots', name: '影のブーツ', slot: 'boots', speedBonus: 25, defenseBonus: 10, rarity: 3),
    'angel_boots': Equipment(id: 'angel_boots', name: '天使のブーツ', slot: 'boots', speedBonus: 30, magicBonus: 15, defenseBonus: 15, rarity: 3),
    'void_walker_boots': Equipment(id: 'void_walker_boots', name: '虚空の靴', slot: 'boots', speedBonus: 60, magicBonus: 40, intelligenceBonus: 40, rarity: 3),
  };
  
  static Equipment? getEquipmentById(String id) {
    return equipmentDatabase[id];
  }
}