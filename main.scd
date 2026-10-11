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
    var sampleDef;
    var samplePaths;
    var masterDef;
    var setupLifecycle;
    var setupSequencer;
    var setupControls;
    var setupGui;
    var presets;
    var app;

    if (executingPath.isNil) {
        Error("Open and evaluate main.scd from the SuperCollider IDE so its relative modules can be found.").throw;
    };
    if (existing.notNil) {
        existing[\shutdown].tryPerform(\value);
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
    sampleDef = readModule.value("src/synthdefs/samples.scd");
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
        sampleDef.isKindOf(SynthDef).not
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
    app[\error] = nil;
    app[\synthDefs] = drumDefs ++ bassDefs ++ [talkingDef, yoiDef, sampleDef];
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
    }.defer;
};
)
