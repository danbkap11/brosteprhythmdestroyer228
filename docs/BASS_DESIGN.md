# BALKAN//BASS bass design

Current groove update: the user switched the playable app to 4/4 halftime at
140 quarter-note BPM. The 7/8 sequencing examples below are historical design
notes, not instructions to revert the current app. The bass SynthDefs remain
meter-independent; the app now also registers `bbYoi` as a bounded drop reply.

Status: implementation specification only, 2026-10-11. No application changes, installation, compilation, server execution, render, or listening test are part of this task.

Current implementation note: `bbTalking` was subsequently added in
`src/synthdefs/bass_talking.scd` for the 32-bar GUI arrangement. The remaining
dedicated bass families below are design specifications. The new voice has
not been compiled or listened to in the cloud workspace.

## 1. Baseline and decisions

Read alongside [PLAN.md](PLAN.md), [PHASE2_VALIDATION.md](PHASE2_VALIDATION.md), and root [AGENTS.md](../AGENTS.md). This document specifies the requested next bass work within the approved architecture. It does not authorize GUI, arrangement, FFT, export, or cross-synthesis implementation. The PLAN roadmap labels differ from the conversation's Phase 3; use the requested bass scope, not the phase number, to choose work.

The existing source has a 140 quarter-note BPM TempoClock, seven eighth-note steps per bar, an eight-bar loop, synthesized drums, a sub, and one FM/reese growl. Preserve the grid: one bar is 3.5 quarter beats / 1.5 seconds; eight bars are 28 quarter beats / 12 seconds. Preserve the snare at step 4. The `[2,2,3]` configuration currently does not drive bass modulation or explicit group accents; that is an integration task below, not an already verified behavior.

Phase 2 has not been compiled, executed, rendered, or listened to. `sclang` and `scsynth` are absent in the inspected environment. All observations below describe source, and all acceptance criteria are future checks.

### Existing bass review

| Component | Source observation | Decision |
| --- | --- | --- |
| `bbGrowl` FM | Audio-rate sine modulator at twice the carrier, index clipped 0–3; depth follows a control-rate triangle | Reuse the two-operator core and index bound. Add an envelope contour and beat-derived modulation. Negative instantaneous FM frequencies are phase reversal, not evidence of runaway feedback. |
| Reese layer | Two `Saw` oscillators at 0.995/1.005 times the note frequency, mixed down | Reuse as restrained growl body and starting point for a separate reese. It currently has no actual stereo width. |
| Nonlinearity/filter | Tanh before `RLPF`, cutoff clipped 280–5200 Hz, rq 0.32 | Retain conservative saturation and bounded resonance. Add final low-band rejection after every nonlinear stage; assess peaks and aliasing on audio. |
| Movement | `LFTri.kr` at 2.6 or 4.2 Hz, restarting with each note | These rates are not divisions of 140 BPM. Retain legacy Hz control for compatibility; use beat synchronization in new events. |
| Lifetime | `Env.perc(0.006, dur)` with doneAction 2 | Preserve automatic finite lifetime. Add optional early release for managed voices; no mandatory note-off for one-shots. |
| `bbSub` | Low-passed sine, identical L/R, self-freeing envelope | Retain dry route and existing arguments. Add bounds; no distortion, detuning, widening, or automatic doubling of every mid note. |
| Kick/sub events | Kick at 0/3, occasional 6; sub at 2/5 with 0.19-second decay | Keep schedule. Nominal sub lifetime is 0.194 seconds versus 0.214286-second adjacent-step spacing; audible overlap/masking remain unverified. |
| Application graph | Stereo mix bus, voice group before protected master; voices write to mix bus | Keep graph for first bass implementation. Separation starts inside each mid voice. No new bus system required to introduce a family. |

Recommended result: five independent mid-bass SynthDefs and one clean sub SynthDef, with the same control vocabulary and a short common processing recipe. Select family before Synth creation. Do not construct all algorithms inside one SynthDef and select the output: inactive graphs still consume CPU.

## 2. Modules, interfaces, and integration boundaries

