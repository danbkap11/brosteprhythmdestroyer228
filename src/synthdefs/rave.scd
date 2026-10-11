// An articulated upper-register brass/rave hook, above the bass's body band.
SynthDef(\bbRave, { |out = 0, freq = 293.66, amp = 0.12, dur = 0.25,
    gate = 1, tone = 0.62, width = 0.32, duckBus = -1|
    var safeDur = dur.clip(0.07, 0.85);
    var tail = (safeDur * 0.22).clip(0.018, 0.12);
    var env = EnvGen.ar(Env([0, 1, 0.72, 0],
        [0.003, (safeDur - tail - 0.003).max(0.005), tail],
        [-4, -1, -4]), doneAction: 2);
    var release = EnvGen.ar(Env.asr(0.001, 1, 0.035, -4),
        gate.clip(0, 1), doneAction: 2);
    var hz = freq.clip(150, 1500);
    var pitch = EnvGen.kr(Env([1.035, 1], [0.025], -4));
    var raw = (Mix(Saw.ar(hz * pitch * [0.996, 1, 1.004])) * 0.22)
        + (Pulse.ar(hz * 2, 0.46) * 0.11);
    var brightness = EnvGen.kr(Env([1, 0.55], [safeDur], -3));
    var cutoff = ((1400 + (tone.clip(0, 1) * 4600)) * brightness).clip(800, 7500);
    var brassy = RLPF.ar((LPF.ar(raw, 6500) * 2.8).tanh, cutoff, 0.5);
    var center = LeakDC.ar((brassy + (BPF.ar(brassy, 1800, 0.65) * 0.45)).tanh);
    var side = HPF.ar(Saw.ar(hz * 1.006) - Saw.ar(hz * 0.994), 900)
        * width.clip(0, 0.6) * 0.10;
    var stereo = HPF.ar([center + side, center - side], 400);
    var duck = Select.kr(duckBus >= 0, [1, In.kr(duckBus.max(0), 1)]);
    Out.ar(out, stereo * env * release * amp.clip(0, 0.18)
        * duck.linlin(0, 1, 0.5, 1));
})
