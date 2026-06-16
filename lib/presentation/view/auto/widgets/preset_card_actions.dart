import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/services/localization/locale_keys.g.dart';
import '../../../../core/extensions/theme_extensions.dart';

class PresetCardActions extends StatelessWidget {
  final VoidCallback onExecute;

  const PresetCardActions({super.key, required this.onExecute});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onExecute,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.accentGreen, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.play_arrow, size: 16), const SizedBox(width: 4), Text(LocaleKeys.presets_execute.tr().toUpperCase())]),
          ),
        ),
      ],
    );
  }
}
