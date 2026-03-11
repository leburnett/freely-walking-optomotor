# Session Notes — Freely Walking Optomotor Manuscript

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
