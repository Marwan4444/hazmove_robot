import 'package:flutter/material.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/style/glass_container.dart';
import '../../../../modules/robot_control/domain/models/base_rotation_model.dart';

class BaseRotationControlWidget extends StatelessWidget {
  final BaseRotationModel? baseRotation;
  /// Called on every drag tick — update UI only, don't send to ESP32.
  final Function(double degrees, int speed) onRotationChanged;
  /// Called once when the user releases the slider — send to ESP32.
  final Function(double degrees, int speed) onRotationCommitted;

  const BaseRotationControlWidget({
    super.key,
    this.baseRotation,
    required this.onRotationChanged,
    required this.onRotationCommitted,
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
    final isLocked = base.isMoving;
    final rawColor = context.accentSecondary;
    final activeColor = isLocked ? rawColor.withOpacity(0.35) : rawColor;

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
              if (isLocked) ..._movingIndicator(context, rawColor)
              else
                Text(
                  '${base.targetDegrees.toStringAsFixed(1)}\u00b0',
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
              value: base.targetDegrees,
              min: base.minDegrees,
              max: base.maxDegrees,
              divisions: 360,
              // Disable all interaction while robot is moving
              onChanged: isLocked
                  ? null
                  : (value) => onRotationChanged(value, base.speed),
              onChangeEnd: isLocked
                  ? null
                  : (value) => onRotationCommitted(value, base.speed),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _movingIndicator(BuildContext context, Color color) => [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Moving...',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ];
}
