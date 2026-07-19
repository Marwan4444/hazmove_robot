# HazMove Robot Control System - ESP32 WebSocket Integration Report

This report documents the implementation details of the ESP32 WebSocket integration for the HazMove Robot. The firmware allows wireless, low-latency, real-time control of the robotic arm and linear rail from a Flutter mobile application.

---

## 1. Libraries, Constants, and Pin Configurations

```cpp
#include <WiFi.h>
#include <WebSocketsServer.h>
#include <ArduinoJson.h>
#include <ESP32Servo.h>
#include <AccelStepper.h>

#define WIFI_AP_MODE true

const char* ssid = "HazMove_Robot_AP";
const char* password = "Password123";

WebSocketsServer webSocket = WebSocketsServer(81);

#define BTN_SEQ1      34
#define BTN_SEQ2      35
#define PAUSE_SWITCH  14
#define BTN_STOP      12
#define SWITCH_REPEAT 13

#define LED_SEQ1 23
#define LED_SEQ2 22

Servo RobotUD1;   // GPIO 19 (Base elevation)
Servo RobotUD2;   // GPIO 18 (Base elevation - inverted)
Servo HandFB;     // GPIO 5
Servo HandUD;     // GPIO 15
Servo HandOC;     // GPIO 21
Servo HandR;      // GPIO 4

#define BASE_STEP 26
#define BASE_DIR  25
#define LIN_STEP  33
#define LIN_DIR   32

AccelStepper stepperBase(AccelStepper::DRIVER, BASE_STEP, BASE_DIR);
```

### Explanation
This section includes all critical libraries and hardware definitions:
* **`WiFi.h`**: Manages the Wi-Fi hardware peripheral.
* **`WebSocketsServer.h`**: Manages TCP connections on port 81, allowing raw frame exchange.
* **`ArduinoJson.h`**: Serializes and deserializes payloads.
* **`ESP32Servo.h` & `AccelStepper.h`**: Interface with the physical servos and stepper motor drivers.
* **`WIFI_AP_MODE = true`**: Configures the ESP32 to host its own Access Point SSID ("HazMove_Robot_AP") to enable direct peer-to-peer control without external routers.

---

## 2. System States and Position Tracking

```cpp
bool runningSequence = false;
bool seq1Active = false;
bool seq2Active = false;
bool initialDone = false;
bool forceStop = false;        // Emergency stop flag
bool softwarePause = false;    // Remote pause flag

float currentLinearCM = 0.0;
float currentBaseDegrees = 0.0;

unsigned long lastBlinkTime = 0;
bool ledBlinkState = false;
const unsigned long BLINK_INTERVAL = 200;

const float STEPS_PER_DEGREE = 2.2222222222;
const float STEPS_PER_CM = 2000;
const int DEFAULT_BASE_SPEED = 1000;
```

### Explanation
State variables manage the operating mode of the robot:
* **`runningSequence`**, **`seq1Active`**, **`seq2Active`**: Manage automatic sequence statuses.
* **`forceStop`**: Controls emergency stops. Setting it to `true` instantly halts all motor movements.
* **`softwarePause`**: Stores the remote pause state sent by the mobile app.
* **`currentLinearCM`** and **`currentBaseDegrees`**: Maintain the coordinate state of the actuators, syncing physical positions with the visual interface on the mobile phone.

---

## 3. Logical-to-Physical Servo Mapping

```cpp
void controlServoById(int id, int targetAngle, int speedDelay) {
  if (id == 1) {
    int start = HandFB.read();
    MoveServo(HandFB, start, targetAngle, speedDelay);
  } 
  else if (id == 2) {
    int targetScaled = map(targetAngle, 0, 180, 0, 100);
    static int currentArmAngle = 50;
    MoveArm(currentArmAngle, targetScaled, speedDelay);
    currentArmAngle = targetScaled;
  } 
  else if (id == 3) {
    int start = HandUD.read();
    MoveServo(HandUD, start, targetAngle, speedDelay);
  } 
  else if (id == 4) {
    int start = HandR.read();
    MoveServo(HandR, start, targetAngle, speedDelay);
  } 
  else if (id == 5) {
    int start = HandOC.read();
    MoveServo(HandOC, start, targetAngle, speedDelay);
  }
}
```

