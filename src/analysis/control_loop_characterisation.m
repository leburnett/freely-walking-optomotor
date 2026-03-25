%% CONTROL_LOOP_CHARACTERISATION - Full characterisation of trajectory loops
%  for the control strain (jfrc100_es_shibire_kir).
%
%  Detects self-intersection loops in fly trajectories, excluding frames
%  750-850 (stimulus direction reversal), and analyses how loop metrics
%  relate to distance from the arena centre.
%
%  Generates 13 figures:
%    Fig 1:     Pooled metric distributions (histograms)
%    Fig 2-4:   Pooled scatter: metric vs distance with OLS regression
%    Fig 5-7:   Per-fly scatter subplots: metric vs distance
%    Fig 8:     Per-fly slope distributions with Wilcoxon signed-rank test
%    Fig 9:     Radial zone box plots with Kruskal-Wallis test
%    Fig 10:    Loop direction vs distance (CW/CCW)
%    Fig 11:    Temporal analysis (distance-time confound)
%    Fig 12:    Multiple regression: distance vs time effects
%    Fig 13:    Metric correlation matrix
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

fig1 = figure('Position', [50 50 1400 700], 'Name', 'Fig 1: Metric Distributions');
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

%% ================================================================
%  SECTION 4: Per-fly scatter subplots (Figures 5-7)
%  ================================================================

MIN_LOOPS_FOR_FIT = 5;   % minimum loops to compute a meaningful per-fly slope

% Pre-compute per-fly slopes for all 3 metrics
per_fly_slopes = NaN(n_flies, 3);  % columns: area, duration, |heading|

metric_names_short = {'area', 'duration', '|heading|'};

for mi = 1:3
    n_cols = ceil(sqrt(n_flies));
    n_rows = ceil(n_flies / n_cols);

    figure('Position', [30 + mi*20, 30 + mi*20, n_cols*220, n_rows*200], ...
        'Name', sprintf('Fig %d: Per-fly %s vs distance', mi+4, metric_names_short{mi}));
    sgtitle(sprintf('Per-fly: %s vs distance from centre', scatter_ylabels{mi}), ...
        'FontSize', 16);

    for f = 1:n_flies
        subplot(n_rows, n_cols, f);
        hold on;

        idx = (flat_fly_id == f);
        d_f = flat_dist(idx);
        m_f = scatter_metrics{mi}(idx);
        valid = ~isnan(d_f) & ~isnan(m_f);
        d_f = d_f(valid);
        m_f = m_f(valid);
        n_l = numel(d_f);

        if n_l >= MIN_LOOPS_FOR_FIT
            scatter(d_f, m_f, 15, [0.216 0.494 0.722], 'filled', ...
                'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', 'none');
            p_f = polyfit(d_f, m_f, 1);
            per_fly_slopes(f, mi) = p_f(1);
            x_fit = linspace(0, ARENA_R, 50);
            plot(x_fit, polyval(p_f, x_fit), '-', ...
                'Color', [0.10 0.25 0.54], 'LineWidth', 1.5);
            title(sprintf('Fly %d (n=%d) s=%.2f', f, n_l, p_f(1)), 'FontSize', 8);
        elseif n_l > 0
            scatter(d_f, m_f, 15, [0.7 0.7 0.7], 'filled', ...
                'MarkerFaceAlpha', 0.5, 'MarkerEdgeColor', 'none');
            title(sprintf('Fly %d (n=%d)', f, n_l), 'FontSize', 8, 'Color', [0.5 0.5 0.5]);
        else
            title(sprintf('Fly %d (n=0)', f), 'FontSize', 8, 'Color', [0.5 0.5 0.5]);
        end

        xlim([0 ARENA_R + 5]);
        set(gca, 'FontSize', 8, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 0.8);
    end
end

%% ================================================================
%  SECTION 5: Per-fly slope distribution and Wilcoxon test (Figure 8)
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

fig8 = figure('Position', [50 50 1500 450], 'Name', 'Fig 8: Per-fly Slopes');
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
%  SECTION 6: Radial zone comparison (Figure 9)
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

