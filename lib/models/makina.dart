import 'dart:math';
import 'item.dart';

// 1. 装備のデータ
class Equipment {
  final String id;
  final String name;
  final String slot;
  final int attackBonus;
  final int magicBonus;
  final int speedBonus;
  final int intelligenceBonus;
  final int defenseBonus;
  final int rarity;
  Equipment(
      {required this.id,
      required this.name,
      required this.slot,
      this.attackBonus = 0,
      this.magicBonus = 0,
      this.speedBonus = 0,
      this.intelligenceBonus = 0,
      this.defenseBonus = 0,
      this.rarity = 1});
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slot': slot,
        'attackBonus': attackBonus,
        'magicBonus': magicBonus,
        'speedBonus': speedBonus,
        'intelligenceBonus': intelligenceBonus,
        'defenseBonus': defenseBonus,
        'rarity': rarity
      };
  factory Equipment.fromJson(Map<String, dynamic> json) => Equipment(
      id: json['id'],
      name: json['name'],
      slot: json['slot'],
      attackBonus: json['attackBonus'] ?? 0,
      magicBonus: json['magicBonus'] ?? 0,
      speedBonus: json['speedBonus'] ?? 0,
      intelligenceBonus: json['intelligenceBonus'] ?? 0,
      defenseBonus: json['defenseBonus'] ?? 0,
      rarity: json['rarity'] ?? 1);
}

// 2. 会話の記憶
class ConversationMemory {
  final String playerMessage;
  final String makinaResponse;
  final DateTime timestamp;
  ConversationMemory(
      {required this.playerMessage,
      required this.makinaResponse,
      required this.timestamp});
  Map<String, dynamic> toJson() => {
        'playerMessage': playerMessage,
        'makinaResponse': makinaResponse,
        'timestamp': timestamp.toIso8601String()
      };
  factory ConversationMemory.fromJson(Map<String, dynamic> json) =>
      ConversationMemory(
          playerMessage: json['playerMessage'],
          makinaResponse: json['makinaResponse'],
          timestamp: DateTime.parse(json['timestamp']));
}

// 3. クエストのデータ
class Quest {
  final String id;
  final String name;
  final String description;
  final int durationMinutes;
  final int difficulty;
  final int requiredGuildRank;
  final int targetAttack;
  final int targetMagic;
  final int targetSpeed;
  final int targetIntelligence;
  final int targetDefense;
  final int experienceReward;
  final int failureExperience;
  final double dropRate;
  final List<String> possibleDrops;
  Quest(
      {required this.id,
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
      this.possibleDrops = const []});

  double calculateSuccessRate(Makina makina, bool isCleared) {
    List<double> r = [];
    List<double> w = [];
    if (targetAttack > 0) {
      r.add((makina.effectiveAttack / targetAttack).clamp(0.0, 3.0));
      w.add(targetAttack.toDouble());
    }
    if (targetMagic > 0) {
      r.add((makina.effectiveMagic / targetMagic).clamp(0.0, 3.0));
      w.add(targetMagic.toDouble());
    }
    if (targetSpeed > 0) {
      r.add((makina.effectiveSpeed / targetSpeed).clamp(0.0, 3.0));
      w.add(targetSpeed.toDouble());
    }
    if (targetIntelligence > 0) {
      r.add(
          (makina.effectiveIntelligence / targetIntelligence).clamp(0.0, 3.0));
      w.add(targetIntelligence.toDouble());
    }
    if (targetDefense > 0) {
      r.add((makina.effectiveDefense / targetDefense).clamp(0.0, 3.0));
      w.add(targetDefense.toDouble());
    }
    double s = 0.0;
    double tw = 0.0;
    for (int i = 0; i < r.length; i++) {
      s += r[i] * w[i];
      tw += w[i];
    }
    if (tw > 0) {
      s /= tw;
    } else {
      s = 3.0;
    }
    double baseRate =
        (s <= 1.0 ? s * 0.55 : 0.55 + (s - 1.0) * 0.25).clamp(0.05, 0.99);
    if (isCleared && makina.reincarnationCount > 0) {
      double bonus = (makina.reincarnationCount * 0.05).clamp(0.0, 0.10);
      baseRate = (baseRate + bonus).clamp(0.05, 0.99);
    }
    return baseRate;
  }

  Map<String, dynamic> toJson() => {
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
        'possibleDrops': possibleDrops
      };
  factory Quest.fromJson(Map<String, dynamic> json) => Quest(
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
          : []);
}

