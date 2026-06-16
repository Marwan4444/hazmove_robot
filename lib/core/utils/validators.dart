import 'package:fpdart/fpdart.dart';
import '../error/failure.dart';

class Validators {
  static Either<Failure, int> validateServoAngle(int angle) {
    if (angle < 0 || angle > 180) {
      return const Left(Failure('Servo angle must be between 0 and 180', type: FailureType.invalidInput));
    }
    return Right(angle);
  }

  static Either<Failure, double> validateLinearDistance(double distance) {
    if (distance < 0 || distance > 100) {
      return const Left(Failure('Linear distance must be between 0 and 100 cm', type: FailureType.invalidInput));
    }
    return Right(distance);
  }

  static Either<Failure, double> validateBaseRotation(double degrees) {
    if (degrees < 0 || degrees > 360) {
      return const Left(Failure('Base rotation must be between 0 and 360 degrees', type: FailureType.invalidInput));
    }
    return Right(degrees);
  }

  static Either<Failure, int> validateSpeed(int speed) {
    if (speed < 1 || speed > 100) {
      return const Left(Failure('Speed must be between 1 and 100', type: FailureType.invalidInput));
    }
    return Right(speed);
  }

  static Either<Failure, String> validateWebSocketUrl(String url) {
    if (!url.startsWith('ws://') && !url.startsWith('wss://')) {
      return const Left(Failure('Invalid WebSocket URL format', type: FailureType.invalidInput));
    }
    return Right(url);
  }
}
