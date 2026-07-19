/* ========= HAZMOVE ROBOT CONTROLLER WITH WEBSOCKETS ========= */
/* ================================================================
   FIX LOG:
   [FIX 1] IP الافتراضي للـ ESP32 في وضع AP هو 192.168.4.1:81
           - تأكد أن Flutter تستخدم: ws://192.168.4.1:81
   [FIX 2] إضافة قراءة speed في أمر "linear" والتطبيق عليه
   [FIX 3] تحسين أمر "mode" لدعم seq1/seq2 بشكل صحيح
   [FIX 4] أمر السيرفو: Flutter بترسل "end" فقط (بدون "start")
           - ESP32 يقرأ الموضع الحالي من servo.read() تلقائياً
   ================================================================ */

#include <WiFi.h>
#include <WebSocketsServer.h>
#include <ArduinoJson.h>
#include <ESP32Servo.h>
#include <AccelStepper.h>

/* ========= CONFIGURATION ========= */
#define WIFI_AP_MODE true // false = اتصال بروتر المنزل

const char* ssid     = "A54";
const char* password = "00000000";

WebSocketsServer webSocket = WebSocketsServer(81);

/* ========= FUNCTION PROTOTYPES ========= */
void InitialPosition();
void PauseButton();
void PauseLED();
void MoveServo(Servo &servo, int startAngle, int endAngle, int speedDelay);
void MoveArm(int startAngle, int endAngle, int speedDelay);
void Sequence1();
void Sequence2();
void sendStatusToClient();
bool KeepAlive();
void MoveBaseDegrees(float degrees, int speed);
void MoveLinearCM(float cm, char direction, int stepDelayUs); // [FIX 2] إضافة stepDelayUs

/* ========= BUTTONS & SWITCH ========= */
#define BTN_SEQ1      34
#define BTN_SEQ2      35
#define PAUSE_SWITCH  14
#define BTN_STOP      12
#define SWITCH_REPEAT 13

/* ========= LEDS ========= */
#define LED_SEQ1 23
#define LED_SEQ2 22

/* ========= SERVO OBJECTS ========= */
Servo RobotUD1;   // GPIO 19 (Base elevation)
Servo RobotUD2;   // GPIO 18 (Base elevation - inverted)
Servo HandFB;     // GPIO 5
Servo HandUD;     // GPIO 15
Servo HandOC;     // GPIO 21
Servo HandR;      // GPIO 4

/* ========= STATES ========= */
bool runningSequence = false;
bool seq1Active      = false;
bool seq2Active      = false;
bool initialDone     = false;
bool forceStop       = false;
bool softwarePause   = false;

/* ========= POSITION TRACKING ========= */
float currentLinearCM    = 0.0;
float currentBaseDegrees = 0.0;

/* ========= PAUSE LED BLINK ========= */
unsigned long lastBlinkTime  = 0;
bool          ledBlinkState  = false;
const unsigned long BLINK_INTERVAL = 200;

/* ========= STEPPER ========= */
#define BASE_STEP 26
#define BASE_DIR  25
#define LIN_STEP  33
#define LIN_DIR   32

AccelStepper stepperBase(AccelStepper::DRIVER, BASE_STEP, BASE_DIR);

const float STEPS_PER_DEGREE  = 2.2222222222;
const float STEPS_PER_CM      = 2000;
const int   DEFAULT_BASE_SPEED = 1000;

// [FIX 2] ثوابت حدود سرعة السكة الخطية
// speed من Flutter: 1 (أبطأ) → 100 (أسرع)
// stepDelay بالمايكروثانية: 500 (سريع) → 5000 (بطيء)
const int LINEAR_FAST_DELAY_US = 500;
const int LINEAR_SLOW_DELAY_US = 5000;