// 4. マキナ本体
class Makina {
  String uid;
  int level;
  int experience;
  int experienceToNextLevel;
  int attack;
  int magic;
  int speed;
  int intelligence;
  int defense;
  double intimacy;
  double brave;
  double dependent;
  int guildRank;
  int questSuccessCountForCurrentRank;
  int reincarnationCount;
  Equipment? weapon;
  Equipment? armor;
  Equipment? shield;
  Equipment? bracelet;
  Equipment? boots;
  List<Equipment> inventory;
  Quest? currentQuest;
  DateTime? questStartTime;
  List<ConversationMemory> recentMemories;
  String? currentOutfitId;
  List<ActiveBuff> activeBuffs;
  bool hasSeenPrologue;
  bool hasSeenTutorial;
  List<String> clearedQuestIds;
  Map<String, dynamic> achievementData;
  int dailyConversationCount;
  String lastConversationDate;

  Makina({
    this.uid = 'local_user',
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
    this.reincarnationCount = 0,
    this.weapon,
    this.armor,
    this.shield,
    this.bracelet,
    this.boots,
    List<Equipment>? inventory,
    this.currentQuest,
    this.questStartTime,
    List<ConversationMemory>? recentMemories,
    this.currentOutfitId,
    List<ActiveBuff>? activeBuffs,
    this.hasSeenPrologue = false,
    this.hasSeenTutorial = false,
    List<String>? clearedQuestIds,
    this.achievementData = const {},
    this.dailyConversationCount = 0,
    this.lastConversationDate = '',
  })  : inventory = inventory ?? [],
        recentMemories = recentMemories ?? [],
        activeBuffs = activeBuffs ?? [],
        clearedQuestIds = clearedQuestIds ?? [];

  int _applyBuff(int val) {
    double m = 1.0;
    for (var b in activeBuffs) {
      if (!b.isExpired) m = max(m, b.statMultiplier);
    }
    return (val * m).toInt();
  }

  int get effectiveAttack => _applyBuff(attack +
      (weapon?.attackBonus ?? 0) +
      (armor?.attackBonus ?? 0) +
      (shield?.attackBonus ?? 0) +
      (bracelet?.attackBonus ?? 0) +
      (boots?.attackBonus ?? 0));
  int get effectiveMagic => _applyBuff(magic +
      (weapon?.magicBonus ?? 0) +
      (armor?.magicBonus ?? 0) +
      (shield?.magicBonus ?? 0) +
      (bracelet?.magicBonus ?? 0) +
      (boots?.magicBonus ?? 0));
  int get effectiveSpeed => _applyBuff(speed +
      (weapon?.speedBonus ?? 0) +
      (armor?.speedBonus ?? 0) +
      (shield?.speedBonus ?? 0) +
      (bracelet?.speedBonus ?? 0) +
      (boots?.speedBonus ?? 0));
  int get effectiveIntelligence => _applyBuff(intelligence +
      (weapon?.intelligenceBonus ?? 0) +
      (armor?.intelligenceBonus ?? 0) +
      (shield?.intelligenceBonus ?? 0) +
      (bracelet?.intelligenceBonus ?? 0) +
      (boots?.intelligenceBonus ?? 0));
  int get effectiveDefense => _applyBuff(defense +
      (weapon?.defenseBonus ?? 0) +
      (armor?.defenseBonus ?? 0) +
      (shield?.defenseBonus ?? 0) +
      (bracelet?.defenseBonus ?? 0) +
      (boots?.defenseBonus ?? 0));

  void addExperience(int exp) {
    experience += exp;
    while (experience >= experienceToNextLevel) {
      levelUp();
    }
  }

  void levelUp() {
    experience -= experienceToNextLevel;
    level++;
    // 👇 ここが経験値の指数関数（累乗数）です
    experienceToNextLevel = (100 * pow(level, 2.9)).toInt();
    int b = 5 + (reincarnationCount * 2);
    attack += b;
    magic += b;
    speed += b - 2;
    intelligence += b - 2;
    defense += b - 2;
  }

  void reincarnate() {
    reincarnationCount++;
    level = 1;
    experience = 0;
    experienceToNextLevel = 100;
    attack = 10;
    magic = 10;
    speed = 10;
    intelligence = 10;
    defense = 10;
    intimacy = 50.0;
    guildRank = 0;
  }

  void changeIntimacy(double delta) =>
      intimacy = (intimacy + delta).clamp(0.0, 100.0);
  void applyPersonalityChange(double b, double d) {
    brave = (brave + b).clamp(-100.0, 100.0);
    dependent = (dependent + d).clamp(-100.0, 100.0);
  }

