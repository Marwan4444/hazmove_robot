import 'package:flutter/material.dart';
import '../../../../core/extensions/theme_extensions.dart';
import 'settings_container.dart';

class AppPreferencesSection extends StatefulWidget {
  const AppPreferencesSection({super.key});

  @override
  State<AppPreferencesSection> createState() => _AppPreferencesSectionState();
}

class _AppPreferencesSectionState extends State<AppPreferencesSection> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return SettingsContainer(
      child: Column(
        children: [
          _buildSwitchRow(context, 'Notifications', _notificationsEnabled, (v) => setState(() => _notificationsEnabled = v)),
          _buildSwitchRow(context, 'Sound Effects', _soundEnabled, (v) => setState(() => _soundEnabled = v)),
          _buildSwitchRow(context, 'Vibration', _vibrationEnabled, (v) => setState(() => _vibrationEnabled = v)),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(BuildContext context, String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.textSecondary, fontSize: 16)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: context.accentPrimary,
            activeTrackColor: context.accentPrimary.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}
