function [pvals, target_mean, control_mean] = dist_metric_tests(cond_data, cond_data_control, delta)

    % Initialise empty arrays:
    pvals = [];
    target_mean = [];
    control_mean = [];
    
    % Set frame ranges 
    % rng_b4_10 = 1:300;
    rng_int_10 = 1500:1800;
    rng_end_stim_3 = 1110:1200;
    rng_swap_stim_3 = 660:750;

%% 0 - Average minimum distance from the centre of the arena 3s before the stimulus changes direction

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_min(cond_data, cond_data_control, rng_swap_stim_3);

    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];

%% 1 - Average minimum distance from the centre of the arena at the end of the stimulus

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_min(cond_data, cond_data_control, rng_end_stim_3);

    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];

%% 2 - Average minimum distance from the centre of the arena before the stimulus
    % if ~delta
    %     [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_min(cond_data, cond_data_control, rng_b4_10);
    % 
    %     % ADD VALUES
    %     pvals = [pvals, p];
    %     target_mean = [target_mean, mean_per_strain];
    %     control_mean = [control_mean, mean_per_strain_control];
    % end 

%% 3 - Average minimum distance from the centre of the arena at the end of the interval

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_min(cond_data, cond_data_control, rng_int_10);

    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];

end 