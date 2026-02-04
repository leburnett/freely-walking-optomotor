% PLOT_COMPARE_CONDITIONS_PER_GROUP - Compare behavioral responses across groups and conditions
%
% SCRIPT CONTENTS:
%   - Section 1: Load DATA and define experimental groups (strains)
%   - Section 2: Compare multiple groups to same conditions (X-group plots)
%   - Section 3: Compare single group to multiple conditions (X-condition plots)
%   - Section 4: Generate scatter/box plots per condition per group
%   - Section 5: Generate line plots for tuning curves (spatial frequency)
%
% DESCRIPTION:
%   This is the main analysis script for comparing behavioral responses across
%   different experimental groups (strains) and stimulus conditions. It supports
%   multiple protocol types (10, 14, 19, 21, 22, 24, 25, 27, 28, 29, 30) and
%   generates timeseries plots, tuning curves, and summary statistics.
%
% EXPERIMENTAL GROUPS DEFINED:
%   - csw1118: Wild-type Canton-S/w1118
%   - jfrc100_es_shibire_kir: Empty Split control (Shibire/Kir)
%   - ss324_t4t5_shibire_kir: T4/T5 silenced
%   - l1l4_jfrc100_shibire_kir: L1/L4 silenced
%   - ss26283_H1_shibire_kir: H1 silenced
%   - ss01027_H2_shibire_kir: H2 silenced
%   - ss1209_DCH_VCH_shibire_kir: DCH/VCH silenced
%   - ss34318_Am1_shibire_kir: Am1 silenced
%   - t4t5_RNAi_control: T4T5 RNAi control
%
% DATA TYPES ANALYZED:
%   - fv_data, av_data, curv_data, dist_data, dist_data_delta
%
% REQUIREMENTS:
%   - DATA struct from comb_data_across_cohorts_cond
%   - Functions: plot_allcond_acrossgroups_tuning, scatter_boxchart_per_cond_per_grp,
%     scatter_boxchart_per_cond_one_grp, line_per_cond_one_grp
%
% See also: comb_data_across_cohorts_cond, plot_allcond_acrossgroups_tuning

protocol_dir = '/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_30';
cd(protocol_dir);

if contains(protocol_dir, '/') % Mac
    strs = split(protocol_dir, '/');
