# HazMove Robot — WebSocket Protocol (Authoritative)

> Single source of truth for Flutter ↔ ESP32 communication.
> Rule: `Flutter command schema == docs/protocol.md == ESP32 parser`.
> Transport: single persistent WebSocket, default `ws://192.168.4.1:81`
> (ESP32 soft-AP). All messages are JSON objects with a string `type` field.
> Encoding: UTF-8. Firmware parses with ArduinoJson; Flutter with `dart:convert`.

## 1. Physical limits (authoritative — verified in firmware)

These are the **final safety authority** (enforced with `constrain()` /
range-reject on ESP32). Flutter validation mirrors them for UX only.

| Axis | Min | Max | Unit | Firmware constant | Flutter constant |
|---|---|---|---|---|---|
| Servo angle (IDs 1–5) | 0 | 180 | degrees | `MIN_SERVO_ANGLE` / `MAX_SERVO_ANGLE` | `AppConstants.minServoAngle` / `maxServoAngle` |
| Linear rail position | 0.0 | 45.0 | cm | `MIN_LINEAR_CM` / `MAX_LINEAR_CM` | `AppConstants.minLinearDistance` / `maxLinearDistance` |
| Base rotation (absolute target) | −180.0 | 180.0 | degrees | `MIN_BASE_DEGREES` / `MAX_BASE_DEGREES` | `AppConstants.minBaseRotation` / `maxBaseRotation` |
| Speed (all axes) | 1 | 100 | unitless (1 = slowest, 100 = fastest) | `MIN_SPEED` / `MAX_SPEED` | `AppConstants.min*Speed` / `max*Speed` |
| Servo ID | 1 | 5 | — | hardcoded `id < 1 \|\| id > 5` | `ServoIds` |

Servo ID map: `1 = HandFB`, `2 = Shoulder (MoveArm, FW maps 0–180 → 0–100)`,
`3 = HandUD`, `4 = HandR (wrist)`, `5 = HandOC (gripper)`.

## 2. Commands (Flutter → ESP32)

Every movement/mode command **MUST** include a client-generated `commandId`
(string, uuid-like unique per command). The firmware echoes it in
`ack` / `done` / `reject` / `error` so Flutter can correlate
`command → ACK → DONE/REJECT/ERROR`. Commands without `commandId` are still
executed (backwards compatibility) but get no correlated response.

### 2.1 `servo` — move one servo

```json
{ "type": "servo", "commandId": "uuid", "servo_id": 1, "end": 90, "speed": 50 }
```

| Field | Required | Type | Range | Notes |
|---|---|---|---|---|
| `type` | yes | string | `"servo"` | |
| `commandId` | yes (new) | string | non-empty | echoed in responses |
| `servo_id` | yes | int | 1–5 | else `reject(INVALID_SERVO_ID)` |
| `end` | yes | int | 0–180 | target angle; FW clamps defensively but rejects out-of-range explicitly when `commandId` present |
| `speed` | no | int | 1–100, default 50 | FW maps 1–100 → delay 30–2 ms |

Expected: `ack` immediately, then `done` after the blocking move finishes.
Rejection: `reject` with `OUT_OF_RANGE` / `INVALID_SERVO_ID` / `BUSY`
(sequence running or servo already moving). Legacy firmware without
`commandId` support silently ignores while busy (Serial log only).

### 2.2 `linear` — move linear rail to absolute position

```json
{ "type": "linear", "commandId": "uuid", "distance": 20.5, "speed": 80 }
```

| Field | Required | Type | Range | Notes |
|---|---|---|---|---|
| `type` | yes | string | `"linear"` | |
| `commandId` | yes | string | non-empty | |
| `distance` | yes | number | 0.0–45.0 cm | absolute target (`currentLinearCM` origin); FW rejects outside |
| `speed` | no | int | 1–100, default 50 | maps to 5000–500 µs step delay |

Expected: `ack` → `done`. Rejection: `OUT_OF_RANGE`, `BUSY`.
Moves < 0.05 cm are no-ops (still `ack` + `done`).

### 2.3 `base` — rotate base to absolute angle

```json
{ "type": "base", "commandId": "uuid", "degrees": -90.0, "speed": 60 }
```

| Field | Required | Type | Range | Notes |
|---|---|---|---|---|
| `type` | yes | string | `"base"` | |
| `commandId` | yes | string | non-empty | |
| `degrees` | yes | number | −180.0–180.0 | absolute target; FW rejects outside |
| `speed` | no | int | 1–100, default 50 | maps to 100–2000 steps/s |

Expected: `ack` → `done`. Rejection: `OUT_OF_RANGE`, `BUSY`.
Moves < 0.5° are no-ops (still `ack` + `done`).

### 2.4 `stop` — emergency stop

```json
{ "type": "stop", "commandId": "uuid" }
```

No other fields. Always accepted when JSON is valid. Clears all motion flags,
stops steppers/sequences, cancels app-side preset execution. Response: `ack`
followed by `done` (both with `commandId` if supplied) plus a `status`
broadcast. `stop` without `commandId` gets a `status` broadcast only (legacy).

### 2.5 `pause` — pause movements

```json
{ "type": "pause", "commandId": "uuid" }
```

Sets `softwarePause`. Response: `ack` (+ `status` with `"status": "paused"`).

### 2.6 `resume` — resume movements

```json
{ "type": "resume", "commandId": "uuid" }
```

