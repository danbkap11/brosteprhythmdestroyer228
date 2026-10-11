{ |app|
    app[\bassControls] = app[\config][\bassControls].copy;
    app[\bpm] = app[\config][\bpm];
    app[\masterDb] = app[\config][\masterDb];
    app[\pendingBpm] = nil;
    app[\message] = nil;
    app[\seed] = app[\config][\seed];
    app[\density] = app[\config][\density];
    app[\variation] = app[\config][\variation];
    app[\presetName] = \destroyer;

    app[\setControl] = { |key, value|
        var validNumber = value.isKindOf(Number);
        var accepted = false;

        if (validNumber) {
            switch(key,
                \bpm, {
                    if ((value >= 120) and: { value <= 160 }) {
                        if (app[\state] == \playing) {
                            app[\pendingBpm] = value;
                        } {
                            app[\bpm] = value;
                            app[\pendingBpm] = nil;
                        };
                        accepted = true;
                    };
                },
                \masterDb, {
                    if ((value >= -24) and: { value <= -6 }) {
                        app[\masterDb] = value;
                        app[\masterTarget] = value.dbamp;
                        app[\masterNode].tryPerform(\set, \amp, app[\masterTarget]);
                        accepted = true;
                    };
                },
                \seed, {
                    if ((value >= 0) and: { value <= 2147483647 } and: { value == value.asInteger }) {
                        if (app[\state] != \playing and: { app[\state] != \stopping }) {
                            app[\seed] = value.asInteger;
                            app[\generatePlan].value;
                            accepted = true;
                        };
                    };
                },
                \density, {
                    if ((value >= 0) and: { value <= 1 }) {
                        if (app[\state] != \playing and: { app[\state] != \stopping }) {
                            app[\density] = value;
                            app[\generatePlan].value;
                            accepted = true;
                        };
                    };
                },
                \variation, {
                    if ((value >= 0) and: { value <= 1 }) {
                        if (app[\state] != \playing and: { app[\state] != \stopping }) {
                            app[\variation] = value;
                            app[\generatePlan].value;
                            accepted = true;
                        };
                    };
                },
                \growl, {
                    if ((value >= 0) and: { value <= 1 }) {
                        app[\bassControls][key] = value;
                        accepted = true;
                    };
                },
                \movement, {
                    if ((value >= 0) and: { value <= 1 }) {
                        app[\bassControls][key] = value;
                        accepted = true;
                    };
                },
                \aggression, {
                    if ((value >= 0) and: { value <= 1 }) {
                        app[\bassControls][key] = value;
                        accepted = true;
                    };
                },
                \tone, {
                    if ((value >= 0) and: { value <= 1 }) {
                        app[\bassControls][key] = value;
                        accepted = true;
                    };
                },
                \texture, {
                    if ((value >= 0) and: { value <= 1 }) {
                        app[\bassControls][key] = value;
                        accepted = true;
                    };
                },
                \width, {
                    if ((value >= 0) and: { value <= 1 }) {
                        app[\bassControls][key] = value;
                        accepted = true;
                    };
                }
            );
        };

        if (accepted) {
            app[\message] = nil;
        } {
            app[\message] = "Ignored invalid control value for " ++ key.asString;
        };
        accepted;
    };

    app[\status] = {
        (
            state: app[\state],
            error: app[\error],
            message: app[\message],
            bpm: app[\bpm],
            pendingBpm: app[\pendingBpm],
            seed: app[\seed], density: app[\density], variation: app[\variation],
            preset: app[\presetName]
        );
    };
}
