% generate_example_figs.m
% Generate example figures for the training guide documentation.
% This script runs parts of the processing pipeline on a single experiment
% and the across-cohorts analysis, saving PNG figures for inclusion in the
% training guide PDF.
%
% Usage: Run from MATLAB command line or via:
%   matlab -batch "run('generate_example_figs.m')"

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
%  PART 1: Single experiment processing
%  ========================================================================
disp('=== PART 1: Single experiment figures ===')

% Path to the experiment
exp_path = fullfile(PROJECT_ROOT, 'data', '2025_03_17', 'protocol_27', ...
    'jfrc100_es_shibire_kir', 'F', '16_33_27');

% Load data
cd(exp_path)

% Load LOG
log_files = dir('LOG_*');
load(fullfile(log_files(1).folder, log_files(1).name), 'LOG');

% Navigate into REC folder to find feat and trx
rec_folder = dir('REC_*');
isdir_mask = [rec_folder.isdir] == 1;
rec_folder = rec_folder(isdir_mask);
cd(fullfile(rec_folder(1).folder, rec_folder(1).name))

rec_name = rec_folder(1).name;

% Load feat
feat_file_path = strcat(rec_name, '-feat.mat');
load(feat_file_path, 'feat');

% Load trx
trx_file_path = strcat(rec_name, '_JAABA/trx.mat');
load(trx_file_path, 'trx');

% Set identifiers
strain = 'jfrc100_es_shibire_kir';
sex = 'F';
protocol = 'protocol_27';
save_str = '2025-03-17_16-33-27_jfrc100_es_shibire_kir_protocol_27_F';

%% Combine data and compute metrics
disp('Computing behavioral metrics...')
n_flies_in_arena = length(trx);
[comb_data, feat, trx] = combine_data_one_cohort(feat, trx);
n_flies_tracked = length(trx);
disp(['Flies tracked: ' num2str(n_flies_tracked) ' / ' num2str(n_flies_in_arena)])

%% Figure 1: Overview histograms
if ~isfile(fullfile(SAVE_DIR, 'ex_overview_histograms.png'))
    disp('Generating overview histograms...')
    f_overview = make_overview(comb_data, strain, sex, protocol);
    exportgraphics(f_overview, fullfile(SAVE_DIR, 'ex_overview_histograms.png'), ...
        'Resolution', 300);
    close(f_overview)
else
    disp('Skipping overview histograms (already exists)')
end

%% Figure 2: Full experiment timeseries (features)
if ~isfile(fullfile(SAVE_DIR, 'ex_full_experiment_timeseries.png'))
    disp('Generating full experiment timeseries...')
    f_feat = plot_all_features_filt(LOG, comb_data, protocol, save_str);
    f_feat.Position = [6 289 1321 757];
    exportgraphics(f_feat, fullfile(SAVE_DIR, 'ex_full_experiment_timeseries.png'), ...
        'Resolution', 300);
    close(f_feat)
else
    disp('Skipping full experiment timeseries (already exists)')
end

%% Figure 3: Acclimation period
if ~isfile(fullfile(SAVE_DIR, 'ex_acclimation_period.png'))
    disp('Generating acclimation figure...')
    f_acclim = plot_all_features_acclim(LOG, comb_data, save_str);
    exportgraphics(f_acclim, fullfile(SAVE_DIR, 'ex_acclimation_period.png'), ...
        'Resolution', 300);
    close(f_acclim)
else
    disp('Skipping acclimation figure (already exists)')
end

%% Figure 4: Per-condition tuning plots (forward velocity)
disp('Generating per-condition tuning plots...')

% Add dist_trav field if missing (computed as cumulative distance from velocity)
if ~isfield(comb_data, 'dist_trav')
    FPS = 30;
    comb_data.dist_trav = comb_data.vel_data / FPS;
end

DATA_single = comb_data_one_cohort_cond(LOG, comb_data, protocol);

% Restructure: remove 'none' landing level to match plot function expectations
% comb_data_one_cohort_cond creates DATA.(strain).none.(sex)
% but plot_allcond_onecohort_tuning expects DATA.(strain).(sex)
strain_fields = fieldnames(DATA_single);
for sf = 1:numel(strain_fields)
    sn = strain_fields{sf};
    if isfield(DATA_single.(sn), 'none')
        DATA_single.(sn) = DATA_single.(sn).none;
    end
end

strain = check_strain_typos(strain);

f_cond_fv = plot_allcond_onecohort_tuning(DATA_single, sex, strain, 'fv_data', 1);
exportgraphics(f_cond_fv, fullfile(SAVE_DIR, 'ex_percondition_fv.png'), ...
    'Resolution', 300);
close(f_cond_fv)

%% Figure 5: Per-condition tuning plots (angular velocity)
f_cond_av = plot_allcond_onecohort_tuning(DATA_single, sex, strain, 'av_data', 1);
exportgraphics(f_cond_av, fullfile(SAVE_DIR, 'ex_percondition_av.png'), ...
    'Resolution', 300);
close(f_cond_av)

close all

%% ========================================================================
%  PART 2: Across-cohorts analysis
%  ========================================================================
disp('=== PART 2: Across-cohorts figures ===')

protocol_dir = fullfile(PROJECT_ROOT, 'results', 'protocol_27');

disp('Combining data across cohorts (this may take a minute)...')
DATA = comb_data_across_cohorts_cond(protocol_dir);
disp('Data combined successfully.')

%% Figure 6: One strain vs empty-split (forward velocity)
disp('Generating strain vs ES comparison...')

% Use ss2344_T4 as an example strain (T4 neurons - key motion detection)
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

f_xgrp_fv = plot_allcond_acrossgroups_tuning(DATA, gp_data, cond_titles, 'fv_data', gps2plot, plot_sem);
exportgraphics(f_xgrp_fv, fullfile(SAVE_DIR, 'ex_strain_vs_ES_fv.png'), ...
    'Resolution', 300);
close(f_xgrp_fv)

%% Figure 7: One strain vs empty-split (angular velocity)
f_xgrp_av = plot_allcond_acrossgroups_tuning(DATA, gp_data, cond_titles, 'av_data', gps2plot, plot_sem);
exportgraphics(f_xgrp_av, fullfile(SAVE_DIR, 'ex_strain_vs_ES_av.png'), ...
    'Resolution', 300);
close(f_xgrp_av)

%% Figure 8: P-value heatmap across strains
disp('Generating p-value heatmap...')
DATA = make_summary_heat_maps_p27(DATA);

f_heatmap = gcf;
exportgraphics(f_heatmap, fullfile(SAVE_DIR, 'ex_pvalue_heatmap.png'), ...
    'Resolution', 300);
close(f_heatmap)

close all

%% Done
disp('=== All example figures generated ===')
disp(['Saved to: ' SAVE_DIR])
dir(fullfile(SAVE_DIR, '*.png'))
