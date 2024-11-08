% Plots for protocol_10

protocol_dir = '/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_10';
cd(protocol_dir);

DATA = comb_data_across_cohorts_cond(protocol_dir);

experimental_groups = {
    'csw1118', 'F';
    'csw1118', 'M';
    'jfrc49_es_kir', 'F';
    'jfrc100_es_shibire', 'F';
    'ss324_t4t5_kir', 'F';
    'ss324_t4t5_shibire', 'F';
    'jfrc49_l1l4_kir', 'F'
    };

n_exp_groups = height(experimental_groups);

for gp = 1:n_exp_groups

    strain = experimental_groups{gp, 1};
    sex = experimental_groups{gp, 2};
    
    % Potentially run through all of the available folders. 
    
    % all_cond_save_folder = '/Users/burnettl/Documents/Projects/oaky_cokey/figures/protocol_10/12cond';
    % if ~isfolder(all_cond_save_folder)
    %     mkdir(all_cond_save_folder);
    % end
    % 
    % % All 12 conditions plotted individually:
    % f = plot_mean_sem_12cond(DATA, strain, sex);
    % saveas(f, fullfile(all_cond_save_folder, strcat(strain, '_', sex, '.png')))
    
    % overlap_cond_save_folder = '/Users/burnettl/Documents/Projects/oaky_cokey/figures/protocol_10/12cond_overlap';
    % if ~isfolder(overlap_cond_save_folder)
    %     mkdir(overlap_cond_save_folder);
    % end
    
    % % Plot the 6 conditions for each trial length overlapped.
    % data_type = 'dist_data';
    % f2 = plot_mean_sem_12cond_overlap(DATA, strain, sex, data_type);
    % % saveas(f2, fullfile(overlap_cond_save_folder, strcat(strain, '_', sex, '.png')))
    % 
    % % Plot the 6 conditions for each trial length overlapped.
    % data_type = 'dist_trav';
    % f3 = plot_mean_sem_12cond_overlap(DATA, strain, sex, 'dist_trav');
    
    data_type = 'heading_data';
    f4a = plot_mean_sem_12cond(DATA, strain, sex, data_type);
    f4b = plot_mean_sem_12cond_overlap(DATA, strain, sex, data_type);

end 

% csw1118 F, M and L1L4
% gps2plot = [1,2,7];

% % csw1118 F , ES Kir, ES Shibire
% gps2plot = [1,3,4];

% % csw1118 F , T4T5 Kir, T4T5 Shibire
gps2plot = [1,5,6];

% gps2plot = [1:1:7];

data_type = 'dist_trav';
plot_sem = false;
f = plot_mean_sem_12cond_groups(DATA, data_type, gps2plot, plot_sem);









