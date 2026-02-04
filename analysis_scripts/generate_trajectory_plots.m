% GENERATE_TRAJECTORY_PLOTS - Generate fly trajectory visualizations
%
% SCRIPT CONTENTS:
%   - Section 1: Load DATA and generate trajectory subplot grids per condition
%   - Section 2: Plot individual fly trajectories across multiple conditions
%   - Section 3: Plot multiple flies for a single condition (reverse phi)
%   - Section 4: Plot pre/post stimulus split trajectories
%
% DESCRIPTION:
%   This script generates various trajectory visualizations for freely-walking
%   optomotor experiments. It creates subplot grids showing all fly trajectories
%   for a given condition, compares individual fly behavior across conditions,
%   and generates split trajectory plots showing behavior before and after
%   stimulus onset.
%
% REQUIREMENTS:
%   - DATA struct from comb_data_across_cohorts_cond
%   - Plotting functions: plot_traj_subplot, plot_traj_xcond, plot_traj_xflies,
%     plot_traj_pre_post
%
% USAGE:
%   1. Set ROOT_DIR and protocol
%   2. Run comb_data_across_cohorts_cond to generate DATA
%   3. Select strain and condition numbers to visualize
%   4. Execute desired plotting sections
%
% See also: plot_traj_subplot, plot_traj_xcond, plot_traj_xflies, plot_traj_pre_post

ROOT_DIR = '/Users/burnettl/Documents/Projects/oaky_cokey';

protocol = "protocol_35";
protocol_dir = fullfile(ROOT_DIR, "results", protocol);
cd(protocol_dir);

DATA = comb_data_across_cohorts_cond(protocol_dir);

strain = "jfrc100_es_shibire_kir";
% strain = "ss00297_Dm4_shibire_kir";
% strain = "ss02360_Dm4_shibire_kir";
% strain = "ss00326_Pm2ab_shibire_kir";
% strain = "l1l4_jfrc100_shibire_kir";
% strain = "ss324_t4t5_shibire_kir";
% strain = "ss1209_DCH_VCH_shibire_kir";

% condition_n = 1:4;

for condition_n = 7 %[1,2,4,6,7,9]

    save_folder = fullfile(ROOT_DIR, "figures", "trajectories", protocol, strain, string(condition_n));
    % if ~isfolder(save_folder)
    %     mkdir(save_folder);
    % end
    
    plot_traj_subplot(DATA, strain, condition_n, save_folder)
    
end 


%% Trajectory of one fly over different conditions

cond_ids = [10, 9, 1];

% [807, 802, 791, 314, 24, 776, 786, 804, 746, 215, 743, 701, 705, 727, 239]
% [24, 692, 646, 639, 631, 245, 637, 625, 581, 583, 87, 547]
for f = [543, 557, 544, 523, 370, 312, 396, 212, 816, 818, 166]
    plot_traj_xcond(DATA, strain, cond_ids, f)
end 

cond_idx = 10;
fly_ids = [557, 543, 637]; %557

plot_traj_xflies(DATA, strain, cond_idx, fly_ids)
legend off

%% Trajectory for reverse phi

cond_idx = 7;

fly_ids = [716, 611, 524];

plot_traj_xflies(DATA, strain, cond_idx, fly_ids)
legend off


%% Plot example empty split trajectory

cond_idx = 7;

fly_ids = 524;

close
plot_traj_pre_post(DATA, strain, cond_idx, fly_ids)
legend off
