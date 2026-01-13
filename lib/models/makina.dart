import 'dart:convert';

// 装備品クラス
class Equipment {
  final String id;
  final String name;
  final String slot; // 'weapon', 'armor', 'shield', 'bracelet', 'boots'
  final int attackBonus;
  final int magicBonus;
  final int speedBonus;
  final int intelligenceBonus;
  final int defenseBonus;
  final int rarity; // 1=コモン, 2=レア, 3=エピック
  
  Equipment({
    required this.id,
    required this.name,
    required this.slot,
    this.attackBonus = 0,
    this.magicBonus = 0,
    this.speedBonus = 0,
    this.intelligenceBonus = 0,
    this.defenseBonus = 0,
    this.rarity = 1,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slot': slot,
      'attackBonus': attackBonus,
      'magicBonus': magicBonus,
      'speedBonus': speedBonus,
      'intelligenceBonus': intelligenceBonus,
      'defenseBonus': defenseBonus,
      'rarity': rarity,
    };
  }
  
  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'],
      name: json['name'],
      slot: json['slot'],
      attackBonus: json['attackBonus'] ?? 0,
      magicBonus: json['magicBonus'] ?? 0,
      speedBonus: json['speedBonus'] ?? 0,
      intelligenceBonus: json['intelligenceBonus'] ?? 0,
      defenseBonus: json['defenseBonus'] ?? 0,
      rarity: json['rarity'] ?? 1,
    );
  }
}

class Makina {
  int level;
  int experience;
  int experienceToNextLevel;
  
  // ステータス
  int attack;
  int magic;
  int speed;
  int intelligence;
  int defense;
  
  // 親密度 (0-100)
  double intimacy;
  
  // 性格パラメータ (-100 to 100)
  double brave; // 勇敢(-100) ↔ 慎重(100)
  double dependent; // 甘え(-100) ↔ 自立(100)
  
  // ギルドランク (F=0, E=1, D=2, C=3, B=4, A=5, S=6)
  int guildRank;
  
  // 現在のランクでの成功数
  int questSuccessCountForCurrentRank;
  
  // 装備スロット
  Equipment? weapon;
  Equipment? armor;
  Equipment? shield;
  Equipment? bracelet;
  Equipment? boots;
  
  // 所持している装備リスト
  List<Equipment> inventory;
  
  // 現在のクエスト
  Quest? currentQuest;
  DateTime? questStartTime;
  
  // 会話履歴(短期記憶)
  List<ConversationMemory> recentMemories;
  
  Makina({
    this.level = 1,
    this.experience = 0,
    this.experienceToNextLevel = 100,
    this.attack = 10,
    this.magic = 10,
    this.speed = 10,
    this.intelligence = 10,
    this.defense = 10,
    this.intimacy = 50.0,
    this.brave = 0.0,
    this.dependent = 0.0,
    this.guildRank = 0,
    this.questSuccessCountForCurrentRank = 0,
    this.weapon,
    this.armor,
    this.shield,
    this.bracelet,
    this.boots,
    List<Equipment>? inventory,
    this.currentQuest,
    this.questStartTime,
    List<ConversationMemory>? recentMemories,
  }) : inventory = inventory ?? [],
       recentMemories = recentMemories ?? [];
  
  // 装備ボーナスを含めた実効ステータス
  int get effectiveAttack => attack + (weapon?.attackBonus ?? 0) + (armor?.attackBonus ?? 0) + (shield?.attackBonus ?? 0) + (bracelet?.attackBonus ?? 0) + (boots?.attackBonus ?? 0);
  int get effectiveMagic => magic + (weapon?.magicBonus ?? 0) + (armor?.magicBonus ?? 0) + (shield?.magicBonus ?? 0) + (bracelet?.magicBonus ?? 0) + (boots?.magicBonus ?? 0);
  int get effectiveSpeed => speed + (weapon?.speedBonus ?? 0) + (armor?.speedBonus ?? 0) + (shield?.speedBonus ?? 0) + (bracelet?.speedBonus ?? 0) + (boots?.speedBonus ?? 0);
  int get effectiveIntelligence => intelligence + (weapon?.intelligenceBonus ?? 0) + (armor?.intelligenceBonus ?? 0) + (shield?.intelligenceBonus ?? 0) + (bracelet?.intelligenceBonus ?? 0) + (boots?.intelligenceBonus ?? 0);
  int get effectiveDefense => defense + (weapon?.defenseBonus ?? 0) + (armor?.defenseBonus ?? 0) + (shield?.defenseBonus ?? 0) + (bracelet?.defenseBonus ?? 0) + (boots?.defenseBonus ?? 0);
  
  // 経験値を追加してレベルアップ処理
  void addExperience(int exp) {
    experience += exp;
    
    while (experience >= experienceToNextLevel) {
      levelUp();
    }
  }
  
  void levelUp() {
    experience -= experienceToNextLevel;
    level++;
    experienceToNextLevel = (100 * level * 1.5).toInt();
    
    // ステータス上昇
    attack += 3;
    magic += 3;
    speed += 2;
    intelligence += 2;
    defense += 2;
  }
  
