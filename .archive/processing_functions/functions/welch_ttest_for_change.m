function [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data, cond_data_control, rng1, rng2, rel_or_norm)
    
    % TARGET 

    % During range 1 - before 
    d_1 = cond_data(:, rng1);
    d2_1 = mean_every_two_rows(d_1);
    mean_per_fly_1 = nanmean(d2_1, 2); % [n_flies x 1];

    % During range 2 - after
    d_2 = cond_data(:, rng2);
    d2_2 = mean_every_two_rows(d_2);
    mean_per_fly_2 = nanmean(d2_2, 2); % [n_flies x 1];

    if rel_or_norm == "rel"
        % Relative change
        fold_change_per_fly = mean_per_fly_2./mean_per_fly_1;
        valid_idx = ~isnan(fold_change_per_fly) & ~isinf(fold_change_per_fly);
        fold_change_per_fly = fold_change_per_fly(valid_idx);

    elseif rel_or_norm == "norm"
        % Normalised change
        norm_diff_per_fly = (mean_per_fly_2 - mean_per_fly_1) ./ (mean_per_fly_2 + mean_per_fly_1);
    end 

    % CONTROL 

    % During range 1 - before 
    d_1c = cond_data_control(:, rng1);
    d2_1c = mean_every_two_rows(d_1c);
    mean_per_fly_1c = nanmean(d2_1c, 2); % [n_flies x 1];

    % During range 2 - after
    d_2c = cond_data_control(:, rng2);
    d2_2c = mean_every_two_rows(d_2c);
    mean_per_fly_2c = nanmean(d2_2c, 2); % [n_flies x 1];

    if rel_or_norm == "rel"

        % Relative change
        fold_change_per_fly_control = mean_per_fly_2c./mean_per_fly_1c;
        valid_idx_control = ~isnan(fold_change_per_fly_control) & ~isinf(fold_change_per_fly_control);
        fold_change_per_fly_control = fold_change_per_fly_control(valid_idx_control);
        very_high_fchange = fold_change_per_fly_control>10000;
        very_low_fchange = fold_change_per_fly_control<-10000;
        fold_change_per_fly_control(very_high_fchange) = [];
        fold_change_per_fly_control(very_low_fchange) = [];

         % Unpaired t-test with unequal group sizes (Welch's t-test)
        [~, p] = ttest2(fold_change_per_fly, fold_change_per_fly_control, 'Vartype','unequal');
        mean_per_strain = nanmean(fold_change_per_fly);
        mean_per_strain_control = nanmean(fold_change_per_fly_control);

    elseif rel_or_norm == "norm"

        % Normalised change
        norm_diff_per_fly_control = (mean_per_fly_2c - mean_per_fly_1c) ./ (mean_per_fly_2c + mean_per_fly_1c);

         % Unpaired t-test with unequal group sizes (Welch's t-test)
        [~, p] = ttest2(norm_diff_per_fly, norm_diff_per_fly_control, 'Vartype','unequal');
        mean_per_strain = nanmean(norm_diff_per_fly);
        mean_per_strain_control = nanmean(norm_diff_per_fly_control);
    end 

end 