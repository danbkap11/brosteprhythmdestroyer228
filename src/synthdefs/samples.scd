// Mono CC0 one-shots, routed through the same protected mix as the synth voices.
SynthDef(\bbSample, { |out = 0, bufnum = 0, amp = 0.15, rate = 1, hp = 20|
    var sound = PlayBuf.ar(
        1, bufnum, BufRateScale.kr(bufnum) * rate.clip(0.8, 1.2),
        doneAction: 2
    );
    sound = LeakDC.ar(HPF.ar(sound, hp.clip(20, 1500)));
    Out.ar(out, (sound * amp.clip(0, 0.35)) ! 2);
})