/* ========= CONTROL SERVOS BY APP ID ========= */
void controlServoById(int id, int targetAngle, int speedDelay) {
  // ID 1: HandFB  (Forward/Backward)
  // ID 2: RobotUD1/RobotUD2 (Shoulder - MoveArm)
  // ID 3: HandUD  (Up/Down)
  // ID 4: HandR   (Wrist rotation)
  // ID 5: HandOC  (Gripper Open/Close)

  if (id == 1) {
    // [FIX 4] نقرأ الموضع الحالي من السيرفو مباشرة (Flutter ما بترسل "start" بعد الآن)
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

/* ========= WEBSOCKET EVENT CALLBACK ========= */
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
      Serial.printf("[%u] Received: %s\n", num, payload);

      StaticJsonDocument<256> doc;
      DeserializationError error = deserializeJson(doc, payload);
      if (error) {
        Serial.print("JSON Error: ");
        Serial.println(error.f_str());
        return;
      }

      const char* commandType = doc["type"];

      // ── أمر السيرفو ──────────────────────────────────────────────
      if (strcmp(commandType, "servo") == 0) {
        int id          = doc["servo_id"];
        int targetAngle = doc["end"];
        int speed       = doc["speed"];
        int speedDelay  = map(speed, 1, 100, 30, 2);

        forceStop = false;
        controlServoById(id, targetAngle, speedDelay);
      }

      // ── أمر السكة الخطية (مع speed) ─────────────────────────────
      // [FIX 2] قراءة واستخدام speed لتحديد سرعة السكة فعلياً
      else if (strcmp(commandType, "linear") == 0) {
        double targetDistance = doc["distance"];
        int    speed          = doc["speed"] | 50; // قيمة افتراضية 50 لو مش موجودة

        // تحويل speed (1-100) إلى تأخير (5000-500 مايكروثانية)
        int stepDelayUs = map(speed, 1, 100, LINEAR_SLOW_DELAY_US, LINEAR_FAST_DELAY_US);

        forceStop = false;
        double delta = targetDistance - currentLinearCM;
        if (delta != 0) {
          char dir = (delta > 0) ? 'R' : 'L';
          MoveLinearCM(abs(delta), dir, stepDelayUs); // [FIX 2] نمرر السرعة
        }
      }

      // ── أمر القاعدة الدوارة ──────────────────────────────────────
      else if (strcmp(commandType, "base") == 0) {
        double targetDegrees = doc["degrees"];
        int    speed         = doc["speed"];
        int    stepperSpeed  = map(speed, 1, 100, 100, 2000);

        forceStop = false;
        double deltaDegrees = targetDegrees - currentBaseDegrees;
        if (deltaDegrees != 0) {
          MoveBaseDegrees(deltaDegrees, stepperSpeed);
        }
      }

      // ── إيقاف طارئ ───────────────────────────────────────────────
      else if (strcmp(commandType, "stop") == 0) {
        forceStop = true;
        stepperBase.stop();
        runningSequence = false;
        seq1Active      = false;
        seq2Active      = false;
        digitalWrite(LED_SEQ1, LOW);
        digitalWrite(LED_SEQ2, LOW);
        Serial.println("EMERGENCY STOP!");
        sendStatusToClient();
      }

      // ── إيقاف مؤقت ───────────────────────────────────────────────
      else if (strcmp(commandType, "pause") == 0) {
        softwarePause = true;
        sendStatusToClient();
      }

      // ── استئناف ──────────────────────────────────────────────────
      else if (strcmp(commandType, "resume") == 0) {
        softwarePause = false;
        forceStop     = false;
        sendStatusToClient();
      }

      // ── تغيير الوضع [FIX 3] ──────────────────────────────────────
      // Flutter بترسل: { "type": "mode", "mode": "auto" }
      //             أو { "type": "mode", "mode": "manual" }
      //             أو { "type": "mode", "mode": "seq1" }
      //             أو { "type": "mode", "mode": "seq2" }
      else if (strcmp(commandType, "mode") == 0) {
        const char* mode = doc["mode"];

        if (strcmp(mode, "auto") == 0 || strcmp(mode, "seq1") == 0) {
          // [FIX 3] تشغيل التسلسل 1 بوضوح
          if (!runningSequence) {
            runningSequence = true;
            seq1Active      = true;
            seq2Active      = false;
            forceStop       = false;
            digitalWrite(LED_SEQ1, HIGH);
            digitalWrite(LED_SEQ2, LOW);
          }
        }
        else if (strcmp(mode, "seq2") == 0) {
          // [FIX 3] تشغيل التسلسل 2 بوضوح
          if (!runningSequence) {
            runningSequence = true;
            seq2Active      = true;
            seq1Active      = false;
            forceStop       = false;
            digitalWrite(LED_SEQ2, HIGH);
            digitalWrite(LED_SEQ1, LOW);
          }
        }
        else if (strcmp(mode, "manual") == 0) {
          // [FIX 3] إيقاف كل التسلسلات والعودة للوضع اليدوي
          forceStop       = true; // يوقف الحركة الحالية
          runningSequence = false;
          seq1Active      = false;
          seq2Active      = false;
          digitalWrite(LED_SEQ1, LOW);
          digitalWrite(LED_SEQ2, LOW);
          Serial.println("Switched to MANUAL mode");
        }
        sendStatusToClient();
      }
      break;
    }
  }
}

