import 'package:flutter_test/flutter_test.dart';
import 'package:hazmove_robot/core/error/failure.dart';
import 'package:hazmove_robot/core/utils/validators.dart';

void main() {
  group('Validators honor the verified firmware limits', () {
    test('linear rail: 0-45 cm', () {
      expect(Validators.validateLinearDistance(0).isRight(), isTrue);
      expect(Validators.validateLinearDistance(45).isRight(), isTrue);
      expect(Validators.validateLinearDistance(-0.1).isLeft(), isTrue);
      expect(Validators.validateLinearDistance(45.1).isLeft(), isTrue);
      expect(Validators.validateLinearDistance(100).isLeft(), isTrue);
    });

    test('base rotation: -180 to 180 degrees', () {
      expect(Validators.validateBaseRotation(-180).isRight(), isTrue);
      expect(Validators.validateBaseRotation(180).isRight(), isTrue);
      expect(Validators.validateBaseRotation(-180.1).isLeft(), isTrue);
      expect(Validators.validateBaseRotation(180.1).isLeft(), isTrue);
      expect(Validators.validateBaseRotation(360).isLeft(), isTrue);
    });

    test('servo angle and speed ranges', () {
      expect(Validators.validateServoAngle(0).isRight(), isTrue);
      expect(Validators.validateServoAngle(180).isRight(), isTrue);
      expect(Validators.validateServoAngle(181).isLeft(), isTrue);
      expect(Validators.validateSpeed(1).isRight(), isTrue);
      expect(Validators.validateSpeed(100).isRight(), isTrue);
      expect(Validators.validateSpeed(0).isLeft(), isTrue);
    });
  });

  group('Failure.userMessage', () {
    test('never exposes raw dumps for transport failures', () {
      const network = Failure('SocketException: OS Error',
          type: FailureType.noInternet);
      expect(network.userMessage, isNot(contains('SocketException')));

      const timeout =
          Failure('TimeoutException after 0:00:10', type: FailureType.timeout);
      expect(timeout.userMessage, isNot(contains('TimeoutException')));
    });

    test('maps each type to a distinct friendly message', () {
      expect(
          const Failure('x', type: FailureType.disconnected).userMessage,
          contains('not connected'));
      expect(const Failure('x', type: FailureType.cancelled).userMessage,
          contains('cancelled'));
      expect(
          const Failure('OUT', type: FailureType.rejected).userMessage, 'OUT');
      expect(const Failure('boom', type: FailureType.firmwareError).userMessage,
          contains('boom'));
    });
  });
}
