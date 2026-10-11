# BALKAN//BASS — implementation plan

## Quick MVP — current authorized scope

The user's latest listening direction supersedes the earlier 7/8 contract:
**140 quarter-note BPM, 4/4 halftime, 16 sixteenth-note steps per bar**, with
the main snare on step 8. The current loop is 28 bars / 48 seconds:
intro 2 → build 2 → drop A 8 → break 4 → build 4 → drop B 8. Drop A begins
after about 6.86 seconds. Keep seeded, pre-generated riffs, a separate mono
sub, native GUI, protected master, and owned-resource cleanup. The bundled
CC0 drum/FX one-shots and bounded mid-bass voices serve this listening
iteration; no external download is required. Export and formal tests remain
deferred. Sections below this Quick MVP note describe historical planning,
including a superseded 7/8 version.

Latest listening revision: **Arabic/Hijaz-inspired brostep**, replacing the
earlier Balkan/pentatonic theme. The equal-tempered collection is
`[0,1,4,5,7,8,10]`, with tonic/b2/major-third/fourth gestures and cadences.
Seeded tonic/bII/IV accompaniment stays in that collection. The GUI reads
HIJAZ//BASS; repository/module names and the `~balkan` API remain compatible.
This is an electronic adaptation, not a claim of traditional maqam intonation.

`bbRave` retains its controls/name but replaces bright brass oscillators with
a rounded native Pluck/reed hybrid, bounded low-pass and final 220 Hz high-pass.
Its maximum finite duration is 1.25 s; early gate release is 45 ms. Melodic
event levels and counterline register are reduced. The atmosphere attack is
25 ms so the break downbeat begins promptly; hook/pad/percussion/sub-pulse
activity starts at the break entrance. Pre-drop vocal cuts remain intentional.

Upper bass has fuller parallel body/formant support, slightly stronger bounded
saturation and higher finite sustain. Foreground mid notes may sustain across
kicks under existing ducking; clean sub durations still end before a later
kick and main bass notes end before the next main note. Sub synthesis, master
peak/gain limits, routing, timing, GUI macros and cleanup are preserved.

The subsequent seed/arrangement iteration preserves the drop synthesis but
generates a seed-specific ancestral motif and mutates its onsets, lengths,
endings and register across phrases. Stable anchors keep thematic identity;
rhythm, melody and harmony must change between seeds rather than only hats.
The four-bar break resolves the preceding drop, develops the hook over a
chord bed, returns sparse counterline/percussion, then connects to the build.
Seeded generation remains separate from playback; Play reuses the stored plan.

Two small supporting modules return one SynthDef each: `bbAtmosphere` in
`src/synthdefs/atmosphere.scd` and `bbSpark` in `src/synthdefs/spark.scd`.
Both use `out/freq/amp/dur/gate/beatHz/duckBus/tone/width`; Atmosphere also
accepts `thirdSemis/fifthSemis`. Their final high-pass is 300 Hz, with bounded
levels, mono-safe width, finite lifetime and optional kick ducking. They write
to the same mix bus inside the owned source group, requiring no new routing
or clock. The pad lasts at most 4.5 s; the spark's dry note is at most 0.6 s
with finite echo taps (total at most about 1.11 s). Stop/cuts free their tails.

Optional plan fields `pad`, `spark`, and `perc` contain resolved note data
or nil. Pad data: `midi/thirdSemis/fifthSemis/durBeats/amp/tone/width`;
spark data: `midi/durBeats/amp/tone/width`; percussion data:
`sample/amp/hp/width` using existing licensed one-shots. All lanes share the
existing step bundle. Supporting layers complement the foreground bass,
retain one clean sub, and stay absent in the pre-drop instrumental cut.

The earlier 2026-10-11 rework added an original seeded rave/brass hook, six composed
two-bar bass cells, sparse `bbScreech` replies, and `bbBassSample` substitutions
using bundled CC0 growl/reese chops. `bass.scd` still returns the existing
`bbSub`/`bbGrowl` Array; `main.scd` explicitly registers each new small module.
The growl now has three FM operators and bounded band-specific saturation.
Final mid high-passes are 115 Hz (180 Hz for screech), while sub stays a
90 Hz low-passed sine. This intentionally retains more low-mid body than
the historical 150 Hz design; it is not a complementary crossover.

Routing remains one stereo mix bus with an owned voice group before master.
One owned control bus and `bbDuck` node precede the voice group; existing
kick events trigger its duck envelope in the same timestamped bundle as all
other layers. Optional `duckBus = -1` preserves standalone voice use. Sub is
ducked directly; upper bass retains a 0.35 floor. Stop frees voice children
after pending bundles drain, preserving the persistent duck/master graph.
Shutdown then frees only owned nodes, buffers, audio/control buses and clock.

The master keeps peak 0.68 and GUI default -6 dB, with stereo-linked parallel
compression and measured makeup. A bounded, smoothed `sectionGain` defaults
to 1 for old callers; the sequencer lowers intro/build/break levels separately
from the user's master setting. Buildups end with a source-group cut followed
by the vocal cue; both drops have coherent root sub and contrasting mid
responses. No GUI, preset or export framework redesign is part of this work.

Actual compatible Linux SC 3.13.0 compilation, NRT rendering, dummy-JACK
lifecycle and offscreen Qt checks now exist; macOS SC 3.14.1 and listening
remain unverified. See PROGRESS.md. This validation is evidence, not a new
prerequisite or formal test-suite requirement for this personal app.

