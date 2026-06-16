import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../models/robot_arm_model.dart';
import '../models/movement_preset_model.dart';

abstract class RobotControlRepo {
  Stream<Either<Failure, bool>> get connectionStatus;
  Stream<Either<Failure, RobotArmModel>> get robotStatus;
  
  Future<Either<Failure, void>> connect(String url);
  Future<Either<Failure, void>> disconnect();
  Future<Either<Failure, RobotArmModel>> getCurrentStatus();
  
  // Controls
  Future<Either<Failure, void>> moveServo(int servoId, int startAngle, int endAngle, int speed);
  Future<Either<Failure, void>> setServoAngle(int servoId, int angle, int speed);
  Future<Either<Failure, void>> moveLinearRail(double distance, int speed);
  Future<Either<Failure, void>> setLinearPosition(double position, int speed);
  Future<Either<Failure, void>> rotateBase(double degrees, int speed);
  Future<Either<Failure, void>> setBaseRotation(double degrees, int speed);
  
  // Preset operations
  Future<Either<Failure, List<MovementPresetModel>>> getPresets();
  Future<Either<Failure, void>> savePreset(MovementPresetModel preset);
  Future<Either<Failure, void>> deletePreset(String presetId);
  Future<Either<Failure, void>> executePreset(String presetId);
  
  // Special controls
  Future<Either<Failure, void>> stopAllMovements();
  Future<Either<Failure, void>> pauseMovements();
  Future<Either<Failure, void>> resumeMovements();
  Future<Either<Failure, void>> setMode(String mode);
}
