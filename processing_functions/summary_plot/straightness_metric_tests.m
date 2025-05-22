function [pvals, target_mean, control_mean] = straightness_metric_tests(x_data, x_data_control, y_data, y_data_control)

    % Initialise empty arrays:
    pvals = [];
    target_mean = [];
    control_mean = [];
    
    % Set frame ranges 
    rng_b4_10 = 1:300;

    rng_stim = 300:1200;
    rng_start_5 = 300:450;
    rng_stim_end_5 = 1050:1200;

    rng_int_5 = 1200:1350;
    rng_int_end_10 = 1500:1800;

%% 1 - Average path straightness before the stimulus 

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_straightness(x_data, x_data_control, y_data, y_data_control, rng_b4_10);
 
    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];

    
%% 2 - Average path straightness during the stimulus 

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_straightness(x_data, x_data_control, y_data, y_data_control, rng_stim);
 
    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];

%% 3 - Average path straightness during the first 5s of the stimulus 

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_straightness(x_data, x_data_control, y_data, y_data_control, rng_start_5);
 
    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];

%% 4 - Average path straightness during the last 5s of the stimulus 

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_straightness(x_data, x_data_control, y_data, y_data_control, rng_stim_end_5);
 
    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];

%% 5 - Average path straightness during the first 5s of the interval 

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_straightness(x_data, x_data_control, y_data, y_data_control, rng_int_5);
 
    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];

%% 6 - Average path straightness during the last 10s of the interval 

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_straightness(x_data, x_data_control, y_data, y_data_control, rng_int_end_10);
 
    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];
end 