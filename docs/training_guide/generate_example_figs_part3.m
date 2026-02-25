% generate_example_figs_part3.m
% Generate example figures for the training guide: analysis scripts.
%
% This script generates example output from:
%   1. fig_different_speeds.m (protocol_31 speed comparison)
%   2. fig1_plots.m (protocol_27 publication figures)
%   3. generate_trajectory_plots.m (trajectory visualizations)

%% Setup paths
REPO_ROOT = fileparts(fileparts(fileparts(mfilename('fullpath'))));  % training_guide -> docs -> repo root
run(fullfile(REPO_ROOT, 'setup_path.m'));
cfg = get_config();
PROJECT_ROOT = cfg.project_root;
SAVE_DIR = fullfile(REPO_ROOT, 'docs', 'training_guide', 'example_figs');

if ~isfolder(SAVE_DIR)
    mkdir(SAVE_DIR);
end

%% ========================================================================
%  PART A: fig_different_speeds.m examples (protocol_31)
%  ========================================================================
disp('=== fig_different_speeds.m examples ===')

protocol_dir_31 = fullfile(PROJECT_ROOT, 'results', 'protocol_31');
DATA_31 = comb_data_across_cohorts_cond(protocol_dir_31);

cond_titles_31 = {"60deg-gratings-1Hz"...
    , "60deg-gratings-2Hz"...
    , "60deg-gratings-4Hz"...
    , "60deg-gratings-8Hz"...
    , "60deg-flicker-4Hz"...
    , "15deg-gratings-4Hz"...
    , "15deg-gratings-8Hz"...
    , "15deg-gratings-16Hz"...
    , "15deg-gratings-32Hz"...
    , "15deg-flicker-4Hz"...
    };

strain = "jfrc100_es_shibire_kir";

% --- Figure: Cross-condition timeseries (all 60-deg speeds) ---
disp('Generating speed comparison timeseries (60 deg)...')
try
    cond_ids = [1,2,3,4];
    data_type = "dist_data_delta";
    protocol = "protocol_31";
    params.save_figs = 0;
    params.plot_sem = 1;
    params.plot_sd = 0;
    params.plot_individ = 0;
    params.shaded_areas = 0;

    figure('Visible', 'off');
    plot_xcond_per_strain2(protocol, data_type, cond_ids, strain, params, DATA_31)
    f = gcf;
    f.Position = [181 611 641 340];
    exportgraphics(f, fullfile(SAVE_DIR, 'ex_speed_comparison_timeseries.png'), ...
        'Resolution', 300);
    close(f)
    disp('Speed comparison timeseries saved.')
catch ME
    disp(['Error: ' ME.message])
end

% --- Figure: Box chart across speeds (distance delta) ---
disp('Generating speed comparison boxchart (distance)...')
try
    cond_ids = [1,2,3,4];
    data_type = "dist_data";
    rng = 1170:1200;
    delta = 1;

    figure('Visible', 'off');
    plot([0.5 4.5], [0 0], 'k')
    hold on
    plot_boxchart_metrics_xcond(DATA_31, cond_ids, strain, data_type, rng, delta)
    f = gcf;
    f.Position = [100 500 400 350];
    exportgraphics(f, fullfile(SAVE_DIR, 'ex_speed_comparison_boxchart.png'), ...
        'Resolution', 300);
    close(f)
    disp('Speed comparison boxchart saved.')
catch ME
    disp(['Error: ' ME.message])
end

close all

%% ========================================================================
%  PART B: fig1_plots.m examples (protocol_27)
%  ========================================================================
disp('=== fig1_plots.m examples ===')

protocol_dir_27 = fullfile(PROJECT_ROOT, 'results', 'protocol_27');
DATA_27 = comb_data_across_cohorts_cond(protocol_dir_27);

strain = "jfrc100_es_shibire_kir";