Historical listening feedback on 2026-10-11 authorized a 32-bar, 48-second
phrase at 140 BPM: intro 4 bars → build 4 → drop A 8 → break 4 → build 4 →
drop B 8. That version kept 7/8 grouped 2+2+3, the native GUI and transport,
deterministic seeded events, separate mono sub, and protected output. It added
a talking bass reply and synthesized open hat, riser, and impact.
The previous eight-bar scope below records the first working version.

### Earlier eight-bar GUI baseline (superseded)

This personal music toy prioritizes a usable GUI and playback over production validation or the complete long-term architecture. Keep the current synthesized kick/snare/hat, mono sub, and moving FM/reese growl. Preserve 140 quarter-note BPM, 7/8 grouped 2+2+3, the eight-bar loop, conservative master protection, and owned start/stop/shutdown behavior.

Add native Qt controls for Play/Stop, status, BPM, master level, and the existing six bass macros. Macro controls affect following notes. Tempo changes take effect at the next bar boundary on the same TempoClock. Opening the app prepares the server without starting playback; evaluating the launcher while its window is open focuses that window. The current quick target also includes a pre-generated seeded eight-bar loop, bounded Density and Variation controls, and two data-only character presets. The selected event plan is reused on each Play until Generate or a stopped generation setting change rebuilds it.

The first milestone is a working macOS launch and manual play/tweak/stop loop, with concise launch instructions. Formal test infrastructure, NRT/export, more bass families, folk and cross-synthesis voices, complex arrangement, and performance profiling are deferred. Do not make those items prerequisites to using this MVP. Keep this scope note authoritative over the longer roadmap and acceptance gates below until the user asks to resume them. Record runtime validation as unavailable in the cloud; do not imply it has passed.

Status: the architecture and backlog below remain the historical long-term reference. The current user-approved target is a playable macOS SuperCollider 3.14.1 app with native Qt controls; current validation evidence is recorded above and in PROGRESS.md.

## 1. Project direction and scope

Build one modular, generative SuperCollider composition and sound-design engine: **7/8 Rhythm Destroyer**. Combine original folk-inspired motifs with synthesized drums, aggressive FM/wobble/reese basses, a clean mono sub, and experimental alien cross-synthesis. Default to **140 BPM**, measured in quarter notes. Use **SuperCollider 3.14.x**, stock UGens, native Patterns/clocks, native Qt controls, and native stereo WAV rendering.

The initial composition should sound deliberately arranged: recognizable motifs, tension and release, heavy drops, and repeatable variations. It should remain understandable enough for a cheaper implementation model to maintain. Do not turn the MVP into a plugin framework, DAW, or general-purpose music workstation.

The $20 ChatGPT Plus subscription is a usage constraint, not a guarantee of a specific Codex quota. Minimize development turns, external research, long tool logs, dependencies, and speculative refactors. Complete one small backlog item at a time and use its acceptance gate before moving on.

### Phase 1: runnable audible kernel

Deliver a 16-bar, 24-second sketch plus a two-second release tail. It must boot, play, stop cleanly, and render a stereo WAV. Include synthesized kick/snare/hats; a seeded folk motif; one bass SynthDef with restrained FM/wobble/reese controls; a separate mono sub; a simple ring-modulation cross-synth; fixed section changes; and protected stereo output. No GUI or FFT processing is required in this first gate.

### Full MVP

Expand Phase 1 into a 64-bar composition, controlled generation, a small native Qt panel, factory preset selection, and deterministic offline export. Required controls: start/stop, seed, tempo, density, bass character, motif variation, cross-synth amount, master level, preset, and export. Defaults must produce useful music without tuning controls first. In drops, alternate a primary growl and a contrasting metallic/reese reply over two-bar cells within the established 8-/16-bar phrases, using bounded parameter sets in the existing bass SynthDef. Additional dedicated impacts/risers remain later work; first use the existing noise/percussion and FX paths for transitions.

### Deferred beyond MVP

Spectral cross-synthesis, microtonal tuning, richer drum voices, more bass algorithms, external MIDI/OSC control, additional meters, custom scales, live performance recording, automation editing, waveform displays, presets on disk, and a larger GUI. No samples, Quarks, sc3-plugins, Python audio stack, Node frontend, or external database are required.

## 2. Repository and environment inspection

Observed on 2026-10-11:

| Item | Evidence and implication |
| --- | --- |
| Checkout | `/workspace/brosteprhythmdestroyer228`; clean, unborn local `work` branch; no tracked project files before this plan. |
| Remote | `danbkap11/brosteprhythmdestroyer228` on GitHub; read-only Git access succeeds, but no refs or `main` branch were advertised during initial inspection. The checkout had no application to extend at that time. |
| Instructions | No repository/workspace `AGENTS.md` was found during initial inspection; this refinement adds root `AGENTS.md` for future agents. |
| Host | Debian GNU/Linux 13, Linux x86_64; five reported processors, approximately 32 GiB memory and 30 GiB free workspace storage. |
| SuperCollider | `sclang`, `scsynth`, and `supernova` are absent. No SuperCollider version is validated yet. |
| Audio/display | No `/dev/snd`; no `jackd`, `pw-jack`, `aplay`, `pactl`, or `xvfb-run`; display variables are unset. Native interactive audio and GUI operation are unverified. JACK/ALSA runtime libraries are present. |
| Package metadata | Current APT cache provides no usable SuperCollider candidate; one APT configuration read was denied. This does not prove packages are unavailable after an authorized package-index refresh. |
| Other tools | Git, Python 3, and `timeout` are available; Python is not an application dependency. |

