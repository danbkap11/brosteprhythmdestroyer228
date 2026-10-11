(
var existing = ~balkan;

if (existing.notNil and: { existing[\guiOpen] == true }) {
    existing[\window].front;
} {
    var executingPath = thisProcess.nowExecutingPath;
    var root;
    var readModule;
    var config;
    var drumDefs;
    var bassDefs;
    var talkingDef;
    var yoiDef;
    var accentDef;
    var bassTopDef;
    var shoutDef;
    var sampleDef;
    var sampleBassDef;
    var screechDef;
    var raveDef;
    var duckDef;
    var atmosphereDef;
    var sparkDef;
    var samplePaths;
    var masterDef;
    var setupLifecycle;
    var setupSequencer;
    var setupControls;
    var setupGui;
    var presets;
    var app;
    var relaunchDelay = 0;

    if (executingPath.isNil) {
        Error("Open and evaluate main.scd from the SuperCollider IDE so its relative modules can be found.").throw;
    };
    if (existing.notNil) {
        relaunchDelay = existing[\shutdown].tryPerform(\value);
        if (relaunchDelay.isKindOf(Number).not) { relaunchDelay = 0.35 };
    };

    root = PathName(executingPath).pathOnly;
    readModule = { |relativePath|
        var fullPath = root +/+ relativePath;
        var contents = File.readAllString(fullPath);
        if (contents.isNil) {
            Error("Unable to read SuperCollider module: " ++ fullPath).throw;
        };
        contents.interpret;
    };

    config = readModule.value("src/config.scd");
    drumDefs = readModule.value("src/synthdefs/drums.scd");
    bassDefs = readModule.value("src/synthdefs/bass.scd");
    talkingDef = readModule.value("src/synthdefs/bass_talking.scd");
    yoiDef = readModule.value("src/synthdefs/bass_yoi.scd");
    accentDef = readModule.value("src/synthdefs/bass_accent.scd");
    bassTopDef = readModule.value("src/synthdefs/bass_top.scd");
    shoutDef = readModule.value("src/synthdefs/shout.scd");
    sampleDef = readModule.value("src/synthdefs/samples.scd");
    sampleBassDef = readModule.value("src/synthdefs/bass_sample.scd");
    screechDef = readModule.value("src/synthdefs/bass_screech.scd");
    raveDef = readModule.value("src/synthdefs/rave.scd");
    duckDef = readModule.value("src/synthdefs/duck.scd");
    atmosphereDef = readModule.value("src/synthdefs/atmosphere.scd");
    sparkDef = readModule.value("src/synthdefs/spark.scd");
    samplePaths = readModule.value("src/samples.scd");
    masterDef = readModule.value("src/routing.scd");
    setupLifecycle = readModule.value("src/lifecycle.scd");
    setupSequencer = readModule.value("src/sequencer.scd");
    setupControls = readModule.value("src/controls.scd");
    presets = readModule.value("src/presets.scd");
    setupGui = readModule.value("src/gui.scd");
    if (setupSequencer.isKindOf(Function).not) {
        Error("The sequencer module did not compile to a setup Function. Check the first earlier Post Window error.").throw;
    };
    if (talkingDef.isKindOf(SynthDef).not) {
        Error("The talking bass SynthDef did not load. Check the first earlier Post Window error.").throw;
    };
    if (yoiDef.isKindOf(SynthDef).not or: {
        accentDef.isKindOf(SynthDef).not or: {
            bassTopDef.isKindOf(SynthDef).not or: {
                shoutDef.isKindOf(SynthDef).not or: {
                    sampleDef.isKindOf(SynthDef).not
                }
            }
        }
    }) {
        Error("A bass or sample SynthDef did not load. Check the first earlier Post Window error.").throw;
    };
    app = Dictionary.new;

    app[\config] = config;
    app[\root] = root;
    app[\samplePaths] = samplePaths;
    app[\sampleBuffers] = Dictionary.new;
    app[\server] = Server.default;
    app[\serverOwned] = false;
    app[\state] = \stopped;
    app[\runId] = 0;
    app[\bootId] = 0;
    app[\bootWaiter] = nil;
    app[\bootTimer] = nil;
    app[\routine] = nil;
    app[\clock] = nil;
    app[\voiceGroup] = nil;
    app[\masterNode] = nil;
    app[\mixBus] = nil;
    app[\duckBus] = nil;
    app[\duckNode] = nil;
    app[\shutdownPending] = false;
    app[\shutdownAt] = 0;
    app[\error] = nil;
    app[\synthDefs] = drumDefs ++ bassDefs ++
        [talkingDef, yoiDef, accentDef, bassTopDef, shoutDef, sampleDef,
            sampleBassDef, screechDef, raveDef, duckDef, atmosphereDef, sparkDef];
    if (app[\synthDefs].every { |definition| definition.isKindOf(SynthDef) }.not) {
        Error("A SynthDef module did not compile. Check the first Post Window error.").throw;
    };
    app[\masterDef] = masterDef;
    app[\presets] = presets;

    setupLifecycle.value(app);
    setupControls.value(app);
    setupSequencer.value(app);
    app[\selectPreset] = { |presetName|
        var preset = app[\presets][presetName];
        var accepted = false;
        if (preset.notNil and: { app[\state] != \playing } and: { app[\state] != \stopping }) {
            app[\bassControls] = preset[\bassControls].copy;
            app[\presetName] = presetName;
            app[\generatePlan].value;
            app[\message] = nil;
            accepted = true;
        } {
            app[\message] = "Preset unavailable while playing or unknown.";
        };
        accepted;
    };
    setupGui.value(app);
    ~balkan = app;

    {
        app[\openGui].value;
        app[\boot].value;
    }.defer(relaunchDelay.max(0));
};
)
