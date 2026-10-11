[
    SynthDef(\bbKick, { |out = 0, amp = 0.46, decay = 0.24|
        var env = EnvGen.kr(Env.perc(0.001, decay, curve: -5), doneAction: 2);
        var pitch = EnvGen.kr(Env([135, 72, 43], [0.025, decay], -6));
        var body = SinOsc.ar(pitch) * 0.72;
        var clickEnv = EnvGen.kr(Env.perc(0.001, 0.012));
        var click = HPF.ar(WhiteNoise.ar, 2600) * clickEnv * 0.11;
        Out.ar(out, ((body + click) * env * amp) ! 2);
    }),

    SynthDef(\bbSnare, { |out = 0, amp = 0.30, decay = 0.23|
        var env = EnvGen.kr(Env.perc(0.002, decay, curve: -4), doneAction: 2);
        var body = (SinOsc.ar(185) + SinOsc.ar(232)) * 0.22;
        var noise = BPF.ar(WhiteNoise.ar, 2100, 0.8) * 0.72;
        Out.ar(out, ((body + noise) * env * amp) ! 2);
    }),

    SynthDef(\bbHat, { |out = 0, amp = 0.095, decay = 0.045|
        var env = EnvGen.kr(Env.perc(0.001, decay, curve: -5), doneAction: 2);
        var metal = HPF.ar(WhiteNoise.ar, 7200);
        Out.ar(out, (metal * env * amp) ! 2);
    })
]
