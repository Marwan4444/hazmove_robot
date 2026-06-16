import 'package:flutter/material.dart';
import 'settings_container.dart';

class RobotLimitsSection extends StatelessWidget {
  const RobotLimitsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsContainer(
      child: Column(
        children: [
          SettingsRow(label: 'Max Servo Speed', value: '100'),
          SettingsRow(label: 'Max Linear Speed', value: '100'),
          SettingsRow(label: 'Max Base Speed', value: '100'),
          SettingsRow(label: 'Servo Range', value: '0\u00b0 - 180\u00b0'),
          SettingsRow(label: 'Linear Range', value: '0 - 100 cm'),
          SettingsRow(label: 'Base Range', value: '0\u00b0 - 360\u00b0'),
        ],
      ),
    );
  }
}
