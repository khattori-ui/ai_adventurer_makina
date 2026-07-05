import 'package:flutter/foundation.dart';

import '../../core/game/game_session.dart';
import '../../shared/models/makina.dart';

class EquipmentLogic {
  EquipmentLogic(this._session, this._notify, this._save);

  final GameSession _session;
  final VoidCallback _notify;
  final Future<void> Function() _save;

  Future<void> equipItem(Equipment e) async {
    _session.makina.equipItem(e);
    await _save();
    _notify();
  }

  Future<void> unequipItem(EquipmentSlot s) async {
    _session.makina.unequipItem(s);
    await _save();
    _notify();
  }
}
