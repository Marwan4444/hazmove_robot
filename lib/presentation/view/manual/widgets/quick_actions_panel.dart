import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/style/glass_container.dart';
import '../../../../core/services/localization/locale_keys.g.dart';

class QuickActionsPanel extends StatelessWidget {
  final bool isPaused;
  final VoidCallback onStop;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const QuickActionsPanel({
    super.key,
    required this.isPaused,
    required this.onStop,
    required this.onPause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    // Start is active when paused
    final isStartActive = isPaused;
    // Pause is active when not paused
    final isPauseActive = !isPaused;

    return GlassContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(24),
      blur: 20,
      border: Border.all(
        color: context.cardBorder.withOpacity(context.isDarkMode ? 0.8 : 0.6),
        width: 1.5,
      ),
      child: Row(
        children: [
          // Start Button (Green)
          Expanded(
            child: _ActionButton(
              icon: Icons.play_arrow_rounded,
              label: LocaleKeys.control_start_btn.tr(),
              color: context.accentGreen,
              isActive: isStartActive,
              onTap: isStartActive ? onResume : null,
            ),
          ),
          const SizedBox(width: 10),
          // Pause Button (Orange/Amber)
          Expanded(
            child: _ActionButton(
              icon: Icons.pause_rounded,
              label: LocaleKeys.control_pause_btn.tr(),
              color: Colors.orange,
              isActive: isPauseActive,
              onTap: isPauseActive ? onPause : null,
            ),
          ),
          const SizedBox(width: 10),
          // Stop Button (Vibrant Red)
          Expanded(
            child: _ActionButton(
              icon: Icons.stop_rounded,
              label: LocaleKeys.control_stop_btn.tr(),
              color: Colors.redAccent,
              isActive: true,
              onTap: onStop,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    
    // Glowing or subtle border based on active state
    final borderColor = isActive 
        ? color.withOpacity(isDark ? 0.5 : 0.4) 
        : color.withOpacity(0.1);
        
    final bgColor = isActive 
        ? color.withOpacity(isDark ? 0.2 : 0.12) 
        : color.withOpacity(0.04);
        
    final contentColor = isActive 
        ? color 
        : context.textSecondary.withOpacity(0.4);

    return Opacity(
      opacity: isActive ? 1.0 : 0.5,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: color.withOpacity(0.2),
            highlightColor: color.withOpacity(0.1),
            child: Container(
              height: 64, // Increased height for premium feel and clarity
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: 1.5,
                ),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: color.withOpacity(isDark ? 0.08 : 0.04),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon, 
                    color: contentColor, 
                    size: 26, // Larger icon for clarity
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: contentColor,
                      fontSize: 13, // Slightly larger font size
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
