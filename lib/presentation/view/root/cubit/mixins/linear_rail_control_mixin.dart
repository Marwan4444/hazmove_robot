import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../modules/robot_control/domain/repo/robot_control_repo.dart';
import '../robot_control_cubit.dart';

/// Linear-rail responsibility of [RobotControlCubit].
///
/// Owns optimistic rail updates, the rail movement guard and the rail
/// safety timer (defensive fallback — normal completion arrives via DONE).
mixin LinearRailControlMixin on Cubit<RobotControlState> {
  RobotControlRepo get repository;

  Timer? linearRailTimeout;

  bool get isConnected =>
      state.connectionStatus == ConnectionStatus.connected;

  Future<void> moveLinearRail(double distance, int speed) async {
    if (state.robotArm != null) {
      emit(state.copyWith(
        robotArm: state.robotArm!.copyWith(
          linearRail: state.robotArm!.linearRail.copyWith(
            currentPosition: distance,
            targetPosition: distance,
            speed: speed,
          ),
        ),
      ));
    }

    if (isConnected) {
      final result = await repository.moveLinearRail(distance, speed);
      result.fold(
        (failure) => emit(state.copyWith(failure: failure)),
        (_) => emit(state.copyWith(clearFailure: true)),
      );
    }
  }

  Future<void> setLinearPosition(double position, int speed) async {
    // Guard: ignore command if linear rail is already moving
    if (state.robotArm?.linearRail.isMoving == true) return;

    final currentPos = state.robotArm?.linearRail.currentPosition ?? 0.0;

    if (state.robotArm != null) {
      emit(state.copyWith(
        robotArm: state.robotArm!.copyWith(
          linearRail: state.robotArm!.linearRail.copyWith(
            currentPosition: position,
            targetPosition: position,
            speed: speed,
            isMoving: true,
          ),
        ),
      ));
    }

    // Repository DONE-await, scaled from the requested travel distance.
    // TODO(hardware): calibrate against measured rail speed; the 0.8 s/cm
    // estimate predates the ACK protocol and slow full-length moves at
    // speed 1 can legitimately exceed it (firmware keeps moving regardless).
    final distanceCm = (position - currentPos).abs();
    final awaitSeconds = ((distanceCm * 0.8 * 1.5).ceil()).clamp(5, 120);
    // Cubit fallback stays strictly longer than the repository timeout.
    linearRailTimeout?.cancel();
    linearRailTimeout = Timer(
      Duration(seconds: awaitSeconds + 15),
      onLinearRailTimeout,
    );

    if (isConnected) {
      final result = await repository.setLinearPosition(
        position,
        speed,
        timeout: Duration(seconds: awaitSeconds),
      );
      result.fold(
        (failure) {
          linearRailTimeout?.cancel();
          unlockLinearRail();
          emit(state.copyWith(failure: failure));
        },
        (_) {
          linearRailTimeout?.cancel();
          unlockLinearRail();
          emit(state.copyWith(clearFailure: true));
        },
      );
    }
  }

  /// Updates linear rail position in the UI state only (no ESP32 send).
  /// Use during slider drag; call [setLinearPosition] on release.
  void updateLinearPositionLocally(double position) {
    if (state.robotArm == null) return;
    emit(state.copyWith(
      robotArm: state.robotArm!.copyWith(
        linearRail: state.robotArm!.linearRail.copyWith(
          targetPosition: position,
          currentPosition: position,
        ),
      ),
    ));
  }

  void onLinearRailTimeout() {
    if (state.robotArm?.linearRail.isMoving != true) return;
    unlockLinearRail();
    emit(state.copyWith(
      failure: const Failure(
        'Linear rail did not respond in time. Check the connection and retry.',
        type: FailureType.timeout,
      ),
    ));
  }

  void unlockLinearRail() {
    if (state.robotArm == null) return;
    emit(state.copyWith(
      robotArm: state.robotArm!.copyWith(
        linearRail: state.robotArm!.linearRail.copyWith(isMoving: false),
      ),
    ));
  }

  void cancelLinearRailTimer() {
    linearRailTimeout?.cancel();
    linearRailTimeout = null;
  }
}
