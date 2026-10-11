SynthDef(\bbMaster, { |in = 0, amp = 0.20, peak = 0.68|
    var dry = LeakDC.ar(In.ar(in, 2));
    // Both channels follow the same detector so the stereo image stays put.
    var detector = (dry[0].abs + dry[1].abs) * 0.5;
    var glued = Compander.ar(dry, detector, 0.16, 1, 0.45,
        0.006, 0.16);
    var safe = Limiter.ar(glued * 1.35, peak, 0.01);
    Out.ar(0, safe * Lag.kr(amp, 0.025));
})
