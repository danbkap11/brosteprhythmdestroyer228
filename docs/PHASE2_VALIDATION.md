# Phase 2 Validation Audit

Date: 2026-10-11

## Scope and result

This is a focused static audit of `main.scd` and the Phase 2 modules listed below against the approved architecture in `docs/PLAN.md`. The environment does not contain `sclang`, `scsynth`, `supernova`, `jackd`, `pw-jack`, or `/dev/snd`. Therefore no SuperCollider compilation, server boot, execution, audio rendering, or listening test was performed. Static checks are not substitutes for those tests.

Audited files: `main.scd`, `src/config.scd`, `src/lifecycle.scd`, `src/routing.scd`, `src/sequencer.scd`, `src/synthdefs/drums.scd`, and `src/synthdefs/bass.scd`.

Two boot-path defects found during review were corrected in `src/lifecycle.scd`: SynthDefs are now sent only to the selected server instead of all booted servers, and boot uses the supported `waitForBoot` argument order without starting a second boot first. An explicit 30-second watchdog handles a timeout because the 3.14.1 `waitForBoot` polling implementation does not enforce its documented limit. These corrections have only been inspected statically; they have not been executed here.

A lightweight source-structure check found balanced delimiters/comments/strings, no trailing whitespace, and all expected source files present. It is not a SuperCollider parser or syntax check.

## Findings

### Language, UGens, and routing

The SynthDefs use standard SuperCollider UGens (`SinOsc`, `WhiteNoise`, `HPF`, `BPF`, `LPF`, `LFTri`, `Saw`, `RLPF`, `LeakDC`, and `Limiter`) and ordinary language constructs. Static inspection found no confirmed malformed UGen calls or obvious variable-declaration/scope errors. Only `sclang` can establish that the installed class library parses and compiles these files.

Voice Synths write to the allocated stereo audio mix bus. A voice group is placed at the server root head, and the master Synth is placed at the root tail, so the master reads the bus after voice nodes execute. The master reads two channels, applies DC removal and a lookahead limiter, then writes stereo to hardware outputs 0/1. This is a simple, coherent signal path. Device channel availability and actual limiter behavior remain untested.

### Meter and phrase timing

The sequencer iterates seven steps per bar and waits 0.5 quarter-note beats per step at `TempoClock.new(140 / 60)`. That yields 3.5 quarter-note beats per bar, i.e. 7/8, with an eighth-note duration of `60 / 140 / 2` = about 0.214286 seconds. Eight bars take `8 * 7 * 0.5 * 60 / 140` = exactly 12 seconds mathematically.

`config[\grouping]` contains `[2, 2, 3]`, but the sequencer does not read that field or explicitly accent those group boundaries. The event grid is valid 7/8; the 2+2+3 grouping currently exists as configuration/documentation rather than an audible sequencing rule. The snare on eighth-step 4 gives a halftime backbeat-like placement once per bar, though it is not a conventional 4/4 halftime backbeat. This is a musical interpretation to confirm by listening, not a timing defect.

### Envelopes, resources, and node cleanup

Kick, snare, hat, sub, and growl each have a main percussive `EnvGen` with `doneAction: 2`, so one-shot voices free themselves after their envelopes. The kick pitch and click envelopes have no doneAction, but are bounded by the kick's freeing amplitude envelope and do not own separate nodes. No indefinitely sustained voice SynthDef was found.

Boot allocates one stereo bus and one voice group, then creates the master node. Shutdown frees voices/group/master/bus when the server is running and quits only a server this application marked as owned. Start is gated on `\ready`; repeated start while `\playing` is ignored. Stop invalidates the current run token, stops its routine, fades the master toward zero, then frees the voice group and clock after 75 ms. Shutdown also invalidates pending run/boot callbacks. These lifecycles look internally consistent under static review; race behavior, server replies, node IDs, and repeated start/stop under load need runtime testing.

The watchdog and boot failure paths are more complex than the ordinary path and remain untested. In particular, confirm locally that boot timeout, a pre-existing external server, shutdown during boot, and a server failure after boot all leave state and owned resources as expected.

