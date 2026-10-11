# Progress

## Hijaz direction, rounder lead and bass presence — current, 2026-10-11

28-bar / 48-second groove and seed controls preserved. Arabic/Hijaz-inspired
equal-tempered motifs replace the pentatonic direction: `[0,1,4,5,7,8,10]`,
tonic/b2/major-third/fourth gestures, tonic cadences and compatible tonic/bII/IV
accompaniment. MaqamWorld source links are in README.md. GUI title is
HIJAZ//BASS; repository names and `~balkan` remain compatible.

`bbRave` now uses a rounded Pluck/reed hybrid rather than the former bright
brass stack; its old name/control interface is retained. Note levels and
counterline register are reduced. Break opening immediately triggers hook,
pad, spark, light tom/hat and a clean sub pulse; atmosphere attack is 25 ms.
Intentional vocal gaps before drops remain intact.

Six upper-bass voices have fuller parallel body/formant support, slightly
stronger bounded saturation and higher finite sustain. Foreground mid calls
can cross kicks under existing ducking, ending before the next main note;
sub still ends before later kicks. Sub SynthDef and master ceiling unchanged.

Actual SC 3.13.0 Linux compatibility results:

- All 22 source modules compile and SynthDefs serialize.
- Eight seeds pass 448-event timing, identical regeneration, Hijaz membership
  across pitched lanes/pad triads, active break downbeat, and distinct
  rhythm/melody signatures.
- 42 upper-bass fixtures pass short/max notes, endpoints, live changes,
  gate release, ducking, finite audio, width-zero mono and automatic node
  removal. Same-note active RMS rises 1.8–3.7 dB; 300–2000 Hz energy rises
  1.5–3.5 dB. Default fixture peaks <0.433; extreme clipped controls <0.660
  before the protected master. Clean sub fixture is unchanged.
- Seven replacement-lead fixtures pass finite/nonzero output, maximum
  1.25-second lifetime, live changes, early release and width-zero equality.
  Maximum raw peak 0.06146; its measured default RMS is lower than the old
  lead, consistent with reducing its prominence.
- Full seed 228 and 12345 NRT renders pass finite/nonzero stereo audio,
  protected peak 0.340813, no server errors and an exactly silent final
  50 ms. Seed 228 drops measure -18.2/-17.5 LUFS. Drop A's 350–1400 Hz
  energy rises 1.30 dB versus the preserved prior render; its 25–90 Hz
  band changes only -0.17 dB. The clean-sub stem has exact L/R equality.
- The first 0.3 seconds of the break have continuous nonzero audio,
  RMS 0.09858 and peak 0.19780: no empty entrance.
- Dummy-JACK playback, live macros, next-bar tempo updates, Stop/restart
  and shutdown pass while preserving an external server and unrelated
  sentinel nodes. Offscreen Qt launch, re-evaluation and window close
  pass without duplicate windows/audio graphs or retained owned resources.

Temporary results: `/tmp/bb-presence-{before,after,bounds}.*` and the current
`/tmp/balkan-render/hijaz-*` artifacts. Listening and macOS SC 3.14.1 remain
unverified here. Earlier validation results are preserved below. No formal
test infrastructure, plugins or application dependencies were added.

## Prior seeded arrangement and layers — 2026-10-11

28 bars / 48 seconds at 140 BPM, still 4/4 halftime. First drop starts at
6.86 s, four-bar break at 20.57 s, second drop at 34.29 s. The seed now shapes
an ancestral motif, bounded onset/length/split/rest edits, harmonic journeys,
phrase mutations, kick replies and fills. Stable motif anchors and the
existing foreground bass synthesis preserve the theme/drop character.

The break develops release → harmonic answer → quiet arpeggio → rhythmic
pickup, followed by a four-bar build. New finite `bbAtmosphere` and `bbSpark`
voices add a high-passed chord bed and metallic pluck/echo counterline;
existing licensed one-shots supply a sparse additional percussion lane.
Optional pad/spark/perc plan data shares the existing step bundle, source
group and mix bus. There are no extra clocks, samples or persistent FX nodes.
GUI transport/macros remain unchanged. References added to README.md:
Ableton's Mutation Over Generations/Dramatic Arc and MusicRadar arranging tips.

Actual Linux SC 3.13.0 compatibility checks:

- All source modules compile; the two new SynthDefs serialize and execute.
- Two independent eight-seed probes passed same-seed repeatability,
  448-event timing/sections, distinct bass onset/melody signatures, backbeat
  anchors and two clear instrumental gaps. One also checked zero main-bass
  overlap or crossing of a later kick, and support parameter bounds.
- Eight support-voice fixtures plus live control updates passed finite,
  nonzero output, width-zero equality, early release and silent tails;
  maximum raw peak 0.08330.
- Full seed 228 and 12345 NRT renders passed: stereo 48 kHz, about 50.20 s
  including tail, finite/nonzero, protected peak 0.340813, zero server errors.
  Seed 228 section LUFS: build -21.0/-22.0, drops -18.0/-18.2, break -23.2.
  These measurements establish level relationships, not listening quality.