Clears `softwarePause`/`forceStop`. Response: `ack` (+ `status`).

### 2.7 `mode` — change operating mode

```json
{ "type": "mode", "commandId": "uuid", "mode": "seq1" }
```

| Field | Required | Type | Values |
|---|---|---|---|
| `type` | yes | string | `"mode"` |
| `commandId` | yes | string | non-empty |
| `mode` | yes | string | `"manual"` \| `"seq1"` (Sequence 1). `"auto"` is accepted as an alias of `"seq1"` for backwards compatibility. `"seq2"` is **not supported** (see §5) — firmware replies `reject(SEQUENCE_NOT_IMPLEMENTED)` and the app must not offer it. |

Expected: `ack` (+ `status` with matching `data.mode`). Unknown mode →
`reject(INVALID_MODE)`.

## 3. Responses (ESP32 → Flutter)

### 3.1 `ack` — command accepted

```json
{ "type": "ack", "commandId": "uuid", "status": "accepted" }
```

Sent immediately after parsing a valid command, before motion starts.

### 3.2 `done` — command completed

```json
{ "type": "done", "commandId": "uuid", "status": "completed" }
```

Sent after the blocking motion function returns (or immediately for
no-op/stop/pause/resume/mode).

### 3.3 `reject` — command refused without execution

```json
{ "type": "reject", "commandId": "uuid", "reason": "OUT_OF_RANGE" }
```

Reasons: `OUT_OF_RANGE` | `INVALID_SERVO_ID` | `BUSY` | `INVALID_MODE` |
`SEQUENCE_NOT_IMPLEMENTED` | `MISSING_FIELD` | `INVALID_JSON`.
Never silently discard a `commandId`-bearing command.

### 3.4 `error` — command failed during/after acceptance

```json
{ "type": "error", "commandId": "uuid", "reason": "..." }
```

E.g. emergency stop interrupted the move (`INTERRUPTED`), JSON parse failure
without recoverable `commandId`.

### 3.5 `status` — periodic/event snapshot (throttled app-side ~30 FPS)

```json
{
  "type": "status",
  "data": {
    "servos": [
      { "id": 1, "name": "Base Servo", "currentAngle": 0, "targetAngle": 0, "speed": 50, "isMoving": false }
    ],
    "linearRail": { "currentPosition": 0.0, "targetPosition": 0.0, "speed": 50, "isMoving": false },
    "baseRotation": { "currentDegrees": 0.0, "targetDegrees": 0.0, "speed": 50, "isMoving": false },
    "mode": "manual",
    "status": "idle",
    "isConnected": true,
    "lastUpdated": "2026-06-30T18:05:25.000Z"
  }
}
```

- `data.mode`: `"manual"` | `"seq1"` | `"seq2"` (firmware never sends `"auto"`).
- `data.status`: `"idle"` | `"moving"` | `"paused"` | `"error"`.
- `isMoving` fields are currently always `false` (firmware limitation, TODO).
- `lastUpdated` is a firmware placeholder timestamp (TODO: send `millis()`).
  The app stamps arrival time locally.
- Status frames carry **no** `commandId` and are throttled (32 ms) at the
  transport edge. `ack`/`done`/`reject`/`error` bypass throttling.

## 4. Correlation state machine

```text
Flutter                    ESP32
   |  cmd(commandId)          |
   |------------------------->|
   |  ack(commandId)          |
   |<-------------------------|
   |  ... motion ...          |
   |  done(commandId)         |
   |<-------------------------|
   |  status (periodic)       |
   |<-------------------------|
```

- Normal completion: `DONE`. Rejection: `REJECT`. Failure: `ERROR`.
- Safety timeout stays as defensive fallback (servo/base ~3 s, linear scaled
  5–120 s) and surfaces `FailureType.timeout` if no terminal frame arrives.
- UI must not treat timeout expiry as success.

## 5. Sequence 2

`Sequence2()` is an **empty stub** in firmware. There is no documented
choreography. Therefore Mode 2 is **disabled**: the app hides it and documents
it as TODO; firmware answers `reject(SEQUENCE_NOT_IMPLEMENTED)` if `seq2` is
ever requested. Do not invent arm choreography without hardware sign-off.

## 6. Backwards compatibility

- Pre-`commandId` clients: commands without `commandId` execute exactly as
  before (no correlated response; status broadcast only). Rejections are still
  Serial-logged.
- `mode: "auto"` ≡ `mode: "seq1"`.
- `servo.start` is ignored (firmware reads `servo.read()`).

## 7. Error catalogue

| Reason | Meaning | Producer |
|---|---|---|
| `OUT_OF_RANGE` | numeric field outside §1 limits | FW `reject` / app `FailureType.invalidInput` |
| `INVALID_SERVO_ID` | `servo_id` ∉ 1–5 | FW `reject` |
| `BUSY` | axis moving or sequence running | FW `reject` |
| `INVALID_MODE` | unknown `mode` value | FW `reject` |
| `SEQUENCE_NOT_IMPLEMENTED` | `seq2` requested | FW `reject` |
| `MISSING_FIELD` | required field absent | FW `reject` |
| `INVALID_JSON` | unparsable payload | FW `error` (no `commandId`) |
| `INTERRUPTED` | stop/forceStop aborted motion | FW `error` |
| timeout (no terminal frame) | defensive fallback | app `FailureType.timeout` |
| transport down | socket closed / unreachable | app `FailureType.noInternet` / `disconnected` |
