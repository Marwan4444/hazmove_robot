import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failure.dart';
import '../../../../modules/robot_control/domain/models/movement_preset_model.dart';
import '../../../../modules/robot_control/domain/repo/robot_control_repo.dart';

class PresetsState extends Equatable {
  final List<MovementPresetModel> presets;
  final bool isLoading;
  final Failure? failure;

  const PresetsState({
    this.presets = const [],
    this.isLoading = false,
    this.failure,
  });

  PresetsState copyWith({
    List<MovementPresetModel>? presets,
    bool? isLoading,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return PresetsState(
      presets: presets ?? this.presets,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [presets, isLoading, failure];
}

class PresetsCubit extends Cubit<PresetsState> {
  final RobotControlRepo _repository;

  PresetsCubit({required RobotControlRepo repository})
      : _repository = repository,
        super(const PresetsState());

  Future<void> loadPresets() async {
    emit(state.copyWith(isLoading: true, clearFailure: true));
    final result = await _repository.getPresets();
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, failure: failure)),
      (presets) {
        if (presets.isEmpty) {
          // If empty, preload with samples for initial setup
          final samples = _getSamplePresets();
          emit(state.copyWith(isLoading: false, presets: samples));
          // Save them locally so they are cached
          for (final preset in samples) {
            _repository.savePreset(preset);
          }
        } else {
          emit(state.copyWith(isLoading: false, presets: presets));
        }
      },
    );
  }

  Future<void> savePreset(MovementPresetModel preset) async {
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
    emit(state.copyWith(isLoading: true, clearFailure: true));
    final result = await _repository.executePreset(presetId);
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, failure: failure)),
      (_) => emit(state.copyWith(isLoading: false)),
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

  List<MovementPresetModel> _getSamplePresets() {
    return [
      MovementPresetModel(
        id: '1',
        name: 'Home Position',
        description: 'Return to home position',
        steps: const [
          MovementStepModel(
            type: 'servo',
            parameters: {'servo_id': 1, 'angle': 0, 'speed': 50},
          ),
          MovementStepModel(
            type: 'servo',
            parameters: {'servo_id': 2, 'angle': 90, 'speed': 50},
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isFavorite: true,
      ),
      MovementPresetModel(
        id: '2',
        name: 'Pick and Place',
        description: 'Pick and place routine',
        steps: const [
          MovementStepModel(
            type: 'linear',
            parameters: {'distance': 10.0, 'speed': 30},
            delayMs: 500,
          ),
          MovementStepModel(
            type: 'servo',
            parameters: {'servo_id': 5, 'angle': 90, 'speed': 30},
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        isFavorite: false,
      ),
    ];
  }
}
