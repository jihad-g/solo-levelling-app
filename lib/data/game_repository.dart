import 'dart:convert';

import '../core/models.dart';
import 'save_store.dart';

/// Saves the whole game as one JSON document.
class GameRepository {
  final SaveStore _store;

  GameRepository({SaveStore? store}) : _store = store ?? SaveStore();

  Future<GameState?> load() async {
    final data = await _store.read();
    if (data == null) return null;
    try {
      return GameState.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (_) {
      await _store.backupCorrupt();
      return null;
    }
  }

  Future<void> save(GameState s) => _store.write(jsonEncode(s.toJson()));

  Future<void> delete() => _store.delete();
}
