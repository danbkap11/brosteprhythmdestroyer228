[
    SynthDef(\bbSub, { |out = 0, freq = 36.71, amp = 0.22, decay = 0.19,
        dur = -1, gate = 1, duckBus = -1|
        var sustained = dur >= 0;
        var safeDur = Select.kr(sustained,
            [decay.clip(0.06, 1.4), dur.clip(0.06, 1.4)]);
        var tail = (safeDur * 0.12).clip(0.015, 0.08);
        var env = EnvGen.ar(Env([0, 1, sustained * 0.92, 0],
            [0.004, (safeDur - 0.004 - tail).max(0.005), tail],
            [-4, (sustained * 4) - 4, -4]), doneAction: 2);
        var gateEnv = EnvGen.ar(Env.asr(0.001, 1, 0.025, -4),
            gate.clip(0, 1), doneAction: 2);
        var tone = LPF.ar(SinOsc.ar(freq.clip(30, 90)), 90);
        var duck = Select.kr(duckBus >= 0, [1, In.kr(duckBus.max(0), 1)]);
        Out.ar(out, (tone * env * gateEnv * amp.clip(0, 0.25) * duck) ! 2);
    }),

    SynthDef(\bbGrowl, { |out = 0, freq = 73.42, amp = 0.16, dur = 0.25,
        wobbleHz = 3, fmIndex = 2.3, cutoff = 2600, gate = 1,
        attack = 0.006, release = 0.02, growl = 0.65, movement = 0.65,
        aggression = 0.45, tone = 0.5, texture = 0.35, width = 0.15,
        rq = 0.32, sync = 0, beatHz = 2.333333, cycleBeats = 1,
        phaseOffset = 0, motionLoop = 0.25, motionStart = 0.2,
        motionPeak = 1, motionEnd = 0.15, riseFrac = 0.15, duckBus = -1|
        var safeDur = dur.clip(0.05, 1.48);
        var safeAttack = attack.clip(0.003, 0.02);
        var tail = (safeDur * 0.16).clip(0.018, 0.12);
        var ampEnv = EnvGen.ar(
            Env([0, 1, 0.88, 0],
                [safeAttack, (safeDur - safeAttack - tail).max(0.005), tail],
                [-4, 0, -4]), doneAction: 2
        );
        var gateEnv = EnvGen.ar(
            Env.asr(0.001, 1, release.clip(0.005, 0.05), -4),
            gate.clip(0, 1), doneAction: 2
        );
        var ampCtl = Lag.kr(amp.clip(0, 0.32), 0.01);
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
        var octaveSaw = Saw.ar(freqCtl * 2);
        // A third operator moves the harmonic structure, not just the volume.
        var harmonicMod = SinOsc.ar(freqCtl * 3, 0,
            freqCtl * (0.25 + (textureCtl * 1.2)) * (0.4 + motion));
        var mod = SinOsc.ar((freqCtl * 2) + harmonicMod, 0,
            freqCtl * fmDepth);
        var fm = SinOsc.ar(freqCtl + mod);
        var body = (fm * 0.68) + ((sawL + sawR) * 0.20 * textureCtl)
            + (octaveSaw * 0.13 * textureCtl);
        var preFiltered = LPF.ar(body, 6000);
        var drive = 1.5 + (6 * aggressionCtl);
        // Different drive on the body and upper harmonics preserves the chest.
        var chest = HPF.ar(LPF.ar(preFiltered, 600), 95);
        var rasp = HPF.ar(preFiltered, 600);
        var shaped = ((chest * (1.3 + (aggressionCtl * 2.4))).tanh * 0.70)
            + ((rasp * drive).tanh * 0.55);
        var octaves = 1.5 * growlCtl * ((motion * 2) - 1) * movementCtl;
        var toneRatio = 2 ** ((toneCtl - 0.5) * 2);
        var movingCutoff = Lag.kr(
            (cutoff.clip(280, 8000) * toneRatio * (2 ** octaves)).clip(280, 8000),
            0.02
        );
        var rqCtl = Lag.kr(rq.clip(0.25, 0.8), 0.02);
        var filtered = RLPF.ar(shaped, movingCutoff, rqCtl);
        var throat = (BPF.ar(shaped,
            ((520 + (motion * 1100)) * toneRatio).clip(350, 3200), 0.30)
                * 0.85) + (BPF.ar(shaped,
            ((1400 + ((1 - motion) * 950)) * toneRatio).clip(800, 4400),
            0.35) * 0.60);
        var mid = LeakDC.ar(((filtered * 1.30) + (throat * 1.35)
            + (shaped * 0.23)).tanh);
        var side = LeakDC.ar((sawL - sawR) * 0.5 * textureCtl);
        var wideSide = HPF.ar(HPF.ar(side, 180), 180) * (0.35 * widthCtl);
        var stereo = [mid + wideSide, mid - wideSide];
        var upperBand = HPF.ar(HPF.ar(stereo, 115), 115);
        var output = LPF.ar(upperBand, movingCutoff);
        var compressed = Compander.ar(output, output, 0.28,
            1, 0.65, 0.006, 0.09);
        var protected = HPF.ar(HPF.ar(
            LeakDC.ar((compressed * 2.6).tanh), 115), 115);
        var wobbleGain = 1 - (0.35 * movementCtl *
            motionLoop.clip(0, 1) * (1 - motion));
        var duck = Select.kr(duckBus >= 0, [1, In.kr(duckBus.max(0), 1)]);
        Out.ar(out, protected * wobbleGain *
            ampEnv * gateEnv * ampCtl * duck.linlin(0, 1, 0.35, 1));
    })
]