  void recordQuestSuccess() => questSuccessCountForCurrentRank++;
  bool tryRankUp(int req) {
    if (guildRank < 6 && questSuccessCountForCurrentRank >= req) {
      guildRank++;
      questSuccessCountForCurrentRank = 0;
      return true;
    }
    return false;
  }

  void addMemory(String pm, String mr) {
    recentMemories.add(ConversationMemory(
        playerMessage: pm, makinaResponse: mr, timestamp: DateTime.now()));
    if (recentMemories.length > 20) recentMemories.removeAt(0);
  }

  void equipItem(Equipment e) {
    Equipment? o;
    if (e.slot == 'weapon') {
      o = weapon;
      weapon = e;
    } else if (e.slot == 'armor') {
      o = armor;
      armor = e;
    } else if (e.slot == 'shield') {
      o = shield;
      shield = e;
    } else if (e.slot == 'bracelet') {
      o = bracelet;
      bracelet = e;
    } else if (e.slot == 'boots') {
      o = boots;
      boots = e;
    }
    if (o != null) inventory.add(o);
    inventory.removeWhere((i) => i.id == e.id);
  }

  void unequipItem(String s) {
    Equipment? e;
    if (s == 'weapon') {
      e = weapon;
      weapon = null;
    } else if (s == 'armor') {
      e = armor;
      armor = null;
    } else if (s == 'shield') {
      e = shield;
      shield = null;
    } else if (s == 'bracelet') {
      e = bracelet;
      bracelet = null;
    } else if (s == 'boots') {
      e = boots;
      boots = null;
    }
    if (e != null) inventory.add(e);
  }

  void addToInventory(Equipment e) => inventory.add(e);
  bool hasEquipment(String id) =>
      (weapon?.id == id) ||
      (armor?.id == id) ||
      (shield?.id == id) ||
      (bracelet?.id == id) ||
      (boots?.id == id) ||
      inventory.any((i) => i.id == id);

  Map<String, dynamic> toJson() => {
        'uid': uid,
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
        'reincarnationCount': reincarnationCount,
        'weapon': weapon?.toJson(),
        'armor': armor?.toJson(),
        'shield': shield?.toJson(),
        'bracelet': bracelet?.toJson(),
        'boots': boots?.toJson(),
        'inventory': inventory.map((e) => e.toJson()).toList(),
        'currentQuest': currentQuest?.toJson(),
        'questStartTime': questStartTime?.toIso8601String(),
        'recentMemories': recentMemories.map((m) => m.toJson()).toList(),
        'currentOutfitId': currentOutfitId,
        'activeBuffs': activeBuffs.map((b) => b.toJson()).toList(),
        'hasSeenPrologue': hasSeenPrologue,
        'hasSeenTutorial': hasSeenTutorial,
        'clearedQuestIds': clearedQuestIds,
        'achievementData': achievementData,
        'dailyConversationCount': dailyConversationCount,
        'lastConversationDate': lastConversationDate
      };
  factory Makina.fromJson(Map<String, dynamic> json) => Makina(
      uid: json['uid'] ?? 'local_user',
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
      questSuccessCountForCurrentRank:
          json['questSuccessCountForCurrentRank'] ?? 0,
      reincarnationCount: json['reincarnationCount'] ?? 0,
      weapon:
          json['weapon'] != null ? Equipment.fromJson(json['weapon']) : null,
      armor: json['armor'] != null ? Equipment.fromJson(json['armor']) : null,
      shield:
          json['shield'] != null ? Equipment.fromJson(json['shield']) : null,
      bracelet: json['bracelet'] != null
          ? Equipment.fromJson(json['bracelet'])
          : null,
      boots: json['boots'] != null ? Equipment.fromJson(json['boots']) : null,
      inventory: json['inventory'] != null
          ? (json['inventory'] as List)
              .map((e) => Equipment.fromJson(e))
              .toList()
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
      currentOutfitId: json['currentOutfitId'],
      activeBuffs: json['activeBuffs'] != null
          ? (json['activeBuffs'] as List)
              .map((b) => ActiveBuff.fromJson(b))
              .toList()
          : [],
      hasSeenPrologue: json['hasSeenPrologue'] ?? false,
      hasSeenTutorial: json['hasSeenTutorial'] ?? false,
      clearedQuestIds: json['clearedQuestIds'] != null
          ? List<String>.from(json['clearedQuestIds'])
          : [],
      achievementData: json['achievementData'] ?? {},
      dailyConversationCount: json['dailyConversationCount'] ?? 0,
      lastConversationDate: json['lastConversationDate'] ?? '');
}
