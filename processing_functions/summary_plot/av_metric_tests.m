function [pvals, target_mean, control_mean] = av_metric_tests(cond_data, cond_data_control)

    % Initialise empty arrays:
    pvals = [];
    target_mean = [];
    control_mean = [];
    
    % Set frame ranges 
    rng_stim = 300:1200;
    % rng_b4_5 = 150:300;
    rng_int_5 = 1200:1350;
    
    % rng_b4_1 = 270:300;
    rng_b4_3 = 210:300;
    % rng_stim_1 = 300:330;
    rng_stim_3 = 300:390;
    % rng_stim_end_1 = 1170:1200;
    rng_stim_end_3 = 1110:1200;
    % rng_int_1 = 1200:1230;
    rng_int_3 = 1200:1290;

%% Make versions of data with CCW gratings values *-1.

    cond_data2 = cond_data;
    cond_data_control2 = cond_data_control;
    % Flip sign of second half of stimulus so that all angular velocities
    % are +ve 
    cond_data2(:, 762:1210) = cond_data2(:, 762:1210)*-1;
    cond_data_control2(:, 762:1210) = cond_data_control2(:, 762:1210)*-1;

%% 1 - Average angular velocity during the stimulus.

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data2, cond_data_control2, rng_stim);

    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];

%% 2 - Average angular velocity 5s before stimulus

    % [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data2, cond_data_control2, rng_b4_5);
    % 
    % % ADD VALUES
    % pvals = [pvals, p];
    % target_mean = [target_mean, mean_per_strain];
    % control_mean = [control_mean, mean_per_strain_control];

%% 3 - Average angular velocity 5s after stimulus - during interval

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data2, cond_data_control2, rng_int_5);

    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];


%% 4 - Average change in av in the 1s before the stimulus and the 1s after the stimulus started.

    % [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data2, cond_data_control2, rng_b4_1, rng_stim_1, "rel");
    % 
    % % ADD VALUES
    % pvals = [pvals, p];
    % target_mean = [target_mean, mean_per_strain];
    % control_mean = [control_mean, mean_per_strain_control];

    % [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data2, cond_data_control2, rng_b4_1, rng_stim_1, "norm");
    % 
    % % ADD VALUES
    % pvals = [pvals, p];
    % target_mean = [target_mean, mean_per_strain];
    % control_mean = [control_mean, mean_per_strain_control];


%% 5 - Average change in av in the 3s before the stimulus and the 3s after the stimulus started.

    % [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data2, cond_data_control2, rng_b4_3, rng_stim_3, "rel");
    % 
    % % ADD VALUES
    % pvals = [pvals, p];
    % target_mean = [target_mean, mean_per_strain];
    % control_mean = [control_mean, mean_per_strain_control];

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data2, cond_data_control2, rng_b4_3, rng_stim_3, "norm");

    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];

%% 6 - Average change in av in the 1s before the stimulus stops and the first 1s of the interval.

    % [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data2, cond_data_control2, rng_stim_end_1, rng_int_1, "rel");
    % 
    % % ADD VALUES
    % pvals = [pvals, p];
    % target_mean = [target_mean, mean_per_strain];
    % control_mean = [control_mean, mean_per_strain_control];
    % 
    % [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data2, cond_data_control2, rng_stim_end_1, rng_int_1, "norm");
    % 
    % % ADD VALUES
    % pvals = [pvals, p];
    % target_mean = [target_mean, mean_per_strain];
    % control_mean = [control_mean, mean_per_strain_control];


%% 7 - Average change in av in the 3s before the stimulus stops and the first 3s of the interval.

    % [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data2, cond_data_control2, rng_stim_end_3, rng_int_3, "rel");
    % 
    % % ADD VALUES
    % pvals = [pvals, p];
    % target_mean = [target_mean, mean_per_strain];
    % control_mean = [control_mean, mean_per_strain_control];

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data2, cond_data_control2, rng_stim_end_3, rng_int_3, "norm");

    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];

end 