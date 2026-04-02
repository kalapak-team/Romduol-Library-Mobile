/// Platform-conditional download helper.
/// On web  → download_helper_web.dart  (dart:html Blob + anchor)
/// On native → download_helper_io.dart (Dio + path_provider + open_filex)
export 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart'
    if (dart.library.io) 'download_helper_io.dart';
