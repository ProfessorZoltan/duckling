# Audio credits

## Music (Freesound)

| Track | Source sound | Author | Freesound ID | License |
|---|---|---|---|---|
| `music/piano_gray.ogg` | Distant Sad Piano | patricklieberkind | 216669 | see note below |
| `music/piano_warm.ogg` | Peaceful Simple Piano | theojt | 510949 | see note below |

## Voices (Freesound)

| Files | Source sound | Author | Freesound ID | License |
|---|---|---|---|---|
| `sfx/quack_1..6.wav` | Generic Duck Quack Sound Effect | mastersoundboy2005 | 754978 | see note below |
| `sfx/squeak_1..5.wav` | Mouse Squeaks | shyguy014 | 463789 | see note below |
| `sfx/muffled_call.wav` | derived from quack 754978, slowed and low-passed | mastersoundboy2005 | 754978 | see note below |

## Water (Freesound)

| Files | Source pack | Author | Freesound ID | License |
|---|---|---|---|---|
| `sfx/splash_1..4.wav` | Waboba Moon Ball Water Splashes | qubodup | pack 46186 (sounds 867456–867464) | CC0 1.0, confirmed by the pack's own license file |

## Synthesized for this project

Generated procedurally, no third-party source: `sfx/peck_1..3.wav`, `sfx/shell_break.wav`,
`sfx/pickup.wav`, `sfx/flap_1..3.wav`, `sfx/hawk_pass.wav`, `sfx/growth_swell.wav`.

## LICENSE NOTE — ACTION NEEDED BEFORE RELEASE

Only the qubodup splash pack shipped with a license file, and it is CC0.
The other four Freesound sounds were downloaded without their license text,
and Freesound sounds carry a mix of CC0, CC BY 4.0, CC BY-NC and Sampling Plus.
Before shipping, open each sound's page and record its licence here:

- https://freesound.org/s/216669/  (piano_gray)
- https://freesound.org/s/510949/  (piano_warm)
- https://freesound.org/s/754978/  (quacks)
- https://freesound.org/s/463789/  (squeaks)

CC BY needs the author credited in-game or in the credits screen. CC BY-NC
cannot be used in a game sold for money, and would need replacing.

## Processing

Music was resampled to 44.1 kHz, peak-normalised and given a three-second
crossfade between the tail and the head so it loops without a seam, then
encoded to Ogg Vorbis. Voices and splashes were mixed to mono (so they can be
positioned in 3D), split on silence into single events, trimmed and normalised.
