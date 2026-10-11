# BALKAN//BASS

A SuperCollider 3.14.1 music toy: **140 BPM, 4/4 halftime**, with an original rave/brass hook, distorted three-operator FM growls, vowel replies, accented bass hits, sparse screeches, and pitched sample chops. Long calls alternate with short answers and rests. A clean mono sub is ducked when the kick hits; parallel master compression adds sustained level while retaining the protected output ceiling.

The seeded 24-bar loop moves through intro (2 bars), build (2), drop A (8), break (2), build (2), and drop B (8): about **41.14 seconds** at 140 BPM. Both builds end with a one-beat instrumental cut and a vocal shout. Intro, buildup, and break have lower section levels than the drops. Seeds select different keys, hooks, two-bar rhythm cells, responses, and drum details, rather than merely changing a few hats.

## Get it running on macOS

1. Install [SuperCollider 3.14.1 for macOS](https://github.com/supercollider/supercollider/releases/download/Version-3.14.1/SuperCollider-3.14.1-macOS-universal.dmg). It includes the IDE, language, server and Qt. No Quarks or separate sample download is required.
2. Get the latest project with `git pull origin main` from an existing clone, or download a fresh ZIP from [GitHub](https://github.com/danbkap11/brosteprhythmdestroyer228). Keep the whole folder together, including `assets/samples`.
3. Set your Mac's sound output and start at a low speaker/headphone volume. This revision has more sustained level; the master still defaults to -6 dB.
4. Close any older BALKAN//BASS window first; evaluating while it is open only focuses that existing session. Open `main.scd` in the SuperCollider IDE. Press **Command+A**, then **Command+Return** to evaluate the whole file. Wait until the new BALKAN//BASS window says **Ready** and press **Play**. The app does not play automatically.

Drop A starts after about **6.86 seconds**; Drop B starts after about **27.43 seconds**. Press **Stop** before changing the seed, density, variation or preset. Enter a seed and click **Generate**, or click **New seed**; **Play** restarts the selected plan from bar one. The same seed and controls select the same planned events, though synthesized noise may differ between plays. The six bass sliders affect new notes, including the new sampled bass voice. Tempo changes take effect at the next bar; existing notes finish at their original modulation rate. Closing the window releases this app's resources after pending audio bundles drain and preserves an externally booted server.

The project includes [CC0 sample credits](assets/samples/README.md), including two new bass chops and a brostep snare. Downloaded Freesound material uses public high-quality MP3 previews converted to WAV; these are not lossless original downloads. All required files are bundled. No Quarks, paid plugins, accounts, or commercial artist recordings are required.

Production references read for this rework:

- [Skrillex's 2011 Computer Music interview](https://www.musicradar.com/news/tech/interview-skrillex-on-ableton-live-plug-ins-production-and-more-510973): FM/Operator bass, multistage distortion/compression, printed and chopped sounds, and room for drum transients. Applied through three-operator FM, bounded band-specific drive, sample substitution, and kick-triggered ducking.
- [Sound On Sound: Dubstep Secrets](https://www.soundonsound.com/techniques/dubstep-secrets): FM sources, synchronized movement, parallel processing, and low-end separation. Applied through beat-locked filter/contour motion, a dedicated clean sub, and final mid-bass high-pass filtering.
- [MusicRadar: bass production tips](https://www.musicradar.com/tutorials/music-production-tutorials/bass-tips-recording-week): fast attacks, kick/bass relationships, and phrase variation. Applied through sustained calls with quick attacks, contrasting replies, and deliberate pre-drop silence.

This is original music and sound design informed by early-2010s brostep production methods. The downloaded sounds are not claimed to be the samples used in Bangarang.

Quick check: launch → Play → change a bass macro → change BPM → Stop → Play again → close the window. Then reopen, try a different seed, and listen through both drops.

If startup fails, copy the **first** error and nearby stack trace from SuperCollider's Post Window, plus your macOS and SuperCollider versions. Actual Linux SuperCollider **3.13.0 compatibility checks** compiled the modules, rendered audio, exercised transport/cleanup on dummy JACK, and constructed the Qt window offscreen. The target macOS **3.14.1**, physical playback, and listening remain unverified here. See [PROGRESS.md](docs/PROGRESS.md) for measured results.
