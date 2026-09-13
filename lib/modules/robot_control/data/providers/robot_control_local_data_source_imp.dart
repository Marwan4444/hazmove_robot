import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movement_preset_model.dart';
import '../robot_control_local_data_source.dart';

class RobotLocalDataSourceImp implements RobotLocalDataSource {
  static const String _presetsKey = 'robot_presets';
  static const String _connectionUrlKey = 'connection_url';

  @override
  Future<List<MovementPresetModel>> getPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = prefs.getString(_presetsKey);
      
      if (presetsJson == null) {
        return [];
      }

      final List<dynamic> presetsList = jsonDecode(presetsJson);
      return presetsList
          .map((preset) => MovementPresetModel.fromJson(preset))
          .toList();
    } catch (e) {
      throw Exception('Failed to load presets from cache');
    }
  }

  @override
  Future<void> savePresets(List<MovementPresetModel> presets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = jsonEncode(
        presets.map((preset) => preset.toJson()).toList(),
      );
      await prefs.setString(_presetsKey, presetsJson);
    } catch (e) {
      throw Exception('Failed to save presets to cache');
    }
  }

  @override
  Future<String?> getConnectionUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_connectionUrlKey);
    } catch (e) {
      throw Exception('Failed to load connection URL from cache');
    }
  }

  @override
  Future<void> saveConnectionUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_connectionUrlKey, url);
    } catch (e) {
      throw Exception('Failed to save connection URL to cache');
    }
  }
}