  // 親密度を変更(0-100の範囲内)
  void changeIntimacy(double delta) {
    intimacy = (intimacy + delta).clamp(0.0, 100.0);
  }
  
  // 性格パラメータを変更
  void changePersonality(double braveChange, double dependentChange) {
    brave = (brave + braveChange).clamp(-100.0, 100.0);
    dependent = (dependent + dependentChange).clamp(-100.0, 100.0);
  }
  
  // クエスト成功時の処理（ランクアップ判定含む）
  void recordQuestSuccess() {
    questSuccessCountForCurrentRank++;
  }
  
  // ランクアップ処理
  bool tryRankUp(int questsRequired) {
    if (guildRank < 6 && questSuccessCountForCurrentRank >= questsRequired) {
      guildRank++;
      questSuccessCountForCurrentRank = 0;
      return true;
    }
    return false;
  }
  
  // 会話記憶を追加
  void addMemory(String playerMessage, String makinaResponse) {
    recentMemories.add(ConversationMemory(
      playerMessage: playerMessage,
      makinaResponse: makinaResponse,
      timestamp: DateTime.now(),
    ));
    
    // 最新5件のみ保持
    if (recentMemories.length > 5) {
      recentMemories.removeAt(0);
    }
  }
  
  // 装備を装着
  void equipItem(Equipment equipment) {
    // 既存の装備を外してインベントリに戻す
    Equipment? oldEquipment;
    switch (equipment.slot) {
      case 'weapon':
        oldEquipment = weapon;
        weapon = equipment;
        break;
      case 'armor':
        oldEquipment = armor;
        armor = equipment;
        break;
      case 'shield':
        oldEquipment = shield;
        shield = equipment;
        break;
      case 'bracelet':
        oldEquipment = bracelet;
        bracelet = equipment;
        break;
      case 'boots':
        oldEquipment = boots;
        boots = equipment;
        break;
    }
    
    if (oldEquipment != null) {
      inventory.add(oldEquipment);
    }
    
    // 装備したアイテムをインベントリから削除
    inventory.removeWhere((item) => item.id == equipment.id);
  }
  
  // 装備を外す
  void unequipItem(String slot) {
    Equipment? equipment;
    switch (slot) {
      case 'weapon':
        equipment = weapon;
        weapon = null;
        break;
      case 'armor':
        equipment = armor;
        armor = null;
        break;
      case 'shield':
        equipment = shield;
        shield = null;
        break;
      case 'bracelet':
        equipment = bracelet;
        bracelet = null;
        break;
      case 'boots':
        equipment = boots;
        boots = null;
        break;
    }
    
    if (equipment != null) {
      inventory.add(equipment);
    }
  }
  
  // アイテムを追加
  void addToInventory(Equipment equipment) {
    inventory.add(equipment);
  }
  
  // JSON変換
  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'experience': experience,
      'experienceToNextLevel': experienceToNextLevel,
      'attack': attack,
      'magic': magic,
      'speed': speed,
      'intelligence': intelligence,
      'defense': defense,
      'intimacy': intimacy,
      'brave': brave,
      'dependent': dependent,
      'guildRank': guildRank,
      'questSuccessCountForCurrentRank': questSuccessCountForCurrentRank,
      'weapon': weapon?.toJson(),
      'armor': armor?.toJson(),
      'shield': shield?.toJson(),
      'bracelet': bracelet?.toJson(),
      'boots': boots?.toJson(),
      'inventory': inventory.map((e) => e.toJson()).toList(),
      'currentQuest': currentQuest?.toJson(),
      'questStartTime': questStartTime?.toIso8601String(),
      'recentMemories': recentMemories.map((m) => m.toJson()).toList(),
    };
  }
  
  factory Makina.fromJson(Map<String, dynamic> json) {
    return Makina(
      level: json['level'] ?? 1,
      experience: json['experience'] ?? 0,
      experienceToNextLevel: json['experienceToNextLevel'] ?? 100,
      attack: json['attack'] ?? 10,
      magic: json['magic'] ?? 10,
      speed: json['speed'] ?? 10,
      intelligence: json['intelligence'] ?? 10,
      defense: json['defense'] ?? 10,
      intimacy: (json['intimacy'] ?? 50.0).toDouble(),
      brave: (json['brave'] ?? 0.0).toDouble(),
      dependent: (json['dependent'] ?? 0.0).toDouble(),
      guildRank: json['guildRank'] ?? 0,
      questSuccessCountForCurrentRank: json['questSuccessCountForCurrentRank'] ?? 0,
      weapon: json['weapon'] != null ? Equipment.fromJson(json['weapon']) : null,
      armor: json['armor'] != null ? Equipment.fromJson(json['armor']) : null,
      shield: json['shield'] != null ? Equipment.fromJson(json['shield']) : null,
      bracelet: json['bracelet'] != null ? Equipment.fromJson(json['bracelet']) : null,
      boots: json['boots'] != null ? Equipment.fromJson(json['boots']) : null,
      inventory: json['inventory'] != null
          ? (json['inventory'] as List).map((e) => Equipment.fromJson(e)).toList()
          : [],
      currentQuest: json['currentQuest'] != null 
          ? Quest.fromJson(json['currentQuest']) 
          : null,
      questStartTime: json['questStartTime'] != null 
          ? DateTime.parse(json['questStartTime']) 
          : null,
      recentMemories: json['recentMemories'] != null
          ? (json['recentMemories'] as List)
              .map((m) => ConversationMemory.fromJson(m))
              .toList()
          : [],
    );
  }
}

