import 'dart:async';
import 'robot_response.dart';

/// Correlates outbound `commandId`s with inbound terminal frames
/// (`done` / `reject` / `error`).
///
/// Usage: `track(id)` before/after sending, then feed every unthrottled
/// [RobotResponse] into [resolve]. `ack` frames mark acceptance but do not
/// complete the future — only terminal frames do. Unknown IDs are ignored so
/// a stale/legacy frame can never complete someone else's command.
class CommandTracker {
  final Map<String, Completer<RobotResponse>> _pending = {};
  final Set<String> _acknowledged = {};

  /// Number of commands currently awaiting a terminal frame (for tests).
  int get pendingCount => _pending.length;

  /// `true` if an `ack` was seen for [commandId] (for tests/diagnostics).
  bool wasAcknowledged(String commandId) => _acknowledged.contains(commandId);

  /// Registers [commandId] and returns a future completing with the terminal
  /// response, or with a [TimeoutException] after [timeout].
  Future<RobotResponse> track(String commandId, {required Duration timeout}) {
    // A retransmit of the same ID replaces the stale entry (fail fast).
    _pending[commandId]?.completeError(StateError(
        'Command $commandId was superseded by a retransmit.'));
    final completer = Completer<RobotResponse>();
    _pending[commandId] = completer;
    Timer(timeout, () {
      final pending = _pending.remove(commandId);
      if (pending != null && !pending.isCompleted) {
        pending.completeError(TimeoutException(
            'No DONE/REJECT/ERROR for command $commandId within $timeout.'));
      }
    });
    return completer.future;
  }

  /// Feeds one parsed response into the tracker.
  ///
  /// Returns `true` if the frame matched a tracked command.
  bool resolve(RobotResponse response) {
    final id = response.commandId;
    if (id == null) return false;
    if (response is AckResponse) {
      if (_pending.containsKey(id)) {
        _acknowledged.add(id);
        return true;
      }
      return false;
    }
    if (response.isTerminal) {
      final completer = _pending.remove(id);
      _acknowledged.remove(id);
      if (completer != null && !completer.isCompleted) {
        completer.complete(response);
        return true;
      }
    }
    return false;
  }

  /// Silently drops one tracked command without completing its future.
  /// Use when the send itself failed and the caller already returned — the
  /// future is orphaned, so completing it with an error would surface as an
  /// unhandled async error. Returns `true` if an entry was removed.
  bool discard(String commandId) {
    final removed = _pending.remove(commandId) != null;
    _acknowledged.remove(commandId);
    return removed;
  }

  /// Cancels one tracked command (e.g. send failed after tracking).
  /// Returns `true` if an entry was removed.
  bool cancel(String commandId) {
    final completer = _pending.remove(commandId);
    _acknowledged.remove(commandId);
    if (completer != null && !completer.isCompleted) {
      completer.completeError(
          StateError('Command $commandId was cancelled before sending.'));
      return true;
    }
    return false;
  }

  /// Fails every pending command (e.g. on disconnect). Returns the count.
  int failAll(Object error) {
    final pending = Map.of(_pending);
    _pending.clear();
    _acknowledged.clear();
    for (final completer in pending.values) {
      if (!completer.isCompleted) completer.completeError(error);
    }
    return pending.length;
  }
}