% --- Figure: Cross-condition timeseries with SEM ---
disp('Generating cross-condition timeseries...')
try
    cond_ids = [1,7];
    data_type = "av_data";
    protocol = "protocol_27";
    params.save_figs = 0;
    params.plot_sem = 1;
    params.plot_sd = 0;
    params.plot_individ = 0;
    params.shaded_areas = 0;

    figure('Visible', 'off');
    plot_xcond_per_strain2(protocol, data_type, cond_ids, strain, params, DATA_27)
    f = gcf;
    f.Position = [181 611 641 340];
    exportgraphics(f, fullfile(SAVE_DIR, 'ex_xcond_timeseries.png'), ...
        'Resolution', 300);
    close(f)
    disp('Cross-condition timeseries saved.')
catch ME
    disp(['Error: ' ME.message])
end

% --- Figure: Boxchart across conditions (angular velocity) ---
disp('Generating cross-condition boxchart...')
try
    cond_ids = [1,7];
    data_type = "av_data";
    rng = 300:1200;
    delta = 0;

    figure('Visible', 'off');
    plot_boxchart_metrics_xcond(DATA_27, cond_ids, strain, data_type, rng, delta)
    f = gcf;
    f.Position = [100 500 400 350];
    exportgraphics(f, fullfile(SAVE_DIR, 'ex_xcond_boxchart.png'), ...
        'Resolution', 300);
    close(f)
    disp('Cross-condition boxchart saved.')
catch ME
    disp(['Error: ' ME.message])
end

% --- Figure: Occupancy heatmap (all cohorts) ---
disp('Generating occupancy heatmap...')
try
    sex = "F";
    data = DATA_27.(strain).(sex);
    hFig = plot_fly_occupancy_heatmaps_all(data);
    hFig.Position = [27 622 1774 425];
    exportgraphics(hFig, fullfile(SAVE_DIR, 'ex_occupancy_heatmap.png'), ...
        'Resolution', 300);
    close(hFig)
    disp('Occupancy heatmap saved.')
catch ME
    disp(['Error: ' ME.message])
end

% --- Figure: Cross-strain timeseries comparison ---
disp('Generating cross-strain timeseries...')
try
    strain_names_all = fieldnames(DATA_27);
    % Find indices for ES, Pm2ab, T4T5
    es_idx = find(strcmp(strain_names_all, 'jfrc100_es_shibire_kir'));
    pm2_idx = find(strcmp(strain_names_all, 'ss00326_Pm2ab_shibire_kir'));
    t4t5_idx = find(strcmp(strain_names_all, 'ss324_t4t5_shibire_kir'));

    if ~isempty(es_idx) && ~isempty(t4t5_idx)
        strains_to_plot = [];
        if ~isempty(es_idx), strains_to_plot(end+1) = es_idx; end
        if ~isempty(pm2_idx), strains_to_plot(end+1) = pm2_idx; end
        if ~isempty(t4t5_idx), strains_to_plot(end+1) = t4t5_idx; end

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
    else
        disp('Could not find required strains for cross-strain plot.')
    end
catch ME
    disp(['Error: ' ME.message])
end

% --- Figure: Cross-strain boxchart comparison ---
disp('Generating cross-strain boxchart...')
try
    strain_names_all = fieldnames(DATA_27);
    es_idx = find(strcmp(strain_names_all, 'jfrc100_es_shibire_kir'));
    pm2_idx = find(strcmp(strain_names_all, 'ss00326_Pm2ab_shibire_kir'));
    t4t5_idx = find(strcmp(strain_names_all, 'ss324_t4t5_shibire_kir'));

    if ~isempty(es_idx) && ~isempty(t4t5_idx)
        strain_ids = [];
        if ~isempty(es_idx), strain_ids(end+1) = es_idx; end
        if ~isempty(pm2_idx), strain_ids(end+1) = pm2_idx; end
        if ~isempty(t4t5_idx), strain_ids(end+1) = t4t5_idx; end

        cond_idx = 1;
        data_type = "av_data";
        rng = 300:1200;
        delta = 0;

        figure('Visible', 'off');
        plot([0.5 numel(strain_ids)+0.5], [0 0], 'k')
        hold on
        plot_boxchart_metrics_xstrains(DATA_27, strain_ids, cond_idx, data_type, rng, delta)
        f = gcf;
        f.Position = [138 605 500 300];
        exportgraphics(f, fullfile(SAVE_DIR, 'ex_xstrain_boxchart.png'), ...
            'Resolution', 300);
        close(f)
        disp('Cross-strain boxchart saved.')
    else
        disp('Could not find required strains for cross-strain boxchart.')
    end
