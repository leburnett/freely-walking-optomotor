% Script to run functions for freely walking optomotor experiments. 
% June - Aug 2024. 

close all
clear
clc

%% PARAMETERS 

path_to_folder = '/Users/burnettl/Documents/Janelia/HMS_2024/DATA/2024_06_26';

save_figs = true;
genotype = 'CSw1118';
save_folder = '/Users/burnettl/Documents/Janelia/HMS_2024/RESULTS'; %'/Users/hms/Documents/Fly Tracking';

fig_save_folder = fullfile(save_folder, "figures");
if ~isfolder(fig_save_folder)
    mkdir(fig_save_folder);
end

ang_data_save_folder = fullfile(save_folder, "data/angvel");
if ~isfolder(ang_data_save_folder)
    mkdir(ang_data_save_folder);
end

vel_data_save_folder = fullfile(save_folder, "data/vel");
if ~isfolder(vel_data_save_folder)
    mkdir(vel_data_save_folder);
end

ratio_data_save_folder = fullfile(save_folder, "data/ratio");
if ~isfolder(ratio_data_save_folder)
    mkdir(ratio_data_save_folder);
end

% mean_med = "median";
% 
% %% 1 - Generate plots for each individual experiment - i.e per cohort  - for all cohorts from that day: 
% 
% % Generate plots for angular velocity analysis
% process_freely_walking_optomotor_ang_vel(path_to_folder, save_figs, fig_save_folder, ang_data_save_folder, genotype, mean_med)
% 
% % Generate plots for velocity analysis
% process_freely_walking_optomotor_vel(path_to_folder, save_figs, fig_save_folder, vel_data_save_folder, genotype, mean_med)
% 
%% Ang vel / vel ratio 

mean_med = "med";

process_freely_walking_optomotor_ang_vel_ratio(path_to_folder, save_figs, fig_save_folder, ratio_data_save_folder, genotype, mean_med)

%% 2 - Generate plots for all flies - across time points (ZT)

zt_file = '/Users/burnettl/Documents/Janelia/HMS_2024/zt_conditions.xlsx';

plot_line_ang_vel_for_zt(ang_data_save_folder, zt_file, save_figs, fig_save_folder, mean_med)

plot_line_vel_for_zt(vel_data_save_folder, zt_file, save_figs, fig_save_folder, mean_med)5

plot_line_ang_vel_ratio_for_zt(ratio_data_save_folder, zt_file, save_figs, save_folder, mean_med)







