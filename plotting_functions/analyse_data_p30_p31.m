
%% Protocol 30 analysis

protocol_dir = '/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_31';
cd(protocol_dir);

DATA = comb_data_across_cohorts_cond(protocol_dir);

% strain = "jfrc100_es_shibire_kir";
strain = "ss00297_Dm4_shibire_kir";
data_types = {'av_data', 'fv_data', 'dist_data', 'dist_data_delta'};
plot_sem = 0;

for d = 1:4

    data_type = data_types{d};
    
    % f1 = plot_timeseries_diff_contrasts_1strain(DATA, strain, data_type, plot_sem);
    
    col = [1 0.5 0];
    f2 = plot_errorbar_tuning_curve_diff_contrasts(DATA, strain, col, data_type);
end 


%% Plot both strains over each other. 
close
data_type = "fv_data";

strains = {"jfrc100_es_shibire_kir", "ss00297_Dm4_shibire_kir"};
for st = [1,2]

    strain = strains{st};

    if st == 1
        col = [0 0.5 1];
    else
        col = [1 0.5 0];
    end 
     
    f2 = plot_errorbar_tuning_curve_diff_contrasts(DATA, strain, col, data_type);
    hold on
end 


%% Protocol 31 analysis

% strain = "ss00297_Dm4_shibire_kir";
strain = "jfrc100_es_shibire_kir";
data_types = {'av_data', 'fv_data', 'dist_data', 'dist_data_delta'};

for d = 1:4
    data_type = data_types{d};
    % figure
    f3 = plot_errorbar_tuning_diff_speeds(DATA, strain, data_type);
end 


%% 
close
data_type = "dist_data_delta";
strains = {"jfrc100_es_shibire_kir", "ss00297_Dm4_shibire_kir"};
for st = [1,2]

    strain = strains{st};
    f3 = plot_errorbar_tuning_diff_speeds(DATA, strain, data_type);

end 