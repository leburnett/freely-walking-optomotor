% STATS_WITHIN_GROUP - Within-group repeated measures ANOVA for condition comparisons
%
% SCRIPT CONTENTS:
%   - Section 1: Load DATA and specify strain/sex to analyze
%   - Section 2: Extract per-fly mean values for each condition
%   - Section 3: Build data table for repeated measures ANOVA
%   - Section 4: Perform repeated measures ANOVA (Table 1: conditions 1-8)
%   - Section 5: Perform repeated measures ANOVA (Table 2: conditions 5-12)
%   - Section 6: Post-hoc pairwise comparisons with Bonferroni correction
%   - Section 7: Save statistical results
%
% DESCRIPTION:
%   This script performs within-group statistical analysis to determine if
%   there are significant differences in behavioral responses across different
%   stimulus conditions within a single strain. It uses repeated measures ANOVA
%   since the same flies are tested under multiple conditions.
%
% PROTOCOL 10 CONDITIONS:
%   Columns: [spatial_freq, temporal_freq, contrast]
%   - Conditions 1-8: Various combinations of 60deg, 30deg, 15deg gratings
%   - Different temporal frequencies (4Hz, 8Hz)
%   - Different contrast levels (2, 15)
%
% STATISTICAL METHODS:
%   - Repeated measures ANOVA (fitrm + ranova)
%   - Post-hoc pairwise comparisons with Bonferroni correction
%
% REQUIREMENTS:
%   - DATA struct from comb_data_across_cohorts_cond
%   - Statistics and Machine Learning Toolbox
%
% OUTPUTS:
%   - stats_results struct containing:
%     - T1, T2: data tables for different condition subsets
%     - ranova results and p-values
%     - pairwise comparison results
%   - Saved to: results/stats/within_group/
%
% See also: fitrm, ranova, multcompare, comb_data_across_cohorts_cond

clear

protocol_dir = '/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_10';
cd(protocol_dir);

DATA = comb_data_across_cohorts_cond(protocol_dir);

% _______________________________________________________________________

% 1 - Specify which strain/sex you want to look at:
strain = 'ss324_t4t5_shibire';
sex = 'F';

% Extract only the data from those experiments:
data = DATA.(strain).(sex); 

% Condition parameters. 
params =[0, 0, 0;
        1, 1, 1;
        60, 4, 2;
        60, 8, 15;
        60, 4, 15;
        60, 8, 2;
        30, 4, 2;
        30, 8, 15;
        30, 4, 15;
        30, 8, 2;
        15, 4, 2;
        15, 8, 15;
        15, 4, 15;
        15, 8, 2;
        ];

% _______________________________________________________________________
%  1 - Is there a significant difference in the clustering of flies to
%  different conditions?

data_type = 'dist_data';

% Find out the total number of flies that were used.
n_exp = length(data);
total_flies = 0;

% Calculate the total number of flies in this experimental group:
for idx = 1:n_exp
    n_flies = size(data(idx).acclim_off1.(data_type), 1);
    total_flies = total_flies + n_flies;
end

fly_data = NaN(total_flies, 14);
data_type = 'dist_data';
curr_n = 0;

for exp = 1:n_exp
    % disp(strcat('Exp - ', string(exp)))

    n_flies = size(data(exp).acclim_off1.(data_type), 1);
    for i = 1:n_flies
        % disp(strcat('Fly - ', string(i)))

        % acclim_off
        d_fly = data(exp).acclim_off1.(data_type);
        fly_data(i+curr_n, 1) = nanmean(d_fly(i, :));
    
        % acclim_patt
        d_fly = data(exp).acclim_patt.(data_type);
        fly_data(i+curr_n, 2) = nanmean(d_fly(i, :));
    
        for cond = 1:12
            % disp(strcat('Cond - ', string(cond)))

            % clear data arrays
            f1_data = [];
            f2_data = [];
            f_data = [];

            rep1_str = strcat('R1_condition_', string(cond));   
            rep2_str = strcat('R2_condition_', string(cond)); 
            % Check for the existence of data from this condition for this
            % fly.
            rep1_data = data(exp).(rep1_str);
            if ~isempty(rep1_data)
                rep1_data = rep1_data.(data_type);
                rep2_data = data(exp).(rep2_str).(data_type);
                
                % if data_type == "dist_data"
                    f1_data = rep1_data(i, 450:900);
                    f2_data = rep2_data(i, 450:900);
                % else
                %     f1_data = rep1_data(i, :);
                %     f2_data = rep2_data(i, :);
                % end 

                f_data = vertcat(f1_data, f2_data);
                fly_data(i+curr_n, cond+2) = nanmean(nanmean(f_data));
            end 
        end
    end 
    curr_n = curr_n+n_flies;

