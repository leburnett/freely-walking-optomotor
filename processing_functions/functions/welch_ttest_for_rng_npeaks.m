function [p_npeaks, mean_peaks_per_strain, mean_peaks_per_strain_control, p_pp, mean_pp_per_strain, mean_pp_per_strain_control] = welch_ttest_for_rng_npeaks(cond_data, cond_data_control, rng)

% Used with turning rate - "curv_data" - find the number of peaks > 40 deg
% mm -1, data has already been smoothed over 0.5s time windows. 

% TARGET 

    d = cond_data(:, rng);

    % Find the number of peaks per rep, then find the average number of
    % peaks across the two reps per fly. 
    n_reps = size(d,1);

    npeaks_per_rep = zeros(n_reps, 1);
    pp_per_rep = zeros(n_reps, 1);

    for f = 1:n_reps
        [pks, ~, ~, p] = findpeaks(d(f, :), 'MinPeakProminence', 40);
        npeaks_per_rep(f, 1) = numel(pks);
        pp_per_rep(f, 1) = mean(p);
    end 
    
    npeaks_per_fly = mean_every_two_rows(npeaks_per_rep);
    pp_per_fly = mean_every_two_rows(pp_per_rep);

    mean_peaks_per_strain = nanmean(npeaks_per_fly); % single value. 
    mean_pp_per_strain = nanmean(pp_per_fly);

% CONTROL

    d2 = cond_data_control(:, rng);

    % Find the number of peaks per rep, then find the average number of
    % peaks across the two reps per fly. 
    n_reps = size(d2,1);

    npeaks_per_rep = zeros(n_reps, 1);
    pp_per_rep = zeros(n_reps, 1);

    for f = 1:n_reps
        [pks, ~, ~, p] = findpeaks(d2(f, :), 'MinPeakProminence', 40);
        npeaks_per_rep(f, 1) = numel(pks);
        pp_per_rep(f, 1) = mean(p);
    end 
    
    npeaks_per_fly_control = mean_every_two_rows(npeaks_per_rep);
    pp_per_fly_control = mean_every_two_rows(pp_per_rep);

    mean_peaks_per_strain_control = nanmean(npeaks_per_fly_control); % single value. 
    mean_pp_per_strain_control = nanmean(pp_per_fly_control);


% STATS

    % Number of peaks - Unpaired t-test with unequal group sizes (Welch's t-test)
    [~, p_npeaks] = ttest2(npeaks_per_fly, npeaks_per_fly_control, 'Vartype','unequal');

    % Peak prominence - Unpaired t-test with unequal group sizes (Welch's t-test)
    [~, p_pp] = ttest2(pp_per_fly, pp_per_fly_control, 'Vartype','unequal');

end 