| File | Requested future responsibility |
| --- | --- |
| `src/synthdefs/bass.scd` | Continue returning an Array of SynthDefs containing `bbSub` and `bbGrowl`. Improve incrementally; retain names and existing arguments. |
| `src/synthdefs/bass_talking.scd` | Return only the `bbTalking` SynthDef. |
| `src/synthdefs/bass_reese.scd` | Return only the `bbReese` SynthDef. |
| `src/synthdefs/bass_wobble.scd` | Return only the `bbWobble` SynthDef. |
| `src/synthdefs/bass_screech.scd` | Return only the `bbScreech` SynthDef. |
| `main.scd` | Explicitly load added definitions and append to existing `app[\synthDefs]` Array. Preserve relative-file loading and ownership. |
| `src/sequencer.scd` | Choose one mid family per event; supply beat timing, phase, macros, and bounded accents. Keep drums/sub timing and one owned TempoClock. |
| `src/config.scd` | Only validated bass defaults/limits needed for this task. No serializer or new public application layer. |
| Existing routing/lifecycle | Register on selected server, sync before use, retain cleanup. Add active-voice tracking only for caps/live updates. |

Keep each new family module small. Duplicate a short envelope/output recipe initially rather than introduce hidden loading or a class framework. Factor a pure graph-building helper only if real duplication warrants it and bootstrap dependencies remain explicit.

Existing `~balkan[\start]`, `[\stop]`, `[\shutdown]`, and internal `[\boot]` retain their meanings. No new public setter API is required here. Later PLAN `setControl` support can use these Synth controls. Test live updates directly on an owned node handle first.

Compatibility: existing `bbGrowl` events containing `out`, `freq`, `amp`, `dur`, `wobbleHz`, `fmIndex`, `cutoff` remain valid; existing `bbSub` events containing `out`, `freq`, `amp`, `decay` remain valid. New events opt into sync. Timbre improvements may change sound; compatibility does not mean identical PCM. Preserve registration Array shape and existing stop fade.

## 3. Bass family specifications

All mids use section 6's output chain and section 5's controls. Mix weights are starting constants, not loudness guarantees; acceptance renders determine conservative trims. Avoid random noise before deterministic rendering is established.

| Family / SynthDef | Source and distinctive movement | Initial constants and macro roles |
| --- | --- | --- |
| FM growl / `bbGrowl` | Existing sine FM plus restrained detuned saw body; envelope moves index/cutoff for throat-like opening/closing | Carrier ratio 1, modulator ratio 2, FM/body weights 0.68/0.20. Index cap 3. `growl` sets index excursion; `texture` sets saw weight, not oscillator count. Preserve existing core. |
| Metallic talking / `bbTalking` | Sines at ratio 1:2.5; blend carrier with bounded ring multiplication; three parallel formant-like bands sweep oh-to-ah | Carrier/ring weights sum 1. Formant-bank wet 0.65, dry body 0.35. BPF rq 0.30; band weights 0.40/0.35/0.25. Center triples interpolate logarithmically [350,800,1800] to [700,1200,2600] Hz. `growl` controls vowel travel; `texture` sets ring mix up to 0.65. Short brightness envelope gives metallic attack. |
| Reese / `bbReese` | Two native band-limited saws, each scaled 0.5; cents detune with restrained slow tone motion | Spread 2–16 cents total, split equally around pitch. `texture` sets detune; `movement` sets cutoff travel; `growl` adds a small mid-peak sweep. Keep stable center signal when widening. |
| Rhythmic wobble / `bbWobble` | Sine/saw body with modest FM; one beat phase drives cutoff and amplitude together | Index cap 1.2. Amplitude floor falls from 1 to 0.30 as `movement` rises; no abrupt waveform gating. Cutoff opens on amplitude crest. `growl` sets FM excursion; `texture` sets sine/saw mix. |
| Screech / `bbScreech` | Audio-rate sine FM at ratio 1:3 plus quiet `SinOscFB` character; short pitch/timbre attack and upper-mid sweep | Index cap 2.4, phase feedback cap 0.6 radians, feedback-layer weight max 0.25. `texture` raises bounded feedback/mix; `growl` sets upper-mid travel. Pitch fall 0–12 semitones over 20–60 ms. Sparse reply/fill, not a permanent wide treble layer. |
| Clean mono sub / `bbSub` | Single sine, finite envelope, low-pass near 90 Hz, identical L/R contribution | Frequency 30–90 Hz, default 36.71; amp default 0.20, cap 0.25. No mid macros, chirp, distortion, chorus, noise, or width. `decay` stays in seconds. |

