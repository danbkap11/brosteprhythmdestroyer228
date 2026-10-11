// Short, mid-heavy drop accent. It replaces a bass note; the clean sub remains separate.
SynthDef(\bbAccent, { |out = 0, freq = 73.42, amp = 0.30, dur = 0.3,
    wobbleHz = 4, fmIndex = 2.5, cutoff = 6500, gate = 1,
    attack = 0.003, release = 0.025, growl = 0.7, movement = 0.7,
    aggression = 0.7, tone = 0.55, texture = 0.5, width = 0.15,
    sync = 1, beatHz = 2.333333, cycleBeats = 1, phaseOffset = 0,
    motionLoop = 0.45, motionStart = 0.1, motionPeak = 1,
    motionEnd = 0.2, riseFrac = 0.25|
    var safeDur = dur.clip(0.07, 0.95);
    var rise = riseFrac.clip(0.05, 0.8);
    var ampEnv = EnvGen.ar(
        Env.perc(attack.clip(0.002, 0.02), safeDur, curve: -5),
        doneAction: 2
    );
    var gateEnv = EnvGen.ar(
        Env.asr(0.001, 1, release.clip(0.005, 0.06), -4),
        gate.clip(0, 1), doneAction: 2
    );
    var freqCtl = Lag.kr(freq.clip(40, 300), 0.01);
    var growlCtl = Lag.kr(growl.clip(0, 1), 0.015);
    var moveCtl = Lag.kr(movement.clip(0, 1), 0.015);
    var driveCtl = Lag.kr(aggression.clip(0, 1), 0.015);
    var toneCtl = Lag.kr(tone.clip(0, 1), 0.02);
    var textureCtl = Lag.kr(texture.clip(0, 1), 0.02);
    var widthCtl = Lag.kr(width.clip(0, 1), 0.025);
    var phase = Phasor.kr(
        Impulse.kr(0),
        Lag.kr(beatHz.clip(2, 2.666667), 0.005) * ControlDur.ir /
            cycleBeats.clip(0.25, 4),
        0, 1, phaseOffset.clip(0, 0.99999)
    );
    var pulse = 1 - ((phase * 2) - 1).abs;
    var cyclic = Select.kr(sync.clip(0, 1), [
        LFTri.kr(wobbleHz.clip(0.25, 12)).range(0, 1), pulse
    ]);
    var contour = EnvGen.kr(Env(
        [motionStart.clip(0, 1), motionPeak.clip(0, 1), motionEnd.clip(0, 1)],
        [safeDur * rise, safeDur * (1 - rise)], \lin
    ));
    var motion = Lag.kr(
        ((contour * (1 - motionLoop.clip(0, 1))) +
            (cyclic * motionLoop.clip(0, 1))) * moveCtl,
        0.008
    ).clip(0, 1);
    // The fast downward pitch scoop and bright noise tick mark the attack.
    var pitch = EnvGen.kr(Env([1.55, 1], [0.055], -5));
    var tickEnv = EnvGen.kr(Env.perc(0.001, 0.035));
    var modulator = SinOsc.ar(freqCtl * pitch * 2.02, 0,
        freqCtl * fmIndex.clip(0, 3) * growlCtl * (0.55 + motion));
    var carrier = SinOsc.ar((freqCtl * pitch * 1.5) + modulator);
    var sawLeft = Saw.ar(freqCtl * 1.99);
    var sawRight = Saw.ar(freqCtl * 2.01);
    var raw = LPF.ar(carrier * 0.85 +
        ((sawLeft + sawRight) * 0.28 * textureCtl), 7000);
    var shaped = (raw * (2.5 + (5.5 * driveCtl))).tanh;
    var toneRatio = 2 ** ((toneCtl - 0.5) * 1.4);
    var vowelOne = (520 + (motion * 1050)) * toneRatio;
    var vowelTwo = (2400 - (motion * 850)) * toneRatio;
    var vowels = BPF.ar(shaped, vowelOne.clip(350, 2600), 0.35) * 1.3 +
        BPF.ar(shaped, vowelTwo.clip(950, 3900), 0.4);
    var tick = HPF.ar(WhiteNoise.ar, 2400) * tickEnv * 0.16;
    var center = ((shaped * 0.72) + (vowels * 2.2) + tick).tanh * 1.15;
    var side = HPF.ar(sawLeft - sawRight, 250) *
        textureCtl * widthCtl * 0.08;
    var stereo = [center + side, center - side];
    // Protect the mono sub band after all nonlinear processing.
    var upper = HPF.ar(HPF.ar(LeakDC.ar(stereo), 150), 150);
    var output = LPF.ar(upper, cutoff.clip(1500, 8000));
    Out.ar(out, output * ampEnv * gateEnv *
        Lag.kr(amp.clip(0, 0.32), 0.01));
})
