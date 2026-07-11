"""Parity check: full-buffer reference chain vs the app's streaming math.

Usage:  python check.py [optional.wav]   (wav: 16 kHz mono 16-bit)
Deps:   pip install onnxruntime numpy
"""
import sys, wave, struct
import numpy as np
import onnxruntime as ort

MODELS = "../../app/assets/models"
CHUNK, CTX, NEW_FRAMES, BINS, WIN, STRIDE, DIM, STEPS = 1280, 480, 8, 32, 76, 8, 96, 16


def load_audio(path=None, seconds=2.0, sr=16000):
    if path:
        with wave.open(path, "rb") as w:
            assert w.getframerate() == sr and w.getnchannels() == 1
            n = w.getnframes()
            pcm = np.frombuffer(w.readframes(n), dtype=np.int16)
    else:  # deterministic synthetic audio: tone + noise
        rng = np.random.default_rng(42)
        t = np.arange(int(seconds * sr)) / sr
        sig = 0.3 * np.sin(2 * np.pi * 440 * t) + 0.1 * rng.standard_normal(len(t))
        pcm = (np.clip(sig, -1, 1) * 32767).astype(np.int16)
    n = (len(pcm) // CHUNK) * CHUNK
    return pcm[:n].astype(np.float32) / 32768.0


def sessions():
    mel = ort.InferenceSession(f"{MODELS}/melspectrogram.onnx")
    emb = ort.InferenceSession(f"{MODELS}/embedding_model.onnx")
    clf = ort.InferenceSession(f"{MODELS}/tampal_pintar.onnx")
    return mel, emb, clf


def run(sess, arr):
    name = sess.get_inputs()[0].name
    return sess.run(None, {name: arr.astype(np.float32)})[0]


def stack16(embs):
    out = np.zeros((STEPS, DIM), dtype=np.float32)
    take = embs[-STEPS:]
    out[STEPS - len(take):] = np.stack(take)
    return out


def reference_score(pcm, mel, emb, clf):
    m = np.squeeze(run(mel, pcm[None, :])) / 10.0 + 2.0  # (F,32)
    windows = [(m[i * STRIDE: i * STRIDE + WIN]) for i in range((len(m) - WIN) // STRIDE + 1)]
    embs = [np.squeeze(run(emb, w[None, :, :, None])) for w in windows]
    return float(np.squeeze(run(clf, stack16(embs)[None])))


def streaming_score(pcm, mel, emb, clf):
    ctx = np.zeros(CTX, dtype=np.float32)
    frames, embs, score = [], [], None
    for i in range(0, len(pcm), CHUNK):
        chunk = pcm[i: i + CHUNK]
        m = np.squeeze(run(mel, np.concatenate([ctx, chunk])[None, :])) / 10.0 + 2.0
        ctx = chunk[-CTX:]
        frames.extend(list(m[-NEW_FRAMES:]))
        if len(frames) < WIN:
            continue
        frames = frames[-WIN:]
        embs.append(np.squeeze(run(emb, np.stack(frames)[None, :, :, None])))
        embs = embs[-STEPS:]
        score = float(np.squeeze(run(clf, stack16(embs)[None])))
    return score


def main():
    pcm = load_audio(sys.argv[1] if len(sys.argv) > 1 else None)
    mel, emb, clf = sessions()
    ref = reference_score(pcm, mel, emb, clf)
    stream = streaming_score(pcm, mel, emb, clf)
    diff = abs(ref - stream)
    print(f"reference={ref:.4f} streaming={stream:.4f} diff={diff:.4f}")
    if diff >= 0.05:
        print("FAIL: streaming math diverges from the reference chain")
        sys.exit(1)
    print("PASS")


if __name__ == "__main__":
    main()
