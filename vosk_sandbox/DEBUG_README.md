# Microphone Debugging - Quick Start

## ✅ What I Added

### Enhanced Logging in Background Service
The app now logs detailed information about every initialization step:
- Step 1: Loading model from assets
- Step 2: Creating Vosk model  
- Step 3: Creating recognizer
- Step 4: Initializing speech service
- Step 5: Setting up partial listener
- Step 6: Starting speech service

Each successful step shows a ✓ checkmark.
Any failure shows ❌ with full error details.

### Error Display in UI
The app now shows:
- **Red error box** if service fails to start (shows the actual error message)
- **Blue status box** showing current service status ("listening")
- Both appear at the top of the screen

### Transcript Monitoring
When the mic is working, you'll see:
- `[VoiceTaskHandler] 🎤 Heard: [text]` in logs
- Text appears in "What Vosk Hears:" box in real-time

## 🔍 How to Debug

### Method 1: Using Android Studio
1. Open Android Studio
2. Connect your device
3. Bottom panel → Logcat tab
4. Filter: `VoiceTaskHandler`
5. Run the app and tap START DRIVE
6. Watch the logs appear step by step

### Method 2: Using Command Line
```bash
# Windows (Git Bash)
cd vosk_sandbox
bash debug_microphone.sh

# Or manually:
adb logcat | grep VoiceTaskHandler
```

### Method 3: Check UI Error Display
Just look at the app screen - if there's a problem, a red box will appear with the error message.

## 🎯 What to Look For

### ✅ Working Correctly:
```
[VoiceTaskHandler] ========== SERVICE STARTING ==========
[VoiceTaskHandler] Step 1: Loading model from assets...
[VoiceTaskHandler] ✓ Model loaded to: /data/user/...
[VoiceTaskHandler] ✓ Model created successfully
[VoiceTaskHandler] ✓ Recognizer created successfully
[VoiceTaskHandler] ✓ Speech service initialized
[VoiceTaskHandler] ✓ Partial listener configured
[VoiceTaskHandler] ✓✓✓ SPEECH SERVICE STARTED - LISTENING NOW! ✓✓✓
[VoiceTaskHandler] 🎤 Heard: hello
```

**UI shows:** Blue "Status: listening" box + real-time transcript updates

### ❌ Most Common Issues:

**1. Model Not Loading**
```
[VoiceTaskHandler] ❌❌❌ FAILED TO INITIALIZE ❌❌❌
[VoiceTaskHandler] Error: Unable to load asset
```
**Fix:** Run `flutter clean && flutter pub get && flutter run`

**2. Microphone Permission Denied**
```
[VoiceTaskHandler] Error: Permission denied: RECORD_AUDIO
```
**Fix:** Settings → Apps → TampalPintar → Permissions → Allow Microphone

**3. Service Starts But No Audio Detected**
```
[VoiceTaskHandler] ✓✓✓ SPEECH SERVICE STARTED - LISTENING NOW! ✓✓✓
(no "🎤 Heard:" messages when speaking)
```
**Fix:** 
- Check if another app is using the microphone
- Test with Voice Recorder app to verify mic works
- Try speaking louder and more clearly

## 🚀 Quick Test

1. **Rebuild the app:**
   ```bash
   flutter run
   ```

2. **Grant all permissions when prompted**

3. **Tap START DRIVE**

4. **Look for the blue status box** - should say "Status: listening"

5. **Speak "hello world" clearly**

6. **Check if text appears** in the "What Vosk Hears:" box

7. **If still not working,** run logcat and share the output:
   ```bash
   adb logcat | grep VoiceTaskHandler > debug.txt
   ```

## 📝 Files Created

- `TROUBLESHOOTING.md` - Comprehensive troubleshooting guide
- `debug_microphone.sh` - Automated debug helper script
- Enhanced `voice_task_handler.dart` - Detailed logging
- Enhanced `main.dart` - Error display UI

The app is now fully instrumented to help identify exactly where the problem is!
