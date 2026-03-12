# Manuscript Checklist: Visual Motion-Driven Centring in Freely Walking Drosophila

> **Plan file:** `.claude/plans/enchanted-exploring-ember.md`
> **Session notes:** `session_notes.md`
> **Branch:** `paper-plan`
> **Last updated:** 2026-03-12 (radial/tangential decomposition + heading-to-center analysis)

---

## Phase 1: Data Validation

| Status | Task | Output Location | Script | Notes |
|--------|------|----------------|--------|-------|
| [x] | Create QC threshold verification script | `figures/FIGS/qc_strain_summary_quiescence.csv`, 6-panel + 10x2 histogram figures | `src/plotting/figures/verify_qc_thresholds.m` | Quiescence method (vel < 0.5 mm/s, >75% frames). Originally FV-based; rewritten to use vel_data |
| [x] | Verify baseline activity explains rejection rates | `figures/FIGS/baseline_activity_summary.csv`, 2x3 figure | `src/plotting/figures/verify_baseline_activity.m` | Spearman rho = -0.70. Dm4/L1L4 = baseline deficit; TmY20/T4/H1 = stimulus-specific slowing |
| [x] | Implement quiescence-based QC in `check_and_average_across_reps` | N/A (function update) | `src/processing/functions/check_and_average_across_reps.m` | Backwards-compatible varargin. Default still `mean_fv`; quiescence available via name-value pairs |
| [x] | Integrate quiescence QC into main data pipeline | N/A (function update) | `src/processing/functions/combine_timeseries_across_exp_check.m` | Now passes `vel_data` and uses `'qc_method', 'quiescence'` by default |
| [x] | Create strain metadata table (Task 1a) | `figures/FIGS/strain_metadata_table.csv`, `.mat` | `src/plotting/figures/generate_strain_metadata_table.m` | 19 screen strains + 8 NorpA strains. Verified 2026-03-11 |
| [x] | Sensitivity analysis: relaxed QC threshold | `figures/FIGS/qc_sensitivity_results.csv`, 2×2 figure | `src/plotting/figures/qc_sensitivity_analysis.m` | 4/5 conclusions ROBUST. Conclusion 3 (T4/T5 narrow gratings) SENSITIVE — p-values borderline ~0.05. Verified 2026-03-12 |
| [x] | Implement within-fly normalization for FV and AV | N/A (pipeline update) | `resolve_delta_data_type.m` + 19 files updated | Created generic helper; updated 19 plotting/analysis/stats files. `fv_data_delta`, `av_data_delta`, `vel_data_delta`, `curv_data_delta` now work everywhere. 2026-03-12 |

---

## Phase 2: New Analysis Development

| Status | Task | Output Location | Script | Notes |
|--------|------|----------------|--------|-------|
| [x] | Radial/tangential velocity decomposition | `figures/FIGS/radial_tangential_per_fly.csv`, 4 figures | `src/plotting/figures/radial_tangential_analysis.m`, `src/processing/functions/compute_radial_tangential.m` | Decomposes velocity into centripetal + tangential. Includes cross-strain comparison and partial correlation geometric test. 2026-03-12 |
| [x] | Heading-to-center analysis | Same CSV and figures | `src/processing/functions/compute_heading_to_center.m` (shared), same analysis script | Alignment index (cos of heading-to-center angle). Polar histograms, distance-binned timeseries. 2026-03-12 |
| [ ] | Cross-strain heatmap: strains x conditions (centring) | TBD | Extend `make_summary_heat_maps_p27.m` | Existing script does 1 condition; need all 12. Both p-value and raw-value versions for dist_data_delta |
| [ ] | Cross-strain heatmap: strains x conditions (turning) | TBD | Same extension | Side-by-side with centring heatmap (Fig 4A-B) |
| [ ] | Centring-vs-turning scatter across strains | TBD | New script | Mean centring magnitude vs mean turning magnitude per strain for condition 1 (Fig 4C) |
| [ ] | Adapt P31 speed analysis for dist_data_delta | TBD | Adapt `analyse_p31_diff_speeds.m` | Speed tuning of centring across strains (Fig 6B) |
| [ ] | Null model / simulation | TBD | New script | Resample turning angles removing radial bias; formal test that centring exceeds geometric expectation |

