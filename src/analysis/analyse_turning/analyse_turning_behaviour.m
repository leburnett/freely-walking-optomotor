%% ANALYSE_TURNING_BEHAVIOUR - Turning analysis for freely-walking flies
%
% Analyses turning behaviour during visual stimulus conditions using
% sliding-window metrics binned by wall distance and discrete 360-degree
% turning event detection.
%
% Currently configured for jfrc100_es_shibire_kir (control) flies during
% condition 1 of protocol 27 (60 deg gratings, 4Hz).
%
% SECTIONS:
%   1. Configuration and data loading
%   2. Sliding-window metrics vs wall distance (|AV|, |curv|, FV, tortuosity)
%   2b. Stimulus-driven delta (stim - baseline) vs wall distance
%   3. Sensitivity analysis (window width heatmaps)
%   4. Metric correlation matrix
%   5. 360-degree turning event detection (per-rep, split by stimulus half)
%
% FIGURES:
%   Fig 1: 2x2 metric vs wall distance (stimulus vs baseline)
%   Fig 2: 2x2 stimulus-driven delta (stim - base) vs wall distance
%   Fig 3: 2x2 window width sensitivity heatmaps
%   Fig 4: Metric correlation matrix (stimulus period)
%   Fig 5: 360-degree turning events summary (duration, direction, geometry)
%
% REQUIREMENTS:
%   - DATA struct from comb_data_across_cohorts_cond (Protocol 27)
%   - Processing functions: compute_sliding_window_metrics,
%     sensitivity_analysis_windows, detect_360_turning_events,
%     compute_turning_event_geometry, load_per_rep_data,
%     bin_metric_by_wall_distance
%   - Plotting functions: plot_metric_vs_wall_distance,
%     plot_sensitivity_heatmap, plot_turning_events_summary,
%     plot_metric_correlations
%
% See also: compute_sliding_window_metrics, detect_360_turning_events

%% 1 — Configuration and Data Loading

if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
    fprintf('Loaded DATA from %s\n', protocol_dir);
end

cfg = get_config();

% Arena geometry
PPM = 4.1691;                     % pixels per mm (from calibration)
ARENA_CENTER = [528, 520] / PPM;  % arena centre in mm [126.6, 124.7]
ARENA_R = 120;                    % arena radius in mm (dist_data = 120 - d_wall)
FPS = 30;

% Key strains and conditions
control_strain = "jfrc100_es_shibire_kir";
key_strains = {"ss324_t4t5_shibire_kir", "ss00297_Dm4_shibire_kir", ...
               "ss03722_Tm5Y_shibire_kir", "l1l4_jfrc100_shibire_kir"};
key_labels  = {"T4/T5", "Dm4", "Tm5Y", "L1/L4"};
key_condition = 1;  % 60 deg gratings 4Hz
sex = 'F';

% Stimulus timing (frames at 30 fps)
% 300 frames pre-stimulus included in data, then 30s stimulus (2 x 15s)
STIM_ON  = 300;   % frame 300 = stimulus onset
STIM_MID = 750;   % frame 750 = direction change (CW -> CCW)
STIM_OFF = 1200;  % frame 1200 = stimulus offset

% Pre-stimulus baseline
PRE_START = 1;
PRE_END   = 300;

% Distance-to-wall bins (mm from wall)
bin_edges = 0:10:ARENA_R;  % 0 = at wall, 120 = at centre
bin_centres = bin_edges(1:end-1) + diff(bin_edges) / 2;

% Colors
ctrl_col      = [0.4 0.4 0.4];
ctrl_col_fill = [0.85 0.85 0.85];
strain_cols = [0.216 0.494 0.722;   % blue   - T4/T5
               0.894 0.102 0.110;   % red    - Dm4
               0.302 0.686 0.290;   % green  - Tm5Y
               0.596 0.306 0.639];  % purple - L1/L4

