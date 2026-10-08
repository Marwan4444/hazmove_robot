import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failure.dart';
import '../../../../modules/robot_control/domain/entities/movement_preset_entity.dart';
import '../../../../modules/robot_control/domain/repo/robot_control_repo.dart';

enum PresetExecutionStatus { idle, running, completed, cancelled, failed }

class PresetsState extends Equatable {
  final List<MovementPresetEntity> presets;
  final bool isLoading;
  final Failure? failure;

  /// ID of the preset currently executing, if any.
  final String? runningPresetId;

  /// Outcome of the last finished execution (stays until the next run).
  final PresetExecutionStatus executionStatus;

  const PresetsState({
    this.presets = const [],
    this.isLoading = false,
    this.failure,
    this.runningPresetId,
    this.executionStatus = PresetExecutionStatus.idle,
  });

  PresetsState copyWith({
    List<MovementPresetEntity>? presets,
    bool? isLoading,
    Failure? failure,
    bool clearFailure = false,
    String? runningPresetId,
    bool clearRunning = false,
    PresetExecutionStatus? executionStatus,
  }) {
    return PresetsState(
      presets: presets ?? this.presets,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
      runningPresetId:
          clearRunning ? null : (runningPresetId ?? this.runningPresetId),
      executionStatus: executionStatus ?? this.executionStatus,
    );
  }

  @override
  List<Object?> get props =>
      [presets, isLoading, failure, runningPresetId, executionStatus];
}

class PresetsCubit extends Cubit<PresetsState> {
  final RobotControlRepo _repository;

  PresetsCubit({required RobotControlRepo repository})
      : _repository = repository,
        super(const PresetsState());

  Future<void> loadPresets() async {
    emit(state.copyWith(isLoading: true, clearFailure: true));
    // Clean up deprecated sample preset 'Pick and Place' (id: '2') from local DB
    await _repository.deletePreset('2');
    // Clean up deprecated sample preset 'Home Position' (id: '1') from local DB
    await _repository.deletePreset('1');
    
    final result = await _repository.getPresets();
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, failure: failure)),
      (presets) async {
        if (presets.isEmpty) {
          // If empty, preload with samples for initial setup
          final samples = _getSamplePresets();
          emit(state.copyWith(isLoading: false, presets: samples));
          // Save them locally so they are cached
          await Future.wait(
              samples.map((preset) => _repository.savePreset(preset)));
        } else {
          emit(state.copyWith(isLoading: false, presets: presets));
        }
      },
    );
  }

  Future<void> savePreset(MovementPresetEntity preset) async {
    emit(state.copyWith(isLoading: true, clearFailure: true));
    final result = await _repository.savePreset(preset);
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, failure: failure)),
      (_) {
        final updated = [...state.presets.where((p) => p.id != preset.id), preset];
        emit(state.copyWith(isLoading: false, presets: updated));
      },
    );
  }

  Future<void> deletePreset(String presetId) async {
    emit(state.copyWith(isLoading: true, clearFailure: true));
    final result = await _repository.deletePreset(presetId);
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, failure: failure)),
      (_) {
        final updated = state.presets.where((p) => p.id != presetId).toList();
        emit(state.copyWith(isLoading: false, presets: updated));
      },
    );
  }

  Future<void> executePreset(String presetId) async {
    emit(state.copyWith(
      isLoading: true,
      clearFailure: true,
      runningPresetId: presetId,
      executionStatus: PresetExecutionStatus.running,
    ));
    final result = await _repository.executePreset(presetId);
    result.fold(
      (failure) {
        if (failure.type == FailureType.cancelled) {
          emit(state.copyWith(
            isLoading: false,
            clearRunning: true,
            executionStatus: PresetExecutionStatus.cancelled,
          ));
        } else {
          emit(state.copyWith(
            isLoading: false,
            failure: failure,
            clearRunning: true,
            executionStatus: PresetExecutionStatus.failed,
          ));
        }
      },
      (_) => emit(state.copyWith(
        isLoading: false,
        clearRunning: true,
        executionStatus: PresetExecutionStatus.completed,
      )),
    );
  }

  Future<void> toggleFavorite(String presetId) async {
    final target = state.presets.firstWhere((p) => p.id == presetId);
    final updatedPreset = target.copyWith(isFavorite: !target.isFavorite);
    
    // Save to repository local cache
    final result = await _repository.savePreset(updatedPreset);
    result.fold(
      (failure) => emit(state.copyWith(failure: failure)),
      (_) {
        final updatedPresets = state.presets.map((p) {
          return p.id == presetId ? updatedPreset : p;
        }).toList();
        emit(state.copyWith(presets: updatedPresets));
      },
    );
  }

  List<MovementPresetEntity> _getSamplePresets() {
    return const [];
  }
}