---

## Phase 3: Figure Generation

### Figure 1 — Experimental System & the Centring Phenomenon

| Status | Panel | Content | Output Location | Script | Notes |
|--------|-------|---------|----------------|--------|-------|
| [ ] | A | Arena schematic (top-down, dimensions) | Manual (Illustrator) | N/A | Cylindrical LED arena, camera view |
| [ ] | B | Example trajectories (3-4 control flies, cond 1), pre/during/post colored | TBD | `plot_traj_xcond.m`, `centring_turning_traj_plots.m` | |
| [ ] | C | Mean +/- SEM time series: dist_data, control, cond 1 | TBD | `plot_xcond_per_strain2.m` via `fig1_plots.m` | Vertical lines at stimulus on/off |
| [ ] | D | Same for dist_data_delta | TBD | Same infrastructure | |
| [ ] | E | Spatial occupancy heatmaps: pre vs during | TBD | `plot_fly_occupancy_heatmaps_all.m` | |
| [ ] | F | Scatter: starting distance vs ending distance (unity line) | TBD | `dv_dist_data.m` | |

### Figure 2 — Centring Dynamics & Relationship to Turning

| Status | Panel | Content | Output Location | Script | Notes |
|--------|-------|---------|----------------|--------|-------|
| [ ] | A | Centring rate time series (d(distance)/dt) | TBD | `plot_centring_rate_timeseries.m` | |
| [ ] | B | Distance traces grouped by starting distance | TBD | `positional_effects_on_behaviour.m` (lines 617-666) | |
| [ ] | C | Centring grouped by forward velocity bins | TBD | `positional_effects_on_behaviour.m` (lines 555-615) | |
| [ ] | D | Scatter: angular velocity vs centripetal displacement | TBD | `dv_dist_data.m` (lines 430-487) | Colored by starting distance |
| [ ] | E | Group (15 flies) vs solo fly dist_data_delta | TBD | Adapt `single_lady_analysis.m` | Solo data from Protocol 25 |

### Figure 3 — Stimulus Specificity

| Status | Panel | Content | Output Location | Script | Notes |
|--------|-------|---------|----------------|--------|-------|
| [ ] | A | Box/bar chart: centring magnitude across all 12 P27 conditions | TBD | `scatter_boxchart_per_cond_one_grp.m` | Control flies only |
| [ ] | B | Time series: gratings (cond 1) vs flicker (cond 9) vs static (cond 10) | TBD | `plot_xcond_per_strain2.m` | Key comparison: coherent motion vs controls |
| [ ] | C | Time series: ON-bars vs OFF-bars, ON-curtains vs OFF-curtains | TBD | Same | |
| [ ] | D | Speed tuning from P31: centring + turning vs speed | TBD | Adapt `analyse_p31_diff_speeds.m` | 60deg and 15deg gratings |
| [ ] | E | Shifted center-of-rotation (cond 11 / P35) | TBD | `analyse_p35_shiftedCoR.m` | Mechanistic smoking gun: does centring target shift with CoR? |

### Figure 4 — Genetic Screen Overview

| Status | Panel | Content | Output Location | Script | Notes |
|--------|-------|---------|----------------|--------|-------|
| [ ] | A | Heatmap: strains x conditions, centring magnitude | TBD | New (extend `make_summary_heat_maps_p27.m`) | Normalized to control. Depends on Phase 2 heatmap work |
| [ ] | B | Heatmap: strains x conditions, angular velocity | TBD | Same | Side-by-side with A |
| [ ] | C | Scatter: mean centring vs mean turning per strain | TBD | New | Off-diagonal points = dissociation. Depends on Phase 2 scatter |

### Figure 5 — Key Genetic Dissections

