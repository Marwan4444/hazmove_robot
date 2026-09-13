import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/extensions/theme_extensions.dart';
import '../../../../core/style/glass_container.dart';
import '../../../../modules/robot_control/domain/entities/linear_rail_entity.dart';

class LinearRailControlWidget extends StatefulWidget {
  final LinearRailEntity? linearRail;
  /// Called when a direction button is pressed (and debounced) — sends target to ESP32.
  final Function(double position) onPositionCommitted;

  const LinearRailControlWidget({
    super.key,
    this.linearRail,
    required this.onPositionCommitted,
  });

  @override
  State<LinearRailControlWidget> createState() => _LinearRailControlWidgetState();
}

class _LinearRailControlWidgetState extends State<LinearRailControlWidget> {
  static const double _stepCm = 1.0;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  double? _virtualPosition;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.linearRail != null) {
      _virtualPosition = widget.linearRail!.currentPosition;
    }
  }

  @override
  void didUpdateWidget(covariant LinearRailControlWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync with the real hardware position if we are not actively debouncing
    // and the robot is not moving.
    final rail = widget.linearRail;
    if (rail != null && _debounceTimer == null && !rail.isMoving) {
      _virtualPosition = rail.currentPosition;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onStepPressed(bool increment, LinearRailEntity rail) {
    if (widget.linearRail == null) return;

    final targetVal = _virtualPosition ?? rail.currentPosition;
    final limitReached = increment 
        ? targetVal >= rail.maxPosition 
        : targetVal <= rail.minPosition;

    if (limitReached) {
      HapticFeedback.heavyImpact();
      return;
    }

    // Cancel existing timer since the user is still typing/tapping
    _debounceTimer?.cancel();

    setState(() {
      final double delta = increment ? _stepCm : -_stepCm;
      _virtualPosition = (targetVal + delta).clamp(rail.minPosition, rail.maxPosition);
    });

    // Debounce the call: only send when the user pauses tapping
    _debounceTimer = Timer(_debounceDuration, () {
      if (_virtualPosition != null) {
        widget.onPositionCommitted(_virtualPosition!);
      }
      _debounceTimer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.linearRail == null) {
      return GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(18),
        child: Center(
          child: Text(
            'Linear Rail Not Available',
            style: TextStyle(color: context.textSecondary, fontSize: 16),
          ),
        ),
      );
    }

    final rail = widget.linearRail!;
    final isLocked = rail.isMoving;
    final rawColor = context.accentGreen;

    // Use virtual position for UI feedback, fallback to real position
    final displayPos = _virtualPosition ?? rail.currentPosition;
    final atMin = displayPos <= rail.minPosition;
    final atMax = displayPos >= rail.maxPosition;

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: context.cardBorder.withOpacity(context.isDarkMode ? 0.8 : 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  'Linear Rail',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isLocked) ...[
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: rawColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Moving...',
                  style: TextStyle(
                    color: rawColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else
                Text(
                  '${displayPos.toStringAsFixed(1)} cm',
                  style: TextStyle(
                    color: rawColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // ─── Controls Row: [LEFT] [Slider] [RIGHT] ────────────────────
          Row(
            children: [
              // LEFT button
              _RailButton(
                icon: Icons.arrow_back_ios_rounded,
                color: rawColor,
                enabled: !isLocked, // Only lock visually when ESP32 is running
                atLimit: atMin,
                onPressed: () => _onStepPressed(false, rail),
              ),

              const SizedBox(width: 12),

              // Display-only slider in the center
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor:
                        isLocked ? rawColor.withOpacity(0.35) : rawColor,
                    inactiveTrackColor:
                        context.isDarkMode ? Colors.white12 : Colors.black12,
                    thumbColor:
                        isLocked ? rawColor.withOpacity(0.35) : rawColor,
                    overlayColor: Colors.transparent,
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: displayPos.clamp(rail.minPosition, rail.maxPosition),
                    min: rail.minPosition,
                    max: rail.maxPosition,
                    onChanged: null, // Display only
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // RIGHT button
              _RailButton(
                icon: Icons.arrow_forward_ios_rounded,
                color: rawColor,
                enabled: !isLocked,
                atLimit: atMax,
                onPressed: () => _onStepPressed(true, rail),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ─── Min/Max labels ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const SizedBox(width: 60),
                Text(
                  '${rail.minPosition.toStringAsFixed(0)} cm',
                  style:
                      TextStyle(color: context.textSecondary, fontSize: 11),
                ),
                const Spacer(),
                Text(
                  '${rail.maxPosition.toStringAsFixed(0)} cm',
                  style:
                      TextStyle(color: context.textSecondary, fontSize: 11),
                ),
                const SizedBox(width: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Rail Button ───────────────────────────────────────────────────────────

class _RailButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final bool enabled;
  final bool atLimit;
  final VoidCallback onPressed;

  const _RailButton({
    required this.icon,
    required this.color,
    required this.enabled,
    required this.atLimit,
    required this.onPressed,
  });

  @override
  State<_RailButton> createState() => _RailButtonState();
}

class _RailButtonState extends State<_RailButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.atLimit ? Colors.redAccent : widget.color;

    return GestureDetector(
      onTapDown: widget.enabled || widget.atLimit
          ? (_) => _ctrl.forward()
          : null,
      onTapUp: widget.enabled
          ? (_) {
              _ctrl.reverse();
              widget.onPressed();
            }
          : null,
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.enabled
                  ? effectiveColor
                  : effectiveColor.withOpacity(0.3),
              width: 1.5,
            ),
            color: widget.enabled
                ? effectiveColor.withOpacity(0.12)
                : effectiveColor.withOpacity(0.04),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: widget.enabled
                ? effectiveColor
                : effectiveColor.withOpacity(0.35),
          ),
        ),
      ),
    );
  }
}
