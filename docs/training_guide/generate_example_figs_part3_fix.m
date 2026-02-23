% generate_example_figs_part3_fix.m
% Fix: regenerate only the failed figures from Part 3.

%% Setup paths
REPO_ROOT = '/Users/burnettl/Documents/GitHub/freely-walking-optomotor';
PROJECT_ROOT = '/Users/burnettl/Documents/Projects/oaky_cokey';
SAVE_DIR = fullfile(REPO_ROOT, 'docs', 'training_guide', 'example_figs');

addpath(genpath(fullfile(REPO_ROOT, 'processing_functions')));
addpath(genpath(fullfile(REPO_ROOT, 'plotting_functions')));
addpath(genpath(fullfile(REPO_ROOT, 'misc')));

%% Load protocol_27 data
protocol_dir_27 = fullfile(PROJECT_ROOT, 'results', 'protocol_27');
DATA_27 = comb_data_across_cohorts_cond(protocol_dir_27);

%% Fix 1: Cross-strain timeseries
% plot_xstrain_per_cond uses strain indices from strain_names2.mat:
%   Indices 1-16 = screened strains, 17 = jfrc100_es_shibire_kir
%   Key indices: 3 = T4T5, 8 = Pm2ab, 17 = ES
disp('Generating cross-strain timeseries...')
try
    strains_to_plot = [17, 8, 3]; % ES, Pm2ab, T4T5
    cond_ids = 1;
    data_type = "av_data";
    protocol = "protocol_27";
    params.save_figs = 0;
    params.plot_sem = 1;
    params.plot_sd = 0;
    params.plot_individ = 0;
    params.shaded_areas = 0;

    figure('Visible', 'off');
    plot_xstrain_per_cond(protocol, data_type, cond_ids, strains_to_plot, params, DATA_27)
    f = gcf;
    f.Position = [181 611 641 340];
    exportgraphics(f, fullfile(SAVE_DIR, 'ex_xstrain_timeseries.png'), ...
        'Resolution', 300);
    close(f)
    disp('Cross-strain timeseries saved.')
catch ME
    disp(['Error (xstrain ts): ' ME.message])
    disp(getReport(ME))
end

%% Fix 2: Cross-strain boxchart
disp('Generating cross-strain boxchart...')
try
    strain_ids = [17, 8, 3]; % ES, Pm2ab, T4T5
    cond_idx = 1;
    data_type = "av_data";
    rng = 300:1200;
    delta = 0;

    figure('Visible', 'off');
    plot([0.5 3.5], [0 0], 'k')
    hold on
    plot_boxchart_metrics_xstrains(DATA_27, strain_ids, cond_idx, data_type, rng, delta)
    f = gcf;
    f.Position = [138 605 500 300];
    exportgraphics(f, fullfile(SAVE_DIR, 'ex_xstrain_boxchart.png'), ...
        'Resolution', 300);
    close(f)
    disp('Cross-strain boxchart saved.')
catch ME
    disp(['Error (xstrain box): ' ME.message])
    disp(getReport(ME))
end

