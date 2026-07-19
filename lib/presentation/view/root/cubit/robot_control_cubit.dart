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

  // ─── Safety timeout timers (3s) ────────────────────────────────────────
  // If ESP32 doesn't respond within 3s, auto-unlock the slider.
  static const _kMovingTimeout = Duration(seconds: 3);
  final Map<int, Timer> _servoTimeouts = {}; // key = servo ID
  Timer? _baseRotationTimeout;
  Timer? _linearRailTimeout;
  // ────────────────────────────────────────────────────────────────────────

  static RobotArmModel get defaultRobotArm => RobotArmModel(
        servos: const [
          // Angles match ESP32's InitialPosition() mapped back to 0-180 Flutter range
          ServoModel(id: 1, name: 'Base Servo',     currentAngle: 0,   targetAngle: 0,   speed: 50, isMoving: false), // HandFB   → 0°
          ServoModel(id: 2, name: 'Shoulder Servo', currentAngle: 90,  targetAngle: 90,  speed: 50, isMoving: false), // MoveArm  → 50/100 → 90° (mapped)
          ServoModel(id: 3, name: 'Elbow Servo',    currentAngle: 180, targetAngle: 180, speed: 50, isMoving: false), // HandUD   → 180°
          ServoModel(id: 4, name: 'Wrist Servo',    currentAngle: 150, targetAngle: 150, speed: 50, isMoving: false), // HandR    → 150°
          ServoModel(id: 5, name: 'Gripper Servo',  currentAngle: 180, targetAngle: 180, speed: 50, isMoving: false), // HandOC   → 180°
        ],
        linearRail: const LinearRailModel(
          currentPosition: 0.0,  // ESP32: currentLinearCM starts at 0
          targetPosition: 0.0,
          speed: 50,
          isMoving: false,
        ),
        baseRotation: const BaseRotationModel(
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
        (robotArm) {
          // ESP32 sent a status update → cancel all safety timeouts
          // because movement is confirmed done.
          _cancelAllTimeouts();
          emit(state.copyWith(robotArm: robotArm, clearFailure: true));
        },
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
    // ❌ Guard: ignore command if this servo is already moving
    final servo = state.robotArm?.servos.firstWhere(
      (s) => s.id == servoId,
      orElse: () => const ServoModel(
        id: -1, name: '', currentAngle: 0,
        targetAngle: 0, speed: 0, isMoving: false,
      ),
    );
    if (servo?.isMoving == true) return;

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

    // Start 3-second safety timeout for this servo
    _servoTimeouts[servoId]?.cancel();
    _servoTimeouts[servoId] = Timer(_kMovingTimeout, () {
      _unlockServo(servoId);
    });

    if (state.connectionStatus == ConnectionStatus.connected) {
      final result = await _repository.setServoAngle(servoId, angle, speed);
      result.fold(
        (failure) => emit(state.copyWith(failure: failure)),
        (_) => null,
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
    // ❌ Guard: ignore command if linear rail is already moving
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

    // Dynamic timeout based on real ESP32 speed:
    // STEPS_PER_CM=2000, step pulse=400μs → ~0.8s per cm + 50% safety margin
    final distanceCm = (position - currentPos).abs();
    final dynamicSeconds = ((distanceCm * 0.8 * 1.5).ceil()).clamp(5, 120);
    _linearRailTimeout?.cancel();
    _linearRailTimeout = Timer(Duration(seconds: dynamicSeconds), () {
      _unlockLinearRail();
    });

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
    // ❌ Guard: ignore command if base rotation is already moving
    if (state.robotArm?.baseRotation.isMoving == true) return;

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

    // Start 3-second safety timeout for base rotation
    _baseRotationTimeout?.cancel();
    _baseRotationTimeout = Timer(_kMovingTimeout, () {
      _unlockBaseRotation();
    });

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

  // ─── Timeout unlock helpers ──────────────────────────────────────────────

  void _unlockServo(int servoId) {
    if (state.robotArm == null) return;
    final updatedServos = state.robotArm!.servos.map((s) {
      return s.id == servoId ? s.copyWith(isMoving: false) : s;
    }).toList();
    emit(state.copyWith(
      robotArm: state.robotArm!.copyWith(servos: updatedServos),
    ));
  }

  void _unlockBaseRotation() {
    if (state.robotArm == null) return;
    emit(state.copyWith(
      robotArm: state.robotArm!.copyWith(
        baseRotation: state.robotArm!.baseRotation.copyWith(isMoving: false),
      ),
    ));
  }

  void _unlockLinearRail() {
    if (state.robotArm == null) return;
    emit(state.copyWith(
      robotArm: state.robotArm!.copyWith(
        linearRail: state.robotArm!.linearRail.copyWith(isMoving: false),
      ),
    ));
  }

  void _cancelAllTimeouts() {
    for (final t in _servoTimeouts.values) {
      t.cancel();
    }
    _servoTimeouts.clear();
    _baseRotationTimeout?.cancel();
    _baseRotationTimeout = null;
    _linearRailTimeout?.cancel();
    _linearRailTimeout = null;
  }

  // ────────────────────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    _connectionSub?.cancel();
    _statusSub?.cancel();
    _cancelAllTimeouts();
    return super.close();
  }
}
