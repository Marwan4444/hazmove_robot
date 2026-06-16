import 'package:flutter/material.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../home/widgets/ambient_blob.dart';
import '../home/widgets/home_background.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/services/localization/locale_keys.g.dart';
import 'widgets/settings_app_bar.dart';
import 'widgets/connection_section.dart';
import 'widgets/theme_language_section.dart';
import 'widgets/safety_about_sections.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const HomeBackground(),
          Positioned(
            top: -100,
            left: -100,
            child: AmbientBlob(color: context.accentPrimary, size: 350),
          ),
          Positioned(
            bottom: 50,
            right: -80,
            child: AmbientBlob(color: context.accentSecondary, size: 300),
          ),
          Positioned(
            top: 250,
            left: 50,
            child: AmbientBlob(
              color: context.accentGreen.withOpacity(0.4),
              size: 200,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: 100,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(context, LocaleKeys.settings_page_connection_settings.tr()),
                  const ConnectionSection(),
                  _buildTitle(context, LocaleKeys.settings_page_aesthetic_language.tr()),
                  const ThemeLanguageSection(),
                  _buildTitle(context, LocaleKeys.settings_page_about.tr()),
                  const AboutSection(),
                ],
              ),
            ),
          ),
          const SettingsAppBar(),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 30, bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          color: context.accentPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