No setup or configuration changes are part of this planning pass. Do not claim this host is audio-ready. During implementation, use the existing isolated checkout; do not create a Git worktree unless explicitly requested.

## 3. Musical contract

### Meter and groove

- The canonical grid is **7/8**, grouped **2+2+3**. One bar contains seven eighth-note steps, or **3.5 quarter-note beats**.
- At 140 BPM an eighth note lasts approximately 0.214286 seconds; one bar lasts **1.5 seconds**. Never interpret BPM as eighth notes per minute or silently round a bar to four beats.
- Use a heavy snare on the **fifth eighth note**, zero-based step **4**, once per bar. This borrows the beat-three impact of halftime brostep but resets at the asymmetric bar boundary; it is not a strict four-quarter-note snare cycle.
- Start with kick anchors at steps 0 and 3, optional kick at step 6, and a restrained seven-step hat pattern. Density adds fills around these anchors without removing the main snare or bar downbeat.
- Folk accents emphasize steps 0, 2, and 4. An optional three-eighth-note ostinato runs against the seven-step bar and realigns every **21 eighth notes / three bars**. Compute its phase from the global step, not a reset counter inside each bar.
- MVP microtiming is limited to seeded velocity variation. Timing humanization and swing are deferred until grid accuracy is established. Later timing offsets must never move anchors across bar boundaries.

### Pitch and motif

- Default tonal center: D. Default motif collection: D–E-flat–F-sharp–G–A–B-flat–C, described as a Hijaz-like pitch collection rather than a claim of a single authentic Balkan tradition.
- Default folk register starts near MIDI 62 (D4); upper bass starts near MIDI 38 (D2); sub starts near MIDI 26 (D1).
- Motifs are original two- or four-bar phrases: repeated notes, short ornaments, neighbor tones, register answers, and occasional rests. Preserve a recognizable anchor before applying variations.
- Store degrees and durations separately from MIDI conversion. Ornament density, transposition within the collection, and bounded register changes are allowed; arbitrary chromatic wandering is not the default.
- Bass and sub follow an explicit harmonic/root lane derived from the same phrase. Do not blindly double every folk ornament in the sub. Fold sub notes into a configured range near MIDI 24–40 and verify the resulting fundamentals stay approximately 30–90 Hz.
- Generative choices are bounded by section and phrase rules. The engine must not become an unstructured random-note stream.

### Arrangement

| Gate | Sections, in bars | Musical behavior |
| --- | --- | --- |
| Phase 1 | Intro 4 → build 4 → drop 8 | Introduce motif, add percussion, then expose full bass/sub and modest cross-synthesis. |
| MVP | Intro 8 → build 8 → drop A 16 → break 8 → drop B 16 → outro 8 | Break strips back the bass; drop B varies motif/bass while preserving identity; outro releases and fades. Total: 64 bars / 96 seconds at 140 BPM, plus a two-second tail. |

Scene changes occur on bar boundaries; fills occupy planned phrase endings. Protect the downbeat after a fill. Section muting preserves the underlying grid and motif phase. Do not change meter during playback in the MVP.

## 4. Architecture and interfaces

Use small `.scd` modules that evaluate to Dictionaries containing data and named operations. Use one public application Dictionary, `~balkan`, established by the entry point. Avoid unrelated global variables, custom class recompilation, and hidden load-order side effects. The bootstrap owns load order explicitly.

Configuration is treated as immutable during compilation. Runtime state is separate and explicitly passed to modules. Audio modules only define SynthDefs; planning modules only produce event data; lifecycle/scheduler/export modules own side effects.

### Shared data contracts

| Contract | Required fields and meaning |
| --- | --- |
| `Config` | `bpm` (default 140; allowed 120–160), `meterEighths` (7), `grouping` ([2,2,3]), `seed` (default 228; nonnegative 31-bit integer), `sampleRate` (48000), `blockSize` (64), `rootMidi` (62), `scaleSemitones` ([0,1,4,5,7,8,10]), `density` (default 0.55; 0–1), `motifVariation` (default 0.25; 0–1), `bassCharacter` (default 0.6; 0–1), `crossMix` (default 0.12; 0–0.35), `masterDb` (default -12; bounded -60–0), and arrangement preset. Upper-bass/sub registers derive from root offsets -24/-36, followed by sub-range folding. Reject invalid values rather than partially applying them. |
| `Plan` | Seed/config snapshot, total beats, ordered scenes, and stable ordered events. Beats are quarter-note units relative to transport epoch; times derive from the selected BPM. |
| `Scene` | Name, start bar, bar count, active lanes, density ceiling, variation settings, FX targets, and final fade behavior. |
| `Event` | Stable `id`, `lane`, `barIndex`, `stepIndex`, `beat`, `durationBeats`, `voiceSeed`, `synthKey`, and a validated parameter Dictionary. A rest produces no synth event. Control events name an owned target and whitelisted parameter. |
| `Runtime` | Lifecycle state, owned server/clock status, source/process/master groups, bus handles, persistent node handles, active schedulers, transport epoch, pending controls, and recorded error. No hard-coded bus or node numbers. |
| `Result` | Operation success/failure, useful error message, and optional output path or test summary. Batch entry points use nonzero exit status on failure. |

### Modules and responsibilities

