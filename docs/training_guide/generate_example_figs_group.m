% generate_example_figs_group.m
% Generate group-level example figures for the training guide.
%
% Loads all processed cohorts for protocol_27 and protocol_31 and saves
% figures demonstrating the across-cohorts analysis pipeline. Slow to run
% (~5-10 minutes due to comb_data_across_cohorts_cond).
%
% Output figures (saved to docs/training_guide/example_figs/):
%
%   Protocol 27 — strain vs empty-split:
%     ex_strain_vs_ES_fv.png
%     ex_strain_vs_ES_av.png
%     ex_pvalue_heatmap.png
%
%   Protocol 27 — cross-condition and cross-strain:
%     ex_xcond_timeseries.png
%     ex_xcond_boxchart.png
%     ex_occupancy_heatmap.png
%     ex_xstrain_timeseries.png
%     ex_xstrain_boxchart.png
%
%   Protocol 27 — trajectories:
%     ex_trajectory_subplot.png
%     ex_trajectory_xcond.png
%     ex_trajectory_xflies.png
%     ex_trajectory_prepost.png
%
%   Protocol 31 — speed comparisons:
%     ex_speed_comparison_timeseries.png
%     ex_speed_comparison_boxchart.png
%
% See also: generate_example_figs_single_exp.m (single-cohort figures, fast)

%% Setup
REPO_ROOT = fileparts(fileparts(fileparts(mfilename('fullpath'))));  % training_guide -> docs -> repo root
run(fullfile(REPO_ROOT, 'setup_path.m'));
cfg = get_config();
PROJECT_ROOT = cfg.project_root;
SAVE_DIR = fullfile(REPO_ROOT, 'docs', 'training_guide', 'example_figs');

if ~isfolder(SAVE_DIR)
    mkdir(SAVE_DIR);
end

% Shared parameters
ES_STRAIN     = 'jfrc100_es_shibire_kir';
TARGET_STRAIN = 'l1l4_jfrc100_shibire_kir';
SEX           = 'F';

COND_TITLES_27 = {"60deg-gratings-4Hz", "60deg-gratings-8Hz", ...
    "narrow-ON-bars-4Hz", "narrow-OFF-bars-4Hz", ...
    "ON-curtains-8Hz", "OFF-curtains-8Hz", ...
    "reverse-phi-2Hz", "reverse-phi-4Hz", ...
    "60deg-flicker-4Hz", "60deg-gratings-static", ...
    "60deg-gratings-0-8-offset", "32px-ON-single-bar"};

% Strain indices in strain_names2.mat (ES=17, Pm2ab=8, T4T5=3)
XSTRAIN_IDS = [17, 8, 3];

% Arena centre coordinates (pixels) for trajectory plots
ARENA_CX = 122.8079;
ARENA_CY = 124.7267;

% Condition colours (12 conditions)
COL_12 = [31 120 180; 31 120 180; 178 223 138; 47 141 41; ...
          251 154 153; 227 26 28; 253 191 111; 255 127 0; ...
          166 206 227; 200 200 200; 255 224 41; 187 75 12] ./ 255;

COND_LABELS = {'4Hz', '8Hz', '4Hz-narrow-ON', '4Hz-narrow-OFF', ...
    'ON-Edge', 'OFF-Edge', 'RevPhi-4Hz', 'RevPhi-8Hz', ...
    '4Hz-Flicker', 'Static', '4Hz-offset', 'Phototaxis'};

% =========================================================================
%  PROTOCOL 27: Load data (used for all p27 figures below)
% =========================================================================
disp('=== Loading protocol_27 data (this may take a few minutes) ===')
protocol_dir_27 = fullfile(PROJECT_ROOT, 'results', 'protocol_27');
DATA_27 = comb_data_across_cohorts_cond(protocol_dir_27);
disp('Protocol 27 data loaded.')

% =========================================================================
%  PROTOCOL 27: Strain vs empty-split
% =========================================================================
disp('=== Strain vs empty-split figures ===')

gp_data = {
    ES_STRAIN,     SEX, [0.7 0.7 0.7];      % light grey (control)
    TARGET_STRAIN, SEX, [0.52, 0.12, 0.57]; % purple (target)
    };
