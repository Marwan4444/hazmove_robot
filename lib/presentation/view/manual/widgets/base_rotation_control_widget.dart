import 'package:flutter/material.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/style/glass_container.dart';
import '../../../../modules/robot_control/domain/models/base_rotation_model.dart';

class BaseRotationControlWidget extends StatelessWidget {
  final BaseRotationModel? baseRotation;
  final Function(double degrees, int speed) onRotationChanged;

  const BaseRotationControlWidget({
    super.key,
    this.baseRotation,
    required this.onRotationChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (baseRotation == null) {
      return GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(18),
        child: Center(
          child: Text(
            'Base Rotation Not Available',
            style: TextStyle(color: context.textSecondary, fontSize: 16),
          ),
        ),
      );
    }

    final base = baseRotation!;
    final baseColor = context.accentSecondary;

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
                  'Base Rotation',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${base.targetDegrees.toStringAsFixed(1)}\u00b0',
                style: TextStyle(
                  color: baseColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: baseColor,
              inactiveTrackColor:
                  context.isDarkMode ? Colors.white24 : Colors.black12,
              thumbColor: baseColor,
              overlayColor: baseColor.withOpacity(0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: base.targetDegrees,
              min: base.minDegrees,
              max: base.maxDegrees,
              divisions: 360,
              onChanged: (value) => onRotationChanged(value, base.speed),
            ),
          ),
        ],
      ),
    );
  }
}
