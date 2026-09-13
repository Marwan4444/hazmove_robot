import 'models/movement_preset_model.dart';

abstract class RobotLocalDataSource {
  Future<List<MovementPresetModel>> getPresets();
  Future<void> savePresets(List<MovementPresetModel> presets);
  Future<String?> getConnectionUrl();
  Future<void> saveConnectionUrl(String url);
}
