# TampalPintar - Demo Handoff Guide

## 📱 Quick Demo Setup (5 Minutes)

### Prerequisites
- ✅ Android phone with USB cable
- ✅ Flutter SDK installed
- ✅ USB debugging enabled on phone

### Step 1: Connect Device
```bash
# Check device is connected
adb devices

# Should show:
# List of devices attached
# XXXXXXXXX    device
```

### Step 2: Build & Run
```bash
cd vosk_sandbox
flutter run
```

⏱️ **Wait Time:** ~2 minutes for build + 5 seconds for model loading

### Step 3: Grant Permissions
When the app launches, it will ask for:
1. ✅ **Microphone** - Tap "Allow"
2. ✅ **Notifications** - Tap "Allow"

### Step 4: Demo Flow

#### 🎬 **Scene 1: Basic Wake-Word Detection** (30 seconds)
1. Wait for "Loading Vosk model..." to disappear (~5 seconds)
2. Tap **"START DRIVE"** button (large green button)
3. ✅ Counter badge turns green
4. ✅ "What Vosk Hears:" box appears
5. **Say clearly:** "hello world"
   - ✅ Text appears in gray box immediately
6. **Say:** "hey potholes"
   - ✅ Counter increments from 0 → 1
   - ✅ Notification text updates

#### 🎬 **Scene 2: Background Operation** (1 minute)
1. **Keep app running** (green badge visible)
2. Press **Home button** (minimize TampalPintar)
3. ✅ Notification stays in notification bar: "TampalPintar - Potholes detected: 1"
4. Open **Google Maps** or **Waze**
5. **Say:** "hey potholes" while using navigation app
6. **Pull down** notification bar
   - ✅ Notification updates: "Potholes detected: 2"
7. **Tap notification** to return to app
   - ✅ Counter shows 2
   - ✅ Transcript still updating

#### 🎬 **Scene 3: Real-Time Transcript** (30 seconds)
1. With app visible and listening (green badge)
2. **Say slowly:** "testing one two three"
   - ✅ Watch words appear in real-time in "What Vosk Hears:" box
3. **Say rapidly:** "hey potholes hey potholes"
   - ✅ Counter jumps from 2 → 4
   - ✅ Transcript keeps updating

## 🎤 Wake Word Variations

The system detects these phonetic variations:
- `hey potholes` ← Primary
- `hey but holes` ← Common mishearing
- `a potholes`
- `hey paul holes`
- `hey pot hose`
- `hey part holes`
- `hey bought holes`

**Demo Tip:** Say "hey PAHT-holes" with clear enunciation for best results.

## 📊 What to Show Stakeholders

### Key Features:
1. ✅ **Offline AI** - No internet required
2. ✅ **Real-time transcript** - See what the AI hears
3. ✅ **Background operation** - Works while using navigation
4. ✅ **Persistent notification** - Always visible when active
5. ✅ **Accurate detection** - Handles phonetic variations

### Value Proposition:
> "Drivers can report potholes hands-free while navigating with Waze, using only their voice. The app runs completely offline using on-device AI, ensuring privacy and reliability even in areas with poor connectivity."

## 🐛 Troubleshooting During Demo

### Issue: Model loading takes forever
**Symptom:** "Loading Vosk model..." doesn't disappear  
**Quick Fix:** 
```bash
flutter clean
flutter run
```

### Issue: No transcript appears when speaking
**Symptom:** "(listening...)" shows but no text  
**Quick Fix:** 
1. Stop app
2. Check microphone works (open Voice Recorder app, test)
3. Re-run: `flutter run`

### Issue: "Permissions required" orange box shows
**Symptom:** Can't tap START DRIVE  
**Quick Fix:**
1. Tap orange box
2. Tap "Open Settings"
3. Enable Microphone + Notifications
4. Return to app

### Issue: Counter doesn't increment
**Symptom:** Transcript appears but saying "hey potholes" does nothing  
**Debug:**
1. Check transcript box shows "hey potholes" (not "high pot holes")
2. Try saying slower: "hey... potholes"
3. Try louder

## 🎥 Recording the Demo

