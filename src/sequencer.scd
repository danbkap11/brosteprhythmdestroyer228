{ |app|
    // Resolve one original hook and two-bar bass cells once, before playback.
    app[\generatePlan] = {
        var config = app[\config];
        var plan = Array.new(config[\bars] * config[\stepsPerBar]);
        var builder = Routine({
            // [sixteenth onset, length in sixteenths, semitone reply, character]
            // Calls, answers and silence are composed together, never stacked.
            var rhythmBank = [
                [
                    [[0, 7, 0, \growl], [10, 2, 0, \yoi], [13, 2, 7, \accent]],
                    [[0, 2, 0, \accent], [3, 2, 0, \yoi], [6, 1, 3, \talk],
                        [10, 3, 0, \growl], [14, 1, 7, \rave]]
                ],
                [
                    [[0, 3, 0, \accent], [4, 3, 0, \growl], [10, 5, 0, \growl]],
                    [[1, 2, 0, \yoi], [4, 3, 0, \growl], [10, 2, 7, \accent],
                        [13, 2, 0, \rave]]
                ],
                [
                    [[0, 6, 0, \growl], [10, 2, 3, \yoi], [13, 1, 0, \accent],
                        [15, 1, 7, \yoi]],
                    [[0, 2, 0, \accent], [3, 4, 0, \growl],
                        [10, 4, 0, \screech], [15, 1, 0, \rave]]
                ],
                [
                    [[0, 2, 0, \accent], [3, 2, 0, \yoi], [6, 1, 0, \accent],
                        [10, 5, 0, \growl]],
                    [[0, 7, 0, \growl], [10, 2, 7, \yoi], [13, 2, 3, \rave]]
                ],
                [
                    [[0, 7, 0, \growl], [10, 3, 7, \screech], [14, 1, 0, \accent]],
                    [[0, 2, 0, \accent], [4, 3, 0, \talk], [10, 2, 0, \yoi],
                        [13, 2, 7, \rave]]
                ],
                [
                    [[0, 3, 0, \growl], [5, 2, 0, \accent], [10, 2, 3, \yoi],
                        [13, 2, 0, \growl]],
                    [[0, 7, 0, \growl], [10, 2, 7, \accent], [13, 2, 0, \rave]]
                ]
            ];
            // Sparse pentatonic rave calls: an original motif, not a song quote.
            var hooks = [
                [[[0, 0, 2], [3, 7, 2], [6, 3, 2], [11, 0, 2]],
                    [[2, 10, 2], [6, 7, 3], [12, 0, 3]]],
                [[[0, 0, 3], [5, 3, 2], [10, 7, 3]],
                    [[0, 10, 2], [3, 7, 2], [6, 3, 2], [12, 0, 3]]],
                [[[0, 7, 2], [3, 0, 2], [6, 3, 3], [12, 0, 2]],
                    [[2, 7, 2], [5, 10, 2], [10, 7, 2], [14, 0, 1]]]
            ];
            var tonic;
            var hook;
            var mainCell;
            var changeCell;
            var secondCell;
            var cellOrderA;
            var cellOrderB;
            var kickReply;
            var voiceReply;
            var dropRootsA = [0, 0, 0, 0, -2, -2, 0, 0];
            var dropRootsB = [0, 0, 3, 3, -2, -2, 0, 0];

            thisThread.randSeed = app[\seed];
            tonic = [26, 29, 31].choose;
            hook = hooks.choose;
            mainCell = rhythmBank.size.rand;
            changeCell = (mainCell + 1 + (rhythmBank.size - 1).rand) % rhythmBank.size;
            secondCell = (mainCell + 2 + 3.rand) % rhythmBank.size;
            cellOrderA = [mainCell, mainCell, changeCell, mainCell];
            cellOrderB = [secondCell, mainCell, secondCell, changeCell];
            kickReply = Array.fill(8, { [5, 6, 11, 14].choose });
            voiceReply = [\bbYoi, \bbTalking].choose;

            config[\bars].do { |bar|
                var section;
                var sectionBar;
                var isBuild;
                var isDrop;
                var isFinalBuild;
                var root = tonic;
                var cell = 0;
                var notes = [];
                var hookNotes = [];
                var phraseEnd;

                section = if (bar < 2, { \intro }, {
                    if (bar < 4, { \build }, {
                        if (bar < 12, { \dropA }, {
                            if (bar < 14, { \breakdown }, {
                                if (bar < 16, { \build }, { \dropB });
                            });
                        });
                    });
                });
                sectionBar = switch(section,
                    \intro, { bar }, \build, { if (bar < 4, { bar - 2 }, { bar - 14 }) },
                    \dropA, { bar - 4 }, \breakdown, { bar - 12 }, \dropB, { bar - 16 }
                );
                isBuild = section == \build;
                isDrop = [\dropA, \dropB].includes(section);
                isFinalBuild = isBuild and: { sectionBar == 1 };
                phraseEnd = isDrop and: { ((sectionBar + 1) % 4) == 0 };
                if (isDrop) {
                    cell = sectionBar.div(2) + if (section == \dropB, { 4 }, { 0 });
                    notes = rhythmBank[if (section == \dropA, {
                        cellOrderA[sectionBar.div(2)]
                    }, { cellOrderB[sectionBar.div(2)] })][sectionBar % 2];
                    root = tonic + if (section == \dropA, {
                        dropRootsA[sectionBar]
                    }, { dropRootsB[sectionBar] });
                } {
                    hookNotes = hook[sectionBar % 2];
                };

                config[\stepsPerBar].do { |step|
                    var gap = isFinalBuild and: { step >= 12 };
                    var note = notes.detect { |item| item[0] == step };
                    var hookNote = hookNotes.detect { |item| item[0] == step };
                    var kick = false;
                    var snare = false;
                    var snareRoll = false;
                    var hat = false;
                    var openHat = false;
                    var bass = nil;
                    var lead = nil;
                    var subMidi = nil;
                    var subDurBeats = 0.25;
                    var tom = nil;
                    var hatAmp = 0.045;
                    var snareAmp = 0.23;
                    var bassDur;
                    var role;
                    var synth;
                    var offset;
                    var isLong;
                    var nextKickStep;

                    if (section == \intro) {
                        kick = (step == 0) and: { sectionBar == 1 };
                        snare = (step == 8) and: { sectionBar == 1 };
                        hat = [0, 4, 8, 12].includes(step);
                        if (sectionBar == 1 and: { step == 10 }) {
                            note = [10, 3, 0, \talk];
                        };
                    };
                    if (section == \breakdown) {
                        hat = [0, 8].includes(step);
                        // Leave the break open, with one low swell answering the hook.
                        if (sectionBar == 1 and: { step == 10 }) {
                            note = [10, 4, 0, \growl];
                        };
                    };
                    if (isBuild) {
                        kick = if (isFinalBuild, {
                            [0, 4].includes(step)
                        }, { [0, 6].includes(step) });
                        snare = if (isFinalBuild, {
                            [0, 4, 6, 8, 9, 10, 11].includes(step)
                        }, { [4, 8, 12, 14].includes(step) });
                        snareRoll = snare;
                        snareAmp = if (isFinalBuild, {
                            (0.065 + (step * 0.011)).clip(0.065, 0.19)
                        }, { 0.10 + (step * 0.003) });
                        hat = (step % 2) == 0;
                        // Final build leaves only drums/riser before the vocal.
                        if (isFinalBuild and: { step >= 8 }) { hookNote = nil };
                    };
                    if (isDrop) {
                        kick = step == 0 or: {
                            (step == kickReply[cell]) and: {
                                ((sectionBar % 2) == 1) or: {
                                    1.0.rand < (0.3 + (app[\density] * 0.5))
                                }
                            }
                        };
                        snare = step == 8;
                        snareAmp = 0.30;
                        // Backbeat breathes; hats accent offbeats, with seeded ghosts.
                        hat = [2, 6, 10, 14].includes(step) or: {
                            ((step % 2) == 0) and: {
                                1.0.rand < (0.2 + (app[\density] * 0.5))
                            }
                        };
                        if ((step % 2) == 1) {
                            hat = 1.0.rand < (app[\density] * 0.23);
                        };
                        hatAmp = if ([2, 6, 10, 14].includes(step), { 0.069 }, { 0.035 });
                        openHat = (step == 14) and: { (sectionBar % 2) == 0 };
                        if (openHat) { hat = false };
                        if (phraseEnd and: { step >= 14 }) {
                            // A brief turn-around, not four layers filling every gap.
                            note = nil;
                            hat = false;
                            openHat = false;
                            tom = if (step == 14, { \tomMid }, { \tomLow });
                            if (step == 15) { snare = true; snareAmp = 0.13; snareRoll = true };
                        };
                        if (note.notNil and: { step > 12 } and: {
                            note[3] != \rave and: {
                                1.0.rand > (0.65 + (app[\density] * 0.35))
                            }
                        }) { note = nil };
                    };
                    if (hookNote.notNil) {
                        lead = (
                            midi: tonic + 36 + hookNote[1],
                            durBeats: hookNote[2] * config[\stepBeats] * 0.76,
                            amp: if (section == \breakdown, { 0.10 }, {
                                if (isBuild, { 0.12 }, { 0.13 })
                            })
                        );
                    };
                    if (note.notNil) {
                        role = note[3];
                        offset = note[2];
                        // The hook's answer has its own space instead of masking a bass note.
                        if (role == \rave) {
                            lead = (
                                midi: root + 36 + offset,
                                durBeats: note[1] * config[\stepBeats] * 0.78,
                                amp: 0.12
                            );
                            subMidi = root;
                            subDurBeats = note[1] * config[\stepBeats] * 0.72;
                        } {
                            isLong = note[1] >= 4;
                            synth = switch(role,
                                \growl, { \bbGrowl }, \accent, { \bbAccent },
                                \yoi, { voiceReply }, \talk, { \bbTalking },
                                \screech, { \bbScreech }
                            );
                            if (role == \screech and: { section == \dropA } and: {
                                sectionBar < 4
                            }) { synth = \bbYoi };
                            if (isDrop and: { step > 8 } and: {
                                1.0.rand < (app[\variation] * 0.32)
                            }) { offset = [0, 3, 7, 10].choose };
                            bassDur = note[1] * config[\stepBeats] *
                                if (isLong, { 0.97 }, { 0.78 });
                            bass = (
                                synth: synth,
                                midi: root + 12 + offset + if (synth == \bbScreech, { 12 }, { 0 }),
                                amp: if (isDrop, {
                                    if (step == 0, { 0.30 }, { 0.27 })
                                }, { 0.14 }),
                                durBeats: bassDur,
                                // The core voice owns its harmonics; layer only phrase accents.
                                topLayer: false,
                                sample: if (isDrop and: { step == notes[0][0] } and: {
                                    (sectionBar % 4) == 0
                                }, {
                                    if (isLong, { \growlyCall }, { \growlHit })
                                }, { nil }),
                                sampleRoot: if (isLong, { 41 }, { 40 }),
                                wobbleHz: 4, fmIndex: 3,
                                cutoff: if (isLong, { 5600 }, { 7200 }),
                                motionLoop: if (isLong, { 0.92 }, { 0.32 }),
                                cycleBeats: if (isLong, {
                                    if (section == \dropB, { 0.5 }, { 1.0 })
                                }, { 0.5 }),
                                phaseOffset: if (isLong, { 0.12 }, { 0.38 }),
                                motionStart: 0.78, motionEnd: 0.08,
                                riseFrac: if (isLong, { 0.18 }, { 0.08 })
                            );
                            // The sub holds the harmonic root, even under upper-register replies.
                            subMidi = root;
                            subDurBeats = bassDur * 0.94;
                        };
                    };
                    if (subMidi.notNil) {
                        // End clean low voices before the next known kick or section gap.
                        nextKickStep = if (isDrop and: { kickReply[cell] > step }, {
                            kickReply[cell]
                        }, { 16 });
                        subDurBeats = subDurBeats.min(
                            ((nextKickStep - step) * config[\stepBeats] - 0.035).max(0.06)
                        );
                    };
                    if (gap) {
                        kick = false; snare = false; hat = false; openHat = false;
                        bass = nil; lead = nil; subMidi = nil; tom = nil;
                    };
                    plan.add((
                        bar: bar, step: step, section: section,
                        sectionGain: if (isDrop, { 1.0 }, {
                            if (isBuild, {
                                if (isFinalBuild, { 0.58 }, { 0.50 })
                            }, { if (section == \intro, { 0.58 }, { 0.42 }) })
                        }),
                        kick: kick, snare: snare, snareRoll: snareRoll,
                        hat: hat, hatAmp: hatAmp, openHat: openHat, tom: tom,
                        cut: isFinalBuild and: { step == 12 },
                        impact: (step == 0) and: { [4, 16].includes(bar) },
                        rise: (step == 0) and: { [2, 14].includes(bar) },
                        reverseCrash: false,
                        // Every drop now receives the same clear vocal cue.
                        shout: isFinalBuild and: { step == 12 },
                        robot: false,
                        kickAmp: if (isDrop, { 0.48 }, { 0.32 }),
                        snareAmp: snareAmp,
                        snareDecay: if (snareRoll, { 0.075 }, { 0.23 }),
                        snareSample: if (isDrop, { \brostepSnare }, { \hardSnare }),
                        subMidi: subMidi,
                        subAmp: if (isDrop, { 0.18 }, { 0.12 }),
                        subDecay: 0.19,
                        subDurBeats: subDurBeats,
                        bass: bass, lead: lead
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
                var duckOut = app[\duckBus].index;

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
                    var snare = { |level = 0.28, decay = 0.23|
                        Synth.tail(source, \bbSnare, [
                            \out, out, \amp, level, \decay, decay
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
                            // One timestamp per grid point keeps layered attacks together.
                            app[\server].makeBundle(app[\server].latency, {
                            if (event[\step] == 0) {
                                app[\masterNode].set(\sectionGain, event[\sectionGain]);
                            };
                            if (event[\cut]) { source.freeAll };
                            if (event[\rise]) {
                                Synth.tail(source, \bbRise, [
                                    \out, out, \amp, 0.16,
                                    \dur, 7 / app[\clock].tempo
                                ]);
                            };
                            if (event[\reverseCrash]) {
                                sample.value(\reverseCrash, 0.19, 180, 0.45);
                            };
                            if (event[\shout]) {
                                if (sample.value(\vocalShout, 0.29, 100, 0.16).not) {
                                    Synth.tail(source, \bbShout, [
                                        \out, out, \amp, 0.28,
                                        \dur, 0.84 / app[\clock].tempo
                                    ]);
                                };
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
                                app[\duckNode].tryPerform(\set, \t_kick, 1);
                                kick.value(event[\kickAmp]);
                                if (isDrop) {
                                    if (sample.value(\attackKick, 0.24, 145).not) {
                                        sample.value(\electroKick, 0.17, 170);
                                    };
                                };
                            };
                            if (event[\snare]) {
                                snare.value(event[\snareAmp], event[\snareDecay]);
                                if (sample.value(event[\snareSample],
                                    if (isDrop and: { event[\snareRoll].not }, {
                                        0.22
                                    }, { 0.055 }),
                                    if (event[\snareRoll], { 750 }, {
                                        if (isDrop, { 95 }, { 135 })
                                    })).not) {
                                    if (isDrop) {
                                        if (sample.value(\beefySnare, 0.22, 135).not) {
                                            sample.value(\snareSlam, 0.20, 135);
                                        };
                                    };
                                };
                                if (isDrop and: { event[\snareRoll].not }) {
                                    sample.value(\hardClap, 0.08, 700, 0.28);
                                };
                            };
                            if (event[\hat]) {
                                var playedHat = false;
                                if (isDrop) {
                                    if ((event[\step] % 2) == 1) {
                                        playedHat = sample.value(
                                            \tightHat, event[\hatAmp], 1500, 0.30);
                                    };
                                    if (playedHat.not) {
                                        if (sample.value(\closedHat, event[\hatAmp], 1500, 0.32).not) {
                                            hat.value(event[\hatAmp]);
                                        };
                                    };
                                } {
                                    hat.value(event[\hatAmp]);
                                };
                            };
                            if (event[\openHat]) {
                                var playedOpenHat = false;
                                if ((event[\bar] % 4) == 0) {
                                    playedOpenHat = sample.value(
                                        \longOpenHat, 0.065, 1500, 0.28);
                                };
                                if (playedOpenHat.not) {
                                    if (sample.value(\openHat, 0.09, 1300, 0.40).not) {
                                        Synth.tail(source, \bbOpenHat, [
                                            \out, out, \amp, 0.07
                                        ]);
                                    };
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
                                    \amp, event[\subAmp], \decay, event[\subDecay],
                                    \dur, event[\subDurBeats] / app[\clock].tempo,
                                    \duckBus, duckOut
                                ]);
                            };
                            if (event[\lead].notNil) {
                                Synth.tail(source, \bbRave, [
                                    \out, out, \freq, event[\lead][\midi].midicps,
                                    \amp, event[\lead][\amp],
                                    \dur, event[\lead][\durBeats] / app[\clock].tempo,
                                    \duckBus, duckOut
                                ]);
                            };
                            if (bass.notNil) {
                                var bassBuffer = if (bass[\sample].notNil, {
                                    app[\sampleBuffers][bass[\sample]]
                                }, { nil });
                                var bassSynth = if (bassBuffer.notNil, {
                                    \bbBassSample
                                }, { bass[\synth] });
                                var bassArgs = [
                                    \out, out, \freq, bass[\midi].midicps,
                                    \amp, bass[\amp],
                                    \duckBus, duckOut,
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
                                ];
                                if (bassBuffer.notNil) {
                                    bassArgs = bassArgs ++ [
                                        \bufnum, bassBuffer.bufnum,
                                        \rootFreq, bass[\sampleRoot].midicps
                                    ];
                                };
                                Synth.tail(source, bassSynth, bassArgs);
                                if (bass[\topLayer]) {
                                    Synth.tail(source, \bbBassTop, [
                                        \out, out, \freq, bass[\midi].midicps,
                                        \dur, bass[\durBeats] / app[\clock].tempo,
                                        \amp, 0.095, \duckBus, duckOut
                                    ]);
                                };
                            };
                            });
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
            // Drain already timestamped note bundles before freeing source nodes.
            SystemClock.sched(app[\server].latency + 0.075, {
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
