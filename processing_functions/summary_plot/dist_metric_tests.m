function [pvals, target_mean, control_mean] = dist_metric_tests(cond_data, cond_data_control, dist_type)

% dist_type == 1 (absolute distance from the centre)
% dist_type == 2 (relative distance from the centre - distance set to "0" when stimulus starts)
% dist_type == 3 (centring rate)

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
% - 55 - distance during interval after stimulus. (Returned?)
% 
% Centring rate (5)
% - 11-40 - mean centring during stimulus 
% - 11:14 - mean initial centring rate when stimulus starts (3s)
% - 11:25 - mean centring during CW
% - 26:40 - mean centring during CCW
% - 40-45 - mean centring during 5s after stim stops.

if dist_type == 1 % absolute


    %% 1 - Absolute distance when the stimulus starts
    rng_at_start = 270:300;
    
    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_min(cond_data, cond_data_control, rng_at_start);

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);

    %% 2 - Absolute distance when the stimulus ends
    rng_at_end = 1170:1200;
    
    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_min(cond_data, cond_data_control, rng_at_end);

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);

    %% 3 - Absolute distance when the interval ends
    rng_end_int = 1770:1800;
    
    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_min(cond_data, cond_data_control, rng_end_int);

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);


elseif dist_type == 2 % relative

     %% 4 - Relative distance moved after the first 10s of the stimulus.
    rng_at_10s = 570:600;
    
    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_min(cond_data, cond_data_control, rng_at_10s);

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);

    %% 5 -  Relative distance moved by the end of the stimulus
    rng_at_end = 1170:1200;

    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_min(cond_data, cond_data_control, rng_at_end);

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);

    %% 6 -  Relative distance moved by the end of the interval (rebound back?)
    rng_end_int = 1770:1800;
    
    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_min(cond_data, cond_data_control, rng_end_int);

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);

elseif dist_type == 3 % centring rate

    %% 7 - Mean rate of centring during the entire stimulus
    rng_stim = 315:1200;

    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data, cond_data_control, rng_stim);

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);

    %% 8 - Mean rate of centring within the first 3s of the stimulus. 
    rng_immed = 315:405; % 3s with 0.5s delay from start.

    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data, cond_data_control, rng_immed);

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);

    %% 9 - Mean rate of centring during the CW stimulus 
    rng_cw = 315:750;

    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data, cond_data_control, rng_cw);

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);

    %% 10 - Mean rate of centring during the CCW stimulus 
    rng_ccw = 765:1200;

    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data, cond_data_control, rng_ccw);

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);

    %% 11 -  Mean rate of centring during the 5s after the stimulus stops.
    rng_stim_end = 1215:1305;

    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data, cond_data_control, rng_stim_end);

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);



end 

end 