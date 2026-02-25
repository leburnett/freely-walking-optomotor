% generate_example_figs_part2.m
% Generate across-cohorts example figures for the training guide.
% Separate script to avoid re-running Part 1.
%
% This script converts existing PDF figures to PNG and generates the heatmap.

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
%  PART 2: Across-cohorts analysis
%  ========================================================================
disp('=== Across-cohorts analysis ===')

protocol_dir = fullfile(PROJECT_ROOT, 'results', 'protocol_27');

disp('Combining data across cohorts...')
DATA = comb_data_across_cohorts_cond(protocol_dir);
disp('Data combined successfully.')

%% Figure 6: Strain vs ES comparison using the raw tuning function
% Use the tuning version that doesn't call check_and_average_across_reps
disp('Generating strain vs ES comparison using raw version...')

target_strain = 'ss2344_T4_shibire_kir';

cond_titles = {"60deg-gratings-4Hz"...
    , "60deg-gratings-8Hz"...
    , "narrow-ON-bars-4Hz"...
    , "narrow-OFF-bars-4Hz"...
    , "ON-curtains-8Hz"...
    , "OFF-curtains-8Hz"...
    , "reverse-phi-2Hz"...
    , "reverse-phi-4Hz"...
    , "60deg-flicker-4Hz"...
    , "60deg-gratings-static"...
    , "60deg-gratings-0-8-offset"...
    , "32px-ON-single-bar"...
    };

gp_data = {
    'jfrc100_es_shibire_kir', 'F', [0.7 0.7 0.7]; % light grey (control)
    target_strain, 'F', [0.52, 0.12, 0.57]; % purple (target)
    };

gps2plot = [1, 2];
plot_sem = 1;

% Use _raw variant which doesn't call check_and_average_across_reps
try
    f_xgrp_fv = plot_allcond_acrossgroups_tuning_raw(DATA, gp_data, cond_titles, 'fv_data', gps2plot, plot_sem);
    exportgraphics(f_xgrp_fv, fullfile(SAVE_DIR, 'ex_strain_vs_ES_fv.png'), ...
        'Resolution', 300);
    close(f_xgrp_fv)
    disp('Strain vs ES (fv) figure saved.')
catch ME
    disp(['Error with raw tuning: ' ME.message])
    disp('Trying alternative approach...')

    % Fall back: generate a simple comparison manually
    generate_simple_strain_comparison(DATA, target_strain, 'fv_data', cond_titles, SAVE_DIR);
end

%% Figure 7: P-value heatmap across strains
disp('Generating p-value heatmap...')
try
    DATA = make_summary_heat_maps_p27(DATA);

    f_heatmap = gcf;
    exportgraphics(f_heatmap, fullfile(SAVE_DIR, 'ex_pvalue_heatmap.png'), ...
        'Resolution', 300);
    close(f_heatmap)
    disp('Heatmap figure saved.')
catch ME
    disp(['Error generating heatmap: ' ME.message])
end

close all

%% Done
disp('=== Part 2 complete ===')
disp(['Saved to: ' SAVE_DIR])
dir(fullfile(SAVE_DIR, '*.png'))


%% Helper function
function generate_simple_strain_comparison(DATA, target_strain, data_type, cond_titles, save_dir)
    % Simple manual comparison plot as fallback
    control = 'jfrc100_es_shibire_kir';
    sex = 'F';

    n_cond = length(cond_titles);

    figure('Position', [1 161 900 1000]);
    t = tiledlayout(ceil(n_cond/2), 2);
    t.TileSpacing = 'compact';
    t.Padding = 'compact';

    for c = 1:n_cond
        nexttile

        cond_str = strcat('R1_condition_', string(c));

        % Control data
        if isfield(DATA, control) && isfield(DATA.(control), sex)
            ctrl_data = DATA.(control).(sex);
            n_ctrl = length(ctrl_data);
            all_ctrl = [];
            for k = 1:n_ctrl
                if isfield(ctrl_data(k), cond_str)
                    d = ctrl_data(k).(cond_str).(data_type);
                    all_ctrl = vertcat(all_ctrl, d);
                end
            end
            if ~isempty(all_ctrl)
                m = mean(all_ctrl, 1, 'omitnan');
                s = std(all_ctrl, 0, 1, 'omitnan') / sqrt(size(all_ctrl, 1));
                x = 1:length(m);
                fill([x fliplr(x)], [m+s fliplr(m-s)], [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.5); hold on
                plot(x, m, 'Color', [0.7 0.7 0.7], 'LineWidth', 1.5);
            end
        end

        % Target data
        if isfield(DATA, target_strain) && isfield(DATA.(target_strain), sex)
            tgt_data = DATA.(target_strain).(sex);
            n_tgt = length(tgt_data);
            all_tgt = [];
            for k = 1:n_tgt
                if isfield(tgt_data(k), cond_str)
                    d = tgt_data(k).(cond_str).(data_type);
                    all_tgt = vertcat(all_tgt, d);
                end
            end
            if ~isempty(all_tgt)
                m = mean(all_tgt, 1, 'omitnan');
                s = std(all_tgt, 0, 1, 'omitnan') / sqrt(size(all_tgt, 1));
                x = 1:length(m);
                fill([x fliplr(x)], [m+s fliplr(m-s)], [0.8 0.6 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.5); hold on
                plot(x, m, 'Color', [0.52 0.12 0.57], 'LineWidth', 1.5);
            end
        end

        title(strrep(cond_titles{c}, '-', ' '), 'FontSize', 8)
        if c == 1
            ylabel(strrep(data_type, '_', ' '))
        end
        box off
    end

    fname = fullfile(save_dir, 'ex_strain_vs_ES_fv.png');
    exportgraphics(gcf, fname, 'Resolution', 300);
    close(gcf)
    disp(['Saved simple comparison to: ' fname])
end