| Module | Inputs → outputs / operations | Responsibility and constraints |
| --- | --- | --- |
| `config` | User overrides → validated `Config` | Defaults, bounds, timing conversions; no server boot. |
| `presets` | Factory registry → preset IDs/metadata; preset ID + seed → validated config | Small data-only configurations using existing modules; no new synth algorithms or executable user files. |
| `lifecycle` | `Config` → `Runtime`; prepare/start/stop/shutdown | Boot or attach to the selected server; install definitions with completion/sync; allocate owned resources; enforce state transitions and idempotent cleanup. |
| `routing` | Server + config → bus/group handles and persistent mixer nodes | Build and free the audio graph, preserve processing order, expose named lane gains and master controls. |
| `synthdefs/drums` | Registration; kick/snare/hat controls | Stock synthesized percussion; self-freeing bounded envelopes. |
| `synthdefs/bass` | Registration; upper-bass and sub controls | Frequency, gate, amplitude, seed, FM index, wobble rate/depth, reese detune, cutoff, and output bus. Upper bass excludes the low sub band. Sub has no distortion or stereo widening. |
| `synthdefs/folk` | Registration; frequency/gate/amplitude/seed/brightness | Plucked/reed-like voice with ornaments scheduled as notes, not a separate uncontrolled clock. |
| `synthdefs/cross` | Folk bus + upper-bass bus → cross bus; mix/tone controls | Bounded ring modulation; no dependency on an FFT or plugins. Never cross-modulate the dedicated sub. |
| `synthdefs/fx` | Lane buses + kick trigger + mix controls → master output | Bass ducking, conservative distortion/filtering, small ambience, DC removal, output protection, and fade. |
| `motifs` | Config + per-layer seed → phrase degrees, durations, harmonic lane | Pure motif generation and bounded variations. |
| `arrangement` | Preset + config → ordered `Scene` data | No audio I/O; chooses musical density and transformations per scene. |
| `sequencer` | Config + motifs + scenes → `Plan`; runtime + plan → scheduled playback | One master clock; deterministic event compilation; explicit 3.5-beat bar quantization; no independently drifting lane clocks. |
| `renderer` | Config/plan + definitions → stereo WAV + `Result` | Native `Score`/`scsynth` non-real-time render; same event compiler and graph topology as playback. |
| `gui` | Public app API + state → native Qt window | Thin controls/status; no synthesis, RNG, or arrangement logic. Export is asynchronous to the UI. |

Public app operations are `prepare`, `start`, `stop`, `shutdown`, `setControl`, `setSeed`, `selectPreset`, `export`, and `status`. This is an interface specification, not implementation syntax.

- `prepare`: establish a ready graph; report boot/definition failures; safe to call twice.
- `start`: compile from seed, reset phase, and begin one transport; a repeated call must not double the music.
- `stop`: cancel only owned schedules, fade the master, release owned notes, and return to ready state. Keep the prepared graph available for restart.
- `shutdown`: free owned buses/groups/nodes and GUI resources; quit a server only if this application started it. Never use global cleanup that stops unrelated sessions.
- `setControl`: validate whitelisted controls. Smooth audio gain/filter changes; commit generation changes at the next bar. Apply tempo changes at a bar boundary using the same master clock; do not pre-schedule the entire performance in wall-clock seconds.
- `setSeed`: set the next run/export seed while stopped; reject during playback with a clear status message. A start from stopped resets the entire generative state.
- `selectPreset`: resolve and validate a factory preset while stopped; preserve the current seed unless explicitly overridden. Reject unknown presets or selection during playback without changing active state. Apply atomically and reprepare only if required; never duplicate the graph.
- `export`: snapshot config and compile a fresh offline arrangement. It exports that snapshot, **not a recording of earlier live knob movements**. Run a fresh NRT server, include release tail, avoid overwriting a file without explicit selection/consent, and return completion/failure.
- `status`: expose lifecycle state, current bar/scene, seed, server mode, and export state. The GUI observes this; it does not infer playback from an open port.

Lifecycle states: idle → preparing → ready → playing → stopping → ready; errors retain a useful message and support cleanup/retry. Export state is separate. Closing the GUI stops the engine and frees its owned controls/resources without quitting an unrelated server.

## 5. Audio graph and sound design

Execution order: source group → cross-synthesis group → FX/mix group → master group. Route drums, folk, upper bass, mono sub, and cross signal through separate allocated buses. No voice writes directly to hardware output.

### Voice goals

| Voice | Native building blocks and sound target | Boundaries |
| --- | --- | --- |
| Kick | Sine body with short pitch fall; short noise/click transient | Clear fundamental around 40–70 Hz, self-freeing envelope; keep click modest. |
| Snare | Filtered noise plus two short tonal bodies | Heavy halftime impact; high-pass unnecessary low rumble; no sample requirement. |
| Hats | Short filtered noise and/or metallic oscillators | Distinct closed/open decay, controlled high-frequency energy; cap overlaps. |
| Folk | `VarSaw`/pulse reed option and/or `Pluck` with filtered excitation | Audible melodic identity, slight ornamentation; folk voice must remain identifiable under the bass. Pick one voice first. |
| FM/wobble bass | `SinOsc` FM with musically bounded ratios/index, filtered saw body, tempo-derived filter/amplitude motion | Growls and formant-like motion; parameters stay finite and bounded; avoid uncontrolled feedback. |
| Reese layer | Two slightly detuned saws and mild saturation | Stereo movement above roughly 110 Hz; keep one combined upper-bass SynthDef initially. |
| Sub | Single sine, short attack/release, low-pass near 90 Hz | Identical left/right contribution; fixed level range; no reese detune, cross-synthesis, distortion, or stereo FX. |
| Cross layer | Multiply folk and upper bass to generate sum/difference frequencies; filter and normalize conservatively | Actual audio cross-synthesis; dry layers remain available; default low mix, hard maximum 0.35. |

