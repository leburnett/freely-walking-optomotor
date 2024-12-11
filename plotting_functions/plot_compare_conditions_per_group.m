% Plots for protocol_10

protocol_dir = '/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_10';
cd(protocol_dir);

DATA = comb_data_across_cohorts_cond(protocol_dir);

experimental_groups = {
    'csw1118', 'none', 'F';
    'csw1118', 'none', 'M';
    'jfrc49_es_kir', 'attP2', 'F';
    'jfrc49_es_kir', 'attP2', 'M';
    'jfrc49_es_kir', 'attP6', 'F';
    'jfrc49_es_kir', 'attP6', 'M'; % none at the moment.
    'jfrc100_es_shibire', 'attP5', 'F';
    'jfrc100_es_shibire', 'attP5', 'M';
    'ss324_t4t5_kir', 'attP2', 'F';
    'ss324_t4t5_kir', 'attP2', 'M';
    'ss324_t4t5_shibire', 'attP5', 'F';
    'ss324_t4t5_shibire', 'attP5', 'M';
    'jfrc49_l1l4_kir', 'attP2', 'F';
    'jfrc49_l1l4_kir', 'attP2', 'M';
    'l1l4_jfrc100_shibire', 'attP5', 'F';
    'l1l4_jfrc100_shibire', 'attP5', 'M';
    't4t5_RNAi_control', 'none', 'F';
    't4t5_mmd_RNAi', 'none', 'F';
    't4t5_ttl_RNAi', 'none', 'F';
    };

n_exp_groups = height(experimental_groups);

data_types =  {'dist_data', 'dist_trav', 'heading_data', 'av_data', 'vel_data'};

for gp = 1:n_exp_groups

    strain = experimental_groups{gp, 1};
    landing = experimental_groups{gp, 2};
    sex = experimental_groups{gp, 3};
    
    overlap_cond_save_folder = '/Users/burnettl/Documents/Projects/oaky_cokey/figures/protocol_10/12cond_overlap';
    if ~isfolder(overlap_cond_save_folder)
        mkdir(overlap_cond_save_folder);
    end
 
    % Plot the 6 conditions for each trial length overlapped.
    for typ = [1,2,4] %1:length(data_types)
        data_type = data_types{typ};
        f = plot_mean_sem_12cond_overlap(DATA, strain, landing, sex, data_type);
        saveas(f, fullfile(overlap_cond_save_folder, strcat(strain, '_',landing, '_', sex, '_', data_type, '.png')))
    end 

end 


%% Compare individual conditions across the different experimental groups:

% csw1118 F, M and L1L4
% gps2plot = [1,2,7];

% % csw1118 F , ES Kir, ES Shibire
% gps2plot = [1,3,4];

% % csw1118 F , T4T5 Kir, T4T5 Shibire
% gps2plot = [1,5,6];

% Plot all of the experimental groups.
% gps2plot = [1:1:7];

% RNA + control 
% gps2plot = [1,8, 9, 10];

cond_across_grps_save_folder = '/Users/burnettl/Documents/Projects/oaky_cokey/figures/protocol_10/12cond_groups';
if ~isfolder(cond_across_grps_save_folder)
    mkdir(cond_across_grps_save_folder);
end

gp2 = [1,2,7; 1,3,4; 1,5,6];
group_titles = {'CS_L1L4', 'CS_ES', 'CS_T4T5'};
% group_titles = {'csw1118', 'RNAi_control', 'RNAi_mmd', 'RNAi_ttl'};

for gps = 1:3
    gps2plot = gp2(gps, :);
    titl = group_titles{gps};

    for typ = 2:length(data_types)
        data_type = data_types{typ};
        
        plot_sem = false;

        f2 = plot_mean_sem_12cond_groups(DATA, data_type, gps2plot, plot_sem);
        saveas(f2, fullfile(cond_across_grps_save_folder, strcat(titl, '_', data_type, '.png')))
    end 

end 












