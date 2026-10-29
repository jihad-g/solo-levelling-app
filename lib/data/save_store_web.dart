import 'package:web/web.dart' as web;

/// The browser's localStorage, for the web preview build. Storage can be
/// blocked (private windows, embedded previews), so failures mean "no save"
/// rather than a crash.
class SaveStore {
  static const _key = 'life_leveling_save';

  Future<String?> read() async {
    try {
      return web.window.localStorage.getItem(_key);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String data) async {
    try {
      web.window.localStorage.setItem(_key, data);
    } catch (_) {}
  }

  Future<void> backupCorrupt() async {
    try {
      final data = web.window.localStorage.getItem(_key);
      if (data != null) {
        web.window.localStorage.setItem(
          '$_key.corrupt-${DateTime.now().millisecondsSinceEpoch}',
          data,
        );
      }
    } catch (_) {}
  }

  Future<void> delete() async {
    try {
      web.window.localStorage.removeItem(_key);
    } catch (_) {}
  }
}
