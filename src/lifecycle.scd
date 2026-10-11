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
        var attemptDuckBus;
        var attemptDuckNode;
        var attemptBuffers;
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
                attemptDuckBus = nil;
                attemptDuckNode = nil;
                attemptBuffers = Dictionary.new;
                app[\sampleBuffers] = attemptBuffers;
                releaseAttempt = {
                    if (server.serverRunning) {
                        attemptGroup.tryPerform(\freeAll);
                        attemptGroup.tryPerform(\free);
                        attemptMaster.tryPerform(\free);
                        attemptDuckNode.tryPerform(\free);
                        attemptBuffers.values.do { |buffer| buffer.free };
                    };
                    if (attemptBus.notNil and: { attemptBus.index.notNil }) {
                        attemptBus.free;
                    };
                    if (attemptDuckBus.notNil and: { attemptDuckBus.index.notNil }) {
                        attemptDuckBus.free;
                    };
                    if (app[\voiceGroup] === attemptGroup) { app[\voiceGroup] = nil };
                    if (app[\masterNode] === attemptMaster) { app[\masterNode] = nil };
                    if (app[\mixBus] === attemptBus) { app[\mixBus] = nil };
                    if (app[\duckBus] === attemptDuckBus) { app[\duckBus] = nil };
                    if (app[\duckNode] === attemptDuckNode) { app[\duckNode] = nil };
                    if (app[\sampleBuffers] === attemptBuffers) {
                        app[\sampleBuffers] = Dictionary.new;
                    };
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
                                app[\samplePaths].keysValuesDo { |key, relativePath|
                                    var fullPath = app[\root] +/+ relativePath;
                                    if (PathName(fullPath).isFile) {
                                        attemptBuffers[key] = Buffer.read(server, fullPath);
                                    } {
                                        ("BALKAN//BASS missing optional sample: " ++ fullPath).warn;
                                    };
                                };
                                server.sync;
                                attemptBus = Bus.audio(server, 2);
                                app[\mixBus] = attemptBus;
                                attemptDuckBus = Bus.control(server, 1);
                                attemptDuckBus.set(1);
                                app[\duckBus] = attemptDuckBus;
                                attemptGroup = Group.head(server);
                                app[\voiceGroup] = attemptGroup;
                                attemptDuckNode = Synth.before(attemptGroup, \bbDuck,
                                    [\out, attemptDuckBus.index]);
                                app[\duckNode] = attemptDuckNode;
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
        var delay = server.latency.max(0) + 0.075;
        if (app[\shutdownPending] != true) {
            app[\shutdownPending] = true;
            app[\shutdownAt] = Main.elapsedTime + delay;
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
                app[\masterNode].tryPerform(\set, \amp, 0);
            };
            app[\state] = \stopped;
            // Let timestamped note bundles drain before freeing their target
            // group/buffers or returning bus indices to the allocator.
            SystemClock.sched(delay, {
                if (server.serverRunning) {
                    app[\voiceGroup].tryPerform(\freeAll);
                    app[\voiceGroup].tryPerform(\free);
                    app[\masterNode].tryPerform(\free);
                    app[\duckNode].tryPerform(\free);
                    app[\sampleBuffers].values.do { |buffer| buffer.free };
                };
                app[\mixBus].tryPerform(\free);
                app[\duckBus].tryPerform(\free);
                app[\routine] = nil;
                app[\clock] = nil;
                app[\voiceGroup] = nil;
                app[\masterNode] = nil;
                app[\mixBus] = nil;
                app[\duckBus] = nil;
                app[\duckNode] = nil;
                app[\sampleBuffers] = Dictionary.new;
                if (app[\serverOwned] and: { server.applicationRunning }) {
                    server.quit(watchShutDown: false);
                };
                app[\serverOwned] = false;
                app[\shutdownPending] = false;
                "BALKAN//BASS owned playback resources released.".postln;
                nil;
            });
        };
        (app[\shutdownAt] - Main.elapsedTime).max(0) + 0.1;
    };
}
