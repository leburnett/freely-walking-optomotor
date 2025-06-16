
ROOT_DIR = '/Users/burnettl/Documents/Projects/oaky_cokey';

protocol = "protocol_31";
protocol_dir = fullfile(ROOT_DIR, "results", protocol);
cd(protocol_dir);

DATA = comb_data_across_cohorts_cond(protocol_dir);

% strain = "jfrc100_es_shibire_kir";
strain = "ss00297_Dm4_shibire_kir";
% strain = "ss02360_Dm4_shibire_kir";
% strain = "ss00326_Pm2ab_shibire_kir";
% strain = "l1l4_jfrc100_shibire_kir";
% strain = "ss324_t4t5_shibire_kir";
% strain = "ss1209_DCH_VCH_shibire_kir";

% condition_n = 1:4;

for condition_n = [1,2,4,6,7,9]

    save_folder = fullfile(ROOT_DIR, "figures", "trajectories", protocol, strain, string(condition_n));
    if ~isfolder(save_folder)
        mkdir(save_folder);
    end
    
    plot_traj_subplot(DATA, strain, condition_n, save_folder)
    
end 