- Actual dummy-JACK regression passed playback through the first drop,
  macro/BPM updates, Stop with an empty source group, restart and shutdown
  preserving the external server and unrelated sentinel nodes. Actual
  offscreen Qt launch/re-evaluation/Play/Stop/window-close also passed without
  duplicate resources. The final render's last 50 ms is exactly silent;
  natural sample/FX tails precede the render's end-of-score cleanup.
- The isolated pad stem is nonzero in the break (RMS 0.01354), roughly 11 dB
  below the full break: a supporting layer rather than a competing lead.
  Measured 25–90 Hz drop RMS did not increase versus the prior render.

Session artifacts use `/tmp/balkan-render/seed-variation-full*` and
`seed-variation-12345*`; new support fixtures are `/tmp/balkan-support.wav`
and `/tmp/balkan-support-live.wav`; current runtime logs are
`seed-variation-lifecycle.log` and `seed-variation-launcher.log`.
No formal runners were added to the repo.
Target macOS SC 3.14.1, physical listening and subjective quality remain
unverified here. The prior runtime results below are historical evidence.

## Prior rework — 2026-10-11

140 BPM, 4/4 halftime, 16 sixteenth steps/bar, 24 bars (~41.14 s).
Original seeded rave hook and six composed two-bar bass cells; sustained
three-operator FM growls alternate with vowel/accent/screech responses and
rests. New CC0 growl/reese chops replace selected mid voices, with a new
brostep snare reinforcing the synthesized backbeat. Both builds end with
an instrumental cut and vocal cue. Clean mono sub receives kick-triggered
ducking; stronger bounded mid processing, parallel master compression and
lower intro/build/break gains preserve drop contrast. GUI/public transport
remain unchanged. Startup/shutdown handle the new owned control bus/node
and drain timestamped bundles before releasing resources.

Research and sample provenance: README.md and assets/samples/README.md.
Export, more dedicated bass families and formal test infrastructure remain
deferred; temporary cloud checks below are not application dependencies.

## Actual verification

Isolated **SC 3.13.0 Linux compatibility runtime**, not target macOS 3.14.1.
Available Debian 3.14.1 binaries required a newer host glibc/Qt, so they could
not run here. The user's macOS target and launch instructions are unchanged.

- Passed: all source modules interpreted and SynthDefs serialized; actual
  server execution produced no errors in the full render or bass fixtures.
- Passed: 384-event plan repeatability, different-seed plan change, halftime
  backbeats, two pre-drop cuts/shouts, hook, sustained sub, sample substitution.
- Passed: 28 short/sustained bass fixtures including macro endpoints, live
  parameter changes and early gate release; finite/nonzero audio, exact
  width-zero L/R equality, silent release tails. Raw maximum peak 0.36136;
  maximum absolute measured fixture DC 0.000983. This is selected fixture
  coverage, not an exhaustive parameter-space guarantee.
- Passed: actual dummy-JACK boot/start/macro/BPM/stop/restart/shutdown;
  source group empty after Stop; externally owned server and unrelated
  sentinel nodes survived shutdown.
- Passed: actual main.scd offscreen Qt startup, no autoplay, reevaluation
  without duplicate graph/window, Play/Stop, window-close cleanup and
  application-owned server shutdown. Final section-gain control was also
  compiled/executed through the captured playback bundles.
- Full NRT artifact: stereo 48 kHz float WAV, **43.344 s including tail**,
  finite/nonzero, peak **0.340813**, final tail exactly silent. Build -21.2 LUFS,
  drops **-17.5/-17.4 LUFS**; drops exceed builds by ~3.7 LU. Full mean DC
  -0.000470. These measurements do not establish perceived quality.

Session artifacts: `/tmp/balkan-render/full.wav`, `bass-notes.wav`,
`final-measurements.json`, `lifecycle.log`, `launcher.log`.
Session commands used `/tmp/balkan-sc-313/sclang` on temporary module,
sequencer, bass, lifecycle and launcher checks. Full render commands:

```sh
python3 /tmp/balkan-make-render-helper.py
/tmp/balkan-sc-313/sclang /tmp/balkan-full-render.scd
/tmp/balkan-sc-313/scsynth -U /tmp/balkan-sc-313/root/usr/lib/SuperCollider/plugins -N /tmp/balkan-render/full.osc _ /tmp/balkan-render/full.wav 48000 WAV float -o 2
python3 /tmp/balkan-render/analyze.py
```

These helpers live only in this cloud session. Mac launch and short manual
checks are in README.md. **Unverified:** listening, physical audio output,
interactive macOS 3.14.1 GUI, exhaustive aliasing/CPU profiling and startup
failure recovery. No subjective audio-quality claim is made.

## Historical notes

Previous versions used a 7/8 eight-bar loop and then a 7/8 32-bar arrangement.
The earlier cloud audit corrected a Random call, boot-waiter cancellation,
playback-time Defaults mismatch, off-accent hat density and seed overflow;
server-loss polling received a partial source fix. The user heard and
controlled an earlier GUI version on macOS but found its music unconvincing.
Subsequent static-only 4/4 iterations added long calls and drum transients;
they had no runtime or listening evidence. Those historical results remain
in PHASE2_VALIDATION.md and AUDIT.md, separate from the actual checks above.
