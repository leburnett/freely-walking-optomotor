function [p, mean_per_strain, mean_per_strain_control] = welch_ttest_for_rng(cond_data, cond_data_control, rng, pre_averaged)
% WELCH_TTEST_FOR_RNG Welch's t-test comparing mean values over a frame range.
%
%   [p, m, mc] = welch_ttest_for_rng(cond_data, cond_data_control, rng)
%   averages paired rep rows (2 rows per fly) before computing per-fly means.
%
%   [p, m, mc] = welch_ttest_for_rng(..., true) skips rep averaging — use
%   when data already has 1 row per fly (e.g., from combine_timeseries_across_exp_check).
%
% See also: mean_every_two_rows, ttest2

    if nargin < 4, pre_averaged = false; end

    d = cond_data(:, rng);
    if pre_averaged
        d2 = d;
    else
        d2 = mean_every_two_rows(d);
    end
    mean_per_fly = nanmean(d2, 2); % [n_flies x 1]; NaN-safe across frames
    mean_per_strain = nanmean(mean_per_fly); % single value.

    d_control = cond_data_control(:, rng);
    if pre_averaged
        d2_control = d_control;
    else
        d2_control = mean_every_two_rows(d_control);
    end
    mean_per_fly_control = nanmean(d2_control, 2); % [n_flies x 1]; NaN-safe across frames
    mean_per_strain_control = nanmean(mean_per_fly_control); % single value.

    % Remove NaN flies before t-test
    mean_per_fly = mean_per_fly(~isnan(mean_per_fly));
    mean_per_fly_control = mean_per_fly_control(~isnan(mean_per_fly_control));

    % Unpaired t-test with unequal group sizes (Welch's t-test)
    [~, p] = ttest2(mean_per_fly, mean_per_fly_control, 'Vartype','unequal');

end
