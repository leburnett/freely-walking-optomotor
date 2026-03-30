%% CONTROL_LOOP_LMM - Per-fly slope and LMM analysis of loop metrics vs distance
%
%  Focused script: fits per-fly OLS slopes and linear mixed-effects models
%  (LMMs) for 4 loop metrics as a function of distance from the arena centre.
%  Control strain only (jfrc100_es_shibire_kir), frames 750-850 excluded.
%
%  Figures (13):
%    Fig 1-6:  Per-fly OLS fit lines overlaid
%              (area, duration, |heading|, aspect, ang_diff, dist_from_prev)
%    Fig 7:    Per-fly slope distributions with Wilcoxon signed-rank test
%    Fig 8-13: LMM per-fly predicted lines with population line and 95% CI
%
%  Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 27).
%  Requires Statistics and Machine Learning Toolbox (fitlme, signrank, corr).

%% ================================================================
%  SECTION 1: Data loading, frame masking, loop detection
%  ================================================================

if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

ARENA_CENTER = [528, 520] / 4.1691;
ARENA_R  = 120;
FPS      = 30;
STIM_ON  = 300;
STIM_OFF = 1200;
MASK_START = 750;
MASK_END   = 850;

control_strain = "jfrc100_es_shibire_kir";

data_types = {'heading_data', 'x_data', 'y_data', 'dist_data', 'vel_data'};
[rep_data, n_flies] = load_per_rep_data( ...
    DATA, control_strain, 'F', 1, data_types);
fprintf('Loaded %d fly-rep observations for %s\n', n_flies, control_strain);

% NaN-mask the stimulus reversal window
rep_data.x_data(:, MASK_START:MASK_END)       = NaN;
rep_data.y_data(:, MASK_START:MASK_END)       = NaN;
rep_data.heading_data(:, MASK_START:MASK_END) = NaN;

stim_range   = STIM_ON:STIM_OFF;
x_stim       = rep_data.x_data(:, stim_range);
y_stim       = rep_data.y_data(:, stim_range);
heading_stim = rep_data.heading_data(:, stim_range);
vel_stim     = rep_data.vel_data(:, stim_range);

loop_opts.lookahead_frames = 75;
loop_opts.min_loop_frames  = 10;
loop_opts.fps              = FPS;
loop_opts.arena_center     = ARENA_CENTER;
loop_opts.arena_radius     = ARENA_R;

% Detect loops and build flat table
flat_fly_id     = [];
flat_area       = [];
flat_dur        = [];
flat_aspect     = [];
flat_hdg        = [];
flat_dist       = [];
flat_start_time = [];
flat_ang_diff   = [];
flat_dist_prev  = [];

for f = 1:n_flies
    loop_opts.vel = vel_stim(f,:);
    loops = find_trajectory_loops( ...
        x_stim(f,:), y_stim(f,:), heading_stim(f,:), loop_opts);

    if loops.n_loops > 0
        n_l = loops.n_loops;
        flat_fly_id     = [flat_fly_id;     repmat(f, n_l, 1)];
        flat_area       = [flat_area;       loops.bbox_area(:)];
        flat_dur        = [flat_dur;        loops.duration_s(:)];
        flat_aspect     = [flat_aspect;     loops.bbox_aspect(:)];
        flat_hdg        = [flat_hdg;        loops.cum_heading(:)];
        flat_dist       = [flat_dist;       loops.bbox_dist_center(:)];
        flat_start_time = [flat_start_time; (loops.start_frame(:) - 1) / FPS];
        flat_ang_diff   = [flat_ang_diff;   loops.mean_ang_diff(:)];
        flat_dist_prev  = [flat_dist_prev;  loops.dist_from_prev(:)];
    end
end

n_total_loops = numel(flat_area);
fprintf('\n=== Loop Detection Summary ===\n');
fprintf('  Total loops: %d from %d flies\n', n_total_loops, n_flies);
fprintf('  Area:     %.0f mean, %.0f median mm²\n', mean(flat_area,'omitnan'), median(flat_area,'omitnan'));
fprintf('  Duration: %.2f mean, %.2f median s\n', mean(flat_dur,'omitnan'), median(flat_dur,'omitnan'));
fprintf('  |Heading|: %.0f mean, %.0f median deg\n', mean(abs(flat_hdg),'omitnan'), median(abs(flat_hdg),'omitnan'));
fprintf('  Aspect:   %.2f mean, %.2f median\n', mean(flat_aspect,'omitnan'), median(flat_aspect,'omitnan'));
fprintf('  Ang diff: %.1f mean, %.1f median deg\n', mean(flat_ang_diff,'omitnan'), median(flat_ang_diff,'omitnan'));
fprintf('  Dist prev: %.1f mean, %.1f median mm\n', mean(flat_dist_prev,'omitnan'), median(flat_dist_prev,'omitnan'));