### Explanation
Translates logical indices transmitted by the mobile client (Servo IDs 1 to 5) into specific physical servos:
* **ID 1**: Maps to `HandFB` (Forward/Backward servo).
* **ID 2**: Maps to `RobotUD1`/`RobotUD2` (Shoulder elevation dual joint) via the custom `MoveArm()` function. It constrains the 0-180 target to a safe physical boundary of 0-100.
* **ID 3**: Maps to `HandUD` (Up/Down wrist servo).
* **ID 4**: Maps to `HandR` (Wrist rotation servo).
* **ID 5**: Maps to `HandOC` (Gripper / Open-Close servo).

---

## 4. WebSocket Event Callback and Command Parsing

```cpp
void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      Serial.printf("[%u] Disconnected!\n", num);
      break;
    case WStype_CONNECTED: {
      IPAddress ip = webSocket.remoteIP(num);
      Serial.printf("[%u] Connected from %s\n", num, ip.toString().c_str());
      forceStop = false;
      sendStatusToClient();
      break;
    }
    case WStype_TEXT: {
      StaticJsonDocument<256> doc;
      DeserializationError error = deserializeJson(doc, payload);
      if (error) return;
      
      const char* commandType = doc["type"];
      if (strcmp(commandType, "servo") == 0) {
        int id = doc["servo_id"];
        int targetAngle = doc["end"];
        int speed = doc["speed"];
        int speedDelay = map(speed, 1, 100, 30, 2);
        
        forceStop = false;
        controlServoById(id, targetAngle, speedDelay);
      }
      else if (strcmp(commandType, "linear") == 0) {
        double targetDistance = doc["distance"];
        forceStop = false;
        
        double delta = targetDistance - currentLinearCM;
        if (delta != 0) {
          char dir = (delta > 0) ? 'R' : 'L';
          MoveLinearCM(abs(delta), dir);
        }
      }
      else if (strcmp(commandType, "base") == 0) {
        double targetDegrees = doc["degrees"];
        int speed = doc["speed"];
        int stepperSpeed = map(speed, 1, 100, 100, 2000);
        
        forceStop = false;
        double deltaDegrees = targetDegrees - currentBaseDegrees;
        if (deltaDegrees != 0) {
          MoveBaseDegrees(deltaDegrees, stepperSpeed);
        }
      }
      else if (strcmp(commandType, "stop") == 0) {
        forceStop = true;
        stepperBase.stop();
        sendStatusToClient();
      }
      else if (strcmp(commandType, "pause") == 0) {
        softwarePause = true;
        sendStatusToClient();
      }
      else if (strcmp(commandType, "resume") == 0) {
        softwarePause = false;
        sendStatusToClient();
      }
      break;
    }
  }
}
```

### Explanation
This function acts as the central asynchronous message receiver:
* Listens for connection events and receives textual JSON frames.
* Parses variables using a 256-byte static JSON document.
* Translates target inputs into motor control instructions (e.g., mapping speed percentage to step speed or delay duration, and calculating step differences for position changes).
* Processes emergency stop and pause triggers immediately.

---

## 5. Dynamic Status Serialization & Feedback Broadcaster

```cpp
void sendStatusToClient() {
  StaticJsonDocument<1024> doc;
  doc["type"] = "status";
  JsonObject data = doc.createNestedObject("data");
  JsonArray servos = data.createNestedArray("servos");

  // Serialize Servo 1
  JsonObject s1 = servos.createNestedObject();
  s1["id"] = 1; s1["name"] = "Base Servo";
  s1["currentAngle"] = HandFB.read(); s1["targetAngle"] = HandFB.read();
  s1["speed"] = 50; s1["isMoving"] = false;

  // Serialize Servo 2
  JsonObject s2 = servos.createNestedObject();
  s2["id"] = 2; s2["name"] = "Shoulder Servo";
  s2["currentAngle"] = map(RobotUD1.read(), 0, 120, 0, 180);
  s2["targetAngle"] = map(RobotUD1.read(), 0, 120, 0, 180);
  s2["speed"] = 50; s2["isMoving"] = false;

  // ... (Other Servos 3, 4, 5 serialized here)

  JsonObject linearRail = data.createNestedObject("linearRail");
  linearRail["currentPosition"] = currentLinearCM;
  linearRail["targetPosition"] = currentLinearCM;
  linearRail["speed"] = 50; linearRail["isMoving"] = false;

  JsonObject baseRotation = data.createNestedObject("baseRotation");
  baseRotation["currentDegrees"] = currentBaseDegrees;
  baseRotation["targetDegrees"] = currentBaseDegrees;
  baseRotation["speed"] = 50; baseRotation["isMoving"] = false;

  data["mode"] = (seq1Active || seq2Active) ? "auto" : "manual";
  data["status"] = forceStop ? "error" : ((softwarePause || digitalRead(PAUSE_SWITCH) == LOW) ? "paused" : (runningSequence ? "moving" : "idle"));
  data["isConnected"] = true;
  data["lastUpdated"] = "2026-06-30T18:05:25.000Z";

  String output;
  serializeJson(doc, output);
  webSocket.broadcastTXT(output);
}
```