elseif contains(protocol_dir, '\') % Windows
    strs = split(protocol_dir, '\');
end 

protocol = strs(end);

if protocol == "protocol_14"
    DATA = comb_data_across_cohorts_cond_v14(protocol_dir);
elseif protcol == "protocol_25"
    DATA = comb_data_across_cohorts_cond_v25(protocol_dir);
else 
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end 

% % % % % Screen strains:
gp_data = {
    'csw1118', 'F', [0.7 0.7 0.7], 1; %[0.85 0.4 0.7]
    'jfrc100_es_shibire_kir', 'F', [0.7 0.7 0.7], 2; %[0.85 0.4 0.7] [0.7 0.7 0.7]
    'ss324_t4t5_shibire_kir', 'F', [0.6 0.8 0.6], 3;
    'l1l4_jfrc100_shibire_kir', 'F', [0.4 0.8 1], 4;
    'ss26283_H1_shibire_kir', 'F', [0.8, 0 , 0], 5;
    'ss01027_H2_shibire_kir', 'F', [0.8, 0.4, 0], 6;
    'ss1209_DCH_VCH_shibire_kir', 'F', [0.52, 0.12, 0.57], 7; % purple
    'ss34318_Am1_shibire_kir', 'F', [1, 0.85, 0], 8; % gold
    't4t5_RNAi_control', 'F', [0.7, 0.7, 0.7], 9; %[0.9, 0.5, 0]
    'test', 'F', [0.2 0.2 0.2], 10; % Test flies 
    };

% gp_data = {
%     'jfrc49_es_kir', 'none', 'F',  [0.51 0.32 0.57], 1; % % % % 
%     'jfrc100_es_shibire', 'attP2', 'F', [0.85 0.4 0.7], 2; % % % %
%     'ss324_t4t5_kir', 'none', 'F', [0 0.4 0], 3;
%     'ss324_t4t5_shibire', 'attP5', 'F', [0.6 0.8 0.6], 3;
%     'jfrc49_l1l4_kir', 'none', 'F', [0.2 0.4 0.7], 5;
%     'l1l4_jfrc100_shibire', 'attP5', 'F', [0.4 0.8 1], 6;
%     };

% % % % RNAi flies:
% gp_data = {'t4t5_RNAi_control', 'none', 'F', [0.9, 0.5, 0], 1;
%     't4t5_mmd_RNAi', 'none', 'F', [0.8, 0 , 0], 2;
%     't4t5_ttl_RNAi', 'none', 'F', [0.9, 0.5, 0], 3};

%% Compare the responses of multiple experimental groups to the same condition. 
% Generate a plot of multiple different conditions - as above - but with
% different coloured lines for the different experimental groups: 

% The indices of the different groups to plot: 
close all
% gps2plot = [3, 7]; % ES Kir versus ES Shibire kir
% gps2plot = [9, 13]; % T4T5 Kir versus T4T5 Shibire kir
% gps2plot = [15, 26]; % L1L4 Kir versus L1L4 Shibire kir

% gps2plot= [7, 13, 26]; % compare 3 dbl effectors
% gps2plot= [3, 9, 15]; % compare 3 kir effectors

% gps2plot = 1:6;
% gps2plot = [1,3,5];
% gps2plot = [2,3,6];
gps2plot = [2,3,4];

grp_title = "ES_CS";

% Store figures in folders of the day that they were created too. Can go
% back and look at previous versions. 
date_str = string(datetime('now','TimeZone','local','Format','yyyy_MM_dd'));

% If saving the figures - create a folder to save them in:
Xgrp_save_folder = strcat('/Users/burnettl/Documents/Projects/oaky_cokey/figures/', protocol, "/Xgrp/", date_str);
if ~isfolder(Xgrp_save_folder)
    mkdir(Xgrp_save_folder);
end

%Save the groups that were used for the plots
writecell(gp_data, fullfile(Xgrp_save_folder,'group_data.txt'), 'Delimiter', ';')

% P 10
% 
% cond_titles = {"60deg-gratings-2s-64fps" ...
%     , "60deg-gratings-15s-127fps" ...
%     , "60deg-gratings-15s-64fps" ...
%     , "60deg-gratings-2s-127fps" ...
%     , "30deg-gratings-2s-64fps" ...
%     , "30deg-gratings-15s-127fps" ...
%     , "30deg-gratings-15s-64fps" ...
%     , "30deg-gratings-2s-127fps" ...
%     , "15deg-gratings-2s-64fps" ...
%     , "15deg-gratings-15s-127fps" ...
%     , "15deg-gratings-15s-64fps" ...
%     , "15deg-gratings-2s-127fps" ...
%     };

% P 19
% cond_titles = {"60deg gratings - 4Hz"...
%     , "60deg gratings - 8Hz"...
%     , "ON curtain - 4Hz"...
%     , "ON curtain - 8Hz"...
%     , "OFF curtain - 4Hz"...
%     , "OFF curtain - 8Hz"...
%     , "2pix ON bar - 4Hz"...
%     , "2pix ON bar - 8Hz"...
%     , "2pix OFF bar - 4Hz"...
%     , "2pix OFF bar - 8Hz"...
%     , "15deg gratings - 4Hz"...
%     , "15deg gratings - 8Hz"...
%     };

% P21
% cond_titles = {"60deg gratings - 4Hz"...
%     , "60deg gratings - 8Hz"...
%     , "30deg gratings - 8Hz"...
%     , "30deg gratings - 16Hz"...
%     , "ON curtain - 1Hz"...
%     , "ON curtain - 2Hz"...
%     , "OFF curtain - 1Hz"...
%     , "OFF curtain - 2Hz"...
%     , "60deg flicker - 2Hz"...
%     , "60deg flicker - 4Hz"...
%     };

% P 22
% cond_titles = {"OFF bar fixation"...
%     , "ON bar fixation"...
%     , "30deg-ReversePhi - 1px step"...
%     , "30deg-ReversePhi - 4px step"...
%     , "30deg-ReversePhi - 8px step"...
%     , "30deg-FoE"...
%     , "15deg-FoE"...
%     , "60deg-FoE"...
%     };

% P 24
% cond_titles = {"60deg-gratings-4Hz"...
%     , "60deg-gratings-8Hz"...
%     , "narrow-ON-bars-4Hz"...
%     , "narrow-OFF-bars-4Hz"...
%     , "ON-curtains-8Hz"...
%     , "OFF-curtains-8Hz"...
%     , "reverse-phi-2Hz"...
%     , "reverse-phi-4Hz"...
%     , "60deg-flicker-4Hz"...
%     , "60deg-flicker-8Hz"...
%     % , "32px-bar-ON"...
%     % , "32px-bar-OFF"...
%     };

% P 25
cond_titles = {"60deg-gratings-4Hz"...
    , "60deg-gratings-8Hz"...
    , "60deg-flicker-4Hz"...
    , "60deg-flicker-8Hz"...
    };

% P 27 / 29
% cond_titles = {"60deg-gratings-4Hz"...
%     , "60deg-gratings-8Hz"...
%     , "narrow-ON-bars-4Hz"...
%     , "narrow-OFF-bars-4Hz"...
%     , "ON-curtains-8Hz"...
%     , "OFF-curtains-8Hz"...
%     , "reverse-phi-2Hz"...
%     , "reverse-phi-4Hz"...
%     , "60deg-flicker-4Hz"...
%     , "60deg-gratings-static"...
%     , "60deg-gratings-0-8-offset"...
%     , "32px-ON-single-bar"...
%     };

% P28 
% cond_titles = {"rev-phi-8pxbar-4pxstep-0-3-8"...
%     , "rev-phi-8pxbar-4pxstep-0-3-7"...
%     , "rev-phi-16pxbar-4pxstep-0-3-7"...
%     , "rev-phi-8pxbar-8pxstep-0-3-7"...
%     , "rev-phi-8pxbar-8pxstep-0-2-7"...
%     };

%Save the groups that were used for the plots
writecell(cond_titles, fullfile(Xgrp_save_folder,'cond_titles.txt'), 'Delimiter', ';')

plot_sem = 1;

% data_types =  {'fv_data', 'av_data', 'curv_data', 'dist_data', 'dist_data_delta', 'dist_data_fv', 'dist_trav', 'heading_data', 'vel_data'};
data_types =  {'fv_data', 'av_data', 'curv_data', 'dist_data', 'dist_data_delta'};

% For protocol 19 - ON / OFF
for typ = 1:5
    data_type = data_types{typ};
    % Data in time series are downsampled by 10.
    f_xgrp = plot_allcond_acrossgroups_tuning(DATA, gp_data, cond_titles, data_type, gps2plot, plot_sem);
    f_xgrp.Position = [ 1   744   507   303];
    % f_scbox = scatter_boxchart_per_cond_per_grp(DATA, gp_data, cond_titles, data_type, gps2plot);
    % save as a PDF - 'Padding' option only for MATLAB online.
    % fname = fullfile(Xgrp_save_folder, strcat(join(string(gps2plot), "-"), '_', data_type) + ".pdf");
    % fname = fullfile(Xgrp_save_folder, strcat(grp_title, '_', data_type, ".pdf"));
    % exportgraphics(f_xgrp ...
    %     , fname ...
    %     , 'ContentType', 'vector' ...
    %     , 'BackgroundColor', 'none' ...
    %     ); 
end

% % For protocol 10:
% if protocol == "protocol_10"
%     for typ = 1:4
%         data_type = data_types{typ};
%         f_xgrp = plot_mean_sem_12cond_groups(DATA, data_type, gps2plot, plot_sem);
%         savefig(f_xgrp, fullfile(Xgrp_save_folder, strcat(join(string(gps2plot), "-"), '_', data_type)));
%     end 
% end 



%% Compare the responses of a single experimental group to multiple conditions:
% ACROSS CONDITIONS
% 
% n_exp_groups = height(gp_data);
% 
% data_types =  {'fv_data', 'av_data', 'curv_data', 'dist_data', 'dist_trav', 'heading_data', 'vel_data'};
% 
% Xcond_save_folder = strcat('/Users/burnettl/Documents/Projects/oaky_cokey/figures/', protocol, "/Xcond");
% if ~isfolder(Xcond_save_folder)
%     mkdir(Xcond_save_folder);
% end
% 
% gp = 1; % csw1118 females
% 
% strain = gp_data{gp, 1};
% landing = gp_data{gp, 2};
% sex = gp_data{gp, 3};
% 
% if protocol == "protocol_14"
%     % - - - protocol 14 - different interval stimuli
%     for typ = 1:4
%         data_type = data_types{typ};
%         f_xcond = plot_mean_sem_12cond_overlap_diff_intervals(DATA, strain, landing, sex, data_type);
%         savefig(f_xcond, fullfile(Xcond_save_folder, strcat(strain, '_',landing, '_', sex, '_', data_type)))
%     end 
% elseif protocol == "protocol_19"
%     for typ = 1:4
%         data_type = data_types{typ};
%         % - - - protocol 19 - ON / OFF stimuli
%         % Compare each stimuli at the 2 speeds - 5 x 1 plot. 2 speeds overlaid. 
%         % f_speed_overlap = plot_mean_sem_cond_overlap_protocol19(DATA, strain, landing, sex, data_type);
% 
%         % Compare all stimuli at the same speed. 1 x 2 plot for the 4Hz & 8Hz
%         % stimuli. 
%         f_xcond = plot_mean_sem_overlap_2speeds_v19(DATA, strain, landing, sex, data_type);
%         % savefig(f_xcond, fullfile(Xcond_save_folder, strcat(strain, '_',landing, '_', sex, '_', data_type)))
%     end 
% else
%     for typ = 1:4
%         data_type = data_types{typ};
%         % - - - other protocols - must be based on protocol 10 condition structure:
%         f_xcond = plot_mean_sem_12cond_overlap(DATA, strain, landing, sex, data_type);
%         savefig(f_xcond, fullfile(Xcond_save_folder, strcat(strain, '_',landing, '_', sex, '_', data_type)))
%     end 
% end 

%% For running through multiple groups:
% 
% for gp = 1:n_exp_groups
% 
%     strain = gp_data{gp, 1};
%     landing = gp_data{gp, 2};
%     sex = gp_data{gp, 3};
% 
%     overlap_cond_save_folder = '/Users/burnettl/Documents/Projects/oaky_cokey/figures/protocol_10/12cond_overlap';
%     if ~isfolder(overlap_cond_save_folder)
%         mkdir(overlap_cond_save_folder);
%     end
% 
%     % Plot the 6 conditions for each trial length overlapped.
%     for typ = [1,2,4] %1:length(data_types)
%         data_type = data_types{typ};
%         f = plot_mean_sem_12cond_overlap(DATA, strain, landing, sex, data_type);
%         saveas(f, fullfile(overlap_cond_save_folder, strcat(strain, '_',landing, '_', sex, '_', data_type, '.png')))
%     end 
% 
% end 
% 
% gp_data = {
    % 'csw1118', 'none', 'F', [0.7 0.7 0.7], 1; 
    % 'csw1118', 'none', 'M', [0.7 0.7 0.7], 2;
    % 'jfrc49_es_kir', 'none', 'F',  [0.51 0.32 0.57], 3;
    % 'jfrc49_es_kir', 'none', 'M',  [0.51 0.32 0.57], 4;
    % 'jfrc49_es_kir', 'attP6', 'F',  [0.31 0.12 0.37], 5;
    % 'jfrc49_es_kir', 'attP6', 'M',  [0.31 0.12 0.37], 6;
    % 'jfrc100_es_shibire_kir', 'attP2', 'F', [0.85 0.4 0.7], 7;
    % 'jfrc100_es_shibire', 'none', 'M', [0.85 0.4 0.7], 8;
    % 'ss324_t4t5_kir', 'none', 'F', [0 0.4 0], 9;
    % 'ss324_t4t5_kir', 'none', 'M', [0 0.4 0], 10;
    % 'ss324_t4t5_shibire', 'attP5', 'F', [0.6 0.8 0.6], 11;
    % 'ss324_t4t5_shibire', 'attP5', 'M', [0.6 0.8 0.6], 12;
    % 'ss324_t4t5_shibire_kir', 'none', 'F', [0.6 0.8 0.6], 13;
    % 'ss324_t4t5_shibire_kir', 'none', 'M', [0, 0, 0], 14;
    % 'jfrc49_l1l4_kir', 'none', 'F', [0.2 0.4 0.7], 15;
    % 'jfrc49_l1l4_kir', 'none', 'M', [0.2 0.4 0.7], 16;
    % 'jfrc49_l1l4_kir', 'attP6', 'F', [0.4 0.6 1], 17; 
    % 'jfrc49_l1l4_kir', 'attP6', 'M', [0.4 0.6 1], 18; 
    % 'jfrc49_l1l4_kir', 'VK00005', 'F', [0.1 0.2 0.5], 19;
    % 'jfrc49_l1l4_kir', 'VK00005', 'M', [0.1 0.2 0.5], 20;
    % 'l1l4_jfrc100_shibire', 'attP5', 'F', [0.4 0.8 1], 21;
    % 'l1l4_jfrc100_shibire', 'attP5', 'M', [0.4 0.8 1], 22;
    % 't4t5_RNAi_control', 'none', 'F', [0.9, 0.5, 0], 23; %[0.7 0.7 0.7]
    % 't4t5_mmd_RNAi', 'none', 'F', [0.8, 0 , 0], 24;
    % 't4t5_ttl_RNAi', 'none', 'F', [0.9, 0.5, 0], 25;
    % 'l1l4_jfrc100_shibire_kir', 'none', 'F', [0.4 0.8 1], 26;
    % 'l1l4_jfrc100_shibire_kir', 'none', 'M', [0.4 0.8 1], 27;
    % 'ss26283_H1_shibire_kir', 'none', 'F', [0.8, 0 , 0], 28;
    % 'ss01027_H2_shibire_kir', 'none', 'F', [0.9, 0.5, 0], 29;
    % };


%% 
gps2plot = [2,5,6];
data_type = "curv_data";
f_all_gps = scatter_boxchart_per_cond_per_grp(DATA, gp_data, cond_titles, data_type, gps2plot);

%% For protocol 10 - BOX PLOTS - different conditions - one experimental group

grp2plot = 6; 

% protocol 10 
% cond2plot = [11,10,7,6,3,2]; % 15s duration - 15 to 60 deg - slow, fast. 
% cond2plot = [9,12,5,8,1,4]; % 2s duration

% protocol 19
% cond2plot = [3,4,5,6,11,12,9,10,7,8,1,2];

% protocol 21
% cond2plot = [3,4,5,6];

% protocol 24
cond2plot = 1:10;

data_type = "dist_data_delta";
f_scatter_xcond = scatter_boxchart_per_cond_one_grp(DATA, gp_data, data_type, grp2plot, cond2plot);
ylim([0 300])

%% For protocol 10 - LINE PLOTS

% % % 15s duration:
% slow - 15, 30, 60 = [3,7,11];
% fast - 15, 30, 60 = [2,6,10];

% % % 2s duration:
% slow - 15, 30, 60 = [1, 5, 9];
% fast - 15, 30, 60 = [4,8,12];

% grp2plot = 2;

%% 15s duration 

% Kir flies
figure
for grp2plot = [1,3,5]

    cond2plot = [11,7,3];
    fast_slow = "slow";
    f = line_per_cond_one_grp(DATA, gp_data, data_type, grp2plot, cond2plot, fast_slow);
    
    cond2plot = [10,6,2];
    fast_slow = "fast";
    line_per_cond_one_grp(DATA, gp_data, data_type, grp2plot, cond2plot, fast_slow);
end 

% Shibire flies

figure
for grp2plot = [2,4,6]

    cond2plot = [11,7,3];
    fast_slow = "slow";
    f = line_per_cond_one_grp(DATA, gp_data, data_type, grp2plot, cond2plot, fast_slow);
    
    cond2plot = [10,6,2];
    fast_slow = "fast";
    line_per_cond_one_grp(DATA, gp_data, data_type, grp2plot, cond2plot, fast_slow);
end 


%% 2s duration 

figure
for grp2plot = [1,3,5]

    cond2plot = [9,5,1];
    fast_slow = "slow";
    f = line_per_cond_one_grp(DATA, gp_data, data_type, grp2plot, cond2plot, fast_slow);
    
    cond2plot = [12,8,4];
    fast_slow = "fast";
    line_per_cond_one_grp(DATA, gp_data, data_type, grp2plot, cond2plot, fast_slow);
end 


figure
for grp2plot = [2,4,6]

    cond2plot = [9,5,1];
    fast_slow = "slow";
    f = line_per_cond_one_grp(DATA, gp_data, data_type, grp2plot, cond2plot, fast_slow);
    
    cond2plot = [12,8,4];
    fast_slow = "fast";
    line_per_cond_one_grp(DATA, gp_data, data_type, grp2plot, cond2plot, fast_slow);
end 

%% For a single group: 
grp2plot = 2;

figure
cond2plot = [11,7,3];
fast_slow = "slow";
f = line_per_cond_one_grp(DATA, gp_data, data_type, grp2plot, cond2plot, fast_slow);

cond2plot = [10,6,2];
fast_slow = "fast";
line_per_cond_one_grp(DATA, gp_data, data_type, grp2plot, cond2plot, fast_slow);

ylim([-40 0])
% hold on 
% plot([0 4], [60 60], 'k', 'LineWidth', 0.5)