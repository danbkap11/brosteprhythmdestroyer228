// Pitched, finite sample chops. A sampled mid voice replaces a synth voice.
SynthDef(\bbBassSample, { |out = 0, bufnum = 0, rootFreq = 82.41,
    freq = 73.42, amp = 0.25, dur = 0.3, gate = 1, duckBus = -1,
    attack = 0.003, release = 0.025, wobbleHz = 4, fmIndex = 2.4,
    cutoff = 6500, growl = 0.78, movement = 0.72, aggression = 0.70,
    tone = 0.58, texture = 0.40, width = 0.12, sync = 1,
    beatHz = 2.333333, cycleBeats = 1, phaseOffset = 0,
    motionLoop = 0.25, motionStart = 0.2, motionPeak = 1,
    motionEnd = 0.15, riseFrac = 0.15|
    var safeDur = dur.clip(0.06, 1.5);
    var tail = (safeDur * 0.15).clip(0.012, 0.09);
    var env = EnvGen.ar(Env([0, 1, 0.94, 0],
        [attack.clip(0.002, 0.02),
            (safeDur - attack.clip(0.002, 0.02) - tail).max(0.005), tail],
        [-4, 0, -4]), doneAction: 2);
    var gateEnv = EnvGen.ar(Env.asr(0.001, 1, release.clip(0.005, 0.06), -4),
        gate.clip(0, 1), doneAction: 2);
    var moveCtl = Lag.kr(movement.clip(0, 1), 0.01);
    var growlCtl = Lag.kr(growl.clip(0, 1), 0.015);
    var driveCtl = Lag.kr(aggression.clip(0, 1), 0.015);
    var toneCtl = Lag.kr(tone.clip(0, 1), 0.015);
    var textureCtl = Lag.kr(texture.clip(0, 1), 0.02);
    var widthCtl = Lag.kr(width.clip(0, 1), 0.02);
    var ratio = (freq.clip(30, 500) / rootFreq.clip(30, 500)).clip(0.67, 1.5);
    var raw = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum) * ratio);
    var phase = Phasor.kr(Impulse.kr(0),
        beatHz.clip(2, 2.666667) * ControlDur.ir / cycleBeats.clip(0.25, 4),
        0, 1, phaseOffset.clip(0, 0.99999));
    var cyclic = Select.kr(sync.clip(0, 1), [
        LFTri.kr(wobbleHz.clip(0.25, 12)).range(0, 1),
        1 - ((phase * 2) - 1).abs
    ]);
    var contour = EnvGen.kr(Env(
        [motionStart.clip(0, 1), motionPeak.clip(0, 1), motionEnd.clip(0, 1)],
        [safeDur * riseFrac.clip(0.05, 0.8), safeDur * (1 - riseFrac.clip(0.05, 0.8))]));
    var motion = Lag.kr((contour * (1 - motionLoop.clip(0, 1)))
        + (cyclic * motionLoop.clip(0, 1)), 0.005).clip(0, 1);
    var clean = LPF.ar(raw, 7500);
    var driven = (clean * (1.5 + (driveCtl * 3))).tanh;
    var ring = driven * SinOsc.ar(freq.clip(30, 500) * 2) * textureCtl * 0.12;
    var base = (clean * (1 - (driveCtl * 0.35)))
        + (driven * driveCtl * 0.35) + ring;
    var movingCutoff = (cutoff.clip(800, 8000)
        * (2 ** ((toneCtl - 0.5) * 1.6))
        * (2 ** (((motion * 2) - 1) * moveCtl))).clip(650, 8000);
    var filtered = RLPF.ar(base, movingCutoff, 0.65);
    var vowel = BPF.ar(base, 650 + (motion * 1400), 0.4) * growlCtl * 0.5;
    var center = (((filtered * 1.1) + vowel) * 1.55).tanh;
    var high = HPF.ar(center, 900);
    var side = (DelayC.ar(high, 0.01, 0.004) - high) * widthCtl * 0.15;
    var upper = LPF.ar(HPF.ar(HPF.ar(LeakDC.ar(
        [center + side, center - side]), 115), 115), 8000);
    var duck = Select.kr(duckBus >= 0, [1, In.kr(duckBus.max(0), 1)]);
    Out.ar(out, upper * 1.15 * env * gateEnv * amp.clip(0, 0.32)
        * duck.linlin(0, 1, 0.35, 1));
})
