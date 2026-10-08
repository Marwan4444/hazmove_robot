import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../modules/robot_control/domain/repo/robot_control_repo.dart';
import '../robot_control_cubit.dart';

/// Connection responsibility of [RobotControlCubit].
///
/// Owns the connection-status subscription and the connect / disconnect /
/// status-loading commands. The live robot-status stream stays in the main
/// cubit so there is exactly one status subscription per cubit instance.
mixin ConnectionControlMixin on Cubit<RobotControlState> {
  RobotControlRepo get repository;

  StreamSubscription? _connectionSub;

  void subscribeConnection() {
    _connectionSub = repository.connectionStatus.listen((result) {
      result.fold(
        (failure) => emit(state.copyWith(
          connectionStatus: ConnectionStatus.disconnected,
          failure: failure,
        )),
        (isConnected) => emit(state.copyWith(
          connectionStatus:
              isConnected ? ConnectionStatus.connected : ConnectionStatus.disconnected,
        )),
      );
    });
  }

  void cancelConnection() {
    _connectionSub?.cancel();
    _connectionSub = null;
  }

  Future<void> connect(String url) async {
    emit(state.copyWith(
        connectionStatus: ConnectionStatus.connecting, clearFailure: true));
    final result = await repository.connect(url);
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
    final result = await repository.disconnect();
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
    final result = await repository.getCurrentStatus();
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, failure: failure)),
      (robotArm) => emit(state.copyWith(
          isLoading: false, robotArm: robotArm, clearFailure: true)),
    );
  }

  Future<String?> getSavedConnectionUrl() async {
    final result = await repository.getConnectionUrl();
    return result.fold((_) => null, (url) => url);
  }
}
