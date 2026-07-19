import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/localization/locale_keys.g.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/style/glass_container.dart';
import '../../root/cubit/robot_control_cubit.dart';
import '../../../../modules/robot_control/domain/enums/robot_enums.dart';
import '../../auto/cubit/auto_modes_cubit.dart';

class HomeNavigation extends StatelessWidget {
  const HomeNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RobotControlCubit, RobotControlState>(
      builder: (context, state) {
        final autoModesCubit = context.watch<AutoModesCubit>();
        final runningMode = autoModesCubit.state.currentMode;
        final isAutoMode = state.robotArm?.mode == RobotMode.auto ||
            runningMode != AutoModeType.none;

        String? disabledReason;
        if (isAutoMode) {
          final modeName = runningMode == AutoModeType.mode1 
              ? LocaleKeys.auto_modes_mode1.tr() 
              : runningMode == AutoModeType.mode2 
                  ? LocaleKeys.auto_modes_mode2.tr() 
                  : LocaleKeys.control_auto.tr();
                  
          if (context.locale.languageCode == 'ar') {
            disabledReason = 'التحكم اليدوي معطل: $modeName قيد التشغيل حالياً';
          } else {
            disabledReason = 'Manual control disabled: $modeName is currently running';
          }
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildNavButton(
                    context,
                    LocaleKeys.control_manual.tr(),
                    Icons.tune,
                    isAutoMode ? null : () => Navigator.pushNamed(context, AppRouter.manual),
                    isDisabled: isAutoMode,
                    disabledReason: disabledReason,
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
      },
    );
  }

  Widget _buildNavButton(
    BuildContext context, 
    String title, 
    IconData icon, 
    VoidCallback? onTap, {
    bool isDisabled = false,
    String? disabledReason,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {
        if (isDisabled) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: context.accentSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      disabledReason ?? LocaleKeys.auto_modes_manual_disabled_title.tr(),
                      style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: context.cardBg,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: context.accentSecondary.withOpacity(0.5)),
              ),
            ),
          );
        }
      },
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isDisabled ? Icons.lock_outline_rounded : icon, 
                color: isDisabled ? context.accentSecondary : context.textPrimary, 
                size: 24,
              ),
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
      ),
    );
  }
}
