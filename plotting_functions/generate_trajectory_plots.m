
ROOT_DIR = '/Users/burnettl/Documents/Projects/oaky_cokey';

protocol = "protocol_31";
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

for condition_n = 1 %[1,2,4,6,7,9]

    save_folder = fullfile(ROOT_DIR, "figures", "trajectories", protocol, strain, string(condition_n));
    if ~isfolder(save_folder)
        mkdir(save_folder);
    end
    
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