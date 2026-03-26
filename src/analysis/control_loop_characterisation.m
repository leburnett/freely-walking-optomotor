%% CONTROL_LOOP_CHARACTERISATION - Full characterisation of trajectory loops
%  for the control strain (jfrc100_es_shibire_kir).
%
%  Detects self-intersection loops in fly trajectories, excluding frames
%  750-850 (stimulus direction reversal), and analyses how loop metrics
%  relate to distance from the arena centre.
%
%  Active figures (10):
%    Fig 1:    Pooled metric distributions (histograms)
%    Fig 2-4:  Per-fly OLS fit lines overlaid: metric vs distance
%    Fig 5:    Per-fly slope distributions with Wilcoxon signed-rank test
%    Fig 6:    Radial zone box plots with Kruskal-Wallis test
%    Fig 7:    CW vs CCW proportions (by zone and by stimulus half) +
%              multiple regression: distance vs time effects
%    Fig 8-10: LMM per-fly predicted lines: metric vs distance
%              (with population fixed-effect line and 95% CI)
%
%  Commented out (slow to render — uncomment to enable):
%    Pooled scatter: metric vs distance with OLS regression (Section 3)
%    Metric correlation matrix (Section 8)
%
%  Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 27).

%% ================================================================
%  SECTION 1: Data loading, frame masking, loop detection
%  ================================================================

if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

PPM = 4.1691;
ARENA_CENTER = [528, 520] / PPM;
ARENA_R = 120;
FPS = 30;

control_strain = "jfrc100_es_shibire_kir";
key_condition = 1;
sex = 'F';

STIM_ON   = 300;
STIM_OFF  = 1200;
MASK_START = 750;   % stimulus direction reversal window
MASK_END   = 850;

% Load per-fly-rep data with provenance for fly identity tracking
data_types = {'heading_data', 'x_data', 'y_data', 'dist_data', 'vel_data'};
[rep_data, n_flies, provenance] = load_per_rep_data( ...
    DATA, control_strain, sex, key_condition, data_types);

fprintf('Loaded %d fly-rep observations for %s\n', n_flies, control_strain);

% NaN-mask frames 750-850 to exclude stimulus direction reversal.
% find_trajectory_loops already skips NaN frames, so loops cannot span
% the reversal window.
rep_data.x_data(:, MASK_START:MASK_END)       = NaN;
rep_data.y_data(:, MASK_START:MASK_END)       = NaN;
rep_data.heading_data(:, MASK_START:MASK_END) = NaN;

% Extract stimulus period
stim_range = STIM_ON:STIM_OFF;
x_stim       = rep_data.x_data(:, stim_range);
y_stim       = rep_data.y_data(:, stim_range);
heading_stim = rep_data.heading_data(:, stim_range);

% Loop detection options
loop_opts.lookahead_frames = 75;
loop_opts.min_loop_frames  = 10;
loop_opts.fps              = FPS;
loop_opts.arena_center     = ARENA_CENTER;
loop_opts.arena_radius     = ARENA_R;

% Frame boundary for stimulus half classification (in stim_range coords)
mask_start_local = MASK_START - STIM_ON + 1;

% Detect loops for each fly and build flat table
flat_fly_id     = [];
flat_area       = [];
flat_dur        = [];
flat_aspect     = [];
flat_hdg        = [];
flat_dist       = [];
flat_wall       = [];
flat_start_time = [];   % seconds relative to stimulus onset
flat_stim_half  = [];   % 1 = CW half (frames 300-749), 2 = CCW half (851-1200)
fly_loop_structs = cell(n_flies, 1);

for f = 1:n_flies
    loops = find_trajectory_loops( ...
        x_stim(f,:), y_stim(f,:), heading_stim(f,:), loop_opts);
    fly_loop_structs{f} = loops;

    if loops.n_loops > 0
        n_l = loops.n_loops;
        flat_fly_id     = [flat_fly_id;     repmat(f, n_l, 1)];
        flat_area       = [flat_area;       loops.bbox_area(:)];
        flat_dur        = [flat_dur;        loops.duration_s(:)];
        flat_aspect     = [flat_aspect;     loops.bbox_aspect(:)];
        flat_hdg        = [flat_hdg;        loops.cum_heading(:)];
        flat_dist       = [flat_dist;       loops.bbox_dist_center(:)];
        flat_wall       = [flat_wall;       loops.bbox_wall_dist(:)];

        % Time of loop start relative to stimulus onset (in seconds).
        % start_frame is relative to stim_range, so frame 1 = stim onset.
        start_s = (loops.start_frame(:) - 1) / FPS;
        flat_start_time = [flat_start_time; start_s];

        % Stimulus half: CW = before mask, CCW = after mask
        half_label = ones(n_l, 1);  % default CW
        half_label(loops.start_frame(:) > mask_start_local) = 2;  % CCW
        flat_stim_half = [flat_stim_half; half_label];
    end
end

n_total_loops = numel(flat_area);
n_flies_with  = sum(cellfun(@(s) s.n_loops > 0, fly_loop_structs));
loops_per_fly = cellfun(@(s) s.n_loops, fly_loop_structs);

fprintf('\n=== Loop Detection Summary ===\n');
fprintf('  Total loops:       %d\n', n_total_loops);
fprintf('  Flies with loops:  %d / %d\n', n_flies_with, n_flies);
fprintf('  Loops per fly:     %.1f mean, %.0f median\n', ...
    mean(loops_per_fly), median(loops_per_fly));
fprintf('  Bbox area:         %.0f mean, %.0f median mm²\n', ...
    mean(flat_area, 'omitnan'), median(flat_area, 'omitnan'));
fprintf('  Duration:          %.2f mean, %.2f median s\n', ...
    mean(flat_dur, 'omitnan'), median(flat_dur, 'omitnan'));
fprintf('  |Heading change|:  %.0f mean, %.0f median deg\n', ...
    mean(abs(flat_hdg), 'omitnan'), median(abs(flat_hdg), 'omitnan'));
fprintf('  Dist from centre:  %.1f mean, %.1f median mm\n', ...
    mean(flat_dist, 'omitnan'), median(flat_dist, 'omitnan'));

% Verify no loops span the masked frames
mask_local_start = MASK_START - STIM_ON + 1;
mask_local_end   = MASK_END - STIM_ON + 1;
n_in_mask = 0;
for f = 1:n_flies
    s = fly_loop_structs{f};
    if s.n_loops > 0
        for k = 1:s.n_loops
            if s.start_frame(k) >= mask_local_start && s.start_frame(k) <= mask_local_end
                n_in_mask = n_in_mask + 1;
            end
        end
    end
