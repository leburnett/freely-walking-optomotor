% Script to run functions from for freely walking optotmotor experiments

path_to_folder = '/Users/burnettl/Documents/Janelia/HMS_2024/DATA/2024_06_26';
% Folders to save figures and data
figure_save_folder = '/Users/burnettl/Documents/Janelia/HMS_2024/RESULTS/Figures';
data_save_folder = '/Users/burnettl/Documents/Janelia/HMS_2024/RESULTS/ProcessedData';
save_figs = false;
genotype = 'csw1118';

process_freely_walking_optomotor(path_to_folder, figure_save_folder, data_save_folder, save_figs, genotype)

plot_line_ang_vel_for_zt(save_figs, 'mean')

plot_line_ang_vel_for_zt(save_figs, 'median')


