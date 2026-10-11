{ |app|
    app[\checkServer] = {
        var server = app[\server];
        var isAlive = server.serverRunning and: { server.unresponsive.not };
        var isActive = [\ready, \playing].includes(app[\state]);
        if (isActive and: { isAlive.not }) {
            app[\runId] = app[\runId] + 1;
            app[\routine].tryPerform(\stop);
            app[\clock].tryPerform(\clear);
            app[\clock].tryPerform(\stop);
            app[\routine] = nil;
            app[\clock] = nil;
            app[\state] = \failed;
            app[\error] = "SuperCollider server stopped responding; close and relaunch the app.";
            app[\error].postln;
        };
        isAlive;
    };

    app[\boot] = { |onReady|
        var server = app[\server];
        var bootToken;
        var serverOwned;
        var waiter;
        var watchdog;
        var attemptBus;
        var attemptGroup;
        var attemptMaster;
        var releaseAttempt;

        if (app[\state] == \ready or: { app[\state] == \playing }) {
            if (onReady.notNil) { onReady.value };
        } {
            if (app[\state] == \booting) {
                "BALKAN//BASS server boot is already in progress.".postln;
            } {
                app[\bootId] = app[\bootId] + 1;
                bootToken = app[\bootId];
                app[\state] = \booting;
                serverOwned = server.serverRunning.not and: { server.serverBooting.not };
                app[\serverOwned] = serverOwned;
                attemptBus = nil;
                attemptGroup = nil;
                attemptMaster = nil;
                releaseAttempt = {
                    if (server.serverRunning) {
                        attemptGroup.tryPerform(\freeAll);
                        attemptGroup.tryPerform(\free);
                        attemptMaster.tryPerform(\free);
                    };
                    if (attemptBus.notNil and: { attemptBus.index.notNil }) {
                        attemptBus.free;
                    };
                    if (app[\voiceGroup] === attemptGroup) { app[\voiceGroup] = nil };
                    if (app[\masterNode] === attemptMaster) { app[\masterNode] = nil };
                    if (app[\mixBus] === attemptBus) { app[\mixBus] = nil };
                };

                if (serverOwned) { server.boot };
                waiter = Routine({
                    var peak = app[\config][\masterPeak];
                    var amp = app[\masterDb].dbamp;
                    while {
                        (app[\bootId] == bootToken) and: {
                            server.serverRunning.not or: { server.statusWatcher.notified.not }
                        }
                    } {
                        0.1.wait;
                    };
                    if ((app[\bootId] == bootToken) and: { server.serverRunning }) {
                        try {
                            app[\synthDefs].do { |definition| definition.send(server) };
                            app[\masterDef].send(server);
                            server.sync;

                            if (app[\bootId] == bootToken) {
                                attemptBus = Bus.audio(server, 2);
                                app[\mixBus] = attemptBus;
                                attemptGroup = Group.head(server);
                                app[\voiceGroup] = attemptGroup;
                                attemptMaster = Synth.tail(server, \bbMaster, [
                                    \in, attemptBus.index,
                                    \amp, 0,
                                    \peak, peak
                                ]);
                                app[\masterNode] = attemptMaster;
                                server.sync;

                                if (app[\bootId] == bootToken) {
                                    app[\bootTimer].tryPerform(\stop);
                                    app[\bootTimer] = nil;
                                    app[\bootWaiter] = nil;
                                    app[\masterTarget] = amp;
                                    app[\state] = \ready;
                                    app[\error] = nil;
                                    if (onReady.notNil) { onReady.value };
                                } {
                                    releaseAttempt.value;
                                };
                            };
                        } { |error|
                            releaseAttempt.value;
                            if (app[\bootId] == bootToken) {
                                app[\bootTimer].tryPerform(\stop);
                                app[\bootTimer] = nil;
                                app[\bootWaiter] = nil;
                                app[\state] = \failed;
                                app[\error] = error.asString;
                                error.reportError;
                                if (serverOwned and: { server.applicationRunning }) {
                                    server.quit(watchShutDown: false);
                                    app[\serverOwned] = false;
                                };
                            };
                        };
                    };
                }).play(SystemClock);
                app[\bootWaiter] = waiter;

                // Keep one owned deadline through both boot and graph preparation.
                watchdog = Routine({
                    30.wait;
                    if (app[\bootId] == bootToken and: { app[\state] == \booting }) {
                        app[\bootId] = app[\bootId] + 1;
                        waiter.tryPerform(\stop);
                        releaseAttempt.value;
                        app[\state] = \failed;
                        app[\error] = "SuperCollider server preparation exceeded 30 seconds.";
                        app[\error].postln;
                        app[\bootWaiter] = nil;
                        app[\bootTimer] = nil;
                        if (serverOwned and: { server.applicationRunning }) {
                            server.quit(watchShutDown: false);
                            app[\serverOwned] = false;
                        };
                    };
                    nil;
                }).play(SystemClock);
                app[\bootTimer] = watchdog;
            };
        };
    };

    app[\shutdown] = {
        var server = app[\server];

        app[\runId] = app[\runId] + 1;
        app[\bootId] = app[\bootId] + 1;
        app[\bootTimer].tryPerform(\stop);
        app[\bootWaiter].tryPerform(\stop);
        app[\bootTimer] = nil;
        app[\bootWaiter] = nil;
        app[\routine].tryPerform(\stop);
        app[\clock].tryPerform(\clear);
        app[\clock].tryPerform(\stop);
        if (server.serverRunning) {
            app[\voiceGroup].tryPerform(\freeAll);
            app[\voiceGroup].tryPerform(\free);
            app[\masterNode].tryPerform(\free);
        };
        app[\mixBus].tryPerform(\free);
        app[\routine] = nil;
        app[\clock] = nil;
        app[\voiceGroup] = nil;
        app[\masterNode] = nil;
        app[\mixBus] = nil;
        app[\state] = \stopped;

        if (app[\serverOwned] and: { server.applicationRunning }) {
            server.quit(watchShutDown: false);
        };
        app[\serverOwned] = false;
        "BALKAN//BASS shutdown requested; owned playback resources released.".postln;
    };
}
