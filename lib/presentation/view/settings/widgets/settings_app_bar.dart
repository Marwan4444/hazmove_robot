import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/services/localization/locale_keys.g.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/style/glass_container.dart';

class SettingsAppBar extends StatelessWidget {
  const SettingsAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            borderRadius: BorderRadius.circular(30),
            blur: 25.0,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: context.textPrimary,
                    size: 18,
                  ),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                ),
                Expanded(
                  child: Text(
                    LocaleKeys.settings_page_title.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
