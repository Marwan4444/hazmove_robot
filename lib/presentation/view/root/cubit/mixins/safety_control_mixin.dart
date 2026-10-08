import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../modules/robot_control/domain/repo/robot_control_repo.dart';
import '../robot_control_cubit.dart';

/// Safety responsibility of [RobotControlCubit].
///
/// Emergency stop, pause/resume and mode switching. These commands bypass
/// movement guards by design — stop must always go through, even mid-motion.
mixin SafetyControlMixin on Cubit<RobotControlState> {
  RobotControlRepo get repository;

  bool get isConnected =>
      state.connectionStatus == ConnectionStatus.connected;

  Future<void> stopAllMovements() async {
    if (state.robotArm != null) {
      final stoppedServos =
          state.robotArm!.servos.map((s) => s.copyWith(isMoving: false)).toList();
      emit(state.copyWith(
        isPaused: false,
        robotArm: state.robotArm!.copyWith(
          servos: stoppedServos,
          linearRail: state.robotArm!.linearRail.copyWith(isMoving: false),
          baseRotation: state.robotArm!.baseRotation.copyWith(isMoving: false),
        ),
      ));
    }

    if (isConnected) {
      emit(state.copyWith(isLoading: true));
      final result = await repository.stopAllMovements();
      result.fold(
        (failure) => emit(state.copyWith(isLoading: false, failure: failure)),
        (_) => emit(state.copyWith(isLoading: false, isPaused: false)),
      );
    }
  }

  Future<void> pauseMovements() async {
    emit(state.copyWith(isPaused: true));
    if (isConnected) {
      final result = await repository.pauseMovements();
      result.fold(
        (failure) => emit(state.copyWith(failure: failure)),
        (_) => null,
      );
    }
  }

  Future<void> resumeMovements() async {
    emit(state.copyWith(isPaused: false));
    if (isConnected) {
      final result = await repository.resumeMovements();
      result.fold(
        (failure) => emit(state.copyWith(failure: failure)),
        (_) => null,
      );
    }
  }

  Future<void> setMode(String mode) async {
    if (isConnected) {
      final result = await repository.setMode(mode);
      result.fold(
        (failure) => emit(state.copyWith(failure: failure)),
        (_) => null,
      );
    }
  }
}
