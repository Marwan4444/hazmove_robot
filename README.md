# HazMove Robot Control

Flutter mobile app that drives a 5-servo robotic arm mounted on a linear rail
with a rotating base, over Wi-Fi WebSocket to an ESP32 controller. Includes
manual control, firmware auto-sequences, user presets, live status and an
isometric arm visualization.

> Source of truth for the wire contract: [`docs/protocol.md`](docs/protocol.md).
> Flutter command schema == `docs/protocol.md` == ESP32 parser.

## 1. What HazMove is

A remote control for a lab robot rig: the phone joins the ESP32 Wi-Fi network
(default soft-AP `ws://192.168.4.1:81`), sends JSON motion commands, and renders
the robot's live `status` broadcasts. No backend, no account, no cloud — the
phone talks directly to the hardware.

## 2. System architecture

```text
Flutter app  <--WebSocket JSON:81-->  ESP32 firmware
   |                                      |
   | commands: servo/linear/base/         | drives 6 servos + 2 steppers
   |   stop/pause/resume/mode             | enforces physical limits
   |                                      | broadcasts status (~1 Hz + on move)
   v                                      v
Cubits + screens                    LEDs + physical buttons
```

Command flow with acknowledgements:

```text
Flutter --cmd(commandId)--> ESP32 --ack(commandId)--> Flutter
                                       --done(commandId)--> Flutter (motion finished)
                                       --reject(reason)--> Flutter (refused, not executed)
```

## 3. Flutter contribution

- Clean-Architecture-style layers: `domain/` (entities, enums, repo contract),
  `data/` (models, mappers, providers, typed protocol), `presentation/`
  (Cubits + screens/widgets), `core/` (DI, routing, errors, theme, network).
- State via `flutter_bloc` Cubits + `get_it` service location.
- Typed protocol layer (`RobotCommand*` / `RobotResponse*` / `CommandTracker`)
  instead of raw JSON maps scattered through the code.
- Optimistic UI with movement guards; DONE-based completion with safety
  timeouts kept strictly as a defensive fallback (a fired timer is a failure,
  never success).
- Isometric `CustomPainter` arm simulator, EN/AR localization, dark/light theme.

## 4. ESP32 role

`hazmove_esp32/hazmove_esp32.ino` runs a `WebSocketsServer` on port 81,
parses commands (ArduinoJson), executes blocking motion functions
(`MoveServo`/`MoveArm`/`MoveLinearCM`/`MoveBaseDegrees`), and broadcasts
`status` snapshots. It is the **final safety authority**: it clamps and
range-checks every command and now answers `ack`/`done`/`reject`/`error`
instead of silently ignoring invalid input.

## 5. WebSocket communication

- Single persistent channel, default URL `ws://192.168.4.1:81`
  (configurable in Settings, persisted locally).
- Auto-reconnect with exponential backoff (2s x 2^n, max 10 attempts);
  intentional disconnects do not retry.
- Inbound `status` frames are throttled at the transport edge to ~30 FPS
  (32 ms). Command responses (`ack`/`done`/`reject`/`error`) bypass
  throttling so completion is never delayed.

## 6. Supported commands

| Command | Payload | Response |
|---|---|---|
| `servo` | `servo_id` 1-5, `end` 0-180, `speed` 1-100 | `ack` -> `done` / `reject` / `error` |
| `linear` | `distance` 0-45 cm, `speed` 1-100 | `ack` -> `done` / `reject` / `error` |
| `base` | `degrees` -180-180, `speed` 1-100 | `ack` -> `done` / `reject` / `error` |
| `stop` | — | `ack` + `done` + `status` |
| `pause` / `resume` | — | `ack` + `done` + `status` |
| `mode` | `manual` / `seq1` (`auto` = legacy alias of `seq1`) | `ack` + `done` + `status` |

Every command carries a `commandId` echoed in all responses (see
[`docs/protocol.md`](docs/protocol.md) for field tables, reject reasons and
the error catalogue).

## 7. Hardware requirements

- ESP32 board with the firmware in `hazmove_esp32/` flashed.
- 5 servo motors (IDs 1-5: base FB, shoulder pair, elbow, wrist, gripper).
- 2 stepper drivers: linear rail (0-45 cm) + base rotation (-180-180 deg).
- Physical controls on the box: SEQ1/SEQ2 buttons, pause switch, stop button,
  repeat switch, SEQ1/SEQ2 LEDs (see firmware pin defines).

## 8. How to run the firmware

