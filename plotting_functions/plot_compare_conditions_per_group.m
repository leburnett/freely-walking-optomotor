% Plots for protocol_10

protocol_dir = '/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_10';
cd(protocol_dir);

DATA = comb_data_across_cohorts_cond(protocol_dir);

% Load in the data for all protocol_10 experiments. 
% files = dir('*.mat');
% load(files(1).name, 'DATA')

strain = 'ss324_t4t5_shibire';
sex = 'F';

% Potentially run through all of the available folders. 

% all_cond_save_folder = '/Users/burnettl/Documents/Projects/oaky_cokey/figures/protocol_10/12cond';
% if ~isfolder(all_cond_save_folder)
%     mkdir(all_cond_save_folder);
% end
% 
% % All 12 conditions plotted individually:
% f = plot_mean_sem_12cond(DATA, strain, sex);
% saveas(f, fullfile(all_cond_save_folder, strcat(strain, '_', sex, '.png')))


overlap_cond_save_folder = '/Users/burnettl/Documents/Projects/oaky_cokey/figures/protocol_10/12cond_overlap';
if ~isfolder(overlap_cond_save_folder)
    mkdir(overlap_cond_save_folder);
end

% Plot the 6 conditions for each trial length overlapped.
f2 = plot_mean_sem_12cond_overlap(DATA, strain, sex);
saveas(f2, fullfile(overlap_cond_save_folder, strcat(strain, '_', sex, '.png')))