Use stock `EnvGen`/done actions for voice lifetimes. Smooth sustained controls with `Lag` or equivalent. Give every randomized voice an explicit server-side seed as well as deterministic language-side event selection. Verify the exact 3.14.x RNG behavior before claiming sample-level reproducibility.

Initial bass limits: FM carrier/modulator ratio 0.5–8, modulation index 0–12, reese detune 0–25 cents, wobble divisions chosen from a finite tempo-synced set, and upper-bass cutoff approximately 110–8000 Hz. Validate frequency/envelope/amplitude controls before scheduling. `bassCharacter` maps to a documented bounded combination of these controls; it must not override their safety bounds. Keep these as patch limits, not new GUI widgets in the MVP.

### Mix and FX

- Apply a short kick-triggered gain envelope to upper bass, cross layer, and sub; triggers come from the same kick events, not a second rhythm generator.
- Keep distortion/wavefolding primarily on the upper bass. Limit input drive, filter after distortion, and remove DC. Start with `tanh`/`softclip` rather than feedback networks.
- Send folk and upper layers sparingly to short delay/ambience. Leave sub dry. Clamp delay feedback below 0.75 and use a two-second release tail in default renders.
- Final path: DC removal, a low-frequency cleanup filter that preserves the sub, smoothed master gain/fade, and a stock limiter near amplitude **0.7**. Account for limiter lookahead; a limiter does not replace sane voice gains.
- Default startup gain is -12 dB. Inspect export levels before listening and start physical monitoring quietly. Do not rely on loudness maximization to make the drop work.
- Default voice cap: 32 concurrent transient/note voices, plus a fixed small set of processing nodes. Clamp event density to at most 64 note events per bar; prioritize anchors over ornaments if the cap is approached.

Phase 3 may add true spectral cross-synthesis using `FFT`/`IFFT` and `PV_MagMul` or a documented native alternative. Allocate FFT buffers explicitly, preserve dry routing, manage frame normalization, and measure latency/CPU. Do not present simple envelope following as spectral cross-synthesis.

## 6. Determinism and scheduling

Use one seed for the composition, with stable independently derived seeds for drums, motif, bass variation, and voice randomness. Document the derivation and avoid unstable object hashes or one shared random stream whose results change when an unrelated lane is muted.

Compile a finite event plan in canonical order: beat, lane priority, then stable event ID. Musical choices occur during compilation, not opportunistically in GUI callbacks or server replies. Event beats use the eighth/sixteenth grid (0.5/0.25 quarter notes) and scene boundaries are exact multiples of 3.5 beats.

Real-time playback uses one owned `TempoClock` and native Patterns or a small clock scheduler consuming this same plan. Choose one playback mechanism initially. Explicitly quantize to the transport epoch and 3.5-beat bars; never rely on the default 4/4 clock bar. Use a small bounded scheduling lookahead and the server's supported latency handling. Account for tempo changes by mapping future beat positions with the active clock.

Offline rendering converts the plan's beats to seconds at its config BPM and uses native `Score`. Initialize SynthDefs/buses/nodes before the first musical event; complete asynchronous definition loading before dependent nodes execute. A render starts from a fresh server state and produces **48 kHz, stereo, 24-bit PCM WAV** by default.

Determinism means identical event plans for identical config/seed. Identical decoded PCM is a separate same-runtime acceptance target: same patch version, UGens, sample rate/block size, node order, and server mode. Cross-platform/version bit identity and real-time device recordings are not promised. Any voice that prevents repeated NRT PCM matching must be diagnosed, replaced with a reproducible native alternative, or documented as an unresolved export limitation.

### Minimal preset handling

Ship two factory presets, `destroyer` (default FM/growl emphasis) and `reeseReply` (more reese/metallic contrast), as data in `src/presets.scd`. Each has a stable ID, display name, schema version 1, and whitelisted config overrides. Resolve by copying defaults, applying preset overrides, then applying the current seed and validating the complete config. Presets cannot store live nodes, buses, paths, clocks, functions, or arbitrary SynthDef names. Record preset ID/schema and resolved config in the export result so the render can be reproduced.

Unit checks must confirm deterministic resolution, valid bounds, independent returned configs, and rejection of unknown IDs/unsupported schemas. User save/load and preset files remain deferred; no serializer, Quark, or evaluation of untrusted preset code is needed in the MVP.

## 7. Planned file structure

The following source files implement the small real-time audio slice. The remaining listed files are planned future work:

```text
main.scd                    implemented entry point; boot server and expose ~balkan
src/config.scd              implemented fixed 140 BPM / 7/8 loop configuration
src/lifecycle.scd           implemented server boot, owned buses/nodes and cleanup
src/routing.scd             implemented stereo mix bus and protected master
src/synthdefs/drums.scd      implemented kick, snare and closed hat
src/synthdefs/bass.scd       implemented mono sub and modulated FM/reese voice
src/sequencer.scd           implemented repeating eight-bar TempoClock pattern
src/presets.scd             two validated factory preset configurations
src/synthdefs/folk.scd       first folk voice
src/synthdefs/cross.scd      ring-modulation processor
src/synthdefs/fx.scd         mix, ducking, ambience, master protection
src/motifs.scd              motif and harmonic lane generation
src/arrangement.scd         scene presets and transitions
src/renderer.scd            native NRT export
src/gui.scd                 native Qt controls
scripts/play.scd            minimal real-time launcher
scripts/export.scd          headless default render
tests/unit.scd              timing, config, plan/seed contracts
tests/nrt_smoke.scd         render and native SoundFile assertions
tests/lifecycle.scd         boot/start/stop/restart resource checks
tests/gui_smoke.scd         widget construction, callbacks, cleanup
docs/SETUP.md               pinned runtime and audio-backend instructions
docs/PROGRESS.md            brief completed gates and known blockers
README.md                   shortest paths to play, export, and test
.gitignore                  generated WAVs, logs, local paths, temp scores
renders/                    ignored user exports
tmp/                        ignored generated scores/logs
```

