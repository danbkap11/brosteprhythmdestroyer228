# BALKAN//BASS

A SuperCollider brostep instrument with synthesized drums, FM growl and
talking bass replies, a separate mono sub, and a native control window. The
default 32-bar phrase is 140 quarter-note BPM in 7/8, grouped 2+2+3. It
lasts 48 seconds and moves through intro, build, drop, break, build, and a
second drop.

## Set up on macOS

1. Install **SuperCollider 3.14.1**. Download the
   [official macOS universal DMG](https://github.com/supercollider/supercollider/releases/download/Version-3.14.1/SuperCollider-3.14.1-macOS-universal.dmg),
   open it, and copy SuperCollider to **Applications**. The SuperCollider IDE,
   language and audio server come with it. No Quarks, samples, Homebrew or
   other packages are needed. If macOS blocks the first launch, Control-click
   the app in Finder and choose **Open**.
2. Get the project from
   [GitHub](https://github.com/danbkap11/brosteprhythmdestroyer228): choose
   **Code → Download ZIP**, unzip it, and keep the folder together. If you
   already use Git, `git clone https://github.com/danbkap11/brosteprhythmdestroyer228.git`
   works too.
3. In macOS **System Settings → Sound → Output**, select your speakers or
   headphones. Start with the Mac's volume low.

## Play

1. Open `main.scd` from the downloaded project folder in the SuperCollider
   IDE. Select the whole file with **Command+A** and evaluate it with
   **Command+Return**. The project loads its other files relative to
   `main.scd`; leave them in the same folder structure.
2. Wait for the BALKAN//BASS window to show **Ready**, then press **Play**.
   The app prepares audio on launch but waits for Play before making music.
   At 140 BPM, Drop A starts about **12 seconds** in and Drop B about
   **36 seconds** in; the full phrase repeats after 48 seconds.
3. Move **Tempo**, **Master**, or the six bass sliders while playing. Bass
   changes affect new notes. A tempo change takes effect after the current
   bar; notes already sounding keep their original modulation rate.
4. Press **Stop** to fade and release the current loop. Press **Play** to
   restart the same loop from bar one. Close the window when finished; it
   stops the app and frees its owned audio resources. Evaluate `main.scd`
   again to reopen it.

While stopped, enter a **Seed**, adjust **Density** and **Variation**, or
choose **Destroyer** or **Reese Reply**. **Generate** rebuilds the 32-bar
event plan from those settings. The same settings produce the same planned
notes and drum hits. **New Seed** chooses another seed. **Defaults** restores
the starting controls. Both presets change the existing bass macro controls;
the notes still alternate growl and talking voices in the drops.

## If it does not start or you hear nothing

Look at the SuperCollider **Post Window**. An **Error** status in the app means
you should close its window, then evaluate `main.scd` again after addressing
the Post Window error. If the app says **Ready** and **Playing** but is silent,
check the Mac's selected sound output and volume, the app's Master control,
and any server or device errors in the Post Window. Closing the app does not
quit a SuperCollider server that was already running before this project.

For help, share the first error and nearby stack trace from the Post Window,
your macOS version, and the SuperCollider version shown in the IDE. This
project has received source review in a Linux cloud workspace; compilation,
GUI operation and listening on macOS 3.14.1 have not yet been verified.
