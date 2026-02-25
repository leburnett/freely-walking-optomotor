% generate_example_figs_single_exp.m
% Generate single-experiment example figures for the training guide.
%
% Loads one experiment and saves 5 figures demonstrating the single-cohort
% processing pipeline. Fast to run (~10 seconds).
%
% Output figures (saved to docs/training_guide/example_figs/):
%   ex_overview_histograms.png
%   ex_full_experiment_timeseries.png
%   ex_acclimation_period.png
%   ex_percondition_fv.png
%   ex_percondition_av.png
%
% See also: generate_example_figs_group.m (group-level figures, slower)

%% Setup
REPO_ROOT = fileparts(fileparts(fileparts(mfilename('fullpath'))));  % training_guide -> docs -> repo root
run(fullfile(REPO_ROOT, 'setup_path.m'));
cfg = get_config();
PROJECT_ROOT = cfg.project_root;
SAVE_DIR = fullfile(REPO_ROOT, 'docs', 'training_guide', 'example_figs');

if ~isfolder(SAVE_DIR)
    mkdir(SAVE_DIR);
end

%% Load single experiment
disp('=== Loading single experiment ===')

exp_path = fullfile(PROJECT_ROOT, 'data', '2025_03_17', 'protocol_27', ...
    'jfrc100_es_shibire_kir', 'F', '16_33_27');

cd(exp_path)

log_files = dir('LOG_*');
load(fullfile(log_files(1).folder, log_files(1).name), 'LOG');

rec_folder = dir('REC_*');
rec_folder = rec_folder([rec_folder.isdir]);
cd(fullfile(rec_folder(1).folder, rec_folder(1).name))

rec_name = rec_folder(1).name;
load(strcat(rec_name, '-feat.mat'), 'feat');
load(strcat(rec_name, '_JAABA/trx.mat'), 'trx');

strain   = 'jfrc100_es_shibire_kir';
sex      = 'F';
protocol = 'protocol_27';
save_str = '2025-03-17_16-33-27_jfrc100_es_shibire_kir_protocol_27_F';

%% Combine data and compute metrics
disp('Computing behavioral metrics...')
n_flies_in_arena = length(trx);
[comb_data, feat, trx] = combine_data_one_cohort(feat, trx);
disp(['Flies tracked: ' num2str(length(trx)) ' / ' num2str(n_flies_in_arena)])

%% Figure 1: Overview histograms
if ~isfile(fullfile(SAVE_DIR, 'ex_overview_histograms.png'))
    disp('Generating overview histograms...')
    f = make_overview(comb_data, strain, sex, protocol);
    exportgraphics(f, fullfile(SAVE_DIR, 'ex_overview_histograms.png'), 'Resolution', 300);
    close(f)
else
    disp('Skipping ex_overview_histograms.png (already exists)')
end

%% Figure 2: Full experiment timeseries
if ~isfile(fullfile(SAVE_DIR, 'ex_full_experiment_timeseries.png'))
    disp('Generating full experiment timeseries...')
    f = plot_all_features_filt(LOG, comb_data, protocol, save_str);
    f.Position = [6 289 1321 757];
    exportgraphics(f, fullfile(SAVE_DIR, 'ex_full_experiment_timeseries.png'), 'Resolution', 300);
    close(f)
else
    disp('Skipping ex_full_experiment_timeseries.png (already exists)')
end

%% Figure 3: Acclimation period
if ~isfile(fullfile(SAVE_DIR, 'ex_acclimation_period.png'))
    disp('Generating acclimation figure...')
    f = plot_all_features_acclim(LOG, comb_data, save_str);
    exportgraphics(f, fullfile(SAVE_DIR, 'ex_acclimation_period.png'), 'Resolution', 300);
    close(f)
else
    disp('Skipping ex_acclimation_period.png (already exists)')
end

%% Figures 4-5: Per-condition tuning (forward and angular velocity)
if ~isfile(fullfile(SAVE_DIR, 'ex_percondition_fv.png')) || ...
        ~isfile(fullfile(SAVE_DIR, 'ex_percondition_av.png'))
    disp('Generating per-condition tuning plots...')

    if ~isfield(comb_data, 'dist_trav')
        comb_data.dist_trav = comb_data.vel_data / 30;  % FPS = 30
    end

    DATA_single = comb_data_one_cohort_cond(LOG, comb_data, protocol);

    % comb_data_one_cohort_cond wraps output in a 'none' level; unwrap it
    for sf = fieldnames(DATA_single)'
        sn = sf{1};
        if isfield(DATA_single.(sn), 'none')
            DATA_single.(sn) = DATA_single.(sn).none;
        end
    end

    strain = check_strain_typos(strain);

    if ~isfile(fullfile(SAVE_DIR, 'ex_percondition_fv.png'))
        f = plot_allcond_onecohort_tuning(DATA_single, sex, strain, 'fv_data', 1);
        exportgraphics(f, fullfile(SAVE_DIR, 'ex_percondition_fv.png'), 'Resolution', 300);
        close(f)
    end

    if ~isfile(fullfile(SAVE_DIR, 'ex_percondition_av.png'))
        f = plot_allcond_onecohort_tuning(DATA_single, sex, strain, 'av_data', 1);
        exportgraphics(f, fullfile(SAVE_DIR, 'ex_percondition_av.png'), 'Resolution', 300);
        close(f)
    end
else
    disp('Skipping per-condition tuning plots (already exist)')
end

close all

%% Done
disp('=== Single-experiment figures complete ===')
disp(['Saved to: ' SAVE_DIR])
dir(fullfile(SAVE_DIR, 'ex_overview*.png'))
dir(fullfile(SAVE_DIR, 'ex_full*.png'))
dir(fullfile(SAVE_DIR, 'ex_acclim*.png'))
dir(fullfile(SAVE_DIR, 'ex_percond*.png'))
