function [pvals, target_mean, control_mean] = fv_metric_tests(cond_data, cond_data_control)

    % Initialise empty arrays:
    pvals = [];
    target_mean = [];
    control_mean = [];
    
% Periods over which to calculate metrics: 
% Ranges are in seconds. 
% - (0-10s) - fv before
% - (7-10:10-13) - change in fv when the stimulus starts. 
% - (10-13) - absolute fv when stimulus starts
% - (22-25:25-28) - change in fv when CW -> CCW
% - (37:43) - change in fv when stimulus end. 
% - (40:43) - absolute fv when stimulus ends

%% 1 - Average absolute forward velocity before the stimulus (10s).

    rng_baseline = 1:300;

    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data, cond_data_control, rng_baseline);

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);

%% 2 - Average absolute forward velocity during the entire stimulus (30s).

    rng_stim = 300:1200;

    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data, cond_data_control, rng_stim);

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);


%% 3 - Average absolute forward velocity just after the stimulus starts (3s).
    rng_stim_3 = 300:390;

    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data, cond_data_control, rng_stim_3);

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);

%% 4 - Average absolute forward velocity just after the stimulus ends (3s).
    rng_int_3 = 1200:1290;

    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data, cond_data_control, rng_int_3);

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);

%% 5 - Change in average forward velocity (+/- 3s) from when the stimulus starts

    rng_b4_3 = 210:300;
    rng_stim_3 = 300:390;

    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data, cond_data_control, rng_b4_3, rng_stim_3, "norm");

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);

%% 6 - Change in average forward velocity (+/- 3s) from when the stimulus changes direction.

    rng_b4_swap_3 = 660:750;
    rng_after_swap_3 = 750:840;

    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data, cond_data_control, rng_b4_swap_3, rng_after_swap_3, "norm");

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);

%% 7 - Change in average forward velocity (+/- 3s) from when the stimulus stops.

    rng_stim_end_3 = 1110:1200;
    rng_int_3 = 1200:1290;

    % RUN TEST
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data, cond_data_control, rng_stim_end_3, rng_int_3, "norm");

    % ADD VALUES
    [pvals, target_mean, control_mean] = add_pvalues(pvals, target_mean, control_mean, p, mean_per_strain, mean_per_strain_control);


end 