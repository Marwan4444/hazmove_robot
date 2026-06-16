import 'dart:async';
import 'package:fpdart/fpdart.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failure.dart';
import '../../domain/models/robot_arm_model.dart';
import '../../domain/models/movement_preset_model.dart';
import '../../domain/models/servo_model.dart';
import '../../domain/models/linear_rail_model.dart';
import '../../domain/models/base_rotation_model.dart';
import '../../domain/repo/robot_control_repo.dart';
import '../robot_control_remote_data_source.dart';
import '../robot_control_local_data_source.dart';

class RobotControlRepoImpl implements RobotControlRepo {
  final RobotRemoteDataSource remoteDataSource;
  final RobotLocalDataSource localDataSource;

  RobotControlRepoImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Stream<Either<Failure, bool>> get connectionStatus =>
      remoteDataSource.connectionStatus.transform(
        StreamTransformer<bool, Either<Failure, bool>>.fromHandlers(
          handleData: (data, sink) => sink.add(Right(data)),
          handleError: (error, stackTrace, sink) => sink.add(Left(Failure.fromException(error))),
        )
      ).asBroadcastStream();

  @override
  Stream<Either<Failure, RobotArmModel>> get robotStatus =>
      remoteDataSource.robotStatus.transform(
        StreamTransformer<RobotArmModel, Either<Failure, RobotArmModel>>.fromHandlers(
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
  Future<Either<Failure, RobotArmModel>> getCurrentStatus() async {
    try {
      // Return a default baseline state when requested, status is live updated via streams
      final robotArm = RobotArmModel(
        servos: const [
          ServoModel(id: 1, name: 'Base', currentAngle: 0, targetAngle: 0, speed: 50, isMoving: false),
          ServoModel(id: 2, name: 'Shoulder', currentAngle: 90, targetAngle: 90, speed: 50, isMoving: false),
          ServoModel(id: 3, name: 'Elbow', currentAngle: 45, targetAngle: 45, speed: 50, isMoving: false),
          ServoModel(id: 4, name: 'Wrist', currentAngle: 0, targetAngle: 0, speed: 50, isMoving: false),
          ServoModel(id: 5, name: 'Gripper', currentAngle: 0, targetAngle: 0, speed: 50, isMoving: false),
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

  @override
  Future<Either<Failure, void>> moveServo(int servoId, int startAngle, int endAngle, int speed) async {
    try {
      final command = {
        'type': RobotCommands.servo,
        'servo_id': servoId,
        'start': startAngle,
        'end': endAngle,
        'speed': speed,
      };
      await remoteDataSource.sendCommand(command);
      return const Right(null);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> setServoAngle(int servoId, int angle, int speed) async {
    try {
      final command = {
        'type': RobotCommands.servo,
        'servo_id': servoId,
        'start': angle,
        'end': angle,
        'speed': speed,
      };
      await remoteDataSource.sendCommand(command);
      return const Right(null);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> moveLinearRail(double distance, int speed) async {
    try {
      final command = {
        'type': RobotCommands.linear,
        'distance': distance,
        'speed': speed,
      };
      await remoteDataSource.sendCommand(command);
      return const Right(null);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> setLinearPosition(double position, int speed) async {
    try {
      final command = {
        'type': RobotCommands.linear,
        'distance': position,
        'speed': speed,
      };
      await remoteDataSource.sendCommand(command);
      return const Right(null);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> rotateBase(double degrees, int speed) async {
    try {
      final command = {
        'type': RobotCommands.base,
        'degrees': degrees,
        'speed': speed,
      };
      await remoteDataSource.sendCommand(command);
      return const Right(null);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> setBaseRotation(double degrees, int speed) async {
    try {
      final command = {
        'type': RobotCommands.base,
        'degrees': degrees,
        'speed': speed,
      };
      await remoteDataSource.sendCommand(command);
      return const Right(null);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> stopAllMovements() async {
    try {
      final command = {'type': RobotCommands.stop};
      await remoteDataSource.sendCommand(command);
      return const Right(null);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> pauseMovements() async {
    try {
      final command = {'type': RobotCommands.pause};
      await remoteDataSource.sendCommand(command);
      return const Right(null);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> resumeMovements() async {
    try {
      final command = {'type': RobotCommands.resume};
      await remoteDataSource.sendCommand(command);
      return const Right(null);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, List<MovementPresetModel>>> getPresets() async {
    try {
      final presets = await localDataSource.getPresets();
      return Right(presets);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> savePreset(MovementPresetModel preset) async {
    try {
      final presets = await localDataSource.getPresets();
      final updatedPresets = [...presets.where((p) => p.id != preset.id), preset];
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

  @override
  Future<Either<Failure, void>> executePreset(String presetId) async {
    try {
      final presets = await localDataSource.getPresets();
      final preset = presets.firstWhere((p) => p.id == presetId);
      
      for (final step in preset.steps) {
        final command = {
          'type': step.type,
          ...step.parameters,
        };
        await remoteDataSource.sendCommand(command);
        
        if (step.delayMs > 0) {
          await Future.delayed(Duration(milliseconds: step.delayMs));
        }
      }
      return const Right(null);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }

  @override
  Future<Either<Failure, void>> setMode(String mode) async {
    try {
      final command = {
        'type': 'mode',
        'mode': mode,
      };
      await remoteDataSource.sendCommand(command);
      return const Right(null);
    } catch (e) {
      return Left(Failure.fromException(e));
    }
  }
}