gps2plot = [1, 2];
plot_sem  = 1;

if ~isfile(fullfile(SAVE_DIR, 'ex_strain_vs_ES_fv.png'))
    disp('Generating strain vs ES (forward velocity)...')
    f = plot_allcond_acrossgroups_tuning(DATA_27, gp_data, COND_TITLES_27, 'fv_data', gps2plot, plot_sem);
    exportgraphics(f, fullfile(SAVE_DIR, 'ex_strain_vs_ES_fv.png'), 'Resolution', 300);
    close(f)
else
    disp('Skipping ex_strain_vs_ES_fv.png (already exists)')
end

if ~isfile(fullfile(SAVE_DIR, 'ex_strain_vs_ES_av.png'))
    disp('Generating strain vs ES (angular velocity)...')
    f = plot_allcond_acrossgroups_tuning(DATA_27, gp_data, COND_TITLES_27, 'av_data', gps2plot, plot_sem);
    exportgraphics(f, fullfile(SAVE_DIR, 'ex_strain_vs_ES_av.png'), 'Resolution', 300);
    close(f)
else
    disp('Skipping ex_strain_vs_ES_av.png (already exists)')
end

if ~isfile(fullfile(SAVE_DIR, 'ex_pvalue_heatmap.png'))
    disp('Generating p-value heatmap...')
    DATA_27 = make_summary_heat_maps_p27(DATA_27);
    f = gcf;
    exportgraphics(f, fullfile(SAVE_DIR, 'ex_pvalue_heatmap.png'), 'Resolution', 300);
    close(f)
else
    disp('Skipping ex_pvalue_heatmap.png (already exists)')
end

% =========================================================================
%  PROTOCOL 27: Cross-condition analysis
% =========================================================================
disp('=== Cross-condition figures (protocol_27) ===')

ts_params.save_figs   = 0;
ts_params.plot_sem    = 1;
ts_params.plot_sd     = 0;
ts_params.plot_individ = 0;
ts_params.shaded_areas = 0;

if ~isfile(fullfile(SAVE_DIR, 'ex_xcond_timeseries.png'))
    disp('Generating cross-condition timeseries...')
    try
        figure('Visible', 'off');
        plot_xcond_per_strain2('protocol_27', "av_data", [1,7], ES_STRAIN, ts_params, DATA_27)
        f = gcf; f.Position = [181 611 641 340];
        exportgraphics(f, fullfile(SAVE_DIR, 'ex_xcond_timeseries.png'), 'Resolution', 300);
        close(f)
    catch ME
        disp(['Error: ' ME.message])
    end
else
    disp('Skipping ex_xcond_timeseries.png (already exists)')
end

if ~isfile(fullfile(SAVE_DIR, 'ex_xcond_boxchart.png'))
    disp('Generating cross-condition boxchart...')
    try
        figure('Visible', 'off');
        plot_boxchart_metrics_xcond(DATA_27, [1,7], ES_STRAIN, "av_data", 300:1200, 0)
        f = gcf; f.Position = [100 500 400 350];
        exportgraphics(f, fullfile(SAVE_DIR, 'ex_xcond_boxchart.png'), 'Resolution', 300);
        close(f)
    catch ME
        disp(['Error: ' ME.message])
    end
else
    disp('Skipping ex_xcond_boxchart.png (already exists)')
end

if ~isfile(fullfile(SAVE_DIR, 'ex_occupancy_heatmap.png'))
    disp('Generating occupancy heatmap...')
    try
        data = DATA_27.(ES_STRAIN).(SEX);
        f = plot_fly_occupancy_heatmaps_all(data);
        f.Position = [27 622 1774 425];
        exportgraphics(f, fullfile(SAVE_DIR, 'ex_occupancy_heatmap.png'), 'Resolution', 300);
        close(f)
    catch ME
        disp(['Error: ' ME.message])
    end
else
    disp('Skipping ex_occupancy_heatmap.png (already exists)')
end

% =========================================================================
%  PROTOCOL 27: Cross-strain analysis
%  Note: XSTRAIN_IDS are indices into strain_names2.mat (ES=17, Pm2ab=8, T4T5=3)
% =========================================================================
disp('=== Cross-strain figures (protocol_27) ===')