Talking/reese mid peaks use stock `BPF`, not a vocal plugin. Keep dry-body contribution and bounded filtered weights: a formant bank does not preserve level automatically. Screech uses stock `SinOscFB` phase feedback, not `LocalIn`/`LocalOut` feedback. Begin testing with feedback zero, then validate its range. No delay-loop feedback in this stage.

### Techniques and tradeoffs

- FM/layering: audio-rate FM generates sidebands; use bounded ratios/index and fixed weighted layers. Two operators first, no arbitrary matrices or unison stacks.
- Saturation: tanh default, bounded drive and fixed family trim. Normalization reduces drive gain differences but cannot guarantee constant RMS/perceived loudness.
- Wavefolding: later talking/screech texture experiment only: one fold stage, drive 1–2, wet 0–0.25, default 0. Require aliasing/level acceptance before enabling it in presets. Never fold the sub.
- Resonance/formants: broad rq bounds and weighted bands. Avoid very narrow moving resonances and high filter input gain.
- Transients: deterministic pitch/index/brightness envelopes, not a click on every note or master transient processor. Amplitude attack at least 3 ms.
- Stereo: restrained high-band side signal from detuned layers/quiet character pair. No initial Haas-delay widener; preserve mono.

## 4. Timing and modulation strategy

### Four separate time domains

| Domain | Owner / units | Contract |
| --- | --- | --- |
| Note triggers | Sequencer / quarter-note beats | Retain eighth/sixteenth positions 0.5/0.25 and existing lane triggers. Same epoch and latency policy for all lanes. Current direct Synth messages have unmeasured real-time jitter; do not claim sample-accurate synchronization. |
| Sound modulation | Server / beat-rate control and note envelopes | Pass `beatHz = clock.tempo`, cycle length in quarter beats, initial normalized phase. Envelope times are seconds captured at creation. |
| Musical phrase | Sequencer / bars and global beats | Bar starts at multiples of 3.5. Eight-bar call/reply uses bar index, not default 4/4 clock bars or server LFO counters. |
| Audio-rate DSP | SynthDef / Hz and samples | FM, phase feedback, ring multiplication, distortion run at audio rate, independent of BPM except their timbre-depth controls. |

Use control-rate envelopes/LFO phase for slow motion, then smooth mapped frequency/gain. Use audio-rate amplitude envelopes with doneAction 2 for clean edges. A control-rate triangle controlling depth is distinct from the audio-rate FM modulator.

### Meter-independent server motion

Each mid voice has one normalized cyclic phase accumulator. Rate is `beatHz / cycleBeats`; integrate current rate rather than multiply elapsed time by latest tempo. Use a control-rate ramp reset to zero by a one-time creation trigger, add `phaseOffset`, wrap 0–1, convert to triangle m=1-abs(2*phase-1), smooth by 5 ms. Tempo updates change rate without resetting phase. Implementation can use stock `Phasor.kr` and an initial trigger; test initial phase rather than assuming resetPos sets initial phase.

Each note has one finite motion envelope, levels `motionStart → motionPeak → motionEnd`; segment times `riseFrac*dur` and `(1-riseFrac)*dur`. Blend contour/triangle with `motionLoop`: 0 envelope, 1 cyclic, intermediates bounded convex blends. This envelope has no freeing doneAction; amplitude envelope owns lifetime.

Do not send arbitrary envelope arrays live. Creation scalars define predictable shapes. Interpolate cutoff/formant positions in logarithmic Hz; index/mix weights linearly. `movement=0` removes contour/cyclic excursion and amplitude wobble while retaining base character. `growl` changes character excursion, never note density or tempo.

For motion m, centered excursion is `(2*m-1)*movement`. Use the bounded excursion for family filter depths in section 5. Raising movement does not change rate. Wobble amplitude uses m directly with its specified floor.

### 2+2+3 integration

