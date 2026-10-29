import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// One JSON file in the app documents folder.
class SaveStore {
  static const _fileName = 'life_leveling_save.json';

  Future<File> _file() async =>
      File('${(await getApplicationDocumentsDirectory()).path}/$_fileName');

  Future<String?> read() async {
    final f = await _file();
    return await f.exists() ? f.readAsString() : null;
  }

  /// Writes to a temp file then renames, so a crash mid-write can't
  /// leave a half-written save.
  Future<void> write(String data) async {
    final f = await _file();
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(data, flush: true);
    await tmp.rename(f.path);
  }

  /// Keeps an unreadable save for recovery instead of overwriting it.
  Future<void> backupCorrupt() async {
    final f = await _file();
    await f.copy('${f.path}.corrupt-${DateTime.now().millisecondsSinceEpoch}');
  }

  Future<void> delete() async {
    final f = await _file();
    if (await f.exists()) await f.delete();
  }
}
