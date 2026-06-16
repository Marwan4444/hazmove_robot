import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../cubit/presets_cubit.dart';
import 'preset_card_widget.dart';
import 'auto_empty_state.dart';
import '../utils/auto_actions.dart';

class AutoPresetsList extends StatelessWidget {
  const AutoPresetsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PresetsCubit, PresetsState>(
      builder: (context, state) {
        if (state.isLoading) return Center(child: CircularProgressIndicator(color: context.accentPrimary));
        if (state.presets.isEmpty) return const AutoEmptyState();
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: state.presets.length,
          itemBuilder: (context, index) {
            final preset = state.presets[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PresetCardWidget(
                preset: preset,
                onExecute: () => AutoActions.executePreset(context, preset.id),
              ),
            );
          },
        );
      },
    );
  }
}