Derive group boundaries by accumulating `config[\grouping]/2` in quarter beats. Here they are 0,1,2,3.5, corresponding to eighth group starts 0,2,4. No SynthDef hardcodes seven steps or 3.5-beat bars.

| Group | Within-bar beat interval | Cyclic period | Contour / accent multiplier |
| --- | --- | --- | --- |
| First 2 | [0,1) | 1 beat | Bite: start 0.20, peak 1, end 0.15, riseFrac 0.12; accent 1.00 |
| Second 2 | [1,2) | 1 beat | Reply: start 0.65, peak 1, end 0.20, riseFrac 0.35; accent 0.85 |
| Final 3 | [2,3.5) | 1.5 beats | Longer opening: start 0.15, peak 1, end 0.35, riseFrac 0.60; accent 1.10 |

Assign existing bass events the contour/cycle/accent of their onset group. For group-relative cycles set `phaseOffset = fractional((eventBeat-groupStartBeat)/cycleBeats)`; for transport-relative cycles use `fractional(eventBeat/cycleBeats)`. groupStartBeat is absolute, including bar offset. Record phase mode in event data; default group-relative. A crossing note keeps its contour/cycle until release. This yields asymmetric motion without rescheduling notes or encoding meter in DSP.

Clamp accent-adjusted amp. Do not add notes at every boundary; existing hats already accent 0/2/4. If later controls accent a held voice, schedule them at exact group beats on the existing scheduler and tracked node, not an independent timer.

Initial eight-bar demonstration uses this exact zero-based table. Primary applies to all existing bass hits except listed overrides; a rest remains a rest.

| Bar | Primary | Overrides by eighth step |
| --- | --- | --- |
| 0 | Growl | step 5: wobble |
| 1 | Growl | step 6: wobble |
| 2 | Growl | step 5: wobble |
| 3 | Growl | step 6: wobble |
| 4 | Talking | step 5: reese |
| 5 | Reese | steps 4 and 6: talking |
| 6 | Talking | step 5: reese |
| 7 | Reese | step 4: talking; step 6: screech |

Choose one family per event; retain existing pitches, trigger beats, sub lane. Group cycle/contour overrides family defaults for this demo; use family defaults in solo tests. Keep existing event amp/dur overrides except the screech reply uses dur 0.16. Later seeded choices vary only permitted substitutions. Eight bars remain 12 seconds.

Do not add server latency to bass alone while drums still use immediate messages. When timed bundles are introduced, bundle the entire step across lanes using one shared latency; beat positions remain unchanged. NRT uses the same beat/phase data converted to seconds.

Tempo changes belong to planned control staging at the next explicit 3.5-beat bar. Send active voices' `beatHz` in the same timed control bundle. Finite amplitude/motion envelopes retain seconds captured at creation; new notes capture new tempo. No retroactive envelope stretching promised.

## 5. Parameter contract

Use lower camel case. Validate before scheduling, clamp safety-critical values server-side. Reject NaN/infinity client-side; clipping cannot repair NaN. Validate bus indices via owned Bus handles.

### Shared mid controls

