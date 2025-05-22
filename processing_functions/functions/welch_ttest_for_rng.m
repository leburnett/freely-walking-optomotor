function [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data, cond_data_control, rng)
 
    d = cond_data(:, rng);
    d2 = mean_every_two_rows(d);
    mean_per_fly = mean(d2, 2); % [n_flies x 1];
    mean_per_strain = nanmean(mean_per_fly); % single value. 

    d_control = cond_data_control(:, rng);
    d2_control = mean_every_two_rows(d_control);
    mean_per_fly_control = mean(d2_control, 2); % [n_flies x 1];
    mean_per_strain_control = nanmean(mean_per_fly_control); % single value. 

    % Unpaired t-test with unequal group sizes (Welch's t-test)
    [~, p] = ttest2(mean_per_fly, mean_per_fly_control, 'Vartype','unequal');

end 