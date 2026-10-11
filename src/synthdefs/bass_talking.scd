// Contrasting, formant-like reply voice. It shares bbGrowl's event controls.
SynthDef(\bbTalking, { |out = 0, freq = 73.42, amp = 0.16, dur = 0.28,
    wobbleHz = 3, fmIndex = 2.3, cutoff = 3000, gate = 1,
    attack = 0.006, release = 0.02, growl = 0.65, movement = 0.65,
    aggression = 0.45, tone = 0.5, texture = 0.35, width = 0.15,
    sync = 0, beatHz = 2.333333, cycleBeats = 1, phaseOffset = 0,
    motionLoop = 0.25, motionStart = 0.2, motionPeak = 1,
    motionEnd = 0.15, riseFrac = 0.15|
    var safeDur = dur.clip(0.06, 0.72);
    var rise = riseFrac.clip(0.05, 0.80);
    var ampEnv = EnvGen.ar(
        Env.perc(attack.clip(0.003, 0.02), safeDur, curve: -3),
        doneAction: 2
    );
    var gateEnv = EnvGen.ar(
        Env.asr(0.001, 1, release.clip(0.005, 0.05), -4),
        gate.clip(0, 1), doneAction: 2
    );
    var freqCtl = Lag.kr(freq.clip(35, 400), 0.012);
    var growlCtl = Lag.kr(growl.clip(0, 1), 0.015);
    var movementCtl = Lag.kr(movement.clip(0, 1), 0.015);
    var aggressionCtl = Lag.kr(aggression.clip(0, 1), 0.015);
    var toneCtl = Lag.kr(tone.clip(0, 1), 0.02);
    var textureCtl = Lag.kr(texture.clip(0, 1), 0.02);
    var widthCtl = Lag.kr(width.clip(0, 1), 0.025);
    var phase = Phasor.kr(
        Impulse.kr(0),
        Lag.kr(beatHz.clip(2, 2.666667), 0.005) * ControlDur.ir /
            cycleBeats.clip(0.5, 3.5),
        0, 1, phaseOffset.clip(0, 0.99999)
    );
    var pulse = 1 - ((phase * 2) - 1).abs;
    var cyclic = Select.kr(
        sync.clip(0, 1),
        [LFTri.kr(wobbleHz.clip(0.25, 12)).range(0.2, 1), pulse]
    );
    var contour = EnvGen.kr(Env(
        [motionStart.clip(0, 1), motionPeak.clip(0, 1), motionEnd.clip(0, 1)],
        [safeDur * rise, safeDur * (1 - rise)], \lin
    ));
    var loopMix = motionLoop.clip(0, 1);
    var motion = Lag.kr(
        ((contour * (1 - loopMix)) + (cyclic * loopMix)) * movementCtl,
        0.008
    ).clip(0, 1);
    var fmDepth = fmIndex.clip(0, 3) * growlCtl * (0.35 + (0.65 * motion));
    var modulator = SinOsc.ar(freqCtl * 2.5, 0, freqCtl * fmDepth);
    var carrier = SinOsc.ar(freqCtl + modulator);
    var ring = carrier * SinOsc.ar(freqCtl * 1.5);
    var sawLeft = Saw.ar(freqCtl * 0.992);
    var sawRight = Saw.ar(freqCtl * 1.008);
    var raw = (carrier * 0.62) + (ring * textureCtl * 0.32) +
        ((sawLeft + sawRight) * textureCtl * 0.14);
    var drive = 1 + (4 * aggressionCtl);
    var shaped = (LPF.ar(raw, 6500) * drive).tanh / drive.sqrt;
    var toneRatio = 2 ** ((toneCtl - 0.5) * 1.4);
    var formantOne = Lag.kr((360 + (motion * 430)) * toneRatio, 0.01).clip(250, 1500);
    var formantTwo = Lag.kr((850 + (motion * 700)) * toneRatio, 0.01).clip(550, 2700);
    var formantThree = Lag.kr((1850 + (motion * 1050)) * toneRatio, 0.01).clip(1200, 4800);
    var vowels = (BPF.ar(shaped, formantOne, 0.30) * 0.55) +
        (BPF.ar(shaped, formantTwo, 0.27) * 0.47) +
        (BPF.ar(shaped, formantThree, 0.32) * 0.35);
    var center = LeakDC.ar((shaped * 0.32) + (vowels * 1.4));
    var side = HPF.ar(sawLeft - sawRight, 220) * textureCtl * widthCtl * 0.08;
    var stereo = [center + side, center - side];
    var upper = HPF.ar(HPF.ar(stereo, 150), 150);
    var output = LPF.ar(upper, cutoff.clip(1200, 8000));
    var wobbleGain = 1 - (0.70 * movementCtl * (1 - motion));
    Out.ar(out, output * wobbleGain * ampEnv * gateEnv *
        Lag.kr(amp.clip(0, 0.30), 0.01));
})