fig9 = figure('Position', [50 50 1500 500], 'Name', 'Fig 9: Radial Zones');
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
%  SECTION 7: Loop direction and temporal analysis (Figures 10-12)
%  ================================================================
%
%  The stimulus is CW gratings for the first half (frames 300-749) then
%  CCW gratings for the second half (frames 851-1200). Loop direction
%  could be confounded with time and with distance.

% CW loops: negative cum_heading; CCW loops: positive cum_heading
is_cw  = flat_hdg < 0;
is_ccw = flat_hdg > 0;

% --- Figure 10: Direction vs distance ---
fig10 = figure('Position', [50 50 1200 500], 'Name', 'Fig 10: Direction vs Distance');
sgtitle('Loop direction vs distance from centre', 'FontSize', 18);

% (1) Scatter: signed heading vs distance
subplot(1, 2, 1);
hold on;
scatter(flat_dist(is_cw), flat_hdg(is_cw), 15, [0.894 0.102 0.110], 'filled', ...
    'MarkerFaceAlpha', 0.3, 'MarkerEdgeColor', 'none');
scatter(flat_dist(is_ccw), flat_hdg(is_ccw), 15, [0.216 0.494 0.722], 'filled', ...
    'MarkerFaceAlpha', 0.3, 'MarkerEdgeColor', 'none');
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

% Trend lines per direction
for dir_i = 1:2
    if dir_i == 1, idx_d = is_cw; col = [0.894 0.102 0.110];
    else,          idx_d = is_ccw; col = [0.216 0.494 0.722]; end
    d_d = flat_dist(idx_d); m_d = flat_hdg(idx_d);
    v = ~isnan(d_d) & ~isnan(m_d);
    if sum(v) >= 3
        p_d = polyfit(d_d(v), m_d(v), 1);
        x_fit = linspace(0, ARENA_R, 100);
        plot(x_fit, polyval(p_d, x_fit), '-', 'Color', col, 'LineWidth', 2);
    end
end

