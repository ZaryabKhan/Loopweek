# Design — Loopweek

<!-- impeccable:design-schema 1 -->

## Platform & Stack

Android. Flutter (Material 3), surface-driven; no backend. All decisions below must
stay achievable with the app's flat, offline, single-accent system.

## Positioning (brief)

Loopweek is a free, fully open-source weekly to-do app whose entire value is constraint:
one screen, seven days, nothing else. The week is the screen; the accordion keeps one day
open at a time; tasks never roll over. Success is planning and completing a week without
ever leaving one screen and without the app asking anything of the user.

Mode: **Operate** — the user completes the task of planning/checking the week; scanability,
predictability, and the real everyday usage scene outrank expression. Brand lives in precise
details, not decoration.

## Visual World — "the week, and nothing else"

A flat, quiet system where **constraint itself is the signature**: one accent color, dividers
instead of shadows, tight condensed display type, generous near-empty space. Nothing vies for
attention because the week is the only thing on screen.

### Palette

- **Accent (one, per user):** default orange `#F4511E`; alt pink `#E91E63`, blue `#1E88E5`,
  green `#43A047`. The same accent drives active checkboxes, selected segmented option, toggles,
  primary actions, and the home widget. (see `lib/core/theme/accent_colors.dart`)
- **Light:** scaffold off-white `#F2F2F2`, surface white `#FFFFFF`, divider `#E0E0E0`.
- **Dark:** scaffold near-black `#121212`, surface `#1E1E1E`, divider `#2A2A2A`.
- **Never pure black/white**; flat surfaces, elevation 0, dividers do the separating.

### Type

Bold, tight-tracking, condensed sans-serif for day headers and section titles (heavy weight,
slightly reduced letter-spacing, e.g. `-0.6`; approximated with Material stack offline). Body
is plain and quiet. (see `lib/core/theme/app_theme.dart`)

### Shape & motion

Moderate corner radius (~10–12dp); toggles stay pill; no shadows, no gradient, no glass.
Interaction is tap + long-press only; no swipe.

## Brand Mark — "the week loops"

The logo is a **seven-segment open loop**: a bold ring broken into seven chunky rounded
segments — the seven days — with a deliberate **opening at the top** so it reads as an open
*loop* that returns (the weekly cycle, one screen, no escape). The **leading segment after the
opening is "today" in the default accent orange `#F4511E`**; the other six are the ink
`#121212`. It sits on the flat off-white tile `#F2F2F2`.

- Flat, single-accent, no shadow/gradient — it obeys the same system as the app surfaces.
- Ownable, not a generic check or calendar: the loop of seven days is the product's exact idea.
- The mark is the brand; there is no text in the launcher mark (the launcher label is the name).

### Audio description / how to read it

"Seven rounded ticks arranged in a circle, open like a loop at the top; the first tick after the
gap is orange — today — while the rest of the week is dark."

### Files

- Raster identity: `docs/brand/logo-mark.png` (1024, light), `logo-mark-transparent.png`.
- Generator (source of truth, rerun to regenerate all densities):
  `docs/brand/generate_logo.py` — outputs every Android density + adaptive foreground/background.
- Installed Android assets: `android/app/src/main/res/mipmap-*/ic_launcher*.png` and the
  adaptive `mipmap-anydpi-v26/ic_launcher.xml` (background `@color/ic_launcher_background`).

### Do not

- Do not add gradients, shadows, gloss, or a second color to the mark.
- Do not put the wordmark inside the launcher icon.
- Do not reinterpret "today" in a third color; the mark stays orange-on-ink on off-white.

## Component language

- Single-open-day accordion, today expanded by default, tapping a day swaps it.
- Cards are flat white/`#1E1E1E` with elevation 0 and a 12dp radius; dividers separate rows.
- The one accent appears only where action or selection lives.
