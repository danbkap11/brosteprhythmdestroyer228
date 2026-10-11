// Rounded plucked/reed hook. Keep the old name/API for existing event plans.
SynthDef(\bbRave, { |out = 0, freq = 293.66, amp = 0.12, dur = 0.25,
    gate = 1, tone = 0.62, width = 0.32, duckBus = -1|
    var safeDur = dur.clip(0.07, 1.25);
    var tail = (safeDur * 0.22).clip(0.018, 0.16);
    var env = EnvGen.ar(Env([0, 1, 0.62, 0],
        [0.005, (safeDur - tail - 0.005).max(0.005), tail],
        [-4, -1, -4]), doneAction: 2);
    var release = EnvGen.ar(Env.asr(0.001, 1, 0.045, -4),
        gate.clip(0, 1), doneAction: 2);
    var hz = Lag.kr(freq.clip(120, 1500), 0.008);
    var toneCtl = Lag.kr(tone.clip(0, 1), 0.025);
    var widthCtl = Lag.kr(width.clip(0, 0.6), 0.025);
    var string = Pluck.ar(PinkNoise.ar(0.4), Impulse.kr(0),
        0.012, hz.reciprocal, (safeDur * 1.25).clip(0.16, 1.5),
        0.38 + (toneCtl * 0.16));
    var reedMotion = EnvGen.kr(Env([0.28, 0.08], [safeDur], -3));
    var reed = (SinOsc.ar(hz, SinOsc.ar(hz * 2) * reedMotion) * 0.62)
        + (SinOsc.ar(hz * 2) * 0.15) + (SinOsc.ar(hz * 3) * 0.04);
    var breath = HPF.ar(PinkNoise.ar(0.006), 2400) * toneCtl;
    var brightness = EnvGen.kr(Env([1, 0.72], [safeDur], -3));
    var cutoff = ((1700 + (toneCtl * 2400)) * brightness).clip(900, 5200);
    var center = LeakDC.ar(LPF.ar(
        ((string * 0.90) + (reed * 0.40) + breath).tanh, cutoff));
    var high = HPF.ar(center, 900);
    var side = (DelayC.ar(high, 0.02, 0.008) - high) * widthCtl * 0.12;
    var stereo = HPF.ar([center + side, center - side], 220);
    var duck = Select.kr(duckBus >= 0, [1, In.kr(duckBus.max(0), 1)]);
    Out.ar(out, stereo * env * release * amp.clip(0, 0.18)
        * duck.linlin(0, 1, 0.5, 1));
})
