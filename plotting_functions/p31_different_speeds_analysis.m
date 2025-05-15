%% Protocol 31 analysis
% Updated different speeds protocol.

% This script contains the functions to plot both the timeseries and a
% tuning curve for the different speeds for a single strain and
% comparing across strains.

protocol_dir = '/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_31';
cd(protocol_dir);

DATA = comb_data_across_cohorts_cond(protocol_dir);

%% Plot both strains on top of each other.
close
data_type = "curv_data";
strains = {"jfrc100_es_shibire_kir", "ss00297_Dm4_shibire_kir"};

for st = [1,2]

    strain = strains{st};
    f3 = plot_errorbar_tuning_diff_speeds(DATA, strain, data_type);
end 

%% timeseries for different speed experiments

strain = "jfrc100_es_shibire_kir";
% strain = "ss00297_Dm4_shibire_kir";
data_types = {'av_data', 'fv_data', 'dist_data', 'dist_data_delta', 'curv_data'};
plot_sem = 0;

for d = 1:5

    data_type = data_types{d};
    figure
    f4 = plot_timeseries_diff_speeds(DATA, strain, data_type, plot_sem);
    % f3 = plot_errorbar_tuning_diff_speeds(DATA, strain, data_type);
end