### Explanation
This function formats and broadcasts the current telemetry data to the mobile client:
* Builds a JSON payload wrapping all servo angles, stepper positions, operating mode, and safety status.
* Mapped output parameters match the `RobotArmModel` models expected by the Flutter app.
* Transmits data as raw text frames to synchronize the mobile phone's GUI and 3D visual simulator.

---

## 6. Multi-tasking & Non-blocking Management

```cpp
bool KeepAlive() {
  webSocket.loop();
  PauseButton();
  if (forceStop) {
    return false;
  }
  return true;
}

void PauseButton() {
  while (digitalRead(PAUSE_SWITCH) == LOW || softwarePause) {
    webSocket.loop();
    PauseLED();
  }
  if (seq1Active) digitalWrite(LED_SEQ1, HIGH);
  if (seq2Active) digitalWrite(LED_SEQ2, HIGH);
}
```

### Explanation
To prevent TCP timeouts during long, blocking movements (e.g. servo sweeps or stepper pulse sequences):
* **`KeepAlive()`**: Must be placed within all movement loops. It continuously executes `webSocket.loop()` and checks for emergency stops. If `forceStop` is triggered, it aborts the movement instantly.
* **`PauseButton()`**: Includes `webSocket.loop()` within its loop. This allows the ESP32 to remain responsive during pause states, ensuring it can receive the wireless `resume` command from the phone.

---

## 7. Actuator Motion Control Logic

```cpp
void MoveServo(Servo &servo, int startAngle, int endAngle, int speedDelay) {
  if (startAngle > endAngle) {
    for (int a = startAngle; a >= endAngle; a--) {
      if (!KeepAlive()) break;
      servo.write(constrain(a, 0, 180));
      delay(speedDelay);
    }
  } else {
    for (int a = startAngle; a <= endAngle; a++) {
      if (!KeepAlive()) break;
      servo.write(constrain(a, 0, 180));
      delay(speedDelay);
    }
  }
  sendStatusToClient();
}

void MoveLinearCM(float cm, char direction) {
  long steps = cm * STEPS_PER_CM;
  if (direction == 'L') {
    digitalWrite(LIN_DIR, LOW);
    currentLinearCM -= cm;
  } else if (direction == 'R') {
    digitalWrite(LIN_DIR, HIGH);
    currentLinearCM += cm;
  } else return;

  for (long i = 0; i < abs(steps); i++) {
    if (!KeepAlive()) break;
    digitalWrite(LIN_STEP, HIGH);
    delayMicroseconds(200);
    digitalWrite(LIN_STEP, LOW);
    delayMicroseconds(200);
  }
  sendStatusToClient();
}
```

### Explanation
Controls physical actuator drivers:
* **`MoveServo()`**: Adjusts positions incrementally with intermediate `KeepAlive` checks to allow speed control.
* **`MoveLinearCM()`**: Drives the linear stepper motor direction and step pins, translating distance in centimeters into electrical steps, while updating the tracking variables.

---

## 8. Initialization and Execution Poll

```cpp
void setup() {
  Serial.begin(115200);
  // Wi-Fi setup...
  webSocket.begin();
  webSocket.onEvent(webSocketEvent);
  
  // Servo Attachments...
  RobotUD1.attach(19);
  RobotUD2.attach(18);
  HandFB.attach(5);
  HandUD.attach(15);
  HandOC.attach(21);
  HandR.attach(4);
  
  stepperBase.setMaxSpeed(1000);
  stepperBase.setAcceleration(500);
}

void loop() {
  webSocket.loop();
  
  if (!initialDone) {
    InitialPosition();
    initialDone = true;
  }
  
  // Buttons and Sequence Trigger Polls...
  
  static unsigned long lastStatusTime = 0;
  if (millis() - lastStatusTime > 1000) {
    lastStatusTime = millis();
    sendStatusToClient(); // Telemetry Heartbeat
  }
}
```

### Explanation
Main execution framework:
* **`setup()`**: Initializes serial baud rate, connects Wi-Fi, activates the WebSocket server and binds callbacks, attaches servos, and configures stepper limits.
* **`loop()`**: Polling loop executing `webSocket.loop()` continuously. Performs startup calibration, monitors physical input switches, and maintains a 1Hz telemetry heartbeat to keep the client synchronized.
