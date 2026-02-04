% COMPARE_DIFF_INTERVAL_STIMULI - Compare behavioral responses to different interval stimuli
%
% SCRIPT CONTENTS:
%   - Section 1: Load combined data from Protocol 14
%   - Section 2: Plot timeseries with stimulus periods highlighted
%   - Section 3: Parse data by condition (contrast levels, grating directions)
%   - Section 4: Perform repeated measures ANOVA across conditions
%   - Section 5: Post-hoc pairwise comparisons with Bonferroni correction
%
% DESCRIPTION:
%   This script analyzes Protocol 14 data to compare fly behavioral responses
%   to different interval stimuli. It extracts distance from center data,
%   groups responses by stimulus condition (acclimation, gratings, flicker,
%   static, all-on, all-off), and performs statistical comparisons.
%
% PROTOCOL 14 CONDITIONS:
%   - acclim_off: no stimulus (contrast = 0)
%   - acclim_on: pattern displayed, no motion (contrast = 1, dir = 0)
%   - gratings: moving gratings (contrast = 1, dir != 0)
%   - flicker: contrast = 1.2
%   - static: contrast = 1.3
%   - allon: contrast = 1.4
%   - alloff: contrast = 1.5
%
% REQUIREMENTS:
%   - combine_data_across_exp function
%   - plot_pink_blue_rects function
%   - LOG struct with stimulus timing information
%
% OUTPUTS:
%   - cond_data: table of per-fly mean values per condition
%   - ranovaResults1: repeated measures ANOVA results
%   - pairwiseResults1: post-hoc pairwise comparison results
%
% See also: combine_data_across_exp, plot_pink_blue_rects, fitrm, ranova, multcompare

clear

path_to_data = '/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_14/csw1118/M';
combined_data = combine_data_across_exp(path_to_data);

data = combined_data.dist_data;

figure
plot_pink_blue_rects(LOG, 'protocol_14', 0, 90)
hold on
plot(mean(data), 'k', 'LineWidth', 2)

% Data 
cond_data = [];

for cond = 1:7

    if cond == 1 
        rows = find(LOG.Log.contrast == 0);
    elseif cond == 2
        rows = find(LOG.Log.contrast == 1 & LOG.Log.dir == 0);
    elseif cond == 3
        rows = find(LOG.Log.contrast == 1 & LOG.Log.dir ~= 0);
    elseif cond == 4
        rows = find(LOG.Log.contrast == 1.2);
    elseif cond == 5
        rows = find(LOG.Log.contrast == 1.3);
    elseif cond == 6
        rows = find(LOG.Log.contrast == 1.4);
    elseif cond == 7
        rows = find(LOG.Log.contrast == 1.5);
    end 

    d_comb = [];
    for j = 1:numel(rows)
        r = rows(j);
        st_f = LOG.Log.start_f(r);
        if st_f ==0 
            st_f = 1;
        end 
        stp_f = LOG.Log.stop_f(r);
        d = data(:,st_f:stp_f);
        d_mean = mean(d,2);
        d_comb = horzcat(d_comb, d_mean);
    end 

    d_comb_mean = mean(d_comb,2);
    cond_data = horzcat(cond_data, d_comb_mean);

end 

T = array2table(cond_data, 'VariableNames', {'acclim_off', 'acclim_on', 'gratings', 'flicker', 'static', 'allon', 'alloff'});

% Meas1 = table(categorical([1:6]'), 'VariableNames', {'Condition'});
Meas1 = table(categorical({'acclim_off', 'acclim_on', 'gratings', 'flicker', 'static', 'allon', 'alloff'}'), 'VariableNames', {'Condition'});
rm1 = fitrm(T, 'acclim_off-alloff~ 1', 'WithinDesign', Meas1);
ranovaResults1 = ranova(rm1);

comp_type = 'bonferroni';
pairwiseResults1 = multcompare(rm1, 'Condition', 'ComparisonType', comp_type); % or 'tukey-kramer', 'sidak', etc.
pairwiseResults1 = sortrows(pairwiseResults1, 'pValue', 'ascend');
pairwiseResults1(2:2:end,:) = [];


%% 