class ConversationMemory {
  final String playerMessage;
  final String makinaResponse;
  final DateTime timestamp;
  
  ConversationMemory({
    required this.playerMessage,
    required this.makinaResponse,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'playerMessage': playerMessage,
      'makinaResponse': makinaResponse,
      'timestamp': timestamp.toIso8601String(),
    };
  }
  
  factory ConversationMemory.fromJson(Map<String, dynamic> json) {
    return ConversationMemory(
      playerMessage: json['playerMessage'],
      makinaResponse: json['makinaResponse'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class Quest {
  final String id;
  final String name;
  final String description;
  final int durationMinutes;
  final int difficulty;
  final int requiredGuildRank; // 必要なギルドランク
  
  // 目標ステータス
  final int targetAttack;
  final int targetMagic;
  final int targetSpeed;
  final int targetIntelligence;
  final int targetDefense;
  
  // 報酬
  final int experienceReward;
  final int failureExperience;
  
  // ドロップ
  final double dropRate; // ドロップ率 (0.0 - 1.0)
  final List<String> possibleDrops; // ドロップ可能な装備ID
  
  Quest({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.difficulty,
    this.requiredGuildRank = 0,
    required this.targetAttack,
    required this.targetMagic,
    required this.targetSpeed,
    required this.targetIntelligence,
    required this.targetDefense,
    required this.experienceReward,
    required this.failureExperience,
    this.dropRate = 0.0,
    this.possibleDrops = const [],
  });
  
  // クエストの成功率を計算(装備ボーナス込み)
  double calculateSuccessRate(Makina makina) {
    // 各ステータスの達成度を計算
    List<double> ratios = [];
    List<double> weights = [];
    
    // 攻撃
    if (targetAttack > 0) {
      ratios.add((makina.effectiveAttack / targetAttack).clamp(0.0, 2.0));
      weights.add(1.0);
    }
    
    // 魔法
    if (targetMagic > 0) {
      ratios.add((makina.effectiveMagic / targetMagic).clamp(0.0, 2.0));
      weights.add(1.0);
    }
    
    // 素早さ
    if (targetSpeed > 0) {
      ratios.add((makina.effectiveSpeed / targetSpeed).clamp(0.0, 2.0));
      weights.add(1.0);
    }
    
    // 賢さ
    if (targetIntelligence > 0) {
      ratios.add((makina.effectiveIntelligence / targetIntelligence).clamp(0.0, 2.0));
      weights.add(1.0);
    }
    
    // 防御
    if (targetDefense > 0) {
      ratios.add((makina.effectiveDefense / targetDefense).clamp(0.0, 2.0));
      weights.add(1.0);
    }
    
    // 重み付き平均スコアを計算
    double score = 0.0;
    double totalWeight = 0.0;
    
    for (int i = 0; i < ratios.length; i++) {
      score += ratios[i] * weights[i];
      totalWeight += weights[i];
    }
    
    if (totalWeight > 0) {
      score = score / totalWeight;
    } else {
      score = 1.0; // 目標ステータスが全て0の場合は100%
    }
    
    // スコアを成功率に変換
    double successRate;
    if (score < 0.3) {
      successRate = 0.01 * (score / 0.3);
    } else {
      successRate = 0.01 + (score - 0.3) / 1.7 * 0.94;
    }
    
    return successRate.clamp(0.0, 0.95);
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'durationMinutes': durationMinutes,
      'difficulty': difficulty,
      'requiredGuildRank': requiredGuildRank,
      'targetAttack': targetAttack,
      'targetMagic': targetMagic,
      'targetSpeed': targetSpeed,
      'targetIntelligence': targetIntelligence,
      'targetDefense': targetDefense,
      'experienceReward': experienceReward,
      'failureExperience': failureExperience,
      'dropRate': dropRate,
      'possibleDrops': possibleDrops,
    };
  }
  
  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      durationMinutes: json['durationMinutes'],
      difficulty: json['difficulty'],
      requiredGuildRank: json['requiredGuildRank'] ?? 0,
      targetAttack: json['targetAttack'],
      targetMagic: json['targetMagic'],
      targetSpeed: json['targetSpeed'],
      targetIntelligence: json['targetIntelligence'],
      targetDefense: json['targetDefense'],
      experienceReward: json['experienceReward'],
      failureExperience: json['failureExperience'],
      dropRate: json['dropRate'] ?? 0.0,
      possibleDrops: json['possibleDrops'] != null 
          ? List<String>.from(json['possibleDrops'])
          : [],
    );
  }
}