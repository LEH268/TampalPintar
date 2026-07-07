#!/bin/bash
# TampalPintar Debug Helper Script

echo "=========================================="
echo "TampalPintar Microphone Debug Helper"
echo "=========================================="
echo ""

# Check if adb is available
if ! command -v adb &> /dev/null; then
    echo "❌ ERROR: adb not found in PATH"
    echo "Please install Android SDK Platform Tools"
    exit 1
fi

echo "✓ ADB found"
echo ""

# Check if device is connected
DEVICE_COUNT=$(adb devices | grep -v "List" | grep "device$" | wc -l)
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "❌ ERROR: No Android device connected"
    echo "Please connect your device via USB and enable USB debugging"
    exit 1
fi

echo "✓ Android device connected"
echo ""

# Clear old logs
echo "Clearing old logs..."
adb logcat -c
echo "✓ Logs cleared"
echo ""

echo "=========================================="
echo "INSTRUCTIONS:"
echo "1. Tap START DRIVE in the app"
echo "2. Wait 5 seconds"
echo "3. Speak clearly into the microphone"
echo "4. Watch for '🎤 Heard:' messages below"
echo "=========================================="
echo ""
echo "Waiting for VoiceTaskHandler logs..."
echo "(Press Ctrl+C to stop)"
echo ""

# Monitor logs in real-time
adb logcat | grep --line-buffered -E "(VoiceTaskHandler|ERROR)"
