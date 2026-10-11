// Original vowel-like fallback if the optional CC0 vocal sample is unavailable.
SynthDef(\bbShout, { |out = 0, amp = 0.25, dur = 0.36|
    var safeDur = dur.clip(0.18, 0.6);
    var env = EnvGen.kr(
        Env.perc(0.012, safeDur - 0.012, curve: -2), doneAction: 2
    );
    var pitch = XLine.kr(255, 165, safeDur);
    var vowel = Line.kr(0, 1, safeDur);
    var source = (Saw.ar(pitch) * 0.75) +
        (Pulse.ar(pitch, 0.42) * 0.25);
    var formantOne = 620 - (vowel * 230);
    var formantTwo = 1700 + (vowel * 600);
    var formantThree = 2650 + (vowel * 250);
    var voiced = (
        (BPF.ar(source, formantOne, 0.30) * 2.0) +
        (BPF.ar(source, formantTwo, 0.24) * 1.7) +
        (BPF.ar(source, formantThree, 0.28) * 1.0)
    );
    var breath = HPF.ar(WhiteNoise.ar, 1600) *
        EnvGen.kr(Env.perc(0.001, 0.075)) * 0.15;
    var call = HPF.ar(LeakDC.ar(((voiced * 2.8) + breath).tanh), 180);
    Out.ar(out, (call * env * amp.clip(0, 0.30)) ! 2);
})
