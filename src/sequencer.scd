{ |app|
    // Resolve all musical choices once, with a Routine-local random stream.
    app[\generatePlan] = {
        var config = app[\config];
        var plan = Array.new(config[\bars] * config[\meterEighths]);
        var builder = Routine({
            var rootOrders = [
                [26, 26, 29, 29, 24, 24, 31, 31],
                [26, 26, 31, 31, 29, 29, 24, 24],
                [26, 26, 24, 24, 33, 33, 31, 31],
                [26, 26, 29, 29, 31, 31, 33, 33]
            ];
            // Each two-bar cell has a recognizable answer, with a different
            // seed selecting different riffs, roots and drum colors.
            var riffPairs = [
                [[1, 5], [2, 5]],
                [[1, 2, 5], [1, 5, 6]],
                [[2, 5], [1, 2, 6]],
                [[1, 5, 6], [2, 5]],
                [[1, 2], [1, 5]],
                [[2, 5, 6], [1, 5]]
            ];
            var introRiffs = [[2], [5], [1, 5], [2, 6], [1, 2]];
            var buildRiffs = [[2, 5], [1, 5], [2, 6], [1, 2, 5]];
            var rootOrder;
            var dropBRoots;
            var introRiffIndex;
            var buildRiffIndex;
            var cellRiffs;
            var cellVoices;
            var cellReplies;
            var cellKicks;
            var cellHats;
            var cellSnares;
            thisThread.randSeed = app[\seed];
            rootOrder = rootOrders.choose;
            dropBRoots = rootOrders.choose;
            introRiffIndex = introRiffs.size.rand;
            buildRiffIndex = buildRiffs.size.rand;
            cellRiffs = Array.fill(8, { riffPairs.choose });
            cellVoices = Array.fill(8, { 2.rand });
            cellReplies = Array.fill(8, { [0, 0, 7, 12].choose });
            cellKicks = Array.fill(8, { [2, 6].choose });
            cellHats = Array.fill(8, { 3.rand });
            cellSnares = Array.fill(8, { [\electroSnare, \hardSnare].choose });

            config[\bars].do { |bar|
                var section;
                var sectionBar;
                var isBuild;
                var isDrop;
                var root;
                var cell;
                var riff;

                section = if (bar < 4, { \intro }, {
                    if (bar < 8, { \build }, {
                        if (bar < 16, { \dropA }, {
                            if (bar < 20, { \breakdown }, {
                                if (bar < 24, { \build }, { \dropB });
                            });
                        });
                    });
                });
                isBuild = section == \build;
                isDrop = [\dropA, \dropB].includes(section);
                sectionBar = if (bar < 8, { bar - 4 }, { bar - 20 });
                root = if (section == \dropB, {
                    dropBRoots.wrapAt(bar - 24)
                }, {
                    rootOrder.wrapAt(bar)
                });
                if (isDrop) {
                    cell = if (section == \dropA, {
                        (bar - 8).div(2)
                    }, {
                        (bar - 24).div(2) + 4
                    });
                    riff = cellRiffs[cell][bar % 2];
                };

                config[\meterEighths].do { |step|
                    var groupIndex = 0;
                    var groupStart = 0;
                    var groupLength = 1;
                    var scanStep = 0;
                    var cycleBeats;
                    var phaseOffset;
                    var motionStart;
                    var motionEnd;
                    var riseFrac;
                    var accent;
                    var gap = isBuild and: { sectionBar == 3 } and: { step == 6 };
                    var kick = false;
                    var snare = false;
                    var hat = false;
                    var openHat = false;
                    var hatTick = false;
                    var bassHit = false;
                    var subMidi = nil;
                    var bassEvent = nil;
                    var roll = 0;
                    var impact = (step == 0) and: { [8, 24].includes(bar) };
                    var rise = (step == 0) and: { [4, 20].includes(bar) };
                    var talkCall = isDrop and: { cellVoices[cell] == 1 };
                    var voice = \bbGrowl;
                    var bassMidi;
                    var bassAmp;

                    if (section == \intro) {
                        kick = (step == 0) or: { (bar > 1) and: { step == 3 } };
                        snare = step == 4;
                        hat = if ((introRiffIndex % 2) == 0, {
                            [0, 2, 4].includes(step)
                        }, {
                            [0, 1, 4, 6].includes(step)
                        });
                        bassHit = introRiffs[(introRiffIndex + bar.div(2)) %
                            introRiffs.size].includes(step);
                    } {
                        if (isBuild) {
                            kick = [0, 3].includes(step);
                            snare = step == 4;
                            hat = [0, 2, 4].includes(step) or: {
                                [1, 3, 5].includes(step) and: {
                                    1.0.rand < (0.12 + (sectionBar * 0.16) +
                                        (app[\density] * 0.18))
                                }
                            };
                            bassHit = buildRiffs[buildRiffIndex].includes(step);
                            if (sectionBar == 3 and: { step == 6 }) {
                                bassHit = false;
                            };
                            if ((sectionBar == 2) and: { step == 6 }) { roll = 1 };
                            if ((sectionBar == 3) and: { step == 5 }) { roll = 2 };
                        } {
                            if (isDrop) {
                                kick = [0, 3].includes(step) or: {
                                    (step == cellKicks[cell]) and: {
                                        (bar % 2) == 1 and: {
                                            1.0.rand < app[\density]
                                        }
                                    }
                                };
                                snare = step == 4;
                                hat = switch(cellHats[cell],
                                    0, { [0, 2, 4].includes(step) },
                                    1, { [0, 1, 2, 4, 5].includes(step) },
                                    2, { [0, 2, 3, 4, 6].includes(step) }
                                );
                                if ([1, 3, 5, 6].includes(step)) {
                                    hat = hat and: { 1.0.rand < (0.35 + (app[\density] * 0.60)) };
                                };
                                openHat = (step == 2) and: { (bar % 2) == 1 };
                                if (openHat) { hat = false };
                                hatTick = [1, 3, 5].includes(step) and: {
                                    1.0.rand < (app[\density] *
                                        if (section == \dropB, 0.75, 0.35))
                                };
                                bassHit = riff.includes(step);
                                if ((step == 6) and: { [15, 31].includes(bar) }) {
                                    bassHit = false;
                                    roll = 1;
                                };
                            } {
                                kick = (step == 0) and: { (bar % 2) == 0 };
                                snare = step == 4;
                                hat = [0, 4].includes(step);
                                bassHit = if ((bar % 2) == 0, { step == 2 }, { step == 5 });
                                voice = \bbTalking;
                            };
                        };
                    };

                    // The last eighth of each build drops out before the impact.
                    if (gap) {
                        kick = false; snare = false; hat = false;
                        openHat = false; hatTick = false; bassHit = false;
                        roll = 0;
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
                        motionStart = 0.12; motionEnd = 0.15;
                        riseFrac = 0.18; accent = 1.0;
                    } {
                        if (groupIndex == 1) {
                            motionStart = 0.65; motionEnd = 0.10;
                            riseFrac = 0.35; accent = 0.88;
                        } {
                            motionStart = 0.18; motionEnd = 0.42;
                            riseFrac = 0.60; accent = 1.08;
                        };
                    };

                    if (bassHit) {
                        bassMidi = root + 12;
                        if (isDrop and: { [5, 6].includes(step) } and: {
                            1.0.rand < (0.25 + (app[\variation] * 0.65))
                        }) { bassMidi = bassMidi + cellReplies[cell] };
                        if (isDrop.not and: { [5, 6].includes(step) } and: {
                            1.0.rand < (app[\variation] * 0.55)
                        }) { bassMidi = bassMidi + 7 };
                        if (isDrop) {
                            voice = if ([1, 2].includes(step), {
                                if (talkCall, { \bbTalking }, { \bbGrowl })
                            }, {
                                if (talkCall, { \bbGrowl }, { \bbTalking })
                            });
                        };
                        bassAmp = if (isDrop, { 0.25 }, {
                            if (isBuild, { 0.15 }, { 0.12 })
                        });
                        bassEvent = (
                            synth: voice,
                            midi: bassMidi,
                            amp: bassAmp * accent,
                            dur: if ([2, 6].includes(step), { 0.12 }, {
                                if (isDrop, { 0.29 }, { 0.25 })
                            }),
                            wobbleHz: if (isDrop, { 5.2 }, { 2.8 }),
                            fmIndex: if (section == \dropB, { 3.0 }, {
                                if (isDrop, { 2.7 }, { 1.9 })
                            }),
                            cutoff: if (isDrop, { 4200 }, { 2600 }),
                            motionLoop: if (isDrop, { 0.52 }, { 0.20 }),
                            cycleBeats: cycleBeats,
                            phaseOffset: phaseOffset,
                            motionStart: motionStart,
                            motionEnd: motionEnd,
                            riseFrac: riseFrac
                        );
                        if ([1, 2, 5].includes(step) and: {
                            (bassMidi == (root + 12)) and: {
                                step != 2 or: { isDrop.not }
                            }
                        }) {
                            subMidi = root;
                        };
                    };

                    plan.add((
                        bar: bar, step: step, section: section,
                        kick: kick, snare: snare, hat: hat,
                        openHat: openHat, hatTick: hatTick,
                        impact: impact, rise: rise, roll: roll,
                        snareSample: if (isDrop, { cellSnares[cell] }, { \hardSnare }),
                        kickAmp: if (isDrop, { 0.52 }, {
                            if (isBuild, { 0.43 }, { 0.34 })
                        }),
                        snareAmp: if (isDrop, { 0.38 }, {
                            if (isBuild, { 0.31 }, { 0.23 })
                        }),
                        subMidi: subMidi,
                        subAmp: if (isDrop, { 0.22 }, { 0.15 }),
                        bass: bassEvent
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
                app[\section] = \intro;
                app[\bar] = 1;
                app[\masterNode].set(\amp, app[\masterTarget]);
                app[\clock] = TempoClock.new(app[\bpm] / 60);
                app[\routine] = Routine({
                    var playRun = app[\runId];
                    var sample = { |key, level = 0.15, hp = 20, rate = 1|
                        var buffer = app[\sampleBuffers][key];
                        if (buffer.notNil) {
                            Synth.tail(source, \bbSample, [
                                \out, out, \bufnum, buffer.bufnum,
                                \amp, level, \hp, hp, \rate, rate
                            ]);
                            true;
                        } {
                            false;
                        };
                    };
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
                            if (event[\step] == 0) {
                                app[\section] = event[\section];
                                app[\bar] = event[\bar] + 1;
                            };
                            if (event[\rise]) {
                                Synth.tail(source, \bbRise, [
                                    \out, out, \amp, 0.15,
                                    \dur, 14 / app[\clock].tempo
                                ]);
                            };
                            if (event[\impact]) {
                                Synth.tail(source, \bbImpact, [\out, out, \amp, 0.22]);
                                sample.value(\crash, 0.12, 180);
                            };
                            if (event[\kick]) {
                                kick.value(event[\kickAmp]);
                                if ([\dropA, \dropB].includes(event[\section])) {
                                    sample.value(\electroKick, 0.17, 170);
                                };
                            };
                            if (event[\snare]) {
                                snare.value(event[\snareAmp]);
                                sample.value(event[\snareSample],
                                    if ([\dropA, \dropB].includes(event[\section]), {
                                        0.21
                                    }, { 0.09 }), 110);
                                if (event[\section] == \dropB) {
                                    sample.value(\clap, 0.16, 240);
                                };
                            };
                            if (event[\hat]) {
                                if ([\dropA, \dropB].includes(event[\section]) and: {
                                    sample.value(\closedHat, 0.075, 1800).not
                                }) {
                                    hat.value(0.08);
                                };
                                if ([\dropA, \dropB].includes(event[\section]).not) {
                                    hat.value(0.08);
                                };
                            };
                            if (event[\openHat]) {
                                if (sample.value(\openHat, 0.10, 1300).not) {
                                    Synth.tail(source, \bbOpenHat, [\out, out, \amp, 0.07]);
                                };
                            };
                            if (event[\rise]) { sample.value(\swoosh, 0.11, 300) };
                            if ([7, 23].includes(event[\bar]) and: {
                                event[\step] == 5
                            }) { sample.value(\swoosh, 0.12, 300) };
                            if ([15, 31].includes(event[\bar]) and: {
                                event[\step] == 6
                            }) { sample.value(\glitch, 0.06, 500) };
                            if (event[\subMidi].notNil) {
                                Synth.tail(source, \bbSub, [
                                    \out, out, \freq, event[\subMidi].midicps,
                                    \amp, event[\subAmp], \decay, 0.16
                                ]);
                            };
                            if (bass.notNil) {
                                Synth.tail(source, bass[\synth], [
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
                                    \phaseOffset, bass[\phaseOffset],
                                    \motionLoop, bass[\motionLoop],
                                    \motionStart, bass[\motionStart], \motionPeak, 1,
                                    \motionEnd, bass[\motionEnd], \riseFrac, bass[\riseFrac]
                                ]);
                            };
                            if (event[\roll] > 0) {
                                var slice = 0.5 / (event[\roll] + 1);
                                event[\roll].do { |index|
                                    slice.wait;
                                    snare.value(0.11 + (index * 0.035));
                                };
                                slice.wait;
                            } {
                                if (event[\hatTick]) {
                                    0.25.wait;
                                    if (sample.value(\closedHat, 0.05, 1800).not) {
                                        hat.value(0.055);
                                    };
                                    0.25.wait;
                                } {
                                    0.5.wait;
                                };
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
