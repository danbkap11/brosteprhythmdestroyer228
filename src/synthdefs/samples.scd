// Mono CC0 one-shots, routed through the same protected mix as the synth voices.
SynthDef(\bbSample, { |out = 0, bufnum = 0, amp = 0.15, rate = 1,
    hp = 20, width = 0|
    var sound = PlayBuf.ar(
        1, bufnum, BufRateScale.kr(bufnum) * rate.clip(0.8, 1.2),
        doneAction: 2
    );
    var side;
    sound = LeakDC.ar(HPF.ar(sound, hp.clip(20, 1500)));
    side = (DelayC.ar(HPF.ar(sound, 900), 0.02, 0.011) -
        HPF.ar(sound, 900)) * width.clip(0, 0.5) * 0.5;
    Out.ar(out, [sound + side, sound - side] * amp.clip(0, 0.35));
})
