function [pvals, target_mean, control_mean] = curv_metric_tests(cond_data, cond_data_control, pre_averaged)
% CURV_METRIC_TESTS Curvature/turning rate metric comparisons between strains.
%
%   pre_averaged (optional, default false): If true, data has 1 row per fly
%   (already rep-averaged). Passed through to Welch test functions.

    if nargin < 3, pre_averaged = false; end

    % Initialise empty arrays:
    pvals = [];
    target_mean = [];
    control_mean = [];

    % Turning rate (5)
    % Ranges are in seconds. 
    % - (10:40) - mean tr over the entire stimulus
    % - (10.5:15) - mean tr during first 5s of CW
    % - (10-25) - tr during CW
    % - (25:30) - mean tr during first 5s of CCW
    % - (25:40) - tr during CCW 
        
    %% Make versions of data with CCW gratings values *-1.
    % Previously, made turning rate absolute but now, doing similar to AV and
    % just flipping the sign of the CCW responses. Also doing a 0.5s moving
    % mean over this data. 
    
    % A - moving mean 
    cond_data2 = zeros(size(cond_data)); 
    cond_data_control2 = zeros(size(cond_data_control));
    
    n_flies_target = size(cond_data2, 1);
    n_flies_control = size(cond_data_control2, 1);
    
    f_window = 15;
    
    for ff = 1:n_flies_target
        cond_data2(ff, :) = movmean(cond_data(ff, :), f_window);
    end 
    
    for ff = 1:n_flies_control
        cond_data_control2(ff, :) = movmean(cond_data_control(ff, :), f_window);
    end 
    
    % B - flip CCW
    
    % Flip sign of second half of stimulus so that all angular velocities
    % are +ve 
    cond_data2(:, 762:1210) = cond_data2(:, 762:1210)*-1;
    cond_data_control2(:, 762:1210) = cond_data_control2(:, 762:1210)*-1;
    
    % CHECK WHAT THIS LOOKS LIKE. 

%% 1 - Average turning rate during the stimulus.

    rng_stim = 300:1200;
    
    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data2, cond_data_control2, rng_stim, pre_averaged);

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);

%% 2 - Average turning rate during the first 5s of the CW stimulus.

    % rng_stim_start = 315:450;
    % 
    % % RUN TEST
    % [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data2, cond_data_control2, rng_stim_start, pre_averaged);
    % 
    % % ADD VALUES
    % [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);


%% 3 - Average turning rate during the first 5s of the CCW stimulus.

    % rng_ccw_start = 765:900;
    % 
    % % RUN TEST
    % [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data2, cond_data_control2, rng_ccw_start);
    % 
    % % ADD VALUES
    % [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);

 
end 