Aim for most modules to remain roughly 80–150 lines; split only when a real responsibility warrants it. Do not add an abstraction solely to meet a line count. Avoid generated frameworks and duplicate real-time/offline synthesis definitions.

## 8. Dependencies and runtime setup plan

| Requirement | Needed for | Planned resolution |
| --- | --- | --- |
| SuperCollider **3.14.x** language, class library, and `scsynth` | All application/test modes | Pin one released 3.14.x patch version after verifying official availability. Match language and server builds. Use an official release/package or an authenticated, checksum-verified source build; never silently substitute another minor version. |
| Qt runtime compatible with that SC build | `sclang` and native GUI | Prefer dependencies supplied by the supported SuperCollider package/build. Headless language tests use Qt offscreen where supported. |
| Writable user/runtime/cache/export locations | Compilation and rendering | Use documented local paths; no secrets or absolute developer-specific paths in modules. |
| Audio backend/device, or JACK dummy backend on Linux | Real-time server/transport tests | Desktop: existing compatible device/backend. Cloud: install/use JACK dummy if available; confirm actual server boot and signal, not just process presence. Dummy output does not establish physical audibility. |
| No audio device | NRT export | `scsynth` non-real-time mode should render to disk without a device. This is the required cloud path. |
| Qt display/offscreen or virtual display | GUI tests | Test offscreen construction first; add Xvfb only if needed. Human GUI interaction and physical listening remain desktop checks. |

No credentials, remote services, licensed sample packs, or package-manager plugins are needed by the music engine. Installation may require approved OS changes/network access; do not embed credentials or disable TLS/checksum verification. Avoid a source build unless a verified matching binary/package is unavailable. If required, inspect CPU/memory limits and use conservative parallelism, initially two build jobs.

Implementation should save tested setup and startup instructions in the cloud configuration when available, after actual installation/validation. This plan does not save installation scripts or claim a published environment.

## 9. Validation commands and acceptance tests

Commands below are planned entry points. Except for the earlier environment inspection, they have **not been executed** and the referenced application/test files do not exist yet. Run from `/workspace/brosteprhythmdestroyer228`. Test scripts must terminate reliably, print assertion totals, and exit nonzero on any failure; no zero-test success.

| Purpose | Planned command | Required evidence |
| --- | --- | --- |
| Verify runtime | `sclang -v` and `scsynth -v` | Both report the selected 3.14.x patch; language/class library compiles without missing UGens. |
| Pure contracts | `QT_QPA_PLATFORM=offscreen timeout 60s sclang -D tests/unit.scd` | Positive assertion count; malformed config rejected; meter math, scenes, and seeds checked without booting audio. |
| Cloud render smoke | `QT_QPA_PLATFORM=offscreen timeout 180s sclang -D tests/nrt_smoke.scd` | Fresh render, file completion confirmed, native `SoundFile` validation, no server/UGen errors. |
| Default WAV export | `QT_QPA_PLATFORM=offscreen timeout 180s sclang -D scripts/export.scd` | Output path reported only after a valid completed WAV; failure propagates. |
| Real-time lifecycle | `QT_QPA_PLATFORM=offscreen timeout 90s sclang -D tests/lifecycle.scd` | Compatible backend already running; source signal and start/stop/restart cleanup verified. Timeout/boot failure is failure. |
| Headless GUI smoke | `QT_QPA_PLATFORM=offscreen timeout 60s sclang -D tests/gui_smoke.scd` | Widgets construct, callbacks call the public API, errors are displayed, close cleans up. Does not certify interactive usability. |
| Desktop play/GUI | `sclang main.scd` | Native window, reliable playback/stop/export and listening checks on a device-equipped host. |

If the SC build cannot run language compilation in offscreen mode, diagnose the Qt error and use a verified virtual-display route. Do not hide the failure by skipping tests. Introduce fixtures/tests only for meaningful contracts, not tests that repeat implementation line by line.

### Acceptance gates

