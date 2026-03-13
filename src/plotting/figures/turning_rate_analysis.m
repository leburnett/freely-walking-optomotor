%% TURNING_RATE_ANALYSIS - Fly-centric angular velocity vs wall distance
%
% Analyzes how angular velocity (av_data, the fly's turning rate in deg/s)
% varies with distance to the arena wall. This is the most direct test of
% the viewing-distance-dependent optomotor gain hypothesis: flies closer to
% the wall see faster retinal slip and should turn more.
%
% Unlike the arena-centric radial/tangential decomposition, this analysis
% measures the fly's actual motor output (turning) rather than the
% positional consequences (centring).
%
% FIGURES PRODUCED:
%   Figure 1 (2x1): Fly-centric motor output timeseries for control
%   Figure 2 (1x2): Angular velocity vs wall distance (stimulus vs baseline)
%   Figure 3 (4x2): Cross-strain comparison of AV vs wall distance
%   Figure 4 (1x1): Per-fly slope summary across strains
%
% REQUIREMENTS:
%   - DATA struct from comb_data_across_cohorts_cond (Protocol 27)
%   - Functions: combine_timeseries_across_exp_check
%
% See also: radial_tangential_analysis, compute_radial_tangential

%% 1 — Configuration

if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
    fprintf('Loaded DATA from %s\n', protocol_dir);
end

cfg = get_config();

% Arena geometry
ARENA_R = 119;  % arena radius in mm
FPS = 30;

% Key strains and conditions
control_strain = "jfrc100_es_shibire_kir";
key_strains = {"ss324_t4t5_shibire_kir", "ss00297_Dm4_shibire_kir", ...
               "ss03722_Tm5Y_shibire_kir", "l1l4_jfrc100_shibire_kir"};
key_labels  = {"T4/T5", "Dm4", "Tm5Y", "L1/L4"};
key_condition = 1;  % 60deg gratings 4Hz
sex = 'F';

% Stimulus timing (frames at 30 fps)
STIM_ON  = 300;   % 10s
STIM_MID = 750;   % 25s (direction change CW->CCW)
STIM_OFF = 1200;  % 40s

% Pre-stimulus window for baseline comparison (last 10s before stim)
PRE_START = 1;
PRE_END   = 300;

% Distance-to-wall bins (mm from wall)
bin_edges = 0:10:ARENA_R;  % 0 = at wall, 119 = at centre
n_bins = numel(bin_edges) - 1;
bin_centres = bin_edges(1:end-1) + diff(bin_edges)/2;

% Colors — light grey for control, blue gradient for strain comparisons
ctrl_col       = [0.7 0.7 0.7];
ctrl_col_line  = [0.4 0.4 0.4];
ctrl_col_fill  = [0.85 0.85 0.85];

% Dashboard strain palette for discrete comparisons
strain_cols = [0.216 0.494 0.722;   % blue   (#377eb8) - T4/T5
               0.894 0.102 0.110;   % red    (#e41a1c) - Dm4
               0.302 0.686 0.290;   % green  (#4daf4a) - Tm5Y
               0.596 0.306 0.639];  % purple (#984ea3) - L1/L4

% Blue gradient for distance bins (light -> dark)
blue_gradient = interp1([1; n_bins], [0.75 0.85 0.95; 0.10 0.25 0.54], 1:n_bins);

% Figure save toggle
save_figs = 0;
save_folder = fullfile(cfg.figures, 'FIGS');

%% 2 — Load control data

fprintf('\n=== Loading control data (condition %d) ===\n', key_condition);
data_ctrl = DATA.(control_strain).(sex);

av_ctrl   = combine_timeseries_across_exp_check(data_ctrl, key_condition, "av_data");
dist_ctrl = combine_timeseries_across_exp_check(data_ctrl, key_condition, "dist_data");
fv_ctrl   = combine_timeseries_across_exp_check(data_ctrl, key_condition, "fv_data");

n_ctrl = size(av_ctrl, 1);
n_frames = size(av_ctrl, 2);
x_frames = 1:n_frames;
fprintf('  Control: %d flies, %d frames\n', n_ctrl, n_frames);

% Distance to wall
wall_dist_ctrl = ARENA_R - dist_ctrl;  % 0 = at wall, 119 = at centre

%% 3 — Figure 1: Fly-centric motor output timeseries (2x1)

fig1 = figure('Position', [392 257 606 527]);
sgtitle('Fly-Centric Motor Outputs — Control, 60° Gratings 4Hz', 'FontSize', 18);

% Panel A: Absolute angular velocity
subplot(2, 1, 1);
hold on;
abs_av = abs(av_ctrl);
mean_av = nanmean(abs_av, 1);
sem_av  = nanstd(abs_av, 0, 1) / sqrt(n_ctrl);
y1 = mean_av + sem_av;
y2 = mean_av - sem_av;
patch([x_frames fliplr(x_frames)], [y1 fliplr(y2)], [0 0 0], ...
    'FaceAlpha', 0.15, 'EdgeColor', 'none');
plot(x_frames, mean_av, '-', 'Color', [0 0 0], 'LineWidth', 1.5);
xline(STIM_ON,  '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(STIM_MID, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(STIM_OFF, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
ylabel('|Angular velocity| (deg/s)', 'FontSize', 14);
title('A — Absolute angular velocity (fly-centric turning rate)', 'FontSize', 16);
xticks([0, 300, 600, 900, 1200, 1500]);
xticklabels({'0', '10', '20', '30', '40', '50'});
xlim([0 1800]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Panel B: Forward velocity
subplot(2, 1, 2);
hold on;
mean_fv = nanmean(fv_ctrl, 1);
sem_fv  = nanstd(fv_ctrl, 0, 1) / sqrt(n_ctrl);
y1 = mean_fv + sem_fv;
y2 = mean_fv - sem_fv;
patch([x_frames fliplr(x_frames)], [y1 fliplr(y2)], [0 0 0], ...
    'FaceAlpha', 0.15, 'EdgeColor', 'none');
plot(x_frames, mean_fv, '-', 'Color', [0 0 0], 'LineWidth', 1.5);
xline(STIM_ON,  '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(STIM_MID, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(STIM_OFF, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
ylabel('Forward velocity (mm/s)', 'FontSize', 14);
xlabel('Time (s)', 'FontSize', 14);
title('B — Forward velocity', 'FontSize', 16);
xticks([0, 300, 600, 900, 1200, 1500]);
xticklabels({'0', '10', '20', '30', '40', '50'});
xlim([0 1800]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

if save_figs
    exportgraphics(fig1, fullfile(save_folder, 'turning_rate_timeseries.pdf'), ...
        'ContentType', 'vector');
    close(fig1);
end

%% 4 — Helper: bin angular velocity by wall distance

function [bin_means, bin_sems, bin_n, per_fly_means] = bin_av_by_wall_dist( ...
        av_data, wall_dist, frame_range, bin_edges)
    % Compute mean |av| per wall-distance bin, averaged across flies
    %
    % Returns:
    %   bin_means    - 1 x n_bins, mean across flies of per-fly bin means
    %   bin_sems     - 1 x n_bins, SEM across flies
    %   bin_n        - 1 x n_bins, number of flies contributing to each bin
    %   per_fly_means - n_flies x n_bins, per-fly bin averages

    n_flies = size(av_data, 1);
    n_bins = numel(bin_edges) - 1;
    per_fly_means = NaN(n_flies, n_bins);

    abs_av = abs(av_data(:, frame_range));
    wd     = wall_dist(:, frame_range);

    for f = 1:n_flies
        av_f = abs_av(f, :);
        wd_f = wd(f, :);
        for b = 1:n_bins
            in_bin = wd_f >= bin_edges(b) & wd_f < bin_edges(b+1);
            if sum(in_bin & ~isnan(av_f)) >= 5  % require at least 5 frames
                per_fly_means(f, b) = nanmean(av_f(in_bin));
            end
        end
    end

    bin_means = nanmean(per_fly_means, 1);
    bin_sems  = nanstd(per_fly_means, 0, 1) ./ sqrt(sum(~isnan(per_fly_means), 1));
    bin_n     = sum(~isnan(per_fly_means), 1);
end

%% 5 — Figure 2: Angular velocity vs wall distance (stimulus vs baseline)

% Stimulus period
[stim_means, stim_sems, stim_n, stim_per_fly] = bin_av_by_wall_dist( ...
    av_ctrl, wall_dist_ctrl, STIM_ON:STIM_OFF, bin_edges);

% Baseline period
[base_means, base_sems, base_n, ~] = bin_av_by_wall_dist( ...
    av_ctrl, wall_dist_ctrl, PRE_START:PRE_END, bin_edges);

fig2 = figure('Position', [227 191 665 242]);
sgtitle('Angular Velocity vs Distance to Wall — Control', 'FontSize', 18);

% Panel A: Stimulus period
subplot(1, 2, 1);
hold on;
% SEM shading
valid = ~isnan(stim_means);
y1 = stim_means(valid) + stim_sems(valid);
y2 = stim_means(valid) - stim_sems(valid);
bc = bin_centres(valid);
patch([bc fliplr(bc)], [y1 fliplr(y2)], [0 0 0], ...
    'FaceAlpha', 0.12, 'EdgeColor', 'none');
plot(bc, stim_means(valid), '-o', 'Color', [0 0 0], ...
    'LineWidth', 1.5, 'MarkerSize', 5, 'MarkerFaceColor', [0 0 0]);

% Linear fit
valid_bins = find(valid);
if numel(valid_bins) >= 3
    p_stim = polyfit(bc, stim_means(valid), 1);
    x_fit = linspace(min(bc), max(bc), 100);
    plot(x_fit, polyval(p_stim, x_fit), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1.5);
    text(0.05, 0.95, sprintf('slope = %.2f deg/s per mm', p_stim(1)), ...
        'Units', 'normalized', 'FontSize', 11, 'VerticalAlignment', 'top');
end

xlabel('Distance to wall (mm)', 'FontSize', 14);
ylabel('Mean |angular velocity| (deg/s)', 'FontSize', 14);
title('A — During stimulus', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Panel B: Baseline period
subplot(1, 2, 2);
hold on;
valid = ~isnan(base_means);
y1 = base_means(valid) + base_sems(valid);
y2 = base_means(valid) - base_sems(valid);
bc_b = bin_centres(valid);
patch([bc_b fliplr(bc_b)], [y1 fliplr(y2)], [0 0 0], ...
    'FaceAlpha', 0.12, 'EdgeColor', 'none');
plot(bc_b, base_means(valid), '-o', 'Color', [0 0 0], ...
    'LineWidth', 1.5, 'MarkerSize', 5, 'MarkerFaceColor', [0 0 0]);

% Linear fit
if sum(valid) >= 3
    p_base = polyfit(bc_b, base_means(valid), 1);
    x_fit = linspace(min(bc_b), max(bc_b), 100);
    plot(x_fit, polyval(p_base, x_fit), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1.5);
    text(0.05, 0.95, sprintf('slope = %.2f deg/s per mm', p_base(1)), ...
        'Units', 'normalized', 'FontSize', 11, 'VerticalAlignment', 'top');
end

xlabel('Distance to wall (mm)', 'FontSize', 14);
ylabel('Mean |angular velocity| (deg/s)', 'FontSize', 14);
title('B — Pre-stimulus baseline', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

if save_figs
    exportgraphics(fig2, fullfile(save_folder, 'turning_rate_vs_wall_distance.pdf'), ...
        'ContentType', 'vector');
    close(fig2);
end

%% 6 — Load key strains

fprintf('\n=== Loading key strains ===\n');
strain_data = struct();

for s = 1:numel(key_strains)
    sname = key_strains{s};
    slabel = key_labels{s};

    data_s = DATA.(sname).(sex);
    av_s   = combine_timeseries_across_exp_check(data_s, key_condition, "av_data");
    dist_s = combine_timeseries_across_exp_check(data_s, key_condition, "dist_data");
    fv_s   = combine_timeseries_across_exp_check(data_s, key_condition, "fv_data");

    n_s = size(av_s, 1);
    fprintf('  %s: %d flies\n', slabel, n_s);

    wall_dist_s = ARENA_R - dist_s;

    % Bin by wall distance during stimulus
    [s_means, s_sems, s_n, s_per_fly] = bin_av_by_wall_dist( ...
        av_s, wall_dist_s, STIM_ON:min(STIM_OFF, size(av_s, 2)), bin_edges);

    strain_data(s).name = sname;
    strain_data(s).label = slabel;
    strain_data(s).n = n_s;
    strain_data(s).av = av_s;
    strain_data(s).dist = dist_s;
    strain_data(s).fv = fv_s;
    strain_data(s).wall_dist = wall_dist_s;
    strain_data(s).bin_means = s_means;
    strain_data(s).bin_sems = s_sems;
    strain_data(s).bin_n = s_n;
    strain_data(s).per_fly_means = s_per_fly;
end

%% 7 — Figure 3: Cross-strain comparison of AV vs wall distance (4x2)

fig3 = figure('Position', [507 54 703 977]);
sgtitle('Angular Velocity vs Wall Distance — Cross-Strain Comparison', 'FontSize', 18);

for s = 1:numel(key_strains)

    % --- Left column: AV vs wall distance ---
    subplot(numel(key_strains), 2, (s-1)*2 + 1);
    hold on;

    % Control (grey)
    valid_c = ~isnan(stim_means);
    bc_c = bin_centres(valid_c);
    y1_c = stim_means(valid_c) + stim_sems(valid_c);
    y2_c = stim_means(valid_c) - stim_sems(valid_c);
    patch([bc_c fliplr(bc_c)], [y1_c fliplr(y2_c)], ctrl_col_fill, ...
        'FaceAlpha', 0.5, 'EdgeColor', 'none');
    plot(bc_c, stim_means(valid_c), '-', 'Color', ctrl_col, 'LineWidth', 1);

    % Strain (colored)
    valid_s = ~isnan(strain_data(s).bin_means);
    bc_s = bin_centres(valid_s);
    y1_s = strain_data(s).bin_means(valid_s) + strain_data(s).bin_sems(valid_s);
    y2_s = strain_data(s).bin_means(valid_s) - strain_data(s).bin_sems(valid_s);
    patch([bc_s fliplr(bc_s)], [y1_s fliplr(y2_s)], strain_cols(s,:), ...
        'FaceAlpha', 0.15, 'EdgeColor', 'none');
    plot(bc_s, strain_data(s).bin_means(valid_s), '-o', 'Color', strain_cols(s,:), ...
        'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', strain_cols(s,:));

    xlabel('Distance to wall (mm)', 'FontSize', 14);
    ylabel('|AV| (deg/s)', 'FontSize', 14);
    title(sprintf('%s — |AV| vs wall distance (n=%d)', strain_data(s).label, strain_data(s).n), 'FontSize', 16);
    set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

    % --- Right column: AV timeseries ---
    subplot(numel(key_strains), 2, (s-1)*2 + 2);
    hold on;

    nf_s = size(strain_data(s).av, 2);
    nf_common = min(n_frames, nf_s);
    x_common = 1:nf_common;

    % Control (grey)
    abs_av_ctrl = abs(av_ctrl(:, 1:nf_common));
    mean_av_c = nanmean(abs_av_ctrl, 1);
    sem_av_c  = nanstd(abs_av_ctrl, 0, 1) / sqrt(n_ctrl);
    patch([x_common fliplr(x_common)], [mean_av_c+sem_av_c fliplr(mean_av_c-sem_av_c)], ...
        ctrl_col_fill, 'FaceAlpha', 0.5, 'EdgeColor', 'none');
    plot(x_common, mean_av_c, '-', 'Color', ctrl_col, 'LineWidth', 1);

    % Strain
    abs_av_s = abs(strain_data(s).av(:, 1:nf_common));
    n_s = strain_data(s).n;
    mean_av_s = nanmean(abs_av_s, 1);
    sem_av_s  = nanstd(abs_av_s, 0, 1) / sqrt(n_s);
    patch([x_common fliplr(x_common)], [mean_av_s+sem_av_s fliplr(mean_av_s-sem_av_s)], ...
        strain_cols(s,:), 'FaceAlpha', 0.15, 'EdgeColor', 'none');
    plot(x_common, mean_av_s, '-', 'Color', strain_cols(s,:), 'LineWidth', 1.5);

    xline(STIM_ON,  '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    xline(STIM_MID, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    xline(STIM_OFF, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    ylabel('|AV| (deg/s)', 'FontSize', 14);
    title(sprintf('%s — |AV| timeseries', strain_data(s).label), 'FontSize', 16);
    xticks([0, 300, 600, 900, 1200, 1500]);
    xticklabels({'0', '10', '20', '30', '40', '50'});
    xlim([0 1800]);
    if s == numel(key_strains)
        xlabel('Time (s)', 'FontSize', 14);
    end
    set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
end

if save_figs
    exportgraphics(fig3, fullfile(save_folder, 'turning_rate_cross_strain.pdf'), ...
        'ContentType', 'vector');
    close(fig3);
end

%% 8 — Per-fly slope computation

fprintf('\n=== Per-fly slope: |AV| vs wall distance ===\n');

% Control slopes
ctrl_slopes = NaN(n_ctrl, 1);
for f = 1:n_ctrl
    per_fly_bins = stim_per_fly(f, :);
    valid = ~isnan(per_fly_bins);
    if sum(valid) >= 3
        p = polyfit(bin_centres(valid), per_fly_bins(valid), 1);
        ctrl_slopes(f) = p(1);  % deg/s per mm (negative = more turning near wall)
    end
end
ctrl_slopes_clean = ctrl_slopes(~isnan(ctrl_slopes));

% Strain slopes
all_slopes = cell(numel(key_strains), 1);
for s = 1:numel(key_strains)
    n_s = strain_data(s).n;
    slopes_s = NaN(n_s, 1);
    for f = 1:n_s
        per_fly_bins = strain_data(s).per_fly_means(f, :);
        valid = ~isnan(per_fly_bins);
        if sum(valid) >= 3
            p = polyfit(bin_centres(valid), per_fly_bins(valid), 1);
            slopes_s(f) = p(1);
        end
    end
    all_slopes{s} = slopes_s;
end

%% 9 — Figure 4: Per-fly slope summary

fig4 = figure('Position', [1173 64 482 498]);
hold on;

% Prepare data for box chart
group_labels = categorical(["Control", key_labels{:}]);
group_labels = reordercats(group_labels, ["Control", key_labels{:}]);

% Plot control
x_jitter = 1 + 0.15 * randn(numel(ctrl_slopes_clean), 1);
scatter(x_jitter, ctrl_slopes_clean, 25, ctrl_col_fill, 'filled', ...
    'MarkerFaceAlpha', 0.4);
bx = boxchart(ones(numel(ctrl_slopes_clean), 1), ctrl_slopes_clean, ...
    'BoxFaceColor', ctrl_col, 'MarkerStyle', 'none', 'BoxWidth', 0.5);

% Plot strains
for s = 1:numel(key_strains)
    slopes_clean = all_slopes{s}(~isnan(all_slopes{s}));
    x_pos = s + 1;
    x_jitter = x_pos + 0.15 * randn(numel(slopes_clean), 1);
    scatter(x_jitter, slopes_clean, 25, strain_cols(s,:), 'filled', ...
        'MarkerFaceAlpha', 0.4);
    boxchart(x_pos * ones(numel(slopes_clean), 1), slopes_clean, ...
        'BoxFaceColor', strain_cols(s,:), 'MarkerStyle', 'none', 'BoxWidth', 0.5);
end

yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xticks(1:numel(key_strains)+1);
xticklabels(["Control", key_labels{:}]);
ylabel('Slope: |AV| vs wall distance (deg/s per mm)', 'FontSize', 14);
title('Per-Fly Slope of Angular Velocity vs Wall Distance', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

if save_figs
    exportgraphics(fig4, fullfile(save_folder, 'turning_rate_slope_summary.pdf'), ...
        'ContentType', 'vector');
    close(fig4);
end

%% 10 — Statistics

fprintf('\n=== Statistics Summary ===\n');

% Control: one-sample t-test on slope vs 0
[~, p_ctrl_slope] = ttest(ctrl_slopes_clean, 0);
fprintf('Control slope: mean = %.3f, median = %.3f, p vs 0 = %.2e (n=%d)\n', ...
    mean(ctrl_slopes_clean), median(ctrl_slopes_clean), p_ctrl_slope, numel(ctrl_slopes_clean));

% Mean |AV| during stimulus
ctrl_mean_av = nanmean(abs(av_ctrl(:, STIM_ON:STIM_OFF)), 2);
fprintf('Control mean |AV| during stimulus: %.1f +/- %.1f deg/s\n', ...
    nanmean(ctrl_mean_av), nanstd(ctrl_mean_av));

% Strains vs control
fprintf('\n%-12s  %6s  %10s  %10s  %10s  %10s  %10s\n', ...
    'Strain', 'N', 'MeanSlope', 'MedianSlp', 'Welch_t', 'Welch_p', 'Cohen_d');
fprintf('%s\n', repmat('-', 1, 80));

for s = 1:numel(key_strains)
    slopes_s = all_slopes{s}(~isnan(all_slopes{s}));

    [~, p_w, ~, stats_w] = ttest2(slopes_s, ctrl_slopes_clean, 'Vartype', 'unequal');

    % Cohen's d
    pooled_sd = sqrt(((numel(ctrl_slopes_clean)-1)*var(ctrl_slopes_clean) + ...
                      (numel(slopes_s)-1)*var(slopes_s)) / ...
                     (numel(ctrl_slopes_clean) + numel(slopes_s) - 2));
    d = (mean(slopes_s) - mean(ctrl_slopes_clean)) / pooled_sd;

    fprintf('%-12s  %6d  %10.4f  %10.4f  %10.2f  %10.2e  %10.3f\n', ...
        key_labels{s}, numel(slopes_s), mean(slopes_s), median(slopes_s), ...
        stats_w.tstat, p_w, d);

    % Mean |AV| during stimulus
    stim_end_s = min(STIM_OFF, size(strain_data(s).av, 2));
    mean_av_s = nanmean(abs(strain_data(s).av(:, STIM_ON:stim_end_s)), 2);
    fprintf('  Mean |AV| during stimulus: %.1f +/- %.1f deg/s\n', ...
        nanmean(mean_av_s), nanstd(mean_av_s));
end

% Baseline vs stimulus slope comparison (control)
[base_means_b, ~, ~, base_per_fly] = bin_av_by_wall_dist( ...
    av_ctrl, wall_dist_ctrl, PRE_START:PRE_END, bin_edges);
base_slopes = NaN(n_ctrl, 1);
for f = 1:n_ctrl
    per_fly_bins = base_per_fly(f, :);
    valid = ~isnan(per_fly_bins);
    if sum(valid) >= 3
        p = polyfit(bin_centres(valid), per_fly_bins(valid), 1);
        base_slopes(f) = p(1);
    end
end
base_slopes_clean = base_slopes(~isnan(base_slopes));

[~, p_base_slope] = ttest(base_slopes_clean, 0);
[~, p_stim_vs_base] = ttest2(ctrl_slopes_clean, base_slopes_clean);
fprintf('\nBaseline slope: mean = %.4f, p vs 0 = %.2e (n=%d)\n', ...
    mean(base_slopes_clean), p_base_slope, numel(base_slopes_clean));
fprintf('Stimulus vs baseline slope: p = %.2e\n', p_stim_vs_base);

fprintf('\n=== Done ===\n');
