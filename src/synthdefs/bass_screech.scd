// Sparse high-mid FM response. Feedback is a bounded oscillator phase control.
SynthDef(\bbScreech, { |out = 0, freq = 73.42, amp = 0.24, dur = 0.3,
    gate = 1, attack = 0.003, release = 0.025, wobbleHz = 4,
    fmIndex = 2.4, cutoff = 6500, growl = 0.78, movement = 0.72,
    aggression = 0.70, tone = 0.58, texture = 0.40, width = 0.12,
    sync = 1, beatHz = 2.333333, cycleBeats = 0.5, phaseOffset = 0,
    motionLoop = 0.5, motionStart = 0.8, motionPeak = 1,
    motionEnd = 0.1, riseFrac = 0.1, duckBus = -1|
    var safeDur = dur.clip(0.06, 1.15);
    var tail = (safeDur * 0.16).clip(0.015, 0.10);
    var env = EnvGen.ar(Env([0, 1, 0.86, 0],
        [attack.clip(0.002, 0.02),
            (safeDur - attack.clip(0.002, 0.02) - tail).max(0.005), tail],
        [-4, 0, -4]), doneAction: 2);
    var gateEnv = EnvGen.ar(Env.asr(0.001, 1, release.clip(0.005, 0.06), -4),
        gate.clip(0, 1), doneAction: 2);
    var hz = Lag.kr(freq.clip(40, 450), 0.008);
    var growlCtl = Lag.kr(growl.clip(0, 1), 0.012);
    var moveCtl = Lag.kr(movement.clip(0, 1), 0.012);
    var driveCtl = Lag.kr(aggression.clip(0, 1), 0.015);
    var textureCtl = Lag.kr(texture.clip(0, 1), 0.02);
    var toneCtl = Lag.kr(tone.clip(0, 1), 0.02);
    var widthCtl = Lag.kr(width.clip(0, 1), 0.02);
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
    var motion = Lag.kr(((contour * (1 - motionLoop.clip(0, 1)))
        + (cyclic * motionLoop.clip(0, 1))) * moveCtl, 0.006).clip(0, 1);
    var pitch = EnvGen.kr(Env([1 + (growlCtl * 0.32), 1], [0.045], -5));
    var mod = SinOsc.ar(hz * pitch * 3, 0,
        hz * fmIndex.clip(0, 3) * growlCtl * (0.6 + motion));
    var fm = SinOsc.ar((hz * pitch * 1.5) + mod);
    var feedback = SinOscFB.ar(hz * 2, 0.1 + (textureCtl * 0.4));
    var raw = LPF.ar((fm * 0.70) + (feedback * 0.18)
        + (Saw.ar(hz * 2.005) * textureCtl * 0.18), 6500);
    var shaped = (raw * (2 + (driveCtl * 6))).tanh;
    var nasal = BPF.ar(shaped,
        ((900 + (motion * 2400)) * (0.75 + toneCtl)).clip(650, 4800), 0.28);
    var center = ((shaped * 0.55) + (nasal * 1.65)).tanh;
    var side = HPF.ar(Saw.ar(hz * 2.01) - Saw.ar(hz * 1.99), 600)
        * widthCtl * textureCtl * 0.09;
    var output = LPF.ar(HPF.ar(HPF.ar(LeakDC.ar(
        [center + side, center - side]), 180), 180), cutoff.clip(1600, 8000));
    var duck = Select.kr(duckBus >= 0, [1, In.kr(duckBus.max(0), 1)]);
    Out.ar(out, output * env * gateEnv * amp.clip(0, 0.30)
        * duck.linlin(0, 1, 0.35, 1));
})
