#!/usr/bin/env python3
"""Lossless private PCM transport; originals and source identity stay unchanged.

PCM16 stereo -> per-channel first differences -> byte lanes -> zlib. The Godot
adapter restores every original sample before existing PCM hash validation.
Authoring uses already-installed NumPy; the game needs no external dependency.
"""
import hashlib
from pathlib import Path
import struct
import wave
import zlib
import numpy as np


def encode(source: Path) -> tuple[bytes, dict]:
    with wave.open(str(source)) as wav:
        assert (wav.getnchannels(), wav.getsampwidth(), wav.getframerate()) == (2, 2, 48000)
        frames = wav.getnframes()
        assert 0 < frames <= 48000 * 30
        raw = wav.readframes(frames)
    assert len(raw) == frames * 4
    samples = np.frombuffer(raw, dtype='<u2').reshape(-1, 2)
    delta = np.empty_like(samples)
    delta[0] = samples[0]
    np.subtract(samples[1:], samples[:-1], out=delta[1:])
    lanes = delta.tobytes()
    compressed = zlib.compress(lanes[::2] + lanes[1::2], 6)
    header = struct.pack('<4sIIHH32s32s32s', b'BMP1', frames, 48000, 2, 1,
                         hashlib.sha256(raw).digest(), hashlib.sha256(compressed).digest(),
                         hashlib.sha256(source.read_bytes()).digest())
    # Independent vector reconstruction and exact PCM comparison before release.
    unpacked = zlib.decompress(compressed)
    values = np.frombuffer(unpacked[:frames*2], dtype='u1').astype('u2')
    values |= np.frombuffer(unpacked[frames*2:], dtype='u1').astype('u2') << 8
    restored = np.cumsum(values.reshape(-1, 2), axis=0, dtype='u8').astype('<u2').tobytes()
    assert restored == raw
    return header + compressed, dict(frames=frames, sample_rate=48000, channels=2,
        pcm_sha256=hashlib.sha256(raw).hexdigest(), source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
        source_bytes=source.stat().st_size, packed_bytes=len(header)+len(compressed))
