import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failure.dart';
import '../../../../modules/robot_control/domain/entities/robot_arm_entity.dart';
import '../../../../modules/robot_control/domain/entities/servo_entity.dart';
import '../../../../modules/robot_control/domain/entities/linear_rail_entity.dart';
import '../../../../modules/robot_control/domain/entities/base_rotation_entity.dart';
import '../../../../modules/robot_control/domain/repo/robot_control_repo.dart';
import 'mixins/connection_control_mixin.dart';
import 'mixins/safety_control_mixin.dart';
import 'mixins/servo_control_mixin.dart';
import 'mixins/linear_rail_control_mixin.dart';
import 'mixins/base_control_mixin.dart';

enum ConnectionStatus { disconnected, connecting, connected }

class RobotControlState extends Equatable {
  final ConnectionStatus connectionStatus;
  final RobotArmEntity? robotArm;
  final bool isLoading;
  final bool isPaused;
  final Failure? failure;

  const RobotControlState({
    this.connectionStatus = ConnectionStatus.disconnected,
    this.robotArm,
    this.isLoading = false,
    this.isPaused = false,
    this.failure,
  });

  RobotControlState copyWith({
    ConnectionStatus? connectionStatus,
    RobotArmEntity? robotArm,
    bool? isLoading,
    bool? isPaused,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return RobotControlState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      robotArm: robotArm ?? this.robotArm,
      isLoading: isLoading ?? this.isLoading,
      isPaused: isPaused ?? this.isPaused,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
        connectionStatus,
        robotArm,
        isLoading,
        isPaused,
        failure,
      ];
}

/// Central robot controller.
///
/// Responsibilities are split into focused mixins while this class keeps the
/// coordination: single status subscription (single source of truth), timer
/// cancellation and disposal. UI behavior is unchanged — the same public
/// methods exist, now grouped by responsibility:
///
/// - [ConnectionControlMixin] — connection lifecycle + status loading.
/// - [ServoControlMixin] — servo axis (guard + optimistic state + timer).
/// - [LinearRailControlMixin] — linear rail axis.
/// - [BaseControlMixin] — base rotation axis.
/// - [SafetyControlMixin] — emergency stop / pause / resume / mode.
///
/// No extra WebSocket subscriptions are created: the status stream is
/// subscribed exactly once here ([AutoModesCubit] holds its own broadcast
/// subscription, which is a separate consumer, not a duplicate).
class RobotControlCubit extends Cubit<RobotControlState>
    with
        ConnectionControlMixin,
        SafetyControlMixin,
        ServoControlMixin,
        LinearRailControlMixin,
        BaseControlMixin {
  final RobotControlRepo _repository;

  @override
  RobotControlRepo get repository => _repository;

  StreamSubscription? _statusSub;

  static RobotArmEntity get defaultRobotArm => RobotArmEntity(
        servos: const [
          // Angles match ESP32's InitialPosition() mapped back to 0-180 Flutter range
          ServoEntity(id: 1, name: 'Base Servo',     currentAngle: 0,   targetAngle: 0,   speed: 50, isMoving: false), // HandFB   → 0°
          ServoEntity(id: 2, name: 'Shoulder Servo', currentAngle: 90,  targetAngle: 90,  speed: 50, isMoving: false), // MoveArm  → 50/100 → 90° (mapped)
          ServoEntity(id: 3, name: 'Elbow Servo',    currentAngle: 180, targetAngle: 180, speed: 50, isMoving: false), // HandUD   → 180°
          ServoEntity(id: 4, name: 'Wrist Servo',    currentAngle: 150, targetAngle: 150, speed: 50, isMoving: false), // HandR    → 150°
          ServoEntity(id: 5, name: 'Gripper Servo',  currentAngle: 180, targetAngle: 180, speed: 50, isMoving: false), // HandOC   → 180°
        ],
        linearRail: const LinearRailEntity(
          currentPosition: 0.0,  // ESP32: currentLinearCM starts at 0
          targetPosition: 0.0,
          speed: 50,
          isMoving: false,
        ),
        baseRotation: const BaseRotationEntity(
          currentDegrees: 0.0,   // ESP32: currentBaseDegrees starts at 0
          targetDegrees: 0.0,
          speed: 50,
          isMoving: false,
        ),
        lastUpdated: DateTime.now(),
      );

  RobotControlCubit({required RobotControlRepo repository})
      : _repository = repository,
        super(RobotControlState(
          connectionStatus: ConnectionStatus.disconnected,
          robotArm: defaultRobotArm,
        )) {
    subscribeConnection();
    _statusSub = _repository.robotStatus.listen((result) {
      result.fold(
        (failure) => emit(state.copyWith(failure: failure)),
        (robotArm) {
          // ESP32 sent a status update → cancel all safety timeouts
          // because movement is confirmed done.
          _cancelAllTimeouts();
          emit(state.copyWith(robotArm: robotArm, clearFailure: true));
        },
      );
    });
  }

  void _cancelAllTimeouts() {
    cancelServoTimers();
    cancelBaseRotationTimer();
    cancelLinearRailTimer();
  }

  /// Clears a surfaced failure without touching anything else.
  void clearFailure() => emit(state.copyWith(clearFailure: true));

  @override
  Future<void> close() {
    cancelConnection();
    _statusSub?.cancel();
    _cancelAllTimeouts();
    return super.close();
  }
}
