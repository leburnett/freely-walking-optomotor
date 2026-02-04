% P30_DIFFERENT_CONTRASTS_ANALYSIS - Analyze optomotor responses at different contrasts
%
% SCRIPT CONTENTS:
%   - Section 1: Load DATA and generate experiment data struct
%   - Section 2: Plot timeseries for single strain across contrast conditions
%   - Section 3: Plot tuning curves comparing strains (errorbar plots)
%
% DESCRIPTION:
%   This script analyzes Protocol 30 data which tests optomotor responses
%   at different stimulus contrast levels. It generates timeseries plots
%   showing behavioral responses over time and tuning curves showing how
%   behavioral metrics vary with contrast, comparing different fly strains.
%
% DATA TYPES ANALYZED:
%   - av_data: angular velocity
%   - fv_data: forward velocity
%   - dist_data: distance from center
%   - dist_data_delta: change in distance from center
%   - curv_data: path curvature (turning rate)
%
% STRAINS COMPARED:
%   - jfrc100_es_shibire_kir (Empty Split control)
%   - ss00297_Dm4_shibire_kir (Dm4 silenced)
%   - l1l4_jfrc100_shibire_kir (L1/L4 silenced)
%   - ss00326_Pm2ab_shibire_kir (Pm2ab silenced)
%   - ss324_t4t5_shibire_kir (T4T5 silenced)
%
% REQUIREMENTS:
%   - DATA struct from comb_data_across_cohorts_cond
%   - Functions: generate_exp_data_struct, plot_timeseries_diff_contrasts_1strain,
%     plot_errorbar_tuning_curve_diff_contrasts
%
% See also: comb_data_across_cohorts_cond, plot_timeseries_diff_contrasts_1strain

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

  