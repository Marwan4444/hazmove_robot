import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/services/localization/locale_keys.g.dart';
import '../../../../core/style/glass_container.dart';
import '../cubit/auto_modes_cubit.dart';

class AutoModesSection extends StatelessWidget {
  const AutoModesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AutoModesCubit, AutoModesState>(
      builder: (context, state) {
        if (state.currentMode != AutoModeType.none) {
          return _buildActiveModeControls(context, state);
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModeCard(
              context: context,
              title: LocaleKeys.auto_modes_mode1.tr(),
              description: LocaleKeys.auto_modes_mode1_desc.tr(),
              icon: Icons.precision_manufacturing_rounded,
              accentColor: context.accentPrimary,
              onTap: () => context.read<AutoModesCubit>().startMode(AutoModeType.mode1),
            ),
            const SizedBox(height: 20),
            _buildModeCard(
              context: context,
              title: LocaleKeys.auto_modes_mode2.tr(),
              description: LocaleKeys.auto_modes_mode2_desc.tr(),
              icon: Icons.smart_toy_rounded,
              accentColor: context.accentGreen,
              onTap: () => context.read<AutoModesCubit>().startMode(AutoModeType.mode2),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(24),
        blur: 20,
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1.5),
        color: accentColor,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.1),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, size: 40, color: accentColor),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: accentColor.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                size: 20,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveModeControls(BuildContext context, AutoModesState state) {
    final modeName = state.currentMode == AutoModeType.mode1 
        ? LocaleKeys.auto_modes_mode1.tr() 
        : LocaleKeys.auto_modes_mode2.tr();
    final accentColor = state.currentMode == AutoModeType.mode1 
        ? context.accentPrimary 
        : context.accentGreen;
    final isPaused = state.modeState == AutoModeState.paused;

    return GlassContainer(
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(24),
      blur: 20,
      border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
      color: accentColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$modeName ${LocaleKeys.auto_modes_active.tr()}',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isPaused ? Colors.orange.withOpacity(0.15) : context.accentGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPaused ? Colors.orange.withOpacity(0.3) : context.accentGreen.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  isPaused ? LocaleKeys.auto_modes_paused.tr() : LocaleKeys.auto_modes_running.tr(),
                  style: TextStyle(
                    color: isPaused ? Colors.orange : context.accentGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (isPaused) {
                      context.read<AutoModesCubit>().resumeMode();
                    } else {
                      context.read<AutoModesCubit>().pauseMode();
                    }
                  },
                  icon: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                  label: Text(isPaused ? LocaleKeys.auto_modes_resume.tr() : LocaleKeys.auto_modes_pause.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.orange.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.read<AutoModesCubit>().stopMode(),
                  icon: const Icon(Icons.stop_rounded),
                  label: Text(LocaleKeys.auto_modes_stop.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.redAccent.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