/* ========= SEND SYSTEM STATUS TO MOBILE ========= */
void sendStatusToClient() {
  StaticJsonDocument<1024> doc;
  doc["type"] = "status";

  JsonObject data   = doc.createNestedObject("data");
  JsonArray  servos = data.createNestedArray("servos");

  JsonObject s1 = servos.createNestedObject();
  s1["id"]           = 1;
  s1["name"]         = "Base Servo";
  s1["currentAngle"] = HandFB.read();
  s1["targetAngle"]  = HandFB.read();
  s1["speed"]        = 50;
  s1["isMoving"]     = false;

  JsonObject s2 = servos.createNestedObject();
  s2["id"]           = 2;
  s2["name"]         = "Shoulder Servo";
  s2["currentAngle"] = map(RobotUD1.read(), 0, 120, 0, 180);
  s2["targetAngle"]  = map(RobotUD1.read(), 0, 120, 0, 180);
  s2["speed"]        = 50;
  s2["isMoving"]     = false;

  JsonObject s3 = servos.createNestedObject();
  s3["id"]           = 3;
  s3["name"]         = "Elbow Servo";
  s3["currentAngle"] = HandUD.read();
  s3["targetAngle"]  = HandUD.read();
  s3["speed"]        = 50;
  s3["isMoving"]     = false;

  JsonObject s4 = servos.createNestedObject();
  s4["id"]           = 4;
  s4["name"]         = "Wrist Servo";
  s4["currentAngle"] = HandR.read();
  s4["targetAngle"]  = HandR.read();
  s4["speed"]        = 50;
  s4["isMoving"]     = false;

  JsonObject s5 = servos.createNestedObject();
  s5["id"]           = 5;
  s5["name"]         = "Gripper Servo";
  s5["currentAngle"] = HandOC.read();
  s5["targetAngle"]  = HandOC.read();
  s5["speed"]        = 50;
  s5["isMoving"]     = false;

  JsonObject linearRail = data.createNestedObject("linearRail");
  linearRail["currentPosition"] = currentLinearCM;
  linearRail["targetPosition"]  = currentLinearCM;
  linearRail["speed"]           = 50;
  linearRail["isMoving"]        = false;

  JsonObject baseRotation = data.createNestedObject("baseRotation");
  baseRotation["currentDegrees"] = currentBaseDegrees;
  baseRotation["targetDegrees"]  = currentBaseDegrees;
  baseRotation["speed"]          = 50;
  baseRotation["isMoving"]       = false;

  // [FIX 3] إرسال الـ mode الصحيح بناءً على الحالة الفعلية
  if (seq1Active)      data["mode"] = "seq1";
  else if (seq2Active) data["mode"] = "seq2";
  else                 data["mode"] = "manual";

  // الحالة
  if (forceStop)                                        data["status"] = "error";
  else if (softwarePause || digitalRead(PAUSE_SWITCH) == LOW) data["status"] = "paused";
  else if (runningSequence)                             data["status"] = "moving";
  else                                                  data["status"] = "idle";

  data["isConnected"] = true;
  data["lastUpdated"] = "2026-06-30T18:05:25.000Z";

  String output;
  serializeJson(doc, output);
  webSocket.broadcastTXT(output);
}

