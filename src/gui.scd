{ |app|
    app[\openGui] = {
        if (app[\guiOpen] == true) {
            app[\window].front;
        } {
            var window = Window(
                "HIJAZ//BASS",
                Rect(120, 120, 700, 590)
            );
            var playButton = Button(window, Rect(20, 18, 100, 32))
                .states_([["Play"]]);
            var stopButton = Button(window, Rect(130, 18, 100, 32))
                .states_([["Stop"]]);
            var statusView = StaticText(window, Rect(250, 20, 430, 28))
                .string_("Preparing SuperCollider...");
            var statusTask;
            var addSlider;
            var statusText;
            var bpmSlider;
            var masterSlider;
            var growlSlider;
            var movementSlider;
            var aggressionSlider;
            var toneSlider;
            var textureSlider;
            var widthSlider;
            var defaultsButton;
            var seedField;
            var densitySlider;
            var variationSlider;
            var presetMenu;
            var generateButton;
            var newSeedButton;

            addSlider = { |label, y, initial, formatValue, mapValue, onChange|
                var control = Slider(window, Rect(175, y, 410, 24))
                    .value_(initial);
                var readout = StaticText(window, Rect(595, y, 75, 24))
                    .string_(formatValue.value(mapValue.value(initial)));

                StaticText(window, Rect(22, y, 150, 24)).string_(label);
                control.action_({ |view|
                    var value = mapValue.value(view.value);
                    readout.string_(formatValue.value(value));
                    onChange.value(value);
                });
                control;
            };

            statusText = {
                var snapshot = app[\status].value;
                var state = snapshot[\state];
                var label = state.asString;
                var sectionLabel;

                if (state == \booting) { label = "Preparing server"; };
                if (state == \ready) { label = "Ready"; };
                if (state == \playing) {
                    sectionLabel = switch(snapshot[\section],
                        \intro, { "Intro" },
                        \build, { "Build" },
                        \dropA, { "Drop A" },
                        \breakdown, { "Break" },
                        \dropB, { "Drop B" },
                        { "Loop" }
                    );
                    label = "Playing — " ++ sectionLabel ++
                        " · bar " ++ snapshot[\bar].asString;
                };
                if (state == \stopping) { label = "Stopping"; };
                if (state == \failed) {
                    label = "Error — check the SuperCollider Post Window";
                } {
                    if (snapshot[\message].notNil) {
                        label = label ++ " — " ++ snapshot[\message];
                    };
                };
                if (snapshot[\pendingBpm].notNil) {
                    label = label ++ " (tempo change at next bar)";
                };
                label;
            };

            bpmSlider = addSlider.value(
                "Tempo (BPM)", 72, 0.5,
                { |value| value.round(1).asInteger.asString },
                { |position| (120 + (position * 40)).round(1) },
                { |value| app[\setControl].value(\bpm, value) }
            );
            masterSlider = addSlider.value(
                "Master (dB)", 112, 1,
                { |value| value.round(0.1).asString },
                { |position| -24 + (position * 18) },
                { |value| app[\setControl].value(\masterDb, value) }
            );
            growlSlider = addSlider.value(
                "Growl", 168, app[\bassControls][\growl],
                { |value| value.round(0.01).asString },
                { |position| position },
                { |value| app[\setControl].value(\growl, value) }
            );
            movementSlider = addSlider.value(
                "Movement", 210, app[\bassControls][\movement],
                { |value| value.round(0.01).asString },
                { |position| position },
                { |value| app[\setControl].value(\movement, value) }
            );
            aggressionSlider = addSlider.value(
                "Aggression", 252, app[\bassControls][\aggression],
                { |value| value.round(0.01).asString },
                { |position| position },
                { |value| app[\setControl].value(\aggression, value) }
            );
            toneSlider = addSlider.value(
                "Tone", 294, app[\bassControls][\tone],
                { |value| value.round(0.01).asString },
                { |position| position },
                { |value| app[\setControl].value(\tone, value) }
            );
            textureSlider = addSlider.value(
                "Texture", 336, app[\bassControls][\texture],
                { |value| value.round(0.01).asString },
                { |position| position },
                { |value| app[\setControl].value(\texture, value) }
            );
            widthSlider = addSlider.value(
                "Width", 378, app[\bassControls][\width],
                { |value| value.round(0.01).asString },
                { |position| position },
                { |value| app[\setControl].value(\width, value) }
            );

            StaticText(window, Rect(22, 426, 100, 24)).string_("Seed");
            seedField = NumberBox(window, Rect(130, 422, 150, 30))
                .value_(app[\seed])
                .clipLo_(0)
                .clipHi_(2147483647)
                .decimals_(0);
            seedField.action_({ |view|
                app[\setControl].value(\seed, view.value.asInteger);
            });
            densitySlider = addSlider.value(
                "Density", 462, app[\density],
                { |value| value.round(0.01).asString },
                { |position| position },
                { |value| app[\setControl].value(\density, value) }
            );
            variationSlider = addSlider.value(
                "Variation", 498, app[\variation],
                { |value| value.round(0.01).asString },
                { |position| position },
                { |value| app[\setControl].value(\variation, value) }
            );
            StaticText(window, Rect(300, 426, 90, 24)).string_("Preset");
            presetMenu = PopUpMenu(window, Rect(390, 422, 185, 30))
                .items_(["Destroyer", "Reese Reply"])
                .value_(0);
            generateButton = Button(window, Rect(22, 542, 110, 30))
                .states_([["Generate"]]);
            newSeedButton = Button(window, Rect(142, 542, 110, 30))
                .states_([["New Seed"]]);

            defaultsButton = Button(window, Rect(262, 542, 110, 30))
                .states_([["Defaults"]]);
            StaticText(window, Rect(390, 542, 290, 30))
                .string_("Hijaz · 4/4 · 28-bar build/drop");

            playButton.action_({ app[\start].value });
            stopButton.action_({ app[\stop].value });
            presetMenu.action_({ |view|
                var presetName = if (view.value == 0, { \destroyer }, { \reeseReply });
                if (app[\selectPreset].value(presetName)) {
                    var controls = app[\bassControls];
                    growlSlider.valueAction_(controls[\growl]);
                    movementSlider.valueAction_(controls[\movement]);
                    aggressionSlider.valueAction_(controls[\aggression]);
                    toneSlider.valueAction_(controls[\tone]);
                    textureSlider.valueAction_(controls[\texture]);
                    widthSlider.valueAction_(controls[\width]);
                };
            });
            generateButton.action_({
                // Commit the displayed field before generating, even if the
                // user clicks Generate without pressing Return in NumberBox.
                app[\setControl].value(\seed, seedField.value.asInteger);
            });
            newSeedButton.action_({
                var seed = ((Main.elapsedTime * 1000000) % 2147483648.0).floor.asInteger;
                if (app[\setControl].value(\seed, seed)) {
                    seedField.value_(seed);
                };
            });
            defaultsButton.action_({
                growlSlider.valueAction_(0.78);
                movementSlider.valueAction_(0.72);
                aggressionSlider.valueAction_(0.70);
                toneSlider.valueAction_(0.58);
                textureSlider.valueAction_(0.40);
                widthSlider.valueAction_(0.12);
                bpmSlider.valueAction_(0.5);
                masterSlider.valueAction_(1);
                seedField.value_(app[\config][\seed]);
                app[\setControl].value(\seed, app[\config][\seed]);
                densitySlider.valueAction_(app[\config][\density]);
                variationSlider.valueAction_(app[\config][\variation]);
                presetMenu.value_(0);
                app[\selectPreset].value(\destroyer);
            });
            window.onClose_({
                app[\guiOpen] = false;
                statusTask.tryPerform(\stop);
                app[\shutdown].value;
                app[\window] = nil;
            });

            app[\window] = window;
            app[\guiOpen] = true;
            statusTask = Routine({
                while { app[\guiOpen] == true } {
                    var state;
                    app[\checkServer].value;
                    state = app[\state];
                    statusView.string_(statusText.value);
                    playButton.enabled_(state == \ready);
                    stopButton.enabled_(state == \playing);
                    seedField.enabled_(state == \ready);
                    densitySlider.enabled_(state == \ready);
                    variationSlider.enabled_(state == \ready);
                    presetMenu.enabled_(state == \ready);
                    generateButton.enabled_(state == \ready);
                    newSeedButton.enabled_(state == \ready);
                    defaultsButton.enabled_(state == \ready);
                    0.15.wait;
                };
            }).play(AppClock);
            window.front;
        };
    };
}
