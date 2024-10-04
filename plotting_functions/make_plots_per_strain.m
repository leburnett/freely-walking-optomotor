function make_plots_per_strain(data_folder)
% Generate pdf with a number of different plots using the combined data
% from all experiments from a particular fly strain and for a particular
% protocol. 

% Inputs
% - - - - 

% data_folder : Path 
% e.g. '/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_v1/JFRC49_ES'
close all

PROJECT_ROOT = '/Users/burnettl/Documents/Projects/oaky_cokey/'; 

% Information about the strain / protocol. 
subfolders = split(data_folder, '/');
sex = subfolders{end};
strain = subfolders{end-1};
protocol = subfolders{end-2};

% Folder to save figs:
results_path = fullfile(PROJECT_ROOT, 'figures');
save_str = strcat('FIG_', strain, '_', sex, '_', protocol);

%% Generate combined velocity data 
combined_data = combine_data_across_exp(data_folder);

% Locomotion overview 
% loco_fig = make_locomotion_overview(combined_data, strain, sex, protocol);

% General overview - full experiment - histograms
figure
overview_fig = make_overview(combined_data, strain, sex, protocol);
% save
fig1_str = strcat(save_str, '_overview');
overview_folder = fullfile(results_path, 'overview');

if ~exist(overview_folder, 'dir')
    mkdir(overview_folder)
end 

savefig(overview_fig, fullfile(overview_folder, fig1_str))

% % % % Figure 2 - line plots
figure
features_fig = plot_features_line(combined_data, strain, sex, protocol);

fig2_str = strcat(save_str, '_features');
features_folder = fullfile(results_path, 'features_line');

if ~exist(features_folder, 'dir')
    mkdir(features_folder)
end

savefig(features_fig, fullfile(features_folder, fig2_str))

end 













