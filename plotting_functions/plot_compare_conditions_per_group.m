% Generate plots for protocol_10-type protocols: 

protocol_dir = '/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_19';
cd(protocol_dir);

strs = split(protocol_dir, '/');
protocol = strs(end);

if protocol == "protocol_14"
    DATA = comb_data_across_cohorts_cond_v14(protocol_dir);
else 
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end 

gp_data = {
    'csw1118', 'none', 'F', [0.3 0.3 0.3]; % 1
    'csw1118', 'none', 'M', [0.7 0.7 0.7]; % 2
    'jfrc49_es_kir', 'attP2', 'F',  [0.51 0.32 0.57]; % 3
    'jfrc49_es_kir', 'attP2', 'M',  [0.51 0.32 0.57]; % 4  - - none?
    'jfrc49_es_kir', 'attP6', 'F',  [0.31 0.12 0.37]; % 5
    'jfrc49_es_kir', 'attP6', 'M',  [0.31 0.12 0.37]; % 6 - - - none at the moment.
    'jfrc100_es_shibire', 'attP5', 'F', [0.85 0.4 0.7]; % 7
    'jfrc100_es_shibire', 'attP5', 'M', [0.85 0.4 0.7]; % 8
    'ss324_t4t5_kir', 'attP2', 'F', [0 0.4 0]; % 9
    'ss324_t4t5_kir', 'attP2', 'M', [0 0.4 0]; % 10
    'ss324_t4t5_shibire', 'attP5', 'F', [0.6 0.8 0.6]; % 11
    'ss324_t4t5_shibire', 'attP5', 'M', [0.6 0.8 0.6]; % 12
    'ss324_t4t5_shibire_kir', 'none', 'F', [0, 0, 0]; % 13
    'ss324_t4t5_shibire_kir', 'none', 'M', [0, 0, 0]; % 14
    'jfrc49_l1l4_kir', 'attP2', 'F', [0.2 0.4 0.7]; %15
    'jfrc49_l1l4_kir', 'attP2', 'M', [0.2 0.4 0.7]; %16
    'jfrc49_l1l4_kir', 'attP6', 'F', [0.4 0.6 1]; % 17 
    'jfrc49_l1l4_kir', 'attP6', 'M', [0.4 0.6 1]; % 18 
    'jfrc49_l1l4_kir', 'VK00005', 'F', [0.1 0.2 0.5]; %19
    'jfrc49_l1l4_kir', 'VK00005', 'M', [0.1 0.2 0.5]; %20
    'l1l4_jfrc100_shibire', 'attP5', 'F', [0.4 0.8 1]; %21
    'l1l4_jfrc100_shibire', 'attP5', 'M', [0.4 0.8 1]; % 22
    't4t5_RNAi_control', 'none', 'F', [0.7 0.7 0.7]; %23
    't4t5_mmd_RNAi', 'none', 'F', [0.8, 0 , 0]; % 24
    't4t5_ttl_RNAi', 'none', 'F', [0.9, 0.5, 0]; % 25
    };

n_exp_groups = height(gp_data);

data_types =  {'dist_data', 'dist_trav', 'heading_data', 'av_data', 'vel_data'};

%% Compare the responses of a single experimental group to multiple conditions:

gp = 25; % csw1118 females
strain = gp_data{gp, 1};
landing = gp_data{gp, 2};
sex = gp_data{gp, 3};

% Set the data type to be analysed:
typ = 4; 
data_type = data_types{typ};

% Generate the plot:
% Some protocols have different functions:

% - - - protocol 19 - ON / OFF stimuli
f = plot_mean_sem_cond_overlap_protocol19(DATA, strain, landing, sex, data_type);

% - - - protocol 14 - different interval stimuli
f2 = plot_mean_sem_12cond_overlap_diff_intervals(DATA, strain, landing, sex, data_type);

% - - - other protocols - must be based on protocol 10 condition structure:
f3 = plot_mean_sem_12cond_overlap(DATA, strain, landing, sex, data_type);


%% For running through multiple groups:

for gp = 1:n_exp_groups

    strain = gp_data{gp, 1};
    landing = gp_data{gp, 2};
    sex = gp_data{gp, 3};
    
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





%% Compare the responses of multiple experimental groups to the same condition. 
% Generate a plot of multiple different conditions - as above - but with
% different coloured lines for the different experimental groups: 

% The indices of the different groups to plot: 

% csw1118 F, M and L1L4
% gps2plot = [1,2,7];

% % csw1118 F , ES Kir, ES Shibire
% gps2plot = [1,3,4];

% % csw1118 F , T4T5 Kir, T4T5 Shibire
% gps2plot = [1,5,6];

% Plot all of the experimental groups.
% gps2plot = [1:1:7];

% RNA + control 
gps2plot = [23, 24, 25];

% If saving the figures - create a folder to save them in:
    cond_across_grps_save_folder = '/Users/burnettl/Documents/Projects/oaky_cokey/figures/protocol_10/12cond_groups_241212';
    if ~isfolder(cond_across_grps_save_folder)
        mkdir(cond_across_grps_save_folder);
    end

% Condition parameters for protocol 19: 
params =[60, 4, 15; % 60 deg gratings 
        60, 8, 15;
        1, 4, 15; % ON curtain
        1, 8, 15;
        0, 4, 15; % OFF curtain
        0, 8, 15; 
        21, 4, 15; % 2ON 14OFF grating 
        21, 8, 15;
        20, 4, 15; % 2OFF 14ON grating
        20, 8, 15;
        ];

plot_sem = 0;

f5 = plot_allcond_acrossgroups(DATA, gp_data, params, data_type, gps2plot, plot_sem);








% gp2 = [1,2,7; 1,3,4; 1,5,6];
% group_titles = {'CS_L1L4', 'CS_ES', 'CS_T4T5'};
% group_titles = {'csw1118', 'RNAi_control', 'RNAi_mmd', 'RNAi_ttl'};
% 
% for gps = 1:3
%     gps2plot = gp2(gps, :);
%     titl = group_titles{gps};
% 
%     for typ = 2:length(data_types)
%         data_type = data_types{typ};
% 
%         plot_sem = false;
% 
%         f2 = plot_mean_sem_12cond_groups(DATA, data_type, gps2plot, plot_sem);
%         saveas(f2, fullfile(cond_across_grps_save_folder, strcat(titl, '_', data_type, '.png')))
%     end 
% 
% end 


gps2plot = [1, 2]; % l1l4 females

data_types =  {'dist_data', 'dist_trav', 'heading_data', 'av_data', 'vel_data'};

for typ = 1 %2:length(data_types)

    data_type = data_types{typ};
    
    plot_sem = false;

    f2 = plot_mean_sem_12cond_groups(DATA, data_type, gps2plot, plot_sem);
    saveas(f2, fullfile(cond_across_grps_save_folder, strcat(titl, '_', data_type, '.png')))
end 


for typ = 1:length(data_types)
    data_type = data_types{typ};
    plot_sem = false;
    f = plot_mean_sem_diff_intervals(DATA, data_type, plot_sem);
end 





