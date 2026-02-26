function [rep_data] = check_and_average_across_reps(rep1_data, rep2_data, rep1_data_fv, rep2_data_fv, rep1_data_dcent, rep2_data_dcent)
% CHECK_AND_AVERAGE_ACROSS_REPS Quality filter and average data across two reps
%
%   rep_data = CHECK_AND_AVERAGE_ACROSS_REPS(rep1_data, rep2_data, rep1_data_fv,
%       rep2_data_fv, rep1_data_dcent, rep2_data_dcent) checks each fly's
%   behavior in both reps and averages valid data.
%
% INPUTS:
%   rep1_data      - [n_flies x n_frames] behavioral data from rep 1
%   rep2_data      - [n_flies x n_frames] behavioral data from rep 2
%   rep1_data_fv   - [n_flies x n_frames] forward velocity from rep 1
%   rep2_data_fv   - [n_flies x n_frames] forward velocity from rep 2
%   rep1_data_dcent - [n_flies x n_frames] distance from center, rep 1
%   rep2_data_dcent - [n_flies x n_frames] distance from center, rep 2
%
% OUTPUT:
%   rep_data - [n_flies x n_frames] averaged data (NaN where both reps invalid)
%
% QUALITY CRITERIA:
%   A rep is marked invalid (set to NaN) if:
%   - Mean forward velocity < 3 mm/s (fly not walking)
%   - Minimum distance from center > 110 mm (fly stuck near edge)
%
% NOTES:
%   - Invalid reps are set to NaN before averaging
%   - Uses nanmean so valid rep data is preserved even if one rep is invalid
%   - Returns NaN for flies where both reps are invalid
%
% EXAMPLE:
%   avg_av = check_and_average_across_reps(r1_av, r2_av, r1_fv, r2_fv, r1_dist, r2_dist);
%
% See also: comb_data_across_cohorts_cond, nanmean 

    % Initialise empty array:
    rep_data = zeros(size(rep1_data));
    % rep_data_fv = zeros((size(rep1_data_fv)));

    for rr = 1:size(rep1_data, 1)

        % Check what the fly's average forward velocity was during the first rep.
        mean_fv_rep1 = mean(rep1_data_fv(rr, :));
        min_dcent_rep1 = min(rep1_data_dcent(rr, :));
        if mean_fv_rep1 < 3  || min_dcent_rep1 > 110 % Less than 3mms-1 or never closer than 100mm from centre.
            rep1_data(rr, :) = nan(size(rep1_data(rr, :)));
        end 

        % Check what the fly's average forward velocity was during the second rep.
        mean_fv_rep2 = mean(rep2_data_fv(rr, :));
        min_dcent_rep2 = min(rep2_data_dcent(rr, :));
        if mean_fv_rep2 < 3 || min_dcent_rep2 > 110 % Less than 3mms-1 or never closer than 100mm from centre.
            rep2_data(rr, :) = nan(size(rep2_data(rr, :)));
        end 
            
        rep_data(rr, :) = nanmean(vertcat(rep1_data(rr, :), rep2_data(rr, :)));
        % rep_data_fv(rr, :) = nanmean(vertcat(rep1_data_fv(rr, :), rep2_data_fv(rr, :)));
    end

    % Remove rows that are filled with NaNs
    % rep_data = rmmissing(rep_data, 'MinNumMissing', size(rep_data, 2));
    % rep_data_fv = rmmissing(rep_data_fv, 'MinNumMissing', size(rep_data, 2));

end 
