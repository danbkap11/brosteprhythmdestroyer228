// Quiet distorted upper harmonics on selected bass hits; no competing sub.
SynthDef(\bbBassTop, { |out = 0, freq = 73.42, amp = 0.075,
    dur = 0.35, width = 0.20, duckBus = -1|
    var safeDur = dur.clip(0.06, 0.85);
    var tail = (safeDur * 0.16).clip(0.018, 0.10);
    var env = EnvGen.ar(Env(
        [0, 1, 0.82, 0],
        [0.004, (safeDur - 0.004 - tail).max(0.005), tail],
        [-4, 0, -4]
    ), doneAction: 2);
    var hz = freq.clip(40, 300);
    var left = Saw.ar(hz * 2.005);
    var right = Saw.ar(hz * 1.995);
    var band = LPF.ar((left + right) * 0.5, 5000);
    var driven = LPF.ar((band * 4.4).tanh, 7600);
    var mid = HPF.ar(LeakDC.ar(driven), 650);
    var side = HPF.ar(left - right, 900) * width.clip(0, 0.35) * 0.20;
    var stereo = [mid + side, mid - side];
    var duck = Select.kr(duckBus >= 0, [1, In.kr(duckBus.max(0), 1)]);
    Out.ar(out, stereo * env * amp.clip(0, 0.11) * duck.linlin(0, 1, 0.35, 1));
})
