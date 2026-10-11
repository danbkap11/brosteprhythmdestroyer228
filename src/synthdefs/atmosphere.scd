// Quiet chord/air support. The drop's separate mono sub owns the low band.
SynthDef(\bbAtmosphere, { |out = 0, freq = 146.83, amp = 0.09, dur = 3.4,
    gate = 1, beatHz = 2.333333, duckBus = -1, tone = 0.38,
    width = 0.42, thirdSemis = 3, fifthSemis = 7|
    var safeDur = dur.clip(0.4, 4.5);
    var env = EnvGen.ar(Env([0, 1, 0.88, 0],
        [0.025, safeDur - 0.265, 0.24], [-2, -1, -4]), doneAction: 2);
    var release = EnvGen.ar(Env.asr(0.01, 1, 0.18, -4),
        gate.clip(0, 1), doneAction: 2);
    var hz = Lag.kr(freq.clip(100, 800), 0.025);
    var toneCtl = Lag.kr(tone.clip(0, 1), 0.04);
    var widthCtl = Lag.kr(width.clip(0, 1), 0.04);
    var rates = [1, thirdSemis.clip(0, 7).midiratio,
        fifthSemis.clip(5, 12).midiratio];
    var chord = Mix(Saw.ar(hz * rates)) / 3;
    var round = Mix(SinOsc.ar(hz * rates * 2)) / 3;
    var motion = SinOsc.kr(beatHz.clip(1.8, 3.2) / 8).range(0.78, 1);
    var cutoff = ((1400 + (toneCtl * 3800)) * motion).clip(1000, 5200);
    var center = LPF.ar(((chord * 0.40) + (round * 0.16)).tanh,
        cutoff);
    var detuned = (Mix(Saw.ar(hz * rates * 1.003))
        - Mix(Saw.ar(hz * rates * 0.997))) / 3;
    var air = HPF.ar(PinkNoise.ar(0.006 + (toneCtl * 0.008)), 2200);
    var side = LPF.ar(HPF.ar(detuned, 650), cutoff)
        * widthCtl * 0.13;
    var stereo = HPF.ar(LeakDC.ar(
        [center + air + side, center + air - side]), 300);
    var duck = Select.kr(duckBus >= 0, [1, In.kr(duckBus.max(0), 1)]);
    Out.ar(out, stereo * env * release * amp.clip(0, 0.16)
        * duck.clip(0, 1).linlin(0, 1, 0.4, 1));
})
