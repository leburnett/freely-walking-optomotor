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

- Implement within-fly normalization (delta from baseline) for FV and AV in the main analysis pipeline
- Run sensitivity analysis with relaxed QC threshold for stimulus-specific slowing strains
- Move to Phase 2: radial/tangential velocity decomposition and cross-strain heatmap