% Figure save toggle
save_figs = 0;
save_folder = fullfile(cfg.figures, 'turning_analysis');
if save_figs && ~exist(save_folder, 'dir')
    mkdir(save_folder);
end

%% Load control data (averaged across reps for Approach A)
fprintf('\n=== Loading control data (condition %d) ===\n', key_condition);
data_ctrl = DATA.(control_strain).(sex);

av_ctrl   = combine_timeseries_across_exp_check(data_ctrl, key_condition, "av_data");
curv_ctrl = combine_timeseries_across_exp_check(data_ctrl, key_condition, "curv_data");
fv_ctrl   = combine_timeseries_across_exp_check(data_ctrl, key_condition, "fv_data");
dist_ctrl = combine_timeseries_across_exp_check(data_ctrl, key_condition, "dist_data");
x_ctrl    = combine_timeseries_across_exp_check(data_ctrl, key_condition, "x_data");
y_ctrl    = combine_timeseries_across_exp_check(data_ctrl, key_condition, "y_data");
head_ctrl = combine_timeseries_across_exp_check(data_ctrl, key_condition, "heading_data");

n_ctrl = size(av_ctrl, 1);
n_frames = size(av_ctrl, 2);
fprintf('  Control: %d flies, %d frames\n', n_ctrl, n_frames);

%% 2 — Approach A: Sliding-window metrics vs wall distance

fprintf('\n=== Approach A: Sliding-window metrics ===\n');

opts_sw.short_window = 0.5;  % seconds
opts_sw.long_window  = 2.0;  % seconds
metrics_ctrl = compute_sliding_window_metrics(av_ctrl, curv_ctrl, fv_ctrl, ...
    dist_ctrl, x_ctrl, y_ctrl, ARENA_R, FPS, opts_sw);

% Bin each metric by wall distance — stimulus period
stim_range = STIM_ON:STIM_OFF;
pre_range  = PRE_START:PRE_END;

[av_means_stim,   av_sems_stim]   = bin_metric_by_wall_distance(metrics_ctrl.abs_av,    metrics_ctrl.wall_dist, stim_range, bin_edges);
[curv_means_stim, curv_sems_stim] = bin_metric_by_wall_distance(metrics_ctrl.abs_curv,  metrics_ctrl.wall_dist, stim_range, bin_edges);
[fv_means_stim,   fv_sems_stim]   = bin_metric_by_wall_distance(metrics_ctrl.fwd_vel,   metrics_ctrl.wall_dist, stim_range, bin_edges);
[tort_means_stim, tort_sems_stim] = bin_metric_by_wall_distance(metrics_ctrl.tortuosity, metrics_ctrl.wall_dist, stim_range, bin_edges);

% Bin — baseline period
[av_means_pre,   av_sems_pre]   = bin_metric_by_wall_distance(metrics_ctrl.abs_av,    metrics_ctrl.wall_dist, pre_range, bin_edges);
[curv_means_pre, curv_sems_pre] = bin_metric_by_wall_distance(metrics_ctrl.abs_curv,  metrics_ctrl.wall_dist, pre_range, bin_edges);
[fv_means_pre,   fv_sems_pre]   = bin_metric_by_wall_distance(metrics_ctrl.fwd_vel,   metrics_ctrl.wall_dist, pre_range, bin_edges);
[tort_means_pre, tort_sems_pre] = bin_metric_by_wall_distance(metrics_ctrl.tortuosity, metrics_ctrl.wall_dist, pre_range, bin_edges);

% Figure: 2x2 metric vs wall distance (stimulus vs baseline)
fig_metrics = figure('Position', [50 50 1200 900]);
tl = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
sgtitle(tl, sprintf('Control — Condition %d (60° Gratings 4Hz)', key_condition), 'FontSize', 18);

metric_names = {'|Angular Velocity| (deg/s)', '|Curvature| (deg/mm)', ...
                'Forward Velocity (mm/s)', 'Tortuosity'};