| Parameter | Range / default | Policy / meaning |
| --- | --- | --- |
| `out` | Owned stereo bus index | Creation only; existing mix bus. |
| `freq` | 30–500 Hz / 73.42 | Live, 15 ms smoothing; pitch before bounded chirp. |
| `amp` | 0–0.30 / 0.16 | Live, 10 ms smoothing; final voice gain. Old 0.17/0.19 events valid. |
| `dur` | 0.05–1.48 s / 0.25 | Creation only; finite decay/contour duration, preserving growl semantics. |
| `attack` | 0.003–0.020 s / 0.006 | Creation only; amplitude attack. |
| `release` | 0.005–0.050 s / 0.020 | Creation only; early-release time, not extra tail after dur. |
| `gate` | 0 or 1 / 1 | Live; 0 begins release; never retrigger a released node with 1. |
| `growl` | 0–1 / 0.60 | Live, 15 ms; family spectral excursion, not raw feedback gain. |
| `movement` | 0–1 / 0.65 | Live, 15 ms; contour/LFO depth, not speed. |
| `aggression` | 0–1 / 0.45 | Live, 15 ms; saturation drive 1–4 with compensation/trim. |
| `tone` | 0–1 / 0.50 | Live, 20 ms; baseline cutoff times `2^((tone-0.5)*2)`, then clamp. |
| `texture` | 0–1 / 0.35 | Live, 20 ms; family layer/detune/feedback mapping. |
| `width` | 0–1 / 0.20 | Live, 25 ms; side gain 0–0.35 above side HPFs; zero exact mono. |
| `cutoff` | 280–8000 Hz / 2600 | Live, 20 ms; baseline retained for old callers. |
| `rq` | 0.25–0.80 / 0.40 | Live, 20 ms; low-pass reciprocal Q, never zero; talking BPF fixed 0.30. |
| `beatHz` | 2–2.666667 / 140/60 | Live, 5 ms; quarter beats/sec for PLAN's 120–160 BPM. |
| `cycleBeats` | 0.5,1,1.5,2,3.5 / 1 | Creation only; allowed data choices, DSP can support future values. |
| `phaseOffset` | [0,1) / 0 | Creation only; normalized cycle phase. |
| `motionLoop` | 0–1 / 0.25 | Creation only; contour/cycle blend; wobble default 1. |
| `motionStart`, `motionPeak`, `motionEnd` | Each 0–1 / 0.20,1,0.15 | Creation only; contour levels. |
| `riseFrac` | 0.05–0.80 / 0.15 | Creation only; peak-time fraction. |
| `sync` | 0 or 1 / 1 for new families | Creation only; growl default 0 for old callers, new events supply 1. |
| `wobbleHz` | 0.25–12 Hz / 3 | Growl compatibility only; live, 5 ms; sync=1 ignores it. |
| `fmIndex` | 0–3 / 2.3 | Growl compatibility only; live, 15 ms; index ceiling. |

Use initialization-rate controls for creation-only values where practical; otherwise enforce at caller. `.set` cannot resize an Env, change oscillator count/channels, or replace a SynthDef. Never update out live. Family selection, waveform topology, and ratios are creation decisions.

Finite amplitude envelope: attack then percussive dur, doneAction 2; nominal maximum lifetime attack+dur, plus server-block granularity. An optional second gate-release envelope also frees early and cannot extend this lifetime. Short hits, not indefinite ADSR sustain. Envelope time controls are not live-updated after capture. For future beat-duration events, convert desired duration to seconds with clock tempo and subtract attack before assigning dur, then validate.

Family defaults override only these values; omitted values use the shared table:

| Family | growl / movement / aggression / tone / texture / width | Other defaults |
| --- | --- | --- |
| Growl | 0.65 / 0.65 / 0.45 / 0.50 / 0.35 / 0.15 | rq 0.32, motionLoop 0.25, sync 0 |
| Talking | 0.75 / 0.75 / 0.35 / 0.45 / 0.55 / 0.10 | cutoff 3300, motionLoop 0, riseFrac 0.35 |
| Reese | 0.25 / 0.35 / 0.40 / 0.45 / 0.50 / 0.35 | motionLoop 1, cycleBeats 3.5 |
| Wobble | 0.35 / 0.85 / 0.45 / 0.50 / 0.25 / 0.15 | motionLoop 1, cycleBeats 1 |
| Screech | 0.70 / 0.55 / 0.55 / 0.65 / 0.35 / 0.20 | cutoff 4200, dur 0.16, motionLoop 0, pitchSemis 7, pitchTime 0.030 |

Screech-only `pitchSemis` 0–12 and `pitchTime` 0.020–0.060 s are creation controls. Its pitch envelope falls linearly in semitones from pitchSemis to zero, then holds zero; frequency multiplier is 2^(semitones/12). Ratios are per-family constants initially, avoiding ambiguous extra mappings.

### Bounded macro mapping rules

Order: smooth validated macros → compute motion → derive frequency/layer/drive → clamp → process audio → envelope/amp. Defaults and extrema use the same graph.

