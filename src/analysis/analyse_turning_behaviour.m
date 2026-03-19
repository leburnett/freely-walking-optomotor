%% ANALYSE_TURNING_BEHAVIOUR - Comprehensive turning analysis for freely-walking flies
%
% Analyses turning behaviour during visual stimulus conditions using two
% complementary approaches:
%   A — Sliding-window time series metrics vs distance from wall
%   B — Discrete 360-degree turning event detection and characterisation
%
% Currently configured for jfrc100_es_shibire_kir (control) flies during
% condition 1 of protocol 27 (60 deg gratings, 4Hz).
%
% SECTIONS:
%   1. Configuration and data loading
%   2. Approach A — Sliding-window metrics vs wall distance
%   3. Diagnostic trajectory plots (Approach A validation)
%   4. Sensitivity analysis
%   5. Metric correlation matrix
%   6. Approach B — 360-degree turning event detection
%   7. Diagnostic turning event plots (Approach B validation)
%   8. Multi-strain comparison stub
%
% REQUIREMENTS:
%   - DATA struct from comb_data_across_cohorts_cond (Protocol 27)
%   - Processing functions: compute_sliding_window_metrics, compute_tortuosity,
%     sensitivity_analysis_windows, detect_360_turning_events,
%     compute_turning_event_geometry, load_per_rep_data,
%     bin_metric_by_wall_distance
%   - Plotting functions: plot_metric_vs_wall_distance, plot_sensitivity_heatmap,
%     plot_turning_events_summary, plot_metric_correlations,
%     plot_trajectory_colormapped, plot_diagnostic_single_fly,
%     plot_turning_event_trajectories
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

%% 3 — Diagnostic trajectory plots (Approach A validation)

fprintf('\n=== Diagnostic: trajectory colormaps ===\n');

% Pick example flies: fly 1, median-activity fly, max-activity fly
mean_av_per_fly = nanmean(abs(av_ctrl(:, stim_range)), 2);
[~, idx_median] = min(abs(mean_av_per_fly - nanmedian(mean_av_per_fly)));
[~, idx_max]    = max(mean_av_per_fly);
example_flies = [1, idx_median, idx_max];
fly_labels = {'Fly 1', sprintf('Fly %d (median AV)', idx_median), ...
              sprintf('Fly %d (max AV)', idx_max)};

for fi = 1:numel(example_flies)
    f = example_flies(fi);

    % Single-fly metrics (extract row)
    fly_metrics.abs_av    = metrics_ctrl.abs_av(f, :);
    fly_metrics.abs_curv  = metrics_ctrl.abs_curv(f, :);
    fly_metrics.fwd_vel   = metrics_ctrl.fwd_vel(f, :);
    fly_metrics.tortuosity = metrics_ctrl.tortuosity(f, :);
    fly_metrics.wall_dist = metrics_ctrl.wall_dist(f, :);

    % Create empty events/geom for diagnostic plot (Approach B not yet run on averaged data)
    empty_events.start_frame = [];
    empty_events.end_frame = [];
    empty_events.direction = [];
    empty_events.duration_s = [];
    empty_events.n_events = 0;

    empty_geom.bbox_area = [];
    empty_geom.bbox_aspect = [];
    empty_geom.bbox_center_x = [];
    empty_geom.bbox_center_y = [];

    diag_opts.fly_id = fly_labels{fi};
    diag_opts.stim_on = STIM_ON;
    diag_opts.stim_off = STIM_OFF;
    diag_opts.arena_radius = ARENA_R;
    diag_opts.arena_center = ARENA_CENTER;
    diag_opts.fps = FPS;
    diag_opts.raw_av = abs(av_ctrl(f, :));
    diag_opts.raw_fv = fv_ctrl(f, :);

    fig_diag = plot_diagnostic_single_fly(x_ctrl(f,:), y_ctrl(f,:), ...
        fly_metrics, head_ctrl(f,:), empty_events, empty_geom, diag_opts);

    if save_figs
        exportgraphics(fig_diag, fullfile(save_folder, ...
            sprintf('diagnostic_fly%d.pdf', f)), 'ContentType', 'vector');
    end

    % Multi-window tortuosity timeseries for this fly
    tort_mw_opts.windows = [0.5, 1, 2, 3];
    tort_mw_opts.stim_on = STIM_ON;
    tort_mw_opts.stim_off = STIM_OFF;
    tort_mw_opts.title_str = sprintf('Tortuosity — %s — Multiple Windows', fly_labels{fi});
    % fig_tort_mw = plot_tortuosity_multiwindow(x_ctrl(f,:), y_ctrl(f,:), FPS, tort_mw_opts);

    if save_figs
        exportgraphics(fig_tort_mw, fullfile(save_folder, ...
            sprintf('tortuosity_multiwindow_fly%d.pdf', f)), 'ContentType', 'vector');
    end
