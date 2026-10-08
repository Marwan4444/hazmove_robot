import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../modules/robot_control/domain/entities/servo_entity.dart';
import '../../../../../modules/robot_control/domain/repo/robot_control_repo.dart';
import '../robot_control_cubit.dart';

/// Servo-axis responsibility of [RobotControlCubit].
///
/// Owns optimistic servo updates, the per-servo movement guards and the
/// servo safety timers (defensive fallback — normal completion arrives via
/// DONE and unlocks immediately).
mixin ServoControlMixin on Cubit<RobotControlState> {
  RobotControlRepo get repository;

  final Map<int, Timer> servoTimeouts = {}; // key = servo ID

  bool get isConnected =>
      state.connectionStatus == ConnectionStatus.connected;

  /// Speed-aware fallback estimate mirroring the firmware map
  /// (speed 1–100 → 30–2 ms/degree). Clamped ABOVE the repository
  /// DONE-await ceiling (15 s) so the repository timeout always wins first.
  Duration servoSafetyTimeout(int from, int to, int speed) {
    final msPerDegree = 30 - (speed.clamp(1, 100) - 1) * (28 / 99);
    final seconds = ((to - from).abs() * msPerDegree / 1000 * 1.5 + 3).ceil();
    return Duration(seconds: seconds.clamp(16, 40));
  }

  Future<void> moveServo(
      int servoId, int startAngle, int endAngle, int speed) async {
    if (state.robotArm != null) {
      final updatedServos = state.robotArm!.servos.map((s) {
        if (s.id == servoId) {
          return s.copyWith(
            currentAngle: endAngle,
            targetAngle: endAngle,
            speed: speed,
          );
        }
        return s;
      }).toList();
      emit(state.copyWith(
        robotArm: state.robotArm!.copyWith(servos: updatedServos),
      ));
    }

    if (isConnected) {
      final result =
          await repository.moveServo(servoId, startAngle, endAngle, speed);
      result.fold(
        (failure) => emit(state.copyWith(failure: failure)),
        (_) => emit(state.copyWith(clearFailure: true)),
      );
    }
  }

  Future<void> setServoAngle(int servoId, int angle, int speed) async {
    // Guard: ignore command if this servo is already moving
    final servo = state.robotArm?.servos.firstWhere(
      (s) => s.id == servoId,
      orElse: () => const ServoEntity(
        id: -1,
        name: '',
        currentAngle: 0,
        targetAngle: 0,
        speed: 0,
        isMoving: false,
      ),
    );
    if (servo?.isMoving == true) return;
    final startAngle = servo?.currentAngle ?? angle;

    if (state.robotArm != null) {
      final updatedServos = state.robotArm!.servos.map((s) {
        if (s.id == servoId) {
          return s.copyWith(
            currentAngle: angle,
            targetAngle: angle,
            speed: speed,
            isMoving: true,
          );
        }
        return s;
      }).toList();
      emit(state.copyWith(
        robotArm: state.robotArm!.copyWith(servos: updatedServos),
      ));
    }

    // Defensive fallback timer (longer than the repository DONE-await).
    servoTimeouts[servoId]?.cancel();
    servoTimeouts[servoId] = Timer(
      servoSafetyTimeout(startAngle, angle, speed),
      () => onServoTimeout(servoId),
    );

    if (isConnected) {
      final result = await repository.setServoAngle(servoId, angle, speed);
      result.fold(
        (failure) {
          servoTimeouts[servoId]?.cancel();
          unlockServo(servoId);
          emit(state.copyWith(failure: failure));
        },
        (_) {
          // DONE received: motion finished — unlock without waiting for status.
          servoTimeouts[servoId]?.cancel();
          unlockServo(servoId);
          emit(state.copyWith(clearFailure: true));
        },
      );
    }
  }

  /// Updates servo angle in the UI state only (no ESP32 send).
  /// Use during slider drag; call [setServoAngle] on release.
  void updateServoAngleLocally(int servoId, int angle, int speed) {
    if (state.robotArm == null) return;
    final updatedServos = state.robotArm!.servos.map((s) {
      if (s.id == servoId) {
        return s.copyWith(targetAngle: angle, currentAngle: angle, speed: speed);
      }
      return s;
    }).toList();
    emit(state.copyWith(
      robotArm: state.robotArm!.copyWith(servos: updatedServos),
    ));
  }

  void onServoTimeout(int servoId) {
    final locked = state.robotArm?.servos
            .any((s) => s.id == servoId && s.isMoving) ??
        false;
    if (!locked) return; // DONE already unlocked — nothing to do.
    unlockServo(servoId);
    emit(state.copyWith(
      failure: const Failure(
        'Servo did not respond in time. Check the connection and retry.',
        type: FailureType.timeout,
      ),
    ));
  }

  void unlockServo(int servoId) {
    if (state.robotArm == null) return;
    final updatedServos = state.robotArm!.servos.map((s) {
      return s.id == servoId ? s.copyWith(isMoving: false) : s;
    }).toList();
    emit(state.copyWith(
      robotArm: state.robotArm!.copyWith(servos: updatedServos),
    ));
  }

  void cancelServoTimers() {
    for (final t in servoTimeouts.values) {
      t.cancel();
    }
    servoTimeouts.clear();
  }
}
