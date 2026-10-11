# BALKAN//BASS application audit

Historical audit of the earlier 7/8 app. The current user-approved groove is
4/4; timing findings below do not describe the current sequencer.

Date: 2026-10-11. Target: stock SuperCollider 3.14.1 on macOS.

## Scope, evidence, and actual feature inventory

Read all six existing Markdown documents and inspected all ten application `.scd` files. This audit changes only this document. The current authorized product is the personal Quick MVP described at the beginning of PLAN.md.

The source contains synthesized kick/snare/hat, a combined FM/reese growl, mono sub, an eight-bar event generator and transport, a protected stereo master, native Qt controls, and two in-memory factory character presets. It does **not** contain WAV export, preset persistence, an offline playback path, a separate FX module, or intro/buildup/drop/breakdown arrangement. Those are deliberate deferrals, not broken implemented features. The call/reply distinction is a fixed first-four/last-four-bar bass parameter change. Do not start implementing absent features as audit remediation.

`sclang`, `scsynth`, and `supernova` are unavailable on PATH; no executable was found in the searched workspace. `/dev/snd` is absent. The workspace search encountered an inaccessible daemon directory in `/tmp`; it is not evidence of an application failure. No SuperCollider installation or cloud audio stack was attempted in this audit.

For API checks, inspected the official `Version-3.14.1` source archive: all 352 stock class-library `.sc` files were searched for a `Random` class declaration. Also inspected Server.sc, ServerStatus.sc, Thread.sc, Object.sc, NumberBox, Kernel.sc, Bus.sc, Integer documentation, and the lexer/math/Phasor implementation. This is source-reference verification, not compilation or execution.

