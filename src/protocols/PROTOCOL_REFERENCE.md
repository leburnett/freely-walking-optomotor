# Protocol Reference

Quick reference for all freely-walking optomotor protocols used in the Reiser Lab G3 LED arena experiments.

For detailed documentation with pattern previews, see the [protocol documentation site](https://burnettl.github.io/reiser-documentation/).
To create a new protocol, start from [`protocol_template.m`](protocol_template.m).

## Abbreviations

**Stimulus types:** G = Grating, F = Flicker, C = Curtain (ON/OFF), B = Bar/Fixation, R = Reverse Phi, S = Shifted CoR, DC = Different Contrasts, OD = One Direction, PA = Partial Arena

**Status:** Active = production experiments (t\_acclim\_start = 300s), Dev = development/testing (t\_acclim\_start = 30s), Legacy = older structure (v1-v9)

---

## Modern Protocols (all_conditions matrix structure)

| # | Description | Based On | Stimuli | Cond | Trial | Int | Acclim | Reps | Routing | Speed Summary | Status |
|--:|:------------|:---------|:--------|-----:|------:|----:|-------:|-----:|:--------|:--------------|:-------|
| 10 | Spatial freq, speed, trial length testing | — | G, F | 8 | 2-15s | — | 20s | 2 | optomotor | 4-8 Hz (30+60 deg) | Dev |
| 15 | Skinny bar gap testing (4ON:12OFF) | — | G, F | 3 | 15s | — | 20s | 2 | optomotor | 4 Hz | Dev |
| 16 | Skinny bar gap testing (2ON:6OFF) | 15 | G, F | 3 | 15s | — | 20s | 2 | optomotor | 4 Hz | Dev |
| 17 | 2ON:14OFF grating + flicker x4 | — | G, F | 4 | 15s | 20s | 10s | 1 | optomotor + flicker | ~8 Hz | Dev |
| 18 | Normal gratings + curtain ON/OFF (T4T5) | 10 | G, F, C | 6 | 15s | — | 2s | 2 | optomotor + curtain | ~4 Hz | Dev |
| 19 | Gratings, curtains, skinny bars (T4T5) | 18 | G, F, C | 12 | 15s | — | 20s | 2 | optomotor + curtain | ~4-8 Hz | Dev |
| 20 | Shifted centre of rotation (60 deg) | — | S | 6 | 15s | — | 20s | 2 | shifted | 4-8 Hz | Dev |
| 21 | Follow-up 1: greyscale interval, speed variants | 19 | G, F, C | 10 | 15s | — | 20s | 2 | optomotor + curtain | 4-8 Hz | Dev |
| 22 | Follow-up 2: bar fixation, reverse phi, FoE | 19 | B, R | 8 | 15s | — | 20s | 2 | fixation + optomotor | varies | Dev |
| 23 | Bar fixation contrast testing | 19 | B, G | 2 | 60s | — | 20s | 2 | fixation | static + 4 Hz | Dev |
| **24** | **Screen protocol 1** | 19 | G, F, C, R, B | 10 | 15s | 20s | 300s | 2 | mixed | 4-8 Hz | **Active** |
| **25** | Short protocol for individual flies | 24 | G, F | 4 | 15s | 20s | 300s | 2 | optomotor | ~4-8 Hz | **Active** |
| 26 | Curtain testing (32px, binary + greyscale) | 24 | C | 4 | 15s | 20s | 30s | 2 | curtain | 127 fps | Dev |
| **27** | **Screen protocol 2** (updated Mar 2025) | 24 | G, F, C, R, B, S | 12 | 15-45s | 20s | 300s | 2 | mixed | 4-8 Hz | **Active** |
| 28 | Reverse phi modifications (gs\_val=3, wider bars) | — | R | 5 | 15s | 15s | 30s | 2 | optomotor | varies | Dev |
| 29 | Screen protocol 3 (interval between CW/CCW) | 27 | G, F, C, R, B, S | 12 | 15-30s | 15s | 30s | 2 | mixed + w\_interval | 4-8 Hz | Dev |
| **30** | Different contrasts (7 levels) | 27 | DC | 7 | 15s | 20s | 300s | 2 | diff\_contrasts | 4 Hz (30 deg) | **Active** |
| **31** | 60 + 15 deg gratings at 4 different speeds | 27 | G, F | 10 | 15s | 20s | 300s | 2 | optomotor | 2-16 Hz | **Active** |
| **32** | Long trials, one direction (120s) | 31 | G, F, OD | 5 | 120s | 20s | 300s | 2 | one\_direction | 4 Hz | **Active** |
| 33 | Low luminance grating + flicker (gs=3, on=3) | — | G, F | 2 | 15s | 20s | 30s | 2 | optomotor | ~4 Hz | Dev |
| 34 | Low luminance grating + flicker (gs=3, on=1) | 33 | G, F | 2 | 15s | 20s | 30s | 2 | optomotor | ~4 Hz | Dev |
| 35 | Offset centre of rotation + screen stimuli | — | G, F, S | 10 | 30s | 20s | 30s | 2 | optomotor | 4 Hz | Dev |
| 36 | Offset CoR focused (60 deg only) | 35 | G, S | 4 | 30s | 20s | 30s | 2 | optomotor | 4 Hz | Dev |
| 37 | Partial arena tests (1/3, 1/2, speed-matched) | — | G, PA | 8 | 30s | 20s | 30s | 2 | optomotor | 4 Hz | Dev |

### Protocols with different structure (no all_conditions matrix)

| # | Description | Stimuli | Structure Notes | Status |
|--:|:------------|:--------|:----------------|:-------|
| 11 | Contrast sweep, all OFF interval | G | Direct variable assignments, contrast\_levels array | Dev |
| 12 | Contrast sweep, all ON interval | G | Direct variable assignments, contrast\_levels array | Dev |
| 13 | Very long blocks (60 trials/block) | G | Direct variable assignments | Dev |
| 14 | Different interval stimuli (flicker/static/ON/OFF) | G, F | 8 conditions via all\_conditions, older 6-col format | Dev |

---

## Legacy Protocols (v1-v10, r4)

These use an older structure with direct variable assignments (`optomotor_pattern`, `flicker_pattern`, `trial_len`, `t_acclim`, `contrast_levels`) rather than the `all_conditions` matrix. They are included for reference only.

| # | Description | Key Patterns | Trial | Acclim | Reps | Notes |
|--:|:------------|:-------------|------:|-------:|-----:|:------|
| v1 | HMS experiments (June 2024) | 1, 7 | 10s | 10s | 2 | First protocol. SS00324\_T4T5. |
| v2 | All high contrast optomotor | 1, 7 | 10s | 60s | 2 | CS\_w1118. 7 contrast levels. |
| v3 | One direction optomotor | 1, 7 | 10s | 60s | 2 | No direction alternation. |
| v4 | Switch intervals (short to long) | 1, 7 | 2-120s | 20s | 2 | Trial lengths: 2,5,10,20,30,60,120s. |
| v5 | Short test for individual flies | 1, 7 | 10s | 10s | 2 | Quick single-fly assessment. |
| v6 | Shifted centre of rotation | 3, 7 | 10s | var | 2 | con\_val selects shift amount. |
| v7 | Different speeds (Hz sweep) | 6, 7 | 10s | var | 2 | hz\_val selects: 1, 2, 4, 8 Hz. |
| v8 | 4 pixel stripes (15 deg) | 4, 5 | 10s | 20s | 2 | Narrow spatial frequency. |
| v9 | Different spatial frequencies | 4-10 | 10s | 20s | 2 | 15, 30, 60 deg gratings. |
| v10 | All tests (freq, speed, trial lengths) | 6,7,9,10 | 2-15s | 20s | 2 | Combined parameter sweep. |
| r4 | Reverse of v4 (long to short) | 1, 7 | 120-2s | 20s | 2 | Mirror of v4 trial order. |

---

## Protocol Lineage

```
v1 ─> v2 ─> v3, v4/r4, v5, v6, v7, v8, v9
                                              ╲
                                v10 ─> 10 ─> 18 ─> 19 ─> 24 (Screen 1) ─> 25
                                                     │                  ╲
                                                     ├─> 20              27 (Screen 2) ─> 29 (Screen 3)
                                                     ├─> 21                             ╲
                                                     ├─> 22                              ├─> 30
                                                     └─> 23                              ├─> 31 ─> 32
                                                                                         └─> 35 ─> 36
Standalone: 15/16, 17, 26, 28, 33/34, 37
```

---

## Routing Reference

| Routing Type | Function | Protocols Using It |
|:-------------|:---------|:-------------------|
| optomotor | `present_optomotor_stimulus` | 10, 15, 16, 25, 28, 31, 33, 34, 35, 36, 37 |
| curtain | `present_optomotor_stimulus_curtain` | 18, 26 |
| fixation | `present_fixation_stimulus` | 23 |
| shifted | `present_shifted_stimulus` | 20 |
| one\_direction | `present_optomotor_stimulus_one_direction` | 32 |
| diff\_contrasts | `present_optomotor_stimulus_diff_contrasts` | 30 |
| mixed | Multiple functions via if/elseif | 19, 21, 22, 24, 27 |
| mixed + w\_interval | With interval between CW/CCW | 29 |

---

## Key Patterns Reference

### Gratings (moving stripes)

| Pattern | Spatial Period | Step Size | Description | Used In |
|--------:|:---------------|:----------|:------------|:--------|
| 1 | 16 px (30 deg) | 1 px/f | 30 deg grating, 7 contrast levels (gs\_val=3) | 30, v1-v5 |
| 4 | 8 px (15 deg) | 1 px/f | 15 deg grating, binary | 15, 16, 19, 31, 32 |
| 6 | 16 px (30 deg) | 1 px/f | 30 deg grating, binary | 10, 35, v7, v9 |
| 9 | 32 px (60 deg) | 1 px/f | 60 deg grating, binary | 10, 19, 24, 27, 29, 31, 35-37 |
| 17 | 16 px (30 deg) | 1 px/f | 2ON:14OFF skinny bar, binary | 17, 19, 24, 27, 29 |
| 24 | 16 px (30 deg) | 1 px/f | 2OFF:14ON skinny bar, binary | 19, 24, 27, 29 |
| 27 | 32 px (60 deg) | 2 px/f | 60 deg grating, 2px step, binary | 21, 24, 25, 27, 29, 31 |
| 63 | 8 px (15 deg) | 2 px/f | 15 deg grating, 2px step, binary | 31 |
| 64 | 32 px (60 deg) | 1 px/f | 60 deg grating, low lum (gs=3, on=3) | 33 |
| 66 | 32 px (60 deg) | 1 px/f | 60 deg grating, very low lum (gs=1, on=1) | — |
| 69 | 32 px (60 deg) | 1 px/f | 60 deg grating, low lum (gs=3, on=3) | 34 |

### Flicker (temporal contrast, no motion)

| Pattern | Spatial Period | Description | Used In |
|--------:|:---------------|:------------|:--------|
| 5 | 8 px (15 deg) | 15 deg flicker, binary | 10, 15, 16, 31, 32 |
| 7 | 16 px (30 deg) | 30 deg flicker, binary | 10, 35, v1-v9 |
| 10 | 32 px (60 deg) | 60 deg flicker, binary | 19, 24, 25, 27, 29, 31, 35 |
| 65 | 32 px (60 deg) | 60 deg flicker, low lum (gs=3) | 33 |
| 67/68 | 32 px (60 deg) | 60 deg flicker, very low lum | 34 |

### Curtains (progressive edge)

| Pattern | Width | Description | Used In |
|--------:|------:|:------------|:--------|
| 19 | 16 px | ON curtain (expanding ON edge) | 18, 19, 21, 24 |
| 20 | 16 px | OFF curtain (expanding OFF edge) | 18, 19, 21, 24 |
| 51 | 32 px | ON curtain (wider bars) | 26, 27, 29 |
| 52 | 32 px | OFF curtain (wider bars) | 26, 27, 29 |

### Reverse Phi (contrast-reversing motion)

| Pattern | Bar Width | Step | GS Val | Used In |
|--------:|:----------|:-----|-------:|:--------|
| 32 | 8+8 px | 4 px/f | 4 | 24, 27 |
| 58 | 8+24 px | 4 px/f | 3 | 28 |
| 59 | 16+16 px | 4 px/f | 3 | 28 |
| 60 | 16+16 px | 8 px/f | 3 | 27, 28, 29 |
| 61 | 16+16 px | 4 px/f | 3 | 28 |
| 62 | 16+16 px | 4 px/f | 2 | — |

### Shifted / Offset Centre of Rotation

| Pattern | Spatial Period | Shift | Used In |
|--------:|:---------------|:------|:--------|
| 21 | 60 deg | 0.8 | 24 (commented out), 27, 29, 35, 36 |
| 22 | 60 deg | 0.0 | 20 |
| 23 | 60 deg | -0.8 | 20 |
| 70 | 30 deg | +0.75 | 35 |
| 71 | 30 deg | -0.75 | 35 |
| 72 | 60 deg | +0.75 | 35, 36 |
| 73 | 60 deg | -0.75 | 35, 36 |

### Partial Arena

| Pattern | Coverage | Step | Description | Used In |
|--------:|:---------|:-----|:------------|:--------|
| 74 | 1/3 (cols 129-192) | 1 px/f | 60 deg, third A | 37 |
| 75 | 1/3 (cols 64-128) | 1 px/f | 60 deg, third B | 37 |
| 76 | 1/3 (cols 1-64) | 1 px/f | 60 deg, third C | 37 |
| 77 | 1/2 (cols 97-192) | 1 px/f | 60 deg, half arena | 37 |
| 78 | 1/2 (cols 97-192) | 2 px/f | 60 deg, half, double speed | 37 |
| 79 | 1/2 (cols 97-192) | 3 px/f | 60 deg, half, triple speed | 37 |
| 80 | Full (split) | mixed | 60 deg (2px) left + 30 deg (1px) right | 37 |

### Background / Calibration

| Pattern | Description | Used As |
|--------:|:------------|:--------|
| 25 | Greyscale background (gs\_val=4, value=3) | Interval in protocol\_32 |
| 29 | Greyscale background (gs\_val=4, value=1) | Interval in protocol\_21 |
| 47 | Dark background (all OFF) | Standard interval in most protocols |
| 48 | Full field ON/OFF flash | Calibration only (not a stimulus) |

### Fixation / Bar Patterns

| Pattern | Width | Type | Used In |
|--------:|------:|:-----|:--------|
| 30 | 4 px | Single bar fixation | 22 |
| 37-44 | 8 px | Bar fixation (ON/OFF, various contrasts) | 22, 23 |
| 45-46 | 16 px | Bar fixation (ON/OFF) | 23 |
| 49-50 | 16 px | Bar fixation (ON/OFF, 3 contrast) | 24 (commented out) |
| 57 | 32 px | Single bar ON | 27, 29 |

---

## Speed Quick-Reference

The `speed_patt` value in `all_conditions` column 3 = frames per second (fps).
Temporal frequency depends on the pattern:

**TF (Hz) = fps x step\_size / spatial\_period\_px**

| Pattern Type | Period | Step | spd 8 | spd 16 | spd 32 | spd 64 | spd 127 |
|:-------------|-------:|-----:|------:|-------:|-------:|-------:|--------:|
| 15 deg grating (4) | 8 px | 1 px/f | 1 Hz | 2 Hz | 4 Hz | 8 Hz | ~16 Hz |
| 30 deg grating (6) | 16 px | 1 px/f | 0.5 Hz | 1 Hz | 2 Hz | 4 Hz | ~8 Hz |
| 60 deg grating (9) | 32 px | 1 px/f | 0.25 Hz | 0.5 Hz | 1 Hz | 2 Hz | ~4 Hz |
| 60 deg 2px step (27) | 32 px | 2 px/f | 0.5 Hz | 1 Hz | 2 Hz | 4 Hz | ~8 Hz |
| 15 deg 2px step (63) | 8 px | 2 px/f | 2 Hz | 4 Hz | 8 Hz | 16 Hz | ~32 Hz |

**Velocity (deg/s) = TF x spatial\_period\_deg**

For example: Pattern 9 at speed 127 → TF = 127/32 ≈ 4 Hz → Velocity = 4 × 60 = 240 deg/s