end

%% 4 — Sensitivity analysis

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

%% 5 — Metric correlations

fprintf('\n=== Metric correlation matrix ===\n');

corr_opts.title_str = 'Control — Metric Correlations (Stimulus Period)';
corr_opts.subsample = 10;
fig_corr = plot_metric_correlations(metrics_ctrl, stim_range, corr_opts);

if save_figs
    exportgraphics(fig_corr, fullfile(save_folder, 'metric_correlations.pdf'), 'ContentType', 'vector');
end

%% 6 — Approach B: 360-degree turning events (per-rep)

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

%% 7 — Diagnostic turning event plots (Approach B validation)

fprintf('\n=== Diagnostic: turning event trajectories ===\n');

% Find flies with detected events for diagnostics
flies_with_events_h1 = find([events_h1.n_events] > 0);
n_diag = min(3, numel(flies_with_events_h1));

for di = 1:n_diag
    f = flies_with_events_h1(di);

    % Compute proper sliding-window metrics for this fly using actual data
    fly_met_diag = compute_sliding_window_metrics( ...
        av_rep(f,:), curv_rep(f,:), fv_rep(f,:), ...
        dist_rep(f,:), x_rep(f,:), y_rep(f,:), ARENA_R, FPS, opts_sw);

    % Combine events from both halves for diagnostic display
    % Offset half-2 frame indices to full-timeseries coordinates
    combined_events.start_frame  = [events_h1(f).start_frame + h1_range(1) - 1, ...
                                    events_h2(f).start_frame + h2_range(1) - 1];
    combined_events.end_frame    = [events_h1(f).end_frame + h1_range(1) - 1, ...
                                    events_h2(f).end_frame + h2_range(1) - 1];
    combined_events.direction    = [events_h1(f).direction, events_h2(f).direction];
    combined_events.duration_s   = [events_h1(f).duration_s, events_h2(f).duration_s];
    combined_events.n_events     = events_h1(f).n_events + events_h2(f).n_events;
    combined_events.peak_av      = [events_h1(f).peak_av, events_h2(f).peak_av];
    combined_events.mean_av      = [events_h1(f).mean_av, events_h2(f).mean_av];
    combined_events.cum_heading  = [events_h1(f).cum_heading, events_h2(f).cum_heading];
    combined_events.av_threshold = event_opts.av_threshold;

    combined_geom.bbox_area        = [geom_h1(f).bbox_area, geom_h2(f).bbox_area];
    combined_geom.bbox_aspect      = [geom_h1(f).bbox_aspect, geom_h2(f).bbox_aspect];
    combined_geom.bbox_center_x    = [geom_h1(f).bbox_center_x, geom_h2(f).bbox_center_x];
    combined_geom.bbox_center_y    = [geom_h1(f).bbox_center_y, geom_h2(f).bbox_center_y];
    combined_geom.wall_dist_center = [geom_h1(f).wall_dist_center, geom_h2(f).wall_dist_center];
    combined_geom.path_length      = [geom_h1(f).path_length, geom_h2(f).path_length];

    diag_opts_b = struct();  % clear from previous iteration
    diag_opts_b.fly_id = sprintf('Rep-fly %d (%d events)', f, combined_events.n_events);
    diag_opts_b.stim_on = STIM_ON;
    diag_opts_b.stim_off = STIM_OFF;
    diag_opts_b.arena_radius = ARENA_R;
    diag_opts_b.arena_center = ARENA_CENTER;
    diag_opts_b.fps = FPS;
    diag_opts_b.raw_av = abs(av_rep(f,:));
    diag_opts_b.raw_fv = fv_rep(f,:);

    fig_diag_b = plot_diagnostic_single_fly(x_rep(f,:), y_rep(f,:), ...
        fly_met_diag, heading_rep(f,:), combined_events, combined_geom, diag_opts_b);

    if save_figs
        exportgraphics(fig_diag_b, fullfile(save_folder, ...
            sprintf('diagnostic_events_fly%d.pdf', f)), 'ContentType', 'vector');
    end

    % % Individual event small multiples (half 1 only for clarity)
    % if events_h1(f).n_events > 0
    %     evt_opts.arena_radius = ARENA_R;
    %     evt_opts.fps = FPS;
    %     fig_evt = plot_turning_event_trajectories(events_h1(f), geom_h1(f), ...
    %         x_rep(f, h1_range), y_rep(f, h1_range), evt_opts);
    % 
    %     if save_figs
    %         exportgraphics(fig_evt, fullfile(save_folder, ...
    %             sprintf('event_trajectories_fly%d_h1.pdf', f)), 'ContentType', 'vector');
    %     end
    % 
    % end