Reference sources: [official tagged archive](https://codeload.github.com/supercollider/supercollider/tar.gz/refs/tags/Version-3.14.1), [Server.sc](https://github.com/supercollider/supercollider/blob/Version-3.14.1/SCClassLibrary/Common/Control/Server.sc), [ServerStatus.sc](https://github.com/supercollider/supercollider/blob/Version-3.14.1/SCClassLibrary/Common/Control/ServerStatus.sc), [Thread.sc](https://github.com/supercollider/supercollider/blob/Version-3.14.1/SCClassLibrary/Common/Core/Thread.sc), [Integer](https://github.com/supercollider/supercollider/blob/Version-3.14.1/HelpSource/Classes/Integer.schelp).

| Check performed | Result and limits |
| --- | --- |
| Source/docs inventory and full inspection | Completed; existing implementation and historical findings reconciled. |
| Stock 3.14.1 API/source comparison | Confirmed the unsupported RNG class and incorrect boot-waiter handle below. |
| Ephemeral Python whitespace/conflict scan over ten `.scd` files | No trailing whitespace or conflict markers. This does not parse SuperCollider. |
| Timing, hat predicate, master-gain and envelope-spacing arithmetic | Results below. These are static calculations, not execution of the SC generator. |
| Language/class-library/SynthDef compilation | Unavailable: no `sclang`. |
| Server boot, GUI, lifecycle, timing/jitter and CPU measurements | Unavailable: no matching runtime; no physical audio device. |
| Automated audio checks/render/export comparison | Unavailable: no server or render implementation; no fresh audio artifact was produced. |
| Listening | Not performed. No perceptual quality conclusion. |

All project files are currently untracked in this checkout. Therefore `git diff --check` alone would inspect no application changes; earlier whitespace-pass statements do not establish compilation or comprehensive source checking.

## 1. Critical defects

### C1 — Unsupported `Random` class prevents the sequencer from compiling

**Confirmed static defect.** `src/sequencer.scd:5` calls `Random.new(app[\seed])`, followed by `rng.next`. Stock SuperCollider 3.14.1 has no `Random` class; the full stock class-source search found no declaration. Randomness is supplied by Thread RNG state and functions such as `rand`, or native random patterns.

`main.scd:43` interprets this module and `main.scd:69` invokes its result. An undefined class prevents that module from compiling. Module loading does not validate the returned type, so the error can also leave missing sequencer operations instead of a useful launch failure. This conclusion is supported by official source, but an actual compiler error has **not** been captured here. The previous claim that a per-generation `Random` object was implemented was incorrect.

**Minimal fix:** replace this unsupported RNG usage within the generator. Use a temporary Routine with its own `thisThread.randSeed`, yield the completed event array, and consume it synchronously; this scopes musical RNG state without changing unrelated caller state. Do not build a custom RNG framework. Check the sequencer module returns a Function and report a failed load before constructing the app.

## 2. High-priority problems

### H1 — Boot cancellation stores a Server, not a waiter Routine

**Confirmed static API defect.** `src/lifecycle.scd:17` assigns the result of `server.waitForBoot` to `app[\bootWaiter]`. In 3.14.1, Server.waitForBoot returns its receiver; the actual polling Routine is created by ServerStatusWatcher.doWhenBooted. Server inherits Object.stop, which is a no-op. Thus the `.tryPerform(\stop)` calls at lines 77 and 96 do not cancel that polling Routine.

The official polling loop also does not enforce its `limit` argument. A failed boot can leave a polling Routine running after the 30-second watchdog or shutdown. A late completion from an old attempt can clear/stop the current app's watchdog and waiter fields because lines 18–20 run **before** checking the attempt token. Repeated attempts can accumulate waiters and interfere with each other.

**Minimal fix:** retain a genuinely owned, bounded wait Routine; start the server only when neither running nor already booting. Check the attempt token before modifying any shared handles. Timeout/shutdown must stop the actual owned waiter and invalidate its token, while preserving externally owned servers.

### H2 — Preparation can resume after shutdown; partial failures are not rolled back

**Confirmed control-flow defect; manifestation unexecuted.** The boot callback checks `bootId` once at `src/lifecycle.scd:22`, then yields at `server.sync` on lines 29 and 38. Shutdown can occur during either yield. The resumed callback does not recheck its token and can allocate a new graph or mark a closed app ready. This is especially consequential when attached to an external server, which shutdown correctly leaves running.

The watchdog is stopped before definition loading and graph preparation, so it does not bound those sync waits. The catch at lines 43–47 reports failure without freeing partially allocated resources. A retry can overwrite their handles.

**Minimal fix:** recheck the attempt token after every asynchronous wait and before publishing ready state. Keep cleanup handles until completion, free partial owned allocations on failure/cancellation, and bound preparation as well as initial boot. Keep the waiter reachable until preparation is complete. Avoid graph allocation after cancellation.

### H3 — Defaults changes displayed settings that playback rejects

**Confirmed static GUI/API defect.** The generation controls are disabled while playing, but Defaults is not disabled (`src/gui.scd:176–191, 201–213`). Its callback changes the seed, Density, Variation and preset widgets. Their engine operations correctly reject generation/preset changes during playing/stopping (`src/controls.scd:37–61`, `main.scd:73`). The widgets are not restored after rejection.

Consequently, the displayed seed/settings can disagree with the engine. After Stop, Generate reads the engine's values, not those shown in the GUI. Defaults also resets bass macros while retaining a rejected preset identity.

**Minimal fix:** disable Defaults during playing/stopping alongside generation controls. Restore all displayed defaults only after the engine accepts them. Retain live macro/BPM/master control behavior.

### H4 — Server failure and server-side initialization errors do not repair state

**Confirmed missing error-handling paths; no failure injection performed.** No owned server-loss or relevant `/fail` handling is installed. A server quit/crash can leave the app ready or playing; `src/sequencer.scd:106–118` trusts state and handles without checking a running, prepared server. SynthDef/node command errors are server replies, not language exceptions: `server.sync` synchronizes commands but does not certify their success, so the existing `try` is insufficient for those failures.

**Minimal fix:** add narrowly scoped, owned error/server-loss handling that cancels transport, invalidates graph handles and sets a useful failed state. Observe registration/graph failures before declaring ready. Free any owned handlers on shutdown. Verify recovery by closing/relaunching before adding a retry feature.

### H5 — The hat-density branch never changes the hat pattern

**Confirmed static logic defect.** `src/sequencer.scd:26` already enables hats at every step except step 6 of odd bars. Lines 34–35 conditionally set hats true at steps 1, 3 and 5, all of which are already true in every bar. There are always **52 hats per loop**, regardless of seed or Density. Density still affects optional bass omissions; the entire control is not inert.

**Minimal fix:** make these off-accent hat positions genuinely optional before the density decision, preserving step 0/2/4 accents and the deliberate ending gaps. Keep kick/snare anchors unchanged. No additional drum voice or scheduler is needed.

### H6 — New Seed performs unsafe 32-bit integer operations

**Confirmed numeric-range defect; exact runtime symptom unverified.** `src/gui.scd:172` converts elapsed microseconds to Integer **before** applying modulo, and uses the integer literal `2147483648`, outside SC's signed 32-bit Integer range. The official lexer parses integer literals through `atoi`; Integer overflow behavior is documented as undefined. Elapsed microseconds exceed the signed range after **2147.483647 seconds**, approximately 35.8 minutes.

This can produce a rejected seed or a widget/engine mismatch during an ordinary evening session. Do not assert a particular overflow result without running the target runtime.

**Minimal fix:** keep elapsed-time multiplication and modulo in Float arithmetic, using a Float modulus, and convert only the final bounded value to Integer. Update the seed display only after the setter accepts it.

## 3. Performance improvements

No CPU, memory, underrun or peak-node measurements were possible. No evidence currently justifies DSP optimization or a new allocator.

- The current graph is small: no buffers, FFT, delay network or inactive bass-family graphs. Transient voices have finite doneActions. Fix the abandoned boot waiters before considering performance tuning.
- Playback sends separate immediate OSC messages for each voice (`src/sequencer.scd:121–160`). Their beat positions are coherent, but they are not scheduled with server timestamps and shared lookahead. Network/language jitter and within-step skew remain unmeasured. If local playback exhibits timing problems, bundle all lanes of a step together using one latency policy; do not add latency to bass alone.
- Density/Variation setters regenerate all 56 cells on every slider action. This is bounded and likely inexpensive; measure UI responsiveness before debouncing or adding asynchronous generation.
- Current growl durations permit short intentional overlaps, normally up to two simultaneous growls within 120–160 BPM. The sub lane does not overlap itself. An explicit general-purpose voice cap is unnecessary for this fixed loop unless runtime measurements contradict these bounds.

## 4. Lower-priority improvements and unverified audio risks

### Confirmed smaller issues

- **L1 — Sub safety contract is incomplete:** `src/synthdefs/bass.scd:2–5` does not bound sub frequency, amplitude or decay as BASS_DESIGN specifies (30–90 Hz, 0–0.25, 0.04–0.30 s). Current sequencer values are safe and finite. Add those clamps for direct/reused calls; do not redesign its clean mono path. The drums and master also trust creation inputs, but current callers provide conservative constants/bounded gains.
- **L2 — Direct shutdown leaves the GUI/task open:** `src/lifecycle.scd:90–119` stops audio resources but does not close the window or stop its locally captured refresh Routine. Re-evaluating main while that window is open only fronts it. Window-close cleanup works by design; public shutdown/relaunch semantics need clarification or a small coordinated close operation.
- **L3 — Preset/control display synchronization:** preset selection directly copies data without validating every macro; current two presets contain valid bounds. Changing macros does not mark the preset as modified. External API changes are not reflected by the polling task, which only refreshes status/enabled states. These are small consistency issues, not a need for preset serialization.
- **L4 — Public generator has no playback-state guard:** GUI Generate is disabled in playback, but code can call `generatePlan` while playing and replace the next loop's plan. Its returned Array is only shallow-copied, so caller mutation can affect stored cell Dictionaries. Guard public generation and document/read-protect returned data if external callers will use it.
- **L5 — Historical/roadmap text is easy to misread:** PLAN's final paragraph still calls GUI future work; PHASE2_VALIDATION includes historical autostart/no-grouping statements, followed by later corrections. Keep history, but add current-status pointers when next editing docs. Planned absent test commands and `git diff --check` do not verify this untracked application.

### Audio/runtime risks requiring measurement or listening

| Area | Static evidence and practical limit |
| --- | --- |
| Gain/clipping/transients | Master is LeakDC → Limiter(0.68, 10 ms parameter) → smoothed gain. For finite signals and settled controls, the mathematical post-limiter ceiling is about 0.1708 at -12 dB and 0.3408 at the GUI maximum -6 dB. These are not measured peaks or a nonfinite-signal guarantee. Filter overshoot and actual limiter activity remain unknown. |
| Aliasing | Native Saw is band-limited; FM sidebands and tanh can still generate aliased content. Pre/post filtering does not prove freedom from folded artifacts. Inspect/listen before lowering bandwidth or adding expensive oversampling. |
| DC/resonance/distortion | Growl and master have LeakDC; rq is bounded 0.25–0.8; drive is 1–4 with tanh normalization. No recursive feedback loop or unbounded gain chain was found. Finite output, actual DC, peak and RMS remain unmeasured. |
| Stereo/mono | Sub duplicates a single signal to L/R. Growl uses a centered mid plus/minus a high-passed side; width=0 removes the side algebraically. Sample equality and mono-collapse behavior have not been rendered or heard. |
| Low-frequency separation | Growl has two final 150 Hz HPFs after distortion; sub is a dry low-passed sine. This is conservative topology, not measured rejection. Current voices share one stereo mix bus, so a later bus distortion processor must not process the sub. |
| Kick/sub timing | Sub lifetime is nominally 0.194 s. At 140 BPM there is a 20.286 ms nominal gap before an adjacent kick. At 160 BPM the spacing is 187.5 ms, allowing **6.5 ms of envelope overlap**. This is not evidence of excessive masking. Shorten sub decay relative to spacing only if needed after listening. |
| Harmony | Sub roots and upper-bass pitches come from separate fixed arrays; Variation selects upper pitches independently. A shared harmonic relation is not enforced. Some combinations may sound intentional or dissonant; listening is required before altering pitches. |
| Phase/envelopes | Control-rate cyclic phase and finite motion contours are distinct from audio-rate FM/amplitude envelopes. Initial Phasor/Impulse phase, smoothing and early gate release need runtime checks. Creation-only parameters are ordinary Synth controls but current playback never updates them. |
| Stop/close | Stop cancels its routine, fades for 75 ms, then frees owned voices/clock. Shutdown frees immediately; close can click. Moving master during stopping can override its fade. Rapid close/relaunch can race asynchronous server quit. None of these have been reproduced here. |
| Emergency stop | CmdPeriod behavior is not integrated with app state/GUI task recovery. Check Command+. locally before claiming reliable emergency-stop recovery. |

Preset persistence, export format/completion, offline determinism, and real-time/offline parity are **not applicable to implemented functionality**. Event repeatability is blocked by C1; even after correction, WhiteNoise drums are not seeded for identical PCM. Do not infer audio repeatability from a repeatable event plan.

## 5. Suggested minimal fixes

Use this order and keep each correction focused. No new framework or application feature is required.

| Order | Issue | Files / smallest intended correction |
| --- | --- | --- |
| 1 | C1 | `sequencer.scd`: supported scoped Thread RNG; `main.scd`: fail clearly on an invalid sequencer module result. |
| 2 | H1/H2 | `lifecycle.scd`: actual bounded owned waiter, token checks after waits, watchdog through preparation, rollback partial owned resources. These related lifecycle fixes should be reviewed together. |
| 3 | H3/H6 | `gui.scd`: lock Defaults while playing/stopping; bound Float seed arithmetic before Integer conversion; accept before publishing a display change. |
| 4 | H5 | `sequencer.scd`: genuinely optional off-accent hats. |
| 5 | H4 | `lifecycle.scd` and minimal transport guards: server failure/error state, owned handler cleanup, avoid false ready state. |
| 6 | L1/L2 | Bound sub creation controls; coordinate public shutdown with the owned GUI/task. |

Leave subjective timbre tuning, sample-accurate scheduling improvements, disk presets, export and broader arrangement out of the first remediation pass.

## 6. Reproduction steps and validation criteria

The following are **local checks to run**, not results already obtained. No formal test runners were added. Use the user's SuperCollider 3.14.1 IDE on macOS; open `main.scd`, select the whole file and evaluate with Command+Return. Keep an eye on the Post Window.

| Issue/check | Reproduction or procedure | Acceptance after a fix |
| --- | --- | --- |
| C1 | On stock 3.14.1 evaluate `\Random.asClass.postln;` and interpret the sequencer module or launch main. | Before fix: missing class. After fix: all modules evaluate, sequencer returns Function, default plan has 56 cells and GUI reaches usable Ready/Play. Actual compiler/server logs contain no errors. |
| Seeded generation | Generate twice with the same seed/Density/Variation; compare canonical cell fields and nested bass parameters in stable order. Change seed with Variation above zero. Save `thisThread.randData.copy` before generation and compare afterwards. | Identical settings produce identical event data; a different seed changes a permitted choice; caller RNG state is preserved. No PCM equality claim. |
| H1 | On a running server inspect `s.waitForBoot({}).class`; separately exercise failed boot/timeout, close, then retry with a diagnostic waiter count. | API returns Server, not a Routine. Corrected app has no polling waiter/watchdog after ready/failure/close; an old attempt cannot alter a new one. |
| H2 | With an externally booted server, close/shutdown during definition/graph sync, using a diagnostic delay if necessary. Also induce an initialization failure in an isolated diagnostic copy. | No graph/state resurrection after close. Partial allocations and owned callbacks return to baseline; unrelated server/node survives. |
| H3 | Stopped: set seed 999, Density 0.2, Variation 0.8 and Reese Reply; Play; try Defaults; Stop; Generate. Compare `status` and widgets. | Defaults is disabled during playing/stopping, or rejected changes leave every display unchanged. Displayed seed/preset/settings match engine state. |
| H4 | Use a separate test server; quit it during playback. Restart, close/relaunch; inspect initialization failures in Post Window. | Transport cancels, state reports failure, owned handlers/resources clean up, recovery works; no false playing/ready state or continuing event sends. |
| H5 | Inspect hat flags for a small fixed seed set at Density 0 and 1. Current predicate arithmetic yields 52 hats in both cases. | Density changes permitted hat flags for the chosen fixtures; step 0/2/4 hats and kick/snare anchors remain. |
| H6 | Evaluate the corrected seed calculation with synthetic elapsed times 2147, 2148 and 7200 seconds instead of waiting. | Each result is an Integer in 0–2147483647; setter accepts it; display matches engine. No out-of-range integer literal or pre-modulo conversion. |
| Lifecycle | After startup repairs, Play/Stop three times, double-Play, close while playing, and reopen after server quit completes. Exercise direct shutdown too. | One owned transport/graph; stop returns to prepared baseline; close/shutdown return to original resource baseline; unrelated nodes/clocks survive. Extend to ten cycles only if investigating a leak. |
| Timing/sections | Observe seven eighth steps/bar and fills at bars 3/7. At 140 BPM, time multiple complete cycles. Change BPM during a bar. | Static grid remains 3.5 beats/bar and 28 beats/loop; nominal loop 12 s. Tempo commits at next explicit bar boundary; no missing/duplicated anchor. Measure jitter separately from loop arithmetic. |
| Audio/controls | Once compiled, listen briefly on the Mac and move each macro, master and BPM; check short-note automatic freeing and early gate release on an owned growl handle. | Controls work, voice counts settle, sub remains centered. Report actual listener/actions; do not equate successful startup with sound quality. |
| Objective audio, if desired | Make a fresh local capture using existing SC recording tools; inspect SoundFile samples for finite/nonzero data, peaks, DC and width-zero channel equality. This is diagnostic recording, not an export feature. | Record artifact, duration, measured values and any error. Absence of capture remains unverified, not passed. Do not install a new audio-analysis stack for this personal MVP. |

Arithmetic actually checked here: one bar is 1.75/1.5/1.3125 s at 120/140/160 BPM; eight bars are 14/12/10.5 s. Every ordinary cell waits 0.5 quarter beats, and a fill cell waits 0.25 + 0.25, so fills do not change cycle length. Group cycles are 1/1/1.5 quarter beats and offsets derive from 2+2+3 group boundaries. Snare anchor remains step 4, kick anchor step 0, and pending tempo commits after step 6.

## 7. Prioritized remediation plan

1. **Restore launch/generation:** fix C1 and compile the modules locally before judging any musical behavior. This is the immediate blocker to a usable app.
2. **Make close/start safe:** correct H1/H2 together; then do the short owned-resource/lifecycle check on the Mac.
3. **Restore trustworthy controls:** fix H3/H6 and H5; perform the focused seed/preset/default/hat checks.
4. **Handle failures:** fix H4 and the small sub/public-shutdown contract gaps when the happy path is functioning.
5. **Listen and stop:** run the normal play/tweak/stop flow. Tune only a demonstrated problem. Production profiling, complex architecture, export and additional bass engines remain outside this remediation scope.

## Remediation pass — 2026-10-11

This pass made focused source edits only. It did not add a test framework or modify SynthDefs/audio design.

| Finding | Source change | Current evidence |
| --- | --- | --- |
| C1 | The sequencer now uses a temporary Routine seeded through thisThread.randSeed, and keeps random draws inside that Routine. The launcher rejects a sequencer module result that is not a Function. | Official 3.14.1 API reference supports randSeed and Routine; source statically reviewed. Compile and event repeatability remain unverified without sclang. |
| H1/H2 | Lifecycle now owns the polling Routine and a 30-second deadline through graph setup, waits for server boot notification, checks the attempt token after each sync, and releases allocations belonging to a cancelled/failed attempt. Shutdown stops the owned waiter/deadline and frees the client bus allocator entry even if the server is down. | Control flow statically reviewed against tagged 3.14.1 sources. Boot timeout, late sync, attached-server cleanup, and races remain unverified. |
| H3 | The GUI disables Defaults unless the app is ready, like the generation controls. | Callback/state mapping statically reviewed; widget behavior unverified. |
| H5 | The sequencer keeps hats on steps 0/2/4 and eligible step 6, while seeded Density controls off-accent steps 1/3/5. | Predicate arithmetic says off-accent hats are absent at Density 0 and present at Density 1. Plan generation has not executed. |
| H6 | The GUI keeps elapsed-time arithmetic in Float, takes a modulo by 2147483648.0, then converts the bounded result; the field updates only if the seed setter accepts it. | Range statically bounded to 0–2147483647. SC conversion/widget behavior unverified. |
| H4 | Lifecycle polls for a stopped/unresponsive server; the sequencer checks server health before starting. An ineffective /fail listener was removed after checking the stock 3.14.1 server source. | Source only; server-loss handling and state recovery remain unverified. Stock /fail for /s_new contains command and reason, without the attempted synth name or target group, so shared-server failures cannot be safely attributed to this app by those fields. Asynchronous /d_recv and master creation failures are likewise not reliably detected during preparation. H4 remains open pending a local runtime check. |

No regression script was added: this checkout has no test runner, sclang/scsynth are unavailable, and an unexecutable SuperCollider test would add a second unverified artifact. The reproducible local checks in section 6 are the regression checklist for this pass. A delimiter/whitespace scan is not compilation.

Checks in this pass: command -v sclang, scsynth, and supernova found none; /dev/snd is absent; an ephemeral scanner found no trailing whitespace or conflict markers in the ten .scd files. No compiler, server, GUI, audio render, sample measurement, or listening test ran. Application state after edits remains unverified.

Conclusion: the prior blocking RNG call and the noted deterministic GUI/hat defects have focused source corrections, with no runtime evidence yet. Boot/lifecycle corrections and server-error handling also require SuperCollider 3.14.1 verification before this MVP can be called stabilized.
