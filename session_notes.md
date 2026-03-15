# Session Notes — Freely Walking Optomotor Manuscript

## 2026-03-13 (cont'd): Figure 1 — Experimental System & the Centring Phenomenon

**New script:** `src/plotting/figures/fig1_centring.m`
**Phase:** 3 (Figure Generation)

### What was done
Created standalone Figure 1 script with 6 panels in a 2×3 `tiledlayout`:

| Panel | Content | Implementation |
|-------|---------|---------------|
| A | Arena schematic | Placeholder (Illustrator) |
| B | Example trajectories (3 control flies, cond 1) | Pre/during/post colored (grey/blue/grey). Fly IDs [807,802,791] from fig1_plots.m |
| C | Mean ± SEM dist_data time series | QC-filtered via `combine_timeseries_across_exp_check` |
| D | Baseline-subtracted dist_data_delta | Subtracted frame 300 baseline |
| E | Occupancy heatmaps (pre vs during) | 2 side-by-side axes from split tile. Adapted from `plot_fly_occupancy_heatmaps_all.m` |
| F | Start vs end distance scatter | Unity line. Below = centring. Adapted from `dv_dist_data.m` |

### Design decisions
- **All inline drawing** — no calls to `plot_trajectory_condition`, `plot_fly_occupancy_heatmaps_all`, or `plot_xcond_per_strain2`. These existing functions create their own figures/legends. For composed multi-panel figures we need direct control over each axes.
- **Panel E tile split:** Used `nexttile(5)` → get position → delete → create 2 manual `axes()` at left/right halves. Standard MATLAB pattern for sub-dividing tiledlayout tiles.
- **`combine_timeseries_across_exp`** (no QC) for x/y trajectory data; `combine_timeseries_across_exp_check` (quiescence QC) for dist_data.
- Saves to `figures/manuscript/fig1_centring.pdf` as vector graphics.

---

## 2026-03-13 (cont'd): Heading-Shuffle Null Model — Centring Exceeds Geometric Expectation

**New script:** `src/model/centring_null_model.m`

### What was done
Per-fly heading-shuffle permutation test (N=1000 iterations) for control flies (P27, condition 1, 60deg 4Hz). For each fly, the frame-to-frame heading changes (dθ) during the stimulus period (frames 300–1200) are randomly permuted, and the trajectory is reconstructed using the original speeds and starting position. This preserves each fly's turning rate distribution and speed profile but breaks any temporal correlation between position and heading direction.

If centring is merely a geometric consequence of curved walking in a bounded circular arena, shuffled trajectories should produce similar centring. If centring is an active behaviour, observed centring should far exceed the null distribution.

### Implementation details
- Loads control data via `combine_timeseries_across_exp_check` (quiescence QC)
- Arena constants: PPM=4.1691, CX=528/PPM, CY=520/PPM, ARENA_R=496/PPM (~119 mm)
- Heading changes computed in radians, wrapped to [-π, π]
- Speeds converted to mm/frame (vel × dt)
- Boundary reflection at arena wall: if reconstructed position exceeds ARENA_R, heading is flipped by π and position stays put (matching `simulate_walking_viewdist_gain.m` logic)
- Local helper: `reconstruct_trajectory_shuffled(x0, y0, theta0, dtheta_shuffled, speeds, CX, CY, ARENA_R)`
- 3-panel figure: (A) histogram of observed vs null per-fly centring, (B) timeseries with null 95% CI envelope, (C) per-fly scatter observed vs shuffled

### Results

| Metric | Value |
|--------|-------|
| **Observed centring** | **-17.8 ± 0.8 mm** (mean ± SEM, N=425 flies) |
| **Null centring** | **-1.4 ± 0.2 mm** (mean ± SD of shuffle means) |
| **Z-score** | **-98.5** |
| **Population p-value** | **0** (empirical, 1000 shuffles) |
| Per-fly significant (p<0.05) | 345/425 (81%) |
| Median per-fly p-value | 0.0040 |
| Mean null centring per fly | -1.4 mm |

**Observed centring is 12.7× stronger than the geometric expectation from shuffled heading changes.** The null distribution is centred near zero (slight negative bias of -1.4 mm likely reflects boundary effects in the circular arena), while observed centring is -17.8 mm — completely outside the null range.

### Interpretation
- Centring is NOT a geometric artifact of curved walking in a bounded arena
- The temporal ordering of heading changes matters — flies actively adjust their heading relative to their position
- Even the 19% of flies that are not individually significant likely have weak centring (the test is conservative for flies with few valid frames or that start near the centre)
- The z-score of -98.5 corresponds to a vanishingly small p-value — the observed population mean is ~100 standard deviations below the null expectation

### Manuscript implications
- This is the definitive control for the "geometric artifact" alternative explanation
- Can be cited as: "Heading-shuffle permutation test (1000 iterations per fly, N=425) confirmed that observed centring (-17.8 mm) far exceeded geometric expectations from random walking (-1.4 mm; z = -98.5, p < 0.001)"
- The null model also provides a useful baseline for interpreting strain effects: if a strain's centring falls within the null range, centring may be abolished

---

## 2026-03-13: Cross-strain x cross-condition heatmaps (Figure 10)

**New script:** `src/plotting/figures/cross_strain_condition_heatmaps.m`

### What was done
Created standalone `cross_strain_condition_heatmaps.m` (1x2 panels):
- **Panel A — Centring**: Relative distance at end of stimulus (Dist-rel-end metric from `dist_metric_tests`)
- **Panel B — Turning**: Mean turning rate during stimulus (Turning-stim metric from `curv_metric_tests`)