1. Open `hazmove_esp32/hazmove_esp32.ino` in Arduino IDE.
2. Install libraries: `WebSocketsServer`, `ArduinoJson`, `ESP32Servo`,
   `AccelStepper`.
3. Flash to the ESP32, open Serial Monitor at 115200.
4. The ESP32 starts a soft-AP; note the printed IP (default `192.168.4.1`).

## 9. How to run the Flutter app

```bash
flutter pub get
flutter run   # pick a device; join the ESP32 Wi-Fi first
```

## 10. Default connection behavior

- Default URL `ws://192.168.4.1:81`; Settings can change it (saved locally).
- App checks local-network availability first (advisory). The WebSocket
  handshake is authoritative: AP-only networks without internet work fine.
- Drops trigger auto-reconnect; after 10 failed attempts reconnect gives up
  and the user retries manually from Settings.

## 11. Project architecture

```text
lib/
  main.dart                        # DI -> localization -> hydrated theme -> app
  core/
    constants/app_constants.dart   # limits == protocol.md == firmware
    di/main_di.dart                # GetIt wiring
    error/failure.dart             # Failure taxonomy + user messages
    network/network_info.dart      # local-network availability (advisory)
    routing/                       # 4 routes + connection guard
    style/                         # theme cubit, colors, glass UI
    utils/                         # validators (firmware limits), logger
  modules/robot_control/
    domain/
      entities/                    # RobotArm/Servo/LinearRail/Base/Preset
      enums/                       # RobotMode{manual,auto,seq1,seq2}, RobotStatus
      repo/                        # RobotControlRepo contract
    data/
      models/                      # serialization models (extend entities)
      mappers/                     # data <-> domain conversion
      providers/                   # WS data source, local DS, repo impl
      protocol/                    # typed commands/responses/tracker/ids
      services/                    # preset cancellation tokens
  presentation/view/
    root/                          # app + RobotControlCubit (+ responsibility mixins)
    home/                          # dashboard, visualization, connection card
    manual/                        # servo / rail / base controls
    auto/                          # auto sequences + presets (cubits, widgets)
    settings/                      # connection, limits, theme/language, about
test/                              # protocol, data, cubit, widget suites (96 tests)
```

There is no `usecases/` layer (Cubits call the repository directly) and no
`features/` folder — earlier docs describing them were outdated.

## 12. Testing

```bash
flutter analyze
flutter test        # 98 unit/cubit/widget tests, no hardware needed
```

Suites: command serialization + boundary validation, response parsing
(ack/done/reject/error/invalid JSON/missing commandId), tracker correlation +
timeout, `RobotArmModel.fromJson` variants, repository send/await/failure
mapping, preset execution + cancellation, cubit guards + DONE/reject/timeout,
connection states, widgets (sliders disabled while moving, status, limits,
connection card). CI (`.github/workflows/ci.yml`) runs
`analyze` + `test` + `build apk --debug` and fails on any of them.

## 13. Known limitations

- `isMoving` in firmware status frames is always `false`; completion is
  tracked via `done`, not via status.
- Firmware `lastUpdated` is a hardcoded placeholder timestamp; the app stamps
  arrival time locally.
- Very slow long rail moves (speed 1) can exceed the DONE-await ceiling; the
  firmware keeps moving and the app reports a timeout — the timeout estimate
  still needs hardware calibration (see code TODOs).
- Dynamic validation messages (limit values, reject reasons) are English-only;
  static banners are localized (EN/AR).
- Package translation assets are not served under `flutter test`, so widget
  tests assert localization keys rather than rendered strings.

## 14. Future improvements (Planned / TODO)

- [ ] Define a safety-reviewed `Sequence2()` choreography with hardware owners,
      then re-enable Auto Mode 2 (currently disabled by design + firmware
      rejects `seq2`).
- [ ] Calibrate DONE-await ceilings against measured axis speeds.
- [ ] Send real timestamps / sequence numbers in firmware status frames.
- [ ] Expose reconnect attempt count in the UI with a manual Retry button.
- [ ] Per-robot connection profiles (custom names, multiple saved URLs).
- [ ] Localize dynamic validation/reject messages with message arguments.

### Implemented (not planned)

WebSocket transport, typed ACK/DONE/REJECT/ERROR protocol, centralized
verified limits (servo 0-180, rail 0-45 cm, base +-180 deg), per-execution
preset cancellation, real network-availability check, 98-test suite, CI,
dependency cleanup, failure taxonomy with user messages.

### Explicitly NOT implemented

Bluetooth control, HTTP communication, cloud accounts, offline command queue.
