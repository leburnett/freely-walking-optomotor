function [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng_min(cond_data, cond_data_control, rng, pre_averaged)
% WELCH_TTEST_FOR_RNG_MIN Welch's t-test comparing min values over a frame range.
%
%   [p, m, mc] = welch_ttest_for_rng_min(cond_data, cond_data_control, rng)
%   finds the min per rep, then averages paired rep rows (2 rows per fly).
%
%   [p, m, mc] = welch_ttest_for_rng_min(..., true) skips rep averaging — use
%   when data already has 1 row per fly (e.g., from combine_timeseries_across_exp_check).
%
%   NaN handling: uses 'omitnan' for min and nanmean for averages so that
%   flies with NaN-padded frames (from cohorts with different frame counts)
%   do not propagate NaN to the entire strain.
%
% See also: mean_every_two_rows, ttest2

    if nargin < 4, pre_averaged = false; end

    d = cond_data(:, rng);
    % Find the min per each rep first THEN average across reps.
    d_min = min(d, [], 2, 'omitnan');
    if pre_averaged
        mean_per_fly = d_min;
    else
        mean_per_fly = mean_every_two_rows(d_min);
    end
    mean_per_strain = nanmean(mean_per_fly); % single value.

    d_control = cond_data_control(:, rng);
    % Find the min per each rep first THEN average across reps.
    d_min_control = min(d_control, [], 2, 'omitnan');
    if pre_averaged
        mean_per_fly_control = d_min_control;
    else
        mean_per_fly_control = mean_every_two_rows(d_min_control);
    end
    mean_per_strain_control = nanmean(mean_per_fly_control); % single value.

    % Remove NaN flies before t-test
    mean_per_fly = mean_per_fly(~isnan(mean_per_fly));
    mean_per_fly_control = mean_per_fly_control(~isnan(mean_per_fly_control));

    % Unpaired t-test with unequal group sizes (Welch's t-test)
    [~, p] = ttest2(mean_per_fly, mean_per_fly_control, 'Vartype','unequal');

end
