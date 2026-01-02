import 'dart:convert';

import '../services/tcp_service.dart';

/// Manages keyboard input commands sent to the desktop server.
/// Supports typing text, tapping keys, and press/release operations.
class KeyboardController {
  final TcpService tcpService;

  KeyboardController(this.tcpService);

  /// Type text (includes newlines, special chars, etc.)
  void typeText(String text) {
    final payload = {
      'keyboard': {'cmd': 'type', 'text': text},
    };
    tcpService.send(jsonEncode(payload));
  }

  /// Tap a key (press and release immediately)
  void tapKey(int keyCode) {
    final payload = {
      'keyboard': {'cmd': 'tap', 'keyCode': keyCode},
    };
    tcpService.send(jsonEncode(payload));
  }

  /// Press and hold a key
  void pressKey(int keyCode) {
    final payload = {
      'keyboard': {'cmd': 'press', 'keyCode': keyCode},
    };
    tcpService.send(jsonEncode(payload));
  }

  /// Release a previously pressed key
  void releaseKey(int keyCode) {
    final payload = {
      'keyboard': {'cmd': 'release', 'keyCode': keyCode},
    };
    tcpService.send(jsonEncode(payload));
  }

  /// Convenience method: tap a named key
  void tapNamedKey(String keyName) {
    final keyCode = KeyCodes.fromName(keyName);
    if (keyCode != null) {
      tapKey(keyCode);
    }
  }
}

/// Java KeyEvent VK_* key code mappings
/// Reference: https://docs.oracle.com/javase/8/docs/api/java/awt/event/KeyEvent.html
class KeyCodes {
  // Common control keys
  static const int enter = 10;
  static const int backspace = 8;
  static const int tab = 9;
  static const int escape = 27;
  static const int space = 32;
  static const int delete = 127;

  // Modifier keys
  static const int shift = 16;
  static const int control = 17;
  static const int alt = 18;
  static const int meta = 157; // Windows key / Command key

  // Arrow keys
  static const int left = 37;
  static const int up = 38;
  static const int right = 39;
  static const int down = 40;

  // Function keys
  static const int f1 = 112;
  static const int f2 = 113;
  static const int f3 = 114;
  static const int f4 = 115;
  static const int f5 = 116;
  static const int f6 = 117;
  static const int f7 = 118;
  static const int f8 = 119;
  static const int f9 = 120;
  static const int f10 = 121;
  static const int f11 = 122;
  static const int f12 = 123;

  // Letters (uppercase ASCII values)
  static const int a = 65;
  static const int b = 66;
  static const int c = 67;
  static const int d = 68;
  static const int e = 69;
  static const int f = 70;
  static const int g = 71;
  static const int h = 72;
  static const int i = 73;
  static const int j = 74;
  static const int k = 75;
  static const int l = 76;
  static const int m = 77;
  static const int n = 78;
  static const int o = 79;
  static const int p = 80;
  static const int q = 81;
  static const int r = 82;
  static const int s = 83;
  static const int t = 84;
  static const int u = 85;
  static const int v = 86;
  static const int w = 87;
  static const int x = 88;
  static const int y = 89;
  static const int z = 90;

  // Numbers
  static const int num0 = 48;
  static const int num1 = 49;
  static const int num2 = 50;
  static const int num3 = 51;
  static const int num4 = 52;
  static const int num5 = 53;
  static const int num6 = 54;
  static const int num7 = 55;
  static const int num8 = 56;
  static const int num9 = 57;

  // Special editing keys
  static const int home = 36;
  static const int end = 35;
  static const int pageUp = 33;
  static const int pageDown = 34;
  static const int insert = 155;

  // Map of common key names to codes
  static final Map<String, int> _nameToCode = {
    'enter': enter,
    'return': enter,
    'backspace': backspace,
    'tab': tab,
    'escape': escape,
    'esc': escape,
    'space': space,
    'delete': delete,
    'del': delete,
    'shift': shift,
    'control': control,
    'ctrl': control,
    'alt': alt,
    'option': alt,
    'meta': meta,
    'command': meta,
    'cmd': meta,
    'win': meta,
    'windows': meta,
    'left': left,
    'up': up,
    'right': right,
    'down': down,
    'home': home,
    'end': end,
    'pageup': pageUp,
    'pagedown': pageDown,
    'insert': insert,
    'f1': f1,
    'f2': f2,
    'f3': f3,
    'f4': f4,
    'f5': f5,
    'f6': f6,
    'f7': f7,
    'f8': f8,
    'f9': f9,
    'f10': f10,
    'f11': f11,
    'f12': f12,
  };

  /// Get key code from a friendly name (case-insensitive)
  static int? fromName(String name) {
    return _nameToCode[name.toLowerCase()];
  }

  /// Get all available key names
  static List<String> get availableNames => _nameToCode.keys.toList();
}