1. **Runtime:** pinned matching 3.14.x language/server installed; class library compiles; a short native NRT tone render has finite nonzero samples and a valid stereo WAV. This tone is a setup check, not the composition acceptance test.
2. **Plan/compiler:** 7 steps = 3.5 beats = 1.5 seconds at 140; default anchor snare occurs at beat 2 of every bar; three-step folk overlay realigns after three bars; no out-of-range notes/controls; identical seed/config yields identical normalized events; a different seed changes at least one permitted motif/variation choice while preserving anchors. Phase 1 spans 56 beats; MVP spans 224 beats.
3. **Voice/routing:** short solo NRT checks exercise drums, folk, upper bass, sub, and cross processor. Each active voice produces finite nonzero output and frees as designed. Sub contribution is identical in both channels; bass/cross processing cannot enter the sub's dedicated dry route. Cross mix zero bypasses its contribution; nonzero mix audibly/spectrally changes output without runaway level.
4. **Phase 1 audio:** render the complete 16-bar plan, approximately **26 seconds including tail** at 140 BPM. Check file channels/rate/format, frame count within one server block of the documented render timeline, nonzero active sections, finite samples, and peak amplitude at or below **0.72**. Listen for anchors, an identifiable motif, and an intentional drop; do not accept only a test tone or open port.
5. **Lifecycle:** complete at least ten start/stop cycles without increasing owned node/bus/scheduler counts; double start/stop is safe; server errors reset useful state; shutdown touches only owned resources. Automated dummy-backend checks are separate from a physical-output listening check.
6. **MVP composition/export:** default 64 bars plus tail renders to approximately **98 seconds**. Different sections change intended lane activity and bass energy; the break removes the full drop texture. Two fresh NRT renders with the same seed/config have identical event plans and decoded PCM on the pinned runtime, or the gate reports the diagnosed audio reproducibility blocker. Compare PCM, not WAV header bytes. Export must not silently overwrite an existing file.
7. **Qt MVP:** every required widget maps to a validated public operation; generation/tempo updates apply at the next bar, seed changes are rejected while playing, export completion/error appears, and closing the window cleans up. Perform one desktop interaction/listening pass; offscreen tests alone do not pass this gate.
8. **Performance:** on a documented device/backend, run a full 96-second arrangement at the selected sample rate with no audio underruns or node leaks. Record server CPU and peak voice count; initially aim below 50% average/70% peak server CPU. NRT render success does not establish real-time performance. If the cloud has no device, report physical audio/interactive GUI checks as outstanding rather than passing them.

Required failures block their gate. Separate environment limitations (missing SC, audio/display backend) from application failures (bad scheduling, clipping, leaks). Tests belong to the current run and must inspect its newly generated output, not a stale WAV.

### Six incremental milestones

These milestones group the existing backlog and detailed gates without introducing additional development stages. Commands refer to the future test entry points above and must report real assertions and failure exit codes.

| Milestone | Backlog items | Executable acceptance |
| --- | --- | --- |
| M1 — Runtime and config | 1–2 | `sclang -v`, `scsynth -v`, and `QT_QPA_PLATFORM=offscreen timeout 60s sclang -D tests/unit.scd`; matching 3.14.x versions, gate 1's setup-tone render, and passing config/timing assertions. |
| M2 — Deterministic composition plan | 3–4 | Rerun `tests/unit.scd` with the command above; gate 2's grid, seed, scene, register, and event-order assertions pass. |
| M3 — Owned graph and voices | 5–8 | `QT_QPA_PLATFORM=offscreen timeout 180s sclang -D tests/nrt_smoke.scd`; its implemented solo-voice/routing cases pass gate 3, including finite output and mono sub. The composition cases are introduced at M4, not counted as passed at M3. |
| M4 — Audible Phase 1 | 9–10 | Run `tests/nrt_smoke.scd` and `QT_QPA_PLATFORM=offscreen timeout 90s sclang -D tests/lifecycle.scd`; gates 4–5 pass for the 26-second sketch and repeated lifecycle. A real listening check is needed for claims about the first drop's sound. |
| M5 — Full composition, presets, export | 11–13 | Run `tests/unit.scd`, `tests/nrt_smoke.scd`, and `tests/lifecycle.scd` with their documented commands; gate 6 plus preset validation, contrasting call/reply events, and bar-boundary control/tempo assertions pass. |
| M6 — Qt instrument and delivery | 14–15 | `QT_QPA_PLATFORM=offscreen timeout 60s sclang -D tests/gui_smoke.scd`, then `sclang main.scd` on a suitable desktop; gates 7–8 pass, setup is reproducible, and all failed/unavailable checks are reported. |

If a backend is unavailable, complete independent checks and report that part of the milestone as blocked; do not certify the whole milestone from its offline subset.

## 10. Ordered implementation backlog for a cheaper model

Each item should fit one focused implementation turn. Read this plan plus only relevant files; avoid rereading the entire repository. State exact touched files and run the item's check. Stop expanding scope once that check passes. Preserve earlier contracts and write a brief progress entry after each gate. Do not repeatedly rerun audio/GUI suites for documentation-only edits.

| Order | Task and constrained deliverable | Depends on | Completion check |
| --- | --- | --- | --- |
| 1 | Establish and document pinned SC 3.14.x installation; verify Qt headless compilation and native NRT capability. No music modules yet. | None | Runtime gate 1; document exact commands/version/backend. |
| 2 | Add `config`, pure timing helpers, test harness, and ignore rules. | 1 | Bounds rejected; timing assertions pass with positive count. |
| 3 | Add fixed Phase 1/MVP scene data, motif/harmonic generation, and independent seed derivation. | 2 | Same seed/phrase data matches; alternate seed varies permitted choices; registers and 64-bar totals valid. |
| 4 | Add the pure event compiler in `sequencer`; export a normalized plan for tests, without audio playback yet. | 3 | Gate 2, including snare positions and cross-bar ostinato phase. |
| 5 | Add lifecycle/routing and minimal master protection, with ownership tracking. | 2 | Prepare twice; cleanup twice; graph resources return to baseline. |
| 6 | Add kick/snare/hats and isolated NRT voice checks. | 5 | Nonzero finite percussion output, protected peaks, bounded envelopes. |
| 7 | Add upper-bass/sub SynthDefs; start with one safe FM/wobble patch, then blend reese. | 5 | Finite output at parameter bounds; sub L/R match; upper/sub separation checked and listened to. |
| 8 | Add the first folk voice and ring-modulation processor. | 5, 7 | Motif voice and cross mix gates; source routing order validated. |
| 9 | Add shared offline renderer and native SoundFile checks; render the full 16-bar plan. | 4, 6–8 | Gate 4, correct completed WAV and failure exit status. **Phase 1 offline checkpoint.** |
| 10 | Add real-time scheduling/public app assembly and launcher; use the same plan and graph. | 9 | Prepare/play/stop/restart, dummy-backend signal and ten-cycle gate 5; device listening where available. **Phase 1 playback checkpoint.** |
| 11 | Add kick ducking, conservative ambience and section transitions; wire the 64-bar arrangement with growl/metallic-reese call-and-response. | 10 | Full arrangement/render and transition checks; contrasting answer events preserve anchors and stable levels. |
| 12 | Verify server-side RNG, same-runtime repeated PCM export, unique filenames, and error propagation. | 11 | Gate 6; document any genuine nondeterministic source rather than hiding it. |
| 13 | Add validated live-control staging/status and the two data-only factory presets without GUI. | 10–12 | Mid-bar updates commit at next bar; invalid values rejected; one master clock survives tempo change; preset resolution/selection checks pass. |
| 14 | Add small native Qt panel, including factory preset selection, using existing API only. | 13 | Gate 7 headless callbacks/cleanup, then desktop interaction where available. |
| 15 | Write short README/setup steps; validate full arrangement CPU/resources; save reusable cloud startup/setup instructions after testing. | 14 | Gate 8 plus final tracked/untracked diff review. **Full MVP checkpoint.** |

