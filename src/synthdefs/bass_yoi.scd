// Bright vowel stab for the drop replies. The sub stays on its own clean bus.
SynthDef(\bbYoi, { |out = 0, freq = 73.42, amp = 0.20, dur = 0.3,
    wobbleHz = 4, fmIndex = 2.5, cutoff = 6500, gate = 1,
    attack = 0.004, release = 0.025, growl = 0.7, movement = 0.7,
    aggression = 0.6, tone = 0.55, texture = 0.5, width = 0.15,
    sync = 1, beatHz = 2.333333, cycleBeats = 1, phaseOffset = 0,
    motionLoop = 0.45, motionStart = 0.1, motionPeak = 1,
    motionEnd = 0.2, riseFrac = 0.25|
    var safeDur = dur.clip(0.07, 0.95);
    var rise = riseFrac.clip(0.05, 0.8);
    var tail = (safeDur * 0.16).clip(0.018, 0.11);
    var ampEnv = EnvGen.ar(
        Env([0, 1, 0.88, 0],
            [attack.clip(0.003, 0.02),
                (safeDur - attack.clip(0.003, 0.02) - tail).max(0.005), tail],
            [-4, 0, -4]),
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
    var synced = 1 - ((phase * 2) - 1).abs;
    var freeMotion = LFTri.kr(wobbleHz.clip(0.25, 12)).range(0, 1);
    var cyclic = Select.kr(sync.clip(0, 1), [freeMotion, synced]);
    var contour = EnvGen.kr(Env(
        [motionStart.clip(0, 1), motionPeak.clip(0, 1), motionEnd.clip(0, 1)],
        [safeDur * rise, safeDur * (1 - rise)], \lin
    ));
    var motion = Lag.kr(
        ((contour * (1 - motionLoop.clip(0, 1))) +
            (cyclic * motionLoop.clip(0, 1))) * moveCtl,
        0.008
    ).clip(0, 1);
    var modulator = SinOsc.ar(freqCtl * 2.01, 0,
        freqCtl * fmIndex.clip(0, 3) * growlCtl * (0.35 + motion));
    var carrier = SinOsc.ar((freqCtl * 1.5) + modulator);
    var sawLeft = Saw.ar(freqCtl * 1.99);
    var sawRight = Saw.ar(freqCtl * 2.01);
    var source = LPF.ar(carrier * 0.8 +
        ((sawLeft + sawRight) * 0.25 * textureCtl), 7000);
    var distorted = (source * (1.8 + (6 * driveCtl))).tanh;
    var toneRatio = 2 ** ((toneCtl - 0.5) * 1.4);
    var lowVowel = (430 + (motion * 1000)) * toneRatio;
    var highVowel = (2600 - (motion * 1050)) * toneRatio;
    var vowels = BPF.ar(distorted, lowVowel.clip(300, 2400), 0.32) * 1.2 +
        BPF.ar(distorted, highVowel.clip(900, 4000), 0.38);
    var center = ((distorted * 0.40) + (vowels * 2.0)).tanh;
    var side = HPF.ar(sawLeft - sawRight, 230) *
        textureCtl * widthCtl * 0.10;
    var stereo = [center + side, center - side];
    var upper = HPF.ar(HPF.ar(LeakDC.ar(stereo), 150), 150);
    var output = LPF.ar(upper, cutoff.clip(1500, 8000));
    var compressed = Compander.ar(output, output, 0.13,
        1, 0.55, 0.004, 0.09);
    var protected = HPF.ar(HPF.ar(
        LeakDC.ar((compressed * 1.3).tanh), 150), 150);
    var wobbleGain = 1 - (0.35 * moveCtl *
        motionLoop.clip(0, 1) * (1 - motion));
    Out.ar(out, protected * wobbleGain * ampEnv * gateEnv *
        Lag.kr(amp.clip(0, 0.30), 0.01));
})
