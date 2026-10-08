import '../../../../core/constants/app_constants.dart';
import '../models/robot_arm_model.dart';

/// Typed robot responses (ESP32 → Flutter). See `docs/protocol.md` §3.
///
/// The protocol explicitly distinguishes:
/// - [AckResponse] — command accepted, motion starting.
/// - [DoneResponse] — command completed normally.
/// - [RejectResponse] — command refused without execution (with [reason]).
/// - [ErrorResponse] — command failed during/after acceptance (with [reason]).
/// - [StatusResponse] — periodic snapshot, throttled, never throttled-through
///   for command correlation (carries no `commandId`).
abstract class RobotResponse {
  /// Response type string (`ack` / `done` / `reject` / `error` / `status`).
  String get type;

  /// Echoed correlation ID, or `null` for legacy frames / status snapshots.
  String? get commandId;

  /// `true` for [DoneResponse], [RejectResponse] and [ErrorResponse] —
  /// frames that terminate a tracked command.
  bool get isTerminal => false;

  /// Parses one inbound JSON frame.
  ///
  /// Throws [FormatException] for unknown types, non-map payloads, or
  /// `ack`/`done`/`reject`/`error` frames missing a `commandId`.
  /// `status` frames are parsed into [StatusResponse].
  static RobotResponse fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString();
    switch (type) {
      case RobotCommands.ack:
        return AckResponse(commandId: _requireCommandId(json));
      case RobotCommands.done:
        return DoneResponse(commandId: _requireCommandId(json));
      case RobotCommands.reject:
        return RejectResponse(
          commandId: _requireCommandId(json),
          reason: json[RobotCommands.reason]?.toString() ?? 'UNKNOWN',
        );
      case RobotCommands.error:
        return ErrorResponse(
          commandId: _requireCommandId(json),
          reason: json[RobotCommands.reason]?.toString() ?? 'UNKNOWN',
        );
      case RobotCommands.status:
        final data = json['data'];
        return StatusResponse(
          robotArm: RobotArmModel.fromJson(
            data is Map<String, dynamic> ? data : <String, dynamic>{},
          ),
        );
      default:
        throw FormatException('Unknown response type: $type');
    }
  }

  static String _requireCommandId(Map<String, dynamic> json) {
    final id = json[RobotCommands.commandId]?.toString();
    if (id == null || id.isEmpty) {
      throw FormatException(
          'Response type "${json['type']}" is missing commandId');
    }
    return id;
  }
}

class AckResponse extends RobotResponse {
  @override
  String get type => RobotCommands.ack;
  @override
  final String commandId;

  AckResponse({required this.commandId});
}

class DoneResponse extends RobotResponse {
  @override
  String get type => RobotCommands.done;
  @override
  final String commandId;

  DoneResponse({required this.commandId});

  @override
  bool get isTerminal => true;
}

class RejectResponse extends RobotResponse {
  @override
  String get type => RobotCommands.reject;
  @override
  final String commandId;
  final String reason;

  RejectResponse({required this.commandId, required this.reason});

  @override
  bool get isTerminal => true;
}

class ErrorResponse extends RobotResponse {
  @override
  String get type => RobotCommands.error;
  @override
  final String commandId;
  final String reason;

  ErrorResponse({required this.commandId, required this.reason});

  @override
  bool get isTerminal => true;
}

class StatusResponse extends RobotResponse {
  @override
  String get type => RobotCommands.status;
  @override
  String? get commandId => null;

  final RobotArmModel robotArm;

  StatusResponse({required this.robotArm});
}
