import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/services/localization/locale_keys.g.dart';
import '../../../../core/constants/app_constants.dart';
import 'settings_container.dart';

class SafetySection extends StatelessWidget {
  const SafetySection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsContainer(
      isDanger: true,
      child: Column(
        children: [
          SettingsRow(label: 'Emergency Stop', value: 'Enabled'),
          SettingsRow(label: 'Collision Detection', value: 'Enabled'),
          SettingsRow(label: 'Speed Limits', value: 'Enabled'),
          SettingsRow(label: 'Position Limits', value: 'Enabled'),
        ],
      ),
    );
  }
}

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsRow(label: LocaleKeys.settings_page_app_name.tr(), value: AppConstants.appName),
          SettingsRow(label: LocaleKeys.settings_page_version.tr(), value: AppConstants.version),
          SettingsRow(label: LocaleKeys.settings_page_developer.tr(), value: 'HazMove Robotics'),
          SettingsRow(label: LocaleKeys.settings_page_build.tr(), value: 'Debug'),
        ],
      ),
    );
  }
}
