import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../modules/robot_control/domain/entities/robot_arm_entity.dart';
import '../../../../modules/robot_control/domain/enums/robot_enums.dart';
import '../../../../modules/robot_control/domain/repo/robot_control_repo.dart';

enum AutoModeType { none, mode1, mode2 }
enum AutoModeState { idle, running, paused }

class AutoModesState extends Equatable {
  final AutoModeType currentMode;
  final AutoModeState modeState;

  const AutoModesState({
    this.currentMode = AutoModeType.none,
    this.modeState = AutoModeState.idle,
  });

  AutoModesState copyWith({
    AutoModeType? currentMode,
    AutoModeState? modeState,
  }) {
    return AutoModesState(
      currentMode: currentMode ?? this.currentMode,
      modeState: modeState ?? this.modeState,
    );
  }

  @override
  List<Object?> get props => [currentMode, modeState];
}

class AutoModesCubit extends Cubit<AutoModesState> {
  final RobotControlRepo _repository;
  StreamSubscription? _statusSub;

  AutoModesCubit({required RobotControlRepo repository})
      : _repository = repository,
        super(const AutoModesState()) {
    _subscribeToStatus();
  }

  void _subscribeToStatus() {
    _statusSub = _repository.robotStatus.listen((result) {
      result.fold(
        (_) => null,
        (robotArm) => _handleRobotStatus(robotArm),
      );
    });
  }

  void _handleRobotStatus(RobotArmEntity robotArm) {
    if (robotArm.mode == RobotMode.seq1) {
      final modeState = robotArm.status == RobotStatus.paused
          ? AutoModeState.paused
          : AutoModeState.running;
      emit(state.copyWith(currentMode: AutoModeType.mode1, modeState: modeState));
    } else if (robotArm.mode == RobotMode.seq2) {
      final modeState = robotArm.status == RobotStatus.paused
          ? AutoModeState.paused
          : AutoModeState.running;
      emit(state.copyWith(currentMode: AutoModeType.mode2, modeState: modeState));
    } else {
      // If robot is in manual or idle, sequence is no longer running on ESP32
      if (state.modeState != AutoModeState.idle || state.currentMode != AutoModeType.none) {
        emit(state.copyWith(
          currentMode: AutoModeType.none,
          modeState: AutoModeState.idle,
        ));
      }
    }
  }

  Future<void> startMode(AutoModeType type) async {
    // TODO(hardware): Mode 2 disabled — Sequence2() is an empty firmware
    // stub and the firmware rejects `seq2` with SEQUENCE_NOT_IMPLEMENTED.
    // Re-enable only with a safety-reviewed Sequence2 choreography
    // (see docs/protocol.md §5).
    if (type == AutoModeType.mode2) return;
    if (state.modeState == AutoModeState.running || state.modeState == AutoModeState.paused) return;
    
    emit(state.copyWith(currentMode: type, modeState: AutoModeState.running));
    
    // ESP32 يقرأ: "seq1" للتسلسل 1، و "seq2" للتسلسل 2
    String modeString = type == AutoModeType.mode1 ? 'seq1' : 'seq2';
    await _repository.setMode(modeString);
  }

  Future<void> pauseMode() async {
    if (state.modeState == AutoModeState.running) {
      emit(state.copyWith(modeState: AutoModeState.paused));
      await _repository.pauseMovements();
    }
  }

  Future<void> resumeMode() async {
    if (state.modeState == AutoModeState.paused) {
      emit(state.copyWith(modeState: AutoModeState.running));
      await _repository.resumeMovements();
    }
  }

  Future<void> stopMode() async {
    emit(state.copyWith(currentMode: AutoModeType.none, modeState: AutoModeState.idle));
    await _repository.stopAllMovements();
    await _repository.setMode('manual');
  }

  @override
  Future<void> close() {
    _statusSub?.cancel();
    return super.close();
  }
}
