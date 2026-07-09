import 'dart:ffi';
import 'package:ffi/ffi.dart';

// ---------------------------------------------------------------------------
// Win32 FFI — user32.dll bindings
// ---------------------------------------------------------------------------

/// `BOOL SystemParametersInfoW(UINT uiAction, UINT uiParam, PVOID pvParam, UINT fWinIni)`
typedef SystemParametersInfoWNative = Int32 Function(
    Uint32, Uint32, Pointer<Void>, Uint32);
typedef SystemParametersInfoWDart = int Function(
    int, int, Pointer<Void>, int);

/// SystemParametersInfo actions.
abstract class SPI {
  /// Sets the desktop wallpaper.
  /// pvParam = LPCWSTR path to .bmp file, fWinIni = SPIF_UPDATEINIFILE | SPIF_SENDCHANGE
  static const int setDeskWallpaper = 0x0014;
  static const int getDeskWallpaper = 0x0073;
}

/// SystemParametersInfo fWinIni flags.
abstract class SPIF {
  static const int updateIniFile = 0x01;
  static const int sendChange = 0x02;
  static const int sendWinIniChange = 0x02;
}

// ---------------------------------------------------------------------------
// Win32Bindings
// ---------------------------------------------------------------------------

/// Implements real Win32 FFI calls for desktop wallpaper operations.
class Win32Bindings {
  DynamicLibrary? _user32;
  SystemParametersInfoWDart? _systemParametersInfoW;

  bool get isLoaded => _systemParametersInfoW != null;

  /// Loads user32.dll and resolves all function pointers.
  void loadDynamicLibraries() {
    _user32 = DynamicLibrary.open('user32.dll');
    _systemParametersInfoW =
        _user32!.lookupFunction<SystemParametersInfoWNative, SystemParametersInfoWDart>(
            'SystemParametersInfoW');
  }

  /// Sets the Windows desktop wallpaper to the image at [imagePath].
  ///
  /// [imagePath] must be an absolute path to a .bmp file.
  /// On success, the desktop wallpaper is updated and the change is
  /// persisted across reboots.
  ///
  /// Returns true on success.
  bool setDesktopWallpaper(String imagePath) {
    if (_systemParametersInfoW == null) {
      throw StateError(
          'Win32Bindings not loaded. Call loadDynamicLibraries() first.');
    }

    final pathPtr = imagePath.toNativeUtf16();
    try {
      final result = _systemParametersInfoW!(
        SPI.setDeskWallpaper,
        0,
        pathPtr.cast<Void>(),
        SPIF.updateIniFile | SPIF.sendChange,
      );
      return result != 0;
    } finally {
      calloc.free(pathPtr);
    }
  }

  /// Disposes loaded library handles.
  void dispose() {
    _systemParametersInfoW = null;
    _user32 = null;
  }
}
