[
    SynthDef(\bbSub, { |out = 0, freq = 36.71, amp = 0.22, decay = 0.19|
        var env = EnvGen.kr(Env.perc(0.004, decay, curve: -4), doneAction: 2);
        var tone = LPF.ar(SinOsc.ar(freq), 90);
        Out.ar(out, (tone * env * amp) ! 2);
    }),

    SynthDef(\bbGrowl, { |out = 0, freq = 73.42, amp = 0.16, dur = 0.25,
        wobbleHz = 3, fmIndex = 2.3, cutoff = 2600, gate = 1,
        attack = 0.006, release = 0.02, growl = 0.65, movement = 0.65,
        aggression = 0.45, tone = 0.5, texture = 0.35, width = 0.15,
        rq = 0.32, sync = 0, beatHz = 2.333333, cycleBeats = 1,
        phaseOffset = 0, motionLoop = 0.25, motionStart = 0.2,
        motionPeak = 1, motionEnd = 0.15, riseFrac = 0.15|
        var safeDur = dur.clip(0.05, 1.48);
        var safeAttack = attack.clip(0.003, 0.02);
        var ampEnv = EnvGen.ar(
            Env.perc(safeAttack, safeDur, curve: -3), doneAction: 2
        );
        var gateEnv = EnvGen.ar(
            Env.asr(0.001, 1, release.clip(0.005, 0.05), -4),
            gate.clip(0, 1), doneAction: 2
        );
        var ampCtl = Lag.kr(amp.clip(0, 0.30), 0.01);
        var growlCtl = Lag.kr(growl.clip(0, 1), 0.015);
        var movementCtl = Lag.kr(movement.clip(0, 1), 0.015);
        var aggressionCtl = Lag.kr(aggression.clip(0, 1), 0.015);
        var toneCtl = Lag.kr(tone.clip(0, 1), 0.02);
        var textureCtl = Lag.kr(texture.clip(0, 1), 0.02);
        var widthCtl = Lag.kr(width.clip(0, 1), 0.025);
        var freqCtl = Lag.kr(freq.clip(30, 500), 0.015);
        var beatCtl = Lag.kr(beatHz.clip(2, 2.666667), 0.005);
        var cycle = cycleBeats.clip(0.5, 3.5);
        var phase = Phasor.kr(
            Impulse.kr(0), beatCtl * ControlDur.ir / cycle,
            0, 1, phaseOffset.clip(0, 0.99999)
        );
        var syncedMotion = 1 - ((phase * 2) - 1).abs;
        var freeMotion = LFTri.kr(wobbleHz.clip(0.25, 12)).range(0.22, 1);
        var cyclicMotion = Select.kr(sync.clip(0, 1), [freeMotion, syncedMotion]);
        var motionEnv = EnvGen.kr(
            Env(
                [motionStart.clip(0, 1), motionPeak.clip(0, 1), motionEnd.clip(0, 1)],
                [safeDur * riseFrac.clip(0.05, 0.80), safeDur * (1 - riseFrac.clip(0.05, 0.80))],
                \lin
            )
        );
        var motionMix = Lag.kr(motionLoop.clip(0, 1), 0.005);
        var motion = Lag.kr(
            (motionEnv * (1 - motionMix)) + (cyclicMotion * motionMix), 0.005
        ).clip(0, 1);
        var fmDepth = fmIndex.clip(0, 3) * growlCtl *
            (1 - movementCtl + (movementCtl * motion));
        var sawL = Saw.ar(freqCtl * 0.995);
        var sawR = Saw.ar(freqCtl * 1.005);
        var mod = SinOsc.ar(freqCtl * 2, 0, freqCtl * fmDepth);
        var fm = SinOsc.ar(freqCtl + mod);
        var body = (fm * 0.68) + ((sawL + sawR) * 0.20 * textureCtl);
        var preFiltered = LPF.ar(body, 6000);
        var drive = 1 + (3 * aggressionCtl);
        var shaped = (preFiltered * drive).tanh / drive.tanh.max(0.1);
        var octaves = 1.5 * growlCtl * ((motion * 2) - 1) * movementCtl;
        var toneRatio = 2 ** ((toneCtl - 0.5) * 2);
        var movingCutoff = Lag.kr(
            (cutoff.clip(280, 8000) * toneRatio * (2 ** octaves)).clip(280, 8000),
            0.02
        );
        var rqCtl = Lag.kr(rq.clip(0.25, 0.8), 0.02);
        var filtered = RLPF.ar(shaped, movingCutoff, rqCtl);
        var mid = LeakDC.ar(filtered);
        var side = LeakDC.ar((sawL - sawR) * 0.5 * textureCtl);
        var wideSide = HPF.ar(HPF.ar(side, 180), 180) * (0.35 * widthCtl);
        var stereo = [mid + wideSide, mid - wideSide];
        var upperBand = HPF.ar(HPF.ar(stereo, 150), 150);
        var output = LPF.ar(upperBand, movingCutoff);
        var wobbleGain = 1 - (0.70 * movementCtl * (1 - motion));
        Out.ar(out, output * wobbleGain * ampEnv * gateEnv * ampCtl);
    })
]