/* ========= SETUP ========= */
void setup() {
  Serial.begin(115200);

  if (WIFI_AP_MODE) {
    WiFi.softAP(ssid, password);
    IPAddress myIP = WiFi.softAPIP();
    Serial.print("AP IP Address: ");
    Serial.println(myIP); // 192.168.4.1
    Serial.println("Flutter URL: ws://192.168.4.1:81");
  } else {
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED) {
      delay(500);
      Serial.print(".");
    }
    Serial.println("\nConnected to WiFi!");
    Serial.print("Flutter URL: ws://");
    Serial.print(WiFi.localIP());
    Serial.println(":81");
  }

  webSocket.begin();
  webSocket.onEvent(webSocketEvent);

  pinMode(BTN_SEQ1,      INPUT_PULLDOWN);
  pinMode(BTN_SEQ2,      INPUT_PULLDOWN);
  pinMode(PAUSE_SWITCH,  INPUT_PULLUP);
  pinMode(SWITCH_REPEAT, INPUT_PULLUP);
  pinMode(BTN_STOP,      INPUT_PULLDOWN);

  pinMode(BASE_STEP, OUTPUT);
  pinMode(BASE_DIR,  OUTPUT);
  pinMode(LIN_STEP,  OUTPUT);
  pinMode(LIN_DIR,   OUTPUT);

  pinMode(LED_SEQ1, OUTPUT);
  pinMode(LED_SEQ2, OUTPUT);
  digitalWrite(LED_SEQ1, LOW);
  digitalWrite(LED_SEQ2, LOW);

  RobotUD1.attach(19);
  RobotUD2.attach(18);
  HandFB.attach(5);
  HandUD.attach(15);
  HandOC.attach(21);
  HandR.attach(4);

  stepperBase.setMaxSpeed(1000);
  stepperBase.setAcceleration(500);
}

/* ========= BASE STEPPER ========= */
void MoveBaseDegrees(float degrees, int speed = DEFAULT_BASE_SPEED) {
  long steps = degrees * STEPS_PER_DEGREE;
  stepperBase.setMaxSpeed(speed);
  stepperBase.move(steps);

  while (stepperBase.distanceToGo() != 0) {
    if (!KeepAlive()) {
      stepperBase.stop();
      break;
    }
    stepperBase.run();
  }
  currentBaseDegrees += (degrees - (stepperBase.distanceToGo() / STEPS_PER_DEGREE));
  sendStatusToClient();
}

/* ========= KEEP ALIVE ========= */
bool KeepAlive() {
  webSocket.loop();
  PauseButton();
  if (forceStop) return false;
  return true;
}

/* ========= PAUSE LED ========= */
void PauseLED() {
  unsigned long now = millis();
  if (now - lastBlinkTime >= BLINK_INTERVAL) {
    lastBlinkTime  = now;
    ledBlinkState  = !ledBlinkState;
    if (seq1Active) digitalWrite(LED_SEQ1, ledBlinkState);
    if (seq2Active) digitalWrite(LED_SEQ2, ledBlinkState);
  }
}

/* ========= PAUSE BUTTON ========= */
void PauseButton() {
  while (digitalRead(PAUSE_SWITCH) == LOW || softwarePause) {
    webSocket.loop();
    PauseLED();
  }
  if (seq1Active) digitalWrite(LED_SEQ1, HIGH);
  if (seq2Active) digitalWrite(LED_SEQ2, HIGH);
}

/* ========= MOVE ONE SERVO ========= */
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

/* ========= MOVE ARM ========= */
void MoveArm(int startAngle, int endAngle, int speedDelay) {
  startAngle = constrain(startAngle, 0, 100);
  endAngle   = constrain(endAngle,   0, 100);

  if (startAngle > endAngle) {
    for (int a = startAngle; a >= endAngle; a--) {
      if (!KeepAlive()) break;
      RobotUD1.write(map(a, 0, 100,   0, 120));
      RobotUD2.write(map(a, 0, 100, 110,   0));
      delay(speedDelay);
    }
  } else {
    for (int a = startAngle; a <= endAngle; a++) {
      if (!KeepAlive()) break;
      RobotUD1.write(map(a, 0, 100,   0, 120));
      RobotUD2.write(map(a, 0, 100, 110,   0));
      delay(speedDelay);
    }
  }
  sendStatusToClient();
}

