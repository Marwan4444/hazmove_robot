import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:hazmove_robot/core/error/failure.dart';
import 'package:hazmove_robot/core/network/network_info.dart';
import 'package:hazmove_robot/modules/robot_control/data/models/movement_preset_model.dart';
import 'package:hazmove_robot/modules/robot_control/data/models/robot_arm_model.dart';
import 'package:hazmove_robot/modules/robot_control/data/protocol/robot_response.dart';
import 'package:hazmove_robot/modules/robot_control/data/robot_control_local_data_source.dart';
import 'package:hazmove_robot/modules/robot_control/data/robot_control_remote_data_source.dart';
import 'package:hazmove_robot/modules/robot_control/domain/entities/movement_preset_entity.dart';
import 'package:hazmove_robot/modules/robot_control/domain/entities/robot_arm_entity.dart';
import 'package:hazmove_robot/modules/robot_control/domain/entities/servo_entity.dart';
import 'package:hazmove_robot/modules/robot_control/domain/entities/linear_rail_entity.dart';
import 'package:hazmove_robot/modules/robot_control/domain/entities/base_rotation_entity.dart';
import 'package:hazmove_robot/modules/robot_control/domain/repo/robot_control_repo.dart';

/// Shared test fakes. No hardware, no network, no timers left pending.

/// Firmware-shaped status payload (mirrors `sendStatusToClient()`).
Map<String, dynamic> sampleStatusData({
  String mode = 'manual',
  String status = 'idle',
}) {
  return {
    'servos': [
      for (int i = 1; i <= 5; i++)
        {
          'id': i,
          'name': 'Servo $i',
          'currentAngle': 90,
          'targetAngle': 90,
          'speed': 50,
          'isMoving': false,
        },
    ],
    'linearRail': {
      'currentPosition': 10.0,
      'targetPosition': 10.0,
      'speed': 50,
      'isMoving': false,
    },
    'baseRotation': {
      'currentDegrees': 0.0,
      'targetDegrees': 0.0,
      'speed': 50,
      'isMoving': false,
    },
    'mode': mode,
    'status': status,
    'isConnected': true,
    'lastUpdated': '2026-06-30T18:05:25.000Z',
  };
}

class FakeRemoteDataSource implements RobotRemoteDataSource {
  final connectionController = StreamController<bool>.broadcast();
  final statusController = StreamController<RobotArmModel>.broadcast();
  final responseController = StreamController<RobotResponse>.broadcast();

  final List<Map<String, dynamic>> sentCommands = [];
  final List<String> connectedUrls = [];
  int disconnectCalls = 0;

  /// Hook run on every send (e.g. auto-answer with done). Throwing here
  /// simulates a transport failure.
  Future<void> Function(Map<String, dynamic> command)? onSend;

  @override
  Stream<bool> get connectionStatus => connectionController.stream;

  @override
  Stream<RobotArmModel> get robotStatus => statusController.stream;

  @override
  Stream<RobotResponse> get commandResponses => responseController.stream;

  @override
  Future<void> connect(String url) async {
    connectedUrls.add(url);
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
  }

  @override
  Future<void> sendCommand(Map<String, dynamic> command) async {
    sentCommands.add(Map<String, dynamic>.from(command));
    await onSend?.call(command);
  }

  /// Auto-answer every command carrying a commandId with `done`.
  void autoDone() {
    onSend = (command) async {
      final id = command['commandId']?.toString();
      if (id != null && id.isNotEmpty) {
        responseController.add(DoneResponse(commandId: id));
      }
    };
  }

  void dispose() {
    connectionController.close();
    statusController.close();
    responseController.close();
  }
}

class FakeLocalDataSource implements RobotLocalDataSource {
  List<MovementPresetModel> presets;
  String? connectionUrl;

  FakeLocalDataSource({List<MovementPresetModel>? presets, this.connectionUrl})
      : presets = presets ?? [];

  @override
  Future<List<MovementPresetModel>> getPresets() async => List.of(presets);

  @override
  Future<void> savePresets(List<MovementPresetModel> value) async {
    presets = List.of(value);
  }

  @override
  Future<String?> getConnectionUrl() async => connectionUrl;

  @override
  Future<void> saveConnectionUrl(String url) async {
    connectionUrl = url;
  }
}

class FakeNetworkInfo implements NetworkInfo {
  bool connected;
  FakeNetworkInfo({this.connected = true});

  @override
  Future<bool> get isConnected async => connected;

  @override
  Future<Either<Failure, void>> checkConnection() async => connected
      ? const Right(null)
      : const Left(NetworkFailure('No local network.'));
}

