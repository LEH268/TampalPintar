# Vosk Sandbox - Wake Word Detection App

## Project Summary
A Flutter-based offline wake-word detection sandbox app using Vosk speech recognition. The app listens for the custom phrase "Tampal Pintar" (and its phonetic variations) to log pothole detections.

## Implementation Details

### Dependencies
- **vosk_flutter**: Offline speech recognition (via GitHub)
- **permission_handler**: Runtime microphone permission handling

### Android Configuration
- **minSdkVersion**: 21
- **ProGuard rules**: Configured to preserve JNA/Vosk native libraries
- **Permissions**: RECORD_AUDIO added to AndroidManifest.xml

### AI Model
- **Model**: vosk-model-small-en-us-0.15 (40MB, English)
- **Source**: https://alphacephei.com/vosk/models/
- **Sample Rate**: 16000 Hz
- **Location**: Bundled as asset in `assets/models/`

### Wake Word Detection
The app monitors partial speech transcripts and matches against:
1. `tampal pintar` (target phrase)
2. `temper painter` (common mishearing)
3. `tampa pinter` (phonetic variation)
4. `log hazard` (alternate mishearing)

### Core Features
- Real-time microphone audio streaming
- Partial transcript display ("What Vosk Hears")
- Pothole counter with visual feedback
- Auto-reset after wake-word detection to prevent overlap
- Clean lifecycle management with proper disposal

### UI Components
- Permission request flow with settings redirect
- Model loading indicator
- Live transcript display
- Pothole count badge (turns green on detection)
- Start/Stop floating action button

## Build Status
✅ All static analysis checks passed
✅ Assets properly bundled
✅ Android platform configured
✅ Dependencies resolved

## Next Steps
To run the app:
```bash
flutter run
```

To build release APK:
```bash
flutter build apk --release
```