/* ========= LINEAR STEPPER (CM) - [FIX 2] إضافة stepDelayUs ========= */
// stepDelayUs: المسافة الزمنية بين كل خطوة (مايكروثانية)
// قيمة صغيرة = سريع | قيمة كبيرة = بطيء
void MoveLinearCM(float cm, char direction, int stepDelayUs = 200) {
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
    delayMicroseconds(stepDelayUs);  // [FIX 2] استخدام السرعة القادمة من التطبيق
    digitalWrite(LIN_STEP, LOW);
    delayMicroseconds(stepDelayUs);
  }
  sendStatusToClient();
}

/* ========= INITIAL POSITION ========= */
void InitialPosition() {
  MoveArm(50, 50, 15);
  MoveServo(HandFB,  0,   0, 15);
  MoveServo(HandUD, 180, 180, 15);
  MoveServo(HandR,  150, 150, 15);
  MoveServo(HandOC, 180, 180, 15);
}

/* ========= SEQUENCES ========= */
void Sequence1() {
  MoveBaseDegrees(-50, 1000);
  MoveServo(HandUD, 180, 45, 10);
  MoveArm(50, 0, 10);
  MoveServo(HandOC, 180, 80, 10);
  MoveServo(HandUD, 45, 10, 10);
  MoveBaseDegrees(50, 1000);
  MoveLinearCM(35, 'L', 200);
  MoveServo(HandUD, 20, 25, 10);
  MoveBaseDegrees(45, 1000);
  MoveServo(HandOC, 80, 180, 10);
  MoveServo(HandUD, 25, 10, 10);
  MoveArm(0, 50, 10);
  MoveBaseDegrees(-45, 1000);
  MoveLinearCM(35, 'R', 200);
  MoveServo(HandUD, 35, 180, 15);
}

void Sequence2() {
  // Sequence 2 - لم يُعرَّف بعد
}

/* ========= LOOP ========= */
void loop() {
  webSocket.loop();

  if (!initialDone) {
    InitialPosition();
    initialDone = true;
  }

  // زر التسلسل 1
  if (!runningSequence && digitalRead(BTN_SEQ1) == HIGH) {
    runningSequence = true;
    seq1Active      = true;
    seq2Active      = false;
    forceStop       = false;
    digitalWrite(LED_SEQ1, HIGH);
    digitalWrite(LED_SEQ2, LOW);
    sendStatusToClient();

    do {
      Sequence1();
    } while (digitalRead(SWITCH_REPEAT) == LOW && KeepAlive());

    seq1Active      = false;
    runningSequence = false;
    digitalWrite(LED_SEQ1, LOW);
    sendStatusToClient();
  }

  // زر التسلسل 2
  if (!runningSequence && digitalRead(BTN_SEQ2) == HIGH) {
    runningSequence = true;
    seq2Active      = true;
    seq1Active      = false;
    forceStop       = false;
    digitalWrite(LED_SEQ2, HIGH);
    digitalWrite(LED_SEQ1, LOW);
    sendStatusToClient();

    do {
      Sequence2();
    } while (digitalRead(SWITCH_REPEAT) == LOW && KeepAlive());

    seq2Active      = false;
    runningSequence = false;
    digitalWrite(LED_SEQ2, LOW);
    sendStatusToClient();
  }

  // تشغيل seq1 من التطبيق (mode: auto/seq1)
  if (runningSequence && seq1Active && !forceStop) {
    do {
      Sequence1();
    } while (digitalRead(SWITCH_REPEAT) == LOW && KeepAlive() && seq1Active);

    seq1Active      = false;
    runningSequence = false;
    digitalWrite(LED_SEQ1, LOW);
    sendStatusToClient();
  }

  // تشغيل seq2 من التطبيق (mode: seq2)
  if (runningSequence && seq2Active && !forceStop) {
    do {
      Sequence2();
    } while (digitalRead(SWITCH_REPEAT) == LOW && KeepAlive() && seq2Active);

    seq2Active      = false;
    runningSequence = false;
    digitalWrite(LED_SEQ2, LOW);
    sendStatusToClient();
  }

  // إرسال status كل ثانية
  static unsigned long lastStatusTime = 0;
  if (millis() - lastStatusTime > 1000) {
    lastStatusTime = millis();
    sendStatusToClient();
  }
}
