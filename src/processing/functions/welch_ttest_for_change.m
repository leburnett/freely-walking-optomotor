function [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_change(cond_data, cond_data_control, rng1, rng2, rel_or_norm)
% WELCH_TTEST_FOR_CHANGE Compare pre-post change between target and control strains
%
%   [p, mean_per_strain, mean_per_strain_control] = WELCH_TTEST_FOR_CHANGE(...)
%   computes the fold change or normalized difference between two time ranges
%   and performs Welch's t-test comparing target vs control groups.
%
% INPUTS:
%   cond_data         - [n_flies x n_frames] target strain data
%   cond_data_control - [n_flies x n_frames] control strain data
%   rng1              - Frame indices for baseline (pre) period
%   rng2              - Frame indices for test (post) period
%   rel_or_norm       - "rel" for relative (fold change) or "norm" for normalized
%
% OUTPUTS:
%   p                      - p-value from Welch's t-test
%   mean_per_strain        - Mean change value for target strain
%   mean_per_strain_control - Mean change value for control strain
%
% CHANGE METRICS:
%   "rel"  - Fold change: mean(rng2) / mean(rng1)
%   "norm" - Normalized difference: (rng2 - rng1) / (rng2 + rng1)
%
% NOTES:
%   - Uses Welch's t-test (unequal variance assumption)
%   - Averages every two rows before computing per-fly means
%   - Filters out NaN, Inf, and extreme fold changes (>10000)
%
% EXAMPLE:
%   [p, m_target, m_ctrl] = welch_ttest_for_change(target_data, ctrl_data, 1:300, 300:600, "rel");
%
% See also: ttest2, mean_every_two_rows

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