stim_means = {av_means_stim, curv_means_stim, fv_means_stim, tort_means_stim};
stim_sems  = {av_sems_stim, curv_sems_stim, fv_sems_stim, tort_sems_stim};
pre_means  = {av_means_pre, curv_means_pre, fv_means_pre, tort_means_pre};
pre_sems   = {av_sems_pre, curv_sems_pre, fv_sems_pre, tort_sems_pre};

for p = 1:4
    ax = nexttile(tl);
    combined_means = [pre_means{p}; stim_means{p}];
    combined_sems  = [pre_sems{p}; stim_sems{p}];
    popts.colors = [0.7 0.7 0.7; 0 0 0];
    popts.labels = {'Baseline', 'Stimulus'};
    popts.ylabel_str = metric_names{p};
    popts.title_str = metric_names{p};
    popts.show_fit = true;
    popts.ax = ax;
    plot_metric_vs_wall_distance(bin_centres, combined_means, combined_sems, popts);
end

f = gcf;
f.Position = [206   287   761   662];

if save_figs
    exportgraphics(fig_metrics, fullfile(save_folder, 'metrics_vs_wall_distance.pdf'), 'ContentType', 'vector');
end

%% 2b — Stimulus-driven delta: (stimulus - baseline) vs wall distance
%
%  Subtracting the baseline (pre-stimulus) bin means from the stimulus bin
%  means isolates the stimulus-driven component of each metric. SEM of the
%  delta is propagated as sqrt(SEM_stim^2 + SEM_pre^2).

fig_delta = figure('Position', [50 50 1200 900]);
tl_d = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
sgtitle(tl_d, sprintf('Control — Condition %d — Stimulus-driven \\Delta (stim - base)', key_condition), 'FontSize', 18);

delta_labels = {'\Delta|AV| (stim - base, deg/s)', '\Delta|Curvature| (stim - base, deg/mm)', ...
                '\DeltaFwd Vel (stim - base, mm/s)', '\DeltaTortuosity (stim - base)'};