if ~isfile(fullfile(SAVE_DIR, 'ex_xstrain_timeseries.png'))
    disp('Generating cross-strain timeseries...')
    try
        figure('Visible', 'off');
        plot_xstrain_per_cond('protocol_27', "av_data", 1, XSTRAIN_IDS, ts_params, DATA_27)
        f = gcf; f.Position = [181 611 641 340];
        exportgraphics(f, fullfile(SAVE_DIR, 'ex_xstrain_timeseries.png'), 'Resolution', 300);
        close(f)
    catch ME
        disp(['Error: ' ME.message])
    end
else
    disp('Skipping ex_xstrain_timeseries.png (already exists)')
end

if ~isfile(fullfile(SAVE_DIR, 'ex_xstrain_boxchart.png'))
    disp('Generating cross-strain boxchart...')
    try
        figure('Visible', 'off');
        plot([0.5 numel(XSTRAIN_IDS)+0.5], [0 0], 'k')
        hold on
        plot_boxchart_metrics_xstrains(DATA_27, XSTRAIN_IDS, 1, "av_data", 300:1200, 0)
        f = gcf; f.Position = [138 605 500 300];
        exportgraphics(f, fullfile(SAVE_DIR, 'ex_xstrain_boxchart.png'), 'Resolution', 300);
        close(f)
    catch ME
        disp(['Error: ' ME.message])
    end
else
    disp('Skipping ex_xstrain_boxchart.png (already exists)')
end

% =========================================================================
%  PROTOCOL 27: Trajectory figures
%  Note: plot_traj_xcond and plot_traj_xflies have a missing argument bug,
%  so trajectory_xcond and trajectory_xflies are generated by calling
%  plot_trajectory_condition directly.
% =========================================================================
disp('=== Trajectory figures (protocol_27) ===')

traj_data    = DATA_27.(ES_STRAIN).(SEX);
frame_rng    = 300:1200;
fly_idx_show = 3;  % single fly for xcond/xflies/prepost figures

if ~isfile(fullfile(SAVE_DIR, 'ex_trajectory_subplot.png'))
    disp('Generating trajectory subplot grid...')
    try
        plot_traj_subplot(DATA_27, ES_STRAIN, 1, SAVE_DIR)
        f = gcf;
        exportgraphics(f, fullfile(SAVE_DIR, 'ex_trajectory_subplot.png'), 'Resolution', 300);
        close all
    catch ME
        disp(['Error: ' ME.message])
    end
else
    disp('Skipping ex_trajectory_subplot.png (already exists)')
end

if ~isfile(fullfile(SAVE_DIR, 'ex_trajectory_xcond.png'))
    disp('Generating single-fly cross-condition trajectory...')
    try
        cond_ids = [10, 9, 1];  % static, flicker, 4Hz

        % Clamp fly index to available data
        n_flies = size(combine_timeseries_across_exp(traj_data, cond_ids(1), "x_data", ...
            'qc', 'none', 'average_reps', false), 1);
        fly_idx = min(fly_idx_show, n_flies);

        figure('Visible', 'off');
        for ci = 1:numel(cond_ids)
            cn = cond_ids(ci);
            x = combine_timeseries_across_exp(traj_data, cn, "x_data", ...
                'qc', 'none', 'average_reps', false);
            y = combine_timeseries_across_exp(traj_data, cn, "y_data", ...
                'qc', 'none', 'average_reps', false);
            plot_trajectory_condition(x(fly_idx, frame_rng), y(fly_idx, frame_rng), ...
                ARENA_CX, ARENA_CY, COL_12(cn,:), COND_LABELS{cn}, ci > 1, 0)
            hold on
        end
        axis off
        title(string(fly_idx))
        lgd = legend; lgd.Position = [0.8178 0.6857 0.1554 0.2821];

        f = gcf;
        exportgraphics(f, fullfile(SAVE_DIR, 'ex_trajectory_xcond.png'), 'Resolution', 300);
        close(f)
    catch ME
        disp(['Error: ' ME.message])
    end