%% ================================================================
%  SECTION 2: Per-fly OLS fit lines overlaid (Figures 1-6)
%  ================================================================
%
%  For each metric, we fit a separate OLS line (metric = a + b*distance)
%  to each fly with >= MIN_LOOPS_FOR_FIT loops. All per-fly lines are
%  overlaid on a single axes (thin, semi-transparent) with the average
%  line (mean of per-fly intercepts and slopes) drawn bold on top.

MIN_LOOPS_FOR_FIT = 5;
N_METRICS = 6;

metric_data   = {flat_area, flat_dur, abs(flat_hdg), flat_aspect, flat_ang_diff, flat_dist_prev};
metric_labels = {'Bbox area (mm^2)', 'Duration (s)', '|Heading change| (deg)', ...
                 'Aspect ratio', 'Mean |ang diff| (deg)', 'Dist from prev loop (mm)'};
metric_short  = {'area', 'duration', '|heading|', 'aspect', 'ang_diff', 'dist_prev'};

per_fly_slopes     = NaN(n_flies, N_METRICS);
per_fly_intercepts = NaN(n_flies, N_METRICS);

x_fit = linspace(0, ARENA_R, 100);

for mi = 1:N_METRICS
    % Compute per-fly OLS fits
    for f = 1:n_flies
        idx = (flat_fly_id == f);
        d_f = flat_dist(idx);
        m_f = metric_data{mi}(idx);
        v = ~isnan(d_f) & ~isnan(m_f);
        if sum(v) >= MIN_LOOPS_FOR_FIT
            p_f = polyfit(d_f(v), m_f(v), 1);
            per_fly_slopes(f, mi)     = p_f(1);
            per_fly_intercepts(f, mi) = p_f(2);
        end
    end

    % Plot
    figure('Position', [30+mi*20, 30+mi*20, 750, 550], ...
        'Name', sprintf('Fig %d: OLS %s vs distance', mi, metric_short{mi}));
    hold on;

    has_fit = ~isnan(per_fly_slopes(:, mi));
    n_with_fit = sum(has_fit);
    fly_idx = find(has_fit);

    for fi = 1:n_with_fit
        f = fly_idx(fi);
        y_f = per_fly_intercepts(f,mi) + per_fly_slopes(f,mi) * x_fit;
        plot(x_fit, y_f, '-', 'Color', [0.216 0.494 0.722 0.25], 'LineWidth', 1);
    end

    mean_slp = mean(per_fly_slopes(has_fit, mi));
    mean_int = mean(per_fly_intercepts(has_fit, mi));
    y_avg = mean_int + mean_slp * x_fit;
    plot(x_fit, y_avg, '-', 'Color', [0.10 0.25 0.54], 'LineWidth', 3);

    all_y = per_fly_intercepts(has_fit,mi) + per_fly_slopes(has_fit,mi) * x_fit;
    y_sem = std(all_y, 0, 1) / sqrt(n_with_fit);
    fill([x_fit, fliplr(x_fit)], [y_avg+y_sem, fliplr(y_avg-y_sem)], ...
        [0.216 0.494 0.722], 'FaceAlpha', 0.15, 'EdgeColor', 'none');

    xlim([0 ARENA_R+5]);
    xlabel('Distance from centre (mm)', 'FontSize', 14);
    ylabel(metric_labels{mi}, 'FontSize', 14);
    title(sprintf('Per-fly OLS: %s vs distance (n=%d flies)', ...
        metric_labels{mi}, n_with_fit), 'FontSize', 16);
    text(5, max(ylim)*0.92, ...
        sprintf('mean slope = %.4f\nn flies = %d (>=%d loops each)', ...
        mean_slp, n_with_fit, MIN_LOOPS_FOR_FIT), ...
        'FontSize', 11, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
    set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
end

%% ================================================================
%  SECTION 3: Per-fly slope distributions + Wilcoxon test (Figure 5)
%  ================================================================
%
%  Each fly's OLS slope is one independent observation. We test whether
%  the population of slopes differs from zero using the Wilcoxon
%  signed-rank test (non-parametric, robust to non-normality).

figure('Position', [50 50 1600 700], 'Name', sprintf('Fig %d: Per-fly Slope Distributions', N_METRICS+1));
sgtitle('Per-fly OLS slopes: metric vs distance from centre', 'FontSize', 18);

for mi = 1:N_METRICS
    subplot(2, ceil(N_METRICS/2), mi);
    hold on;

    slopes_v = per_fly_slopes(~isnan(per_fly_slopes(:,mi)), mi);
    n_v = numel(slopes_v);

    histogram(slopes_v, 15, 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'w');
    xline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

    m_slp = mean(slopes_v);
    xline(m_slp, '-', 'Color', [0.216 0.494 0.722], 'LineWidth', 1.5);

    [p_wil, ~] = signrank(slopes_v);

    se = std(slopes_v) / sqrt(n_v);
    ci_lo = m_slp - 1.96*se;
    ci_hi = m_slp + 1.96*se;

    xlabel(sprintf('Slope (%s / mm)', metric_short{mi}), 'FontSize', 12);
    ylabel('Number of flies', 'FontSize', 12);
    title(sprintf('%s\nmean=%.4f [%.4f, %.4f]\np_{Wil}=%.2e, n=%d', ...
        metric_labels{mi}, m_slp, ci_lo, ci_hi, p_wil, n_v), 'FontSize', 10);
    set(gca, 'FontSize', 11, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

    fprintf('Per-fly slope (%s): mean=%.4f, 95%%CI=[%.4f,%.4f], Wilcoxon p=%.3e (n=%d)\n', ...
        metric_short{mi}, m_slp, ci_lo, ci_hi, p_wil, n_v);
end

%% ================================================================
%  SECTION 4: Linear Mixed-Effects Models (Figures 6-9)
%  ================================================================
%
%  For each metric we fit:
%    metric ~ 1 + distance + (1 + distance | fly_id)
%
%  Fixed effects:
%    Intercept — population-average metric value at distance = 0
%    distance  — population-average change per mm (**main result**)
%
%  Random effects:
%    (1 | fly_id)        — per-fly intercept offset
%    (distance | fly_id) — per-fly slope offset
%
%  The per-fly predicted line is:
%    y_fly = (beta0 + u0_fly) + (beta1 + u1_fly) * distance
%  where u0, u1 are the fly's random effects (BLUPs).
%
%  Fitted with REML (default, unbiased variance estimates).

fprintf('\n=== Fitting Linear Mixed-Effects Models ===\n');

% Build table (fitlme requires a MATLAB table with categorical grouping)
valid = ~isnan(flat_area) & ~isnan(flat_dist) & ~isnan(flat_dur) & ...
        ~isnan(flat_hdg) & ~isnan(flat_aspect) & ~isnan(flat_start_time) & ...
        ~isnan(flat_ang_diff) & ~isnan(flat_dist_prev);

lmm_tbl = table( ...
    categorical(flat_fly_id(valid)), ...
    flat_dist(valid), ...
    flat_area(valid), ...
    flat_dur(valid), ...
    abs(flat_hdg(valid)), ...
    flat_aspect(valid), ...
    flat_ang_diff(valid), ...
    flat_dist_prev(valid), ...
    flat_start_time(valid), ...
    'VariableNames', {'fly_id','distance','bbox_area','duration_s', ...
                      'abs_heading','bbox_aspect','mean_ang_diff','dist_from_prev','start_time'});

fprintf('LMM table: %d loops from %d flies\n', height(lmm_tbl), numel(unique(lmm_tbl.fly_id)));

lmm_vars = {'bbox_area', 'duration_s', 'abs_heading', 'bbox_aspect', 'mean_ang_diff', 'dist_from_prev'};
lmm_formulas = {
    'bbox_area      ~ 1 + distance + (1 + distance | fly_id)'
    'duration_s     ~ 1 + distance + (1 + distance | fly_id)'
    'abs_heading    ~ 1 + distance + (1 + distance | fly_id)'
    'bbox_aspect    ~ 1 + distance + (1 + distance | fly_id)'
    'mean_ang_diff  ~ 1 + distance + (1 + distance | fly_id)'
    'dist_from_prev ~ 1 + distance + (1 + distance | fly_id)'
};
lmm_models = cell(N_METRICS, 1);

x_pred = linspace(0, ARENA_R, 100)';

for mi = 1:N_METRICS
    fprintf('\n--- LMM: %s ~ distance + (1 + distance | fly_id) ---\n', lmm_vars{mi});

    lmm_models{mi} = fitlme(lmm_tbl, lmm_formulas{mi});
    disp(lmm_models{mi});

    fe = fixedEffects(lmm_models{mi});
    [~, ~, fe_stats] = fixedEffects(lmm_models{mi}, 'DFMethod', 'satterthwaite');

    fprintf('  Fixed effects (Satterthwaite df):\n');
    fprintf('    Intercept: %.3f (SE=%.3f, t=%.2f, p=%.3e)\n', ...
        fe_stats.Estimate(1), fe_stats.SE(1), fe_stats.tStat(1), fe_stats.pValue(1));
    fprintf('    Distance:  %.4f (SE=%.4f, t=%.2f, p=%.3e)\n', ...
        fe_stats.Estimate(2), fe_stats.SE(2), fe_stats.tStat(2), fe_stats.pValue(2));
    fprintf('    95%% CI on slope: [%.4f, %.4f]\n', fe_stats.Lower(2), fe_stats.Upper(2));

    [~, ~, re_stats] = randomEffects(lmm_models{mi});
    re_int = re_stats.Estimate(strcmp(re_stats.Name, '(Intercept)'));
    re_slp = re_stats.Estimate(strcmp(re_stats.Name, 'distance'));
    n_flies_re = numel(re_int);

    fprintf('    Random effect SDs: intercept=%.3f, slope=%.4f\n', ...
        std(re_int), std(re_slp));

    % --- Plot: per-fly LMM predicted lines + population line + 95% CI ---
    figure('Position', [30+mi*20, 30+mi*20, 750, 550], ...
        'Name', sprintf('Fig %d: LMM %s', mi+5, metric_short{mi}));
    hold on;

    for fi = 1:n_flies_re
        y_fly = (fe(1) + re_int(fi)) + (fe(2) + re_slp(fi)) * x_pred;
        plot(x_pred, y_fly, '-', 'Color', [0.216 0.494 0.722 0.15], 'LineWidth', 0.8);
    end

    y_pop = fe(1) + fe(2) * x_pred;
    plot(x_pred, y_pop, '-', 'Color', [0.10 0.25 0.54], 'LineWidth', 3);

    % 95% CI on the population line from the fixed-effect covariance matrix:
    %   Var(y_hat(x)) = Var(b0) + x^2*Var(b1) + 2*x*Cov(b0,b1)
    cov_fe = lmm_models{mi}.CoefficientCovariance;
    var_pred = cov_fe(1,1) + x_pred.^2 * cov_fe(2,2) + 2 * x_pred * cov_fe(1,2);
    se_pred = sqrt(var_pred);
    fill([x_pred; flipud(x_pred)], ...
        [y_pop + 1.96*se_pred; flipud(y_pop - 1.96*se_pred)], ...
        [0.216 0.494 0.722], 'FaceAlpha', 0.2, 'EdgeColor', 'none');

    xlim([0 ARENA_R+5]);
    xlabel('Distance from centre (mm)', 'FontSize', 14);
    ylabel(metric_labels{mi}, 'FontSize', 14);
    title(sprintf('LMM: %s vs distance\nslope = %.4f [%.4f, %.4f], p = %.2e', ...
        metric_labels{mi}, fe_stats.Estimate(2), fe_stats.Lower(2), ...
        fe_stats.Upper(2), fe_stats.pValue(2)), 'FontSize', 14);
    text(5, max(ylim)*0.92, ...
        sprintf('Fixed slope: %.4f, p=%.2e\nRandom slope SD: %.4f\nn=%d loops, %d flies', ...
        fe(2), fe_stats.pValue(2), std(re_slp), height(lmm_tbl), n_flies_re), ...
        'FontSize', 11, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
    set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
end

%% ================================================================
%  SECTION 5: OLS vs LMM slope comparison
%  ================================================================
%
%  The LMM slopes are "partially pooled" — flies with few loops are
%  pulled toward the population mean (shrinkage). The OLS slopes are
%  estimated independently per fly with no borrowing of information.
%  The shrinkage ratio (LMM SD / OLS SD) quantifies this: values < 1
%  mean the LMM estimates are tighter than the raw OLS estimates.

fprintf('\n=== Comparison: Per-fly OLS slopes vs LMM slopes ===\n');

for mi = 1:N_METRICS
    [~, ~, re_stats] = randomEffects(lmm_models{mi});
    re_slp = re_stats.Estimate(strcmp(re_stats.Name, 'distance'));
    fe = fixedEffects(lmm_models{mi});
    lmm_fly_slopes = fe(2) + re_slp;

    ols_v = per_fly_slopes(~isnan(per_fly_slopes(:,mi)), mi);

    fprintf('\n  %s:\n', metric_short{mi});
    fprintf('    OLS:  mean=%.4f, SD=%.4f, range=[%.4f, %.4f] (n=%d)\n', ...
        mean(ols_v), std(ols_v), min(ols_v), max(ols_v), numel(ols_v));
    fprintf('    LMM:  mean=%.4f, SD=%.4f, range=[%.4f, %.4f] (n=%d)\n', ...
        mean(lmm_fly_slopes), std(lmm_fly_slopes), ...
        min(lmm_fly_slopes), max(lmm_fly_slopes), numel(lmm_fly_slopes));
    fprintf('    LMM fixed slope: %.4f\n', fe(2));
    fprintf('    Shrinkage ratio: %.2f (LMM SD / OLS SD)\n', ...
        std(lmm_fly_slopes) / std(ols_v));
end

%% ================================================================
%  SECTION 6: LMM with time as additional fixed effect
%  ================================================================
%
%  Tests whether the distance effect survives after controlling for time:
%    metric ~ distance + start_time + (1 + distance | fly_id)
%
%  A likelihood ratio test (LRT) compares the distance-only model to the
%  distance+time model. If p > 0.05, adding time does not significantly
%  improve the fit, confirming distance is the real driver.

fprintf('\n=== LMM: controlling for temporal confound (distance + time) ===\n');

lmm_formulas_dt = {
    'bbox_area      ~ 1 + distance + start_time + (1 + distance | fly_id)'
    'duration_s     ~ 1 + distance + start_time + (1 + distance | fly_id)'
    'abs_heading    ~ 1 + distance + start_time + (1 + distance | fly_id)'
    'bbox_aspect    ~ 1 + distance + start_time + (1 + distance | fly_id)'
    'mean_ang_diff  ~ 1 + distance + start_time + (1 + distance | fly_id)'
    'dist_from_prev ~ 1 + distance + start_time + (1 + distance | fly_id)'
};

for mi = 1:N_METRICS
    mdl_dt = fitlme(lmm_tbl, lmm_formulas_dt{mi});
    [~, ~, fe_stats] = fixedEffects(mdl_dt, 'DFMethod', 'satterthwaite');

    fprintf('\n  %s ~ distance + time + (1 + distance | fly_id):\n', lmm_vars{mi});
    fprintf('    distance:   beta=%.4f (SE=%.4f, p=%.3e)\n', ...
        fe_stats.Estimate(2), fe_stats.SE(2), fe_stats.pValue(2));
    fprintf('    start_time: beta=%.4f (SE=%.4f, p=%.3e)\n', ...
        fe_stats.Estimate(3), fe_stats.SE(3), fe_stats.pValue(3));

    % Likelihood ratio test requires ML (not REML) for valid comparison
    mdl_dist_ml = fitlme(lmm_tbl, lmm_formulas{mi}, 'FitMethod', 'ML');
    mdl_dt_ml   = fitlme(lmm_tbl, lmm_formulas_dt{mi}, 'FitMethod', 'ML');
    comp = compare(mdl_dist_ml, mdl_dt_ml);
    fprintf('    LRT (dist-only vs dist+time): chi2=%.2f, p=%.4f\n', ...
        comp.LRStat(2), comp.pValue(2));
    fprintf('    (p>0.05 means time does not improve the model)\n');
end

%% Summary

fprintf('\n=============================================\n');
fprintf('  ANALYSIS COMPLETE\n');
fprintf('  %d loops from %d flies (control strain)\n', n_total_loops, n_flies);
fprintf('  Frames 750-850 excluded (stimulus reversal)\n');
fprintf('  13 figures generated (6 OLS + 1 slopes + 6 LMM)\n');
fprintf('=============================================\n');
