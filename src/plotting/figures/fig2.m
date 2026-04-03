%% Figure 2 - Relationship between turning and centring with position within the arena.
% Specifically the radial distance of the fly.
% Just using control flies and condition 1

%% ================================================================
%  SECTION 1: Setup
%  ================================================================

cfg = get_config();
ROOT_DIR = cfg.project_root;

if ~exist('DATA', 'var')
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

%% Fixed parameters. 
protocol = "protocol_27";
data_types =  {'fv_data', 'av_data', 'curv_data', 'dist_data', 'dist_data_delta'};

params.save_figs = 0;
params.plot_sem = 1;
params.plot_sd = 0;
params.plot_individ = 0;
params.shaded_areas = 0;

%% These plots compare control flies' behaviour to moving and static gratings
cond_ids = [10, 1]; % 60 deg gratings (condition 1) and 60 deg flicker (condition 10).

%% ================================================================
%  SECTION 2: Timeseries - metrics versus distance from the centre.
%  ================================================================

ARENA_R = 120;
FPS = 30;

control_strain = "jfrc100_es_shibire_kir";
key_condition = 1;
sex = 'F';

STIM_ON  = 300;
STIM_OFF = 1200;
PRE_START = 1250; % use 15s within interval as baseline.
PRE_END   = 1700;

bin_edges = 0:10:ARENA_R;
bin_centres = bin_edges(1:end-1) + diff(bin_edges) / 2;

%% Load control data
data_ctrl = DATA.(control_strain).(sex);
av_ctrl   = combine_timeseries_across_exp_check(data_ctrl, key_condition, "av_data");
curv_ctrl = combine_timeseries_across_exp_check(data_ctrl, key_condition, "curv_data");
fv_ctrl   = combine_timeseries_across_exp_check(data_ctrl, key_condition, "fv_data");
dist_ctrl = combine_timeseries_across_exp_check(data_ctrl, key_condition, "dist_data");
x_ctrl    = combine_timeseries_across_exp_check(data_ctrl, key_condition, "x_data");
y_ctrl    = combine_timeseries_across_exp_check(data_ctrl, key_condition, "y_data");

%% Compute sliding-window metrics
opts_sw.short_window = 0.5;
opts_sw.long_window  = 1.6;
metrics_ctrl = compute_sliding_window_metrics(av_ctrl, curv_ctrl, fv_ctrl, ...
    dist_ctrl, x_ctrl, y_ctrl, ARENA_R, FPS, opts_sw);

stim_range = STIM_ON:STIM_OFF;
pre_range  = PRE_START:PRE_END;

%% Bin by distance from centre
[av_means_stim,   av_sems_stim]   = bin_metric_by_wall_distance(metrics_ctrl.abs_av,     metrics_ctrl.centre_dist, stim_range, bin_edges);
[curv_means_stim, curv_sems_stim] = bin_metric_by_wall_distance(metrics_ctrl.abs_curv,   metrics_ctrl.centre_dist, stim_range, bin_edges);
[fv_means_stim,   fv_sems_stim]   = bin_metric_by_wall_distance(metrics_ctrl.fwd_vel,    metrics_ctrl.centre_dist, stim_range, bin_edges);
[tort_means_stim, tort_sems_stim] = bin_metric_by_wall_distance(metrics_ctrl.tortuosity, metrics_ctrl.centre_dist, stim_range, bin_edges);

[av_means_pre,   av_sems_pre]   = bin_metric_by_wall_distance(metrics_ctrl.abs_av,     metrics_ctrl.centre_dist, pre_range, bin_edges);
[curv_means_pre, curv_sems_pre] = bin_metric_by_wall_distance(metrics_ctrl.abs_curv,   metrics_ctrl.centre_dist, pre_range, bin_edges);
[fv_means_pre,   fv_sems_pre]   = bin_metric_by_wall_distance(metrics_ctrl.fwd_vel,    metrics_ctrl.centre_dist, pre_range, bin_edges);
[tort_means_pre, tort_sems_pre] = bin_metric_by_wall_distance(metrics_ctrl.tortuosity, metrics_ctrl.centre_dist, pre_range, bin_edges);

%% Plot each metric as a separate figure
metric_names = {'|Angular Velocity| (deg/s)', '|Curvature| (deg/mm)', ...
                'Forward Velocity (mm/s)', 'Tortuosity'};
