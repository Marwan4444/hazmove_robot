import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hazmove_robot/core/error/failure.dart';
import 'package:hazmove_robot/presentation/view/root/cubit/robot_control_cubit.dart';

import '../fakes.dart';

void main() {
  group('RobotControlCubit', () {
    late FakeRobotControlRepo repo;
    late RobotControlCubit cubit;

    setUp(() {
      repo = FakeRobotControlRepo();
      cubit = RobotControlCubit(repository: repo);
    });

    tearDown(() async {
      await cubit.close();
      repo.dispose();
    });

    test('starts disconnected with firmware-range defaults', () {
      expect(cubit.state.connectionStatus, ConnectionStatus.disconnected);
      expect(cubit.state.robotArm, isNotNull);
      // Phase-2 regression guard: defaults must equal firmware limits.
      expect(cubit.state.robotArm!.linearRail.maxPosition, 45.0);
      expect(cubit.state.robotArm!.linearRail.minPosition, 0.0);
      expect(cubit.state.robotArm!.baseRotation.minDegrees, -180.0);
      expect(cubit.state.robotArm!.baseRotation.maxDegrees, 180.0);
    });

    test('connect success moves connecting -> connected', () async {
      final future = cubit.connect('ws://192.168.4.1:81');
      expect(cubit.state.connectionStatus, ConnectionStatus.connecting);
      await future;
      expect(cubit.state.connectionStatus, ConnectionStatus.connected);
      expect(cubit.state.failure, isNull);
    });

    test('connect failure stays disconnected and surfaces the failure',
        () async {
      repo.onConnect = (_) async =>
          const Left(Failure('unreachable', type: FailureType.noInternet));
      await cubit.connect('ws://192.168.4.1:81');
      expect(cubit.state.connectionStatus, ConnectionStatus.disconnected);
      expect(cubit.state.failure, isNotNull);
    });

    test('dropped socket flips state back to disconnected', () async {
      repo.connectionController.add(const Right(true));
      await Future.delayed(Duration.zero);
      expect(cubit.state.connectionStatus, ConnectionStatus.connected);
      repo.connectionController.add(const Right(false));
      await Future.delayed(Duration.zero);
      expect(cubit.state.connectionStatus, ConnectionStatus.disconnected);
    });

    test('status stream updates the arm and clears failures', () async {
      repo.statusController.add(Right(testArm()));
      await Future.delayed(Duration.zero);
      expect(cubit.state.robotArm!.linearRail.currentPosition, 10);
      expect(cubit.state.failure, isNull);
    });

    test('DONE unlocks the servo and clears the failure', () async {
      await cubit.connect('ws://x');
      final pending = cubit.setServoAngle(1, 100, 50);
      // Optimistic lock is visible synchronously.
      expect(
          cubit.state.robotArm!.servos
              .firstWhere((s) => s.id == 1)
              .isMoving,
          isTrue);
      await pending; // fake repo resolves DONE immediately
      final servo =
          cubit.state.robotArm!.servos.firstWhere((s) => s.id == 1);
      expect(servo.isMoving, isFalse);
      expect(servo.targetAngle, 100);
      expect(cubit.state.failure, isNull);
    });

    test('movement guard blocks a second command while moving', () async {
      final gate = Completer<Either<Failure, void>>();
      repo.onSetServo = (_, __, ___) => gate.future;
      await cubit.connect('ws://x');

      final first = cubit.setServoAngle(1, 100, 50);
      await Future.delayed(Duration.zero);
      await cubit.setServoAngle(1, 120, 50); // must be ignored
      expect(repo.setServoCalls, 1);

      gate.complete(const Right(null));
      await first;
      expect(
          cubit.state.robotArm!.servos
              .firstWhere((s) => s.id == 1)
              .isMoving,
          isFalse);
    });

    test('REJECT surfaces a failure and unlocks the axis', () async {
      repo.onSetServo = (_, __, ___) async => const Left(Failure(
          'Target is outside the robot safety limits.',
          type: FailureType.rejected));
      await cubit.connect('ws://x');
      await cubit.setServoAngle(1, 40, 50);
      expect(cubit.state.failure?.type, FailureType.rejected);
      expect(
          cubit.state.robotArm!.servos
              .firstWhere((s) => s.id == 1)
              .isMoving,
          isFalse);
    });

    test('repository timeout failure is surfaced, not swallowed', () async {
      repo.onSetLinear = (_, __) async =>
          const Left(Failure('timed out', type: FailureType.timeout));
      await cubit.connect('ws://x');
      await cubit.setLinearPosition(20, 50);
      expect(cubit.state.failure?.type, FailureType.timeout);
      expect(cubit.state.robotArm!.linearRail.isMoving, isFalse);
    });

    test('safety-timer fallback fires a timeout failure when still locked',
        () async {
      // Simulate a broken response stream: the repo future never resolves,
      // the axis stays locked, so the defensive timer path must report it.
      await cubit.setServoAngle(1, 100, 50); // disconnected: locked, no send
      expect(
          cubit.state.robotArm!.servos
              .firstWhere((s) => s.id == 1)
              .isMoving,
          isTrue);
      cubit.onServoTimeout(1);
      expect(cubit.state.failure?.type, FailureType.timeout);
      expect(
          cubit.state.robotArm!.servos
              .firstWhere((s) => s.id == 1)
              .isMoving,
          isFalse);

      // A second fire after unlock is a no-op (no duplicate failure).
      cubit.clearFailure();
      cubit.onServoTimeout(1);
      expect(cubit.state.failure, isNull);
    });

    test('clearFailure removes the surfaced failure', () async {
      repo.onSetBase = (_, __) async =>
          const Left(Failure('busy', type: FailureType.rejected));
      await cubit.connect('ws://x');
      await cubit.setBaseRotation(10, 50);
      expect(cubit.state.failure, isNotNull);
      cubit.clearFailure();
      expect(cubit.state.failure, isNull);
    });

    test('safety timeout estimates stay above repository ceilings', () {
      // Repository ceilings: servo 15 s, base 30 s. Cubit fallbacks must be
      // strictly longer so the repo timeout always wins first.
      expect(cubit.servoSafetyTimeout(0, 180, 100).inSeconds,
          greaterThan(15));
      expect(cubit.baseSafetyTimeout(-180, 180, 100).inSeconds,
          greaterThan(30));
    });
  });
}
