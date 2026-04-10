function [pvals, target_mean, control_mean] = dist_metric_tests(cond_data, cond_data_control, dist_type, pre_averaged)
% DIST_METRIC_TESTS Distance metric comparisons between strains.
%
%   pre_averaged (optional, default false): If true, data has 1 row per fly
%   (already rep-averaged). Passed through to Welch test functions.

% dist_type == 1 (absolute distance from the centre)
% dist_type == 2 (relative distance from the centre - distance set to "0" when stimulus starts)
% dist_type == 3 (centring rate)

if nargin < 4, pre_averaged = false; end

% Initialise empty arrays:
pvals = [];
target_mean = [];
control_mean = [];

% Absolute distance from the centre (3)
% - (9:10) - mean absolute distance when/before the stimulus starts. 
% - (39:40) - mean absolute distance when the stimulus ends.
% - (50:55) -  mean absolute distance when the interval ends. 
% 
% Relative distance from the centre (3)
% - 20 - distance moved within the first 10s of the stimulus
% - 40 - distance moved by the end of the stimulus
% -  difference in the absolute distance from the end of the stimulus to
% 10s after the stimulus ends.


if dist_type == 1 % absolute

    % %% 1 - Absolute distance when the stimulus starts
    % rng_at_start = 270:300;
    % 
    % % RUN TEST
    % [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_min(cond_data, cond_data_control, rng_at_start, pre_averaged);
    % 
    % % ADD VALUES
    % [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);

    %% 2 - Absolute distance when the stimulus ends
    rng_at_end = 1170:1200;
    
    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_min(cond_data, cond_data_control, rng_at_end, pre_averaged);

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);


elseif dist_type == 2 % normalised by the position at the beginning of the stimulus

     %% 4 - Relative distance moved after the first 10s of the stimulus.
    % rng_at_10s = 570:600;
    % 
    % % RUN TEST
    % [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_min(cond_data, cond_data_control, rng_at_10s, pre_averaged);
    % 
    % % ADD VALUES
    % [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);

    %% 5 -  Relative distance moved by the end of the stimulus
    rng_at_end = 1170:1200;

    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_min(cond_data, cond_data_control, rng_at_end, pre_averaged);

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);


elseif dist_type == 3 % dist_data_delta_end  - normalised by the position at the end of the stimulus

    %% 6 - Relative distance moved in the first 10s after the stimulus ends.
    rng_end_stim = 1470:1500;

    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_min(cond_data, cond_data_control, rng_end_stim, pre_averaged);

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);


end 

end 