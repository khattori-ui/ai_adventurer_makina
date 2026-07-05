import 'package:flutter/foundation.dart';

import '../../core/game/game_session.dart';
import '../../shared/models/item.dart';

class ShopLogic {
  ShopLogic(this._session, this._notify, this._save);

  final GameSession _session;
  final VoidCallback _notify;
  final Future<void> Function() _save;

  Future<void> useItem(ShopItem item) async {
    if (item.category == ItemCategory.personality) {
      _session.makina.applyPersonalityChange(
        item.braveChange.toDouble(),
        item.dependentChange.toDouble(),
      );
      _session.currentMessage = 'マキナ：${item.name}、ありがとう！';
    } else if (item.duration != null) {
      _session.makina.activeBuffs.add(ActiveBuff(
        id: item.id,
        name: item.name,
        statMultiplier: item.statMultiplier.toDouble(),
        timeReductionRate: item.timeReductionRate.toDouble(),
        expiry: DateTime.now().add(item.duration!),
      ));
      _session.currentMessage = 'マキナ：${item.name}のおかげで、力が湧いてきたよ！';
    } else if (item.category == ItemCategory.outfit) {
      _session.makina.currentOutfitId = item.id;
      _session.currentMessage = 'マキナ：わあ、素敵な服！似合ってるかな？';
    }
    await _save();
    _notify();
  }
}
