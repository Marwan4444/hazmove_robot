/// Per-execution cancellation token for preset runs.
///
/// Replaces the old shared singleton-level boolean flag, which let
/// concurrent preset executions interfere with each other (one run's cancel
/// aborted every run, and a stale `false` reset could un-cancel another
/// run's stop). Each [executePreset] call owns exactly one token:
///
/// - `stopAllMovements()` cancels **all** active tokens (prompt stop).
/// - [cancelPresetExecution] cancels one execution by ID.
/// - Delay slices check [isCancelled] every 100 ms, so cancellation during
///   a delay resolves promptly without awaiting the full sleep.
class PresetCancellationToken {
  bool _cancelled = false;

  /// `true` once [cancel] has been called. Never resets — tokens are
  /// single-use and discarded when their execution finishes.
  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}
