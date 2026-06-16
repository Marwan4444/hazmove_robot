import 'package:flutter/material.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/style/glass_container.dart';
import '../../../../modules/robot_control/domain/models/servo_model.dart';

class ServoControlWidget extends StatelessWidget {
  final ServoModel servo;
  final Function(int angle, int speed) onAngleChanged;

  const ServoControlWidget({
    super.key,
    required this.servo,
    required this.onAngleChanged,
  });

  @override
  Widget build(BuildContext context) {
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
              Text(
                '${servo.targetAngle}\u00b0',
                style: TextStyle(
                  color: context.accentPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: context.accentPrimary,
              inactiveTrackColor:
                  context.isDarkMode ? Colors.white24 : Colors.black12,
              thumbColor: context.accentPrimary,
              overlayColor: context.accentPrimary.withOpacity(0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: servo.targetAngle.toDouble(),
              min: servo.minAngle.toDouble(),
              max: servo.maxAngle.toDouble(),
              divisions: (servo.maxAngle - servo.minAngle),
              onChanged: (value) => onAngleChanged(value.toInt(), servo.speed),
            ),
          ),
        ],
      ),
    );
  }
}
