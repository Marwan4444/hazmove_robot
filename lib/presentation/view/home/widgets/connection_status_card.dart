import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/services/localization/locale_keys.g.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../../root/cubit/robot_control_cubit.dart';
import '../../../../core/style/glass_container.dart';

class ConnectionStatusCard extends StatelessWidget {
  final RobotControlState state;

  const ConnectionStatusCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isConnected = state.connectionStatus == ConnectionStatus.connected;
    
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isConnected ? context.accentGreen : context.accentPrimary).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              color: isConnected ? context.accentGreen : context.accentPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected 
                      ? LocaleKeys.connection_connected.tr() 
                      : LocaleKeys.connection_disconnected.tr(),
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (state.connectionStatus == ConnectionStatus.connecting)
                  Text(
                    LocaleKeys.connection_connecting.tr(),
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                if (state.failure != null)
                  Text(
                    state.failure!.message,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
