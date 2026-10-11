# Progress

## Current rework — 2026-10-11

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
