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
%   Figure 5 (1x2): Delta-AV (stimulus minus baseline) vs wall distance
%   Figure 6 (1x2): Early vs late stimulus AV vs wall distance
%   Figure 7 (1x2): Forward velocity vs wall distance (stimulus vs baseline)
%   Figure 8 (2x2): Starting-position-conditioned AV (first 3s of stimulus)
%   Figure 9 (1x3): Offset CoR (cond 11 vs cond 1 vs flicker cond 9)
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

function [bin_means, bin_sems, bin_n, per_fly_means] = bin_fv_by_wall_dist( ...
        fv_data, wall_dist, frame_range, bin_edges)
    % Same as bin_av_by_wall_dist but for forward velocity (no abs)

    n_flies = size(fv_data, 1);
    n_bins = numel(bin_edges) - 1;
    per_fly_means = NaN(n_flies, n_bins);

    fv = fv_data(:, frame_range);
    wd = wall_dist(:, frame_range);

    for f = 1:n_flies
        fv_f = fv(f, :);
        wd_f = wd(f, :);
        for b = 1:n_bins
            in_bin = wd_f >= bin_edges(b) & wd_f < bin_edges(b+1);
            if sum(in_bin & ~isnan(fv_f)) >= 5
                per_fly_means(f, b) = nanmean(fv_f(in_bin));
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

%% 11 — Figure 5: Delta-AV (stimulus minus baseline) vs wall distance
%  Removes pre-existing distance-dependent turning to isolate stimulus effect

fprintf('\n=== Delta-AV Analysis (stimulus minus baseline) ===\n');

% Per-fly delta: stimulus bin mean minus baseline bin mean
delta_per_fly = stim_per_fly - base_per_fly(1:size(stim_per_fly,1), :);
delta_means = nanmean(delta_per_fly, 1);
delta_sems  = nanstd(delta_per_fly, 0, 1) ./ sqrt(sum(~isnan(delta_per_fly), 1));

% Per-fly delta slopes
delta_slopes = NaN(n_ctrl, 1);
for f = 1:n_ctrl
    d_bins = delta_per_fly(f, :);
    valid = ~isnan(d_bins);
    if sum(valid) >= 3
        p = polyfit(bin_centres(valid), d_bins(valid), 1);
        delta_slopes(f) = p(1);
    end
end
delta_slopes_clean = delta_slopes(~isnan(delta_slopes));

[~, p_delta] = ttest(delta_slopes_clean, 0);
fprintf('Delta slope (stim - base): mean = %.4f, p vs 0 = %.2e (n=%d)\n', ...
    mean(delta_slopes_clean), p_delta, numel(delta_slopes_clean));

fig5 = figure('Position', [50 500 900 350]);
sgtitle('Stimulus-Driven Change in |AV| vs Wall Distance — Control', 'FontSize', 18);

% Panel A: Delta-AV vs wall distance
subplot(1, 2, 1);
hold on;
valid = ~isnan(delta_means);
bc_d = bin_centres(valid);
y1 = delta_means(valid) + delta_sems(valid);
y2 = delta_means(valid) - delta_sems(valid);
patch([bc_d fliplr(bc_d)], [y1 fliplr(y2)], [0 0 0], ...
    'FaceAlpha', 0.12, 'EdgeColor', 'none');
plot(bc_d, delta_means(valid), '-o', 'Color', [0 0 0], ...
    'LineWidth', 1.5, 'MarkerSize', 5, 'MarkerFaceColor', [0 0 0]);
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

if sum(valid) >= 3
    p_fit = polyfit(bc_d, delta_means(valid), 1);
    x_fit = linspace(min(bc_d), max(bc_d), 100);
    plot(x_fit, polyval(p_fit, x_fit), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1.5);
    text(0.05, 0.95, sprintf('slope = %.2f deg/s per mm', p_fit(1)), ...
        'Units', 'normalized', 'FontSize', 11, 'VerticalAlignment', 'top');
end

