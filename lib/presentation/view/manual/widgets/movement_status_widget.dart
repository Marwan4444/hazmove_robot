import 'package:flutter/material.dart';
import '../../../../core/extensions/theme_extensions.dart';

class MovementStatusWidget extends StatelessWidget {
  final bool isMoving;
  final bool isPaused;

  const MovementStatusWidget({
    super.key,
    required this.isMoving,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isPaused) {
      statusColor = context.accentPrimary;
      statusText = 'PAUSED';
      statusIcon = Icons.pause;
    } else if (isMoving) {
      statusColor = context.accentGreen;
      statusText = 'MOVING';
      statusIcon = Icons.play_arrow;
    } else {
      statusColor = context.accentSecondary;
      statusText = 'IDLE';
      statusIcon = Icons.stop;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(context.isDarkMode ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: statusColor.withOpacity(context.isDarkMode ? 0.4 : 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Robot Status', style: TextStyle(color: context.textSecondary, fontSize: 12)),
                Text(statusText, style: TextStyle(color: statusColor, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (isMoving && !isPaused)
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(6)),
            ),
        ],
      ),
    );
  }
}
