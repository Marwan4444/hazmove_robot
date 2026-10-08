class AppConstants {
  // Network
  static const String defaultWebSocketUrl = 'ws://192.168.4.1:81';
  static const int connectionTimeout = 15000;
  static const int sendTimeout = 5000;
  
  // Robot Arm Limits — MUST match docs/protocol.md §1 and the ESP32
  // firmware constants (MIN_/MAX_*). The firmware is the final safety
  // authority; these Flutter values exist for UX validation only.
  // Verified physical limits: linear 0–45 cm, base −180–180°.
  static const int maxServoAngle = 180;
  static const int minServoAngle = 0;
  static const double maxLinearDistance = 45.0; // cm
  static const double minLinearDistance = 0.0;
  static const double maxBaseRotation = 180.0; // degrees
  static const double minBaseRotation = -180.0;
  
  // Speed Limits
  static const int maxServoSpeed = 100;
  static const int minServoSpeed = 1;
  static const int maxLinearSpeed = 100;
  static const int minLinearSpeed = 1;
  static const int maxBaseSpeed = 100;
  static const int minBaseSpeed = 1;
  
  // UI
  static const String appName = 'HazMove Robot Control';
  static const String version = '1.0.0';
  
  // Storage Keys
  static const String presetsKey = 'robot_presets';
  static const String settingsKey = 'app_settings';
  static const String connectionKey = 'connection_config';
}

class RobotCommands {
  // ── Commands (Flutter → ESP32) ──────────────────────────────────────
  static const String servo = 'servo';
  static const String linear = 'linear';
  static const String base = 'base';
  static const String stop = 'stop';
  static const String pause = 'pause';
  static const String resume = 'resume';
  static const String mode = 'mode';
  // ── Responses (ESP32 → Flutter) ─────────────────────────────────────
  static const String status = 'status';
  static const String ack = 'ack';
  static const String done = 'done';
  static const String reject = 'reject';
  static const String error = 'error';

  // ── Shared JSON keys ────────────────────────────────────────────────
  static const String commandId = 'commandId';
  static const String reason = 'reason';
  static const String statusField = 'status';
  static const String acceptedValue = 'accepted';
  static const String completedValue = 'completed';

  // ── Reject / error reasons (see docs/protocol.md §7) ────────────────
  static const String reasonOutOfRange = 'OUT_OF_RANGE';
  static const String reasonInvalidServoId = 'INVALID_SERVO_ID';
  static const String reasonBusy = 'BUSY';
  static const String reasonInvalidMode = 'INVALID_MODE';
  static const String reasonSequenceNotImplemented = 'SEQUENCE_NOT_IMPLEMENTED';
  static const String reasonMissingField = 'MISSING_FIELD';
  static const String reasonUnknownCommand = 'UNKNOWN_COMMAND';
  static const String reasonInvalidJson = 'INVALID_JSON';
  static const String reasonInterrupted = 'INTERRUPTED';
}

/// Mode values accepted by the `mode` command (see docs/protocol.md §2.7).
/// NOTE: `seq2` is intentionally unsupported — `Sequence2()` is an empty
/// firmware stub. The app must not offer Mode 2 (TODO: implement or remove).
class RobotModes {
  static const String manual = 'manual';
  static const String seq1 = 'seq1';
  static const String seq2 = 'seq2';

  /// Backwards-compatibility alias of [seq1] (legacy clients send `auto`).
  static const String auto = 'auto';
}

class ServoIds {
  static const int base = 1;
  static const int shoulder = 2;
  static const int elbow = 3;
  static const int wrist = 4;
  static const int gripper = 5;
}