%% Fix 3: Trajectory xcond - need to fix the start_stop arg bug
% plot_traj_xcond and plot_traj_xflies call plot_trajectory_condition with 7 args
% but it requires 8 (missing start_stop parameter).
% Workaround: call plot_trajectory_condition directly with correct args.
disp('Generating single-fly cross-condition trajectory (manual)...')
try
    strain = "jfrc100_es_shibire_kir";
    sex = "F";
    data = DATA_27.(strain).(sex);

    col_12 = [31 120 180; 31 120 180; 178 223 138; 47 141 41; ...
        251 154 153; 227 26 28; 253 191 111; 255 127 0; ...
        166 206 227; 200 200 200; 255 224 41; 187 75 12]./255;
    cond_titles_plot = {'4Hz', '8Hz', '4Hz-narrow-ON', '4Hz-narrow-OFF', ...
        'ON-Edge', 'OFF-Edge', 'RevPhi-4Hz', 'RevPhi-8Hz', ...
        '4Hz-Flicker', 'Static', '4Hz-offset', 'Phototaxis'};

    cx = 122.8079;
    cy = 124.7267;
    frame_rng_stim = 300:1200;

    cond_ids = [10, 9, 1]; % static, flicker, 4Hz
    fly_idx = 3; % Use fly 3

    figure('Visible', 'off');
    for c = 1:numel(cond_ids)
        condition_n = cond_ids(c);
        line_colour = col_12(condition_n, :);
        cond_name = cond_titles_plot{condition_n};

        cond_data_x = combine_timeseries_across_exp(data, condition_n, "x_data");
        cond_data_y = combine_timeseries_across_exp(data, condition_n, "y_data");

        if fly_idx > size(cond_data_x, 1)
            fly_idx = 1;
        end

        x = cond_data_x(fly_idx, frame_rng_stim);
        y = cond_data_y(fly_idx, frame_rng_stim);

        if c == 1
            traj_only = 0;
        else
            traj_only = 1;
        end
        plot_trajectory_condition(x, y, cx, cy, line_colour, cond_name, traj_only, 0)
        hold on
    end
    axis off
    title(string(fly_idx))
    lgd = legend;
    lgd.Position = [0.8178 0.6857 0.1554 0.2821];

    f = gcf;
    exportgraphics(f, fullfile(SAVE_DIR, 'ex_trajectory_xcond.png'), ...
        'Resolution', 300);
    close(f)
    disp('Single-fly cross-condition trajectory saved.')
catch ME
    disp(['Error (traj xcond): ' ME.message])
    disp(getReport(ME))
end

%% Fix 4: Trajectory xflies
disp('Generating multi-fly trajectory (manual)...')
try
    strain = "jfrc100_es_shibire_kir";
    sex = "F";
    data = DATA_27.(strain).(sex);

    cx = 122.8079;
    cy = 124.7267;
    frame_rng_stim = 300:1200;

    col_12 = [31 120 180; 31 120 180; 178 223 138; 47 141 41; ...
        251 154 153; 227 26 28; 253 191 111; 255 127 0; ...
        166 206 227; 200 200 200; 255 224 41; 187 75 12]./255;
    cond_titles_plot = {'4Hz', '8Hz', '4Hz-narrow-ON', '4Hz-narrow-OFF', ...
        'ON-Edge', 'OFF-Edge', 'RevPhi-4Hz', 'RevPhi-8Hz', ...
        '4Hz-Flicker', 'Static', '4Hz-offset', 'Phototaxis'};

    cond_idx = 1;
    line_colour = col_12(cond_idx, :);
    cond_name = cond_titles_plot{cond_idx};
    fly_ids = [1, 2, 3];

    cond_data_x = combine_timeseries_across_exp(data, cond_idx, "x_data");
    cond_data_y = combine_timeseries_across_exp(data, cond_idx, "y_data");

    n_avail = size(cond_data_x, 1);
    fly_ids = fly_ids(fly_ids <= n_avail);

    figure('Visible', 'off');
    for f_i = 1:numel(fly_ids)
        fly_idx = fly_ids(f_i);
        x = cond_data_x(fly_idx, frame_rng_stim);
        y = cond_data_y(fly_idx, frame_rng_stim);

        if f_i == 1
            traj_only = 0;
        else
            traj_only = 1;
        end
        plot_trajectory_condition(x, y, cx, cy, line_colour, ...
            strcat('Fly ', string(fly_idx)), traj_only, 0)
        hold on
    end
    axis off
    legend off

    f = gcf;
    exportgraphics(f, fullfile(SAVE_DIR, 'ex_trajectory_xflies.png'), ...
        'Resolution', 300);
    close(f)
    disp('Multi-fly trajectory saved.')
catch ME
    disp(['Error (traj xflies): ' ME.message])
    disp(getReport(ME))
end

close all

%% Done
disp('=== Fix run complete ===')
dir(fullfile(SAVE_DIR, '*.png'))
