SynthDef(\bbMaster, { |in = 0, amp = 0.20, peak = 0.68, sectionGain = 1|
    var dry = LeakDC.ar(In.ar(in, 2));
    // Both channels follow the same detector so the stereo image stays put.
    var detector = (dry[0].abs + dry[1].abs) * 0.5;
    var glued = Compander.ar(dry, detector, 0.12, 1, 0.55,
        0.012, 0.12);
    var punch = (dry * 0.35) + (glued * 0.65);
    // Program makeup is measured on the drop, with a fixed output ceiling.
    // Kick ducking creates transient room before this final limiter.
    var safe = Limiter.ar(punch * 7.5, peak.clip(0.4, 0.75), 0.006);
    Out.ar(0, safe * Lag.kr(amp, 0.025)
        * Lag.kr(sectionGain.clip(0, 1), 0.02));
})
