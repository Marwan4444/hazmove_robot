import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/robot_arm_entity.dart';
import '../entities/movement_preset_entity.dart';

abstract class RobotControlRepo {
  Stream<Either<Failure, bool>> get connectionStatus;
  Stream<Either<Failure, RobotArmEntity>> get robotStatus;
  
  Future<Either<Failure, void>> connect(String url);
  Future<Either<Failure, void>> disconnect();
  Future<Either<Failure, RobotArmEntity>> getCurrentStatus();
  
  // Controls
  Future<Either<Failure, void>> moveServo(int servoId, int startAngle, int endAngle, int speed);
  Future<Either<Failure, void>> setServoAngle(int servoId, int angle, int speed);
  Future<Either<Failure, void>> moveLinearRail(double distance, int speed);
  Future<Either<Failure, void>> setLinearPosition(double position, int speed);
  Future<Either<Failure, void>> rotateBase(double degrees, int speed);
  Future<Either<Failure, void>> setBaseRotation(double degrees, int speed);
  
  // Preset operations
  Future<Either<Failure, List<MovementPresetEntity>>> getPresets();
  Future<Either<Failure, void>> savePreset(MovementPresetEntity preset);
  Future<Either<Failure, void>> deletePreset(String presetId);
  Future<Either<Failure, void>> executePreset(String presetId);
  
  // Special controls
  Future<Either<Failure, void>> stopAllMovements();
  Future<Either<Failure, void>> pauseMovements();
  Future<Either<Failure, void>> resumeMovements();
  Future<Either<Failure, void>> setMode(String mode);
}