stim_means = {av_means_stim, curv_means_stim, fv_means_stim, tort_means_stim};
stim_sems  = {av_sems_stim,  curv_sems_stim,  fv_sems_stim,  tort_sems_stim};
pre_means  = {av_means_pre,  curv_means_pre,  fv_means_pre,  tort_means_pre};
pre_sems   = {av_sems_pre,   curv_sems_pre,   fv_sems_pre,   tort_sems_pre};

for p = 1:4
    plot_metric_vs_centre_distance(bin_centres, ...
        stim_means{p}, stim_sems{p}, pre_means{p}, pre_sems{p}, metric_names{p});
end




%% ================================================================
%  SECTION 3: Timeseries - versus viewing distance?? 
%  ================================================================

%% Load control data
data_ctrl = DATA.(control_strain).(sex);
av_ctrl   = combine_timeseries_across_exp_check(data_ctrl, key_condition, "av_data");
curv_ctrl = combine_timeseries_across_exp_check(data_ctrl, key_condition, "curv_data");
fv_ctrl   = combine_timeseries_across_exp_check(data_ctrl, key_condition, "fv_data");
dist_ctrl = combine_timeseries_across_exp_check(data_ctrl, key_condition, "dist_data");
vd_ctrl   = combine_timeseries_across_exp_check(data_ctrl, key_condition, "view_dist");
x_ctrl    = combine_timeseries_across_exp_check(data_ctrl, key_condition, "x_data");
y_ctrl    = combine_timeseries_across_exp_check(data_ctrl, key_condition, "y_data");

%% Compute sliding-window metrics
opts_sw.short_window = 0.5;
opts_sw.long_window  = 1.6;
metrics_ctrl = compute_sliding_window_metrics(av_ctrl, curv_ctrl, fv_ctrl, ...
    dist_ctrl, x_ctrl, y_ctrl, ARENA_R, FPS, opts_sw);

stim_range = STIM_ON:STIM_OFF;
pre_range  = PRE_START:PRE_END;

%% Bin by viewing distance
% view_dist ranges from ~0 to ~240 mm (diameter); use 10 mm bins
vd_bin_edges = 0:10:240;
vd_bin_centres = vd_bin_edges(1:end-1) + diff(vd_bin_edges) / 2;

[av_means_stim,   av_sems_stim]   = bin_metric_by_wall_distance(metrics_ctrl.abs_av,     vd_ctrl, stim_range, vd_bin_edges);
[curv_means_stim, curv_sems_stim] = bin_metric_by_wall_distance(metrics_ctrl.abs_curv,   vd_ctrl, stim_range, vd_bin_edges);
[fv_means_stim,   fv_sems_stim]   = bin_metric_by_wall_distance(metrics_ctrl.fwd_vel,    vd_ctrl, stim_range, vd_bin_edges);
[tort_means_stim, tort_sems_stim] = bin_metric_by_wall_distance(metrics_ctrl.tortuosity, vd_ctrl, stim_range, vd_bin_edges);

[av_means_pre,   av_sems_pre]   = bin_metric_by_wall_distance(metrics_ctrl.abs_av,     vd_ctrl, pre_range, vd_bin_edges);
[curv_means_pre, curv_sems_pre] = bin_metric_by_wall_distance(metrics_ctrl.abs_curv,   vd_ctrl, pre_range, vd_bin_edges);
[fv_means_pre,   fv_sems_pre]   = bin_metric_by_wall_distance(metrics_ctrl.fwd_vel,    vd_ctrl, pre_range, vd_bin_edges);
[tort_means_pre, tort_sems_pre] = bin_metric_by_wall_distance(metrics_ctrl.tortuosity, vd_ctrl, pre_range, vd_bin_edges);

%% Plot each metric as a separate figure
metric_names = {'|Angular Velocity| (deg/s)', '|Curvature| (deg/mm)', ...
                'Forward Velocity (mm/s)', 'Tortuosity'};
stim_means = {av_means_stim, curv_means_stim, fv_means_stim, tort_means_stim};
stim_sems  = {av_sems_stim,  curv_sems_stim,  fv_sems_stim,  tort_sems_stim};
pre_means  = {av_means_pre,  curv_means_pre,  fv_means_pre,  tort_means_pre};
pre_sems   = {av_sems_pre,   curv_sems_pre,   fv_sems_pre,   tort_sems_pre};

for p = 1:4
    plot_metric_vs_viewing_distance(vd_bin_centres, ...
        stim_means{p}, stim_sems{p}, pre_means{p}, pre_sems{p}, metric_names{p});
end

