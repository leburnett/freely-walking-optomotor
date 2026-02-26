function [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_min(cond_data, cond_data_control, rng)
 
    d = cond_data(:, rng);
    % Find the min per each rep first THEN average across reps. 
    d_min = min(d');
    mean_per_fly = mean_every_two_rows(d_min');
    mean_per_strain = mean(mean_per_fly); % single value. 

    d_control = cond_data_control(:, rng);
    % Find the min per each rep first THEN average across reps. 
    d_min_control = min(d_control'); 
    mean_per_fly_control = mean_every_two_rows(d_min_control');
    mean_per_strain_control = mean(mean_per_fly_control); % single value. 

    % Unpaired t-test with unequal group sizes (Welch's t-test)
    [~, p] = ttest2(mean_per_fly, mean_per_fly_control, 'Vartype','unequal');

end 