xlabel('Distance to wall (mm)', 'FontSize', 14);
ylabel('\Delta|AV| (stim - base, deg/s)', 'FontSize', 14);
title('A — Stimulus-driven \Delta|AV|', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Panel B: Delta slope distribution
subplot(1, 2, 2);
hold on;
histogram(delta_slopes_clean, 30, 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'w');
xline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(mean(delta_slopes_clean), '-', 'Color', [0 0 0], 'LineWidth', 1.5);
xlabel('\Delta slope (deg/s per mm)', 'FontSize', 14);
ylabel('Count', 'FontSize', 14);
title(sprintf('B — Per-fly \\Delta slopes (p = %.1e)', p_delta), 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

if save_figs
    exportgraphics(fig5, fullfile(save_folder, 'turning_rate_delta_av.pdf'), ...
        'ContentType', 'vector');
    close(fig5);
end

%% 12 — Figure 6: Early vs late stimulus — temporal confound test
%  If positive slope is a centring artifact, it should be absent early

fprintf('\n=== Early vs Late Stimulus Analysis ===\n');

EARLY_START = STIM_ON;
EARLY_END   = STIM_ON + 150;   % first 5s of stimulus
LATE_START  = STIM_OFF - 150;  % last 5s of stimulus
LATE_END    = STIM_OFF;

[early_means, early_sems, ~, early_per_fly] = bin_av_by_wall_dist( ...
    av_ctrl, wall_dist_ctrl, EARLY_START:EARLY_END, bin_edges);
[late_means, late_sems, ~, late_per_fly] = bin_av_by_wall_dist( ...
    av_ctrl, wall_dist_ctrl, LATE_START:LATE_END, bin_edges);

% Per-fly slopes for early and late
early_slopes = NaN(n_ctrl, 1);
late_slopes  = NaN(n_ctrl, 1);
for f = 1:n_ctrl
    e_bins = early_per_fly(f, :);
    l_bins = late_per_fly(f, :);
    v_e = ~isnan(e_bins);
    v_l = ~isnan(l_bins);
    if sum(v_e) >= 3
        p = polyfit(bin_centres(v_e), e_bins(v_e), 1);
        early_slopes(f) = p(1);
    end
    if sum(v_l) >= 3
        p = polyfit(bin_centres(v_l), l_bins(v_l), 1);
        late_slopes(f) = p(1);
    end
end
early_slopes_clean = early_slopes(~isnan(early_slopes));
late_slopes_clean  = late_slopes(~isnan(late_slopes));

[~, p_early] = ttest(early_slopes_clean, 0);
[~, p_late]  = ttest(late_slopes_clean, 0);
[~, p_el]    = ttest2(early_slopes_clean, late_slopes_clean);

fprintf('Early slope (first 5s): mean = %.4f, p vs 0 = %.2e (n=%d)\n', ...
    mean(early_slopes_clean), p_early, numel(early_slopes_clean));
fprintf('Late slope (last 5s):   mean = %.4f, p vs 0 = %.2e (n=%d)\n', ...
    mean(late_slopes_clean), p_late, numel(late_slopes_clean));
fprintf('Early vs late:          p = %.2e\n', p_el);

fig6 = figure('Position', [50 100 900 350]);
sgtitle('Early vs Late Stimulus: |AV| vs Wall Distance — Control', 'FontSize', 18);

early_col = [0.45 0.62 0.80];
late_col  = [0.10 0.25 0.54];

% Panel A: Binned curves
subplot(1, 2, 1);
hold on;
valid_e = ~isnan(early_means);
valid_l = ~isnan(late_means);
bc_e = bin_centres(valid_e);
bc_l = bin_centres(valid_l);

patch([bc_e fliplr(bc_e)], ...
    [early_means(valid_e)+early_sems(valid_e) fliplr(early_means(valid_e)-early_sems(valid_e))], ...
    early_col, 'FaceAlpha', 0.15, 'EdgeColor', 'none');
h1 = plot(bc_e, early_means(valid_e), '-o', 'Color', early_col, ...
    'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', early_col);

patch([bc_l fliplr(bc_l)], ...
    [late_means(valid_l)+late_sems(valid_l) fliplr(late_means(valid_l)-late_sems(valid_l))], ...
    late_col, 'FaceAlpha', 0.15, 'EdgeColor', 'none');
h2 = plot(bc_l, late_means(valid_l), '-o', 'Color', late_col, ...
    'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', late_col);

legend([h1 h2], {sprintf('Early (first 5s), slope=%.2f', mean(early_slopes_clean)), ...
                  sprintf('Late (last 5s), slope=%.2f', mean(late_slopes_clean))}, ...
    'Location', 'best', 'FontSize', 10);
xlabel('Distance to wall (mm)', 'FontSize', 14);
ylabel('Mean |AV| (deg/s)', 'FontSize', 14);
title('A — |AV| vs wall distance', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Panel B: Slope comparison
subplot(1, 2, 2);
hold on;
x_jit_e = 1 + 0.15 * randn(numel(early_slopes_clean), 1);
x_jit_l = 2 + 0.15 * randn(numel(late_slopes_clean), 1);
scatter(x_jit_e, early_slopes_clean, 15, early_col, 'filled', 'MarkerFaceAlpha', 0.3);
scatter(x_jit_l, late_slopes_clean, 15, late_col, 'filled', 'MarkerFaceAlpha', 0.3);
boxchart(ones(numel(early_slopes_clean),1), early_slopes_clean, ...
    'BoxFaceColor', early_col, 'MarkerStyle', 'none', 'BoxWidth', 0.5);
boxchart(2*ones(numel(late_slopes_clean),1), late_slopes_clean, ...
    'BoxFaceColor', late_col, 'MarkerStyle', 'none', 'BoxWidth', 0.5);
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xticks([1 2]);
xticklabels({'Early (5s)', 'Late (5s)'});
ylabel('Slope (deg/s per mm)', 'FontSize', 14);
title(sprintf('B — Slope comparison (p = %.1e)', p_el), 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

if save_figs
    exportgraphics(fig6, fullfile(save_folder, 'turning_rate_early_late.pdf'), ...
        'ContentType', 'vector');
    close(fig6);
end

%% 13 — Figure 7: Forward velocity vs wall distance
%  Rules out locomotor confound (slower walking near wall = lower AV)

fprintf('\n=== Forward Velocity vs Wall Distance ===\n');

% Reuse bin_av_by_wall_dist but pass fv_data instead of av_data
% Need a version that doesn't take abs() — use a wrapper
[fv_stim_means, fv_stim_sems, ~, fv_stim_per_fly] = bin_fv_by_wall_dist( ...
    fv_ctrl, wall_dist_ctrl, STIM_ON:STIM_OFF, bin_edges);
[fv_base_means, fv_base_sems, ~, ~] = bin_fv_by_wall_dist( ...
    fv_ctrl, wall_dist_ctrl, PRE_START:PRE_END, bin_edges);

% Per-fly FV slopes during stimulus
fv_slopes = NaN(n_ctrl, 1);
for f = 1:n_ctrl
    fv_bins = fv_stim_per_fly(f, :);
    valid = ~isnan(fv_bins);
    if sum(valid) >= 3
        p = polyfit(bin_centres(valid), fv_bins(valid), 1);
        fv_slopes(f) = p(1);
    end
end
fv_slopes_clean = fv_slopes(~isnan(fv_slopes));
[~, p_fv_slope] = ttest(fv_slopes_clean, 0);
fprintf('FV slope (stimulus): mean = %.4f, p vs 0 = %.2e (n=%d)\n', ...
    mean(fv_slopes_clean), p_fv_slope, numel(fv_slopes_clean));

fig7 = figure('Position', [500 500 900 350]);
sgtitle('Forward Velocity vs Wall Distance — Control', 'FontSize', 18);

% Panel A: Stimulus
subplot(1, 2, 1);
hold on;
valid = ~isnan(fv_stim_means);
bc_fv = bin_centres(valid);
y1 = fv_stim_means(valid) + fv_stim_sems(valid);
y2 = fv_stim_means(valid) - fv_stim_sems(valid);
patch([bc_fv fliplr(bc_fv)], [y1 fliplr(y2)], [0 0 0], ...
    'FaceAlpha', 0.12, 'EdgeColor', 'none');
plot(bc_fv, fv_stim_means(valid), '-o', 'Color', [0 0 0], ...
    'LineWidth', 1.5, 'MarkerSize', 5, 'MarkerFaceColor', [0 0 0]);

if sum(valid) >= 3
    p_fit = polyfit(bc_fv, fv_stim_means(valid), 1);
    x_fit = linspace(min(bc_fv), max(bc_fv), 100);
    plot(x_fit, polyval(p_fit, x_fit), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1.5);
    text(0.05, 0.95, sprintf('slope = %.3f mm/s per mm', p_fit(1)), ...
        'Units', 'normalized', 'FontSize', 11, 'VerticalAlignment', 'top');
end

xlabel('Distance to wall (mm)', 'FontSize', 14);
ylabel('Forward velocity (mm/s)', 'FontSize', 14);
title('A — During stimulus', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Panel B: Baseline
subplot(1, 2, 2);
hold on;
valid = ~isnan(fv_base_means);
bc_fvb = bin_centres(valid);
y1 = fv_base_means(valid) + fv_base_sems(valid);
y2 = fv_base_means(valid) - fv_base_sems(valid);
patch([bc_fvb fliplr(bc_fvb)], [y1 fliplr(y2)], [0 0 0], ...
    'FaceAlpha', 0.12, 'EdgeColor', 'none');
plot(bc_fvb, fv_base_means(valid), '-o', 'Color', [0 0 0], ...
    'LineWidth', 1.5, 'MarkerSize', 5, 'MarkerFaceColor', [0 0 0]);

if sum(valid) >= 3
    p_fit = polyfit(bc_fvb, fv_base_means(valid), 1);
    x_fit = linspace(min(bc_fvb), max(bc_fvb), 100);
    plot(x_fit, polyval(p_fit, x_fit), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1.5);
    text(0.05, 0.95, sprintf('slope = %.3f mm/s per mm', p_fit(1)), ...
        'Units', 'normalized', 'FontSize', 11, 'VerticalAlignment', 'top');
end

xlabel('Distance to wall (mm)', 'FontSize', 14);
ylabel('Forward velocity (mm/s)', 'FontSize', 14);
title('B — Pre-stimulus baseline', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

if save_figs
    exportgraphics(fig7, fullfile(save_folder, 'fv_vs_wall_distance.pdf'), ...
        'ContentType', 'vector');
    close(fig7);
end

%% 14 — Figure 8: Starting-position-conditioned analysis
%  Group flies by starting distance, look at first 3s before centring occurs

fprintf('\n=== Starting-Position-Conditioned Analysis ===\n');

EARLY_WINDOW = STIM_ON:(STIM_ON + 90);  % first 3s of stimulus (90 frames)

% Starting distance = mean distance from centre in last 1s before stimulus
start_dist = nanmean(dist_ctrl(:, (STIM_ON-30):STIM_ON), 2);
start_wall_dist = ARENA_R - start_dist;

% Split into tertiles by starting wall distance
terciles = quantile(start_wall_dist, [1/3, 2/3]);
grp_near = start_wall_dist <= terciles(1);       % near wall
grp_mid  = start_wall_dist > terciles(1) & start_wall_dist <= terciles(2);
grp_far  = start_wall_dist > terciles(2);         % far from wall (near centre)

grp_names = {'Near wall', 'Mid', 'Near centre'};
grp_masks = {grp_near, grp_mid, grp_far};
grp_cols  = [0.75 0.85 0.95; 0.45 0.62 0.80; 0.10 0.25 0.54];

fprintf('  Tertile boundaries: %.1f mm, %.1f mm from wall\n', terciles(1), terciles(2));

fig8 = figure('Position', [100 50 900 700]);
sgtitle('AV vs Wall Distance — Conditioned on Starting Position (first 3s)', 'FontSize', 18);

grp_slopes_all = cell(3, 1);

for g = 1:3
    mask = grp_masks{g};
    n_g = sum(mask);
    fprintf('  %s: n=%d flies (wall_dist %.0f-%.0f mm)\n', grp_names{g}, n_g, ...
        min(start_wall_dist(mask)), max(start_wall_dist(mask)));

    % Bin AV by wall distance for this group, early window only
    av_g = av_ctrl(mask, :);
    wd_g = wall_dist_ctrl(mask, :);
    [g_means, g_sems, ~, g_per_fly] = bin_av_by_wall_dist( ...
        av_g, wd_g, EARLY_WINDOW, bin_edges);

    % Per-fly slopes
    slopes_g = NaN(n_g, 1);
    for f = 1:n_g
        gb = g_per_fly(f, :);
        v = ~isnan(gb);
        if sum(v) >= 3
            p = polyfit(bin_centres(v), gb(v), 1);
            slopes_g(f) = p(1);
        end
    end
    grp_slopes_all{g} = slopes_g(~isnan(slopes_g));
    [~, p_g] = ttest(grp_slopes_all{g}, 0);
    fprintf('    Slope: mean = %.4f, p vs 0 = %.2e (n=%d)\n', ...
        mean(grp_slopes_all{g}), p_g, numel(grp_slopes_all{g}));

    % Panel: AV vs wall distance
    subplot(2, 2, g);
    hold on;
    valid = ~isnan(g_means);
    bc_g = bin_centres(valid);
    y1 = g_means(valid) + g_sems(valid);
    y2 = g_means(valid) - g_sems(valid);
    patch([bc_g fliplr(bc_g)], [y1 fliplr(y2)], grp_cols(g,:), ...
        'FaceAlpha', 0.15, 'EdgeColor', 'none');
    plot(bc_g, g_means(valid), '-o', 'Color', grp_cols(g,:), ...
        'LineWidth', 1.5, 'MarkerSize', 5, 'MarkerFaceColor', grp_cols(g,:));

    % Control reference (all flies, early window)
    [all_early_means, all_early_sems, ~, ~] = bin_av_by_wall_dist( ...
        av_ctrl, wall_dist_ctrl, EARLY_WINDOW, bin_edges);
    valid_all = ~isnan(all_early_means);
    plot(bin_centres(valid_all), all_early_means(valid_all), '-', ...
        'Color', ctrl_col, 'LineWidth', 1);

    if sum(valid) >= 3
        p_fit = polyfit(bc_g, g_means(valid), 1);
        x_fit = linspace(min(bc_g), max(bc_g), 100);
        plot(x_fit, polyval(p_fit, x_fit), '-', 'Color', grp_cols(g,:)*0.7, 'LineWidth', 1);
        text(0.05, 0.95, sprintf('slope = %.2f', p_fit(1)), ...
            'Units', 'normalized', 'FontSize', 11, 'VerticalAlignment', 'top');
    end

    xlabel('Distance to wall (mm)', 'FontSize', 14);
    ylabel('|AV| (deg/s)', 'FontSize', 14);
    title(sprintf('%s (n=%d)', grp_names{g}, n_g), 'FontSize', 16);
    set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
end

% Panel D: Mean |AV| in first 3s vs starting wall distance (all flies)
%  One point per fly — avoids the multi-bin requirement that made slopes underpowered
early_mean_av = nanmean(abs(av_ctrl(:, EARLY_WINDOW)), 2);
valid_scatter = ~isnan(early_mean_av) & ~isnan(start_wall_dist);

subplot(2, 2, 4);
hold on;

% Color each point by its tertile group
for g = 1:3
    mask_g = grp_masks{g} & valid_scatter;
    scatter(start_wall_dist(mask_g), early_mean_av(mask_g), 15, grp_cols(g,:), ...
        'filled', 'MarkerFaceAlpha', 0.3);
end

% Linear fit and Pearson correlation across all flies
x_sc = start_wall_dist(valid_scatter);
y_sc = early_mean_av(valid_scatter);
[r_corr, p_corr] = corr(x_sc, y_sc, 'type', 'Pearson');
p_fit = polyfit(x_sc, y_sc, 1);
x_line = linspace(min(x_sc), max(x_sc), 100);
plot(x_line, polyval(p_fit, x_line), '-', 'Color', [0 0 0], 'LineWidth', 1.5);

text(0.05, 0.95, sprintf('r = %.3f, p = %.1e (n=%d)', r_corr, p_corr, sum(valid_scatter)), ...
    'Units', 'normalized', 'FontSize', 11, 'VerticalAlignment', 'top');

xlabel('Starting wall distance (mm)', 'FontSize', 14);
ylabel('Mean |AV| first 3s (deg/s)', 'FontSize', 14);
title('D — Mean |AV| vs starting position', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

fprintf('  Correlation: mean |AV| (first 3s) vs start wall distance\n');
fprintf('    r = %.4f, p = %.2e, n = %d\n', r_corr, p_corr, sum(valid_scatter));

if save_figs
    exportgraphics(fig8, fullfile(save_folder, 'turning_rate_start_position.pdf'), ...
        'ContentType', 'vector');
    close(fig8);
end

%% 15 — Figure 9: Offset CoR (condition 11) — optic flow balance test
%  The grating's centre of rotation is shifted 0.8 arena radii from centre.
%  Prediction: if centring arises from optic flow balance at the CoR,
%  the positive |AV| vs wall-distance slope (seen for cond 1) should be
%  reduced or reversed for cond 11 when referenced to the ARENA centre,
%  because the balance point is now near the wall (23.8 mm from wall).
%  Flicker (cond 9) is included as a negative control (no coherent motion).

fprintf('\n=== Offset CoR Analysis (condition 11 vs condition 1 vs flicker) ===\n');

OFFSET_COND  = 11;  % 60deg gratings 0.8 offset CoR (Pattern 21)
FLICKER_COND = 9;   % 60deg flicker (no coherent motion)
COR_OFFSET   = 0.8; % arena radii units
COR_DIST     = COR_OFFSET * ARENA_R;  % distance from arena centre to CoR (mm)
COR_WALL_DIST = ARENA_R - COR_DIST;   % CoR distance from wall (mm)

fprintf('  CoR offset: %.1f mm from arena centre (%.1f mm from wall)\n', ...
    COR_DIST, COR_WALL_DIST);

% --- Load condition 11 (offset CoR) ---
av_offset   = combine_timeseries_across_exp_check(data_ctrl, OFFSET_COND, "av_data");
dist_offset = combine_timeseries_across_exp_check(data_ctrl, OFFSET_COND, "dist_data");
n_offset = size(av_offset, 1);
wall_dist_offset = ARENA_R - dist_offset;
stim_end_offset = min(STIM_OFF, size(av_offset, 2));
fprintf('  Condition %d (offset CoR): %d flies, %d frames\n', ...
    OFFSET_COND, n_offset, size(av_offset, 2));

% --- Load condition 9 (flicker) ---
av_flicker   = combine_timeseries_across_exp_check(data_ctrl, FLICKER_COND, "av_data");
dist_flicker = combine_timeseries_across_exp_check(data_ctrl, FLICKER_COND, "dist_data");
n_flicker = size(av_flicker, 1);
wall_dist_flicker = ARENA_R - dist_flicker;
stim_end_flicker = min(STIM_OFF, size(av_flicker, 2));
fprintf('  Condition %d (flicker):    %d flies, %d frames\n', ...
    FLICKER_COND, n_flicker, size(av_flicker, 2));

% --- Bin |AV| by wall distance during stimulus ---
[offset_stim_means, offset_stim_sems, ~, offset_stim_per_fly] = bin_av_by_wall_dist( ...
    av_offset, wall_dist_offset, STIM_ON:stim_end_offset, bin_edges);
[offset_base_means, offset_base_sems, ~, offset_base_per_fly] = bin_av_by_wall_dist( ...
    av_offset, wall_dist_offset, PRE_START:PRE_END, bin_edges);

[flicker_stim_means, flicker_stim_sems, ~, flicker_stim_per_fly] = bin_av_by_wall_dist( ...
    av_flicker, wall_dist_flicker, STIM_ON:stim_end_flicker, bin_edges);
[flicker_base_means, ~, ~, flicker_base_per_fly] = bin_av_by_wall_dist( ...
    av_flicker, wall_dist_flicker, PRE_START:PRE_END, bin_edges);

% --- Per-fly slopes during stimulus ---
offset_slopes = NaN(n_offset, 1);
for f = 1:n_offset
    pf = offset_stim_per_fly(f, :);
    v = ~isnan(pf);
    if sum(v) >= 3
        p = polyfit(bin_centres(v), pf(v), 1);
        offset_slopes(f) = p(1);
    end
end
offset_slopes_clean = offset_slopes(~isnan(offset_slopes));
[~, p_offset_slope] = ttest(offset_slopes_clean, 0);
fprintf('  Cond %d slope (stim):  mean = %.4f, p vs 0 = %.2e (n=%d)\n', ...
    OFFSET_COND, mean(offset_slopes_clean), p_offset_slope, numel(offset_slopes_clean));

flicker_slopes = NaN(n_flicker, 1);
for f = 1:n_flicker
    pf = flicker_stim_per_fly(f, :);
    v = ~isnan(pf);
    if sum(v) >= 3
        p = polyfit(bin_centres(v), pf(v), 1);
        flicker_slopes(f) = p(1);
    end
end
flicker_slopes_clean = flicker_slopes(~isnan(flicker_slopes));
[~, p_flicker_slope] = ttest(flicker_slopes_clean, 0);
fprintf('  Cond %d slope (stim):  mean = %.4f, p vs 0 = %.2e (n=%d)\n', ...
    FLICKER_COND, mean(flicker_slopes_clean), p_flicker_slope, numel(flicker_slopes_clean));

% Recap condition 1 for comparison
fprintf('  Cond %d slope (stim):  mean = %.4f (n=%d) [from Section 10]\n', ...
    key_condition, mean(ctrl_slopes_clean), numel(ctrl_slopes_clean));

% --- Unpaired comparisons: cond 1 vs cond 11 ---
[~, p_1vs11] = ttest2(ctrl_slopes_clean, offset_slopes_clean);
[~, p_1vs9]  = ttest2(ctrl_slopes_clean, flicker_slopes_clean);
[~, p_11vs9] = ttest2(offset_slopes_clean, flicker_slopes_clean);
fprintf('  Slope comparisons: cond1 vs cond11 p=%.2e, cond1 vs cond9 p=%.2e, cond11 vs cond9 p=%.2e\n', ...
    p_1vs11, p_1vs9, p_11vs9);

% --- Delta-AV slopes (stimulus minus baseline) ---
offset_delta_per_fly = offset_stim_per_fly - offset_base_per_fly(1:size(offset_stim_per_fly,1), :);
offset_delta_slopes = NaN(n_offset, 1);
for f = 1:n_offset
    d_bins = offset_delta_per_fly(f, :);
    v = ~isnan(d_bins);
    if sum(v) >= 3
        p = polyfit(bin_centres(v), d_bins(v), 1);
        offset_delta_slopes(f) = p(1);
    end
end
offset_delta_slopes_clean = offset_delta_slopes(~isnan(offset_delta_slopes));
[~, p_offset_delta] = ttest(offset_delta_slopes_clean, 0);
fprintf('  Cond %d delta slope:   mean = %.4f, p vs 0 = %.2e (n=%d)\n', ...
    OFFSET_COND, mean(offset_delta_slopes_clean), p_offset_delta, numel(offset_delta_slopes_clean));

flicker_delta_per_fly = flicker_stim_per_fly - flicker_base_per_fly(1:size(flicker_stim_per_fly,1), :);
flicker_delta_slopes = NaN(n_flicker, 1);
for f = 1:n_flicker
    d_bins = flicker_delta_per_fly(f, :);
    v = ~isnan(d_bins);
    if sum(v) >= 3
        p = polyfit(bin_centres(v), d_bins(v), 1);
        flicker_delta_slopes(f) = p(1);
    end
end
flicker_delta_slopes_clean = flicker_delta_slopes(~isnan(flicker_delta_slopes));
[~, p_flicker_delta] = ttest(flicker_delta_slopes_clean, 0);
fprintf('  Cond %d delta slope:   mean = %.4f, p vs 0 = %.2e (n=%d)\n', ...
    FLICKER_COND, mean(flicker_delta_slopes_clean), p_flicker_delta, numel(flicker_delta_slopes_clean));

% Delta slope comparisons
[~, p_delta_1vs11] = ttest2(delta_slopes_clean, offset_delta_slopes_clean);
[~, p_delta_1vs9]  = ttest2(delta_slopes_clean, flicker_delta_slopes_clean);
fprintf('  Delta slope comparisons: cond1 vs cond11 p=%.2e, cond1 vs cond9 p=%.2e\n', ...
    p_delta_1vs11, p_delta_1vs9);

% --- Figure 9 ---
cond1_col    = [0 0 0];           % black
cond11_col   = [1.000 0.498 0.000]; % orange
flicker_col  = [0.5 0.5 0.8];    % light blue-grey

fig9 = figure('Position', [100 200 1350 420]);
sgtitle('Centred vs Offset CoR vs Flicker — Control', 'FontSize', 18);

% Panel A: |AV| vs wall distance — three conditions overlaid
subplot(1, 3, 1);
hold on;

% Condition 1 (centred CoR)
valid_1 = ~isnan(stim_means);
bc_1 = bin_centres(valid_1);
patch([bc_1 fliplr(bc_1)], ...
    [stim_means(valid_1)+stim_sems(valid_1) fliplr(stim_means(valid_1)-stim_sems(valid_1))], ...
    cond1_col, 'FaceAlpha', 0.08, 'EdgeColor', 'none');
h1 = plot(bc_1, stim_means(valid_1), '-o', 'Color', cond1_col, ...
    'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', cond1_col);

% Condition 11 (offset CoR)
valid_11 = ~isnan(offset_stim_means);
bc_11 = bin_centres(valid_11);
patch([bc_11 fliplr(bc_11)], ...
    [offset_stim_means(valid_11)+offset_stim_sems(valid_11) ...
     fliplr(offset_stim_means(valid_11)-offset_stim_sems(valid_11))], ...
    cond11_col, 'FaceAlpha', 0.12, 'EdgeColor', 'none');
h2 = plot(bc_11, offset_stim_means(valid_11), '-o', 'Color', cond11_col, ...
    'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', cond11_col);

% Condition 9 (flicker)
valid_9 = ~isnan(flicker_stim_means);
bc_9 = bin_centres(valid_9);
patch([bc_9 fliplr(bc_9)], ...
    [flicker_stim_means(valid_9)+flicker_stim_sems(valid_9) ...
     fliplr(flicker_stim_means(valid_9)-flicker_stim_sems(valid_9))], ...
    flicker_col, 'FaceAlpha', 0.12, 'EdgeColor', 'none');
h3 = plot(bc_9, flicker_stim_means(valid_9), '-o', 'Color', flicker_col, ...
    'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', flicker_col);

% Linear fits
if sum(valid_1) >= 3
    p_fit1 = polyfit(bc_1, stim_means(valid_1), 1);
    x_fit = linspace(0, ARENA_R, 100);
    plot(x_fit, polyval(p_fit1, x_fit), '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 1);
end
if sum(valid_11) >= 3
    p_fit11 = polyfit(bc_11, offset_stim_means(valid_11), 1);
    plot(x_fit, polyval(p_fit11, x_fit), '-', 'Color', cond11_col * 0.7, 'LineWidth', 1);
end

% Mark CoR wall distance
xline(COR_WALL_DIST, '-', 'Color', cond11_col, 'LineWidth', 1.5, 'Alpha', 0.5);
yl = get(gca, 'YLim');
text(COR_WALL_DIST + 2, yl(2) * 0.95, 'CoR', ...
    'Color', cond11_col, 'FontSize', 10, 'FontWeight', 'bold', 'VerticalAlignment', 'top');

legend([h1 h2 h3], ...
    {sprintf('Centred (slope=%.2f)', p_fit1(1)), ...
     sprintf('Offset (slope=%.2f)', p_fit11(1)), ...
     'Flicker'}, ...
    'Location', 'best', 'FontSize', 9);
xlabel('Distance to wall (mm)', 'FontSize', 14);
ylabel('Mean |AV| (deg/s)', 'FontSize', 14);
title('A — |AV| vs wall distance (stimulus)', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Panel B: Per-fly slope boxcharts
subplot(1, 3, 2);
hold on;

% Condition 1
x_jit = 1 + 0.15 * randn(numel(ctrl_slopes_clean), 1);
scatter(x_jit, ctrl_slopes_clean, 15, cond1_col, 'filled', 'MarkerFaceAlpha', 0.3);
boxchart(ones(numel(ctrl_slopes_clean), 1), ctrl_slopes_clean, ...
    'BoxFaceColor', cond1_col, 'MarkerStyle', 'none', 'BoxWidth', 0.5);

% Condition 11
x_jit = 2 + 0.15 * randn(numel(offset_slopes_clean), 1);
scatter(x_jit, offset_slopes_clean, 15, cond11_col, 'filled', 'MarkerFaceAlpha', 0.3);
boxchart(2 * ones(numel(offset_slopes_clean), 1), offset_slopes_clean, ...
    'BoxFaceColor', cond11_col, 'MarkerStyle', 'none', 'BoxWidth', 0.5);

% Condition 9 (flicker)
x_jit = 3 + 0.15 * randn(numel(flicker_slopes_clean), 1);
scatter(x_jit, flicker_slopes_clean, 15, flicker_col, 'filled', 'MarkerFaceAlpha', 0.3);
boxchart(3 * ones(numel(flicker_slopes_clean), 1), flicker_slopes_clean, ...
    'BoxFaceColor', flicker_col, 'MarkerStyle', 'none', 'BoxWidth', 0.5);

yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xticks([1 2 3]);
xticklabels({'Centred', 'Offset', 'Flicker'});
ylabel('Slope: |AV| vs wall dist (deg/s per mm)', 'FontSize', 14);
title('B — Per-fly slopes', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Panel C: Delta-AV slope boxcharts (stimulus minus baseline)
subplot(1, 3, 3);
hold on;

% Condition 1 delta
x_jit = 1 + 0.15 * randn(numel(delta_slopes_clean), 1);
scatter(x_jit, delta_slopes_clean, 15, cond1_col, 'filled', 'MarkerFaceAlpha', 0.3);
boxchart(ones(numel(delta_slopes_clean), 1), delta_slopes_clean, ...
    'BoxFaceColor', cond1_col, 'MarkerStyle', 'none', 'BoxWidth', 0.5);

% Condition 11 delta
x_jit = 2 + 0.15 * randn(numel(offset_delta_slopes_clean), 1);
scatter(x_jit, offset_delta_slopes_clean, 15, cond11_col, 'filled', 'MarkerFaceAlpha', 0.3);
boxchart(2 * ones(numel(offset_delta_slopes_clean), 1), offset_delta_slopes_clean, ...
    'BoxFaceColor', cond11_col, 'MarkerStyle', 'none', 'BoxWidth', 0.5);

% Condition 9 delta
x_jit = 3 + 0.15 * randn(numel(flicker_delta_slopes_clean), 1);
scatter(x_jit, flicker_delta_slopes_clean, 15, flicker_col, 'filled', 'MarkerFaceAlpha', 0.3);
boxchart(3 * ones(numel(flicker_delta_slopes_clean), 1), flicker_delta_slopes_clean, ...
    'BoxFaceColor', flicker_col, 'MarkerStyle', 'none', 'BoxWidth', 0.5);

yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xticks([1 2 3]);
xticklabels({'Centred', 'Offset', 'Flicker'});
ylabel('\Delta slope (stim-base, deg/s per mm)', 'FontSize', 14);
title(sprintf('C — \\Delta slopes (1v11 p=%.1e)', p_delta_1vs11), 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

if save_figs
    exportgraphics(fig9, fullfile(save_folder, 'turning_rate_offset_cor.pdf'), ...
        'ContentType', 'vector');
    close(fig9);
end

fprintf('\n=== Done ===\n');
