%% Protocol 31 analysis
% Updated different speeds protocol.

% This script contains the functions to plot both the timeseries and a
% tuning curve for the different speeds for a single strain and
% comparing across strains.

protocol_dir = '/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_31';
cd(protocol_dir);

DATA = comb_data_across_cohorts_cond(protocol_dir);
exp_data = generate_exp_data_struct(DATA);

%% Plot both strains on top of each other.

% strains = {"jfrc100_es_shibire_kir", "ss00297_Dm4_shibire_kir"};
% strains = {"jfrc100_es_shibire_kir", "ss02360_Dm4_shibire_kir"};
% strains = {"jfrc100_es_shibire_kir", "ss00326_Pm2ab_shibire_kir"};
strains = {"jfrc100_es_shibire_kir", "ss324_t4t5_shibire_kir"};
% strains = {"jfrc100_es_shibire_kir", "l1l4_jfrc100_shibire_kir"};
data_types = {'av_data', 'dist_data_delta'};

close all
for dt = 1:numel(data_types)
    data_type = data_types{dt};
    figure
    for st = [1,2]
        strain = strains{st};
        f3 = plot_errorbar_tuning_diff_speeds(DATA, strain, data_type);
    end 
    if data_type == "gain"
        ylim([-0.2 1])
    end 
end 


% For AV plot
% hold on
% plot([1, 2,3,4,5], [0, 60, 120, 240, 480], '--', 'Color', [0.2 0.2 0.2], 'LineWidth', 1.2)
% plot(2, 60, 'k.', 'MarkerSize', 18)
% plot(3, 120, 'k.', 'MarkerSize', 18)
% plot(4, 240, 'k.', 'MarkerSize', 18)

% plot(5, 480, 'k.', 'MarkerSize', 18)


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