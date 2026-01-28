enum ItemCategory { personality, statBoost, growth, outfit }

class ShopItem {
  final String id;
  final String name;
  final String effectDescription;
  final ItemCategory category;
  final String priceLabel; // 👈 5. "¥1,000" などの表示用ラベル
  final double braveChange;
  final double dependentChange;
  final double statMultiplier;
  final Duration? duration;
  final double timeReductionRate;

  ShopItem({
    required this.id,
    required this.name,
    required this.effectDescription,
    required this.category,
    this.priceLabel = '¥0',
    this.braveChange = 0,
    this.dependentChange = 0,
    this.statMultiplier = 1.0,
    this.duration,
    this.timeReductionRate = 0,
  });
}

// ActiveBuff クラスは変更なしなのでそのまま保持
class ActiveBuff {
  final String id;
  final String name;
  final double statMultiplier;
  final double timeReductionRate;
  final DateTime expiry;
  ActiveBuff(
      {required this.id,
      required this.name,
      required this.statMultiplier,
      required this.timeReductionRate,
      required this.expiry});
  bool get isExpired => DateTime.now().isAfter(expiry);
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'statMultiplier': statMultiplier,
        'timeReductionRate': timeReductionRate,
        'expiry': expiry.toIso8601String()
      };
  factory ActiveBuff.fromJson(Map<String, dynamic> json) => ActiveBuff(
      id: json['id'],
      name: json['name'],
      statMultiplier: (json['statMultiplier'] ?? 1.0).toDouble(),
      timeReductionRate: (json['timeReductionRate'] ?? 0.0).toDouble(),
      expiry: DateTime.parse(json['expiry']));
}
