# TampalPintar - Microphone Not Working Troubleshooting Guide

## Problem: "(listening...)" shows but no transcript appears

This enhanced version includes detailed logging to help diagnose the issue.

## Step 1: Check Logcat Output

Run this command in a terminal to see real-time logs:
```bash
adb logcat | grep VoiceTaskHandler
```

### What to Look For:

#### ✅ SUCCESS Pattern:
```
[VoiceTaskHandler] ========== SERVICE STARTING ==========
[VoiceTaskHandler] Step 1: Loading model from assets...
[VoiceTaskHandler] ✓ Model loaded to: /data/user/.../vosk-model-small-en-us-0.15
[VoiceTaskHandler] Step 2: Creating Vosk model...
[VoiceTaskHandler] ✓ Model created successfully
[VoiceTaskHandler] Step 3: Creating recognizer (16000 Hz)...
[VoiceTaskHandler] ✓ Recognizer created successfully
[VoiceTaskHandler] Step 4: Initializing speech service...
[VoiceTaskHandler] ✓ Speech service initialized
[VoiceTaskHandler] Step 5: Setting up partial listener...
[VoiceTaskHandler] ✓ Partial listener configured
[VoiceTaskHandler] Step 6: Starting speech service...
[VoiceTaskHandler] ✓✓✓ SPEECH SERVICE STARTED - LISTENING NOW! ✓✓✓
[VoiceTaskHandler] 🎤 Heard: hello world
```

#### ❌ FAILURE Patterns:

**Model Load Failure:**
```
[VoiceTaskHandler] Step 1: Loading model from assets...
[VoiceTaskHandler] ❌❌❌ FAILED TO INITIALIZE ❌❌❌
[VoiceTaskHandler] Error: Unable to load asset: assets/models/...
```
**Solution:** Model file missing or path incorrect. Check `assets/` folder.

**Permission Issue:**
```
[VoiceTaskHandler] Step 4: Initializing speech service...
[VoiceTaskHandler] ❌❌❌ FAILED TO INITIALIZE ❌❌❌
[VoiceTaskHandler] Error: Permission denied: android.permission.RECORD_AUDIO
```
**Solution:** Grant microphone permission manually in Settings → Apps → TampalPintar → Permissions.

**Service Starts But No Audio:**
```
[VoiceTaskHandler] ✓✓✓ SPEECH SERVICE STARTED - LISTENING NOW! ✓✓✓
(no further "🎤 Heard:" messages appear when speaking)
```
**Solution:** Microphone hardware issue or another app is using it. Close other voice apps.

## Step 2: Check UI Error Display

The app now shows error messages in a red box if the service fails to start. Look for:
- "Service Error" box with details
- "Status: listening" box when working correctly

## Step 3: Check Permissions Again

```bash
adb shell dumpsys package com.example.vosk_sandbox | grep permission
```

Should show:
```
android.permission.RECORD_AUDIO: granted=true
android.permission.FOREGROUND_SERVICE: granted=true
android.permission.FOREGROUND_SERVICE_MICROPHONE: granted=true
```

## Step 4: Verify Model File Exists

```bash
cd vosk_sandbox
ls -lh assets/models/vosk-model-small-en-us-0.15.zip
```

Should show:
```
-rw-r--r-- 1 user user 40M ... vosk-model-small-en-us-0.15.zip
```

## Step 5: Test Microphone Separately

Open Android's Voice Recorder or Google app and verify the microphone works at all.

## Step 6: Common Fixes

### Fix 1: Rebuild with Clean
```bash
flutter clean
flutter pub get
flutter run
```

### Fix 2: Force Stop and Restart
```bash
adb shell am force-stop com.example.vosk_sandbox
flutter run
```

### Fix 3: Check for Conflicting Apps
Close these apps before testing:
- Google Assistant (may hold microphone)
- Other voice recording apps
- Phone calls in background

### Fix 4: Increase Logging Verbosity
The code now includes:
- ✓ Checkmarks for successful steps
- 🎤 Emoji for actual heard text
- ❌ Clear error markers
- Full stack traces on failures

## Expected Flow (Successful)

1. Tap START DRIVE
2. Wait 2-5 seconds for model loading
3. "Status: listening" appears (blue box)
4. Speak clearly: "hello"
5. "What Vosk Hears:" box updates with "hello"
6. Continue speaking, text updates in real-time

## Known Issues

### Issue 1: Background Isolate Not Starting
**Symptom:** Service notification appears but no logs from VoiceTaskHandler
**Cause:** `startVoiceCallback` not registered properly
**Fix:** Check `@pragma('vm:entry-point')` is present on `startVoiceCallback()`

### Issue 2: Model Path Wrong in Background Isolate
**Symptom:** "Unable to load asset" error
**Cause:** Asset path resolution differs in background isolate
**Fix:** Already using `ModelLoader().loadFromAssets()` which handles this

### Issue 3: Speech Service Silently Fails
**Symptom:** Service starts but onPartial never fires
**Cause:** Sample rate mismatch or recognizer not initialized
**Fix:** Verify 16000 Hz is correct for the model (check model docs)

## Get Detailed Logs

Full logcat with timestamps:
```bash
adb logcat -T 1 *:V | grep -E "(VoiceTaskHandler|FlutterForegroundTask)"
```

Save logs to file for analysis:
```bash
adb logcat -T 1 > tampalPintar_debug.log
```

Then search the file for error patterns.

## Still Not Working?

Share the output of:
```bash
adb logcat | grep -E "(VoiceTaskHandler|ERROR|FATAL)"
```

This will show exactly where the initialization is failing.
