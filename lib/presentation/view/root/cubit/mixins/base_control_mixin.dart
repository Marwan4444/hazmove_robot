import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../modules/robot_control/domain/repo/robot_control_repo.dart';
import '../robot_control_cubit.dart';

/// Base-rotation responsibility of [RobotControlCubit].
///
/// Owns optimistic base updates, the base movement guard and the base
/// safety timer (defensive fallback — normal completion arrives via DONE).
mixin BaseControlMixin on Cubit<RobotControlState> {
  RobotControlRepo get repository;

  Timer? baseRotationTimeout;

  bool get isConnected =>
      state.connectionStatus == ConnectionStatus.connected;

  /// Speed-aware fallback estimate mirroring the firmware map
  /// (speed 1–100 → 100–2000 steps/s). Clamped ABOVE the repository
  /// DONE-await ceiling (30 s) so the repository timeout always wins first.
  Duration baseSafetyTimeout(double from, double to, int speed) {
    final stepsPerSec = (100 + (speed.clamp(1, 100) - 1) * (1900 / 99));
    const stepsPerDegree = 2.2222222222;
    final seconds =
        ((to - from).abs() * stepsPerDegree / stepsPerSec * 1.5 + 3).ceil();
    return Duration(seconds: seconds.clamp(31, 90));
  }

  Future<void> rotateBase(double degrees, int speed) async {
    if (state.robotArm != null) {
      emit(state.copyWith(
        robotArm: state.robotArm!.copyWith(
          baseRotation: state.robotArm!.baseRotation.copyWith(
            currentDegrees: degrees,
            targetDegrees: degrees,
            speed: speed,
          ),
        ),
      ));
    }

    if (isConnected) {
      final result = await repository.rotateBase(degrees, speed);
      result.fold(
        (failure) => emit(state.copyWith(failure: failure)),
        (_) => emit(state.copyWith(clearFailure: true)),
      );
    }
  }

  Future<void> setBaseRotation(double degrees, int speed) async {
    // Guard: ignore command if base rotation is already moving
    if (state.robotArm?.baseRotation.isMoving == true) return;
    final startDegrees =
        state.robotArm?.baseRotation.currentDegrees ?? degrees;

    if (state.robotArm != null) {
      emit(state.copyWith(
        robotArm: state.robotArm!.copyWith(
          baseRotation: state.robotArm!.baseRotation.copyWith(
            currentDegrees: degrees,
            targetDegrees: degrees,
            speed: speed,
            isMoving: true,
          ),
        ),
      ));
    }

    // Defensive fallback timer (longer than the repository DONE-await).
    baseRotationTimeout?.cancel();
    baseRotationTimeout = Timer(
      baseSafetyTimeout(startDegrees, degrees, speed),
      onBaseRotationTimeout,
    );

    if (isConnected) {
      final result = await repository.setBaseRotation(degrees, speed);
      result.fold(
        (failure) {
          baseRotationTimeout?.cancel();
          unlockBaseRotation();
          emit(state.copyWith(failure: failure));
        },
        (_) {
          baseRotationTimeout?.cancel();
          unlockBaseRotation();
          emit(state.copyWith(clearFailure: true));
        },
      );
    }
  }

  /// Updates base rotation in the UI state only (no ESP32 send).
  /// Use during slider drag; call [setBaseRotation] on release.
  void updateBaseRotationLocally(double degrees, int speed) {
    if (state.robotArm == null) return;
    emit(state.copyWith(
      robotArm: state.robotArm!.copyWith(
        baseRotation: state.robotArm!.baseRotation.copyWith(
          targetDegrees: degrees,
          currentDegrees: degrees,
          speed: speed,
        ),
      ),
    ));
  }

  void onBaseRotationTimeout() {
    if (state.robotArm?.baseRotation.isMoving != true) return;
    unlockBaseRotation();
    emit(state.copyWith(
      failure: const Failure(
        'Base rotation did not respond in time. Check the connection and retry.',
        type: FailureType.timeout,
      ),
    ));
  }

  void unlockBaseRotation() {
    if (state.robotArm == null) return;
    emit(state.copyWith(
      robotArm: state.robotArm!.copyWith(
        baseRotation: state.robotArm!.baseRotation.copyWith(isMoving: false),
      ),
    ));
  }

  void cancelBaseRotationTimer() {
    baseRotationTimeout?.cancel();
    baseRotationTimeout = null;
  }
}
