%% Protocol 30 analysis
% Updated different contrasts protocol.

% This script contains the functions to plot both the timeseries and a
% tuning curve for the different contrasts for a single strain and
% comparing across strains.

protocol_dir = '/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_30';
cd(protocol_dir);

DATA = comb_data_across_cohorts_cond(protocol_dir);

exp_data = generate_exp_data_struct(DATA);

%% 
% strain = "jfrc100_es_shibire_kir";
strain = "ss00297_Dm4_shibire_kir";
data_types = {'av_data', 'fv_data', 'dist_data', 'dist_data_delta'};
plot_sem = 0;

for d = 1:4
    figure
    data_type = data_types{d};
    f1 = plot_timeseries_diff_contrasts_1strain(DATA, strain, data_type, plot_sem);

    % col = [1 0.5 0];
    % f2 = plot_errorbar_tuning_curve_diff_contrasts(DATA, strain, col, data_type);
end 


%% Plot both strains over each other. 
close
data_type = "curv_data";

% strains = {"jfrc100_es_shibire_kir", "ss00297_Dm4_shibire_kir"};
strains = {"jfrc100_es_shibire_kir", "l1l4_jfrc100_shibire_kir"};
% strains = {"jfrc100_es_shibire_kir", "ss00326_Pm2ab_shibire_kir"};
% strains = {"jfrc100_es_shibire_kir", "ss324_t4t5_shibire_kir"};

for st = [1,2]

    strain = strains{st};

    if st == 1
         col = [0.8, 0.8, 0.8]/1.2;
    else
        col = [0.9, 0.5, 0.9]/1.5;
    end 
     
    f2 = plot_errorbar_tuning_curve_diff_contrasts(DATA, strain, col, data_type);
    hold on
end 

  