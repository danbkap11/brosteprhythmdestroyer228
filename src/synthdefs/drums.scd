[
    SynthDef(\bbKick, { |out = 0, amp = 0.46, decay = 0.24|
        var env = EnvGen.kr(Env.perc(0.001, decay, curve: -5), doneAction: 2);
        var pitch = EnvGen.kr(Env([135, 72, 43], [0.025, decay], -6));
        var body = SinOsc.ar(pitch) * 0.72;
        var clickEnv = EnvGen.kr(Env.perc(0.001, 0.012));
        var click = HPF.ar(WhiteNoise.ar, 2600) * clickEnv * 0.16;
        Out.ar(out, (((body * env) + click) * amp) ! 2);
    }),

    SynthDef(\bbSnare, { |out = 0, amp = 0.30, decay = 0.23|
        var env = EnvGen.kr(Env.perc(0.002, decay, curve: -4), doneAction: 2);
        var body = (SinOsc.ar(185) + SinOsc.ar(232)) * 0.22;
        var noise = BPF.ar(WhiteNoise.ar, 2100, 0.8) * 0.72;
        var snap = HPF.ar(WhiteNoise.ar, 4500) *
            EnvGen.kr(Env.perc(0.001, 0.025)) * 0.32;
        Out.ar(out, ((((body + noise) * env) + snap) * amp) ! 2);
    }),

    SynthDef(\bbHat, { |out = 0, amp = 0.095, decay = 0.045|
        var env = EnvGen.kr(Env.perc(0.001, decay, curve: -5), doneAction: 2);
        var metal = HPF.ar(WhiteNoise.ar, 7200);
        Out.ar(out, (metal * env * amp) ! 2);
    }),

    SynthDef(\bbOpenHat, { |out = 0, amp = 0.07|
        var env = EnvGen.kr(Env.perc(0.002, 0.16, curve: -5), doneAction: 2);
        var metal = HPF.ar(WhiteNoise.ar, 5700);
        Out.ar(out, (metal * env * amp) ! 2);
    }),

    SynthDef(\bbRise, { |out = 0, amp = 0.15, dur = 6|
        var safeDur = dur.clip(0.5, 8);
        var sweep = XLine.kr(450, 7200, safeDur);
        var env = EnvGen.kr(Env(
            [0, 0.06, 0.7, 0],
            [safeDur * 0.20, safeDur * 0.76, safeDur * 0.04],
            \lin
        ), doneAction: 2);
        var noise = HPF.ar(WhiteNoise.ar, sweep) * 0.55;
        var whistle = SinOsc.ar(XLine.kr(250, 950, safeDur)) * 0.08;
        Out.ar(out, ((noise + whistle) * env * amp.clip(0, 0.25)) ! 2);
    }),

    SynthDef(\bbImpact, { |out = 0, amp = 0.22|
        var env = EnvGen.kr(Env.perc(0.002, 0.85, curve: -5), doneAction: 2);
        var noise = WhiteNoise.ar;
        var bright = HPF.ar(noise, 500) * 0.42;
        var metallic = BPF.ar(noise, 1350, 0.45) * 0.40;
        Out.ar(out, ((bright + metallic) * env * amp.clip(0, 0.30)) ! 2);
    })
]