xlabel('Distance from centre (mm)', 'FontSize', 14);
ylabel('Cumulative heading change (deg)', 'FontSize', 14);
title('Signed heading vs distance', 'FontSize', 14);
legend('CW', 'CCW', 'Location', 'best');
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% (2) Proportion CW vs CCW per radial zone
subplot(1, 2, 2);
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
ylabel('Proportion', 'FontSize', 14);
title(sprintf('CW vs CCW by zone (\\chi^2 p=%.3f)', p_chi_zone), 'FontSize', 14);
legend('CW', 'CCW', 'Location', 'best');
ylim([0 1]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

fprintf('\nDirection vs zone chi-squared: chi2=%.2f, df=%d, p=%.4f\n', chi2, df_chi, p_chi_zone);

% --- Figure 11: Temporal analysis ---
fig11 = figure('Position', [50 50 1100 900], 'Name', 'Fig 11: Temporal Analysis');
sgtitle('Temporal analysis — distance, time, and stimulus half', 'FontSize', 18);

% (1) Distance vs time — are they correlated?
subplot(2, 2, 1);
hold on;
scatter(flat_start_time, flat_dist, 15, [0.216 0.494 0.722], 'filled', ...
    'MarkerFaceAlpha', 0.3, 'MarkerEdgeColor', 'none');
v = ~isnan(flat_start_time) & ~isnan(flat_dist);
[rho_dt, p_dt] = corr(flat_start_time(v), flat_dist(v), 'Type', 'Spearman');
if sum(v) >= 3
    p_fit = polyfit(flat_start_time(v), flat_dist(v), 1);
    x_fit = linspace(min(flat_start_time), max(flat_start_time), 100);
    plot(x_fit, polyval(p_fit, x_fit), '-', 'Color', [0.10 0.25 0.54], 'LineWidth', 2);
end
xlabel('Time since stim onset (s)', 'FontSize', 12);
ylabel('Distance from centre (mm)', 'FontSize', 12);
title(sprintf('Distance vs time\n\\rho=%.3f, p=%.3e', rho_dt, p_dt), 'FontSize', 12);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% (2) Area vs time
subplot(2, 2, 2);
hold on;
scatter(flat_start_time, flat_area, 15, [0.216 0.494 0.722], 'filled', ...
    'MarkerFaceAlpha', 0.3, 'MarkerEdgeColor', 'none');
v = ~isnan(flat_start_time) & ~isnan(flat_area);
if sum(v) >= 3
    p_fit = polyfit(flat_start_time(v), flat_area(v), 1);
    x_fit = linspace(min(flat_start_time), max(flat_start_time), 100);
    plot(x_fit, polyval(p_fit, x_fit), '-', 'Color', [0.10 0.25 0.54], 'LineWidth', 2);
end
[rho_at, p_at] = corr(flat_start_time(v), flat_area(v), 'Type', 'Spearman');
xlabel('Time since stim onset (s)', 'FontSize', 12);
ylabel('Bbox area (mm^2)', 'FontSize', 12);
title(sprintf('Area vs time\n\\rho=%.3f, p=%.3e', rho_at, p_at), 'FontSize', 12);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% (3) CW vs CCW proportion by stimulus half
subplot(2, 2, 3);
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

set(gca, 'XTick', 1:2, 'XTickLabel', {'CW stim (half 1)', 'CCW stim (half 2)'});
ylabel('Proportion', 'FontSize', 12);
title(sprintf('Direction by stim half\n\\chi^2=%.2f, p=%.3f', chi2_h, p_chi_half), 'FontSize', 12);
legend('CW loops', 'CCW loops', 'Location', 'best');
ylim([0 1]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

fprintf('Direction vs stimulus half chi-squared: chi2=%.2f, df=%d, p=%.4f\n', ...
    chi2_h, df_h, p_chi_half);

% (4) |heading| vs time, coloured by stimulus half
subplot(2, 2, 4);
hold on;
h1_idx = flat_stim_half == 1;
h2_idx = flat_stim_half == 2;
scatter(flat_start_time(h1_idx), abs(flat_hdg(h1_idx)), 15, [0.894 0.102 0.110], ...
    'filled', 'MarkerFaceAlpha', 0.3, 'MarkerEdgeColor', 'none');
scatter(flat_start_time(h2_idx), abs(flat_hdg(h2_idx)), 15, [0.216 0.494 0.722], ...
    'filled', 'MarkerFaceAlpha', 0.3, 'MarkerEdgeColor', 'none');
xlabel('Time since stim onset (s)', 'FontSize', 12);
ylabel('|Heading change| (deg)', 'FontSize', 12);
title('|Heading| vs time by stim half', 'FontSize', 12);
legend('CW half', 'CCW half', 'Location', 'best');
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% --- Figure 12: Multiple regression to disentangle distance vs time ---
%
%  For each metric, fit:  metric = b0 + b_dist * distance + b_time * time
%
%  We z-score both predictors so the coefficients (standardised betas)
%  are directly comparable in effect size. This tests whether distance
%  has an effect *after controlling for time*, and vice versa.

fig12 = figure('Position', [50 50 900 450], 'Name', 'Fig 12: Distance vs Time Effects');
sgtitle('Multiple regression: standardised betas (distance vs time)', 'FontSize', 18);

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

set(gca, 'XTick', x_pos, 'XTickLabel', scatter_ylabels);
ylabel('Standardised beta', 'FontSize', 14);
legend('Distance', 'Time', 'Location', 'best');
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

%% ================================================================
%  SECTION 8: Metric correlation matrix (Figure 13)
%  ================================================================

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

%% Print final summary

fprintf('\n=============================================\n');
fprintf('  ANALYSIS COMPLETE\n');
fprintf('  %d loops from %d flies (control strain)\n', n_total_loops, n_flies);
fprintf('  Frames 750-850 excluded (stimulus reversal)\n');
fprintf('  13 figures generated\n');
fprintf('=============================================\n');
