import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/presets_cubit.dart';

class AutoActions {
  static void executePreset(BuildContext context, String presetId) {
    context.read<PresetsCubit>().executePreset(presetId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Executing preset...'), backgroundColor: Colors.green),
    );
  }
}
