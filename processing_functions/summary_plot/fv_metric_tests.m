function [pvals, target_mean, control_mean] = fv_metric_tests(cond_data, cond_data_control)

    % Initialise empty arrays:
    pvals = [];
    target_mean = [];
    control_mean = [];
    
    % Set frame ranges 
    rng_stim = 300:1200;
    rng_b4_5 = 150:300;
    rng_int_5 = 1200:1350;
    
    rng_b4_1 = 270:300;
    rng_b4_3 = 210:300;
    rng_stim_1 = 300:330;
    rng_stim_3 = 300:390;

    rng_b4_swap_1 = 720:750;
    rng_b4_swap_3 = 660:750;
    rng_after_swap_1 = 750:780;
    rng_after_swap_3 = 750:840;

    rng_stim_end_1 = 1170:1200;
    rng_stim_end_3 = 1110:1200;
    rng_int_1 = 1200:1230;
    rng_int_3 = 1200:1290;

%% 1 - Average forward velocity during the stimulus.

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data, cond_data_control, rng_stim);

    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];

%% 2 - Average forward velocity 5s before stimulus

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data, cond_data_control, rng_b4_5);

    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];

%% 3 - Average forward velocity 5s after stimulus - during interval

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data, cond_data_control, rng_int_5);

    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];


%% 4 - Average change in fv in the 1s before the stimulus and the 1s after the stimulus started.

    % [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data, cond_data_control, rng_b4_1, rng_stim_1, "rel");
    % 
    % % ADD VALUES
    % pvals = [pvals, p];
    % target_mean = [target_mean, mean_per_strain];
    % control_mean = [control_mean, mean_per_strain_control];

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data, cond_data_control, rng_b4_1, rng_stim_1, "norm");

    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];


%% 5 - Average change in fv in the 3s before the stimulus and the 3s after the stimulus started.

    % [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data, cond_data_control, rng_b4_3, rng_stim_3, "rel");
    % 
    % % ADD VALUES
    % pvals = [pvals, p];
    % target_mean = [target_mean, mean_per_strain];
    % control_mean = [control_mean, mean_per_strain_control];

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data, cond_data_control, rng_b4_3, rng_stim_3, "norm");

    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];

%% 6 - Average change in fv - 1s before / after swaps direction

    % [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data, cond_data_control, rng_b4_swap_1, rng_after_swap_1, "rel");
    % 
    % % ADD VALUES
    % pvals = [pvals, p];
    % target_mean = [target_mean, mean_per_strain];
    % control_mean = [control_mean, mean_per_strain_control];

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data, cond_data_control, rng_b4_swap_1, rng_after_swap_1, "norm");

    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];


%% 7 - Average change in fv - 3s before / after swaps direction
    % 
    % [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data, cond_data_control, rng_b4_swap_3, rng_after_swap_3, "rel");
    % 
    % % ADD VALUES
    % pvals = [pvals, p];
    % target_mean = [target_mean, mean_per_strain];
    % control_mean = [control_mean, mean_per_strain_control];

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data, cond_data_control, rng_b4_swap_3, rng_after_swap_3, "norm");

    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];



%% 8 - Average change in fv in the 1s before the stimulus stops and the first 1s of the interval.

    % [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data, cond_data_control, rng_stim_end_1, rng_int_1, "rel");
    % 
    % % ADD VALUES
    % pvals = [pvals, p];
    % target_mean = [target_mean, mean_per_strain];
    % control_mean = [control_mean, mean_per_strain_control];

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data, cond_data_control, rng_stim_end_1, rng_int_1, "norm");

    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];


%% 9 - Average change in fv in the 3s before the stimulus stops and the first 3s of the interval.

    % [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data, cond_data_control, rng_stim_end_3, rng_int_3, "rel");
    % 
    % % ADD VALUES
    % pvals = [pvals, p];
    % target_mean = [target_mean, mean_per_strain];
    % control_mean = [control_mean, mean_per_strain_control];

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data, cond_data_control, rng_stim_end_3, rng_int_3, "norm");

    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];


%% 10 - Proportion of flies whose average fv is < 2 mm s-1 during the stimulus

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_proportion(cond_data, cond_data_control, rng_stim, 2, "less");
    
    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];


%% 11 - Proportion of flies whose average fv is > 20 mm s-1 during the stimulus
    
    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_proportion(cond_data, cond_data_control, rng_stim, 20, "more");
    
    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];

end 