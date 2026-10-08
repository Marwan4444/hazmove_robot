# CHANGELOG

All architectural / protocol changes. Newest first.

## Unreleased
- Added `docs/protocol.md` as the authoritative Flutter ↔ ESP32 contract
  (commands, limits, ack/done/reject/error, correlation diagram).
- Centralized motion limits to verified firmware values:
  linear 0–45 cm, base −180–180°, servo 0–180°, speed 1–100
  (`AppConstants`, entities, models, validators, settings UI).
- Implemented `commandId` correlation (`ack` → `done`/`reject`/`error`)
  on Flutter + ESP32 with timeout fallback; responses bypass status throttle.
- Added typed protocol layer (`RobotCommand*`, `RobotResponse*`, constants).
- Removed duplicated `domain/models/` set; domain keeps
  `entities/` + `enums/` + `repo/`, data keeps `models/` + `mappers/`.
- Split `RobotControlCubit` responsibilities into focused mixins/controllers
  with a single status subscription; UI behavior unchanged.
- Replaced shared preset-cancel flag with per-execution cancellation tokens.
- Disabled Auto Mode 2 (`Sequence2()` is an empty firmware stub); documented TODO.
- Implemented real `NetworkInfo` (local-network aware); WebSocket stays the
  authoritative connection state.
- Replaced broken counter widget test with real unit/cubit/widget test suite
  (98 tests, all passing, no hardware needed).
- Added GitHub Actions CI (`analyze` + `test` + `build apk --debug`).
- Rewrote README from implementation; removed Bluetooth/usecases/features/HTTP
  claims; separated Implemented vs Planned.
- Removed unused deps (`http`, `json_annotation`, `json_serializable`,
  `build_runner`); verified analyzer/tests after removal.
- Expanded `Failure` taxonomy (rejected/firmware/timeout/disconnected/…) with
  user-facing messages; firmware rejections are surfaced, never silent.