/// A neutral connected arm snapshot for cubit tests.
RobotArmEntity testArm() => RobotArmEntity(
      servos: [
        for (int i = 1; i <= 5; i++)
          ServoEntity(
              id: i,
              name: 'Servo $i',
              currentAngle: 90,
              targetAngle: 90,
              speed: 50,
              isMoving: false),
      ],
      linearRail: const LinearRailEntity(
          currentPosition: 10,
          targetPosition: 10,
          speed: 50,
          isMoving: false),
      baseRotation: const BaseRotationEntity(
          currentDegrees: 0, targetDegrees: 0, speed: 50, isMoving: false),
      lastUpdated: DateTime(2026, 1, 1),
    );

/// Controllable [RobotControlRepo] for cubit tests.
class FakeRobotControlRepo implements RobotControlRepo {
  final connectionController =
      StreamController<Either<Failure, bool>>.broadcast();
  final statusController =
      StreamController<Either<Failure, RobotArmEntity>>.broadcast();

  Future<Either<Failure, void>> Function(String url)? onConnect;
  Future<Either<Failure, void>> Function()? onDisconnect;
  Future<Either<Failure, RobotArmEntity>> Function()? onGetStatus;
  Future<Either<Failure, void>> Function(
      int servoId, int angle, int speed)? onSetServo;
  Future<Either<Failure, void>> Function(double position, int speed)?
      onSetLinear;
  Future<Either<Failure, void>> Function(double degrees, int speed)? onSetBase;
  Future<Either<Failure, void>> Function()? onStop;
  Future<Either<Failure, void>> Function()? onPause;
  Future<Either<Failure, void>> Function()? onResume;
  Future<Either<Failure, void>> Function(String mode)? onSetMode;
  Future<Either<Failure, void>> Function(String presetId)? onExecutePreset;

  int setServoCalls = 0;
  int setLinearCalls = 0;
  int setBaseCalls = 0;
  final List<String> modeCalls = [];

  @override
  Stream<Either<Failure, bool>> get connectionStatus =>
      connectionController.stream;

  @override
  Stream<Either<Failure, RobotArmEntity>> get robotStatus =>
      statusController.stream;

  @override
  Future<Either<Failure, void>> connect(String url) =>
      onConnect?.call(url) ?? Future.value(const Right(null));

  @override
  Future<Either<Failure, void>> disconnect() =>
      onDisconnect?.call() ?? Future.value(const Right(null));

  @override
  Future<Either<Failure, RobotArmEntity>> getCurrentStatus() =>
      onGetStatus?.call() ??
      Future.value(Left(Failure('not stubbed',
          type: FailureType.unknown)));

  @override
  Future<Either<Failure, String?>> getConnectionUrl() =>
      Future.value(const Right(null));

  @override
  Future<Either<Failure, void>> moveServo(
          int servoId, int startAngle, int endAngle, int speed) =>
      setServoAngle(servoId, endAngle, speed);

  @override
  Future<Either<Failure, void>> setServoAngle(
      int servoId, int angle, int speed) {
    setServoCalls++;
    return onSetServo?.call(servoId, angle, speed) ??
        Future.value(const Right(null));
  }

  @override
  Future<Either<Failure, void>> moveLinearRail(double distance, int speed,
          {Duration? timeout}) =>
      setLinearPosition(distance, speed);

  @override
  Future<Either<Failure, void>> setLinearPosition(double position, int speed,
      {Duration? timeout}) {
    setLinearCalls++;
    return onSetLinear?.call(position, speed) ??
        Future.value(const Right(null));
  }

  @override
  Future<Either<Failure, void>> rotateBase(double degrees, int speed) =>
      setBaseRotation(degrees, speed);

  @override
  Future<Either<Failure, void>> setBaseRotation(double degrees, int speed) {
    setBaseCalls++;
    return onSetBase?.call(degrees, speed) ??
        Future.value(const Right(null));
  }

  @override
  Future<Either<Failure, List<MovementPresetEntity>>> getPresets() =>
      Future.value(const Right(<MovementPresetEntity>[]));

  @override
  Future<Either<Failure, void>> savePreset(MovementPresetEntity preset) =>
      Future.value(const Right(null));

  @override
  Future<Either<Failure, void>> deletePreset(String presetId) =>
      Future.value(const Right(null));

  @override
  Future<Either<Failure, void>> executePreset(String presetId) =>
      onExecutePreset?.call(presetId) ?? Future.value(const Right(null));

  @override
  Future<Either<Failure, void>> cancelPresetExecution(int executionId) =>
      Future.value(const Right(null));

  @override
  Future<Either<Failure, void>> stopAllMovements() =>
      onStop?.call() ?? Future.value(const Right(null));

  @override
  Future<Either<Failure, void>> pauseMovements() =>
      onPause?.call() ?? Future.value(const Right(null));

  @override
  Future<Either<Failure, void>> resumeMovements() =>
      onResume?.call() ?? Future.value(const Right(null));

  @override
  Future<Either<Failure, void>> setMode(String mode) {
    modeCalls.add(mode);
    return onSetMode?.call(mode) ?? Future.value(const Right(null));
  }

  void dispose() {
    connectionController.close();
    statusController.close();
  }
}