- Growl index is `fmIndex*growl*(1-movement+movement*m)`, clipped 0–3. Filter excursion up to ±1.5 octaves times growl and centered motion; texture maps saw weight 0–0.20.
- Talking vowel position is `growl*(1-movement+movement*m)`. Interpolate the specified center triples; texture maps ring weight 0–0.65. Tone affects final low-pass, not band ordering. Metallic brightness attack starts one octave above baseline cutoff and falls to baseline over 0.020 s, with its depth scaled by aggression and final frequency clamp.
- Reese spread is `2+14*texture` cents. Growl enables a peak at 400–1200 Hz driven by centered motion, wet weight max 0.20*growl, BPF rq 0.40. Cutoff excursion ±0.5 octaves times centered motion.
- Wobble cutoff excursion ±2 octaves times centered motion. Amplitude multiplier is floor plus `(1-floor)*m`, floor `1-0.70*movement`. FM index `1.2*growl*(1-movement+movement*m)`. Texture maps saw weight 0.25–0.75, complementary sine weight.
- Screech index `2.4*growl*(1-movement+movement*(0.35+0.65*m))`. Texture maps feedback 0–0.6 and layer weight 0–0.25, with complementary main-FM weight. Upper-mid peak sweeps 1400–3600 Hz using centered motion, BPF rq 0.40, wet max 0.20*growl.
- Final cutoff targets clamp 280–min(8000,0.35*sampleRate) Hz. All formant/mid-peak dry/wet weights are complementary and sum 1. Aggression/width use common table. No macro changes lifetime, pitch register, density, bus, or oscillator count.

For saturation, drive=1+3*aggression, shape audio x as tanh(x*drive)/tanh(drive); fixed trim controls remaining level differences. Start trim 1 per family, then match defaults by reducing louder families against a measured reference. Do not normalize each frame or add slow AGC to hide unstable dynamics.

Sub retains out/freq/amp/decay. Decay range/default 0.04–0.30 / 0.19 s; attack stays 0.004 s. Clip freq 30–90, amp 0–0.25, preserve identical stereo output. Add early gate/release only if cap management needs it; finite decay and old callers remain valid.

## 6. Audio routing, separation, and FX

### First implementation: preserve buses

Mid chain: bounded oscillator layers → pre-nonlinearity low-pass → saturation → family filter/formants → DC removal → stereo matrix → final two cascaded HPFs at 150 Hz → final low-pass → amplitude envelope/amp → existing stereo mix bus → existing master.

Pre-nonlinearity ceiling min(6000,0.25*sampleRate) Hz; final ceiling min(8000,0.35*sampleRate). Pre-filter can use fixed ceiling; final low-pass follows the bounded tone/motion cutoff. Nonlinear stages precede final high-pass. Filters reduce excess energy but cannot undo aliasing already folded into the audible band. No oversampling or alias-free claim. If family resonances fail peak checks, first reduce band weights/trim; do not silently add more distortion stages.

Stereo: mid M=(L+R)/2, side S=(L-R)/2; high-pass side twice at 180 Hz, use side gain 0.35*width; output M plus/minus side. Mono-core families can use one quiet detuned character pair, total mix max 0.25, with complementary centered-core weight; fixed ±4 cents. Reuse growl/reese saw pairs, replace wobble saw with a pair, and replace screech feedback character with a pair rather than add another layer. Talking may use an additional quiet carrier pair. Main FM stays centered. Width 0 duplicates M exactly. Never derive sub from distorted mid/side.

Sub chain: sine → existing 90 Hz low-pass → finite envelope/amp → identical L/R on existing mix bus. Lanes remain logically separate before bus split. The 90–150 Hz transition is conservative, not complementary reconstruction; no promise of zero spectral overlap. No distortion after mid high-pass that could recreate low-frequency products.

Leave current master LeakDC, limiter peak 0.68, and -12 dB gain. Limiter precedes gain; nominal steady default ceiling is approximately 0.171, not 0.68. Do not raise master to compensate for filtering/family mismatch.

### Later approved routing/FX integration

When PLAN routing/FX work is implemented, allocate stereo upper-bass bus and mono sub bus, retain final mix bus, and insert ordered processor groups. Clean sub mixer duplicates one channel to L/R without distortion. Keep out contract; migrate existing stereo sub output explicitly before sending to a mono bus. Never point current two-channel sub at a one-channel allocation.

