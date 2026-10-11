{ |app|
    // Resolve all random musical choices before transport. Random is local to
    // this generation call, so the language's shared random stream is untouched.
    app[\generatePlan] = {
        var seed = app[\seed];
        var config = app[\config];
        var plan = Array.new(config[\bars] * config[\meterEighths]);
        var bassNotes = [38, 41, 36, 43, 38, 45, 41];
        var subNotes = [26, 26, 30, 26, 31, 26, 33, 26];
        var builder = Routine({
            thisThread.randSeed = seed;

            config[\bars].do { |bar|
              config[\meterEighths].do { |step|
                var groupIndex = 0;
                var groupStart = 0;
                var scanStep = 0;
                var groupLength = 1;
                var cycleBeats;
                var phaseOffset;
                var motionStart;
                var motionEnd;
                var riseFrac;
                var accent;
                var isFill = (step == 6) and: { (bar % 4) == 3 };
                var kick = [0, 3].includes(step) or: { isFill };
                var snare = step == 4;
                var hat = [0, 2, 4].includes(step)
                    or: { (step == 6) and: { (bar % 2) == 0 } };
                var bassHit = [1, 2, 5, 6].includes(step)
                    or: { ((bar % 2) == 1) and: { step == 4 } };
                var bassMidi;
                var bassEvent = nil;

                // Density varies off-accent hats and optional bass responses.
                if ([1, 3, 5].includes(step)) {
                    hat = 1.0.rand < app[\density];
                };
                if ([1, 6].includes(step) and: { 1.0.rand < ((1 - app[\density]) * 0.30) }) {
                    bassHit = false;
                };

                config[\grouping].do { |length, index|
                    if ((step >= scanStep) and: { step < (scanStep + length) }) {
                        groupIndex = index;
                        groupStart = scanStep;
                        groupLength = length;
                    };
                    scanStep = scanStep + length;
                };
                cycleBeats = groupLength * 0.5;
                phaseOffset = ((step - groupStart) * 0.5) / cycleBeats;

                if (groupIndex == 0) {
                    motionStart = 0.20; motionEnd = 0.15; riseFrac = 0.12; accent = 1.0;
                } {
                    if (groupIndex == 1) {
                        motionStart = 0.65; motionEnd = 0.20; riseFrac = 0.35; accent = 0.85;
                    } {
                        motionStart = 0.15; motionEnd = 0.35; riseFrac = 0.60; accent = 1.10;
                    };
                };

                bassMidi = bassNotes.wrapAt(step + (bar % 4));
                if (bassHit) {
                    // Variation selects only from the existing tonal pitch pool.
                    if (1.0.rand < app[\variation]) {
                        bassMidi = bassNotes.wrapAt(bassNotes.size.rand);
                    };
                    bassEvent = (
                        midi: bassMidi,
                        amp: (if (bar < 4, 0.17, 0.19) * accent),
                        dur: if ([2, 5].includes(step), 0.22, 0.28),
                        wobbleHz: if (bar < 4, 2.6, 4.2),
                        fmIndex: if (bar < 4, 2.7, 1.8),
                        cutoff: if (bar < 4, 2100, 3300),
                        groupIndex: groupIndex,
                        cycleBeats: cycleBeats,
                        phaseOffset: phaseOffset,
                        motionStart: motionStart,
                        motionEnd: motionEnd,
                        riseFrac: riseFrac
                    );
                };

                plan.add((
                    bar: bar,
                    step: step,
                    kick: kick,
                    snare: snare,
                    hat: hat,
                    subMidi: if ([2, 5].includes(step), subNotes.wrapAt(bar), nil),
                    bass: bassEvent,
                    fill: isFill
                ));
              };
            };
        });
        builder.next;
        app[\plan] = plan;
        plan.copy;
    };

    app[\generatePlan].value;

    app[\start] = {
        app[\checkServer].value;
        if (app[\state] == \playing) {
            "BALKAN//BASS is already playing.".postln;
        } {
            if (app[\state] != \ready) {
                ("Cannot start engine in state: " ++ app[\state]).postln;
            } {
                var source = app[\voiceGroup];
                var out = app[\mixBus].index;

                if (app[\pendingBpm].notNil) {
                    app[\bpm] = app[\pendingBpm];
                    app[\pendingBpm] = nil;
                };
                app[\runId] = app[\runId] + 1;
                app[\masterNode].set(\amp, app[\masterTarget]);
                app[\clock] = TempoClock.new(app[\bpm] / 60);
                app[\routine] = Routine({
                    var playRun = app[\runId];
                    var kick = { |level = 0.43|
                        Synth.tail(source, \bbKick, [\out, out, \amp, level]);
                    };
                    var snare = { |level = 0.29|
                        Synth.tail(source, \bbSnare, [\out, out, \amp, level]);
                    };
                    var hat = { |level = 0.085|
                        Synth.tail(source, \bbHat, [\out, out, \amp, level]);
                    };

                    while { playRun == app[\runId] } {
                        app[\plan].do { |event|
                            var bass = event[\bass];
                            if (event[\kick]) { kick.value(if (event[\fill], 0.30, 0.43)) };
                            if (event[\snare]) { snare.value(0.29) };
                            if (event[\hat]) { hat.value(if ([0, 2, 4].includes(event[\step]), 0.105, 0.072)) };
                            if (event[\subMidi].notNil) {
                                Synth.tail(source, \bbSub, [
                                    \out, out, \freq, event[\subMidi].midicps,
                                    \amp, 0.20, \decay, 0.19
                                ]);
                            };
                            if (bass.notNil) {
                                Synth.tail(source, \bbGrowl, [
                                    \out, out, \freq, bass[\midi].midicps,
                                    \amp, bass[\amp], \dur, bass[\dur],
                                    \wobbleHz, bass[\wobbleHz], \fmIndex, bass[\fmIndex],
                                    \cutoff, bass[\cutoff],
                                    \growl, app[\bassControls][\growl],
                                    \movement, app[\bassControls][\movement],
                                    \aggression, app[\bassControls][\aggression],
                                    \tone, app[\bassControls][\tone],
                                    \texture, app[\bassControls][\texture],
                                    \width, app[\bassControls][\width],
                                    \sync, 1, \beatHz, app[\clock].tempo,
                                    \cycleBeats, bass[\cycleBeats],
                                    \phaseOffset, bass[\phaseOffset], \motionLoop, 0.35,
                                    \motionStart, bass[\motionStart], \motionPeak, 1,
                                    \motionEnd, bass[\motionEnd], \riseFrac, bass[\riseFrac]
                                ]);
                            };
                            if (event[\fill]) {
                                0.25.wait;
                                snare.value(0.13);
                                0.25.wait;
                            } {
                                0.5.wait;
                            };
                            if ((event[\step] == 6) and: { app[\pendingBpm].notNil }) {
                                app[\bpm] = app[\pendingBpm];
                                app[\clock].tempo = app[\bpm] / 60;
                                app[\pendingBpm] = nil;
                            };
                        };
                    };
                    "BALKAN//BASS transport stopped.".postln;
                });
                app[\routine].play(app[\clock], 0);
                app[\state] = \playing;
                ("BALKAN//BASS looping at " ++ app[\bpm] ++
                    " BPM, 7/8, " ++ app[\config][\bars] ++ " bars per phrase.").postln;
            };
        };
    };

    app[\stop] = {
        if (app[\state] == \playing) {
            var stopRun;
            app[\runId] = app[\runId] + 1;
            stopRun = app[\runId];
            app[\routine].tryPerform(\stop);
            app[\state] = \stopping;
            app[\masterNode].set(\amp, 0);
            SystemClock.sched(0.075, {
                if ((app[\runId] == stopRun) and: { app[\state] == \stopping }) {
                    app[\voiceGroup].freeAll;
                    app[\clock].clear;
                    app[\clock].stop;
                    app[\routine] = nil;
                    app[\clock] = nil;
                    app[\state] = \ready;
                    "BALKAN//BASS stopped; active voices released.".postln;
                };
                nil;
            });
        } {
            if (app[\state] == \stopping) {
                "BALKAN//BASS stop is already in progress.".postln;
            } {
                "BALKAN//BASS is not playing.".postln;
            };
        };
    };
}