### Bass stability and low-frequency overlap

The growl's FM index is clipped to 0–3, the moving filter cutoff is clipped to 280–5200 Hz, the RLPF resonance parameter is 0.32, and the signal is tanh-limited before filtering. These bounds avoid an obvious unbounded-feedback or runaway-control path. They do not prove freedom from aliasing, clipping, or unpleasant resonant peaks. FM sidebands can extend below the nominal bass note, and the growl has no explicit high-pass split from the sub; check its spectrum and level after rendering.

The kick is triggered at steps 0 and 3, with occasional step-6 phrase fills. The sub is triggered only at steps 2 and 5, so no kick and sub are intentionally started on the same eighth step. The sub's 0.19-second decay is shorter than the approximately 0.214-second spacing to the next eighth step, leaving a small nominal gap before the adjacent step-3/step-6 kick. Its low-frequency tail can still overlap a later kick in practice depending on envelope shape and playback response. The kick sweeps into the low range, and the growl can contribute low partials, so the mix cannot be declared clean without measuring/listening to rendered audio.

### Startup assumptions

`main.scd` locates modules relative to `thisProcess.nowExecutingPath`, reads and interprets them, selects `Server.default`, and automatically boots then starts playback. This assumes it is executed as a saved file with a meaningful `nowExecutingPath`, the expected relative files are present, and the default server has a usable audio backend. Loading individual modules from an arbitrary interpreter context is not supported by this entry point. These assumptions are reasonable for launching the project from its root but have not been exercised in `sclang`.

## Runtime validation still required

Run from the project root in an environment with SuperCollider 3.14.x and a configured audio backend:

1. Check installed versions: `sclang -v` and `scsynth -v`.
2. Start the engine and observe language/server output: `sclang main.scd`. Confirm the server reaches ready and playback begins without SynthDef, bus, node, or audio-device errors.
3. In the running interpreter, test transport and cleanup by evaluating, in order: `~balkan[\stop].value;`, `~balkan[\start].value;`, `~balkan[\stop].value;`, then `~balkan[\shutdown].value;`. Wait at least 100 ms after each stop before starting again. Confirm no continuing nodes/voices and that shutdown quits only the application-owned server.
4. Confirm the pattern spans 12 seconds per eight-bar cycle at 140 quarter-note BPM. Check the audible accents for the intended 2+2+3 grouping and confirm the halftime snare feel.
5. Render or capture at least one full cycle, inspect for finite/non-silent samples, clipping, low-frequency buildup, and unintended node accumulation. Listen on speakers/headphones before making any sound-quality claim.

The current Phase 2 entry point does not provide an offline WAV-export command. Audio capture/export validation therefore requires a local recording workflow or a separately approved export milestone; do not treat the static timing calculation as an audio export test.

## Phase 3C runtime baseline attempt

Date: 2026-10-11

### Outcome

Runtime validation remains unavailable. The selected Debian 13 (trixie) environment has no `sclang` or `scsynth` (`sclang -v` and `scsynth -v` both exit 127 with `command not found`), no `/dev/snd`, and no SuperCollider executable found in the workspace. The process is uid 1000, `sudo` is absent, and system package directories are not writable. An isolated APT index refresh under `/tmp/sc-apt` was attempted against the environment's configured Debian snapshot; the HTTPS proxy returned 403 for each InRelease, so no candidate version or installable package could be verified. No build toolchain/development package set for a source build was established. I did not downgrade from the required 3.14.x target or add audio dependencies.

Consequently, none of the following have been verified: matching language/server versions, class-library compilation, module evaluation, SynthDef compilation/registration, server boot, node instantiation/control/release, NRT render, finite/non-silent audio samples, measured low-band rejection/peak/DC, width-zero sample equality, real-time lifecycle, node counts, preservation of external server resources, or listening. Static inspection and arithmetic are not substitutes for these checks.

### Static findings and minimal correction

