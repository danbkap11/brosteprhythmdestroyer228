# Included one-shots

The original one-shots are **CC0 1.0** samples from
[Kringel samples](https://github.com/Gradigang-Solutions/kringel-samples)
at commit `60810ece266e94fdf1c91330a088ba3efb94041f`. They were converted to
mono 44.1 kHz, 16-bit PCM WAV with FFmpeg for simple SuperCollider loading.
The three toms were trimmed to 320 ms and faded at the end to fit a fast fill.
`reverse_crash.wav` reverses the included `crash.wav`. `snare_slam.wav` combines
the two included CC0 snares with bounded soft clipping and peak normalization.
The upstream [credits](https://github.com/Gradigang-Solutions/kringel-samples/blob/60810ece266e94fdf1c91330a088ba3efb94041f/CREDITS.md)
trace the Sonic Pi/Freesound and body-percussion origins. See
[LICENSE-CC0.txt](LICENSE-CC0.txt). No artist recordings or commercial sample
packs are included.

| Local file | Upstream file |
| --- | --- |
| `electro_kick.wav` | `SonicPiElectro/bd.flac` |
| `electro_snare.wav` | `SonicPiElectro/sd.flac` |
| `hard_snare.wav` | `SonicPiAcoustic/sd.flac` |
| `clap.wav` | `KringelPercussion/clap.wav` |
| `closed_hat.wav` | `SonicPiElectro/hh.flac` |
| `open_hat.wav` | `SonicPiElectro/oh.flac` |
| `crash.wav` | `SonicPiAcoustic/cr.flac` |
| `swoosh.wav` | `KringelTextures/swoosh.flac` |
| `glitch.wav` | `KringelTextures/glitch.flac` |
| `robot.wav` | `KringelTextures/robot.flac` |
| `tom_low.wav` | `SonicPiAcoustic/lt.flac` |
| `tom_mid.wav` | `SonicPiAcoustic/mt.flac` |
| `tom_high.wav` | `SonicPiAcoustic/ht.flac` |
| `reverse_crash.wav` | derived from `crash.wav` above |
| `snare_slam.wav` | derived from `hard_snare.wav` and `electro_snare.wav` above |

These are one-shot accents layered with the existing synthesized drums and
bass. The source collection is a practical licensed palette, not a claim that
these individual files were used in any particular 2012 track.

## Added transient and vocal one-shots

`hard_clap.wav`, `trap_snare.wav`, `tight_hat.wav`, and `long_open_hat.wav`
come from [Boochi44/free-drum-samples](https://github.com/Boochi44/free-drum-samples)
at commit `77ba31428a079dd8f17c8e144c1e649ea0a198b3`. Its README states that
all samples are CC0 1.0. The upstream files, respectively, are
`drum-samples/01-hard-trap/claps/clap-01.wav`,
`snares/hard-snare-01.wav`, `hi-hats/hi-hat-closed-01.wav`, and
`open-hats/open-hat-01.wav` under the same `01-hard-trap` folder. The local
versions were high-passed, trimmed, and faded to keep their transients short.

`vocal_shout.wav` is derived from the high-quality preview of
[“male_shout_01.wav” by slamaxu on Freesound](https://freesound.org/people/slamaxu/sounds/509885/),
which its sound page labels **Creative Commons 0**. The audible phrase was
trimmed from the preview, high-passed, faded and saved as mono 44.1 kHz PCM.
The app uses this original shout near one or both drops; its synthesized
`bbShout` remains a fallback if the file is missing. No commercial vocal or
artist recording is included.
