import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/services/localization/locale_keys.g.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/style/glass_container.dart';

class HomeNavigation extends StatelessWidget {
  const HomeNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildNavButton(
                context,
                LocaleKeys.control_manual.tr(),
                Icons.tune,
                () => Navigator.pushNamed(context, AppRouter.manual),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNavButton(
                context,
                LocaleKeys.control_auto.tr(),
                Icons.play_arrow,
                () => Navigator.pushNamed(context, AppRouter.auto),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildNavButton(
          context,
          LocaleKeys.control_settings.tr(),
          Icons.settings,
          () => Navigator.pushNamed(context, AppRouter.settings),
        ),
      ],
    );
  }

  Widget _buildNavButton(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: context.textPrimary, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
