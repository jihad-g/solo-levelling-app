/// Where the save JSON lives: a file on Android, localStorage on the web.
library;

export 'save_store_io.dart' if (dart.library.js_interop) 'save_store_web.dart';
