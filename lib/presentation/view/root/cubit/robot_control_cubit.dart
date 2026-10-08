import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failure.dart';
import '../../../../modules/robot_control/domain/entities/robot_arm_entity.dart';
import '../../../../modules/robot_control/domain/entities/servo_entity.dart';
import '../../../../modules/robot_control/domain/entities/linear_rail_entity.dart';
import '../../../../modules/robot_control/domain/entities/base_rotation_entity.dart';
import '../../../../modules/robot_control/domain/repo/robot_control_repo.dart';

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

class RobotControlCubit extends Cubit<RobotControlState> {
  final RobotControlRepo _repository;
  StreamSubscription? _connectionSub;
  StreamSubscription? _statusSub;

  // ─── Safety timeout timers (defensive fallback only) ────────────────────
  // Normal completion arrives via DONE and unlocks the axis immediately.
  // These timers are deliberately LONGER than the repository await-timeouts,
  // so they only fire when the response stream itself is broken. A fired
  // timer is a timeout FAILURE — never treated as success.
  final Map<int, Timer> _servoTimeouts = {}; // key = servo ID
  Timer? _baseRotationTimeout;
  Timer? _linearRailTimeout;
  // ────────────────────────────────────────────────────────────────────────

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

  Future<String?> getSavedConnectionUrl() async {
    final result = await _repository.getConnectionUrl();
    return result.fold((_) => null, (url) => url);
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
        (_) => emit(state.copyWith(clearFailure: true)),
      );
    }
  }

  Future<void> setServoAngle(int servoId, int angle, int speed) async {
    // Guard: ignore command if this servo is already moving
    final servo = state.robotArm?.servos.firstWhere(
      (s) => s.id == servoId,
      orElse: () => const ServoEntity(
        id: -1, name: '', currentAngle: 0,
        targetAngle: 0, speed: 0, isMoving: false,
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
    _servoTimeouts[servoId]?.cancel();
    _servoTimeouts[servoId] = Timer(
      _servoSafetyTimeout(startAngle, angle, speed),
      () => _onServoTimeout(servoId),
    );

    if (state.connectionStatus == ConnectionStatus.connected) {
      final result = await _repository.setServoAngle(servoId, angle, speed);
      result.fold(
        (failure) {
          _servoTimeouts[servoId]?.cancel();
          _unlockServo(servoId);
          emit(state.copyWith(failure: failure));
        },
        (_) {
          // DONE received: motion finished — unlock without waiting for status.
          _servoTimeouts[servoId]?.cancel();
          _unlockServo(servoId);
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
    _linearRailTimeout?.cancel();
    _linearRailTimeout = Timer(
      Duration(seconds: awaitSeconds + 15),
      _onLinearRailTimeout,
    );

    if (state.connectionStatus == ConnectionStatus.connected) {
      final result = await _repository.setLinearPosition(
        position,
        speed,
        timeout: Duration(seconds: awaitSeconds),
      );
      result.fold(
        (failure) {
          _linearRailTimeout?.cancel();
          _unlockLinearRail();
          emit(state.copyWith(failure: failure));
        },
        (_) {
          _linearRailTimeout?.cancel();
          _unlockLinearRail();
          emit(state.copyWith(clearFailure: true));
        },
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
    _baseRotationTimeout?.cancel();
    _baseRotationTimeout = Timer(
      _baseSafetyTimeout(startDegrees, degrees, speed),
      _onBaseRotationTimeout,
    );

    if (state.connectionStatus == ConnectionStatus.connected) {
      final result = await _repository.setBaseRotation(degrees, speed);
      result.fold(
        (failure) {
          _baseRotationTimeout?.cancel();
          _unlockBaseRotation();
          emit(state.copyWith(failure: failure));
        },
        (_) {
          _baseRotationTimeout?.cancel();
          _unlockBaseRotation();
          emit(state.copyWith(clearFailure: true));
        },
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

  // ─── Timeout estimation (mirrors firmware speed maps, defensively) ───────
  //
  // Firmware maps speed 1–100 → per-degree delay 30–2 ms (servo) and
  // 100–2000 steps/s (base). Estimates add 50% margin, then clamp ABOVE the
  // repository DONE-await ceilings (15 s servo / 30 s base) so the repository
  // timeout always wins first.

  Duration _servoSafetyTimeout(int from, int to, int speed) {
    final msPerDegree = 30 - (speed.clamp(1, 100) - 1) * (28 / 99);
    final seconds = ((to - from).abs() * msPerDegree / 1000 * 1.5 + 3).ceil();
    return Duration(seconds: seconds.clamp(16, 40));
  }

  Duration _baseSafetyTimeout(double from, double to, int speed) {
    final stepsPerSec = (100 + (speed.clamp(1, 100) - 1) * (1900 / 99));
    const stepsPerDegree = 2.2222222222;
    final seconds =
        ((to - from).abs() * stepsPerDegree / stepsPerSec * 1.5 + 3).ceil();
    return Duration(seconds: seconds.clamp(31, 90));
  }

  // ─── Timeout unlock helpers (failures, never success) ────────────────────

  void _onServoTimeout(int servoId) {
    final locked = state.robotArm?.servos
            .any((s) => s.id == servoId && s.isMoving) ??
        false;
    if (!locked) return; // DONE already unlocked — nothing to do.
    _unlockServo(servoId);
    emit(state.copyWith(
      failure: const Failure(
        'Servo did not respond in time. Check the connection and retry.',
        type: FailureType.timeout,
      ),
    ));
  }

  void _onBaseRotationTimeout() {
    if (state.robotArm?.baseRotation.isMoving != true) return;
    _unlockBaseRotation();
    emit(state.copyWith(
      failure: const Failure(
        'Base rotation did not respond in time. Check the connection and retry.',
        type: FailureType.timeout,
      ),
    ));
  }

  void _onLinearRailTimeout() {
    if (state.robotArm?.linearRail.isMoving != true) return;
    _unlockLinearRail();
    emit(state.copyWith(
      failure: const Failure(
        'Linear rail did not respond in time. Check the connection and retry.',
        type: FailureType.timeout,
      ),
    ));
  }

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
