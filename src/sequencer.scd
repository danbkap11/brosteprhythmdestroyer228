{ |app|
    // A seed builds a theme and edits its two-bar rhythm, then develops both.
    app[\generatePlan] = {
        var config = app[\config];
        var plan = Array.new(config[\bars] * config[\stepsPerBar]);
        var builder = Routine({
            // [sixteenth onset, maximum length, local interval, character]
            var rhythmBank = [
                [ [[0,7,0,\growl],[10,2,0,\yoi],[13,2,7,\accent]],
                    [[0,2,0,\accent],[3,2,0,\yoi],[6,1,3,\talk],[10,3,0,\growl],[14,1,7,\rave]] ],
                [ [[0,3,0,\accent],[4,3,0,\growl],[10,5,0,\growl]],
                    [[1,2,0,\yoi],[4,3,0,\growl],[10,2,7,\accent],[13,2,0,\rave]] ],
                [ [[0,6,0,\growl],[10,2,3,\yoi],[13,1,0,\accent],[15,1,7,\yoi]],
                    [[0,2,0,\accent],[3,4,0,\growl],[10,4,0,\screech],[15,1,0,\rave]] ],
                [ [[0,2,0,\accent],[3,2,0,\yoi],[6,1,0,\accent],[10,5,0,\growl]],
                    [[0,7,0,\growl],[10,2,7,\yoi],[13,2,3,\rave]] ],
                [ [[0,7,0,\growl],[10,3,7,\screech],[14,1,0,\accent]],
                    [[0,2,0,\accent],[4,3,0,\talk],[10,2,0,\yoi],[13,2,7,\rave]] ]
            ];
            var hookGrids = [ [[0,3,6,11],[2,6,12]], [[0,4,10],[1,5,10,14]],
                [[0,3,7,12],[2,5,13]], [[0,5,10],[2,6,11,15]] ];
            var journeys = [ [0,0,8,8,3,3,0,0], [0,0,3,3,10,10,0,0],
                [0,0,10,10,8,8,0,0], [0,0,8,8,10,10,0,0] ];
            var minorScale = [0,3,5,7,10,12];
            var tonic;
            var theme;
            var hookGrid;
            var hook;
            var mainCell;
            var changedCell;
            var secondCell;
            var cellOrderA;
            var cellOrderB;
            var rootsA;
            var rootsB;
            var breakRoots;
            var voiceReply;
            var mutation;
            var mutateCell;
            var buildHook;

            thisThread.randSeed = app[\seed];
            tonic = [26,29,31].choose;
            // Root, fifth and minor third identify the motif; its continuation is seeded.
            theme = [0,7,3] ++ [5,10,12].scramble ++ [0];
            hookGrid = hookGrids.choose;
            hook = Array.fill(2, { |half|
                hookGrid[half].collect { |step,index|
                    var themeIndex = if (half == 0, { index }, { index + hookGrid[0].size });
                    [step, theme[themeIndex % theme.size], [2,3].choose]
                }
            });
            mutation = (0.35 + (app[\variation] * 0.55)).clip(0.35,0.9);
            // Edit selected answers, preserve the first call, and leave the snare pocket open.
            mutateCell = { |original,amount|
                original.collect { |sourceBar,half|
                    var result = sourceBar.collect { |item,index|
                        var note = item.copy;
                        if (index > 0 and: { 1.0.rand < amount }) {
                            note[0] = if (note[0] < 8, {
                                (note[0] + [-2,-1,1,2].choose).clip(2,6)
                            }, { (note[0] + [-2,-1,1,2].choose).clip(10,15) });
                            note[1] = (note[1] + [-1,1,2].choose).clip(1,7);
                            note[2] = [0,3,7,10].choose;
                        };
                        note
                    };
                    var seen = List.new;
                    var split;
                    if (1.0.rand < (amount * 0.48)) {
                        split = result.detect { |note| note[1] >= 5 };
                        if (split.notNil) {
                            var secondOnset = split[0] + [3,4].choose;
                            if (secondOnset < if (split[0] < 8, { 7 }, { 16 })) {
                                split[1] = 2;
                                result = result.add([secondOnset,2,7,\yoi]);
                            };
                        };
                    };
                    if (1.0.rand < (amount * 0.3)) {
                        // A purposeful late rest, never removal of the cell's main call.
                        result = result.select { |note,index| (index == 0) or: { note[0] < 13 } };
                    };
                    result = result.sort { |left,right| left[0] < right[0] };
                    result = result.select { |note|
                        var fresh = seen.includes(note[0]).not;
                        if (fresh) { seen.add(note[0]) };
                        fresh
                    };
                    result.do { |note,index|
                        var next = if (index < (result.size - 1), {
                            result[index + 1][0]
                        }, { 16 });
                        var pocketEnd = if (note[0] < 8, { 8 }, { 16 });
                        note[1] = note[1].min(next - note[0]).min(pocketEnd - note[0]).max(1);
                    };
                    result
                }
            };
            mainCell = mutateCell.value(rhythmBank.choose, mutation);
            changedCell = mutateCell.value(mainCell, mutation * 0.65);
            secondCell = mutateCell.value(rhythmBank.choose, mutation);
            // Repetition introduces identity; one edited repetition supplies contrast.
            cellOrderA = [mainCell,mainCell,changedCell,mainCell];
            cellOrderB = [secondCell,changedCell,secondCell,mainCell];
            rootsA = journeys.choose;
            rootsB = journeys.choose;
            breakRoots = [0,rootsA[2],rootsA[4],0];
            voiceReply = [\bbYoi,\bbTalking].choose;

            config[\bars].do { |bar|
                var section;
                var sectionBar;
                var buildLength = 2;
                var isBuild;
                var isDrop;
                var isFinalBuild;
                var root = tonic;
                var chordOffset = 0;
                var chordMajor = false;
                var notes = [];
                var hookNotes = [];
                var phraseEnd;
                var kickSteps = [];
                var hatGhosts;
                var fillSteps;
                var sparkSteps = [];
                var percSteps = [];
                var padMidi;
                var fillSample;
                var cellIndex = 0;
                var sectionGain;

                section = if (bar < 2, { \intro }, {
                    if (bar < 4, { \build }, {
                        if (bar < 12, { \dropA }, {
                            if (bar < 16, { \breakdown }, {
                                if (bar < 20, { \build }, { \dropB });
                            });
                        });
                    });
                });
                sectionBar = switch(section,
                    \intro,{bar}, \build,{if (bar < 4,{bar - 2},{bar - 16})},
                    \dropA,{bar - 4}, \breakdown,{bar - 12}, \dropB,{bar - 20}
                );
                if (isBuild = section == \build) { buildLength = if (bar < 4,{2},{4}) };
                isDrop = [\dropA,\dropB].includes(section);
                isFinalBuild = isBuild and: { sectionBar == (buildLength - 1) };
                phraseEnd = isDrop and: { ((sectionBar + 1) % 4) == 0 };
                if (isDrop) {
                    cellIndex = sectionBar.div(2);
                    notes = if (section == \dropA, {
                        cellOrderA[cellIndex][sectionBar % 2]
                    }, { cellOrderB[cellIndex][sectionBar % 2] });
                    chordOffset = if (section == \dropA,{rootsA[sectionBar]},{rootsB[sectionBar]});
                    kickSteps = [0,[5,6,10,11,14].choose];
                    if ((sectionBar % 2) == 0 and: { 1.0.rand > (0.45 + (app[\density] * 0.4)) }) {
                        kickSteps = [0];
                    };
                    if (app[\density] > 0.8 and: { 1.0.rand < app[\variation] }) {
                        kickSteps = (kickSteps ++ [[3,12].choose]).sort;
                    };
                } {
                    if (section == \breakdown) { chordOffset = breakRoots[sectionBar] };
                    if (isBuild and: { buildLength == 4 }) {
                        chordOffset = [breakRoots[2],breakRoots[3],0,0][sectionBar];
                    };
                    hookNotes = hook[sectionBar % 2];
                    if (section == \breakdown and: { sectionBar == 1 }) {
                        // Tonal inversion inside the same pentatonic collection, lower register.
                        hookNotes = hookNotes.collect { |item|
                            [item[0], minorScale[5 - minorScale.indexOf(item[1])], item[2]]
                        };
                    };
                    if (section == \breakdown and: { sectionBar == 2 }) { hookNotes = [] };
                    if (section == \breakdown and: { sectionBar == 3 }) {
                        hookNotes = hook[0].select { |item| item[0] < 8 };
                    };
                    if (section == \intro) { kickSteps = if (sectionBar == 1,{[0]},{[]}) };
                    if (section == \breakdown and: { sectionBar == 3 }) { kickSteps = [0,10] };
                    if (isBuild) {
                        kickSteps = if (isFinalBuild,{[0,4]}, {
                            if (sectionBar < 2,{[0]},{[0,6]})
                        });
                    };
                };
                chordMajor = chordOffset != 0;
                root = tonic + chordOffset;
                while { root > 34 } { root = root - 12 };
                while { root < 24 } { root = root + 12 };
                padMidi = root + 36;
                hatGhosts = [1,3,5,7,9,11,13,15].select { 1.0.rand < (app[\density] * 0.22) };
                fillSteps = [[12,14,15],[13,15],[12,13,15]].choose;
                fillSample = [\tomHigh,\tomMid,\glitch].choose;
                if (section == \breakdown) {
                    sparkSteps = if (sectionBar == 2,{[1,5,9,13]}, {
                        if (sectionBar >= 1,{[5,13]},{[13]})
                    });
                    percSteps = if (sectionBar >= 2,{[3,11,15]},{[11]});
                };
                if (isBuild) {
                    sparkSteps = if (isFinalBuild,{[1,5]},{[1,5,9,13]});
                    percSteps = if (isFinalBuild,{[3,7]},{[3,11]});
                };
                if (isDrop) {
                    sparkSteps = [1,5,9,13].select { 1.0.rand < (0.2 + (app[\variation] * 0.28)) };
                    percSteps = [3,7,11,15].select { 1.0.rand < (0.18 + (app[\density] * 0.17)) };
                };
                sectionGain = if (isDrop,{1.0},{
                    if (isBuild,{(0.48 + (sectionBar * (0.10 / (buildLength - 1)))).clip(0.48,0.58)}, {
                        if (section == \breakdown,{[0.58,0.62,0.55,0.63][sectionBar]},{0.58})
                    })
                });

                config[\stepsPerBar].do { |step|
                    var gap = isFinalBuild and: { step >= 12 };
                    var note = notes.detect { |item| item[0] == step };
                    var hookNote = hookNotes.detect { |item| item[0] == step };
                    var kick = kickSteps.includes(step);
                    var snare = false;
                    var snareRoll = false;
                    var hat = false;
                    var openHat = false;
                    var bass = nil;
                    var lead = nil;
                    var pad = nil;
                    var spark = nil;
                    var perc = nil;
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
                    var nextKick;
                    var nextBass;
                    var localIntervals = if (chordMajor,{[0,4,7,12]},{[0,3,7,10]});

                    if (section == \intro) {
                        snare = (step == 8) and: { sectionBar == 1 };
                        hat = [0,4,8,12].includes(step);
                        if (sectionBar == 1 and: { step == 10 }) { note = [10,3,0,\talk] };
                    };
                    if (section == \breakdown) {
                        // Release -> harmonic answer -> quiet arp -> rhythmic pickup.
                        hat = if (sectionBar < 2,{[2,10].includes(step)}, {
                            if (sectionBar == 2,{[2,6,10,14].includes(step)},{(step % 2) == 0})
                        });
                        hatAmp = [0.022,0.025,0.035,0.043][sectionBar];
                        snare = (sectionBar == 3) and: { step == 8 };
                        snareAmp = 0.16;
                        if (sectionBar == 3 and: { step == 12 }) { note = [12,3,0,\talk] };
                    };
                    if (isBuild) {
                        snare = if (isFinalBuild, {
                            [0,4,6,8,9,10,11].includes(step)
                        }, {
                            if (sectionBar < (buildLength - 2), {
                                [4,12].includes(step)
                            }, { [4,8,12,14].includes(step) })
                        });
                        snareRoll = snare;
                        snareAmp = if (isFinalBuild,{
                            (0.065 + (step * 0.011)).clip(0.065,0.19)
                        },{0.08 + (sectionBar * 0.015) + (step * 0.002)});
                        hat = (step % 2) == 0;
                        if (isFinalBuild and: { step >= 8 }) { hookNote = nil };
                    };
                    if (isDrop) {
                        snare = step == 8;
                        snareAmp = 0.30;
                        hat = [2,6,10,14].includes(step) or: {
                            ((step % 2) == 0) and: { 1.0.rand < (0.2 + (app[\density] * 0.5)) }
                        } or: { hatGhosts.includes(step) };
                        hatAmp = if ([2,6,10,14].includes(step),{0.069},{0.035});
                        openHat = (step == 14) and: { (sectionBar % 2) == 0 };
                        if (openHat) { hat = false };
                        if (step == 7 and: { app[\density] > 0.65 } and: {
                            1.0.rand < (app[\variation] * 0.35)
                        }) { snare = true; snareRoll = true; snareAmp = 0.07 };
                        if (phraseEnd and: { fillSteps.includes(step) }) {
                            note = nil; hat = false; openHat = false;
                            tom = if (step == 15,{\tomLow},{fillSample});
                            if (step == 15) { snare = true; snareAmp = 0.13; snareRoll = true };
                        };
                    };
                    if (hookNote.notNil) {
                        lead = (
                            midi: tonic + if (section == \breakdown and: { sectionBar == 1 },{24},{36}) + hookNote[1],
                            durBeats: if (section == \breakdown, {
                                [0.8,1.3,1.8].choose
                            },{hookNote[2] * config[\stepBeats] * 0.82}),
                            amp: if (section == \breakdown,{0.105},{if (isBuild,{0.12},{0.13})}),
                            tone: if (section == \breakdown,{0.24},{if (isBuild,{0.42},{0.55})}),
                            width: if (section == \breakdown,{0.35},{0.24})
                        );
                        // Extended break notes stop before the next motif attack.
                        nextBass = hookNotes.detect { |item| item[0] > step };
                        lead[\durBeats] = lead[\durBeats].min(
                            (((if (nextBass.notNil,{nextBass[0]},{16})) - step) * 0.25) * 0.96
                        );
                    };
                    if (note.notNil) {
                        role = note[3]; offset = note[2];
                        if (chordMajor and: { offset == 3 }) { offset = 4 };
                        if (role == \rave) {
                            lead = (
                                midi: tonic + 36 + theme[(cellIndex + step) % theme.size],
                                durBeats: note[1] * config[\stepBeats] * 0.78,
                                amp: 0.12, tone: 0.55, width: 0.24
                            );
                            subMidi = root;
                            subDurBeats = note[1] * config[\stepBeats] * 0.72;
                        } {
                            isLong = note[1] >= 4;
                            synth = switch(role,
                                \growl,{\bbGrowl}, \accent,{\bbAccent}, \yoi,{voiceReply},
                                \talk,{\bbTalking}, \screech,{\bbScreech}
                            );
                            if (role == \screech and: { section == \dropA } and: { sectionBar < 4 }) {
                                synth = \bbYoi;
                            };
                            if (isDrop and: { step > 8 } and: { 1.0.rand < (app[\variation] * 0.42) }) {
                                offset = localIntervals.choose;
                            };
                            bassDur = note[1] * config[\stepBeats] * if (isLong,{0.97},{0.78});
                            nextBass = notes.detect { |item| item[0] > step };
                            nextKick = kickSteps.detect { |onset| onset > step };
                            if (nextBass.notNil) { bassDur = bassDur.min(((nextBass[0] - step) * 0.25) - 0.02) };
                            if (nextKick.notNil) { bassDur = bassDur.min(((nextKick - step) * 0.25) - 0.025) };
                            bassDur = bassDur.max(0.08);
                            bass = (
                                synth: synth,
                                midi: root + 12 + offset + if (synth == \bbScreech,{12},{0}),
                                amp: if (isDrop,{if (step == 0,{0.30},{0.27})},{0.14}),
                                durBeats: bassDur, topLayer: false,
                                sample: if (isDrop and: { step == notes[0][0] } and: {
                                    (sectionBar % 4) == 0
                                },{if (isLong,{\growlyCall},{\growlHit})},{nil}),
                                sampleRoot: if (isLong,{41},{40}),
                                wobbleHz: 4, fmIndex: 3, cutoff: if (isLong,{5600},{7200}),
                                motionLoop: if (isLong,{0.92},{0.32}),
                                cycleBeats: if (isLong,{
                                    if (section == \dropB,{[0.5,1.0].choose},{1.0})
                                },{0.5}),
                                phaseOffset: if (isLong,{0.12},{0.38}),
                                motionStart: 0.78, motionEnd: 0.08, riseFrac: if (isLong,{0.18},{0.08})
                            );
                            subMidi = root;
                            subDurBeats = bassDur * 0.94;
                        };
                    };
                    if (subMidi.notNil) {
                        nextKick = kickSteps.detect { |onset| onset > step };
                        subDurBeats = subDurBeats.min(
                            (((if (nextKick.notNil,{nextKick},{16})) - step) * 0.25 - 0.035).max(0.06)
                        );
                    };
                    // Each supporting lane has a register and a quiet, sparse purpose.
                    if (step == 0 and: {
                        (section == \breakdown) or: { isBuild and: { (sectionBar % 2) == 0 } } or: {
                            isDrop and: { (sectionBar % 4) == 0 }
                        }
                    }) {
                        pad = (
                            midi: padMidi, thirdSemis: if (chordMajor,{4},{3}), fifthSemis: 7,
                            durBeats: if (section == \breakdown,{3.65},{if (isDrop,{6.6},{7.0})}),
                            amp: if (isDrop,{0.04},{if (isBuild,{0.055},{0.075})}),
                            tone: if (isDrop,{0.46},{0.28}), width: 0.42
                        );
                    };
                    if (sparkSteps.includes(step)) {
                        var sparkMidi = tonic + 48 + theme[(step.div(4) + sectionBar) % theme.size];
                        if (sparkMidi > 84) { sparkMidi = sparkMidi - 12 };
                        spark = (
                            midi: sparkMidi,
                            durBeats: if (section == \breakdown,{0.62},{0.32}),
                            amp: if (isDrop,{0.04},{if (section == \breakdown,{0.06},{0.047})}),
                            tone: if (section == \breakdown,{0.25},{0.48}), width: 0.38
                        );
                    };
                    if (percSteps.includes(step)) {
                        perc = (
                            sample: [\tomHigh,\tomMid,\glitch,\robot,\closedHat].choose,
                            amp: if (section == \breakdown,{0.035},{0.045}),
                            hp: [650,900,1200].choose, width: 0.3
                        );
                    };
                    if (gap) {
                        kick = false; snare = false; hat = false; openHat = false;
                        bass = nil; lead = nil; subMidi = nil; tom = nil;
                        pad = nil; spark = nil; perc = nil;
                    };
                    plan.add((
                        bar: bar, step: step, section: section, sectionGain: sectionGain,
                        kick: kick, snare: snare, snareRoll: snareRoll, hat: hat, hatAmp: hatAmp,
                        openHat: openHat, tom: tom,
                        cut: isFinalBuild and: { step == 12 },
                        impact: (step == 0) and: { [4,20].includes(bar) },
                        rise: (step == 0) and: { [2,18].includes(bar) },
                        reverseCrash: false, shout: isFinalBuild and: { step == 12 }, robot: false,
                        kickAmp: if (isDrop,{0.48},{0.32}), snareAmp: snareAmp,
                        snareDecay: if (snareRoll,{0.075},{0.23}),
                        snareSample: if (isDrop,{\brostepSnare},{\hardSnare}),
                        subMidi: subMidi, subAmp: if (isDrop,{0.18},{0.12}),
                        subDecay: 0.19, subDurBeats: subDurBeats,
                        bass: bass, lead: lead, pad: pad, spark: spark, perc: perc
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
                            if (event[\perc].notNil) {
                                var percussion = event[\perc];
                                sample.value(percussion[\sample], percussion[\amp],
                                    percussion[\hp], percussion[\width]);
                            };
                            if (event[\pad].notNil) {
                                var pad = event[\pad];
                                Synth.tail(source, \bbAtmosphere, [
                                    \out, out, \freq, pad[\midi].midicps,
                                    \thirdSemis, pad[\thirdSemis],
                                    \fifthSemis, pad[\fifthSemis],
                                    \amp, pad[\amp],
                                    \dur, pad[\durBeats] / app[\clock].tempo,
                                    \tone, pad[\tone], \width, pad[\width],
                                    \beatHz, app[\clock].tempo, \duckBus, duckOut
                                ]);
                            };
                            if (event[\spark].notNil) {
                                var spark = event[\spark];
                                Synth.tail(source, \bbSpark, [
                                    \out, out, \freq, spark[\midi].midicps,
                                    \amp, spark[\amp],
                                    \dur, spark[\durBeats] / app[\clock].tempo,
                                    \tone, spark[\tone], \width, spark[\width],
                                    \beatHz, app[\clock].tempo, \duckBus, duckOut
                                ]);
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
                                    \tone, event[\lead][\tone] ? 0.62,
                                    \width, event[\lead][\width] ? 0.32,
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
