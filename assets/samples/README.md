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

`attack_kick.wav` comes from the high-quality preview of
[“Kick - Attack.wav” by TechGeekMusic](https://freesound.org/people/TechGeekMusic/sounds/353395/),
and `beefy_snare.wav` from the high-quality preview of
[“Dubstep Snare #2 - Beefy” by mrbossosity](https://freesound.org/people/mrbossosity/sounds/774955/).
Both sound pages label the sounds **Creative Commons 0**. The local versions
were trimmed, high-passed, faded and reduced in level before conversion to
mono 44.1 kHz, 16-bit PCM WAV. The kick supplies attack above the synthesized
kick's low body; the snare replaces the former stack of multiple snare samples
on drop beats. These are style-appropriate licensed one-shots, not a claim of
being the exact samples used in any artist's recording.

## Bass chops and brostep snare — 2026-10-11 rework

Each source page below explicitly labels its sound **Creative Commons 0**.
The downloads were the public `hq.mp3` previews, converted to mono 44.1 kHz,
16-bit PCM WAV. Conversion does not restore the lossless originals; those
original downloads require a Freesound account. Local peaks were normalized
to 0.85, with short end fades to avoid cut clicks.

| Local file | Source | Local treatment |
| --- | --- | --- |
| `growl_e_hit.wav` | [1 Hit Growl_Bass_E.wav — MichaelMalong, 360545](https://freesound.org/people/MichaelMalong/sounds/360545/) | 290 ms, 125 Hz high-pass, 20 ms end fade; source fundamental near E1. |
| `reese_f_call.wav` | [Growly F.wav — TechGeekMusic, 353268](https://freesound.org/people/TechGeekMusic/sounds/353268/) | 1.15 s, 125 Hz high-pass, 70 ms end fade; source fundamental near F1. |
| `brostep_snare.wav` | [Brostep - Wide Punchy Snare — Hybrid_V, 319613](https://freesound.org/people/Hybrid_V/sounds/319613/) | 600 ms, 95 Hz high-pass, 60 ms end fade; retained low-mid body. |

Preview URLs:

- `https://cdn.freesound.org/previews/360/360545_5916931-hq.mp3`
- `https://cdn.freesound.org/previews/353/353268_6397561-hq.mp3`
- `https://cdn.freesound.org/previews/319/319613_5436764-hq.mp3`

`bbBassSample` replaces a selected synthesized mid-bass event; it does not
stack an extra low bass underneath it. The sequencer's E2/F2 reference values
match its upper-bass note register while retaining the recordings' lower
source register. For example, D2/E2 playback transposes the E1 recording to
D1; high-pass processing keeps its upper harmonics while the separate sub
supplies the clean D1 fundamental. Sample pitch ratios are bounded, all six
macros affect processing, and a finite envelope owns each node's lifetime.
