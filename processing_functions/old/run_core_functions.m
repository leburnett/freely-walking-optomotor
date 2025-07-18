% Script to run functions for freely walking optomotor experiments. 
% June - Aug 2024. 

close all
clear
clc

%% Initialise fixed paths.
PROJECT_ROOT = '/Users/burnettl/Documents/Projects/oaky_cokey/';
data_path = fullfile(PROJECT_ROOT, 'data');
results_path = fullfile(PROJECT_ROOT, 'results');

date_to_analyse = '2024_08_02';
path_to_folder = fullfile(data_path, date_to_analyse);

save_figs = false; % Save the figures that are generated? 
genotype = 'CSw1118';
save_folder = fullfile(results_path, genotype);

%% 

% Generate scripts that ONLY process the data and output the processed data
% for velocity, angular velocity, distance from centre, angvel/vel. 




% Find the mean 'mean' or the median 'med'
mean_med = "med";

fig_save_folder = fullfile(save_folder, "figures");
if ~isfolder(fig_save_folder)
    mkdir(fig_save_folder);
end

ang_data_save_folder = fullfile(save_folder, "data/angvel/post_HM");
if ~isfolder(ang_data_save_folder)
    mkdir(ang_data_save_folder);
end

vel_data_save_folder = fullfile(save_folder, "data/vel/post_HM");
if ~isfolder(vel_data_save_folder)
    mkdir(vel_data_save_folder);
end

ratio_data_save_folder = fullfile(save_folder, "data/ratio");
if ~isfolder(ratio_data_save_folder)
    mkdir(ratio_data_save_folder);
end

dcentre_data_save_folder = fullfile(save_folder, "data/distcentre");
if ~isfolder(dcentre_data_save_folder)
    mkdir(dcentre_data_save_folder);
end

%% 1 - Generate plots for each individual experiment - i.e per cohort  - for all cohorts from that day: 
% and create results files that will be used for the plotting functions in section 2. 

% % % Generate plots for angular velocity analysis
process_freely_walking_optomotor_ang_vel(path_to_folder, save_figs, fig_save_folder, ang_data_save_folder, genotype, mean_med)
% 
% % % Generate plots for velocity analysis
process_freely_walking_optomotor_vel(path_to_folder, save_figs, fig_save_folder, vel_data_save_folder, genotype, mean_med)
% 
% % process angle versus displacement ratio
% % process_freely_walking_optomotor_ang_vel_ratio(path_to_folder, save_figs, fig_save_folder, ratio_data_save_folder, genotype, mean_med)
% 
% % process distance from the centre. 
process_freely_walking_optomotor_dist_centre(path_to_folder, dcentre_data_save_folder, genotype)

%% 2 - Generate plots for all flies - across time points (ZT)

% zt_file = '/Users/burnettl/Documents/Janelia/HMS_2024/zt_conditions.xlsx';
% 
% % What to use for errorbars
% % Can only take "STD", "SEM" or "CI"
% ebar = "IQR";
% 
% % Plot the average angular velocity per contrast per zt condition.
% % Normalised to the ang vel at the first 1.0 contrast condition. 
% plot_line_ang_vel_ratio_for_zt_normalised(ratio_data_save_folder, zt_file, save_figs, fig_save_folder, mean_med, ebar)
% 
% % % Plot the unnormalised version: 
% plot_line_ang_vel_for_zt(ang_data_save_folder, zt_file, save_figs, fig_save_folder, mean_med, ebar)
% 
% % Plot the velocity per constrast per zt condition
% plot_line_vel_for_zt(vel_data_save_folder, zt_file, save_figs, fig_save_folder, mean_med, ebar)


%% For generating plots for the different protocols

% data_path = '/Users/burnettl/Documents/Janelia/HMS_2024/RESULTS/data/distcentre/protocol_v6/cond_val_3/SS324_motionblind_females';
data_path = '/Users/burnettl/Documents/Janelia/HMS_2024/RESULTS/data/distcentre/protocol_v1/empty_split_females';

save_figs = false;

save_folder = '/Users/burnettl/Documents/Janelia/HMS_2024/RESULTS'; %'/Users/hms/Documents/Fly Tracking';

% 1 - Distance to centre

fig_save_folder = fullfile(save_folder, "figures");
dist_fig_save_path = fullfile(fig_save_folder, 'dist2centre');
if ~isfolder(dist_fig_save_path)
    mkdir(dist_fig_save_path);
end

plot_line_dist_from_centre(data_path, save_figs, dist_fig_save_path, 'mean')

% 2 -  Velocity 

% data_path = '/Users/burnettl/Documents/Janelia/HMS_2024/RESULTS/data/vel/protocol_v1';
data_path = '/Users/burnettl/Documents/Janelia/HMS_2024/RESULTS/data/vel/protocol_v1/post-HM/ES_JFRC49';

mean_med = 'med';

plot_line_velocity(data_path, save_figs, '', mean_med)


% 3 - Ang vel
vel_or_ang = "ang";
plot_line_velocity(data_path, save_figs, fig_save_path, mean_med, vel_or_ang)

