import 'dart:ffi';
import 'package:ffi/ffi.dart';

// ─── C function typedefs ───────────────────────────────────────────────

typedef _FindWindowW_C = IntPtr Function(Pointer<Utf16>, Pointer<Utf16>);
typedef _FindWindowW_D = int Function(Pointer<Utf16>, Pointer<Utf16>);

typedef _FindWindowExW_C = IntPtr Function(IntPtr, IntPtr, Pointer<Utf16>, Pointer<Utf16>);
typedef _FindWindowExW_D = int Function(int, int, Pointer<Utf16>, Pointer<Utf16>);

typedef _EnumWindows_C = Int32 Function(Pointer<NativeFunction<_EnumProcC>>, IntPtr);
typedef _EnumWindows_D = int Function(Pointer<NativeFunction<_EnumProcC>>, int);

typedef _EnumProcC = Int32 Function(IntPtr, IntPtr);

typedef _SendMsgTimeoutW_C = IntPtr Function(IntPtr, Uint32, IntPtr, IntPtr, Uint32, Uint32, Pointer<IntPtr>);
typedef _SendMsgTimeoutW_D = int Function(int, int, int, int, int, int, Pointer<IntPtr>);

typedef _SetParent_C = IntPtr Function(IntPtr, IntPtr);
typedef _SetParent_D = int Function(int, int);

typedef _SPI_C = Int32 Function(Uint32, Uint32, Pointer<Void>, Uint32);
typedef _SPI_D = int Function(int, int, Pointer<Void>, int);

typedef _GetActiveWindow_C = IntPtr Function();
typedef _GetActiveWindow_D = int Function();

// ─── Win32Bindings ──────────────────────────────────────────────────────

class Win32Bindings {
  late final DynamicLibrary _lib;
  late final _FindWindowW_D _findWindowW;
  late final _FindWindowExW_D _findWindowExW;
  late final _EnumWindows_D _enumWindows;
  late final _SendMsgTimeoutW_D _sendMessageTimeout;
  late final _SetParent_D _setParent;
  late final _SPI_D _systemParametersInfoW;
  late final _GetActiveWindow_D _getActiveWindow;

  int _foundWorkerW = 0;

  void loadDynamicLibraries() {
    _lib = DynamicLibrary.open('user32.dll');
    _findWindowW = _lib.lookupFunction<_FindWindowW_C, _FindWindowW_D>('FindWindowW');
    _findWindowExW = _lib.lookupFunction<_FindWindowExW_C, _FindWindowExW_D>('FindWindowExW');
    _enumWindows = _lib.lookupFunction<_EnumWindows_C, _EnumWindows_D>('EnumWindows');
    _sendMessageTimeout = _lib.lookupFunction<_SendMsgTimeoutW_C, _SendMsgTimeoutW_D>('SendMessageTimeoutW');
    _setParent = _lib.lookupFunction<_SetParent_C, _SetParent_D>('SetParent');
    _systemParametersInfoW = _lib.lookupFunction<_SPI_C, _SPI_D>('SystemParametersInfoW');
    _getActiveWindow = _lib.lookupFunction<_GetActiveWindow_C, _GetActiveWindow_D>('GetActiveWindow');
  }

  /// WorkerW discovery callback — returns 0 (stop) when found.
  int _onWindow(int hwnd) {
    final cls = 'SHELLDLL_DefView'.toNativeUtf16();
    final child = _findWindowExW(hwnd, 0, cls, nullptr);
    calloc.free(cls);
    if (child != 0) {
      _foundWorkerW = hwnd;
      return 0;
    }
    return 1;
  }

  static int _enumCallback(int hwnd, int lParam) {
    return Win32Bindings._current!._onWindow(hwnd);
  }

  static Win32Bindings? _current;

  /// Embeds the Flutter window behind desktop icons.
  bool embedAsWallpaper() {
    _current = this;
    _foundWorkerW = 0;

    // 1. Find Progman
    final progman = _findWindowW('Progman'.toNativeUtf16(), nullptr);
    if (progman == 0) return false;

    // 2. Create WorkerW via 0x052C
    final r = calloc<IntPtr>();
    _sendMessageTimeout(progman, 0x052C, 0, 0, 0, 1000, r);
    calloc.free(r);

    // 3. Find WorkerW containing SHELLDLL_DefView
    final cb = Pointer.fromFunction<_EnumProcC>(_enumCallback, 0);
    _enumWindows(cb, 0);
    _current = null;
    if (_foundWorkerW == 0) return false;

    // 4. Get Flutter window handle
    final flutter = _getActiveWindow();
    if (flutter == 0) return false;

    // 5. Reparent Flutter window to WorkerW
    _setParent(flutter, _foundWorkerW);
    return true;
  }

  /// Sets the Windows desktop wallpaper to [imagePath].
  bool setDesktopWallpaper(String imagePath) {
    final p = imagePath.toNativeUtf16();
    final r = _systemParametersInfoW(0x0014, 0, p.cast<Void>(), 0x01 | 0x02);
    calloc.free(p);
    return r != 0;
  }
}
