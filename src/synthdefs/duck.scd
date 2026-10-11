// Persistent kick-triggered gain contour; this node lives before the voice group.
SynthDef(\bbDuck, { |out = 0, t_kick = 0|
    var envelope = EnvGen.kr(
        Env([1, 0.15, 0.15, 1], [0.002, 0.025, 0.105], [-4, 0, 4]),
        t_kick
    );
    ReplaceOut.kr(out, envelope);
})
