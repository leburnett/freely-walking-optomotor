%% fig4 — Screen summary: heatmap, violins, time series, scatter
%
% Generates figures for the main screen results (condition 1):
%   1. P-value heatmap (strains x 6 metrics) + colour bar
%   2. Six violin plots (one per heatmap metric column)
%   3. Six ES control time series (2x3 grid) with shaded metric windows
%   4. Centring vs turning scatter (one marker per strain)
%
% REQUIREMENTS:
%   - Protocol 27 data via comb_data_across_cohorts_cond
%   - strain_names2.mat in results folder
%   - Functions: make_summary_heat_maps_p27, plot_colour_bar_for_summary_plot,
%     plot_violin_metrics_xstrains, plot_violin, plot_xcond_per_strain2,
%     combine_timeseries_across_exp_check, combine_timeseries_across_exp
%
% See also: cross_strain_condition_heatmaps, figS1

%% 1 — Configuration & data loading

cfg = get_config();
protocol_dir = fullfile(cfg.results, 'protocol_27');

if ~exist('DATA', 'var') || isempty(fieldnames(DATA))
    fprintf('Loading Protocol 27 data from: %s\n', protocol_dir);
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

save_figs = false;
save_folder = fullfile(cfg.figures, 'FIGS');

%% 2 — Strain ordering & colours

control_strain = 'jfrc100_es_shibire_kir';
sex = 'F';
cond_idx = 1;  % condition 1: 60deg gratings 4Hz

% strain_ids: 1:16 = experimental, 17 = ES control (matches strain_names2.mat)
strain_ids = 1:17;

% Strain colours (from cmap_config)
cmaps = cmap_config();
strain_colours = cmaps.strains.colors;

% Load strain names for labelling
strain_names_s = load(fullfile(cfg.results, 'strain_names2.mat'));
strain_names_list = strain_names_s.strain_names;
strain_names_list{end+1} = 'jfrc100_es_shibire_kir';
strain_names_list{end+1} = 'csw1118';

%% 3 — Heatmap + colour bar

make_summary_heat_maps_p27(DATA);

plot_colour_bar_for_summary_plot();
f = gcf; f.Position = [118   901   749    34];

%% 4 — Violin plots (6 figures, one per heatmap metric column)

% --- Hard-coded y-limits for each violin plot ---
% Edit these values to ensure median text labels are visible.
% Format: [ymin, ymax] or [] to use auto-limits.
violin_ylims = { ...
    [-10 38];      % Metric 1: Avg FV during stimulus
    [-35 35];    % Metric 2: FV change at onset
    [-75 310];   % Metric 3: Avg turning during stimulus
    [-300 750];   % Metric 4: Early turning (first 5s CW)
    [-150 160];   % Metric 5: Centring at end of stimulus
    [-110 170];   % Metric 6: Centring after 10s
};

% Metric 1: Avg FV during stimulus (frames 300:1200)
plot_violin_metrics_xstrains(DATA, strain_ids, cond_idx, "fv_data", 300:1200, 0);
% title('Metric 1: Avg FV during stimulus', 'FontSize', 14);
hold on; yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5); hold off;
if ~isempty(violin_ylims{1}); ylim(violin_ylims{1}); end
f = gcf; f.Position = [376   335   937   410];

% Metric 3: Avg turning rate during stimulus (frames 300:1200)
plot_violin_metrics_xstrains(DATA, strain_ids, cond_idx, "curv_data", 300:1200, 0);
% title('Metric 3: Avg turning during stimulus', 'FontSize', 14);
hold on; yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5); hold off;
if ~isempty(violin_ylims{3}); ylim(violin_ylims{3}); end
f = gcf; f.Position = [376   335   937   410];

% Metric 5: Relative distance at end of stimulus (frames 1170:1200, delta=1)
plot_violin_metrics_xstrains(DATA, strain_ids, cond_idx, "dist_data", 1170:1200, 1);
hold on; yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5); hold off;
% title('Metric 5: Centring at end of stimulus', 'FontSize', 14);
if ~isempty(violin_ylims{5}); ylim(violin_ylims{5}); end
f = gcf; f.Position = [376   335   937   410];


%% 5 — Time series plots (separate figures, key strains vs control)
%
%  Plots time series for condition 1 comparing H1, Dm4, T4T5 against ES
%  control. Uses plot_xstrain_per_cond which colours each strain by the
%  strain palette. Each metric gets its own figure.

% Strain indices into strain_names2.mat order:
%   H1 = 12 (ss26283_H1), Dm4 = 7 (ss00297_Dm4), L1L4 = 1 , ES = 17

ts_params.save_figs    = 0;
ts_params.plot_sem     = 0;
ts_params.plot_sd      = 0;
ts_params.plot_individ = 0;
ts_params.shaded_areas = 1;

metric_ts = { ...
    "fv_data",          'FV: full stimulus', [1,7, 17]; ...
    "curv_data",        'Turning: full stimulus', [1, 12, 17]; ...
    "dist_data_delta",  'Centring: end of stim', [1, 12, 7, 17]; ...
};

for sp = 1:size(metric_ts, 1)
    figure;
    plot_xstrain_per_cond('protocol_27', metric_ts{sp, 1}, 1, metric_ts{sp, 3}, ts_params, DATA);
    % title(metric_ts{sp, 2}, 'FontSize', 14);
    set(gca, 'TickDir', 'out', 'Box', 'off');
    f = gcf; f.Position = [338   440   672   396];
end

%% 6 — Centring vs turning scatter (one marker per strain)

% Define x-axis metric: turning rate during stimulus
x_met.data_type = "av_data";
x_met.frames    = 300:1200;
x_met.delta     = 0;
x_met.flip_ccw  = true;
x_met.label     = 'Mean angular velocity during stimulus (deg/s)';

% Define y-axis metric: centring at end of stimulus
y_met.data_type = "dist_data";
y_met.frames    = 1170:1200;
y_met.delta     = 1;
y_met.flip_ccw  = false;
y_met.label     = 'Centring at end of stimulus (mm)';

scatter_opts.title_str = sprintf('Centring vs Turning — Condition %d', cond_idx);
fig_scatter = plot_strain_scatter(DATA, strain_ids, cond_idx, x_met, y_met, scatter_opts);
fig_scatter.Position = [50 50 305 269];

if save_figs
    if ~isfolder(save_folder); mkdir(save_folder); end
    exportgraphics(fig_scatter, fullfile(save_folder, 'fig4_centring_vs_turning.pdf'), ...
        'ContentType', 'vector');
end


cond_idx = 2;
scatter_opts.title_str = sprintf('Centring vs Turning — Condition %d', cond_idx);
fig_scatter = plot_strain_scatter(DATA, strain_ids, cond_idx, x_met, y_met, scatter_opts);
fig_scatter.Position = [50 50 305 269];