Shared distortion, width, ambience, and cross-synthesis receive only upper-bass bus. Reapply final mid high-pass after nonlinear bus processors. Sub remains dry. Kick ducking is optional future FX, not required here: drive a deterministic duck envelope from existing kick events, not a second clock. Leave reverb/delay off in family tests.

## 7. CPU, determinism, and voice management

- Target PLAN's 48 kHz/block 64. Do not change backend settings before matched runtime validation. Evaluate 44.1 kHz additionally, not as replacement target.
- Budget 2–4 main/character oscillators, one contour, one cyclic phase, up to three formant bands, short output chain. No FFT/convolution/unison framework/oversampling graph. Profile actual CPU.
- Default maximum two overlapping mid notes; hard ceiling four; one active sub. Old short mid tails intentionally overlap nearby triggers. Current sub spacing permits one voice without stealing.
- Track owned nodes/removal notifications. At hard cap, release oldest and omit the new event with a reported cap hit; do not delay/requantize musical intent silently. Factory event table must never hit cap. Prefer prevalidated event spacing over routine stealing; do not add a complex allocator.
- Stop cancels owned future triggers/controls, retains master fade, then frees owned voices. No global server/clock resets. Removing a node removes live-update handle. Free buses after dependent nodes/callbacks are cleared.
- Automatic lifetime remains even if note-off is lost. Gate is early release, not normal lifetime ownership.
- Defaults use deterministic oscillators/envelopes, not noise/random-rate UGens. Seeded family/detune choices occur during event compilation with PLAN's independent bass seed; store resolved values, no randomness in UI/server callbacks.
- Later server noise requires explicit per-voice seeding and repeated same-runtime decoded PCM tests. Event determinism is distinct from PCM determinism; a composition seed does not automatically seed audio UGens.
- Record hardware/backend, voice count, CPU, underruns. PLAN target <50% average / <70% peak CPU on 96-second stress run. Reduce overlaps/side layers first if too costly; no promised CPU cost without measurement.

## 8. Ordered implementation backlog

One row per focused turn. Tests/commands below are future work; proposed bass fixture file does not exist now.

| Order | Narrow deliverable | Acceptance |
| --- | --- | --- |
| 1 | Match SC 3.14.x, run unchanged Phase 2 using PHASE2_VALIDATION steps. Record baseline defects separately. | Real compilation/definition loading/boot/transport/cleanup and fresh non-silent audio. Do not build timbres on uncompiled baseline. |
| 2 | Add bounded sub controls and growl final low-band/DC protection in bass.scd. Keep names, Array shape, arguments, mix bus. | Sub mono/frequency/lifetime, high-pass probe; existing loop still runs. |
| 3 | Add growl macros, finite contour/early release, beat phase/sync; retain legacy Hz mode. Only bass-control construction changes in sequencer. | Old calls compile; rate/phase/extrema/lifetime pass; trigger beats unchanged. |
| 4 | Add talking/reese files and explicit main registration. | Solo finite/stereo/level tests, discernible vowel/reese movement; no unused-family DSP. |
| 5 | Add wobble/screech files and same contract. Start feedback zero, then validate bounds. | Period/gate/feedback/mono/aliasing checks. Folding disabled by default. |
| 6 | Fixed call/reply table, group contours/phases/accents; minimal active-node tracking. | Drum/sub beats unchanged, 12-second cycle, group/family assertions, ten clean transport cycles. |
| 7 | Calibrate trims/macros via renders and recorded listening; capped-voice CPU profile. | Criteria below pass or precise blockers reported. No GUI, arrangement rewrite, export API, larger FX graph. |

Extend PLAN's tests/unit.scd, tests/nrt_smoke.scd, tests/lifecycle.scd; do not introduce competing runners. Add small tests/bass_cases.scd fixture table if needed. Native Score/SoundFile test artifacts are not implementation of full export feature.

## 9. Testable acceptance criteria

All runtime checks remain unrun here. Report unavailable separately from failed. Use run-specific new artifacts; record version/config/fixture/measurements.