for p = 1:4
    delta_mean = stim_means{p} - pre_means{p};
    delta_sem  = sqrt(stim_sems{p}.^2 + pre_sems{p}.^2);

    dopts = struct();
    dopts.ylabel_str = delta_labels{p};
    dopts.title_str  = delta_labels{p};
    dopts.show_fit   = false;
    dopts.ax         = nexttile(tl_d);
    plot_metric_vs_wall_distance(bin_centres, delta_mean, delta_sem, dopts);

    % Zero reference line
    yline(dopts.ax, 0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
end

f = gcf;
f.Position = [206 287 761 662];

if save_figs
    exportgraphics(fig_delta, fullfile(save_folder, 'delta_metrics_vs_wall_distance.pdf'), 'ContentType', 'vector');
end

%% 3 — Sensitivity analysis

fprintf('\n=== Sensitivity analysis ===\n');

window_range = 0.1:0.1:3.0;
sens_results = sensitivity_analysis_windows(av_ctrl, curv_ctrl, fv_ctrl, ...
    dist_ctrl, x_ctrl, y_ctrl, ARENA_R, FPS, stim_range, bin_edges, window_range);

% Plot 4 heatmaps
fig_sens = figure('Position', [50 50 1200 900]);
tl_s = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
sgtitle(tl_s, 'Window Width Sensitivity — Control, Condition 1', 'FontSize', 18);

sens_metrics = {'av', 'curv', 'fv', 'tort'};
for p = 1:4
    sopts.ax = nexttile(tl_s);
    plot_sensitivity_heatmap(sens_results, sens_metrics{p}, sopts);
end

if save_figs
    exportgraphics(fig_sens, fullfile(save_folder, 'sensitivity_heatmaps.pdf'), 'ContentType', 'vector');
end

%% 4 — Metric correlations

fprintf('\n=== Metric correlation matrix ===\n');

corr_opts.title_str = 'Control — Metric Correlations (Stimulus Period)';
corr_opts.subsample = 10;
fig_corr = plot_metric_correlations(metrics_ctrl, stim_range, corr_opts);

if save_figs
    exportgraphics(fig_corr, fullfile(save_folder, 'metric_correlations.pdf'), 'ContentType', 'vector');
end

%% 5 — Approach B: 360-degree turning events (per-rep)

fprintf('\n=== Approach B: 360-degree turning events ===\n');

% Load per-rep data (not averaged) to preserve trajectory structure
data_types_b = {'heading_data', 'x_data', 'y_data', 'dist_data', 'av_data', 'fv_data', 'curv_data'};
[rep_data, n_flies_rep] = load_per_rep_data(DATA, control_strain, sex, key_condition, data_types_b);

% Split into first half (CW) and second half (CCW) at direction change
% STIM_MID is the direction change frame in the combined timeseries
heading_rep = rep_data.heading_data;
av_rep      = rep_data.av_data;
fv_rep      = rep_data.fv_data;
curv_rep    = rep_data.curv_data;
x_rep       = rep_data.x_data;
y_rep       = rep_data.y_data;
dist_rep    = rep_data.dist_data;

% Half 1: stimulus onset to direction change
h1_range = STIM_ON:STIM_MID;
% Half 2: direction change to stimulus offset
h2_range = STIM_MID:min(STIM_OFF, size(heading_rep, 2));

fprintf('  Half 1 frames: %d-%d (%d frames)\n', h1_range(1), h1_range(end), numel(h1_range));
fprintf('  Half 2 frames: %d-%d (%d frames)\n', h2_range(1), h2_range(end), numel(h2_range));

% Turning event detection options
event_opts.av_threshold    = 30;   % deg/s — only count active turning
event_opts.merge_gap       = 0;   % frames — merge briefly-interrupted bouts
event_opts.min_bout_frames = 1;    % frames — discard very short bouts
event_opts.heading_target  = 360;  % degrees — full turn criterion
event_opts.max_duration_s  = 6;    % seconds — discard long meandering events

fprintf('  AV threshold: %d deg/s, max duration: %.1fs\n', ...
    event_opts.av_threshold, event_opts.max_duration_s);

% Clear stale variables from previous runs (field sets may have changed)
clear events_h1 events_h2 geom_h1 geom_h2;

% Detect turning events in each half (now requires av_data)
events_h1 = detect_360_turning_events(heading_rep(:, h1_range), av_rep(:, h1_range), FPS, event_opts);
events_h2 = detect_360_turning_events(heading_rep(:, h2_range), av_rep(:, h2_range), FPS, event_opts);

% Compute geometry for each half
for f = 1:n_flies_rep
    geom_h1(f) = compute_turning_event_geometry(events_h1(f), ...
        x_rep(f, h1_range), y_rep(f, h1_range), ARENA_R, ARENA_CENTER);
    geom_h2(f) = compute_turning_event_geometry(events_h2(f), ...
        x_rep(f, h2_range), y_rep(f, h2_range), ARENA_R, ARENA_CENTER);
end

% Summary statistics
total_h1 = sum([events_h1.n_events]);
total_h2 = sum([events_h2.n_events]);
fprintf('  Half 1: %d events across %d flies\n', total_h1, sum([events_h1.n_events] > 0));
fprintf('  Half 2: %d events across %d flies\n', total_h2, sum([events_h2.n_events] > 0));

% Summary figure
summary_opts.title_str = sprintf('Control — Condition %d — 360° Turning Events', key_condition);
fig_events = plot_turning_events_summary(events_h1, geom_h1, events_h2, geom_h2, summary_opts);

if save_figs
    exportgraphics(fig_events, fullfile(save_folder, 'turning_events_summary.pdf'), 'ContentType', 'vector');
end

fprintf('\n=== Analysis complete ===\n');