end 

T = array2table(fly_data, 'VariableNames', {'Acclim_off', 'Acclim_patt', 'Cond1', 'Cond2', 'Cond3', 'Cond4', 'Cond5', 'Cond6', 'Cond7', 'Cond8', 'Cond9', 'Cond10', 'Cond11', 'Cond12'});

stats_results = struct();
stats_results.params = params;

comp_type = 'bonferroni';

% _______________________________________________________________________
% Table 1 - conditions 1-8

T1 = rmmissing(T, 1, 'DataVariables', {'Cond1', 'Cond2', 'Cond3', 'Cond4' });
T1 = rmmissing(T1, 2);
stats_results.T1.data = T1;

M1 = mean(T1);
stats_results.T1.mean = M1; 

n_flies1 = height(T1);
stats_results.T1.n_flies = n_flies1; 

Meas1 = table(categorical([1:10]'), 'VariableNames', {'Condition'});
rm1 = fitrm(T1, 'Acclim_off-Cond8~ 1', 'WithinDesign', Meas1);
ranovaResults1 = ranova(rm1);
stats_results.T1.ranova = ranovaResults1;
stats_results.T1.p_value = ranovaResults1.pValue(1);

stats_results.T1.comp_type = comp_type;
if ranovaResults1.pValue(1) < 0.05
    pairwiseResults1 = multcompare(rm1, 'Condition', 'ComparisonType', comp_type); % or 'tukey-kramer', 'sidak', etc.
    pairwiseResults1 = sortrows(pairwiseResults1, 'pValue', 'ascend');
    % Remove duplicate rows for inverse comparisons.
    pairwiseResults1(1:2:end,:) = [];
    stats_results.T1.pairwise = pairwiseResults1;
end

% _______________________________________________________________________
% Table 2 - conditions 5-12

T2 = rmmissing(T, 1, 'DataVariables', {'Cond9', 'Cond10', 'Cond11', 'Cond12'});
T2 = rmmissing(T2, 2);
stats_results.T2.data = T2;

M2 = mean(T2);
stats_results.T2.mean = M2; 

n_flies2 = height(T2);
stats_results.T2.n_flies = n_flies2; 

Meas2 = table([1,2,7,8,9,10,11,12,13,14]', 'VariableNames', {'Condition'});
rm2 = fitrm(T2, 'Acclim_off-Cond12~ 1', 'WithinDesign', Meas2);
ranovaResults2 = ranova(rm2);
stats_results.T2.ranova = ranovaResults2;
stats_results.T2.p_value = ranovaResults2.pValue(1);

stats_results.T1.comp_type = comp_type;
if ranovaResults2.pValue(1) < 0.05
    pairwiseResults2 = multcompare(rm2, 'Condition', 'ComparisonType', comp_type); % or 'tukey-kramer', 'sidak', etc.
    pairwiseResults2 = sortrows(pairwiseResults2, 'pValue', 'ascend');
    % Remove duplicate rows for inverse comparisons.
    pairwiseResults2(1:2:end,:) = [];
    stats_results.T2.pairwise = pairwiseResults2;
end

% _______________________________________________________________________

save_folder = '/Users/burnettl/Documents/Projects/oaky_cokey/results/stats/within_group';
if ~isfolder(save_folder)
    mkdir(save_folder);
end
save_str = strcat('STATS_', strain, '_', sex, '_', data_type, '.mat');
save(fullfile(save_folder, save_str), 'stats_results')







