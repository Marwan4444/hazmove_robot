import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/services/localization/locale_keys.g.dart';
import '../../../../core/extensions/theme_extensions.dart';
import 'add_preset_dialog.dart';

class AutoEmptyState extends StatelessWidget {
  const AutoEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.playlist_play, color: context.textSecondary.withOpacity(0.5), size: 64),
          const SizedBox(height: 20),
          Text(
            LocaleKeys.presets_no_presets.tr(),
            style: TextStyle(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text('Create your first movement preset', style: TextStyle(color: context.textSecondary, fontSize: 14)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => showDialog(context: context, builder: (_) => const AddPresetDialog()),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.accentPrimary,
              foregroundColor: context.isDarkMode ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: Text(LocaleKeys.presets_save.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
