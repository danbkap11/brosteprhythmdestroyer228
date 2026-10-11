# BALKAN//BASS agent instructions

## Scope and workflow

- Read `docs/PLAN.md` before major changes. Use its ordered backlog and module contracts; implement only the task requested by the user.
- Planning requests authorize documentation changes only. Do not generate application code or install dependencies during a planning task.
- Preserve existing working functionality and user changes. Avoid unrelated refactoring, unsolicited features, and architecture redesign.
- Keep modules small with clear responsibilities and stable interfaces. If a requested change requires an interface change, explain it and update the affected contract and callers within that task.
- Use the existing isolated checkout. Do not create a worktree unless requested.
- Optimize for limited Codex usage: inspect relevant files, complete one focused task, run relevant checks, and stop when its acceptance criteria are satisfied.

## Technical constraints

- Target SuperCollider 3.14.x, stock UGens/libraries, native Qt, and native stereo WAV export. Avoid external frontends, unnecessary dependencies, paid plugins, and proprietary samples.
- Preserve the musical baseline: 140 quarter-note BPM, 7/8 grouped 2+2+3, folk motifs, heavy halftime-inspired grooves, bounded bass variation, and a clean mono sub. The refined brostep direction does not implicitly replace the established meter.
- Keep generation seeded and bounded. Preserve independent layer seeds and the shared real-time/offline event plan.
- Allocate buses and nodes through owned runtime resources. Respect source → cross → FX → master ordering, synchronize definition loading, and free only resources this application owns.
- Preserve protected output and conservative default gain when changing DSP. Avoid uncontrolled feedback or bypassing bounds to make a patch louder.

## Verification and reporting

- Verify changes with available tools and the relevant acceptance checks in `docs/PLAN.md`. Documentation-only edits need consistency checks, not audio tests.
- SuperCollider has no separate universal syntax-only CLI check: load/compile the relevant files in `sclang` when installed, and test server-side SynthDefs separately. Do not present a text scan as a successful SC compilation.
- Report passed, failed, skipped, and unavailable checks accurately. Identify concrete blockers and never claim unrun checks passed or zero-test runs validated behavior.
- Distinguish language compilation, server boot, node cleanup, timing, rendered audio, physical playback, and interactive GUI validation. A running process or successful offline render does not prove real-time audibility.
- Never claim that audio sounds good without a listening test. Report measured signal/peak properties as measurements; identify the listener and artifact when reporting subjective sound checks.
- Verify fresh WAV outputs, file completion, format, finite/nonzero samples, and output peaks. Preserve test exit status and avoid silently overwriting user exports.
- Prefer concise summaries of changed files, checks, and limitations over large code dumps. Keep `docs/PROGRESS.md` brief if it exists; do not create extra reports for routine documentation work.
