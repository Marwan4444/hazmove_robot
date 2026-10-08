import 'package:fpdart/fpdart.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failure.dart';
import 'command_id.dart';

/// Typed robot commands (Flutter → ESP32).
///
/// Replaces scattered raw maps like `{"type": "servo", ...}` with validated,
/// serializable command objects. Every command carries a [commandId] used to
/// correlate `ACK → DONE/REJECT/ERROR` (see `docs/protocol.md`).
///
/// Client-side [validate] mirrors the authoritative firmware limits for fast
/// UX feedback. The firmware remains the final safety authority and rejects
/// out-of-range commands with a `reject` frame.
abstract class RobotCommand {
  /// Command type string sent as `type` (one of [RobotCommands]).
  String get type;

  /// Unique correlation ID echoed by the firmware in every response.
  String get commandId;

  /// Full JSON payload, including [commandId].
  Map<String, dynamic> toJson();

  /// Fast local range check. Returns the command on success so call-sites
  /// can chain: `cmd.validate().fold(fail, send)`.
  Either<Failure, RobotCommand> validate();
}

/// Fallback for preset steps whose type is forwarded verbatim.
class RawCommand extends RobotCommand {
  @override
  final String type;
  @override
  final String commandId;
  final Map<String, dynamic> parameters;

  RawCommand({
    required this.type,
    required this.parameters,
    String? commandId,
  }) : commandId = commandId ?? CommandId.newId();

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        RobotCommands.commandId: commandId,
        ...parameters,
      };

  @override
  Either<Failure, RobotCommand> validate() => Right(this);
}

class ServoCommand extends RobotCommand {
  final int servoId;
  final int endAngle;
  final int speed;

  ServoCommand({
    required this.servoId,
    required this.endAngle,
    this.speed = 50,
    String? commandId,
  }) : commandId = commandId ?? CommandId.newId();

  @override
  String get type => RobotCommands.servo;

  @override
  final String commandId;

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        RobotCommands.commandId: commandId,
        'servo_id': servoId,
        'end': endAngle,
        'speed': speed,
      };

  @override
  Either<Failure, RobotCommand> validate() {
    if (servoId < 1 || servoId > 5) {
      return Left(Failure(
        'Servo ID must be between 1 and 5 (got $servoId).',
        type: FailureType.invalidInput,
      ));
    }
    if (endAngle < AppConstants.minServoAngle ||
        endAngle > AppConstants.maxServoAngle) {
      return Left(Failure(
        'Servo angle must be between ${AppConstants.minServoAngle} and '
        '${AppConstants.maxServoAngle} (got $endAngle).',
        type: FailureType.invalidInput,
      ));
    }
    final speedCheck = _validateSpeed(speed);
    if (speedCheck != null) return Left(speedCheck);
    return Right(this);
  }
}

class LinearCommand extends RobotCommand {
  /// Absolute target position in cm (0–45).
  final double distance;
  final int speed;

  LinearCommand({
    required this.distance,
    this.speed = 50,
    String? commandId,
  }) : commandId = commandId ?? CommandId.newId();

  @override
  String get type => RobotCommands.linear;

  @override
  final String commandId;

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        RobotCommands.commandId: commandId,
        'distance': distance,
        'speed': speed,
      };

  @override
  Either<Failure, RobotCommand> validate() {
    if (distance < AppConstants.minLinearDistance ||
        distance > AppConstants.maxLinearDistance) {
      return Left(Failure(
        'Linear position must be between ${AppConstants.minLinearDistance} '
        'and ${AppConstants.maxLinearDistance} cm (got $distance).',
        type: FailureType.invalidInput,
      ));
    }
    final speedCheck = _validateSpeed(speed);
    if (speedCheck != null) return Left(speedCheck);
    return Right(this);
  }
}

class BaseCommand extends RobotCommand {
  /// Absolute target angle in degrees (−180–180).
  final double degrees;
  final int speed;

  BaseCommand({
    required this.degrees,
    this.speed = 50,
    String? commandId,
  }) : commandId = commandId ?? CommandId.newId();

  @override
  String get type => RobotCommands.base;

  @override
  final String commandId;

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        RobotCommands.commandId: commandId,
        'degrees': degrees,
        'speed': speed,
      };

  @override
  Either<Failure, RobotCommand> validate() {
    if (degrees < AppConstants.minBaseRotation ||
        degrees > AppConstants.maxBaseRotation) {
      return Left(Failure(
        'Base rotation must be between ${AppConstants.minBaseRotation} and '
        '${AppConstants.maxBaseRotation} degrees (got $degrees).',
        type: FailureType.invalidInput,
      ));
    }
    final speedCheck = _validateSpeed(speed);
    if (speedCheck != null) return Left(speedCheck);
    return Right(this);
  }
}

class StopCommand extends RobotCommand {
  StopCommand({String? commandId})
      : commandId = commandId ?? CommandId.newId();

  @override
  String get type => RobotCommands.stop;

  @override
  final String commandId;

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        RobotCommands.commandId: commandId,
      };

  @override
  Either<Failure, RobotCommand> validate() => Right(this);
}

class PauseCommand extends RobotCommand {
  PauseCommand({String? commandId})
      : commandId = commandId ?? CommandId.newId();

  @override
  String get type => RobotCommands.pause;

  @override
  final String commandId;

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        RobotCommands.commandId: commandId,
      };

  @override
  Either<Failure, RobotCommand> validate() => Right(this);
}

class ResumeCommand extends RobotCommand {
  ResumeCommand({String? commandId})
      : commandId = commandId ?? CommandId.newId();

  @override
  String get type => RobotCommands.resume;

  @override
  final String commandId;

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        RobotCommands.commandId: commandId,
      };

  @override
  Either<Failure, RobotCommand> validate() => Right(this);
}

class ModeCommand extends RobotCommand {
  /// One of `manual` / `seq1` (`auto` accepted as legacy alias of `seq1`).
  /// `seq2` is rejected by design — see [RobotModes].
  final String mode;

  ModeCommand(this.mode, {String? commandId})
      : commandId = commandId ?? CommandId.newId();

  @override
  String get type => RobotCommands.mode;

  @override
  final String commandId;

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        RobotCommands.commandId: commandId,
        'mode': mode,
      };

  @override
  Either<Failure, RobotCommand> validate() {
    const allowed = {
      RobotModes.manual,
      RobotModes.seq1,
      RobotModes.auto,
    };
    if (!allowed.contains(mode)) {
      if (mode == RobotModes.seq2) {
        return const Left(Failure(
          'Auto Mode 2 is not available on this robot yet.',
          type: FailureType.invalidInput,
        ));
      }
      return Left(Failure(
        'Unknown mode "$mode". Expected manual or seq1.',
        type: FailureType.invalidInput,
      ));
    }
    return Right(this);
  }
}

Failure? _validateSpeed(int speed) {
  if (speed < AppConstants.minServoSpeed ||
      speed > AppConstants.maxServoSpeed) {
    return Failure(
      'Speed must be between ${AppConstants.minServoSpeed} and '
      '${AppConstants.maxServoSpeed} (got $speed).',
      type: FailureType.invalidInput,
    );
  }
  return null;
}
