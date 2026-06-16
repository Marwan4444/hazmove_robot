import 'package:flutter/material.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/style/glass_container.dart';
import '../../../../modules/robot_control/domain/models/linear_rail_model.dart';

class LinearRailControlWidget extends StatelessWidget {
  final LinearRailModel? linearRail;
  final Function(double position, int speed) onPositionChanged;

  const LinearRailControlWidget({
    super.key,
    this.linearRail,
    required this.onPositionChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (linearRail == null) {
      return GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(18),
        child: Center(
          child: Text(
            'Linear Rail Not Available',
            style: TextStyle(color: context.textSecondary, fontSize: 16),
          ),
        ),
      );
    }

    final rail = linearRail!;
    final activeColor = context.accentGreen;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: context.cardBorder.withOpacity(context.isDarkMode ? 0.8 : 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Linear Rail',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${rail.targetPosition.toStringAsFixed(1)} cm',
                style: TextStyle(
                  color: activeColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: activeColor,
              inactiveTrackColor:
                  context.isDarkMode ? Colors.white24 : Colors.black12,
              thumbColor: activeColor,
              overlayColor: activeColor.withOpacity(0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: rail.targetPosition,
              min: rail.minPosition,
              max: rail.maxPosition,
              divisions: 100,
              onChanged: (value) => onPositionChanged(value, rail.speed),
            ),
          ),
        ],
      ),
    );
  }
}
