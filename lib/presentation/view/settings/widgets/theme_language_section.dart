import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/services/localization/locale_keys.g.dart';
import '../../../../core/style/theme_cubit.dart';
import 'settings_container.dart';

class ThemeLanguageSection extends StatelessWidget {
  const ThemeLanguageSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsContainer(
      child: Column(
        children: [
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) {
              final isDark = mode == ThemeMode.dark;
              return _buildSwitchRow(
                context,
                isDark ? LocaleKeys.theme_dark.tr() : LocaleKeys.theme_light.tr(),
                isDark,
                (_) => context.read<ThemeCubit>().toggleTheme(),
                icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Divider(color: context.dividerColor),
          ),
          _buildLanguageRow(
            context,
            LocaleKeys.settings_page_language.tr(),
            context.locale.languageCode == 'ar',
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(BuildContext context, String label, bool value, Function(bool) onChanged, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: context.textSecondary),
                const SizedBox(width: 12),
              ],
              Text(label, style: TextStyle(color: context.textSecondary, fontSize: 16)),
            ],
          ),
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

  Widget _buildLanguageRow(BuildContext context, String label, bool isArabic) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.language_rounded, color: context.textSecondary),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(color: context.textSecondary, fontSize: 16)),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: context.cardBorder.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.dividerColor),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLangButton(
                  context,
                  'EN',
                  !isArabic,
                  () => context.setLocale(const Locale('en')),
                ),
                const SizedBox(width: 4),
                _buildLangButton(
                  context,
                  'AR',
                  isArabic,
                  () => context.setLocale(const Locale('ar')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangButton(BuildContext context, String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? context.accentPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: context.accentPrimary.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : context.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