Both are strains (rows) x conditions 1-12 (columns) heatmaps. Each cell compares one strain vs ES control (Welch's t-test), with FDR correction across all comparisons (q<0.05). Color scheme: red = target metric value higher than control, blue = lower, intensity = significance level.

### Implementation details
- Reuses existing `make_pvalue_heatmap_across_strains(DATA, condition_n)` for all 12 conditions
- Extracts specific metric columns from the 6-metric output: col 6 (centring), col 3 (turning)
- `build_heatmap_rgb` local helper function mirrors the existing `mapValues`/`plot_pval_heatmap` color scheme
- FDR correction is joint across both panels (2 x n_strains x 12 comparisons)

### Results — key findings

**Overall:** Centring 34/192 cells significant; Turning 72/192 cells significant (FDR q<0.05).

#### Key dissociations (centring vs turning)

1. **Tm5Y (ss03722):** Enhanced centring (RED in 60deg 4Hz p=4.9e-11, ON bars p=4.2e-10, OFF bars p=4.0e-3) but NORMAL turning (no sig cells except RevPhi). **This is the critical dissociation** — more centring without more turning, suggesting centring can be upregulated independently of optomotor response.

2. **TmY20 (ss2603):** Reduced centring (BLUE in 60deg 4Hz/8Hz, ON/OFF bars, OFF curtains, Offset CoR) but INCREASED turning (RED in 60deg 4Hz/8Hz, ON/OFF bars, ON curtains, Offset CoR). **Opposite direction** — these flies turn more but centre less.

3. **T4/T5 combined (ss324):** Abolished BOTH turning (BLUE, p~1e-123 to 1e-142 for gratings/bars) AND centring (BLUE, p~1e-9 to 1e-16). Classic motion-blind phenotype — near-zero turning rate values (~5 deg/s vs 80 control).

4. **T4-only (ss2344):** INCREASED turning (RED in 60deg 4Hz/8Hz, ON bars, OFF bars, OFF curtains, Offset CoR) but centring NOT significantly different (mostly p>0.05). Compensatory response — silencing T4 alone doesn't abolish motion vision.

5. **T5-only (ss2571):** INCREASED turning (RED in 60deg 4Hz/8Hz, ON bars, ON curtains, Offset CoR) and slightly MORE centring (RED in ON curtains p=3.5e-2). Similar to T4-only — individual pathway silencing is compensated.

6. **Dm4 (ss00297):** Reduced centring (BLUE in 60deg 4Hz p=5.5e-10, 8Hz p=5.4e-25, OFF curtains p=3.5e-12, Offset CoR p=4.6e-20) but turning only increased for bars (RED ON bars p=3.5e-10, OFF bars p=1.4e-4). **Selective** — centring impairment broader than turning change.

#### Stimulus specificity

- **Reverse phi (conds 7-8):** Generally NOT significant for centring across strains. But L1/L4 and T4/T5 show RED (increased) turning for RevPhi — reversed optomotor response when primary pathways are silenced.
- **Flicker (cond 9) & Static (cond 10):** Mostly white (not significant). Exception: Am1 shows BLUE centring for flicker (p=4.2e-4) and static (p=4.9e-3) — specific deficit.
- **Bar fixation (cond 12):** Mostly white. Not a centring-driving stimulus.
- **Am1 (ss34318):** BLUE centring in flicker, static, AND Offset CoR (p=4.9e-12) but NOT in standard gratings. Unusual pattern — may relate to adaptation or static pattern responses rather than motion processing.

#### Control validations
- **L1/L4:** Severely impaired across the board (BLUE everywhere) — confirms screen sensitivity
- **Pm2ab (ss00326):** No centring phenotype but INCREASED turning (RED) across most conditions — another centring-turning dissociation
- **H1 (ss26283):** Reduced centring (BLUE) at 8Hz and Offset CoR, but INCREASED turning (RED) across many conditions — same dissociation pattern as TmY20

#### Raw mean values (condition 1, 60deg 4Hz)
- Control centring: -32.8 mm (strong centring)
- Tm5Y: -49.1 mm (strongest centring of any strain)
- T4/T5: -17.6 mm (reduced by ~46%)
- L1/L4: -4.1 mm (nearly abolished, ~88% reduction)
- Dm4: -12.9 mm (reduced by ~61%)
- TmY20: -23.8 mm (reduced by ~27%)
- Control turning: 79.6 deg/s
- T4/T5: 5.2 deg/s (nearly abolished)
- L1/L4: 2.6 deg/s (nearly abolished)
- T4-only: 110.3 deg/s (38% increase)
- TmY20: 114.9 deg/s (44% increase)

### Interpretations

#### Tm5Y: "personal space" / proximity avoidance hypothesis
Tm5Y cells may normally mediate a proximity-avoidance or "personal space" mechanism — a tendency to maintain distance from nearby visual features (the arena wall). Silencing Tm5Y removes this avoidance, allowing flies to centre more aggressively. This is consistent with the phenotype: enhanced centring with unchanged turning. The centring enhancement is NOT because the flies turn more — their optomotor turning is normal — but because a separate spatial-positioning signal that normally counteracts full centring is removed. This would place Tm5Y in a pathway that computes distance-to-wall or looming/proximity information and feeds into a positional control system parallel to the optomotor turning pathway.

#### Visual projection neurons (Am1, H1, H2, DCH-VCH): binocular integration
Am1, H1, H2, and DCH-VCH all show centring deficits that are specifically worse for the faster 8Hz gratings and the offset CoR condition, while standard 4Hz gratings are less affected. These neurons are visual projection neurons (VPNs) at the output side of the visual system, thought to be involved in:
- Integrating information across both eyes (binocular processing)
- Complex visual processing over the entire field of view

This pattern makes sense: centring to offset gratings requires comparing optic flow across the full visual field to find the CoR, and faster gratings (8Hz) may require more sophisticated temporal integration. These are exactly the conditions where whole-field or binocular integration would be most critical. Standard 4Hz centred gratings may be simple enough that local motion circuits suffice, but offset CoR and high temporal frequency demand the kind of global integration these VPNs provide.

Specific p-values for the VPN cluster (centring, BLUE = reduced):
- **Am1:** 8Hz p=1.8e-2, Offset CoR p=4.9e-12, Flicker p=4.2e-4, Static p=4.9e-3
- **H1:** 8Hz p=5.2e-7, Offset CoR p=3.9e-2
- **H2:** 8Hz p=1.1e-4
- **DCH-VCH:** 8Hz p=3.1e-5, Offset CoR p=1.2e-2

### Manuscript implications

The heatmap reveals four classes of strain phenotype:
1. **Motion-blind (T4/T5, L1/L4):** Both turning and centring abolished — centring requires motion processing
2. **Centring-turning dissociation (Tm5Y, TmY20, Pm2ab, H1):** Turning intact or increased but centring impaired (TmY20) or enhanced (Tm5Y) — centring is not a simple byproduct of turning
3. **Proximity/spatial regulation (Tm5Y):** Enhanced centring with normal turning — silencing removes a "personal space" mechanism that normally limits centring. Places Tm5Y in a distance-to-wall / proximity avoidance pathway parallel to optomotor turning.
4. **Visual projection neuron cluster (Am1, H1, H2, DCH-VCH):** Centring deficits specifically at 8Hz and offset CoR — conditions requiring binocular/whole-field integration. Consistent with their known role in integrating visual information across both eyes and the full visual field.
5. **Selective condition effects (Dm4):** Broad centring impairment but turning increase only for bars — suggests modular processing

### Next steps
- Continue with remaining Phase 2 tasks: P31 speed analysis, null model

---

## 2026-03-13 (cont'd): Centring-vs-turning scatter across strains

**New script:** `src/plotting/figures/centring_vs_turning_scatter.m`

### What was done
Created standalone scatter plot: each point is one strain (condition 1, 60deg 4Hz).
- X-axis: mean turning rate during stimulus (deg/s)
- Y-axis: mean centring (relative distance at end of stimulus, mm) — axis reversed so MORE centring = UP
- Grey crosshairs at ES control values; control point labelled
- All strain labels annotated on points
- Spearman correlation and per-strain summary table printed to console

### Results

**Spearman correlation: rho = -0.006, p = 0.987** — essentially zero. Turning rate does NOT predict centring across strains.

This is the single strongest argument that centring is not a simple byproduct of optomotor turning: strains that turn more do not necessarily centre more, and vice versa.

Key positions in the scatter:

| Strain | Turning (deg/s) | Centring (mm) | Interpretation |
|--------|-----------------|---------------|----------------|
| ES control | 79.6 | -32.8 | Reference |
| Tm5Y | 75.6 | -49.1 | Normal turning, ENHANCED centring |
| TmY20 | 114.9 | -23.8 | HIGH turning, reduced centring |
| H1 | 105.0 | -27.2 | HIGH turning, reduced centring |
| Pm2ab | 108.0 | -38.4 | HIGH turning, normal centring |
| T4/T5 | 5.2 | -17.6 | Both abolished (motion-blind) |
| L1/L4 | 2.6 | -4.1 | Both abolished (motion-blind) |
| T4-only | 110.3 | -26.1 | HIGH turning, slightly reduced centring |
| Dm4 | 86.0 | -12.9 | Normal turning, severely reduced centring |
| TmY3 | 55.9 | -39.8 | Reduced turning, normal centring |

Notable dissociations:
- **Tm5Y** has control-level turning but the STRONGEST centring of any strain — confirms "personal space" hypothesis
- **TmY20** turns 44% more than control but centres 27% less — opposite directions
- **Dm4** turns normally but centres 61% less — centring impaired independently of turning
- **TmY3** turns 30% less than control but centres normally — turning deficit doesn't impair centring

---

## 2026-03-13 (cont'd): P31 Speed Tuning — Centring & Turning

**New script:** `src/plotting/figures/p31_speed_tuning_centring.m`

### What was done
Speed tuning curves for centring (dist_data_delta) and turning (av_data) across 6 P31 strains: control (N=46), L1/L4 (N=16), Dm4/ss00297 (N=76), Pm2ab (N=61), T4-only (N=15), T4/T5 (N=48). Two spatial frequencies: 60deg and 15deg gratings. Excluded csw1118 and ss02360_Dm4.

### Key findings

#### 1. Centring IS speed-tuned
Control centring varies with speed:
- **60deg:** peaks at 240 deg/s (-24.0 mm), declining at 480 (-19.9)
- **15deg:** monotonically increases, peaking at 480 deg/s (-30.0 mm)
- Centring speed tuning roughly tracks turning speed tuning but is NOT identical — 60deg centring peaks at 240 while turning is still increasing at 480

#### 2. Dm4: most consistent centring deficit
Dm4 centring is impaired at ALL speeds and BOTH spatial frequencies:
- 60deg: -5.3 to -8.3 mm vs control -14.7 to -24.0 (p = 1.9e-3 to 4.8e-8)
- 15deg: -1.5 to -19.1 mm vs control -6.0 to -30.0 (p = 1.1e-2 to 2.2e-4)
- Turning is largely NORMAL (no sig difference except marginal at 120 and 480 for 60deg)
- **This confirms P27 finding:** Dm4 impairs centring without abolishing turning

#### 3. T4/T5 centring less impaired than turning
T4/T5 turning is near-zero across all speeds (~5-20 vs 30-187 control), yet centring is only moderately reduced:
- 60deg: -12.9 to -16.9 vs control -14.7 to -24.0 (sig only at 240 and 480, p = 0.015 and 0.023)
- 15deg at low speeds: -13.1 at 60 deg/s and -21.0 at 120 deg/s — essentially EQUAL to control (-6.0 and -19.4)
- 15deg at 480: -8.7 vs -30.0 (p = 1.3e-6) — strongly impaired
- **Implication:** At lower speeds, T4/T5 flies can centre without optomotor turning — other sensory cues may contribute

#### 4. L1/L4 speed-selective centring deficit
L1/L4 centring is impaired selectively at higher speeds:
- 60deg: significant at 120 (p=0.036) and 480 (p=0.010) but NOT at 60 or 240
- 15deg: strongly impaired at 240 (p=2.1e-6) and 480 (p=2.3e-4) but NOT at 60 or 120
- Turning is abolished across the board (all p < 1e-11)

#### 5. Flicker centring is a genuine behaviour
Control flicker centring: -16.6 mm (60deg) and -9.5 mm (15deg). Rather than baseline drift, this appears to be a genuine centring response to luminance modulation itself. T4/T5 also shows flicker centring (-19.0 mm for 60deg, -6.6 mm for 15deg), confirming it does not require direction-selective motion processing.

### Interpretations

#### Two-component model: flicker centring + motion centring
The data support a model where **total centring = flicker/luminance centring + motion-specific centring**:

- **Flicker centring:** T4/T5-independent, driven by luminance modulation. Present for both gratings AND flicker stimuli. Has its own temporal frequency limit.
- **Motion centring:** T4/T5-dependent, driven by directional motion signals. Adds on top of the flicker component for grating stimuli.

Key evidence — T4/T5 15deg centring matches control except at 480 deg/s:

| Speed | Control | T4/T5 | Notes |
|-------|---------|-------|-------|
| 60 | -6.0 | -13.1 | T4/T5 MORE than control |
| 120 | -19.4 | -21.0 | Matched |
| 240 | -29.2 | -29.8 | Matched |
| 480 | -30.0 | -8.7 | Collapsed (p=1.3e-6) |
| Flicker | -9.5 | -6.6 | Both present |

Despite near-zero turning (~3-5 deg/s), T4/T5 centres as well as controls at 60-240 deg/s. The flicker/luminance component alone is sufficient at these speeds. At 480 deg/s (= 32 Hz temporal frequency for 15deg), T4/T5 centring collapses — the luminance pathway has a temporal frequency ceiling below 32 Hz.

**Dm4 interpretation in this framework:** Dm4 impairs centring across ALL speeds and flicker (-5.2 mm vs control -16.6 mm for 60deg flicker). This suggests Dm4 affects the luminance/flicker centring pathway, not just the motion pathway. Dm4 cells may be upstream of both centring mechanisms.

### Raw values — 60deg centring (mm)

| Strain | 60 | 120 | 240 | 480 | Flicker |
|--------|-----|------|------|------|---------|
| Control | -14.7 | -21.6 | -24.0 | -19.9 | -16.6 |
| T4/T5 | -12.9 | -16.9 | -14.3 | -13.0 | -19.0 |
| L1/L4 | -12.2 | -11.2 | -13.7 | -8.6 | -12.3 |
| Dm4 | -5.3 | -5.6 | -8.3 | -7.0 | -5.2 |
| Pm2ab | -11.4 | -11.7 | -17.6 | -15.3 | -7.9 |
| T4-only | -12.6 | -6.9 | -21.5 | -18.2 | -21.0 |

### Manuscript implications
- Speed tuning of centring can be plotted alongside speed tuning of turning (Fig 3D)
- Dm4 is the clearest "centring-specific" deficit across speeds — and may affect both flicker and motion centring pathways
- **T4/T5 15deg result is critical:** centring without turning at low/moderate speeds demonstrates that motion processing is NOT required for centring. A T4/T5-independent luminance pathway contributes substantially.
- Two-component model (flicker centring + motion centring) can be tested directly: subtract flicker centring from grating centring to isolate the motion-specific component
- The peak speed for centring differs from turning (centring peaks earlier at 240 for 60deg), consistent with two overlapping components with different temporal frequency optima

---

## 2026-03-13 (cont'd): Offset CoR Turning Rate Analysis + Unified Optic Flow Balance Narrative

**Script updated:** `src/plotting/figures/turning_rate_analysis.m` (now 9 figures, Section 15 added)
**Branch:** `paper-plan`
**Phase:** 2 (New Analysis Development)

### Context: Connecting Turning Rate Findings to the Offset CoR Experiment

The earlier session (below) established that optomotor turning rate (|AV|) is HIGHER at the arena centre (positive slope +0.47), rejecting the simple viewing-distance gain hypothesis. This session connects that finding to the offset centre-of-rotation (CoR) experiment (condition 11, Protocol 27).

### The Unified "Optic Flow Balance Seeking" Mechanism

The original project motivation was that flies seek the position where the optomotor stimulus is most balanced across both eyes. This predicts:

1. **Centred CoR (condition 1):** The balance point is at the arena centre → flies centre
2. **Offset CoR (condition 11):** The balance point shifts with the CoR (0.8 × ARENA_R ≈ 95.2 mm from centre, 23.8 mm from wall) → flies track the CoR, not the arena centre

This was confirmed in the position data (existing `analyse_offset_gratings.m`). The turning rate analysis now provides the mechanistic link:

- **At the balance point (CoR):** optic flow is symmetric → maximal optomotor drive → high |AV| → tight circular walking → "trapping"
- **Away from the balance point:** optic flow is asymmetric → reduced optomotor drive → lower |AV| → looser walking → drift possible
- The position-dependent turning strength creates a natural "attractor" at the CoR

### New Analysis: Figure 9 (Section 15)

**Figure 9 (1×3):** Offset CoR (condition 11) vs Centred CoR (condition 1) vs Flicker (condition 9)

- **Panel A:** |AV| vs wall distance — three conditions overlaid during stimulus, with CoR position marked (23.8 mm from wall). Linear fits for each.
- **Panel B:** Per-fly slope boxcharts (conditions 1, 11, 9)
- **Panel C:** Delta-AV slopes (stimulus minus baseline) boxcharts

**Key predictions:**
- Condition 1 (centred): positive slope (confirmed, +0.47)
- Condition 11 (offset CoR): the positive slope should be REDUCED or REVERSED when referenced to the arena centre, because the optic flow balance point has shifted near the wall
- Condition 9 (flicker): flat slope (no coherent motion → no position-dependent optomotor drive)

**Technical details:**
- Condition 11: Pattern 21 (`0-8shift_60deg_1-875step_32frames`), speed 127, 15s duration
- CoR offset: t = 0.8 arena radii = 95.2 mm from arena centre
- CoR wall distance: ARENA_R - COR_DIST = 119 - 95.2 = 23.8 mm from wall
- Physical setup: C = [528,516] px, W = [606,37] px, PPM = 4.1691 (from `analyse_offset_gratings.m`)

### Figure 9 Results

| Condition | Slope (stim) | p vs 0 | Delta slope | Delta p |
|-----------|-------------|--------|-------------|---------|
| **Cond 1 (centred)** | **+0.47** | 1.2e-8 | **+1.44** | 1.7e-13 |
| **Cond 11 (offset)** | **+0.58** | 1.4e-9 | **+1.51** | 2.5e-12 |
| **Cond 9 (flicker)** | **-0.40** | 1.2e-29 | **-0.01** | 0.91 |

**Critical comparisons:**
- Cond 1 vs 11 slope: **p = 0.38** (NOT different)
- Cond 1 vs 9 slope: p = 1.6e-22 (highly significant)
- Cond 11 vs 9 slope: p = 3.7e-22 (highly significant)
- Delta slope cond 1 vs 11: **p = 0.79** (NOT different)
- Delta slope cond 1 vs 9: p = 2.1e-12

**The prediction was wrong.** Shifting the CoR near the wall did NOT reduce or reverse the positive |AV| slope when referenced to the arena centre. The offset CoR condition has an essentially identical slope (+0.58 vs +0.47, p=0.38). Flicker behaves as expected: delta slope is flat (no stimulus-driven position dependence).

### Revised Interpretation — Two Separable Mechanisms

The Figure 9 result reveals that the positive |AV| slope is determined by the fly's position relative to the **arena walls**, NOT by proximity to the CoR. This means:

1. **Turning rate magnitude** (|AV| vs wall distance) — scales with arena-centre distance regardless of where the CoR is. Driven by how the circular arena geometry shapes retinal image statistics:
   - Near the wall: one eye sees extremely fast motion (exceeding temporal frequency optimum of motion detectors), the other sees slow motion → weaker integrated optomotor drive
   - At the centre: both eyes see moderate-speed motion from equidistant walls → stronger integrated drive
   - This is true regardless of CoR position because it's the arena walls that determine retinal velocities

2. **Centring target** (position data) — tracks the CoR. Confirmed by existing position data: flies move toward the offset CoR, not the arena centre. Driven by optic flow balance/symmetry of the stimulus pattern itself.

Both mechanisms are vision-dependent (T4/T5 and L1/L4 eliminate both), but they operate on different spatial references:
- |AV| magnitude → arena geometry (wall distances)
- Centring target → stimulus geometry (CoR position)

### Manuscript Narrative Update

The paper's mechanistic story is now more nuanced than the initial "unified optic flow balance" framing:

1. **Observation:** Flies centre during optomotor stimulation
2. **Not geometric artifact:** Radial/tangential decomposition confirms active centring
3. **Mechanism — arena geometry shapes optomotor drive:** |AV| scales with wall distance because retinal image statistics depend on the fly's position within the circular arena. This is stimulus-driven (absent for flicker) and vision-dependent (absent for T4/T5, L1/L4), but NOT CoR-dependent.
4. **Centring target tracks the CoR:** Position data shows flies move toward the CoR. The offset CoR experiment dissociates the centring target (CoR-dependent) from the turning rate magnitude (arena-dependent).
5. **Implication:** Centring arises from the combination of (a) strong stimulus-driven turning that is amplified at the centre due to arena geometry, and (b) directional bias toward the CoR from optic flow balance. The "trapping" effect (tight circles where |AV| is highest) contributes to centring but is arena-geometry-dependent, not CoR-dependent.

### Files Modified

- **Updated:** `src/plotting/figures/turning_rate_analysis.m` — added Section 15 (Figure 9), updated header comments, fixed tick labels
- **Updated:** `manuscript_checklist.md` — added offset CoR turning rate task to Phase 2, updated Alternative Explanation row
- **Updated:** `session_notes.md` — added Figure 9 results and revised interpretation

### Next Steps

- Compute |AV| vs distance-from-CoR for condition 11 (requires x_data, y_data) to test whether the slope reappears when referenced to the shifted CoR — this would confirm that centring target and turning magnitude CAN be linked when measured in the right reference frame
- Consider speed-tuning analysis (condition 2 = 8Hz) to test whether the positive slope changes with temporal frequency
- P35/P36 offset conditions (0.75 shift, bidirectional) for replication
- Begin composing manuscript figure panels

---

## 2026-03-13: Fly-Centric Turning Rate Analysis — Optomotor Gain vs Position

**Script created:** `src/plotting/figures/turning_rate_analysis.m` (8 figures)
**Branch:** `paper-plan`
**Phase:** 2 (New Analysis Development)

### Motivation

The radial/tangential analysis (2026-03-12) showed centring is not a geometric byproduct of curved walking, but the mechanism remained unclear. The original hypothesis was "viewing-distance-dependent optomotor gain": flies closer to the wall experience faster retinal slip, driving stronger turning that pushes them toward the centre.

This analysis tests that hypothesis directly by measuring the fly's actual motor output — angular velocity (`av_data`, deg/s) — as a function of distance to the arena wall.

### Key Finding: The Simple Viewing-Distance Hypothesis Is Wrong

**The data shows the OPPOSITE of the prediction.** During the stimulus, control flies turn MORE when farther from the wall (positive slope +0.47, p = 1.2e-8). Pre-stimulus baseline shows the reverse pattern: more turning near the wall (slope -0.63, p = 1.6e-20). The stimulus fundamentally reverses the turning-vs-distance relationship (p = 5.8e-24).

### Results — Main Figures (1–4)

**Figure 1: Motor output timeseries (control, condition 1)**
- Mean |AV| during stimulus: 133.9 ± 39.5 deg/s
- Clear ramp at stimulus onset, direction change visible at STIM_MID

**Figure 2: |AV| vs wall distance (stimulus vs baseline)**
- Stimulus slope: +0.47 deg/s per mm (positive — more turning at centre)
- Baseline slope: -0.63 deg/s per mm (negative — more turning near wall)

**Figure 3: Cross-strain comparison (4×2)**

| Strain | N | Mean Slope | Mean |AV| | Welch p (slope) | Cohen's d |
|--------|---|-----------|---------|----------------|-----------|
| Control | 369 | +0.472 | 133.9 | — | — |
| T4/T5 | 214 | -0.293 | 47.7 | 1.0e-16 | -0.598 |
| Dm4 | 97 | +0.744 | 108.1 | 0.13 | +0.176 |
| Tm5Y | 133 | +0.356 | 137.0 | 0.37 | -0.079 |
| L1/L4 | 144 | -0.360 | 48.3 | 1.0e-11 | -0.582 |

**Key dissociation:** Visually impaired strains (T4/T5, L1/L4) have NEGATIVE slopes matching the baseline pattern — they behave as if unstimulated. Visually intact strains (control, Dm4, Tm5Y) all have positive slopes.

**Figure 4: Per-fly slope summary (box/scatter)**
- Clear separation between impaired (negative) and intact (positive) strains

### Results — Follow-Up Analyses (Figures 5–8)

Four analyses to probe whether the positive slope is an artifact:

**Figure 5: Delta-AV (stimulus minus baseline per distance bin)**
- Delta slope = +1.44, p = 1.7e-13
- The stimulus adds MORE turning at the centre even after subtracting baseline
- **Rules out:** positive slope inherited from pre-existing turning pattern

**Figure 6: Early (first 5s) vs Late (last 5s) stimulus**
- Early slope = +0.87, p = 0.002 (n=116 valid)
- Late slope = -0.53, p = 0.15 (n=58 valid)
- Early vs late: p = 0.003
- **Rules out:** centring artifact. If centring caused the positive slope, it should be ABSENT early and STRONGER late. The data shows the opposite — the positive slope is strongest early, before significant centring has occurred.

**Figure 7: Forward velocity vs wall distance**
- FV slope = +0.004, p = 0.60
- Forward velocity is FLAT across wall distances during the stimulus
- **Rules out:** locomotor confound (flies walking slower near wall → lower AV)

**Figure 8: Starting-position-conditioned analysis (first 3s)**
- Correlation of mean |AV| (first 3s) vs starting wall distance: r = +0.250, p = 1.8e-7 (n=425)
- Flies that start farther from the wall turn more in the first 3 seconds
- **Confirms** the positive slope at the individual-fly level with full statistical power
- (Per-fly slopes were underpowered: only 22/142 near-wall flies had enough bins in 3s)

### Revised Interpretation

**Why the simple hypothesis was wrong:** A fly at the arena centre sees coherent rotational optic flow from all directions — the grating subtends the full visual field symmetrically. A fly near the wall sees extremely fast motion on the near side (likely exceeding the temporal frequency optimum of Reichardt-type motion detectors) and slow motion on the far side. The integrated optomotor drive is weaker near the wall due to this asymmetry.

**What this means for centring:** The centring mechanism does NOT require distance-dependent gain where proximity to the wall drives stronger turning. Instead:
1. The optomotor response drives strong turning globally (134 deg/s mean |AV|)
2. The geometry of curved walking in a bounded circular arena produces net inward drift
3. The stronger optomotor drive at the centre (symmetric optic flow) may help maintain flies there once they arrive
4. Silencing motion-vision neurons (T4/T5, L1/L4) eliminates the stimulus-driven turning, and the slope reverts to the baseline wall-proximity pattern

The partial correlation from radial/tangential analysis (rho = 0.70) still holds — centring scales with starting distance beyond what geometry alone predicts. But the mechanism is about the interplay of turning + arena geometry, not a simple gain gradient.

### Files Created/Modified

- **Created:** `src/plotting/figures/turning_rate_analysis.m` — 8 figures, helper functions `bin_av_by_wall_dist` and `bin_fv_by_wall_dist`
- **Updated:** `manuscript_checklist.md` — added Phase 2 task + Alternative Explanation row

### Manuscript Narrative Implications

The turning rate analysis changes the paper's mechanistic story:

**Old framing:** "Flies closer to the wall experience faster retinal slip → stronger optomotor turning → centripetal drift → centring."

**Revised framing:** "The optomotor stimulus drives strong turning that is actually MORE effective at the arena centre (where optic flow is symmetric). Centring arises from the interaction between stimulus-driven circular walking and the arena's geometry. Motion-vision silencing eliminates the stimulus-driven turning component, revealing a baseline wall-proximity turning pattern underneath."

This is actually a **stronger** result than the original hypothesis because:
1. It explains why centring is so robust (geometry-driven, not dependent on a fragile gain gradient)
2. It naturally explains the strain dissociation (no vision → no turning → no centring)
3. It's consistent with the partial correlation (distance dependence exceeds geometric prediction because flies at different distances experience different optic flow coherence)
4. It makes a testable prediction: reducing grating temporal frequency should shift the optimal distance (moving the peak further from the wall)

### Next Steps

- Update Alternative Explanations in manuscript checklist to reflect revised understanding
- Consider adding a speed-tuning analysis (condition 2 = 8Hz, condition 8 = reverse phi) to test whether the positive slope changes with temporal frequency
- Write up session notes for the interactive HTML explorer updates (turning rate added to both scenarios)
- Begin composing the actual figure panels for the manuscript

---

## 2026-03-12: Radial/Tangential Velocity Decomposition + Heading-to-Center Analysis

**Scripts created:**
- `src/processing/functions/compute_radial_tangential.m` — shared function
- `src/processing/functions/compute_heading_to_center.m` — shared function
- `src/plotting/figures/radial_tangential_analysis.m` — main analysis (4 figures)

**Branch:** `paper-plan`
**Phase:** 2 (New Analysis Development)

### Motivation

The manuscript argues centring is an active behavior. A key alternative explanation: centring is a geometric byproduct of curved walking paths. To address this we need:
1. Radial/tangential velocity decomposition — cleanly separates centring from orbiting
2. Heading-to-center angle — tests whether flies actively orient toward center
3. Geometric prediction test — if centring is geometric, radial velocity should be predictable from tangential velocity + position alone

### Implementation

**`compute_radial_tangential.m`** — Shared function for reuse by null model analysis (future task).
- Input: x_data, y_data, arena center (cx, cy), fps
- Computes radial unit vector at each frame, projects velocity onto radial/tangential
- 5-frame moving mean smoothing (matches `add_dist_dt.m` convention)
- Sign convention: v_rad positive = outward (away from center), so centripetal = -v_rad
- Validation: mean(-v_rad) should correlate >0.99 with dist_dt from `add_dist_dt.m`

**`compute_heading_to_center.m`** — Angle between fly heading and direction to arena center.
- Uses `mod(angle_to_center - heading_wrap + 180, 360) - 180` wrapping (same as `phototaxis_test_code.m`)
- Outputs alignment index `cos(htc_angle)`: +1 = heading toward center, -1 = away

**`radial_tangential_analysis.m`** — Main analysis script with 4 figures:
1. **Velocity decomposition timeseries** (3×1): centripetal velocity, tangential speed, total speed for control
2. **Heading-to-center analysis** (2×2): alignment timeseries, polar histogram, scatter of alignment vs centring, distance-binned alignment
3. **Cross-strain comparison** (3×2): T4/T5, Dm4, Tm5Y vs control — centripetal velocity + alignment timeseries
4. **Geometric prediction test** (1×2): tangential vs centripetal scatter colored by distance; partial correlation controlling for tangential speed

### Key findings

**Validation (control, condition 1, n = 427 flies):**
- Correlation of mean(-v_rad) vs mean(dist_dt) = 0.9692 (below 0.99 target; difference is because dist_dt smooths scalar distance then differentiates, while v_rad differentiates 2D position then smooths — order matters)
- Correlation of sqrt(vr² + vt²) vs vel_data = 0.9292 (vel_data uses 3-point velocity, decomposition uses forward-diff + 5-frame movmean — different temporal smoothing)
- Both are acceptably high to validate the decomposition

**Control results:**
- Mean centripetal velocity during stimulus = 0.654 mm/s (p = 5.7e-47) — highly significant centring
- Mean alignment index during stimulus = **−0.107** (p = 2.7e-15) — **flies head slightly AWAY from center, yet still move toward it**

**Geometric prediction test:**
- Partial correlation (centripetal ~ starting distance | tangential speed): rho = 0.7026, p = 2.35e-64
- Centring scales with distance from center even after controlling for orbiting speed
- Strongly argues against centring being a purely geometric byproduct of curved paths

**Cross-strain comparisons (Cohen's d vs control, Welch t-test p-values):**

| Strain | N | Mean Cp Vel | Cp Vel p (vs 0) | d (Cp Vel) | Welch p (Cp Vel) | Mean Align | d (Align) | Welch p (Align) |
|--------|---|-------------|-----------------|------------|-----------------|------------|-----------|----------------|
| Control | 427 | 0.654 | 5.7e-47 | — | — | −0.107 | — | — |
| T4/T5 | 217 | 0.305 | 2.5e-03 | −0.322 | 1.3e-03 | +0.028 | +0.511 | 1.0e-09 |
| Dm4 | 123 | 0.303 | 8.8e-04 | −0.409 | 4.0e-04 | −0.196 | −0.336 | 8.3e-04 |
| Tm5Y | 139 | 0.864 | 2.0e-13 | +0.222 | 6.5e-02 | +0.001 | +0.409 | 1.9e-05 |

### Interpretation — supports viewing-distance-dependent optomotor gain

The negative control alignment (−0.107) is the headline finding: flies do NOT orient toward the arena center to achieve centring. Instead, centring arises from distance-dependent optomotor turning — when flies are closer to the wall, the grating's retinal slip is faster, driving stronger turning that pushes them away from the wall (toward center). The partial correlation (rho = 0.70) confirms the distance dependence exceeds what tangential orbiting alone predicts.

**T4/T5**: Reduced centring (d = −0.32) but alignment *increases* toward positive (+0.028 vs −0.107, d = +0.51). Without direction-selective motion detectors, the curved-path centring mechanism is disrupted; residual centring may use a different (heading-based?) strategy.

**Dm4**: Reduced centring (d = −0.41) and alignment becomes even more negative (−0.196, d = −0.34). Consistent with "tight coils" phenotype: vigorous turning that is not spatially modulated by distance — the gain is high everywhere rather than scaling with proximity to wall.

**Tm5Y**: Mean centripetal velocity is higher (0.864 vs 0.654) but Welch p = 0.065 — borderline non-significant, high variance. Alignment shifts to neutral (0.001, Welch p = 1.9e-05).

### Bug fix applied

Fixed frame-count dimension mismatch in Figure 3 (`patch` error at line 354). Root cause: `x_frames` was computed from control data but strain data from `combine_timeseries_across_exp_check` can have different frame counts. Fix: compute `nf_common = min(n_frames, nf_s)` per strain and trim both control and strain overlays to common range. Same defensive indexing added to statistics and CSV export sections.

### Next steps

- Consider adding condition 3 (narrow ON bars) for T4/T5 dissociation comparison
- Consider adding flicker (cond 9) and static (cond 10) as negative controls
- Feed results into null model analysis (Phase 2 remaining task)
- Investigate whether viewing distance (ray-traced, from `calculate_viewing_distance.m`) better predicts centripetal velocity than simple distance-from-center

---

## 2026-03-11: QC Threshold Verification (Protocol 27)

**Script:** `src/plotting/figures/verify_qc_thresholds.m`
**Branch:** `paper-plan`
**QC thresholds:** mean FV < 3 mm/s OR min distance > 110 mm (per-fly, per-condition, per-rep)

### Summary

Ran QC verification across all 19 strains and 12 conditions in Protocol 27 (68,208 total rep-level observations).

### Per-Strain Results

8 of 19 strains exceed 20% rejection rate. Rejections are overwhelmingly driven by the FV threshold (flies not walking), not the distance threshold (flies stuck at edge).

| Strain | N Reps | % Rejected | Fail FV Only | Fail Dist Only | Fail Both | Mean FV | Mean Dist |
|--------|--------|-----------|-------------|---------------|----------|---------|----------|
| TmY20 (ss2603) | 3192 | **38.6%** | 1226 | 0 | 6 | 5.9 | 40.1 |
| H1 (ss26283) | 3480 | **37.0%** | 1267 | 2 | 18 | 5.9 | 36.8 |
| T4 (ss2344) | 3072 | **36.3%** | 1086 | 3 | 26 | 6.3 | 39.1 |
| Dm4 (ss00297) | 2952 | **33.4%** | 985 | 0 | 1 | 6.7 | 34.6 |
| L1/L4 | 3960 | **23.8%** | 929 | 0 | 14 | 8.3 | 32.0 |
| Dm4 (ss02360) | 2832 | **23.1%** | 652 | 0 | 1 | 7.9 | 34.5 |
| Pm2ab (ss00326) | 2688 | **21.9%** | 579 | 3 | 8 | 7.6 | 35.2 |
| T5 (ss2571) | 3288 | **20.6%** | 673 | 1 | 2 | 9.3 | 29.9 |
| **Control (JFRC100)** | **10248** | **18.3%** | 1805 | 5 | 65 | 10.3 | 29.8 |
| Dm4 (ss02587) | 1992 | 17.1% | 341 | 0 | 0 | 8.9 | 31.5 |
| LPC1 (ss2575) | 2736 | 16.5% | 431 | 6 | 15 | 11.1 | 29.6 |
| Mi4 (ss00316) | 3600 | 12.5% | 444 | 0 | 7 | 10.5 | 31.1 |
| TmY5a (ss02594) | 2616 | 10.9% | 254 | 9 | 23 | 11.5 | 32.6 |
| TmY3 (ss00395) | 3120 | 10.4% | 288 | 10 | 26 | 12.2 | 31.1 |
| DCH/VCH (ss1209) | 3696 | 9.3% | 334 | 2 | 9 | 12.8 | 26.3 |
| H2 (ss01027) | 3192 | 8.1% | 222 | 0 | 35 | 10.4 | 32.0 |
| Am1 (ss34318) | 3000 | 6.5% | 189 | 1 | 6 | 13.2 | 29.6 |
| Tm5Y (ss03722) | 3336 | 5.8% | 173 | 3 | 19 | 12.6 | 27.0 |
| T4/T5 (ss324) | 5208 | 5.1% | 252 | 11 | 5 | 13.9 | 25.1 |

### Key Observations

1. **FV dominates rejection.** Virtually all rejections come from the forward velocity threshold (flies not walking fast enough). The distance threshold (>110 mm) almost never triggers alone.

2. **High-rejection strains have lower mean FV.** The top 4 rejected strains (TmY20, H1, T4-only, Dm4) all have mean FV around 5.9-6.7 mm/s, compared to 10-14 mm/s for low-rejection strains. This suggests genuinely lower locomotor activity, not a threshold artefact.

3. **T4-only and T5-only are asymmetric.** T4 (ss2344) has 36.3% rejection while T5 (ss2571) has 20.6%, yet the combined T4/T5 line (ss324) has only 5.1%. This is surprising and may reflect differences in the split-GAL4 lines rather than the neuron types.

4. **Control has ~18% rejection** — a non-trivial baseline rate. This means some rejection in mutants is expected even without locomotor deficits.

5. **Condition-specific variation is moderate.** Static gratings (cond 10, 21.3%) and narrow ON bars (cond 3, 20.9%) have the highest rejection, while narrow OFF bars (cond 4, 14.7%) and ON curtains (cond 5, 15.2%) have the lowest. This makes biological sense — static stimuli don't drive walking.

### Per-Condition Results

| Condition | Name | % Rejected |
|-----------|------|-----------|
| 10 | 60deg gratings static | 21.3% |
| 3 | narrow ON bars 4Hz | 20.9% |
| 2 | 60deg gratings 8Hz | 19.8% |
| 6 | OFF curtains 8Hz | 19.8% |
| 8 | reverse phi 4Hz | 19.6% |
| 9 | 60deg flicker 4Hz | 18.9% |
| 7 | reverse phi 2Hz | 18.4% |
| 1 | 60deg gratings 4Hz | 17.6% |
| 12 | 32px ON single bar | 17.2% |
| 11 | 60deg gratings 0.8 offset | 15.9% |
| 5 | ON curtains 8Hz | 15.2% |
| 4 | narrow OFF bars 4Hz | 14.7% |

### Next Steps

- ~~Run `verify_baseline_activity.m`~~ → Done, see below
- Within-fly normalization (delta from baseline) should be implemented for FV and AV in downstream analyses
- Consider sensitivity analysis with relaxed FV threshold (e.g., 1.5 mm/s)

---

## 2026-03-11: Baseline Activity vs QC Rejection (Protocol 27)

**Script:** `src/plotting/figures/verify_baseline_activity.m`
**Branch:** `paper-plan`
**Question:** Do the 8 high-rejection strains have different baseline locomotor activity during pre-stimulus acclimation (acclim_off1, dark period)?

### Summary

Extracted per-fly mean forward velocity and mean distance from centre during the 20s dark acclimation period (acclim_off1) for all 19 strains (2,887 total flies). Compared baseline metrics to stimulus-condition QC rejection rates.

**Key result: Baseline FV strongly predicts rejection rate (Spearman ρ = −0.70, p = 0.001). Baseline distance does not (ρ = −0.004, p = 0.99).**

### Per-Strain Baseline Summary

| Strain | N Flies | Baseline Mean FV | Baseline Median FV | Baseline Mean Dist | % Below FV Thresh | % Rejected (stim) | Group |
|--------|---------|-----------------|-------------------|-------------------|------------------|-------------------|-------|
| TmY20 (ss2603) | 133 | 6.79 | 5.91 | 83.8 | 39.1% | **41.3%** | high_reject |
| H1 (ss26283) | 145 | 7.14 | 6.67 | 95.8 | 27.6% | **40.0%** | high_reject |
| T4 (ss2344) | 128 | 7.86 | 6.43 | 87.0 | 38.3% | **39.2%** | high_reject |
| Dm4 (ss00297) | 123 | **3.71** | **1.52** | 83.2 | **61.8%** | **36.4%** | high_reject |
| L1/L4 | 165 | 4.65 | 3.26 | 78.9 | 46.1% | **26.7%** | high_reject |
| Dm4 (ss02360) | 118 | 4.89 | 3.22 | 83.2 | 48.3% | **26.2%** | high_reject |
| Pm2ab (ss00326) | 112 | 7.41 | 5.37 | 87.2 | 31.3% | **24.3%** | high_reject |
| T5 (ss2571) | 137 | 8.76 | 9.31 | 86.0 | 27.7% | **22.6%** | high_reject |
| Dm4 (ss02587) | 83 | 7.95 | 6.95 | 87.2 | 26.5% | **20.2%** | high_reject |
| **Control** | **427** | **7.20** | **6.33** | **85.8** | **30.9%** | **20.0%** | control |
| LPC1 (ss2575) | 114 | 8.50 | 7.58 | 86.2 | 31.6% | 18.3% | other |
| Mi4 (ss00316) | 150 | 11.16 | 11.66 | 82.5 | 11.3% | 14.4% | other |
| TmY5a (ss02594) | 109 | 9.46 | 9.12 | 92.8 | 22.0% | 12.3% | other |
| TmY3 (ss00395) | 130 | 8.59 | 7.30 | 92.7 | 23.8% | 11.7% | other |
| DCH/VCH (ss1209) | 154 | 8.27 | 8.23 | 84.7 | 22.1% | 10.5% | other |
| H2 (ss01027) | 133 | 7.61 | 7.81 | 86.5 | 22.6% | 9.1% | other |
| Am1 (ss34318) | 125 | 9.37 | 9.22 | 83.7 | 21.6% | 7.2% | other |
| Tm5Y (ss03722) | 139 | 8.24 | 7.88 | 85.4 | 27.3% | 7.0% | other |
| T4/T5 (ss324) | 217 | 9.74 | 9.93 | 85.2 | 19.4% | 5.9% | other |

### Statistical Results

**Omnibus tests:**
- Kruskal-Wallis (FV across strains): p = 4.7 × 10⁻⁴⁰ — highly significant differences in baseline walking speed
- Kruskal-Wallis (distance across strains): p = 1.7 × 10⁻⁸ — significant but weaker

**Correlation with rejection rate:**
- Baseline FV vs rejection: **ρ = −0.70, p = 0.001** (strong negative — slower baseline walkers get rejected more)
- Baseline distance vs rejection: ρ = −0.004, p = 0.99 (no relationship)

**Pairwise vs control (FDR-corrected, q < 0.05):**

| Strain | FV p-adj | FV Cohen's d | Dist p-adj | Dist Cohen's d | Interpretation |
|--------|----------|-------------|-----------|---------------|----------------|
| Dm4 (ss00297) | **<0.0001*** | −0.65 (medium) | 0.16 | −0.11 | Walks much slower at baseline |
| L1/L4 | **<0.0001*** | −0.47 (small) | 0.08 | −0.28 | Reduced baseline walking |
| Dm4 (ss02360) | **<0.0001*** | −0.41 (small) | 0.73 | −0.11 | Reduced baseline walking |
| Mi4 (ss00316) | **<0.0001*** | +0.70 (medium) | 0.16 | −0.14 | Walks *faster* than control |
| T4/T5 (ss324) | **<0.0001*** | +0.43 (small) | 0.73 | −0.02 | Walks faster than control |
| Am1 (ss34318) | **0.002*** | +0.37 (small) | 0.73 | −0.09 | Walks faster than control |
| TmY5a (ss02594) | **0.003*** | +0.39 (small) | **0.019*** | +0.32 | Faster, farther from centre |
| TmY3 (ss00395) | **0.026*** | +0.24 (small) | **0.012*** | +0.31 | Faster, farther from centre |
| DCH/VCH (ss1209) | **0.045*** | +0.19 (negligible) | 0.73 | −0.05 | Marginally faster |
| T5 (ss2571) | **0.026*** | +0.27 (small) | 0.83 | +0.01 | Slightly faster |
| H1 (ss26283) | 0.90 | −0.01 | **<0.0001*** | +0.45 (small) | Normal FV but farther from centre |
| TmY20 (ss2603) | 0.29 | −0.07 | 0.73 | −0.09 | Normal baseline (!) |
| T4 (ss2344) | 0.90 | +0.11 | 0.73 | +0.06 | Normal baseline (!) |
| Pm2ab (ss00326) | 0.90 | +0.04 | 0.83 | +0.06 | Normal baseline |

### Key Observations

1. **Dm4 stands out with genuinely impaired baseline locomotion.** ss00297 has a median baseline FV of just 1.52 mm/s — half the QC threshold. 61.8% of flies are below the 3 mm/s threshold even during baseline. This is consistent with the known Dm4 phenotype (reduced walking, tight coils). The second Dm4 line (ss02360) is similar (median 3.22, 48.3% below threshold).

2. **L1/L4 has reduced baseline activity** (median 3.26 mm/s, 46.1% below threshold). Expected for severely vision-impaired flies — they may be less motivated to explore in the dark.

3. **TmY20 and T4-only have normal baselines but high rejection.** This is the most interesting finding: TmY20 (ss2603, baseline FV 6.79) and T4 (ss2344, baseline FV 7.86) have baselines statistically indistinguishable from control (p-adj = 0.29 and 0.90), yet they have 41% and 39% rejection rates during stimuli. This means their QC failures are **stimulus-specific** — these flies walk normally in the dark but stop or slow down during visual stimulation. This is a genuine behavioural response, not a locomotor deficit.

4. **H1 has normal baseline FV but sits farther from the centre** (95.8 mm mean distance, p < 0.0001 vs control). Its high rejection (40%) is driven by FV during stimuli, not distance, but the edge preference during baseline is notable.

5. **The correlation is driven by a mix of mechanisms.** Some strains (Dm4, L1/L4) have genuinely lower baseline locomotion explaining their rejections. Others (TmY20, T4, H1) have normal baselines but stimulus-specific slowing. The strong overall correlation (ρ = −0.70) is real but masks this heterogeneity.

6. **Control flies also have 30.9% below the FV threshold at baseline** and 20% rejection during stimuli. This sets the "floor" — some level of inactivity is normal.

### Implications for the Manuscript

1. **Within-fly normalization (delta from baseline) is essential.** For metrics like FV and AV, subtracting each fly's baseline value will control for intrinsic locomotor differences between strains. Already implemented for distance (dist_data_delta); extend to velocity metrics.

2. **Strains fall into two categories of high rejection:**
   - *Baseline locomotor deficit* (Dm4, L1/L4): These flies don't walk much regardless of stimulation. QC is legitimately filtering non-responsive flies. Report this transparently.
   - *Stimulus-specific slowing* (TmY20, T4, H1): These flies walk normally at baseline but stop during visual stimulation. This is a genuine behavioural phenotype, not an artefact. Consider reporting both pre- and post-QC results for these strains.

3. **Sensitivity analysis recommended:** Re-run key strain comparisons with a relaxed threshold (e.g., FV < 1.5 mm/s) for TmY20, T4, and H1 to confirm that conclusions hold when more of these "stimulus-slowed" flies are included.

### Next Steps

- ~~Update QC filtering to quiescence-based method~~ → Done, see below
- Implement within-fly normalization (delta from baseline) for FV and AV in the main analysis pipeline
- Run sensitivity analysis comparing mean_fv vs quiescence QC methods
- Move to Phase 2: radial/tangential velocity decomposition and cross-strain heatmap

---

## 2026-03-11: QC Method Update — Quiescence-Based Filtering

**File modified:** `src/processing/functions/check_and_average_across_reps.m`
**Branch:** `paper-plan`

### Motivation

The baseline activity analysis revealed that the original FV-based QC threshold (`mean(fv) < 3 mm/s`) systematically removes flies with genuine behavioural responses:

1. **Dm4 flies** spin in tight coils during stimulation — high angular velocity but low *forward* velocity. The FV threshold removes these flies even though they are actively responding to the stimulus. This is the most biologically interesting Dm4 phenotype (altered turning strategy), and the original QC discards it.

2. **Stimulus-specific slowing strains** (TmY20, T4, H1) have normal baseline FV but slow down during visual stimulation. This slowing is itself a genuine behavioural response that should be analysed, not filtered out.

3. The distinction between "not walking" (QC failure) and "responding differently" (genuine phenotype) depends on measuring the right thing. Forward velocity misses rotational movement; total velocity captures any body displacement.

### Changes

Added **quiescence-based QC** as an optional alternative to the original `mean_fv` method, implemented via `varargin` name-value pairs for full backwards compatibility.

**Original method (`qc_method = 'mean_fv'`, default):**
- Reject if `mean(fv_data) < 3 mm/s` — fly not walking forward
- Reject if `min(dist_data) > 110 mm` — fly stuck near edge

**New method (`qc_method = 'quiescence'`):**
- Reject if `vel_data < 0.5 mm/s` for `>75%` of frames — fly truly stationary/dead
- Reject if `min(dist_data) > 110 mm` — fly stuck near edge (unchanged)

**Key difference:** Uses `vel_data` (total velocity, direction-independent) instead of `fv_data` (forward velocity, in heading direction). A fly spinning in place has `fv ≈ 0` but `vel > 0`. The quiescence method only removes flies that are genuinely not moving at all.

### Implementation Details

- **Backwards compatible**: All existing callers with 6 positional arguments continue to work unchanged (default = `mean_fv`)
- **New optional parameters**: `'qc_method'`, `'rep1_vel'`, `'rep2_vel'`, `'vel_threshold'` (default 0.5), `'quiescence_frac'` (default 0.75)
- **Validation**: Asserts that `rep1_vel` and `rep2_vel` are provided when using quiescence method
- **Distance threshold** (110 mm) is unchanged in both methods
- **Constants** (`FV_THRESHOLD = 3`, `DIST_THRESHOLD = 110`) are now explicitly named at the top of the function

### Usage

```matlab
% Original method (no change needed for existing code):
avg = check_and_average_across_reps(r1, r2, r1_fv, r2_fv, r1_dist, r2_dist);

% New quiescence method:
avg = check_and_average_across_reps(r1, r2, r1_fv, r2_fv, r1_dist, r2_dist, ...
    'qc_method', 'quiescence', 'rep1_vel', r1_vel, 'rep2_vel', r2_vel);
```

### Expected Impact

| Strain | Original Method | Quiescence Method (expected) | Reason |
|--------|----------------|------------------------------|--------|
| Dm4 (ss00297) | 33.4% rejected | **Lower** — spinning flies retained | Tight coils have low FV but non-zero vel |
| TmY20 (ss2603) | 38.6% rejected | **Lower** — slowed flies retained | Stimulus-specific slowing ≠ stationary |
| T4 (ss2344) | 36.3% rejected | **Lower** — slowed flies retained | Same as TmY20 |
| H1 (ss26283) | 37.0% rejected | **Lower** — slowed flies retained | Same as TmY20 |
| Control (JFRC100) | 18.3% rejected | **Lower** — only dead flies removed | Many control flies walk slowly but aren't stationary |
| T4/T5 (ss324) | 5.1% rejected | ~Similar — already low rejection | Few flies are truly stationary |

### Next Steps

- ~~Re-run `verify_qc_thresholds.m` with quiescence method~~ → Done, see below
- ~~Update `combine_timeseries_across_exp_check.m` to pass vel_data for quiescence method~~ → Done
- Implement within-fly normalization (delta from baseline) for FV and AV
- Move to Phase 2: radial/tangential velocity decomposition and cross-strain heatmap

---

## 2026-03-11: Quiescence QC Verification Results

**Script:** `src/plotting/figures/verify_qc_thresholds.m`
**Branch:** `paper-plan`
**QC thresholds:** vel < 0.5 mm/s for >75% of frames OR min distance > 110 mm

### Summary

Ran the updated quiescence-based QC verification across all 19 strains and 12 conditions in Protocol 27 (68,208 total rep-level observations). Compared to the old FV-based method (mean FV < 3 mm/s), the quiescence method substantially reduces rejection rates while still removing truly stationary/dead flies.

### Comparison: Old (FV) vs New (Quiescence) Rejection Rates

| Strain | Old % Rejected | New % Rejected | Change | Mean Frac Stationary |
|--------|---------------|---------------|--------|---------------------|
| TmY20 (ss2603) | 38.6% | **25.9%** | −12.7pp | 0.498 |
| H1 (ss26283) | 37.0% | **23.6%** | −13.4pp | 0.485 |
| T4 (ss2344) | 36.3% | **22.8%** | −13.5pp | 0.485 |
| Dm4 (ss00297) | 33.4% | **16.9%** | −16.5pp | 0.469 |
| L1/L4 | 23.8% | **13.3%** | −10.5pp | 0.399 |
| Dm4 (ss02360) | 23.1% | **11.9%** | −11.2pp | 0.413 |
| Pm2ab (ss00326) | 21.9% | **12.1%** | −9.8pp | 0.373 |
| T5 (ss2571) | 20.6% | **11.4%** | −9.2pp | 0.343 |
| **Control (JFRC100)** | **18.3%** | **9.9%** | **−8.4pp** | **0.251** |
| Dm4 (ss02587) | 17.1% | **9.2%** | −7.9pp | 0.381 |
| LPC1 (ss2575) | 16.5% | **7.2%** | −9.3pp | 0.210 |
| Mi4 (ss00316) | 12.5% | **7.6%** | −4.9pp | 0.293 |
| TmY5a (ss02594) | 10.9% | **5.0%** | −5.9pp | 0.225 |
| TmY3 (ss00395) | 10.4% | **4.7%** | −5.7pp | 0.167 |
| DCH/VCH (ss1209) | 9.3% | **3.5%** | −5.8pp | 0.162 |
| H2 (ss01027) | 8.1% | **3.5%** | −4.6pp | 0.160 |
| Tm5Y (ss03722) | 5.8% | **3.5%** | −2.3pp | 0.187 |
| Am1 (ss34318) | 6.5% | **2.3%** | −4.2pp | 0.127 |
| T4/T5 (ss324) | 5.1% | **3.0%** | −2.1pp | 0.199 |

### Key Observations

1. **Rejection rates dropped substantially across all strains.** Every strain sees a reduction, from −2.1pp (T4/T5) to −16.5pp (Dm4 ss00297). The method successfully retains flies that were walking slowly but not truly stationary.

2. **Only 3 strains remain above 20% rejection** (TmY20, H1, T4), down from 8 with the old method. These three are the stimulus-specific slowing strains — their high rejection reflects genuine behavioural responses to stimulation, not a measurement artefact.

3. **Dm4 (ss00297) dropped from 33.4% to 16.9%.** This is the biggest absolute reduction and confirms that many Dm4 flies were spinning in tight coils (low FV but non-zero total velocity). The quiescence method correctly retains these flies.

4. **Control dropped from 18.3% to 9.9%.** The old method was rejecting almost 1 in 5 control reps. The new method halves this, meaning the old threshold was overly aggressive for healthy flies.

5. **Condition-specific pattern changed.** Static gratings (16.7%) and reverse phi (14.4%) now have the highest rejection. Notably, gratings at 4Hz (cond 1) dropped to just 4.5% — compared to 17.6% with the old method. This confirms the old FV threshold was penalising flies that slowed in response to strong motion stimuli.

### Per-Condition Results (Quiescence Method)

| Condition | Name | % Rejected |
|-----------|------|-----------|
| 10 | 60deg gratings static | 16.7% |
| 8 | reverse phi 4Hz | 14.4% |
| 9 | 60deg flicker 4Hz | 14.3% |
| 7 | reverse phi 2Hz | 13.4% |
| 12 | 32px ON single bar | 13.2% |
| 6 | OFF curtains 8Hz | 12.5% |
| 5 | ON curtains 8Hz | 9.5% |
| 4 | narrow OFF bars 4Hz | 8.5% |
| 2 | 60deg gratings 8Hz | 5.3% |
| 11 | 60deg gratings 0.8 offset | 5.1% |
| 3 | narrow ON bars 4Hz | 4.9% |
| 1 | 60deg gratings 4Hz | 4.5% |

### Implementation in Main Pipeline

Updated `combine_timeseries_across_exp_check.m` to use quiescence-based QC by default:
- Extracts `vel_data` alongside `fv_data` and `dist_data` for both reps
- Passes `'qc_method', 'quiescence', 'rep1_vel', ..., 'rep2_vel', ...` to `check_and_average_across_reps`
- All downstream analysis scripts that call this function will now use quiescence QC automatically
- Default parameters: `vel_threshold = 0.5 mm/s`, `quiescence_frac = 0.75`

**Note:** Other plotting/analysis scripts that call `check_and_average_across_reps` directly (not via `combine_timeseries_across_exp_check`) still use the old `mean_fv` method by default. These are primarily one-off plotting functions and can be updated individually as needed.

---

## 2026-03-11: Fix QC Bug in Statistical Comparison Pipeline

**Files modified (8):**
- `src/processing/functions/combine_timeseries_across_exp_check.m`
- `src/processing/functions/welch_ttest_for_rng.m`
- `src/processing/functions/welch_ttest_for_rng_min.m`
- `src/processing/functions/welch_ttest_for_change.m`
- `src/processing/summary_plot/fv_metric_tests.m`
- `src/processing/summary_plot/dist_metric_tests.m`
- `src/processing/summary_plot/curv_metric_tests.m`
- `src/processing/summary_plot/make_pvalue_array_per_condition.m`

### The Bug

The statistical comparison pipeline (`make_pvalue_array_per_condition.m` → `make_pvalue_heatmap_across_strains.m` → `make_summary_heat_maps_p27.m`) was using the **OLD** `combine_timeseries_across_exp` function, which applies **no QC filtering at all**. Meanwhile, the main data pipeline (timeseries plots, etc.) uses `combine_timeseries_across_exp_check` with quiescence-based QC. This means the heatmap p-values included dead/stationary flies that were excluded from all other analyses.

### Data Format Difference (Root Cause of Complexity)

| Function | Output | Rows per fly |
|----------|--------|-------------|
| `combine_timeseries_across_exp` (OLD) | Interleaved rep1, rep2 | **2** |
| `combine_timeseries_across_exp_check` (NEW) | QC-filtered, rep-averaged | **1** |

All three Welch test functions (`welch_ttest_for_rng`, `_min`, `_for_change`) call `mean_every_two_rows()` internally to average the paired rep rows before running `ttest2`. Simply swapping the data source function would crash or give wrong results because the new data has 1 row per fly — `mean_every_two_rows` would average fly 1 with fly 2 instead of rep 1 with rep 2.

### Fix: `pre_averaged` Flag

Added an optional `pre_averaged` parameter (default `false`) to the entire call chain:

1. **Welch test functions** (3 files): When `pre_averaged = true`, skip `mean_every_two_rows()` — data already has 1 row per fly.
   - `welch_ttest_for_rng(data, ctrl, rng, pre_averaged)` — 4th arg
   - `welch_ttest_for_rng_min(data, ctrl, rng, pre_averaged)` — 4th arg
   - `welch_ttest_for_change(data, ctrl, rng1, rng2, rel_or_norm, pre_averaged)` — 6th arg

2. **Metric test functions** (3 files): Accept and pass through `pre_averaged`.
   - `fv_metric_tests(data, ctrl, pre_averaged)` — 3rd arg
   - `curv_metric_tests(data, ctrl, pre_averaged)` — 3rd arg
   - `dist_metric_tests(data, ctrl, dist_type, pre_averaged)` — 4th arg

3. **`make_pvalue_array_per_condition.m`**: Switched all 6 data extraction calls from `combine_timeseries_across_exp` to `combine_timeseries_across_exp_check`, and passes `true` for `pre_averaged` to all metric test calls.

All changes are backwards compatible — existing callers that don't pass `pre_averaged` get the original `false` default and behaviour is unchanged.

### Configurable Thresholds for Sensitivity Analysis

Also added `varargin` with `inputParser` to `combine_timeseries_across_exp_check.m`:
- `'vel_threshold'` (default 0.5) — velocity below which frames count as stationary
- `'quiescence_frac'` (default 0.75) — fraction of stationary frames to reject a fly

This enables the sensitivity analysis to sweep thresholds without modifying the function.

### Verification Needed

Run `make_summary_heat_maps_p27(DATA)` in MATLAB for condition 1. Compare p-values before and after:
- Most p-values should be similar (QC mainly removes dead flies)
- Dm4, TmY20 p-values may shift (these had high rejection under old method)
- No errors from `mean_every_two_rows` (would crash if `pre_averaged` flag not working)

---

## 2026-03-11: QC Sensitivity Analysis Script Created

**Script:** `src/plotting/figures/qc_sensitivity_analysis.m`
**Branch:** `paper-plan`

### Purpose

Sweep QC thresholds to confirm manuscript conclusions are robust to threshold choice. Required for Methods section — demonstrates that results are not artefacts of a specific QC cutoff.

### Parameter Sweeps

**Primary sweep** (quiescence fraction, vel_threshold = 0.5 fixed):
- `quiescence_frac = [0.50, 0.75, 0.90, 1.00]`
- 1.00 = effectively no activity QC (only distance filter remains)

**Secondary sweep** (velocity threshold, quiescence_frac = 0.75 fixed):
- `vel_threshold = [0.3, 0.5, 1.0]`

### Key Strains and Conditions

| Strain | Key Condition(s) | Why |
|--------|------------------|-----|
| T4/T5 (ss324) | Cond 1 (wide), Cond 3 (narrow) | Centring preserved despite turning loss |
| Dm4 (ss00297) | Cond 1 | Reduced centring, tight coils |
| Tm5Y (ss03722) | Cond 1 | Enhanced centring |
| Am1 (ss34318) | Cond 9 (flicker), Cond 10 (static) | Attraction to static |

### Metrics Computed Per Strain × Condition × Threshold

1. **N retained** — number of flies after QC
2. **Centring magnitude** — mean dist_data_delta at stimulus end (frames 1170:1200, baselined to frame 300)
3. **Turning magnitude** — mean absolute curv_data during stimulus (frames 300:1200), sign-flipped for CCW half
4. **Welch p-value vs control** — for centring and turning metrics
5. **Cohen's d vs control** — effect size

### Conclusions Tested at Each Threshold

| # | Conclusion | Test |
|---|-----------|------|
| 1 | Control flies centre | One-sample t-test on centring metric, p < 0.05 |
| 2 | T4/T5 has reduced turning (cond 1) | Welch p < 0.05 for turning vs control |
| 3 | T4/T5 still centres to narrow gratings (cond 3) | Welch p > 0.05 for centring vs control |
| 4 | Dm4 has reduced centring (cond 1) | Welch p < 0.05 for centring vs control |
| 5 | Tm5Y has enhanced centring (cond 1) | Welch p < 0.05, centring MORE negative than control |

### Output

- **Figure:** 2×2 panel (N vs threshold, centring vs threshold, p-value vs threshold, Cohen's d vs threshold)
- **Console:** Robustness summary — for each conclusion, prints ROBUST/SENSITIVE with threshold details
- **CSV:** `figures/FIGS/qc_sensitivity_results.csv` — full sweep results

### Results (run 2026-03-12)

**Primary sweep:** quiescence_frac = [0.50, 0.75, 0.90, 1.00], vel_threshold = 0.5 fixed.

| # | Conclusion | Verdict | Notes |
|---|-----------|---------|-------|
| 1 | Control flies centre (cond 1) | **ROBUST** | Centring −30 to −35 mm, all thresholds |
| 2 | T4/T5 reduced turning (cond 1) | **Mostly robust** | Fails at QF=0.50 only (p=0.75). Passes at 0.75, 0.90, 1.00 |
| 3 | T4/T5 still centres to narrow gratings (cond 3) | **SENSITIVE** | p-values hover around 0.05: QF=0.50 p=0.024, **QF=0.75 p=0.082**, QF=0.90 p=0.048, QF=1.00 p=0.047. Only passes (p > 0.05) at the manuscript threshold |
| 4 | Dm4 reduced centring (cond 1) | **ROBUST** | p ≈ 0 at all thresholds, Cohen's d = 0.70–0.84 |
| 5 | Tm5Y enhanced centring (cond 1) | **ROBUST** | p ≈ 0 at all thresholds, Cohen's d = 0.51–0.69 |

**Secondary sweep:** vel_threshold = [0.3, 0.5, 1.0], quiescence_frac = 0.75 fixed. All conclusions stable.

**Key concern:** Conclusion 3 (T4/T5 narrow gratings dissociation) has borderline p-values. The manuscript should frame this with effect sizes and direction rather than relying on a binary significance cutoff. Consider supplementing with equivalence testing or Bayesian analysis.

**Other observations:**
- Dm4 N changes substantially with threshold (75–123 at flicker), reflecting genuinely low activity
- Am1 static attraction is robust: p < 0.001, d ≈ 0.35–0.41 at all thresholds
- Am1 flicker aversion (positive centring values relative to control): robust, p < 0.001

---

## 2026-03-12: NaN Bug Fix in Welch Test Functions

**Files modified (3):**
- `src/processing/functions/welch_ttest_for_rng_min.m`
- `src/processing/functions/welch_ttest_for_rng.m`
- `src/processing/functions/welch_ttest_for_change.m`

### The Bug

`combine_timeseries_across_exp_check` NaN-pads shorter cohorts to match the longest cohort's frame count. Just **2 out of 427 Control flies** had NaN in the metric window (frames 1170:1200). Because `min()` and `mean()` propagate NaN, the entire Control strain's distance metrics became NaN. In `plot_pval_heatmap.m`, `NaN > 0` evaluates to `false`, routing all NaN cells to the blue branch. This made **every distance metric cell blue** regardless of the actual data.

### Diagnosis

Created `src/plotting/figures/diagnose_heatmap_signs.m` which:
1. Extracts dist_data and dist_data_delta for key strains
2. Reports NaN counts at critical frames per strain
3. Compares buggy (NaN-propagating) vs NaN-safe metric values
4. Predicts heatmap colors under both approaches

### Fixes

| File | Change |
|------|--------|
| `welch_ttest_for_rng_min.m` | `min(d')` → `min(d, [], 2, 'omitnan')`; `mean()` → `nanmean()`; NaN flies removed before ttest2 |
| `welch_ttest_for_rng.m` | `mean(d2, 2)` → `nanmean(d2, 2)`; NaN flies removed before ttest2 |
| `welch_ttest_for_change.m` | NaN flies filtered before ttest2 in "norm" branch |

### Verification

After fix, heatmaps show correct colors:
- Tm5Y → RED for distance (more centring than control, confirmed by diagnostic: −49 vs −33)
- Dm4 → BLUE for distance (less centring, −11 vs −31)
- T4/T5 → BLUE for distance (less centring, −18 vs −33)

---

## 2026-03-12: Within-Fly Normalization for FV and AV

**Files created (1):**
- `src/processing/functions/resolve_delta_data_type.m`

**Files modified (19):**
- `src/plotting/functions/get_ylb_from_data_type.m`
- `src/plotting/functions/scatter_boxchart_per_cond_per_grp.m`
- `src/plotting/functions/scatter_boxchart_per_cond_one_grp.m`
- `src/plotting/functions/plot_timeseries_acclim_cond.m`
- `src/plotting/functions/plot_allcond_onecohort_tuning.m`
- `src/plotting/functions/plot_timeseries_across_groups_all_cond.m`
- `src/plotting/functions/plot_errorbar_tuning_curve_diff_contrasts.m`
- `src/plotting/functions/plot_allcond_acrossgroups_tuning.m`
- `src/plotting/functions/plot_allcond_acrossgroups_tuning_raw.m`
- `src/plotting/functions/plot_timeseries_diff_contrasts_1strain.m`
- `src/plotting/functions/plot_timeseries_diff_speeds.m`
- `src/plotting/functions/plot_errorbar_tuning_diff_speeds.m`
- `src/plotting/functions/line_per_cond_one_grp.m`
- `src/plotting/functions/plot_xcond_per_strain.m`
- `src/plotting/functions/plot_xcond_per_strain2.m`
- `src/plotting/functions/plot_xstrain_per_cond.m`
- `src/plotting/functions/plot_boxchart_metrics_xstrains.m`
- `src/plotting/functions/plot_boxchart_metrics_xcond.m`
- `src/analysis/single_lady_analysis.m`

**Statistical pipeline also updated (1):**
- `src/processing/summary_plot/make_pvalue_array_per_condition.m`

### Motivation

Within-fly normalization (subtracting baseline at stimulus onset, frame 300) is critical for controlling intrinsic locomotor differences between strains. This was already implemented for `dist_data_delta` but not for other metrics. Strains like Dm4 have lower baseline forward velocity — without normalization, their stimulus responses appear smaller in absolute terms even if the *change* is equivalent.

### Design: `resolve_delta_data_type.m` Helper

Created a centralized helper function that maps delta data_type strings to their base field name + flags:

```matlab
[base_type, delta, d_fv] = resolve_delta_data_type(data_type);
```

| Input | base_type | delta | d_fv |
|-------|-----------|-------|------|
| `"dist_data_delta"` | `"dist_data"` | 1 | 0 |
| `"dist_data_delta_end"` | `"dist_data"` | 2 | 0 |
| `"dist_data_fv"` | `"dist_data"` | 1 | 1 |
| `"fv_data_delta"` | `"fv_data"` | 1 | 0 |
| `"av_data_delta"` | `"av_data"` | 1 | 0 |
| `"vel_data_delta"` | `"vel_data"` | 1 | 0 |
| `"curv_data_delta"` | `"curv_data"` | 1 | 0 |
| Any other type | unchanged | 0 | 0 |

### Changes

**Before:** Each of the 19 plotting/analysis files had a duplicated if/elseif block:
```matlab
if data_type == "dist_data_delta"
    data_type = "dist_data";
    delta = 1;
    d_fv = 0;
elseif data_type == "dist_data_fv"
    data_type = "dist_data";
    delta = 1;
    d_fv = 1;
else
    delta = 0;
    d_fv = 0;
end
```
This ONLY handled `dist_data_delta` — passing `"fv_data_delta"` would fall through to the else branch with `delta = 0`, meaning no baseline subtraction.

**After:** Single function call:
```matlab
[data_type, delta, d_fv] = resolve_delta_data_type(data_type);
```
Now ALL delta types (`fv_data_delta`, `av_data_delta`, `vel_data_delta`, `curv_data_delta`) are handled uniformly.

**Y-axis limits:** Updated for functions that set axis ranges by data_type. Added delta-aware ranges for FV (±8 or ±15 for SD) and AV (±200).

**Y-axis labels:** Updated `get_ylb_from_data_type.m` to show Δ prefix for delta types (e.g., "ΔForward velocity (mm s⁻¹)").

**Statistical pipeline:** `make_pvalue_array_per_condition.m` now uses `resolve_delta_data_type` for the data loading section, removing duplicated inline delta logic.

### Usage

To use the new delta types in any script:
```matlab
% Timeseries plotting (functions with delta parameter):
plot_xcond_per_strain2(protocol, "fv_data_delta", cond_ids, strain_names, params, DATA)

% Box chart comparisons:
plot_boxchart_metrics_xcond(DATA, cond_ids, strain_names, "av_data_delta", rng, 0)
% (delta is resolved from the data_type string automatically)

% Direct use with combine_timeseries_across_exp_check:
[base, delta_flag] = resolve_delta_data_type("fv_data_delta");
cond_data = combine_timeseries_across_exp_check(data, cond_n, base);
if delta_flag == 1
    cond_data = cond_data - cond_data(:, 300);
end
```

### Backwards Compatibility

All changes are fully backwards compatible:
- Existing callers passing `"dist_data_delta"` get identical behavior
- Existing callers passing raw types (`"fv_data"`, `"av_data"`) get `delta = 0`
- Functions with explicit `delta` parameter still accept it; resolved delta overrides only if > 0

### Next Steps

- Test in MATLAB: call key plotting functions with `"fv_data_delta"` and `"av_data_delta"` to verify
- Consider adding `fv_data_delta` metrics to the heatmap (currently only dist_data_delta is in the heatmap)
- Move to Phase 2: radial/tangential velocity decomposition, cross-strain heatmaps

---

## 2026-03-12: Pipeline Status Page — Auto-populate Cross-Reference Ticks

**File modified:** `python/automation/shared/registry.py`
**Branch:** `paper-plan`

### Problem

The HTML pipeline status page (`pipeline_status.html`) has six cross-reference tick columns (Data Acq, Data Proc, Data Net, Res Acq, Res Proc, Res Net) indicating where copies of each experiment's data/results exist. These columns were **never populated by the live pipeline** — they were only filled when `backfill_registry.py` was run manually. As a result, newly acquired experiments (e.g. `2026_03_09`) appeared in the table with no ticks, even though data clearly existed (the experiment couldn't have been detected without it).

### Root Cause

`update_registry()` builds a summary dict with basic metadata (date, protocol, strain, etc.) but never set the `has_data_local_*` / `has_data_network` / `has_*_results` fields. For **new** experiments (not yet in the registry), these fields simply didn't exist. The "preserve" logic only applied to existing entries being updated.

### Solution

The per-experiment `pipeline_status.json` already records which pipeline stages have been completed, and each completed stage implicitly tells us where data exists. Added a `_infer_cross_refs()` helper that reads the `stages` dict and maps completed stages to cross-reference flags:

| Stage completed | Cross-ref field set to `True` |
|:---|:---|
| `acquired` | `has_data_local_acquisition` |
| `copied_to_network` | `has_data_network` |
| `tracked` | `has_data_local_processing` |
| `processed` | `has_local_results_processing` |
| `synced_to_network` | `has_network_results` |

The inferred flags are merged into the summary dict **before** the upsert/preserve logic, so:
- Newly inferred `True` values take effect immediately
- Previously backfilled values for fields we don't infer (e.g. `has_local_results_acquisition`) are preserved via the existing preserve logic
- Only fields with completed stages are set; incomplete/missing stages are omitted, so old values aren't overwritten

### Limitations

These are "data *was* here" flags — they indicate data passed through a location based on pipeline stage completion. If data is later deleted from a machine (e.g. cleanup on the acquisition rig), the tick will persist until the next `backfill_registry.py` run corrects it. This is acceptable since backfill can be run periodically to reconcile.

### How the HTML page is updated (for reference)

The HTML status page is regenerated automatically every time `update_registry()` is called (via `generate_status_page()`). This happens when:
1. `monitor_and_copy.py` copies new data from the acquisition rig to the network
2. `monitor_and_track.py` finishes (or fails) tracking on the processing machine
3. `daily_processing.py` finishes processing or syncing results on the processing machine

So the ticks will now appear as soon as each pipeline stage completes — no manual intervention required.