| Check | Fixture / pass criterion |
| --- | --- |
| Language/server | Load all families with matched 3.14.x sclang, send to selected scsynth, sync, instantiate each. No parser/class/UGen/definition/server errors. A delimiter scan does not pass. |
| Safety | Defaults, each macro endpoint, all-low/all-high, 16 fixed corner fixtures/family; valid output finite, non-muted output nonzero. Client rejects invalid/nonfinite inputs; server safety bounds hold. |
| Lifetime | Default/max durations and gate=0 midway. NRT nodes end within envelope time plus one block; real-time allowance includes measured OSC latency. No voices two seconds beyond maximum lifetime. |
| Timing regression | Normalized lane trigger beat lists before/after match. Seven eighths=3.5 beats, boundaries [0,1,2,3.5], next eight-bar cycle beat 28/12 s. No four-beat phrase gap. |
| Motion | 120/140/160 BPM; cycles 0.5/1/1.5/3.5; phases 0/0.25/0.5 in diagnostic motion fixture. Period cycleBeats/beatHz within one control block. Tempo update preserves phase; contour peak timing within one block. Test unsmoothed phase separately from documented 5 ms smoothed output. |
| Asymmetry | Group-derived values for all seven steps; third group 1.5 beats versus first/second 1. Call/reply deterministic. Listening required for perceived grouping. |
| Sub | Solo allowed pitches: sample-identical L/R, no distortion/detune/width, nonzero RMS. Inspect/listen for harmonics/clicks; finite envelope causes spectral spreading and is not evidence of extra oscillator. |
| Separation | Filter-only steady 60 Hz probe through cascaded 150 Hz HPFs: >=28 dB RMS attenuation; repeat output recipes. Record actual family energy below 90 Hz, investigate outliers. Nonlinear processing never enters sub path. |
| Level/DC | Solo defaults/corners and eight-bar mix finite. Solo mid sample peak <=0.50 before master; match factory active-window RMS within ±4 dB of measured growl reference by reducing louder trims, diagnose weak families. Absolute active-window DC mean <=0.001 excluding startup transient. Mix peak <=0.72; routine protection must not depend on heavy limiting. |
| Stereo | Width=0 sample-identical L/R. Factory width: mono-collapse RMS loss <=3 dB versus stereo energy. Probe side HPF attenuation; inspect/listen for cancellation and unstable image. |
| Aliasing/quality | Sustained/short notes at 44.1/48 kHz and extreme pitch/drive/index/texture. Inspect spectra and listen for folded/whistling artifacts. Post low-pass alone is insufficient evidence. Lower drive/index/bandwidth or keep folding disabled if artifacts dominate; record unresolved limits. |
| Resources/CPU | Ten start/stop cycles; double calls, pending-playback shutdown, unrelated nodes preserved. Counts return to prepared baseline after stop/initial baseline after shutdown. Capped voices run 96 s; measured CPU/underruns. |
| Determinism | Same seed/config gives identical normalized family/parameter events. Fresh pinned-runtime bass-only NRT renders match decoded PCM. Existing drum noise needs separate seeding/diagnosis; bass results do not certify whole loop repeatability. |
| Musical quality | Named human listens to identified eight-bar and solo artifacts: FM opening/closing, vowel motion, reese beating, synced wobble, controlled screech reply, clean sub. Render/spectrum alone cannot certify sound quality. |

### Future validation commands

From repository root after matched runtime/test implementation:

| Purpose | Command |
| --- | --- |
| Version | `sclang -v` and `scsynth -v` |
| Timing/control | `QT_QPA_PLATFORM=offscreen timeout 60s sclang -D tests/unit.scd` |
| Solo/eight-bar NRT | `QT_QPA_PLATFORM=offscreen timeout 180s sclang -D tests/nrt_smoke.scd` |
| Lifecycle | `QT_QPA_PLATFORM=offscreen timeout 90s sclang -D tests/lifecycle.scd` |
| Desktop audition | `sclang main.scd`, then existing ~balkan controls |

Wait for fresh WAV completion, verify format/finite/nonzero/peaks, count actual assertions, exit nonzero on failure. Dummy backend tests signal/transport, not physical listening. This documentation task checks source/design consistency and arithmetic only; no runtime or audio-quality pass is established.