end
fprintf('  Loops starting in masked frames: %d (should be 0)\n', n_in_mask);

%% ================================================================
%  SECTION 2: Pooled metric distributions (Figure 1)
%  ================================================================

figure('Position', [50 50 1400 700], 'Name', 'Fig 1: Metric Distributions');
sgtitle('Control strain — Loop metric distributions', 'FontSize', 18);

hist_data   = {flat_area, flat_dur, flat_aspect, ...
               abs(flat_hdg), flat_dist, flat_wall};
hist_labels = {'Bbox area (mm^2)', 'Duration (s)', 'Aspect ratio', ...
               '|Heading change| (deg)', 'Distance from centre (mm)', ...
               'Wall distance (mm)'};

for hi = 1:6
    subplot(2, 3, hi);
    d = hist_data{hi};
    d = d(~isnan(d));

    histogram(d, 25, 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'w');
    hold on;
    xline(mean(d), '-', 'Color', [0.216 0.494 0.722], 'LineWidth', 1.5);
    xline(median(d), '-', 'Color', [0.894 0.102 0.110], 'LineWidth', 1.5);
    xlabel(hist_labels{hi}, 'FontSize', 12);
    ylabel('Count', 'FontSize', 12);
    title(sprintf('n=%d, mean=%.1f, med=%.1f', numel(d), mean(d), median(d)), ...
        'FontSize', 11);
    legend('', 'Mean', 'Median', 'Location', 'best', 'FontSize', 9);
    set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
end

%% ================================================================
%  SECTION 3: Pooled scatter plots with OLS regression (Figures 2-4)
%  ================================================================
%
%  For each metric we fit a simple OLS line: metric = a + b * distance.
%  We test H0: b = 0 using a t-test (t = b / SE_b, df = n-2).
%  R-squared measures the fraction of variance explained by distance.
%
%  NOTE: This pooled regression treats all loops as independent. Since
%  multiple loops come from the same fly, the p-values are anti-conservative.
%  Section 5 addresses this with per-fly slope analysis.

scatter_metrics = {flat_area, flat_dur, abs(flat_hdg)};
scatter_ylabels = {'Bbox area (mm^2)', 'Duration (s)', '|Heading change| (deg)'};
scatter_titles  = {'Loop area vs distance', 'Loop duration vs distance', ...
                   '|Heading change| vs distance'};