catch ME
    disp(['Error: ' ME.message])
end

close all

%% ========================================================================
%  PART C: generate_trajectory_plots.m examples (protocol_27)
%  ========================================================================
disp('=== generate_trajectory_plots.m examples ===')

% Use protocol_27 data (already loaded) for trajectory examples
strain = "jfrc100_es_shibire_kir";

% --- Figure: Trajectory subplot grid ---
disp('Generating trajectory subplot grid...')
try
    condition_n = 1; % 4Hz gratings
    save_folder = SAVE_DIR; % passed but not used for saving by the function
    plot_traj_subplot(DATA_27, strain, condition_n, save_folder)
    f = gcf;
    exportgraphics(f, fullfile(SAVE_DIR, 'ex_trajectory_subplot.png'), ...
        'Resolution', 300);
    close all
    disp('Trajectory subplot grid saved.')
catch ME
    disp(['Error: ' ME.message])
end

% --- Figure: Single fly across conditions ---
disp('Generating single-fly cross-condition trajectory...')
try
    cond_ids = [10, 9, 1]; % static, flicker, 4Hz

    % Find a valid fly index by checking the data
    sex = "F";
    data = DATA_27.(strain).(sex);
    % Use first cohort, check number of flies
    n_flies = size(data(1).R1_condition_1.x_data, 1);
    fly_idx = min(3, n_flies); % Use fly 3 or less if fewer flies

    plot_traj_xcond(DATA_27, strain, cond_ids, fly_idx)
    f = gcf;
    exportgraphics(f, fullfile(SAVE_DIR, 'ex_trajectory_xcond.png'), ...
        'Resolution', 300);
    close(f)
    disp('Single-fly cross-condition trajectory saved.')
catch ME
    disp(['Error: ' ME.message])
end

% --- Figure: Multiple flies in one condition ---
disp('Generating multi-fly trajectory...')
try
    cond_idx = 1; % 4Hz gratings
    sex = "F";
    data = DATA_27.(strain).(sex);
    n_flies = size(data(1).R1_condition_1.x_data, 1);
    fly_ids = 1:min(3, n_flies); % First 3 flies

    plot_traj_xflies(DATA_27, strain, cond_idx, fly_ids)
    legend off
    f = gcf;
    exportgraphics(f, fullfile(SAVE_DIR, 'ex_trajectory_xflies.png'), ...
        'Resolution', 300);
    close(f)
    disp('Multi-fly trajectory saved.')
catch ME
    disp(['Error: ' ME.message])
end

% --- Figure: Pre/post stimulus split ---
disp('Generating pre/post stimulus trajectory...')
try
    cond_idx = 1; % 4Hz gratings
    sex = "F";
    data = DATA_27.(strain).(sex);
    n_flies = size(data(1).R1_condition_1.x_data, 1);
    fly_ids = min(3, n_flies); % Single fly

    plot_traj_pre_post(DATA_27, strain, cond_idx, fly_ids)
    legend off
    f = gcf;
    exportgraphics(f, fullfile(SAVE_DIR, 'ex_trajectory_prepost.png'), ...
        'Resolution', 300);
    close(f)
    disp('Pre/post stimulus trajectory saved.')
catch ME
    disp(['Error: ' ME.message])
end

close all

%% Done
disp('=== Part 3 complete ===')
disp(['Saved to: ' SAVE_DIR])
dir(fullfile(SAVE_DIR, '*.png'))
