function [pvals, target_mean, control_mean] = av_metric_tests(cond_data, cond_data_control, pre_averaged)

%   pre_averaged (optional, default false): If true, data has 1 row per fly
%   (already rep-averaged). Passed through to Welch test functions.

    if nargin < 3, pre_averaged = false; end

    % Initialise empty arrays:
    pvals = [];
    target_mean = [];
    control_mean = [];

    % Angular velocity (5)
    % Ranges are in seconds. 
    % - (10:40) - mean av over the entire stimulus
    % - (10.5:15) - mean av during first 5s of CW
    % - (10-25) - av during CW
    % - (25:30) - mean av during first 5s of CCW
    % - (25:40) - av during CCW  

%% Make versions of data with CCW gratings values *-1.

    cond_data2 = cond_data;
    cond_data_control2 = cond_data_control;

    % Flip sign of second half of stimulus so that all angular velocities
    % are +ve 
    cond_data2(:, 762:1210) = cond_data2(:, 762:1210)*-1;
    cond_data_control2(:, 762:1210) = cond_data_control2(:, 762:1210)*-1;

%% 1 - Average angular velocity during the stimulus.

    rng_stim = 300:1200;
    
    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data2, cond_data_control2, rng_stim, pre_averaged);

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);

%% 2 - Average angular velocity during the first 5s of the CW stimulus.

    % rng_stim_start = 315:450;
    % 
    % % RUN TEST
    % [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data2, cond_data_control2, rng_stim_start);
    % 
    % % ADD VALUES
    % [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);


%% 3 - Average angular velocity during the first 5s of the CCW stimulus.

    % rng_ccw_start = 765:900;
    % 
    % % RUN TEST
    % [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data2, cond_data_control2, rng_ccw_start);
    % 
    % % ADD VALUES
    % [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);



end 