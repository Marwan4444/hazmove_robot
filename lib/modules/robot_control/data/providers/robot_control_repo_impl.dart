import 'dart:async';
import 'package:fpdart/fpdart.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/robot_arm_entity.dart';
import '../../domain/entities/movement_preset_entity.dart';
import '../../domain/repo/robot_control_repo.dart';
import '../robot_control_remote_data_source.dart';
import '../robot_control_local_data_source.dart';
import '../models/robot_arm_model.dart';
import '../models/movement_preset_model.dart';
import '../models/servo_model.dart';
import '../models/linear_rail_model.dart';
import '../models/base_rotation_model.dart';
import '../mappers/preset_mapper.dart';
import '../mappers/robot_arm_mapper.dart';
import '../protocol/command_tracker.dart';
import '../protocol/robot_command.dart';
import '../protocol/robot_response.dart';

class RobotControlRepoImpl implements RobotControlRepo {
  final RobotRemoteDataSource remoteDataSource;
  final RobotLocalDataSource localDataSource;

  /// Correlates outbound `commandId`s with inbound terminal frames.
  final CommandTracker commandTracker = CommandTracker();
  StreamSubscription<RobotResponse>? _responseSub;

  /// Generous per-command ceilings. The UI safety timers (cubit) are
  /// deliberately LONGER so the repository timeout always wins first and the
  /// cubit timer stays a purely defensive fallback.
  static const Duration servoAwaitTimeout = Duration(seconds: 15);
  static const Duration baseAwaitTimeout = Duration(seconds: 30);
  static const Duration linearAwaitTimeout = Duration(seconds: 120);
  static const Duration controlAwaitTimeout = Duration(seconds: 10);

  RobotControlRepoImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  }) {
    _responseSub =
        remoteDataSource.commandResponses.listen(commandTracker.resolve);
  }

  @override
  Stream<Either<Failure, bool>> get connectionStatus =>
      remoteDataSource.connectionStatus.transform(
        StreamTransformer<bool, Either<Failure, bool>>.fromHandlers(
          handleData: (data, sink) => sink.add(Right(data)),
          handleError: (error, stackTrace, sink) => sink.add(Left(Failure.fromException(error))),
        )
      ).asBroadcastStream();

  @override
  Stream<Either<Failure, RobotArmEntity>> get robotStatus =>
      remoteDataSource.robotStatus.transform(
        StreamTransformer<RobotArmModel, Either<Failure, RobotArmEntity>>.fromHandlers(
          handleData: (data, sink) => sink.add(Right(data)),
          handleError: (error, stackTrace, sink) => sink.add(Left(Failure.fromException(error))),
        )
      ).asBroadcastStream();

  @override
  Future<Either<Failure, void>> connect(String url) async {
    try {
      await remoteDataSource.connect(url);
      await localDataSource.saveConnectionUrl(url);
      return const Right(null);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> disconnect() async {
    try {
      await remoteDataSource.disconnect();
      return const Right(null);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, String?>> getConnectionUrl() async {
    try {
      final url = await localDataSource.getConnectionUrl();
      return Right(url);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, RobotArmEntity>> getCurrentStatus() async {
    try {
      // Return a default baseline state when requested, status is live updated via streams
      final robotArm = RobotArmModel(
        servos: const [
          // Names match ESP32 sendStatusToClient(), angles match InitialPosition()
          ServoModel(id: 1, name: 'Base Servo',     currentAngle: 0,   targetAngle: 0,   speed: 50, isMoving: false), // HandFB   → 0°
          ServoModel(id: 2, name: 'Shoulder Servo', currentAngle: 90,  targetAngle: 90,  speed: 50, isMoving: false), // MoveArm  → 90° (mapped)
          ServoModel(id: 3, name: 'Elbow Servo',    currentAngle: 180, targetAngle: 180, speed: 50, isMoving: false), // HandUD   → 180°
          ServoModel(id: 4, name: 'Wrist Servo',    currentAngle: 150, targetAngle: 150, speed: 50, isMoving: false), // HandR    → 150°
          ServoModel(id: 5, name: 'Gripper Servo',  currentAngle: 180, targetAngle: 180, speed: 50, isMoving: false), // HandOC   → 180°
        ],
        linearRail: const LinearRailModel(
          currentPosition: 0.0,
          targetPosition: 0.0,
          speed: 50,
          isMoving: false,
        ),
        baseRotation: const BaseRotationModel(
          currentDegrees: 0.0,
          targetDegrees: 0.0,
          speed: 50,
          isMoving: false,
        ),
        lastUpdated: DateTime.now(),
      );
      return Right(robotArm);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  /// Sends a typed command and awaits its terminal frame.
  ///
  /// Normal completion resolves via `DONE`; `REJECT`/`ERROR` map to typed
  /// failures; no terminal frame within [timeout] maps to a timeout failure.
  /// Client-side range violations fail fast without touching the socket.
  Future<Either<Failure, void>> _sendAndAwait(
    RobotCommand command, {
    required Duration timeout,
  }) async {
    final valid = command.validate();
    if (valid.isLeft()) {
      return Left(valid.fold((l) => l, (_) => Failure('Invalid command')));
    }
    final pending =
        commandTracker.track(command.commandId, timeout: timeout);
    try {
      await remoteDataSource.sendCommand(command.toJson());
    } catch (e) {
      commandTracker.cancel(command.commandId);
      return Left(Failure.fromException(e));
    }
    try {
      final response = await pending;
      if (response is DoneResponse) return const Right(null);
      if (response is RejectResponse) {
        return Left(Failure(
          _rejectMessage(response.reason),
          type: FailureType.rejected,
        ));
      }
      if (response is ErrorResponse) {
        return Left(Failure(
          'Robot error: ${response.reason}',
          type: FailureType.firmwareError,
        ));
      }
      return const Left(
          Failure('Unexpected robot response.', type: FailureType.unknown));
    } on TimeoutException catch (e) {
      return Left(Failure(
        'Robot did not confirm the command in time (${e.duration}).',
        type: FailureType.timeout,
      ));
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  static String _rejectMessage(String reason) {
    switch (reason) {
      case RobotCommands.reasonOutOfRange:
        return 'Target is outside the robot safety limits.';
      case RobotCommands.reasonInvalidServoId:
        return 'Unknown servo ID.';
      case RobotCommands.reasonBusy:
        return 'Robot is busy. Wait for the current movement to finish.';
      case RobotCommands.reasonInvalidMode:
        return 'Unknown robot mode.';
      case RobotCommands.reasonSequenceNotImplemented:
        return 'Auto Mode 2 is not available on this robot yet.';
      case RobotCommands.reasonMissingField:
        return 'Command was missing a required field.';
      case RobotCommands.reasonUnknownCommand:
        return 'Robot did not understand the command.';
      default:
        return 'Robot rejected the command ($reason).';
    }
  }

  @override
  Future<Either<Failure, void>> moveServo(
      int servoId, int startAngle, int endAngle, int speed) {
    // NOTE: `startAngle` is kept for interface stability; the firmware reads
    // the live position via `servo.read()` and only needs `end`.
    return _sendAndAwait(
      ServoCommand(servoId: servoId, endAngle: endAngle, speed: speed),
      timeout: servoAwaitTimeout,
    );
  }

  @override
  Future<Either<Failure, void>> setServoAngle(
      int servoId, int angle, int speed) {
    return _sendAndAwait(
      ServoCommand(servoId: servoId, endAngle: angle, speed: speed),
      timeout: servoAwaitTimeout,
    );
  }

  @override
  Future<Either<Failure, void>> moveLinearRail(double distance, int speed,
      {Duration? timeout}) {
    return _sendAndAwait(
      LinearCommand(distance: distance, speed: speed),
      timeout: timeout ?? linearAwaitTimeout,
    );
  }

  @override
  Future<Either<Failure, void>> setLinearPosition(double position, int speed,
      {Duration? timeout}) {
    return _sendAndAwait(
      LinearCommand(distance: position, speed: speed),
      timeout: timeout ?? linearAwaitTimeout,
    );
  }

  @override
  Future<Either<Failure, void>> rotateBase(double degrees, int speed) {
    return _sendAndAwait(
      BaseCommand(degrees: degrees, speed: speed),
      timeout: baseAwaitTimeout,
    );
  }

  @override
  Future<Either<Failure, void>> setBaseRotation(double degrees, int speed) {
    return _sendAndAwait(
      BaseCommand(degrees: degrees, speed: speed),
      timeout: baseAwaitTimeout,
    );
  }

  bool _isPresetCancelled = false;

  @override
  Future<Either<Failure, void>> stopAllMovements() {
    _isPresetCancelled = true;
    return _sendAndAwait(StopCommand(), timeout: controlAwaitTimeout);
  }

  @override
  Future<Either<Failure, void>> pauseMovements() {
    return _sendAndAwait(PauseCommand(), timeout: controlAwaitTimeout);
  }

  @override
  Future<Either<Failure, void>> resumeMovements() {
    return _sendAndAwait(ResumeCommand(), timeout: controlAwaitTimeout);
  }

  @override
  Future<Either<Failure, List<MovementPresetEntity>>> getPresets() async {
    try {
      final presets = await localDataSource.getPresets();
      return Right(presets);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> savePreset(MovementPresetEntity preset) async {
    try {
      final presets = await localDataSource.getPresets();
      final presetModel = preset.toModel();
      final updatedPresets = [...presets.where((p) => p.id != preset.id), presetModel];
      await localDataSource.savePresets(updatedPresets);
      return const Right(null);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> deletePreset(String presetId) async {
    try {
      final presets = await localDataSource.getPresets();
      final updatedPresets = presets.where((p) => p.id != presetId).toList();
      await localDataSource.savePresets(updatedPresets);
      return const Right(null);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  /// Builds a typed, validated command from a stored preset step.
  /// Falls back to [RawCommand] for unknown step types so the firmware —
  /// not the app — decides (via `reject`) whether the step is legal.
  RobotCommand _commandFromStep(String type, Map<String, dynamic> params) {
    int speedOf(Map<String, dynamic> p) =>
        (p['speed'] as num?)?.toInt() ?? 50;
    try {
      switch (type) {
        case RobotCommands.servo:
          return ServoCommand(
            servoId: (params['servo_id'] as num).toInt(),
            endAngle: (params['end'] as num).toInt(),
            speed: speedOf(params),
          );
        case RobotCommands.linear:
          return LinearCommand(
            distance: (params['distance'] as num).toDouble(),
            speed: speedOf(params),
          );
        case RobotCommands.base:
          return BaseCommand(
            degrees: (params['degrees'] as num).toDouble(),
            speed: speedOf(params),
          );
        case RobotCommands.stop:
          return StopCommand();
        case RobotCommands.pause:
          return PauseCommand();
        case RobotCommands.resume:
          return ResumeCommand();
        case RobotCommands.mode:
          return ModeCommand(params['mode']?.toString() ?? RobotModes.manual);
        default:
          return RawCommand(type: type, parameters: params);
      }
    } catch (_) {
      return RawCommand(type: type, parameters: params);
    }
  }

  @override
  Future<Either<Failure, void>> executePreset(String presetId) async {
    try {
      _isPresetCancelled = false;
      final presets = await localDataSource.getPresets();
      final preset = presets.firstWhere((p) => p.id == presetId);

      for (final step in preset.steps) {
        if (_isPresetCancelled) break;

        final command = _commandFromStep(step.type, step.parameters);
        final result = await _sendAndAwait(command,
            timeout: _presetStepTimeout(command));
        if (result.isLeft()) {
          return result;
        }

        if (step.delayMs > 0) {
          final intervals = (step.delayMs / 100).ceil();
          for (int i = 0; i < intervals; i++) {
            if (_isPresetCancelled) break;
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }
        if (_isPresetCancelled) break;
      }
      if (_isPresetCancelled) {
        return const Left(
            Failure('Preset execution cancelled.', type: FailureType.cancelled));
      }
      return const Right(null);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  static Duration _presetStepTimeout(RobotCommand command) {
    if (command is LinearCommand) return linearAwaitTimeout;
    if (command is BaseCommand) return baseAwaitTimeout;
    if (command is ServoCommand) return servoAwaitTimeout;
    return controlAwaitTimeout;
  }

  @override
  Future<Either<Failure, void>> setMode(String mode) {
    return _sendAndAwait(ModeCommand(mode), timeout: controlAwaitTimeout);
  }

  /// Releases the command-response subscription. Call on app teardown.
  Future<void> dispose() async {
    await _responseSub?.cancel();
  }
}