- The current sequencer advances seven times per bar by 0.5 quarter-note beats on a `TempoClock` at 140 quarter-note BPM. This is 7/8 and the configured 2+2+3 grouping is consumed to select per-step bass contours and offsets. Eight bars equal 28 quarter-note beats and 12 seconds. This confirms the source's timing arithmetic only; scheduler execution/jitter was not measured.
- Kick events occur on steps 0 and 3, with a step-6 phrase fill every fourth bar. Sub events occur on steps 2 and 5, including some steps that also trigger growl. The growl path now has two cascaded 150 Hz high-pass stages after its nonlinear stage, while the sub stays on its separate sine → 90 Hz low-pass path. This is a useful static separation topology, not proof of measured attenuation or absence of low-frequency competition.
- `bbSub` duplicates one mono signal to both output channels. `bbGrowl` computes one centered mid signal and a separate side signal; at `width=0`, the side contribution is zero by construction. Sample equality and actual routing still require render tests.
- One-shot voices use `EnvGen` with `doneAction: 2`; growl also has an early-release ASR envelope with a freeing done action. The sequencer places voices in its application-owned voice group, and stop/shutdown free that group rather than issuing a global server reset. The control-flow intent is reasonable, but release timing, repeated lifecycle behavior, partial boot failure cleanup, and unrelated-node preservation remain runtime risks.
- Comparison with `docs/BASS_DESIGN.md` found confirmed growl contract mismatches: amplitude and macro defaults differed, the cutoff ceiling was 5200 Hz instead of 8000 Hz, and `rq` was not smoothed. `src/synthdefs/bass.scd` now uses the documented growl defaults (`amp=0.16`, macros `0.65/0.65/0.45/0.50/0.35/0.15`, width `0.15`), clamps cutoff to 280–8000 Hz after tone/excursion, and applies the specified 20 ms `rq` smoothing. These restore the design contract but change the default timbre for old calls that omit those arguments; existing argument names and bounds remain compatible. Explicit sequencer macro values are unchanged. The growl's legacy `sync=0` and `wobbleHz` behavior remain as documented for old callers; sequencer events opt into sync.
- No other confirmed syntax, UGen, bus, or lifecycle defect can be established without the SuperCollider compiler/server. In particular, source inspection cannot establish that `Phasor`, envelope construction, or control updates compile and behave as intended on 3.14.x.

### Checks performed

| Check | Result |
| --- | --- |
| `sclang -v` | Unavailable: executable absent, exit 127. |
| `scsynth -v` | Unavailable: executable absent, exit 127. |
| `ls -l /dev/snd` | Unavailable: device path absent. |
| Isolated package metadata refresh | Failed: configured Debian snapshot endpoints returned proxy HTTP 403; no install performed. |
| Timing arithmetic | Passed static calculation: 0.214285714 s/eighth, 1.5 s/bar, 12 s/eight bars at 140 BPM. |
| `git diff --check` | Passed for whitespace/conflict-marker issues only; does not parse SuperCollider. |

### Exact local validation sequence

Use a machine/container with matching SuperCollider 3.14.x `sclang` and `scsynth`. From the repository root:

```sh
sclang -v
scsynth -v
QT_QPA_PLATFORM=offscreen timeout 60s sclang -D tests/unit.scd
QT_QPA_PLATFORM=offscreen timeout 180s sclang -D tests/nrt_smoke.scd
QT_QPA_PLATFORM=offscreen timeout 90s sclang -D tests/lifecycle.scd
```

The three test scripts listed here are planned validation entry points and are not present in this checkout; they must be implemented as assertion-based tests before these commands can pass. Once available, they must report assertion counts and return nonzero on failure. Use NRT for clean sub/growl rendering at default and maximum durations, parameter updates, gate release, finite/nonzero samples, peak/DC and spectrum checks, and width-zero channel comparison. Use a dummy/compatible backend for real-time boot/start/stop/restart/shutdown tests; include a deliberately unrelated server node and verify it survives application cleanup. Compare normalized event timestamps for 7/8, 2+2+3, 12-second cycle, and confirm owned node counts return to baseline. Physical listening remains a separate check on an audio-capable machine.