### Recommended Tools:
- **Android Screen Recording:** Settings → Developer Options → Screen Record
- **ADB Screen Record:** 
  ```bash
  adb shell screenrecord /sdcard/demo.mp4
  # Record demo (max 3 minutes)
  # Press Ctrl+C when done
  adb pull /sdcard/demo.mp4 .
  ```

### Demo Script (2 minutes):

**[0:00-0:15] Introduction**
> "TampalPintar helps drivers report potholes hands-free. Let me show you how it works."

**[0:15-0:30] Initialization**
- Open app
- Show model loading
- Tap START DRIVE

**[0:30-0:50] Basic Detection**
- Say "hello world" → show transcript
- Say "hey potholes" → show counter increment
- Point out: "Notice the real-time transcript"

**[0:50-1:30] Background Demo**
- Press Home
- Open Waze
- Say "hey potholes" twice
- Pull down notification
- Point out: "Works while navigating"

**[1:30-2:00] Close**
> "Completely offline, privacy-first, and works seamlessly with any navigation app."

## 📱 Demo Best Practices

### Environment:
- ✅ Quiet room (reduces false positives)
- ✅ Phone at arm's length
- ✅ Speak clearly and moderately loud
- ❌ Don't demo in noisy area (cafeteria, street)

### Phone Settings:
- ✅ Brightness at 100% (for visibility)
- ✅ Do Not Disturb OFF (so notifications show)
- ✅ Battery Saver OFF (prevents CPU throttling)
- ✅ WiFi/Data ON (even though app is offline, avoids "no connection" confusion)

### Backup Plan:
If live demo fails:
1. Have pre-recorded screen recording ready
2. Or show `FIXED_AND_WORKING.md` documentation
3. Or demonstrate with pre-built APK on different device

## 🚀 Advanced Demo (Optional)

### Show Technical Details:
```bash
# While app is running, show logs:
adb logcat | grep "Main\|Vosk"

# Shows:
# [Main] App backgrounded, Vosk continues in foreground service
# [Main] 🎤 Heard: hey potholes
```

### Show Architecture:
Open `ROOT_CAUSE_FOUND.md` and explain:
> "We run Vosk in the main isolate, not a background isolate, because MethodChannels don't work in background isolates. The foreground service keeps the notification visible and prevents Android from killing the app."

### Show Code:
Open `lib/main.dart` and point out:
- Line 184: `_speechService!.onPartial().listen(...)` - Real-time audio stream
- Line 214: `_checkForWakeWord(text)` - Wake word matching logic
- Line 68: `didChangeAppLifecycleState` - Handles app backgrounding

## 📋 Demo Checklist

Before demo:
- [ ] Device fully charged (>80%)
- [ ] TampalPintar installed and tested
- [ ] Permissions granted
- [ ] Model loaded successfully (test once)
- [ ] Waze or Google Maps installed
- [ ] Screen recording enabled (if recording)
- [ ] Quiet demo location confirmed

During demo:
- [ ] Show app launch → model loading
- [ ] Demonstrate real-time transcript
- [ ] Show wake word detection (counter increment)
- [ ] Minimize app and show background operation
- [ ] Return to app and show persistent counter
- [ ] Tap STOP DRIVE to clean shutdown

After demo:
- [ ] Stop app (tap STOP DRIVE)
- [ ] Show notification disappears
- [ ] Reset counter (restart app) for next demo

## 📞 Support Contacts

If demo fails or technical questions arise:
- **Developer:** [Your contact]
- **Backup Device:** Have second phone with app pre-loaded
- **Documentation:** Share `FIXED_AND_WORKING.md` via email/Slack

---

## 🎯 Expected Demo Outcome

**Audience takeaway:**
> "This app solves the hands-free pothole reporting problem by running an offline AI voice recognition system that works seamlessly while drivers use their preferred navigation app. It's practical, privacy-first, and ready for pilot testing."

**Technical validation:**
> "The team solved a critical technical challenge (running Vosk in foreground vs background isolate) and demonstrated deep understanding of Android lifecycle management and Flutter architecture."

---

**Version:** 1.0  
**Last Updated:** 2026-07-07  
**Build Tested:** Flutter 3.44.4 | Android SDK 36.1.0  
**Demo Duration:** 2-5 minutes  
**Preparation Time:** 5 minutes
