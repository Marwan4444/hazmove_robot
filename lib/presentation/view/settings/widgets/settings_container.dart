import 'package:flutter/material.dart';
import 'package:hazmove_robot/core/extensions/theme_extensions.dart';
import 'package:hazmove_robot/core/style/glass_container.dart';

class SettingsContainer extends StatelessWidget {
  final Widget child;
  final bool isDanger;

  const SettingsContainer({
    super.key,
    required this.child,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18);

    if (isDanger) {
      return GlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: borderRadius,
        color: Colors.red,
        border: Border.all(
          color: Colors.red.withOpacity(context.isDarkMode ? 0.35 : 0.25),
        ),
        child: child,
      );
    }

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: borderRadius,
      border: Border.all(
        color: context.cardBorder.withOpacity(context.isDarkMode ? 0.8 : 0.6),
      ),
      child: child,
    );
  }
}

class SettingsRow extends StatelessWidget {
  final String label;
  final String value;

  const SettingsRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: context.textSecondary, fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(
              color: context.accentPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
