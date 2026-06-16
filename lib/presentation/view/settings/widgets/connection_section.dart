import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/services/localization/locale_keys.g.dart';
import '../../root/cubit/robot_control_cubit.dart';
import 'settings_container.dart';

class ConnectionSection extends StatefulWidget {
  const ConnectionSection({super.key});

  @override
  State<ConnectionSection> createState() => _ConnectionSectionState();
}

class _ConnectionSectionState extends State<ConnectionSection> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _urlController.text = AppConstants.defaultWebSocketUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsContainer(
      child: Column(
        children: [
          TextField(
            controller: _urlController,
            style: TextStyle(color: context.textPrimary),
            decoration: InputDecoration(
              labelText: LocaleKeys.connection_url.tr(),
              labelStyle: TextStyle(color: context.accentPrimary),
              hintText: 'ws://10.76.62.83:81',
              hintStyle: TextStyle(color: context.textHint),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.accentPrimary)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.accentPrimary)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.read<RobotControlCubit>().connect(_urlController.text);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.accentPrimary,
                    foregroundColor: context.isDarkMode ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(LocaleKeys.connection_connect.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.read<RobotControlCubit>().disconnect(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(LocaleKeys.connection_disconnect.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
