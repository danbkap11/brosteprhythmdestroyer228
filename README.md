# BALKAN//BASS

A SuperCollider 3.14.1 music toy: 140 BPM, **4/4 halftime**, distorted FM/growl, talking and vowel basses, a punchy accent bass, tempo-locked wobble, and a clean mono sub. Longer bass calls now alternate with short responses; the growl has an extra octave harmonic and moving throat-like mid bands. CC0 kick and snare one-shots reinforce the synthesized drums, and short snare rolls lead into a one-beat pre-drop pause with a CC0 vocal shout. Its seeded 24-bar loop moves through intro (2 bars), build (2), drop A (8), break (2), build (2), and drop B (8). At 140 BPM it lasts about **41.14 seconds**.

## Get it running on macOS

1. Install [SuperCollider 3.14.1 for macOS](https://github.com/supercollider/supercollider/releases/download/Version-3.14.1/SuperCollider-3.14.1-macOS-universal.dmg). It includes the IDE, language, server and Qt. No Quarks or separate sample download is required.
2. Get the latest project with `git pull origin main` from an existing clone, or download a fresh ZIP from [GitHub](https://github.com/danbkap11/brosteprhythmdestroyer228). Keep the whole folder together, including `assets/samples`.
3. Set your Mac's sound output and start at a low speaker/headphone volume. This revision has denser, louder bass and a higher default master level.
4. Close any older BALKAN//BASS window first; evaluating while it is open only focuses that existing session. Open `main.scd` in the SuperCollider IDE. Press **Command+A**, then **Command+Return** to evaluate the whole file. Wait until the new BALKAN//BASS window says **Ready** and press **Play**. The app does not play automatically.

Drop A starts after about **6.86 seconds**; Drop B starts after about **27.43 seconds**. The selected pre-drop shout is near the end of the buildup immediately before one of those drops. Press **Stop** before changing the seed, density, variation or preset. Enter a seed and click **Generate** to make a new plan; **Play** restarts it from bar one. The same seed and controls select the same planned events, though synthesized noise may differ between plays. The six bass sliders affect new notes, and tempo changes take effect at the next bar. Closing the window releases this app's audio resources.

The project includes [CC0 sample credits](assets/samples/README.md). These are licensed one-shots and original synth sounds, not samples from a commercial artist's recordings. The mix changes draw on [Sound On Sound's dubstep bass guide](https://www.soundonsound.com/techniques/dubstep-secrets) and [EDM Templates' drop-mixing checklist](https://edmtemplates.net/blogs/edm-templates-blog/how-to-mix-a-dubstep-drop): synchronized filter movement, parallel distortion/compression, a dedicated mono sub, and transient-focused drum layers.

If startup fails, copy the **first** error and nearby stack trace from SuperCollider's Post Window, plus your macOS and SuperCollider versions. This cloud workspace has no `sclang` or `scsynth`; the latest revision has had source and asset checks here, but not a macOS compilation, playback or listening check.