% --- COMMENTED OUT: many-point scatter plots are slow to render ---
% Uncomment this block to generate Figures 2-4.
%{
for mi = 1:3
    figure('Position', [50 + mi*30, 50 + mi*30, 700, 550], ...
        'Name', sprintf('Fig %d: %s', mi+1, scatter_titles{mi}));

    m_vals = scatter_metrics{mi};
    valid = ~isnan(m_vals) & ~isnan(flat_dist);
    d = flat_dist(valid);
    m = m_vals(valid);
    n_valid = numel(d);

    scatter(d, m, 20, [0.216 0.494 0.722], 'filled', ...
        'MarkerFaceAlpha', 0.35, 'MarkerEdgeColor', 'none');
    hold on;

    % OLS fit and t-test on slope
    [p_coeff, S] = polyfit(d, m, 1);
    x_fit = linspace(0, ARENA_R, 100);
    y_fit = polyval(p_coeff, x_fit);
    plot(x_fit, y_fit, '-', 'Color', [0.10 0.25 0.54], 'LineWidth', 2);

    % R-squared
    y_hat = polyval(p_coeff, d);
    SS_res = sum((m - y_hat).^2);
    SS_tot = sum((m - mean(m)).^2);
    R2 = 1 - SS_res / SS_tot;

    % p-value on slope: t = slope / SE_slope, df = n-2
    SE_slope = sqrt(SS_res / (n_valid - 2)) / sqrt(sum((d - mean(d)).^2));
    t_stat = p_coeff(1) / SE_slope;
    p_val = 2 * (1 - tcdf(abs(t_stat), n_valid - 2));

    xlabel('Distance from centre (mm)', 'FontSize', 14);
    ylabel(scatter_ylabels{mi}, 'FontSize', 14);
    title(scatter_titles{mi}, 'FontSize', 16);
    xlim([0 ARENA_R + 5]);

    % Annotation
    text(5, max(ylim) * 0.92, ...
        sprintf('slope = %.3f\nR^2 = %.3f\np = %.2e\nn = %d', ...
        p_coeff(1), R2, p_val, n_valid), ...
        'FontSize', 11, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
    set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
end
%}
fprintf('  (Figures 2-4 commented out — pooled scatter plots slow to render)\n');

%% ================================================================
%  SECTION 4: Per-fly fit lines overlaid on one plot (Figures 2-4)
%  ================================================================
%
%  Instead of individual subplots per fly, each figure overlays all
%  per-fly OLS fit lines (thin, semi-transparent) on a single axes,
%  with the average fit line (mean intercept and slope across flies)
%  drawn bold on top. Flies with fewer than MIN_LOOPS_FOR_FIT loops
%  are excluded from fitting.

MIN_LOOPS_FOR_FIT = 5;   % minimum loops to compute a meaningful per-fly slope

% Pre-compute per-fly slopes and intercepts for all 3 metrics
per_fly_slopes     = NaN(n_flies, 3);  % columns: area, duration, |heading|
per_fly_intercepts = NaN(n_flies, 3);

metric_names_short = {'area', 'duration', '|heading|'};

x_fit = linspace(0, ARENA_R, 100);

for mi = 1:3
    % First pass: compute per-fly fits
    for f = 1:n_flies
        idx = (flat_fly_id == f);
        d_f = flat_dist(idx);
        m_f = scatter_metrics{mi}(idx);
        valid = ~isnan(d_f) & ~isnan(m_f);
        d_f = d_f(valid);
        m_f = m_f(valid);

        if numel(d_f) >= MIN_LOOPS_FOR_FIT
            p_f = polyfit(d_f, m_f, 1);
            per_fly_slopes(f, mi)     = p_f(1);
            per_fly_intercepts(f, mi) = p_f(2);
        end
    end

    % Second pass: plot
    figure('Position', [30 + mi*20, 30 + mi*20, 750, 550], ...
        'Name', sprintf('Fig %d: Per-fly %s vs distance', mi+1, metric_names_short{mi}));
    hold on;

    % Individual per-fly fit lines (thin, semi-transparent)
    has_fit = ~isnan(per_fly_slopes(:, mi));
    n_with_fit = sum(has_fit);
    fly_indices = find(has_fit);

    for fi = 1:n_with_fit
        f = fly_indices(fi);
        y_fit = per_fly_intercepts(f, mi) + per_fly_slopes(f, mi) * x_fit;
        plot(x_fit, y_fit, '-', 'Color', [0.216 0.494 0.722 0.25], 'LineWidth', 1);
    end

    % Average fit line: mean of per-fly intercepts and slopes
    mean_slope = mean(per_fly_slopes(has_fit, mi));
    mean_int   = mean(per_fly_intercepts(has_fit, mi));
    y_avg = mean_int + mean_slope * x_fit;
    plot(x_fit, y_avg, '-', 'Color', [0.10 0.25 0.54], 'LineWidth', 3);

    % SE envelope around the average line (mean +/- SEM of predicted values)
    all_y_fits = per_fly_intercepts(has_fit, mi) + per_fly_slopes(has_fit, mi) * x_fit;
    y_sem = std(all_y_fits, 0, 1) / sqrt(n_with_fit);
    fill([x_fit, fliplr(x_fit)], ...
        [y_avg + y_sem, fliplr(y_avg - y_sem)], ...
        [0.216 0.494 0.722], 'FaceAlpha', 0.15, 'EdgeColor', 'none');

    xlim([0 ARENA_R + 5]);
    xlabel('Distance from centre (mm)', 'FontSize', 14);
    ylabel(scatter_ylabels{mi}, 'FontSize', 14);
    title(sprintf('Per-fly fit lines: %s vs distance (n=%d flies)', ...
        scatter_ylabels{mi}, n_with_fit), 'FontSize', 16);
    text(5, max(ylim) * 0.92, ...
        sprintf('mean slope = %.3f\nn flies = %d (>=%d loops each)', ...
        mean_slope, n_with_fit, MIN_LOOPS_FOR_FIT), ...
        'FontSize', 11, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
    set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
end

%% ================================================================
%  SECTION 5: Per-fly slope distribution and Wilcoxon test (Figure 5)
%  ================================================================
%
%  For each metric we collected one OLS slope per fly (Section 4).
%  Testing whether the population of slopes differs from zero respects
%  the non-independence of loops within a fly. We use the Wilcoxon
%  signed-rank test (non-parametric, robust to non-normality).
%
%  Alternative: a linear mixed-effects model (fitlme) with fly as a
%  random intercept would be the gold standard, but the per-fly slope
%  approach is simpler, interpretable, and does not require specific
%  toolbox functions.

figure('Position', [50 50 1500 450], 'Name', 'Fig 5: Per-fly Slopes');
sgtitle('Per-fly OLS slopes: metric vs distance from centre', 'FontSize', 18);

for mi = 1:3
    subplot(1, 3, mi);
    hold on;

    slopes_mi = per_fly_slopes(:, mi);
    slopes_valid = slopes_mi(~isnan(slopes_mi));
    n_valid = numel(slopes_valid);

    % Histogram of slopes
    histogram(slopes_valid, 15, 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'w');

    % Zero reference
    xline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

    % Mean line
    mean_slope = mean(slopes_valid);
    xline(mean_slope, '-', 'Color', [0.216 0.494 0.722], 'LineWidth', 1.5);

    % Wilcoxon signed-rank test: H0: median slope = 0
    [p_wil, ~, stats_wil] = signrank(slopes_valid);

    % 95% CI on mean (t-based)
    se_slope = std(slopes_valid) / sqrt(n_valid);
    ci_lo = mean_slope - 1.96 * se_slope;
    ci_hi = mean_slope + 1.96 * se_slope;

    xlabel(sprintf('Slope (%s per mm)', metric_names_short{mi}), 'FontSize', 12);
    ylabel('Number of flies', 'FontSize', 12);
    title(sprintf('%s\nmean=%.3f [%.3f, %.3f]\np_{Wilcoxon}=%.3e, n=%d', ...
        scatter_ylabels{mi}, mean_slope, ci_lo, ci_hi, p_wil, n_valid), ...
        'FontSize', 11);
    set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

    fprintf('Per-fly slope (%s): mean=%.4f, 95%%CI=[%.4f, %.4f], Wilcoxon p=%.4e (n=%d flies)\n', ...
        metric_names_short{mi}, mean_slope, ci_lo, ci_hi, p_wil, n_valid);
end

%% ================================================================
%  SECTION 6: Radial zone comparison (Figure 6)
%  ================================================================

zone_edges  = [0 40 80 120];
zone_labels = {'Inner (0-40)', 'Middle (40-80)', 'Outer (80-120)'};
n_zones     = 3;

% Assign each loop to a zone
zone_id = discretize(flat_dist, zone_edges);

% Blue gradient for zones (lightest = centre, darkest = edge)
zone_colors = [0.75 0.85 0.95;
               0.40 0.58 0.78;
               0.10 0.25 0.54];

figure('Position', [50 50 1500 500], 'Name', 'Fig 6: Radial Zones');
sgtitle('Loop metrics by radial zone — Kruskal-Wallis test', 'FontSize', 18);

zone_metrics = {flat_area, flat_dur, abs(flat_hdg)};
zone_ylabels = {'Bbox area (mm^2)', 'Duration (s)', '|Heading change| (deg)'};

for mi = 1:3
    subplot(1, 3, mi);
    hold on;

    m_vals = zone_metrics{mi};
    groups = cell(n_zones, 1);
    for zi = 1:n_zones
        groups{zi} = m_vals(zone_id == zi & ~isnan(m_vals));
    end

    % Manual box plots
    positions = 1:n_zones;
    for zi = 1:n_zones
        g = groups{zi};
        if isempty(g), continue; end
        q = prctile(g, [25 50 75]);
        iqr_val = q(3) - q(1);
        whi = min(max(g), q(3) + 1.5*iqr_val);
        wlo = max(min(g), q(1) - 1.5*iqr_val);

        % Box
        bw = 0.35;
        fill([positions(zi)-bw, positions(zi)+bw, positions(zi)+bw, positions(zi)-bw], ...
            [q(1), q(1), q(3), q(3)], zone_colors(zi,:), ...
            'FaceAlpha', 0.6, 'EdgeColor', zone_colors(zi,:), 'LineWidth', 1.2);
        % Median line
        plot([positions(zi)-bw, positions(zi)+bw], [q(2) q(2)], '-k', 'LineWidth', 2);
        % Whiskers
        plot([positions(zi) positions(zi)], [q(3) whi], '-', 'Color', zone_colors(zi,:), 'LineWidth', 1.2);
        plot([positions(zi) positions(zi)], [wlo q(1)], '-', 'Color', zone_colors(zi,:), 'LineWidth', 1.2);
    end

    % Kruskal-Wallis test
    all_vals = vertcat(groups{:});
    all_grp  = [];
    for zi = 1:n_zones
        all_grp = [all_grp; repmat(zi, numel(groups{zi}), 1)];
    end
    [p_kw, ~, stats_kw] = kruskalwallis(all_vals, all_grp, 'off');

    % Post-hoc pairwise Wilcoxon with Bonferroni correction (3 comparisons)
    posthoc_str = '';
    if p_kw < 0.05
        pairs = [1 2; 1 3; 2 3];
        for pi_idx = 1:3
            z1 = pairs(pi_idx, 1);
            z2 = pairs(pi_idx, 2);
            p_pair = ranksum(groups{z1}, groups{z2});
            p_adj = min(p_pair * 3, 1);  % Bonferroni
            if p_adj < 0.05
                posthoc_str = [posthoc_str, ...
                    sprintf('%s vs %s: p_{adj}=%.3f\n', ...
                    zone_labels{z1}, zone_labels{z2}, p_adj)];
            end
        end
    end

    set(gca, 'XTick', positions, 'XTickLabel', zone_labels);
    ylabel(zone_ylabels{mi}, 'FontSize', 14);
    n_str = sprintf('n=[%d, %d, %d]', numel(groups{1}), numel(groups{2}), numel(groups{3}));
    title(sprintf('%s\nKW p=%.3e, %s', zone_ylabels{mi}, p_kw, n_str), 'FontSize', 11);
    set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

    fprintf('Kruskal-Wallis (%s): p=%.4e, n=%s\n', ...
        metric_names_short{mi}, p_kw, n_str);
    if ~isempty(posthoc_str)
        fprintf('  Post-hoc:\n    %s', strrep(posthoc_str, newline, [newline '    ']));
    end
end

%% ================================================================
%  SECTION 7: Loop direction, temporal analysis, and multiple
%  regression (Figure 7)
%  ================================================================
%
%  The stimulus is CW gratings for the first half (frames 300-749) then
%  CCW gratings for the second half (frames 851-1200). Loop direction
%  could be confounded with time and with distance.
%
%  This figure combines three bar-chart analyses into a 1x3 layout:
%    (a) CW vs CCW proportion by radial zone + chi-squared test
%    (b) CW vs CCW proportion by stimulus half + chi-squared test
%    (c) Multiple regression: standardised betas for distance vs time

% CW loops: negative cum_heading; CCW loops: positive cum_heading
is_cw  = flat_hdg < 0;
is_ccw = flat_hdg > 0;

figure('Position', [50 50 1600 500], 'Name', 'Fig 7: Direction & Temporal');
sgtitle('Loop direction, stimulus half, and distance vs time effects', 'FontSize', 18);

% --- Subplot (a): CW vs CCW proportion by radial zone ---
subplot(1, 3, 1);
hold on;
n_cw_zone  = zeros(n_zones, 1);
n_ccw_zone = zeros(n_zones, 1);
for zi = 1:n_zones
    in_zone = (zone_id == zi);
    n_cw_zone(zi)  = sum(in_zone & is_cw);
    n_ccw_zone(zi) = sum(in_zone & is_ccw);
end
total_zone = n_cw_zone + n_ccw_zone;
prop_cw  = n_cw_zone ./ max(total_zone, 1);
prop_ccw = n_ccw_zone ./ max(total_zone, 1);

b = bar(1:n_zones, [prop_cw, prop_ccw], 'grouped');
b(1).FaceColor = [0.894 0.102 0.110]; b(1).EdgeColor = 'none';
b(2).FaceColor = [0.216 0.494 0.722]; b(2).EdgeColor = 'none';

% Chi-squared test: direction vs zone
obs = [n_cw_zone'; n_ccw_zone'];
exp_chi = sum(obs, 2) * sum(obs, 1) / sum(obs(:));
chi2 = sum((obs(:) - exp_chi(:)).^2 ./ max(exp_chi(:), 1));
df_chi = (size(obs,1)-1) * (size(obs,2)-1);
p_chi_zone = 1 - chi2cdf(chi2, df_chi);

set(gca, 'XTick', 1:n_zones, 'XTickLabel', zone_labels);
ylabel('Proportion', 'FontSize', 12);
title(sprintf('CW vs CCW by zone\n\\chi^2 p=%.3f', p_chi_zone), 'FontSize', 12);
legend('CW', 'CCW', 'Location', 'best');
ylim([0 1]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

fprintf('\nDirection vs zone chi-squared: chi2=%.2f, df=%d, p=%.4f\n', chi2, df_chi, p_chi_zone);

% --- Subplot (b): CW vs CCW proportion by stimulus half ---
subplot(1, 3, 2);
hold on;
n_cw_h  = [sum(flat_stim_half == 1 & is_cw),  sum(flat_stim_half == 2 & is_cw)];
n_ccw_h = [sum(flat_stim_half == 1 & is_ccw), sum(flat_stim_half == 2 & is_ccw)];
total_h = n_cw_h + n_ccw_h;
prop_cw_h  = n_cw_h ./ max(total_h, 1);
prop_ccw_h = n_ccw_h ./ max(total_h, 1);

b2 = bar(1:2, [prop_cw_h; prop_ccw_h]', 'grouped');
b2(1).FaceColor = [0.894 0.102 0.110]; b2(1).EdgeColor = 'none';
b2(2).FaceColor = [0.216 0.494 0.722]; b2(2).EdgeColor = 'none';

% Chi-squared: direction vs stimulus half
obs_h = [n_cw_h; n_ccw_h];
exp_h = sum(obs_h, 2) * sum(obs_h, 1) / sum(obs_h(:));
chi2_h = sum((obs_h(:) - exp_h(:)).^2 ./ max(exp_h(:), 1));
df_h = 1;
p_chi_half = 1 - chi2cdf(chi2_h, df_h);

set(gca, 'XTick', 1:2, 'XTickLabel', {'CW stim', 'CCW stim'});
ylabel('Proportion', 'FontSize', 12);
title(sprintf('Direction by stim half\n\\chi^2=%.2f, p=%.3f', chi2_h, p_chi_half), 'FontSize', 12);
legend('CW loops', 'CCW loops', 'Location', 'best');
ylim([0 1]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

fprintf('Direction vs stimulus half chi-squared: chi2=%.2f, df=%d, p=%.4f\n', ...
    chi2_h, df_h, p_chi_half);

% Compute Spearman correlations for console (distance-time confound)
v_dt = ~isnan(flat_start_time) & ~isnan(flat_dist);
[rho_dt, p_dt] = corr(flat_start_time(v_dt), flat_dist(v_dt), 'Type', 'Spearman');
v_at = ~isnan(flat_start_time) & ~isnan(flat_area);
[rho_at, p_at] = corr(flat_start_time(v_at), flat_area(v_at), 'Type', 'Spearman');
fprintf('  Distance vs time: rho=%.3f, p=%.3e\n', rho_dt, p_dt);
fprintf('  Area vs time:     rho=%.3f, p=%.3e\n', rho_at, p_at);

% --- Subplot (c): Multiple regression (standardised betas) ---
%
%  For each metric, fit:  metric = b0 + b_dist * distance + b_time * time
%
%  We z-score both predictors so the coefficients (standardised betas)
%  are directly comparable in effect size. This tests whether distance
%  has an effect *after controlling for time*, and vice versa.

subplot(1, 3, 3);
hold on;

mreg_metrics = {flat_area, flat_dur, abs(flat_hdg)};
beta_dist = NaN(3, 1);
beta_time = NaN(3, 1);
se_dist   = NaN(3, 1);
se_time   = NaN(3, 1);
p_dist    = NaN(3, 1);
p_time    = NaN(3, 1);

for mi = 1:3
    m_vals = mreg_metrics{mi};
    valid = ~isnan(m_vals) & ~isnan(flat_dist) & ~isnan(flat_start_time);
    y = m_vals(valid);
    x_d = flat_dist(valid);
    x_t = flat_start_time(valid);
    n_v = numel(y);

    % Z-score predictors for standardised betas
    x_d_z = (x_d - mean(x_d)) / std(x_d);
    x_t_z = (x_t - mean(x_t)) / std(x_t);
    y_z   = (y - mean(y)) / std(y);

    % OLS: y_z = b0 + b1*x_d_z + b2*x_t_z
    X = [ones(n_v, 1), x_d_z, x_t_z];
    b = X \ y_z;
    y_hat = X * b;
    resid = y_z - y_hat;
    MSE = sum(resid.^2) / (n_v - 3);
    var_b = MSE * inv(X' * X); %#ok<MINV>
    se_b = sqrt(diag(var_b));

    beta_dist(mi) = b(2);
    beta_time(mi) = b(3);
    se_dist(mi)   = se_b(2);
    se_time(mi)   = se_b(3);
    t_d = b(2) / se_b(2);
    t_t = b(3) / se_b(3);
    p_dist(mi) = 2 * (1 - tcdf(abs(t_d), n_v - 3));
    p_time(mi) = 2 * (1 - tcdf(abs(t_t), n_v - 3));

    fprintf('Multiple regression (%s):\n', metric_names_short{mi});
    fprintf('  beta_distance = %.3f (SE=%.3f, p=%.3e)\n', b(2), se_b(2), p_dist(mi));
    fprintf('  beta_time     = %.3f (SE=%.3f, p=%.3e)\n', b(3), se_b(3), p_time(mi));
end

% Bar chart: grouped bars (distance vs time) for each metric
x_pos = 1:3;
bar_width = 0.35;

hold on;
b1 = bar(x_pos - bar_width/2, beta_dist, bar_width);
b1.FaceColor = [0.216 0.494 0.722]; b1.EdgeColor = 'none';
b2 = bar(x_pos + bar_width/2, beta_time, bar_width);
b2.FaceColor = [0.894 0.102 0.110]; b2.EdgeColor = 'none';

% Error bars
errorbar(x_pos - bar_width/2, beta_dist, se_dist, 'k', 'LineStyle', 'none', ...
    'LineWidth', 1.2, 'CapSize', 6);
errorbar(x_pos + bar_width/2, beta_time, se_time, 'k', 'LineStyle', 'none', ...
    'LineWidth', 1.2, 'CapSize', 6);
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

% Significance stars
for mi = 1:3
    y_max = max(abs([beta_dist(mi) + se_dist(mi), beta_time(mi) + se_time(mi)]));
    if p_dist(mi) < 0.001, star_d = '***';
    elseif p_dist(mi) < 0.01, star_d = '**';
    elseif p_dist(mi) < 0.05, star_d = '*';
    else, star_d = 'ns'; end

    if p_time(mi) < 0.001, star_t = '***';
    elseif p_time(mi) < 0.01, star_t = '**';
    elseif p_time(mi) < 0.05, star_t = '*';
    else, star_t = 'ns'; end

    % Place stars above the bar tip (accounting for sign)
    y_d = beta_dist(mi) + sign(beta_dist(mi) + eps) * se_dist(mi) * 1.5;
    y_t = beta_time(mi) + sign(beta_time(mi) + eps) * se_time(mi) * 1.5;
    text(x_pos(mi) - bar_width/2, y_d, star_d, ...
        'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
    text(x_pos(mi) + bar_width/2, y_t, star_t, ...
        'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold', ...
        'Color', [0.894 0.102 0.110]);
end

set(gca, 'XTick', x_pos, 'XTickLabel', metric_names_short);
ylabel('Standardised \beta', 'FontSize', 12);
title('Distance vs time (multiple regression)', 'FontSize', 12);
legend('Distance', 'Time', 'Location', 'best');
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

%% ================================================================
%  SECTION 8: Metric correlation matrix (Figure 13)
%  ================================================================

% --- COMMENTED OUT: 6x6 scatter matrix is slow with many data points ---
% Uncomment this block to generate Figure 13.
%{
corr_data = [flat_area, flat_dur, abs(flat_hdg), flat_aspect, flat_dist, flat_start_time];
corr_labels = {'Area', 'Duration', '|Heading|', 'Aspect', 'Distance', 'Time'};
n_vars = size(corr_data, 2);

fig13 = figure('Position', [50 50 1100 1000], 'Name', 'Fig 13: Correlation Matrix');
sgtitle('Pairwise Spearman correlations — loop metrics', 'FontSize', 18);

for ri = 1:n_vars
    for ci = 1:n_vars
        ax = subplot(n_vars, n_vars, (ri-1)*n_vars + ci);

        x_c = corr_data(:, ci);
        y_c = corr_data(:, ri);
        v = ~isnan(x_c) & ~isnan(y_c);

        if ri == ci
            % Diagonal: histogram
            histogram(ax, x_c(v), 20, 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'w');
        elseif ri > ci
            % Lower triangle: scatter
            scatter(ax, x_c(v), y_c(v), 5, [0.216 0.494 0.722], 'filled', ...
                'MarkerFaceAlpha', 0.2);
        else
            % Upper triangle: Spearman rho
            [rho, p_rho] = corr(x_c(v), y_c(v), 'Type', 'Spearman');
            text(ax, 0.5, 0.5, sprintf('\\rho=%.2f\np=%.1e', rho, p_rho), ...
                'Units', 'normalized', 'HorizontalAlignment', 'center', ...
                'FontSize', 10, 'FontWeight', 'bold');
            set(ax, 'XTick', [], 'YTick', []);
        end

        % Labels on edges only
        if ri == n_vars
            xlabel(ax, corr_labels{ci}, 'FontSize', 9);
        end
        if ci == 1
            ylabel(ax, corr_labels{ri}, 'FontSize', 9);
        end
        if ri ~= n_vars, set(ax, 'XTickLabel', []); end
        if ci ~= 1, set(ax, 'YTickLabel', []); end
        set(ax, 'FontSize', 8, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 0.8);
    end
end
%}
fprintf('  (Figure 13 commented out — correlation matrix slow to render)\n');

%% ================================================================
%  SECTION 9: Linear Mixed-Effects Models (LMM) — Figures 8-10
%  ================================================================
%
%  WHY A MIXED-EFFECTS MODEL?
%  --------------------------
%  Our data is hierarchical: each fly contributes multiple loops, and
%  loops from the same fly are not independent (a fly that makes big
%  loops will tend to make big loops everywhere). A standard OLS
%  regression ignores this structure and treats each loop as if it came
%  from a different fly, which inflates significance (anti-conservative).
%
%  The per-fly slope approach in Section 5 handles this by collapsing
%  each fly to a single slope, but it throws away information: a fly
%  with 30 loops gets the same weight as a fly with 5.
%
%  A linear mixed-effects model (LMM) is the formal solution. It
%  simultaneously estimates:
%    - FIXED EFFECTS: the population-average relationship (the thing
%      we care about — "does loop area decrease with distance?")
%    - RANDOM EFFECTS: how much each individual fly deviates from the
%      population average (both in baseline level and in slope)
%
%  NOTATION
%  --------
%  We write the model in Wilkinson notation (as used by MATLAB's fitlme):
%
%    bbox_area ~ 1 + distance + (1 + distance | fly_id)
%
%  This means:
%    Fixed part:   bbox_area = beta0 + beta1 * distance
%                  beta0 = population intercept (average area at distance=0)
%                  beta1 = population slope (how area changes per mm of distance)
%                  ** This is the key parameter — its p-value tells us whether
%                     the distance effect is real across the population **
%
%    Random part:  (1 + distance | fly_id)
%                  Each fly gets its OWN intercept and slope that deviate
%                  from the population values. The model estimates the
%                  variance of these deviations (how much flies differ).
%                  "1" = random intercept (some flies make bigger loops overall)
%                  "distance" = random slope (some flies show steeper trends)
%                  The "|" means "grouped by" — so each fly_id gets its own pair.
%
%  HOW IT WORKS (intuition)
%  ------------------------
%  Think of it as fitting a separate regression line for each fly, but
%  with "partial pooling": flies with very few data points get pulled
%  toward the population average (shrinkage), while flies with lots of
%  data are allowed to show their own pattern. This is more efficient
%  than the two-stage approach because it uses all the data optimally.
%
%  The fixed-effect p-value on the slope is the formal test of:
%    H0: the population-average slope is zero
%  This properly accounts for the within-fly correlation.
%
%  REQUIRES: Statistics and Machine Learning Toolbox (for fitlme, table).

fprintf('\n=== Section 9: Linear Mixed-Effects Models ===\n');

% ---------------------------------------------------------------
% STEP 1: BUILD THE DATA TABLE
% ---------------------------------------------------------------
% fitlme requires data in a MATLAB table (like a dataframe in R/Python).
% Each row is one observation (one loop), with columns for the response
% variable, the predictor, and the grouping variable (fly identity).

% Remove rows with any NaN in the variables we need
valid = ~isnan(flat_area) & ~isnan(flat_dist) & ~isnan(flat_dur) & ...
        ~isnan(flat_hdg) & ~isnan(flat_start_time);

lmm_tbl = table( ...
    flat_fly_id(valid),  ...
    flat_dist(valid),    ...
    flat_area(valid),    ...
    flat_dur(valid),     ...
    abs(flat_hdg(valid)), ...
    flat_start_time(valid), ...
    'VariableNames', {'fly_id', 'distance', 'bbox_area', 'duration_s', ...
                      'abs_heading', 'start_time'});

% fly_id must be categorical for fitlme to treat it as a grouping variable
% (not a continuous number). This tells MATLAB "fly 1 and fly 2 are
% different groups, not that fly 2 is twice fly 1".
lmm_tbl.fly_id = categorical(lmm_tbl.fly_id);

fprintf('LMM table: %d loops from %d unique flies\n', ...
    height(lmm_tbl), numel(unique(lmm_tbl.fly_id)));

% ---------------------------------------------------------------
% STEP 2: FIT THE MODELS
% ---------------------------------------------------------------
% We fit three separate LMMs, one for each metric.
%
% Model specification in Wilkinson notation:
%   'metric ~ 1 + distance + (1 + distance | fly_id)'
%
% Breaking this down:
%   metric ~ 1 + distance       = fixed effects (population line)
%   (1 + distance | fly_id)     = random effects (per-fly deviations)
%
% The "1" in the fixed part is the intercept (implicit, but written
% explicitly for clarity). The "1" in the random part means each fly
% gets its own intercept offset. "distance" in the random part means
% each fly also gets its own slope offset.
%
% fitlme estimates the model using Restricted Maximum Likelihood (REML),
% which is the default and recommended method. REML gives unbiased
% estimates of the variance components (how much flies vary in their
% intercepts and slopes).

lmm_metrics  = {'bbox_area', 'duration_s', 'abs_heading'};
lmm_ylabels  = {'Bbox area (mm^2)', 'Duration (s)', '|Heading change| (deg)'};
lmm_formulas = {
    'bbox_area  ~ 1 + distance + (1 + distance | fly_id)'
    'duration_s ~ 1 + distance + (1 + distance | fly_id)'
    'abs_heading ~ 1 + distance + (1 + distance | fly_id)'
};
lmm_models = cell(3, 1);

for mi = 1:3
    fprintf('\n--- Fitting LMM: %s ~ distance + (1 + distance | fly_id) ---\n', ...
        lmm_metrics{mi});

    lmm_models{mi} = fitlme(lmm_tbl, lmm_formulas{mi});

    % ---------------------------------------------------------------
    % STEP 3: INTERPRET THE OUTPUT
    % ---------------------------------------------------------------
    % The model output has two key sections:
    %
    % FIXED EFFECTS (fixedEffects / coefTest):
    %   (Intercept): population-average metric value at distance = 0
    %   distance:    population-average change in metric per mm of distance
    %                *** This is the main result ***
    %                Its p-value answers: "Is there a significant linear
    %                relationship between distance and this metric, after
    %                properly accounting for repeated measures within flies?"
    %
    % RANDOM EFFECTS (covarianceParameters):
    %   Variance of fly intercepts: how much flies differ in baseline metric
    %   Variance of fly slopes: how much flies differ in their distance trend
    %   Covariance: whether flies with high baselines tend to have steeper slopes

    % Display the full model summary
    disp(lmm_models{mi});

    % Extract fixed effects with confidence intervals
    fe = fixedEffects(lmm_models{mi});
    [~, ~, fe_stats] = fixedEffects(lmm_models{mi}, 'DFMethod', 'satterthwaite');

    fprintf('  Fixed effects (Satterthwaite df):\n');
    fprintf('    Intercept: %.3f (SE=%.3f, t=%.2f, p=%.3e)\n', ...
        fe_stats.Estimate(1), fe_stats.SE(1), fe_stats.tStat(1), fe_stats.pValue(1));
    fprintf('    Distance:  %.4f (SE=%.4f, t=%.2f, p=%.3e)\n', ...
        fe_stats.Estimate(2), fe_stats.SE(2), fe_stats.tStat(2), fe_stats.pValue(2));
    fprintf('    95%% CI on slope: [%.4f, %.4f]\n', ...
        fe_stats.Lower(2), fe_stats.Upper(2));

    % ---------------------------------------------------------------
    % STEP 3b: UNDERSTAND THE RANDOM EFFECTS
    % ---------------------------------------------------------------
    % randomEffects() returns the estimated deviation of each fly from
    % the population average. These are called BLUPs (Best Linear
    % Unbiased Predictors). Each fly gets two values:
    %   - intercept offset (how much higher/lower than average)
    %   - slope offset (how much steeper/shallower than average)
    %
    % The per-fly predicted line is:
    %   y_fly = (beta0 + u0_fly) + (beta1 + u1_fly) * distance
    % where u0 and u1 are the random effects for that fly.

    [~, ~, re_stats] = randomEffects(lmm_models{mi});
    re_intercepts = re_stats.Estimate(strcmp(re_stats.Name, '(Intercept)'));
    re_slopes     = re_stats.Estimate(strcmp(re_stats.Name, 'distance'));

    fprintf('    Random effect SDs: intercept=%.3f, slope=%.4f\n', ...
        std(re_intercepts), std(re_slopes));
end

% ---------------------------------------------------------------
% STEP 4: PLOT THE LMM RESULTS — Per-fly predicted lines (Figures 8-10)
% ---------------------------------------------------------------
%
% For each metric, we plot:
%   - Thin semi-transparent lines: each fly's PREDICTED line from the LMM
%     (population fixed effect + that fly's random effect). These are the
%     "shrunk" estimates — flies with few data points are pulled toward
%     the population mean.
%   - Bold line: the population fixed-effect line (the LMM's answer to
%     "what is the average trend?")
%   - Shaded band: 95% CI on the population fixed-effect line
%
% Compare this to Section 4 (per-fly OLS lines):
%   - Section 4 lines are raw OLS fits — each fly's line is estimated
%     independently with no borrowing of information from other flies.
%   - LMM lines are "partially pooled" — flies with few data points are
%     regularised toward the population average. This is visible as
%     tighter clustering of the LMM lines compared to the OLS lines.

x_pred = linspace(0, ARENA_R, 100)';

for mi = 1:3
    mdl = lmm_models{mi};
    fe = fixedEffects(mdl);       % [intercept; slope]
    [~, ~, re_stats] = randomEffects(mdl);

    % Extract per-fly random effects
    re_int = re_stats.Estimate(strcmp(re_stats.Name, '(Intercept)'));
    re_slp = re_stats.Estimate(strcmp(re_stats.Name, 'distance'));
    fly_ids_re = re_stats.Level(strcmp(re_stats.Name, '(Intercept)'));
    n_flies_re = numel(re_int);

    figure('Position', [30 + mi*20, 30 + mi*20, 750, 550], ...
        'Name', sprintf('Fig %d: LMM %s', mi+7, lmm_metrics{mi}));
    hold on;

    % Per-fly predicted lines (fixed + random effects)
    for fi = 1:n_flies_re
        fly_int = fe(1) + re_int(fi);   % population intercept + fly offset
        fly_slp = fe(2) + re_slp(fi);   % population slope + fly offset
        y_fly = fly_int + fly_slp * x_pred;
        plot(x_pred, y_fly, '-', 'Color', [0.216 0.494 0.722 0.15], 'LineWidth', 0.8);
    end

    % Population fixed-effect line (the main result)
    y_pop = fe(1) + fe(2) * x_pred;
    plot(x_pred, y_pop, '-', 'Color', [0.10 0.25 0.54], 'LineWidth', 3);

    % 95% CI on the fixed-effect line
    % We need the variance of the predicted mean at each x value.
    % For a linear model: Var(y_hat) = Var(b0) + x^2*Var(b1) + 2*x*Cov(b0,b1)
    % The covariance matrix of fixed effects gives us this.
    cov_fe = lmm_models{mi}.CoefficientCovariance;
    var_pred = cov_fe(1,1) + x_pred.^2 * cov_fe(2,2) + 2 * x_pred * cov_fe(1,2);
    se_pred = sqrt(var_pred);
    ci_upper = y_pop + 1.96 * se_pred;
    ci_lower = y_pop - 1.96 * se_pred;

    fill([x_pred; flipud(x_pred)], [ci_upper; flipud(ci_lower)], ...
        [0.216 0.494 0.722], 'FaceAlpha', 0.2, 'EdgeColor', 'none');

    xlim([0 ARENA_R + 5]);
    xlabel('Distance from centre (mm)', 'FontSize', 14);
    ylabel(lmm_ylabels{mi}, 'FontSize', 14);

    [~, ~, fe_stats] = fixedEffects(mdl, 'DFMethod', 'satterthwaite');
    title(sprintf('LMM: %s vs distance\nslope = %.4f [%.4f, %.4f], p = %.2e', ...
        lmm_ylabels{mi}, fe_stats.Estimate(2), fe_stats.Lower(2), ...
        fe_stats.Upper(2), fe_stats.pValue(2)), 'FontSize', 14);

    text(5, max(ylim) * 0.92, ...
        sprintf('Fixed: slope=%.4f, p=%.2e\nRandom slope SD=%.4f\nn=%d loops, %d flies', ...
        fe(2), fe_stats.pValue(2), std(re_slp), height(lmm_tbl), n_flies_re), ...
        'FontSize', 11, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
    set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
end

% ---------------------------------------------------------------
% STEP 5: COMPARE PER-FLY SLOPES — OLS vs LMM (console output)
% ---------------------------------------------------------------
%
% This comparison shows the "shrinkage" effect of the LMM. The LMM
% slopes will be more tightly clustered around the population mean
% because flies with few data points are pulled toward the average.
% The OLS slopes from Section 4 show more spread because each fly
% is estimated independently.

fprintf('\n=== Comparison: Per-fly OLS slopes vs LMM random slopes ===\n');
for mi = 1:3
    [~, ~, re_stats] = randomEffects(lmm_models{mi});
    re_slp = re_stats.Estimate(strcmp(re_stats.Name, 'distance'));
    fe = fixedEffects(lmm_models{mi});

    % LMM per-fly slopes = fixed slope + random slope offset
    lmm_fly_slopes = fe(2) + re_slp;

    % OLS per-fly slopes from Section 4
    ols_slopes_valid = per_fly_slopes(~isnan(per_fly_slopes(:, mi)), mi);

    fprintf('\n  %s:\n', metric_names_short{mi});
    fprintf('    OLS per-fly slopes:  mean=%.4f, SD=%.4f, range=[%.4f, %.4f] (n=%d)\n', ...
        mean(ols_slopes_valid), std(ols_slopes_valid), ...
        min(ols_slopes_valid), max(ols_slopes_valid), numel(ols_slopes_valid));
    fprintf('    LMM per-fly slopes:  mean=%.4f, SD=%.4f, range=[%.4f, %.4f] (n=%d)\n', ...
        mean(lmm_fly_slopes), std(lmm_fly_slopes), ...
        min(lmm_fly_slopes), max(lmm_fly_slopes), numel(lmm_fly_slopes));
    fprintf('    LMM fixed slope:     %.4f (this is the population estimate)\n', fe(2));
    fprintf('    Shrinkage ratio:     %.2f (LMM SD / OLS SD — <1 means LMM is tighter)\n', ...
        std(lmm_fly_slopes) / std(ols_slopes_valid));
end

% ---------------------------------------------------------------
% STEP 6 (optional): MODEL WITH TIME AS ADDITIONAL FIXED EFFECT
% ---------------------------------------------------------------
%
% This is the LMM equivalent of the multiple regression in Section 7c,
% but now properly accounting for repeated measures.
%
%   metric ~ distance + start_time + (1 + distance | fly_id)
%
% If the distance fixed effect remains significant after adding time,
% the spatial effect is real and not a temporal artefact.

fprintf('\n=== LMM with distance + time (controlling for temporal confound) ===\n');

lmm_formulas_dt = {
    'bbox_area   ~ 1 + distance + start_time + (1 + distance | fly_id)'
    'duration_s  ~ 1 + distance + start_time + (1 + distance | fly_id)'
    'abs_heading ~ 1 + distance + start_time + (1 + distance | fly_id)'
};

for mi = 1:3
    mdl_dt = fitlme(lmm_tbl, lmm_formulas_dt{mi});
    [~, ~, fe_stats] = fixedEffects(mdl_dt, 'DFMethod', 'satterthwaite');

    fprintf('\n  %s ~ distance + time + (1 + distance | fly_id):\n', lmm_metrics{mi});
    fprintf('    distance:   beta=%.4f (SE=%.4f, p=%.3e)\n', ...
        fe_stats.Estimate(2), fe_stats.SE(2), fe_stats.pValue(2));
    fprintf('    start_time: beta=%.4f (SE=%.4f, p=%.3e)\n', ...
        fe_stats.Estimate(3), fe_stats.SE(3), fe_stats.pValue(3));

    % Compare models using likelihood ratio test (LRT)
    % This tests whether adding time significantly improves the model.
    % compare() requires models fit with ML (not REML) for valid LRT.
    mdl_dist_ml = fitlme(lmm_tbl, lmm_formulas{mi}, 'FitMethod', 'ML');
    mdl_dt_ml   = fitlme(lmm_tbl, lmm_formulas_dt{mi}, 'FitMethod', 'ML');
    comp = compare(mdl_dist_ml, mdl_dt_ml);
    fprintf('    LRT (distance-only vs distance+time): chi2=%.2f, p=%.4f\n', ...
        comp.LRStat(2), comp.pValue(2));
    fprintf('    (p>0.05 means adding time does not significantly improve the model)\n');
end

%% Print final summary

fprintf('\n=============================================\n');
fprintf('  ANALYSIS COMPLETE\n');
fprintf('  %d loops from %d flies (control strain)\n', n_total_loops, n_flies);
fprintf('  Frames 750-850 excluded (stimulus reversal)\n');
fprintf('  10 figures generated\n');
fprintf('=============================================\n');
