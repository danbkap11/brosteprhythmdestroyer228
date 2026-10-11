// Metallic upper counterline with two finite, tempo-related echo taps.
SynthDef(\bbSpark, { |out = 0, freq = 587.33, amp = 0.08, dur = 0.18,
    gate = 1, beatHz = 2.333333, duckBus = -1, tone = 0.52, width = 0.34|
    var safeDur = dur.clip(0.06, 0.6);
    var tempo = Lag.kr(beatHz.clip(1.8, 3.2), 0.02);
    var lastTap = 0.75 / tempo;
    var lifetime = safeDur + (0.75 / beatHz.clip(1.8, 3.2)) + 0.08;
    var life = EnvGen.kr(Env([1, 1, 0], [lifetime, 0.01]), doneAction: 2);
    var release = EnvGen.ar(Env.asr(0.001, 1, 0.055, -4),
        gate.clip(0, 1), doneAction: 2);
    var env = EnvGen.ar(Env([0, 1, 0.14, 0],
        [0.003, safeDur * 0.5, (safeDur * 0.5) - 0.003],
        [-4, -5, -6]));
    var hz = Lag.kr(freq.clip(200, 2400), 0.01);
    var toneCtl = Lag.kr(tone.clip(0, 1), 0.025);
    var widthCtl = Lag.kr(width.clip(0, 1), 0.025);
    var pitch = EnvGen.kr(Env([1.012, 1], [0.018], -4));
    var modEnv = EnvGen.kr(Env([1, 0.2], [safeDur * 0.7], -4));
    var fm = SinOsc.ar(hz * pitch,
        SinOsc.ar((hz * 2.414).clip(400, 9000))
            * (1.2 + (toneCtl * 3)) * modEnv);
    var harmonics = Saw.ar(hz * 1.002) * 0.17;
    var dry = HPF.ar(LPF.ar(((fm * 0.52) + harmonics).tanh,
        2000 + (toneCtl * 6200)), 300) * env;
    var echoA = DelayC.ar(dry, 0.56, 0.5 / tempo) * 0.30;
    var echoB = DelayC.ar(dry, 0.56, lastTap) * 0.16;
    var center = dry + echoA + echoB;
    var side = HPF.ar(DelayC.ar(echoA + echoB, 0.02, 0.007)
        - (echoA + echoB), 700) * widthCtl * 0.45;
    var stereo = HPF.ar(LeakDC.ar([center + side, center - side]), 300);
    var duck = Select.kr(duckBus >= 0, [1, In.kr(duckBus.max(0), 1)]);
    Out.ar(out, stereo * release * life * amp.clip(0, 0.12)
        * duck.clip(0, 1).linlin(0, 1, 0.4, 1));
})
