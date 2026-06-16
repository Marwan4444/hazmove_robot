import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failure.dart';
import '../../../../modules/robot_control/domain/models/robot_arm_model.dart';
import '../../../../modules/robot_control/domain/models/servo_model.dart';
import '../../../../modules/robot_control/domain/models/linear_rail_model.dart';
import '../../../../modules/robot_control/domain/models/base_rotation_model.dart';
import '../../../../modules/robot_control/domain/repo/robot_control_repo.dart';

enum ConnectionStatus { disconnected, connecting, connected }

class RobotControlState extends Equatable {
  final ConnectionStatus connectionStatus;
  final RobotArmModel? robotArm;
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
    RobotArmModel? robotArm,
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

class RobotControlCubit extends Cubit<RobotControlState> {
  final RobotControlRepo _repository;
  StreamSubscription? _connectionSub;
  StreamSubscription? _statusSub;

  static RobotArmModel get defaultRobotArm => RobotArmModel(
        servos: const [
          ServoModel(id: 1, name: 'Base Servo', currentAngle: 90, targetAngle: 90, speed: 50, isMoving: false),
          ServoModel(id: 2, name: 'Shoulder Servo', currentAngle: 45, targetAngle: 45, speed: 50, isMoving: false),
          ServoModel(id: 3, name: 'Elbow Servo', currentAngle: 90, targetAngle: 90, speed: 50, isMoving: false),
          ServoModel(id: 4, name: 'Wrist Servo', currentAngle: 45, targetAngle: 45, speed: 50, isMoving: false),
          ServoModel(id: 5, name: 'Gripper Servo', currentAngle: 0, targetAngle: 0, speed: 50, isMoving: false),
        ],
        linearRail: const LinearRailModel(
          currentPosition: 50.0,
          targetPosition: 50.0,
          speed: 50,
          isMoving: false,
        ),
        baseRotation: const BaseRotationModel(
          currentDegrees: 180.0,
          targetDegrees: 180.0,
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
    _subscribeToStreams();
  }

  void _subscribeToStreams() {
    _connectionSub = _repository.connectionStatus.listen((result) {
      result.fold(
        (failure) => emit(state.copyWith(
          connectionStatus: ConnectionStatus.disconnected,
          failure: failure,
        )),
        (isConnected) => emit(state.copyWith(
          connectionStatus: isConnected ? ConnectionStatus.connected : ConnectionStatus.disconnected,
        )),
      );
    });

    _statusSub = _repository.robotStatus.listen((result) {
      result.fold(
        (failure) => emit(state.copyWith(failure: failure)),
        (robotArm) => emit(state.copyWith(robotArm: robotArm, clearFailure: true)),
      );
    });
  }

  Future<void> connect(String url) async {
    emit(state.copyWith(connectionStatus: ConnectionStatus.connecting, clearFailure: true));
    final result = await _repository.connect(url);
    result.fold(
      (failure) => emit(state.copyWith(
        connectionStatus: ConnectionStatus.disconnected,
        failure: failure,
      )),
      (_) => emit(state.copyWith(
        connectionStatus: ConnectionStatus.connected,
      )),
    );
  }

  Future<void> disconnect() async {
    emit(state.copyWith(isLoading: true));
    final result = await _repository.disconnect();
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, failure: failure)),
      (_) => emit(state.copyWith(
        isLoading: false,
        connectionStatus: ConnectionStatus.disconnected,
      )),
    );
  }

  Future<void> loadStatus() async {
    emit(state.copyWith(isLoading: true));
    final result = await _repository.getCurrentStatus();
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, failure: failure)),
      (robotArm) => emit(state.copyWith(isLoading: false, robotArm: robotArm, clearFailure: true)),
    );
  }

  Future<void> moveServo(int servoId, int startAngle, int endAngle, int speed) async {
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

    if (state.connectionStatus == ConnectionStatus.connected) {
      final result = await _repository.moveServo(servoId, startAngle, endAngle, speed);
      result.fold(
        (failure) => emit(state.copyWith(failure: failure)),
        (_) => null,
      );
    }
  }

  Future<void> setServoAngle(int servoId, int angle, int speed) async {
    if (state.robotArm != null) {
      final updatedServos = state.robotArm!.servos.map((s) {
        if (s.id == servoId) {
          return s.copyWith(
            currentAngle: angle,
            targetAngle: angle,
            speed: speed,
          );
        }
        return s;
      }).toList();
      emit(state.copyWith(
        robotArm: state.robotArm!.copyWith(servos: updatedServos),
      ));
    }

    if (state.connectionStatus == ConnectionStatus.connected) {
      final result = await _repository.setServoAngle(servoId, angle, speed);
      result.fold(
        (failure) => emit(state.copyWith(failure: failure)),
        (_) => null,
      );
    }
  }

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

    if (state.connectionStatus == ConnectionStatus.connected) {
      final result = await _repository.moveLinearRail(distance, speed);
      result.fold(
        (failure) => emit(state.copyWith(failure: failure)),
        (_) => null,
      );
    }
  }

  Future<void> setLinearPosition(double position, int speed) async {
    if (state.robotArm != null) {
      emit(state.copyWith(
        robotArm: state.robotArm!.copyWith(
          linearRail: state.robotArm!.linearRail.copyWith(
            currentPosition: position,
            targetPosition: position,
            speed: speed,
          ),
        ),
      ));
    }

    if (state.connectionStatus == ConnectionStatus.connected) {
      final result = await _repository.setLinearPosition(position, speed);
      result.fold(
        (failure) => emit(state.copyWith(failure: failure)),
        (_) => null,
      );
    }
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

    if (state.connectionStatus == ConnectionStatus.connected) {
      final result = await _repository.rotateBase(degrees, speed);
      result.fold(
        (failure) => emit(state.copyWith(failure: failure)),
        (_) => null,
      );
    }
  }

  Future<void> setBaseRotation(double degrees, int speed) async {
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

    if (state.connectionStatus == ConnectionStatus.connected) {
      final result = await _repository.setBaseRotation(degrees, speed);
      result.fold(
        (failure) => emit(state.copyWith(failure: failure)),
        (_) => null,
      );
    }
  }

  Future<void> stopAllMovements() async {
    if (state.robotArm != null) {
      final stoppedServos = state.robotArm!.servos.map((s) => s.copyWith(isMoving: false)).toList();
      emit(state.copyWith(
        isPaused: false,
        robotArm: state.robotArm!.copyWith(
          servos: stoppedServos,
          linearRail: state.robotArm!.linearRail.copyWith(isMoving: false),
          baseRotation: state.robotArm!.baseRotation.copyWith(isMoving: false),
        ),
      ));
    }

    if (state.connectionStatus == ConnectionStatus.connected) {
      emit(state.copyWith(isLoading: true));
      final result = await _repository.stopAllMovements();
      result.fold(
        (failure) => emit(state.copyWith(isLoading: false, failure: failure)),
        (_) => emit(state.copyWith(isLoading: false, isPaused: false)),
      );
    }
  }

  Future<void> pauseMovements() async {
    emit(state.copyWith(isPaused: true));
    if (state.connectionStatus == ConnectionStatus.connected) {
      final result = await _repository.pauseMovements();
      result.fold(
        (failure) => emit(state.copyWith(failure: failure)),
        (_) => null,
      );
    }
  }

  Future<void> resumeMovements() async {
    emit(state.copyWith(isPaused: false));
    if (state.connectionStatus == ConnectionStatus.connected) {
      final result = await _repository.resumeMovements();
      result.fold(
        (failure) => emit(state.copyWith(failure: failure)),
        (_) => null,
      );
    }
  }

  Future<void> setMode(String mode) async {
    if (state.connectionStatus == ConnectionStatus.connected) {
      final result = await _repository.setMode(mode);
      result.fold(
        (failure) => emit(state.copyWith(failure: failure)),
        (_) => null,
      );
    }
  }

  @override
  Future<void> close() {
    _connectionSub?.cancel();
    _statusSub?.cancel();
    return super.close();
  }
}
