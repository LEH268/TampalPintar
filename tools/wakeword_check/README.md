# Wake-word parity check

Validates that the app's streaming pipeline math (Tasks 18/20) produces the
same score as the openWakeWord/livekit-wakeword full-buffer reference chain.

    pip install onnxruntime numpy
    cd tools/wakeword_check
    python check.py            # synthetic audio
    python check.py drive.wav  # 16 kHz mono 16-bit recording of the phrase

PASS means the streaming math agrees with the full-buffer reference chain
*as expressed in Python* -- this script never executes the Dart
implementation, so it cannot catch a bug in the Dart transcription of that
math (e.g. a transposed bin index or a wrong mel window). Those cases are
covered by the Dart-side layout tests in
app/test/feature_math_layout_test.dart and
app/test/wake_word_pipeline_test.dart. If this script FAILs, adjust the
streaming math (mel context / frame take) in BOTH feature_math.dart and this
script until parity holds; the two files must express the same algorithm at
all times.
