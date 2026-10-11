SynthDef(\bbMaster, { |in = 0, amp = 0.20, peak = 0.68|
    var dry = LeakDC.ar(In.ar(in, 2));
    var safe = Limiter.ar(dry, peak, 0.01);
    Out.ar(0, safe * Lag.kr(amp, 0.025));
})
