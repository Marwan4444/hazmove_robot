import 'package:flutter/material.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/style/glass_container.dart';
import '../../../../modules/robot_control/domain/entities/servo_entity.dart';

class ServoControlWidget extends StatelessWidget {
  final ServoEntity servo;
  /// Called on every drag tick — update UI only, don't send to ESP32.
  final Function(int angle, int speed) onAngleChanged;
  /// Called once when the user releases the slider — send to ESP32.
  final Function(int angle, int speed) onAngleCommitted;

  const ServoControlWidget({
    super.key,
    required this.servo,
    required this.onAngleChanged,
    required this.onAngleCommitted,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = servo.isMoving;
    final activeColor = isLocked
        ? context.accentPrimary.withOpacity(0.35)
        : context.accentPrimary;

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
                  servo.name,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isLocked) ..._movingIndicator(context)
              else
                Text(
                  '${servo.targetAngle}\u00b0',
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
              value: servo.targetAngle
                  .clamp(servo.minAngle, servo.maxAngle)
                  .toDouble(),
              min: servo.minAngle.toDouble(),
              max: servo.maxAngle.toDouble(),
              divisions: (servo.maxAngle - servo.minAngle),
              // Disable all interaction while robot is moving
              onChanged: isLocked
                  ? null
                  : (value) => onAngleChanged(value.toInt(), servo.speed),
              onChangeEnd: isLocked
                  ? null
                  : (value) => onAngleCommitted(value.toInt(), servo.speed),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _movingIndicator(BuildContext context) => [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.accentPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Moving...',
          style: TextStyle(
            color: context.accentPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ];
}
