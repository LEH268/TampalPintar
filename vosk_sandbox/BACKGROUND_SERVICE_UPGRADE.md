# Vosk Sandbox - Background Service Upgrade

## Architectural Changes

The app has been upgraded from foreground-only wake-word detection to a full Android Foreground Service implementation, allowing continuous voice monitoring while using other apps like Waze.

## New Dependencies

### Added Packages
- **flutter_foreground_task** (v8.17.0): Handles background isolate and persistent notification
- **audioplayers** (v6.1.0): Plays audible "beep" confirmation when pothole is detected

## Android Configuration

### Permissions Added (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### Foreground Service Declaration
```xml
<service
    android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
    android:foregroundServiceType="microphone"
    android:exported="false" />
```

## Architecture

### Background Isolate (`voice_task_handler.dart`)
- **VoiceTaskHandler**: TaskHandler class that runs in isolated background thread
- **Model Loading**: Vosk model loads once in background isolate on service start
- **Speech Recognition**: Continuous `SpeechService` streaming in background
- **Wake Word Detection**: Monitors for phonetic variants:
  - `hey potholes` (primary)
  - `hey but holes`
  - `a potholes`
  - `hey paul holes`
  - `hey pot hose`
  - `hey part holes`
  - `hey bought holes`

### Main UI (`main.dart`)
- **DrivingModeScreen**: Controller interface for background service
- **Permissions**: Requests Microphone + Notification permissions on startup
- **Service Control**:
  - "START DRIVE" button → launches foreground service
  - "STOP DRIVE" button → terminates service
- **Counter Updates**: Receives messages from background isolate via data callback
- **Visual Feedback**: Counter badge turns green when service is active

## Data Flow

1. User taps "START DRIVE"
2. Main isolate starts `FlutterForegroundTask.startService()` with `startVoiceCallback`
3. Background isolate spawns and loads Vosk model
4. Background isolate starts continuous speech recognition
5. When wake word detected:
   - Background isolate sends `{'action': 'pothole_detected'}` to main
   - Main UI increments counter
   - Audio beep plays (if implemented)
   - Speech service resets buffer
6. Service continues until user taps "STOP DRIVE"

## Key Features

### Background Persistence
- Service runs with persistent notification
- Survives app backgrounding
- Continues listening while using Waze, Google Maps, etc.

### Clean Lifecycle
- Proper `dispose()` of SpeechService on service stop
- Null-safe model/recognizer cleanup
- AudioPlayer disposal in main UI

### Error Handling
- Permission denial → opens Settings
- Model load failure → logged to console
- Service start failure → UI reflects inactive state

## Build Status
✅ Static analysis passed (warnings only, no errors)
✅ Android manifest configured
✅ Foreground service registered
✅ Background isolate implemented

## Testing Instructions

1. Build and install:
   ```bash
   flutter run
   ```

2. Grant permissions:
   - Microphone access
   - Notification access

3. Tap "START DRIVE" - notification should appear

4. Open Waze or another navigation app

5. Say "Hey Potholes" clearly

6. Check counter increments and notification remains visible

7. Tap "STOP DRIVE" to end session

## Known Limitations

- Audio beep fallback not implemented (requires asset or TTS)
- Print statements for debugging (should use logging framework in production)
- No reconnection logic if speech service crashes
- No battery optimization warnings shown to user

## Next Steps

1. Add beep sound asset at `assets/beep.mp3`
2. Implement proper logging instead of print statements
3. Add crash recovery in TaskHandler
4. Test battery usage over extended periods
5. Add UI to show last detection time
6. Implement trip summary/history