else
    disp('Skipping ex_trajectory_xcond.png (already exists)')
end

if ~isfile(fullfile(SAVE_DIR, 'ex_trajectory_xflies.png'))
    disp('Generating multi-fly trajectory...')
    try
        cn = 1;  % 4Hz gratings
        x_all = combine_timeseries_across_exp(traj_data, cn, "x_data", ...
            'qc', 'none', 'average_reps', false);
        y_all = combine_timeseries_across_exp(traj_data, cn, "y_data", ...
            'qc', 'none', 'average_reps', false);
        fly_ids = 1:min(3, size(x_all, 1));

        figure('Visible', 'off');
        for fi = 1:numel(fly_ids)
            fid = fly_ids(fi);
            plot_trajectory_condition(x_all(fid, frame_rng), y_all(fid, frame_rng), ...
                ARENA_CX, ARENA_CY, COL_12(cn,:), strcat('Fly ', string(fid)), fi > 1, 0)
            hold on
        end
        axis off; legend off

        f = gcf;
        exportgraphics(f, fullfile(SAVE_DIR, 'ex_trajectory_xflies.png'), 'Resolution', 300);
        close(f)
    catch ME
        disp(['Error: ' ME.message])
    end
else
    disp('Skipping ex_trajectory_xflies.png (already exists)')
end

if ~isfile(fullfile(SAVE_DIR, 'ex_trajectory_prepost.png'))
    disp('Generating pre/post stimulus trajectory...')
    try
        n_flies = size(combine_timeseries_across_exp(traj_data, 1, "x_data", ...
            'qc', 'none', 'average_reps', false), 1);
        fly_idx = min(fly_idx_show, n_flies);
        plot_traj_pre_post(DATA_27, ES_STRAIN, 1, fly_idx)
        legend off
        f = gcf;
        exportgraphics(f, fullfile(SAVE_DIR, 'ex_trajectory_prepost.png'), 'Resolution', 300);
        close(f)
    catch ME
        disp(['Error: ' ME.message])
    end
else
    disp('Skipping ex_trajectory_prepost.png (already exists)')
end

close all

% =========================================================================
%  PROTOCOL 31: Load data and generate speed comparison figures
% =========================================================================
disp('=== Loading protocol_31 data ===')
protocol_dir_31 = fullfile(PROJECT_ROOT, 'results', 'protocol_31');
DATA_31 = comb_data_across_cohorts_cond(protocol_dir_31);
disp('Protocol 31 data loaded.')

if ~isfile(fullfile(SAVE_DIR, 'ex_speed_comparison_timeseries.png'))
    disp('Generating speed comparison timeseries (protocol_31)...')
    try
        figure('Visible', 'off');
        plot_xcond_per_strain2('protocol_31', "dist_data_delta", [1,2,3,4], ES_STRAIN, ts_params, DATA_31)
        f = gcf; f.Position = [181 611 641 340];
        exportgraphics(f, fullfile(SAVE_DIR, 'ex_speed_comparison_timeseries.png'), 'Resolution', 300);
        close(f)
    catch ME
        disp(['Error: ' ME.message])
    end
else
    disp('Skipping ex_speed_comparison_timeseries.png (already exists)')
end

if ~isfile(fullfile(SAVE_DIR, 'ex_speed_comparison_boxchart.png'))
    disp('Generating speed comparison boxchart (protocol_31)...')
    try
        figure('Visible', 'off');
        plot([0.5 4.5], [0 0], 'k'); hold on
        plot_boxchart_metrics_xcond(DATA_31, [1,2,3,4], ES_STRAIN, "dist_data", 1170:1200, 1)
        f = gcf; f.Position = [100 500 400 350];
        exportgraphics(f, fullfile(SAVE_DIR, 'ex_speed_comparison_boxchart.png'), 'Resolution', 300);
        close(f)
    catch ME
        disp(['Error: ' ME.message])
    end
else
    disp('Skipping ex_speed_comparison_boxchart.png (already exists)')
end

close all

%% Done
disp('=== Group-level figures complete ===')
disp(['Saved to: ' SAVE_DIR])
dir(fullfile(SAVE_DIR, '*.png'))