For implementation prompts, use: “Implement backlog item N only. Read docs/PLAN.md and the named relevant files. Preserve public contracts. Run its acceptance check; report changed files, test outcome, and any concrete blocker. Do not start item N+1.” This template is guidance for the next phase, not permission to implement now.

## 11. Roadmap after MVP

| Phase | Goal | Acceptance before proceeding |
| --- | --- | --- |
| 1 | Audible 7/8 kernel: 16-bar plan, synthesized voices, ring modulation, playback, WAV | Backlog 1–10; distinguish offline success from physical listening. |
| 2 | Full MVP: 64-bar composition, bounded generative changes, polished FX, Qt controls, deterministic export | Backlog 11–15; a usable default composition and all required gates. |
| 3 | Alien spectral laboratory | One stock FFT cross-synth algorithm with A/B bypass, level normalization, measured latency/CPU, and no resource leak. |
| 4 | Deeper folk and sequencing | More motifs, five-step overlays, optional tuning systems, richer phrase grammar, explicit musical provenance for any borrowed material; deterministic plans remain intact. |
| 5 | Performance GUI and export workflow | Presets, automation capture/live recording, visual arrangement controls, optional MIDI/OSC; maintain headless export and thin UI separation. |

## 12. Risks and decisions

| Risk | Response / evidence needed |
| --- | --- |
| Empty repository and missing `main` | Do not assume existing tests or source. Initial application code/commits belong to the subsequent implementation task, not this planning pass. |
| Requested 3.14.x unavailable in default package sources | Confirm official release availability and a compatible trusted installation route before implementation. Report the precise installation blocker; do not silently downgrade. |
| Cloud has no audio device/display | Make NRT export a first-class workflow. Add dummy/virtual display only as needed; defer physical listening and interactive usability to a suitable host. |
| 7/8 versus conventional halftime expectations | Keep explicit quarter-note BPM, fifth-eighth snare, and 2+2+3 identity. Optional conventional 4/4 mode comes later, rather than weakening the default meter. |
| Aggressive synthesis creates aliasing, clipping, or fatigue | Bounded ratios/index/drive, upper-band processing, finite-sample/peak checks, conservative mix, and human listening. Revisit quality before adding more algorithms. |
| GUI/clock changes alter random results | Pure event compilation, independent seed streams, queued controls, and no random choices inside widgets. |
| Server noise/random UGens break PCM reproducibility | Seed and test on the pinned runtime, use a fresh NRT server and stable node order; diagnose specific offending voices. Event determinism alone does not pass the audio-repeatability gate. |
| Two render/playback paths drift | Share config, SynthDefs, routing specification, arrangement, and event compiler; only transport and time conversion differ. |
| Resource leaks or duplicate playback | Owned resources, explicit states, idempotent methods, voice caps and repeated lifecycle checks. |
| SC asynchronous definition loading and node execution order | Await completion/sync before scheduling dependent voices; explicit ordered groups and bus channel counts prevent missing SynthDefs, stale reads, and accidental channel expansion. Mirror initialization in the NRT score. |
| SC clock/thread context | Create/update Qt widgets on the supported application/UI context; keep musical scheduling on the owned TempoClock. Convert quarter-note BPM to beats per second and pass beat-based note duration to server envelopes in seconds. Keep language random state scoped to generation. |
| SC cleanup and language/server divergence | Envelope done actions release transient nodes; bounded completion waits and server-loss handling repair runtime state. Stop owned players/responders/tasks before freeing referenced buses; never use global node/clock resets. |
| SC syntax/load errors mistaken for DSP validation | Compile/evaluate relevant modules in the pinned `sclang`, then boot/test SynthDefs in `scsynth`. There is no generic syntax-only linter to replace these checks. |
| Scope outruns limited Codex usage | Finish the audible kernel first; no GUI, FFT, plugins, or broad framework work until their scheduled gate. Keep tasks and reports narrow; use one relevant test suite per task. |

The minimal eight-bar audio slice is implemented in the files listed above. The larger 16-bar Phase 1 and 64-bar MVP, reusable rendering, GUI, installation, SuperCollider execution, and listening checks remain future work or require a SuperCollider-capable host.
