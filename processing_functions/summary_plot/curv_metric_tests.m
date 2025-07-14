function [pvals, target_mean, control_mean] = curv_metric_tests(cond_data, cond_data_control)

    % Initialise empty arrays:
    pvals = [];
    target_mean = [];
    control_mean = [];
    
    % Set frame ranges 
    rng_stim = 300:1200;
    rng_b4 = 1:300;
    rng_int = 1200:1800;

    rng_b4_5 = 150:300;
    rng_int_5 = 1200:1350;

%% Update turning rate - make absolute (we don't care about turing direction) and movmean over 0.5s. 

    cond_data2 = zeros(size(cond_data)); 
    cond_data_control2 = zeros(size(cond_data_control));

    n_flies_target = size(cond_data2, 1);
    n_flies_control = size(cond_data_control2, 1);

    f_window = 15;

    for ff = 1:n_flies_target
        cond_data2(ff, :) = movmean(abs(cond_data(ff, :)), f_window);
    end 

    for ff = 1:n_flies_control
        cond_data_control2(ff, :) = movmean(abs(cond_data_control(ff, :)), f_window);
    end 

%% 1 - Average turning rate during the stimulus.

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data2, cond_data_control2, rng_stim);

    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];

%% 2 - Average turning rate 5s before stimulus

    % [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data2, cond_data_control2, rng_b4_5);
    % 
    % % ADD VALUES
    % pvals = [pvals, p];
    % target_mean = [target_mean, mean_per_strain];
    % control_mean = [control_mean, mean_per_strain_control];

%% 3 - Average turning rate 5s after stimulus - during interval

    [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data2, cond_data_control2, rng_int_5);

    % ADD VALUES
    pvals = [pvals, p];
    target_mean = [target_mean, mean_per_strain];
    control_mean = [control_mean, mean_per_strain_control];


%% 4 - Average number of sharp turns during the stimulus 

    [p_npeaks, mean_peaks_per_strain, mean_peaks_per_strain_control, p_pp, mean_pp_per_strain, mean_pp_per_strain_control] = welch_ttest_for_rng_npeaks(cond_data2, cond_data_control2, rng_stim);

    % ADD VALUES
    pvals = [pvals, p_npeaks, p_pp];
    target_mean = [target_mean, mean_peaks_per_strain, mean_pp_per_strain];
    control_mean = [control_mean, mean_peaks_per_strain_control, mean_pp_per_strain_control];

%% 5 - Average number of sharp turns before the stimulus 

    % [p_npeaks, mean_peaks_per_strain, mean_peaks_per_strain_control, p_pp, mean_pp_per_strain, mean_pp_per_strain_control] = welch_ttest_for_rng_npeaks(movmean(cond_data, f_window), movmean(cond_data_control, f_window), rng_b4);
    % 
    % % ADD VALUES
    % pvals = [pvals, p_npeaks, p_pp];
    % target_mean = [target_mean, mean_peaks_per_strain, mean_pp_per_strain];
    % control_mean = [control_mean, mean_peaks_per_strain_control, mean_pp_per_strain_control];

%% 6 - Average number of sharp turns during the interval 

    [p_npeaks, mean_peaks_per_strain, mean_peaks_per_strain_control, p_pp, mean_pp_per_strain, mean_pp_per_strain_control] = welch_ttest_for_rng_npeaks(movmean(cond_data, f_window), movmean(cond_data_control, f_window), rng_int);

    % ADD VALUES
    pvals = [pvals, p_npeaks, p_pp];
    target_mean = [target_mean, mean_peaks_per_strain, mean_pp_per_strain];
    control_mean = [control_mean, mean_peaks_per_strain_control, mean_pp_per_strain_control];


end 