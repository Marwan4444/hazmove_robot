import 'dart:math';

/// Generates unique command IDs for correlating
/// `command → ACK → DONE/REJECT/ERROR` (see `docs/protocol.md` §4).
///
/// Format: `<microsecondsSinceEpoch>-<counter>-<random>` — unique without any
/// external dependency (no `uuid` package needed).
abstract class CommandId {
  static int _counter = 0;
  static final Random _random = Random();

  static String newId() {
    final micros = DateTime.now().microsecondsSinceEpoch;
    final count = (_counter++ & 0xFFFFF);
    final rand = _random.nextInt(0xFFFFFF);
    return '$micros-$count-${rand.toRadixString(16)}';
  }

  /// Resets the counter. Visible for tests only.
  static void resetForTest() => _counter = 0;
}