| Status | Panel | Content | Output Location | Script | Notes |
|--------|-------|---------|----------------|--------|-------|
| [ ] | A | T4/T5 (ss324): turning abolished, centring preserved (narrow gratings) | TBD | `plot_xstrain_per_cond.m` | Headline result. Show cond 1 (wide) and cond 3 (narrow) side-by-side. Consider T4-only vs T5-only |
| [ ] | B | Dm4 (ss00297): tight coils, reduced centring | TBD | Same + curvature | Show av_data, curv_data, dist_data_delta, fv_data. Replicate with ss02360, ss02587 in supp |
| [ ] | C | Tm5Y (ss03722): enhanced centring | TBD | Same | Centres MORE than control. Suggests inhibitory regulation |
| [ ] | D | Am1 (ss34318): attraction to static, no flicker aversion | TBD | Same | Show cond 9 (flicker) and cond 10 (static) specifically |
| [ ] | E | L1/L4: negative control | TBD | Same | Severely impaired — confirms screen sensitivity |

### Figure 6 — Condition-Specific Effects

| Status | Panel | Content | Output Location | Script | Notes |
|--------|-------|---------|----------------|--------|-------|
| [ ] | A | Tuning curves: centring across conditions, key strains vs control | TBD | Adapt `plot_allcond_acrossgroups_tuning.m` | |
| [ ] | B | Speed tuning (P31): centring for key strains vs control | TBD | Adapt `analyse_p31_diff_speeds.m` | |
| [ ] | C | Summary table or circuit diagram | TBD | New | Which strains have deficits in which conditions |

### Supplementary Figures

| Status | Panel | Content | Output Location | Script | Notes |
|--------|-------|---------|----------------|--------|-------|
| [ ] | S1 | Fly counts per strain | TBD | `generate_fly_n_bar_charts.m` | |
| [ ] | S2 | Forward velocity across strains | TBD | TBD | Rules out non-specific locomotor effects |
| [ ] | S3 | Inter-fly distance during centring | TBD | `convex_hull_analysis.m` | |
| [ ] | S4 | Tortuosity analysis | TBD | `python/.../tortuosity_comparison.py` | |
| [ ] | S5 | Viewing distance analysis | TBD | `analyse_viewing_distance.m` | |
| [ ] | S6 | Additional Dm4 lines replication (ss02360, ss02587) | TBD | Same as Fig 5B | |

### Master figure scripts

| Status | Task | Output Location | Script | Notes |
|--------|------|----------------|--------|-------|
| [ ] | Define consistent color scheme and formatting | N/A | Shared config or function | Plotting conventions in CLAUDE.md |
| [ ] | Create `fig1_centring.m` master script | `figures/FIGS/fig1_*.pdf` | `src/plotting/figures/fig1_centring.m` | |
| [ ] | Create `fig2_dynamics.m` master script | `figures/FIGS/fig2_*.pdf` | `src/plotting/figures/fig2_dynamics.m` | |
| [ ] | Create `fig3_stimulus_specificity.m` master script | `figures/FIGS/fig3_*.pdf` | `src/plotting/figures/fig3_stimulus_specificity.m` | |
| [ ] | Create `fig4_screen_overview.m` master script | `figures/FIGS/fig4_*.pdf` | `src/plotting/figures/fig4_screen_overview.m` | |
| [ ] | Create `fig5_genetic_dissections.m` master script | `figures/FIGS/fig5_*.pdf` | `src/plotting/figures/fig5_genetic_dissections.m` | |
| [ ] | Create `fig6_condition_effects.m` master script | `figures/FIGS/fig6_*.pdf` | `src/plotting/figures/fig6_condition_effects.m` | |
| [ ] | Export all as vector graphics (PDF/EPS) | `figures/FIGS/` | Via `exportgraphics` | |

---

## Phase 4: Statistics & Quantification

| Status | Task | Output Location | Script | Notes |
|--------|------|----------------|--------|-------|
| [ ] | One-sample t-test: does centring occur? (control, dist_data_delta vs 0) | TBD | TBD | Within-control, at stimulus end |
| [ ] | Repeated-measures ANOVA: centring across conditions (within strain) | TBD | Extend `stats_within_group.m` | |
| [ ] | Linear mixed-effects model: strain-vs-control comparisons | TBD | New (MATLAB `fitlme`) | `centring ~ strain + (1|cohort)` with Dunnett's correction. Covariates: starting distance, mean FV |
| [ ] | Partial correlation: turning vs centring controlling for position | TBD | TBD | |
| [ ] | Multiple comparison correction across 18 strains | TBD | `fdr_bh.m` or Dunnett's | Dunnett = many-to-one vs control |
| [ ] | Cluster-based permutation test for time series | TBD | New (Maris & Oostenveld 2007) | |
| [ ] | Compute effect sizes (Cohen's d / Hedge's g) for all comparisons | TBD | TBD | Report alongside p-values |
| [ ] | Run null model (geometric expectation of centring from turning) | TBD | New | See Phase 2: null model |
| [ ] | Generate supplementary statistics table | TBD | TBD | All strain comparisons, corrections, effect sizes |