end

%% 8 — Multi-strain comparison stub

fprintf('\n=== Multi-strain comparison (stub) ===\n');
fprintf('To add strains, populate key_strains and re-run this section.\n');
fprintf('Currently configured strains:\n');
for s = 1:numel(key_strains)
    fprintf('  %s (%s)\n', key_strains{s}, key_labels{s});
end

% Uncomment and extend below to run multi-strain comparison:
%{
fig_multi = figure('Position', [50 50 1200 900]);
tl_m = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
sgtitle(tl_m, 'Cross-Strain Comparison — Condition 1', 'FontSize', 18);

metric_fields = {'abs_av', 'abs_curv', 'fwd_vel', 'tortuosity'};

for p = 1:4
    ax_m = nexttile(tl_m);
    hold(ax_m, 'on');

    % Control (grey)
    all_means = ctrl_means{p};  % from Section 2
    all_sems  = ctrl_sems{p};
    all_labels = {'Control'};
    all_colors = [0.7 0.7 0.7];

    % Loop over strains
    for s = 1:numel(key_strains)
        strain_name = key_strains{s};
        if ~isfield(DATA, strain_name), continue; end

        data_s = DATA.(strain_name).(sex);
        av_s   = combine_timeseries_across_exp_check(data_s, key_condition, "av_data");
        curv_s = combine_timeseries_across_exp_check(data_s, key_condition, "curv_data");
        fv_s   = combine_timeseries_across_exp_check(data_s, key_condition, "fv_data");
        dist_s = combine_timeseries_across_exp_check(data_s, key_condition, "dist_data");
        x_s    = combine_timeseries_across_exp_check(data_s, key_condition, "x_data");
        y_s    = combine_timeseries_across_exp_check(data_s, key_condition, "y_data");

        metrics_s = compute_sliding_window_metrics(av_s, curv_s, fv_s, ...
            dist_s, x_s, y_s, ARENA_R, FPS, opts_sw);

        [s_means, s_sems] = bin_metric_by_wall_distance( ...
            metrics_s.(metric_fields{p}), metrics_s.wall_dist, stim_range, bin_edges);

        all_means = [all_means; s_means];
        all_sems  = [all_sems; s_sems];
        all_labels{end+1} = key_labels{s};
        all_colors = [all_colors; strain_cols(s,:)];
    end

    mopts.colors = all_colors;
    mopts.labels = all_labels;
    mopts.ylabel_str = metric_names{p};
    mopts.title_str = metric_names{p};
    mopts.ax = ax_m;
    plot_metric_vs_wall_distance(bin_centres, all_means, all_sems, mopts);
end
%}

fprintf('\n=== Analysis complete ===\n');
