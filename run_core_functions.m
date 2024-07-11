% Script to run functions for freely walking optotmotor experiments. Summer
% 2024. 

%% PARAMETERS 

path_to_folder = '/Users/burnettl/Documents/Janelia/HMS_2024/DATA/2024_06_26';

save_figs = false;
genotype = 'csw1118';
save_folder = '/Users/burnettl/Documents/Janelia/HMS_2024/RESULTS'; %'/Users/hms/Documents/Fly Tracking';

fig_save_folder = fullfile(save_folder, "figures");
if ~isfolder(figure_save_folder)
        mkdir(figure_save_folder);
end

data_save_folder = fullfile(save_folder, "data");
if ~isfolder(data_save_folder)
        mkdir(data_save_folder);
end

mean_med = "mean";

%% FUNCTIONS

% Generate plots for angular velocity analysis
process_freely_walking_optomotor_ang_vel(path_to_folder, save_figs, fig_save_folder, data_save_folder, genotype, mean_med)

% Generate plots for velocity analysis
process_freely_walking_optomotor_vel(path_to_folder, save_figs, fig_save_folder, data_save_folder, genotype, mean_med)

% Generate plots where flies are pooled across timepoints (ZT).

plot_line_ang_vel_for_zt(save_figs, fig_save_folder, mean_med)