---

## Phase 5: Writing

| Status | Task | Output Location | Script | Notes |
|--------|------|----------------|--------|-------|
| [ ] | Draft figure legends (n, tests, processing details) | Manuscript | N/A | One legend per figure |
| [ ] | Write Results (following figure sequence) | Manuscript | N/A | |
| [ ] | Write Introduction | Manuscript | N/A | Optomotor = classical; centring = novel; screen visual neurons |
| [ ] | Write Methods | Manuscript | N/A | Fly husbandry, arena, tracking, QC (quiescence), statistics |
| [ ] | Write Discussion | Manuscript | N/A | Circuit model, optic flow navigation, behavioral ecology (why centre?) |

---

## Alternative Explanations to Address

Each of these should be addressed in the manuscript with the corresponding data.

| Status | Alternative Explanation | Control / Test | Data Source | Where Addressed |
|--------|------------------------|---------------|-------------|-----------------|
| [ ] | Wall avoidance | Centring absent for flicker/static (same positions, no motion) | P27 conds 9, 10 | Fig 3B |
| [ ] | Social/collision effects | Solo flies still centre | P25 solo data, `single_lady_analysis.m` | Fig 2E |
| [ ] | Phototaxis | Phototaxis condition doesn't produce centring | P27 cond 12 | Fig 3A |
| [ ] | Geometric consequence of turning | Radial/tangential decomposition; null model; centring-vs-turning scatter | New analyses | Fig 2D, Fig 4C, Methods |
| [ ] | Optic flow CoR tracking | Centring shifts with shifted CoR | P27 cond 11, P35/P36 | Fig 3E |
| [ ] | Temperature / shibire effects | Empty-split control has same temp protocol | Control strain | Methods |
| [ ] | Non-specific locomotor deficits | Forward velocity comparable across strains | Supplementary | Supp Fig S2 |

---

## Infrastructure & Pipeline

| Status | Task | Output Location | Script | Notes |
|--------|------|----------------|--------|-------|
| [x] | Set up plotting conventions | `CLAUDE.md` | N/A | box off, ticks out, LineWidth 1.2, FontSize 12/14/16/18, solid lines, light grey references |
| [x] | Fix QC in statistical comparison pipeline | N/A (8 files modified) | `make_pvalue_array_per_condition.m` + 6 Welch/metric test functions | Switched from `combine_timeseries_across_exp` (no QC) to `_check` (quiescence QC). Added `pre_averaged` flag throughout chain. 2026-03-11 |
| [x] | Add configurable thresholds to `combine_timeseries_across_exp_check` | N/A (function update) | `src/processing/functions/combine_timeseries_across_exp_check.m` | varargin for vel_threshold and quiescence_frac. Enables sensitivity analysis sweep. 2026-03-11 |
| [x] | Fix NaN propagation in Welch test functions | N/A (3 files) | `welch_ttest_for_rng.m`, `_min.m`, `_for_change.m` | 2 NaN-padded Control flies made ALL distance heatmap cells blue. Fixed with 'omitnan' and nanmean. 2026-03-12 |
| [ ] | Update remaining direct callers of `check_and_average_across_reps` to use quiescence | N/A | ~12 scripts in `src/plotting/` and `src/analysis/` | Low priority — these are one-off scripts. Main pipeline already updated |
| [ ] | Reprocess all Protocol 27 data with quiescence QC | `results/protocol_27/` | Via `combine_timeseries_across_exp_check.m` | Run in MATLAB to regenerate .mat results files |
| [ ] | Reprocess Protocol 31 data with quiescence QC | `results/protocol_31/` | Same | Speed tuning data |
