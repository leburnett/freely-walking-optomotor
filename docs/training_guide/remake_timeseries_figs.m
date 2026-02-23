% remake_timeseries_figs.m
% Regenerate only the two timeseries figures that use plot_xcond_per_strain2,
% now that the hardcoded col value has been fixed.

%% Setup paths
REPO_ROOT = '/Users/burnettl/Documents/GitHub/freely-walking-optomotor';
PROJECT_ROOT = '/Users/burnettl/Documents/Projects/oaky_cokey';
SAVE_DIR = fullfile(REPO_ROOT, 'docs', 'training_guide', 'example_figs');

addpath(genpath(fullfile(REPO_ROOT, 'processing_functions')));
addpath(genpath(fullfile(REPO_ROOT, 'plotting_functions')));
addpath(genpath(fullfile(REPO_ROOT, 'misc')));
addpath(genpath(fullfile(REPO_ROOT, 'analysis_scripts')));

%% Figure 1: Speed comparison timeseries (protocol_31)
disp('=== Remaking speed comparison timeseries (protocol_31) ===')

protocol_dir_31 = fullfile(PROJECT_ROOT, 'results', 'protocol_31');
DATA_31 = comb_data_across_cohorts_cond(protocol_dir_31);

cond_ids = [1,2,3,4];
data_type = "dist_data_delta";
protocol = "protocol_31";
strain = "jfrc100_es_shibire_kir";
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
disp('ex_speed_comparison_timeseries.png saved.')

%% Figure 2: Cross-condition timeseries (protocol_27)
disp('=== Remaking cross-condition timeseries (protocol_27) ===')

protocol_dir_27 = fullfile(PROJECT_ROOT, 'results', 'protocol_27');
DATA_27 = comb_data_across_cohorts_cond(protocol_dir_27);

cond_ids = [1,7];
data_type = "av_data";
protocol = "protocol_27";
strain = "jfrc100_es_shibire_kir";
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
disp('ex_xcond_timeseries.png saved.')

close all
disp('=== Done remaking timeseries figures ===')
