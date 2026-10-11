{ |app|
    // The seed resolves the whole 24-bar event plan before playback.
    app[\generatePlan] = {
        var config = app[\config];
        var plan = Array.new(config[\bars] * config[\stepsPerBar]);
        var builder = Routine({
            var rootOrders = [
                [26, 26, 24, 24, 31, 31, 29, 29],
                [26, 26, 31, 31, 24, 24, 29, 29],
                [26, 26, 29, 29, 24, 24, 31, 31],
                [26, 26, 24, 24, 29, 29, 31, 31]
            ];
            var riffPairs = [
                [[2, 6, 10, 14], [2, 5, 10, 13]],
                [[2, 5, 11, 14], [2, 6, 10, 12, 14]],
                [[0, 3, 6, 10, 13], [2, 6, 11, 14]],
                [[2, 6, 9, 14], [0, 2, 10, 12, 15]],
                [[3, 6, 10, 14], [2, 5, 9, 13]]
            ];
            var introRiffs = [[2], [5], [10], [2, 12], [3]];
            var buildRiffs = [[2, 10], [3, 11], [2, 6, 10], [5, 10]];
            var rootA;
            var rootB;
            var introIndex;
            var buildIndex;
            var cellRiffs;
            var cellVoices;
            var cellReplies;
            var cellKicks;
            var cellHats;

            thisThread.randSeed = app[\seed];
            rootA = rootOrders.choose;
            rootB = rootOrders.choose;
            introIndex = introRiffs.size.rand;
            buildIndex = buildRiffs.size.rand;
            cellRiffs = Array.fill(8, { riffPairs.choose });
            cellVoices = Array.fill(8, { 3.rand });
            cellReplies = Array.fill(8, { [0, 0, 7, 12].choose });
            cellKicks = Array.fill(8, { [6, 10, 14].choose });
            cellHats = Array.fill(8, { 3.rand });

            config[\bars].do { |bar|
                var section;
                var sectionBar = 0;
                var isBuild;
                var isDrop;
                var cell = nil;
                var root = 26;
                var activeRiff = nil;

                section = if (bar < 2, { \intro }, {
                    if (bar < 4, { \build }, {
                        if (bar < 12, { \dropA }, {
                            if (bar < 14, { \breakdown }, {
                                if (bar < 16, { \build }, { \dropB });
                            });
                        });
                    });
                });
                isBuild = section == \build;
                isDrop = [\dropA, \dropB].includes(section);
                if (isBuild) {
                    sectionBar = if (bar < 4, { bar - 2 }, { bar - 14 });
                    activeRiff = buildRiffs[buildIndex];
                };
                if (section == \intro) {
                    activeRiff = introRiffs[(introIndex + bar) % introRiffs.size];
                };
                if (section == \breakdown) {
                    activeRiff = if ((bar % 2) == 0, { [10] }, { [5] });
                };
                if (isDrop) {
                    cell = if (section == \dropA, {
                        (bar - 4).div(2)
                    }, {
                        (bar - 16).div(2) + 4
                    });
                    activeRiff = cellRiffs[cell][bar % 2];
                    root = if (section == \dropA, {
                        rootA[bar - 4]
                    }, {
                        rootB[bar - 16]
                    });
                };

                config[\stepsPerBar].do { |step|
                    var groupIndex = step.div(4);
                    var groupStart = groupIndex * 4;
                    var cycleBeats = config[\grouping][groupIndex] *
                        config[\stepBeats];
                    var phaseOffset = ((step - groupStart) *
                        config[\stepBeats]) / cycleBeats;
                    var motionStart = [0.08, 0.68, 0.14, 0.78][groupIndex];
                    var motionEnd = [0.28, 0.12, 0.42, 0.06][groupIndex];
                    var riseFrac = [0.18, 0.42, 0.28, 0.64][groupIndex];
                    var accent = [1.0, 0.88, 1.06, 0.84][groupIndex];
                    var gap = isBuild and: {
                        sectionBar == 1 and: { step >= 14 }
                    };
                    var kick = false;
                    var snare = false;
                    var hat = false;
                    var openHat = false;
                    var bassHit = activeRiff.includes(step);
                    var subMidi = nil;
                    var subDecay = 0.17;
                    var bassEvent = nil;
                    var tom = nil;
                    var bassMidi;
                    var bassVoice = \bbGrowl;
                    var nextStep;
                    var gapSteps;
                    var durBeats;

                    if (section == \intro) {
                        kick = step == 0;
                        snare = step == 8;
                        hat = [0, 4, 8, 12].includes(step) or: {
                            ((introIndex % 2) == 1) and: {
                                [2, 10].includes(step)
                            }
                        };
                    };
                    if (isBuild) {
                        kick = [0, 6].includes(step);
                        snare = step == 8;
                        hat = (step % 2) == 0 or: {
                            1.0.rand < (0.05 + (app[\density] * 0.25))
                        };
                        if (sectionBar == 1) {
                            if ([12, 13].includes(step)) { snare = true };
                            if (step == 10) { tom = \tomHigh };
                            if (step == 12) { tom = \tomMid };
                            if (step == 13) { tom = \tomLow };
                        };
                    };
                    if (isDrop) {
                        kick = step == 0 or: {
                            (step == cellKicks[cell]) and: {
                                ((bar % 2) == 1) and: {
                                    1.0.rand < (0.40 + (app[\density] * 0.60))
                                }
                            }
                        };
                        snare = step == 8;
                        hat = (step % 2) == 0;
                        if ((step % 2) == 1) {
                            hat = (cellHats[cell] > 0) and: {
                                1.0.rand < (app[\density] *
                                    if (cellHats[cell] == 2, { 0.62 }, { 0.32 }))
                            };
                        };
                        openHat = (step == 14) and: { (bar % 2) == 0 };
                        if (openHat) { hat = false };
                        if ([11, 23].includes(bar)) {
                            if (step == 12) { tom = \tomHigh };
                            if (step == 14) { tom = \tomMid };
                            if (step == 15) { tom = \tomLow };
                        };
                    };
                    if (section == \breakdown) {
                        kick = step == 0;
                        snare = step == 8;
                        hat = [0, 8, 12].includes(step);
                        bassVoice = \bbTalking;
                    };
                    if (gap) {
                        kick = false;
                        snare = false;
                        hat = false;
                        openHat = false;
                        bassHit = false;
                        tom = nil;
                    };

                    if (bassHit) {
                        var position = activeRiff.indexOf(step);
                        nextStep = if (position < (activeRiff.size - 1), {
                            activeRiff[position + 1]
                        }, {
                            config[\stepsPerBar]
                        });
                        gapSteps = nextStep - step;
                        durBeats = (gapSteps * config[\stepBeats] * 0.84)
                            .clip(0.17, 1.2);
                        bassMidi = root + 12;
                        if (isDrop and: { step >= 9 } and: {
                            1.0.rand < (0.20 + (app[\variation] * 0.65))
                        }) {
                            bassMidi = bassMidi + cellReplies[cell];
                        };
                        if (isDrop) {
                            bassVoice = switch(cellVoices[cell],
                                0, { if (step < 8, { \bbGrowl }, { \bbYoi }) },
                                1, { if (step < 8, { \bbYoi }, { \bbTalking }) },
                                2, { if (step < 8, { \bbTalking }, { \bbYoi }) }
                            );
                        };
                        bassEvent = (
                            synth: bassVoice,
                            midi: bassMidi,
                            amp: if (isDrop, { 0.27 }, {
                                if (isBuild, { 0.16 }, { 0.11 })
                            }) * accent,
                            durBeats: durBeats,
                            wobbleHz: if (isDrop, { 6.5 }, { 3.0 }),
                            fmIndex: if (isDrop, { 3.0 }, { 2.0 }),
                            cutoff: if (isDrop, { 6800 }, { 3000 }),
                            motionLoop: if (isDrop, { 0.58 }, { 0.28 }),
                            cycleBeats: cycleBeats,
                            phaseOffset: phaseOffset,
                            motionStart: motionStart,
                            motionEnd: motionEnd,
                            riseFrac: riseFrac
                        );
                        if ((bassMidi == (root + 12)) and: {
                            kick.not and: { step > 0 and: { step < 15 } }
                        }) {
                            subMidi = root;
                            subDecay = (durBeats / (config[\bpm] / 60) * 0.7)
                                .clip(0.12, 0.25);
                            // Leave the next sixteenth clear if this cell can
                            // place its extra kick there.
                            if (isDrop and: { (bar % 2) == 1 } and: {
                                cellKicks[cell] == (step + 1)
                            }) {
                                subMidi = nil;
                            };
                        };
                    };

                    plan.add((
                        bar: bar, step: step, section: section,
                        kick: kick, snare: snare, hat: hat,
                        openHat: openHat, tom: tom,
                        impact: (step == 0) and: {
                            [4, 8, 16, 20].includes(bar)
                        },
                        rise: (step == 0) and: { [2, 14].includes(bar) },
                        reverseCrash: (step == 0) and: {
                            [3, 15].includes(bar)
                        },
                        robot: (step == 12) and: {
                            [11, 23].includes(bar)
                        },
                        kickAmp: if (isDrop, { 0.52 }, {
                            if (isBuild, { 0.42 }, { 0.30 })
                        }),
                        snareAmp: if (isDrop, { 0.30 }, {
                            if (isBuild, {
                                if ([12, 13].includes(step), { 0.12 }, { 0.28 })
                            }, { 0.20 })
                        }),
                        snareSample: if (isDrop, { \snareSlam }, { \hardSnare }),
                        subMidi: subMidi,
                        subAmp: if (isDrop, { 0.20 }, { 0.12 }),
                        subDecay: subDecay,
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
                    var sample = { |key, level = 0.15, hp = 20, width = 0|
                        var buffer = app[\sampleBuffers][key];
                        if (buffer.notNil) {
                            Synth.tail(source, \bbSample, [
                                \out, out, \bufnum, buffer.bufnum,
                                \amp, level, \hp, hp, \width, width
                            ]);
                            true;
                        } {
                            false;
                        };
                    };
                    var kick = { |level = 0.43|
                        Synth.tail(source, \bbKick, [
                            \out, out, \amp, level, \decay, 0.20
                        ]);
                    };
                    var snare = { |level = 0.28|
                        Synth.tail(source, \bbSnare, [
                            \out, out, \amp, level
                        ]);
                    };
                    var hat = { |level = 0.07|
                        Synth.tail(source, \bbHat, [\out, out, \amp, level]);
                    };

                    while { playRun == app[\runId] } {
                        app[\plan].do { |event|
                            var bass = event[\bass];
                            var isDrop = [\dropA, \dropB].includes(event[\section]);
                            if (event[\step] == 0) {
                                app[\section] = event[\section];
                                app[\bar] = event[\bar] + 1;
                            };
                            if (event[\rise]) {
                                Synth.tail(source, \bbRise, [
                                    \out, out, \amp, 0.17,
                                    \dur, 8 / app[\clock].tempo
                                ]);
                                sample.value(\swoosh, 0.12, 300, 0.4);
                            };
                            if (event[\reverseCrash]) {
                                sample.value(\reverseCrash, 0.19, 180, 0.45);
                            };
                            if (event[\impact]) {
                                Synth.tail(source, \bbImpact, [
                                    \out, out, \amp, if ([4, 16].includes(event[\bar]), {
                                        0.24
                                    }, { 0.15 })
                                ]);
                                sample.value(\crash, 0.15, 200, 0.45);
                            };
                            if (event[\kick]) {
                                kick.value(event[\kickAmp]);
                                if (isDrop) {
                                    sample.value(\electroKick, 0.17, 170);
                                };
                            };
                            if (event[\snare]) {
                                snare.value(event[\snareAmp]);
                                sample.value(event[\snareSample],
                                    if (isDrop, { 0.25 }, { 0.08 }), 110);
                                if (event[\section] == \dropB) {
                                    sample.value(\clap, 0.16, 240);
                                };
                            };
                            if (event[\hat]) {
                                if (isDrop) {
                                    if (sample.value(\closedHat, 0.065, 1800, 0.32).not) {
                                        hat.value;
                                    };
                                } {
                                    hat.value;
                                };
                            };
                            if (event[\openHat]) {
                                if (sample.value(\openHat, 0.09, 1300, 0.40).not) {
                                    Synth.tail(source, \bbOpenHat, [
                                        \out, out, \amp, 0.07
                                    ]);
                                };
                            };
                            if (event[\tom].notNil) {
                                sample.value(event[\tom], 0.11, 90);
                            };
                            if (event[\robot]) {
                                sample.value(\robot, 0.07, 420, 0.38);
                            };
                            if (event[\subMidi].notNil) {
                                Synth.tail(source, \bbSub, [
                                    \out, out, \freq, event[\subMidi].midicps,
                                    \amp, event[\subAmp], \decay, event[\subDecay]
                                ]);
                            };
                            if (bass.notNil) {
                                Synth.tail(source, bass[\synth], [
                                    \out, out, \freq, bass[\midi].midicps,
                                    \amp, bass[\amp],
                                    \dur, bass[\durBeats] / app[\clock].tempo,
                                    \wobbleHz, bass[\wobbleHz],
                                    \fmIndex, bass[\fmIndex],
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
                                    \motionStart, bass[\motionStart],
                                    \motionPeak, 1,
                                    \motionEnd, bass[\motionEnd],
                                    \riseFrac, bass[\riseFrac]
                                ]);
                            };
                            app[\config][\stepBeats].wait;
                            if ((event[\step] == (app[\config][\stepsPerBar] - 1)) and: {
                                app[\pendingBpm].notNil
                            }) {
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
                    " BPM, 4/4, " ++ app[\config][\bars] ++
                    " bars per phrase.").postln;
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
