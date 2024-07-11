% Script to run functions from for freely walking optotmotor experiments

path_to_folder = '/Users/burnettl/Documents/Janelia/HMS_2024/DATA/2024_06_17';
save_figs = false;
genotype = 'csw1118';
save_folder = '/Users/burnettl/Documents/Janelia/HMS_2024/RESULTS'; %'/Users/hms/Documents/Fly Tracking';

% Generate plots for angular velocity analysis
process_freely_walking_optomotor_ang_vel(path_to_folder, save_figs, genotype)

% Generate plots for velocity analysis
process_freely_walking_optomotor_vel(path_to_folder, save_figs, save_folder, genotype)











