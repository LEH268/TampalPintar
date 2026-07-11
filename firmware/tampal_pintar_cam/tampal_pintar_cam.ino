// TampalPintar ESP32-CAM firmware (AI-Thinker module)
// Lifecycle per spec: boot -> NTP sync -> cleanup leftover live/ photos ->
// capture VGA JPEG ~1/s -> upload to Supabase Storage until power-off.
// The kept photos live under reports/ and are never touched by cleanup.

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include "esp_camera.h"
#include "time.h"
#include <sys/time.h>

// ---------------- CONFIG (edit these) ----------------
const char* WIFI_SSID   = "TampalPintar";        // your phone hotspot name
const char* WIFI_PASS   = "potholes123";         // your phone hotspot password
const char* DASHCAM_ID  = "DEMO-CAM-01";         // must match the profile's dashcam_id
// See README.md "Configure the codebase" for where these two values come from.
const char* SUPABASE_URL = "https://YOUR_PROJECT_REF.supabase.co";
const char* SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";
const unsigned long CAPTURE_INTERVAL_MS = 1000;  // ~1 fps
// ------------------------------------------------------

// AI-Thinker ESP32-CAM pin map
#define PWDN_GPIO_NUM  32
#define RESET_GPIO_NUM -1
#define XCLK_GPIO_NUM   0
#define SIOD_GPIO_NUM  26
#define SIOC_GPIO_NUM  27
#define Y9_GPIO_NUM    35
#define Y8_GPIO_NUM    34
#define Y7_GPIO_NUM    39
#define Y6_GPIO_NUM    36
#define Y5_GPIO_NUM    21
#define Y4_GPIO_NUM    19
#define Y3_GPIO_NUM    18
#define Y2_GPIO_NUM     5
#define VSYNC_GPIO_NUM 25
#define HREF_GPIO_NUM  23
#define PCLK_GPIO_NUM  22
#define LED_GPIO_NUM   33   // onboard red LED, active LOW

WiFiClientSecure tls;
unsigned long lastCapture = 0;

void ledOn()  { digitalWrite(LED_GPIO_NUM, LOW); }
void ledOff() { digitalWrite(LED_GPIO_NUM, HIGH); }

bool initCamera() {
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer   = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;
  config.frame_size   = FRAMESIZE_VGA;   // 640x480: ~30-60 KB JPEG
  config.jpeg_quality = 12;
  config.fb_count     = 2;
  config.grab_mode    = CAMERA_GRAB_LATEST;
  config.fb_location  = CAMERA_FB_IN_PSRAM;
  return esp_camera_init(&config) == ESP_OK;
}

void connectWifi() {
  Serial.printf("Joining hotspot %s", WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  for (int i = 0; WiFi.status() != WL_CONNECTED; i++) {
    if (i >= 40) {  // ~20 s to associate -> reboot and retry cleanly
      Serial.println(" failed, rebooting");
      ESP.restart();
    }
    delay(500);
    Serial.print(".");
  }
  Serial.printf("\nConnected, IP %s\n", WiFi.localIP().toString().c_str());
}

void syncTime() {
  configTime(0, 0, "pool.ntp.org", "time.google.com");
  Serial.print("NTP sync");
  for (int i = 0; time(nullptr) < 1700000000; i++) {  // block until a sane epoch arrives
    if (i >= 40) {  // ~20 s with no valid epoch -> reboot and retry cleanly
      Serial.println(" failed, rebooting");
      ESP.restart();
    }
    delay(500);
    Serial.print(".");
  }
  Serial.println(" done");
}

uint64_t epochMs() {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return (uint64_t)tv.tv_sec * 1000ULL + tv.tv_usec / 1000ULL;
}

// Boot-time cleanup: server deletes everything left in live/{DASHCAM_ID}/
// from the previous run. Kept report photos are unaffected.
void cleanupOldPhotos() {
  HTTPClient http;
  String url = String(SUPABASE_URL) + "/functions/v1/dashcam-cleanup";
  http.begin(tls, url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Authorization", String("Bearer ") + SUPABASE_ANON_KEY);
  String body = String("{\"dashcam_id\":\"") + DASHCAM_ID + "\"}";
  int code = http.POST(body);
  Serial.printf("Cleanup -> HTTP %d: %s\n", code, http.getString().c_str());
  http.end();
}

bool uploadFrame(camera_fb_t* fb) {
  char name[24];
  snprintf(name, sizeof(name), "%013llu.jpg", (unsigned long long)epochMs());
  HTTPClient http;
  String url = String(SUPABASE_URL) + "/storage/v1/object/media/live/" +
               DASHCAM_ID + "/" + name;
  http.begin(tls, url);
  http.setTimeout(8000);
  http.addHeader("Content-Type", "image/jpeg");
  http.addHeader("Authorization", String("Bearer ") + SUPABASE_ANON_KEY);
  int code = http.POST(fb->buf, fb->len);
  http.end();
  if (code != 200) {
    Serial.printf("Upload %s failed: HTTP %d\n", name, code);
    return false;
  }
  return true;
}

void setup() {
  Serial.begin(115200);
  pinMode(LED_GPIO_NUM, OUTPUT);
  ledOff();
  if (!initCamera()) {
    Serial.println("FATAL: camera init failed");
    while (true) { ledOn(); delay(100); ledOff(); delay(100); }
  }
  connectWifi();
  tls.setInsecure();  // PRD-accepted prototype risk: no cert validation
  syncTime();
  cleanupOldPhotos();
  Serial.println("Streaming photos to Supabase Storage...");
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi lost, reconnecting...");
    connectWifi();
  }
  unsigned long now = millis();
  if (now - lastCapture < CAPTURE_INTERVAL_MS) {
    delay(20);
    return;
  }
  lastCapture = now;
  camera_fb_t* fb = esp_camera_fb_get();
  if (!fb) {
    Serial.println("Capture failed");
    return;
  }
  ledOn();
  uploadFrame(fb);
  ledOff();
  esp_camera_fb_return(fb);
}
