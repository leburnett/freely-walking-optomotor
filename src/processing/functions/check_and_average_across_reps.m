function [rep_data] = check_and_average_across_reps(rep1_data, rep2_data, rep1_data_fv, rep2_data_fv, rep1_data_dcent, rep2_data_dcent, varargin)
% CHECK_AND_AVERAGE_ACROSS_REPS Quality filter and average data across two reps
%
%   rep_data = CHECK_AND_AVERAGE_ACROSS_REPS(rep1_data, rep2_data, rep1_data_fv,
%       rep2_data_fv, rep1_data_dcent, rep2_data_dcent) checks each fly's
%   behavior in both reps and averages valid data using the default 'mean_fv'
%   QC method.
%
%   rep_data = CHECK_AND_AVERAGE_ACROSS_REPS(..., 'qc_method', 'quiescence',
%       'rep1_vel', vel1, 'rep2_vel', vel2) uses quiescence-based filtering
%   instead, marking a rep as invalid only if the fly is nearly stationary
%   for most of the trial.
%
% INPUTS (positional):
%   rep1_data      - [n_flies x n_frames] behavioral data from rep 1
%   rep2_data      - [n_flies x n_frames] behavioral data from rep 2
%   rep1_data_fv   - [n_flies x n_frames] forward velocity from rep 1
%   rep2_data_fv   - [n_flies x n_frames] forward velocity from rep 2
%   rep1_data_dcent - [n_flies x n_frames] distance from center, rep 1
%   rep2_data_dcent - [n_flies x n_frames] distance from center, rep 2
%
% OPTIONAL NAME-VALUE PAIRS:
%   'qc_method'      - 'mean_fv' (default) or 'quiescence'
%                       'mean_fv': reject if mean(fv) < 3 mm/s (original)
%                       'quiescence': reject if vel < threshold for >frac of frames
%   'rep1_vel'       - [n_flies x n_frames] total velocity from rep 1
%                       Required when qc_method = 'quiescence'
%   'rep2_vel'       - [n_flies x n_frames] total velocity from rep 2
%                       Required when qc_method = 'quiescence'
%   'vel_threshold'  - Total velocity threshold for quiescence (mm/s)
%                       Default: 0.5. Frames with vel < this are "stationary"
%   'quiescence_frac'- Fraction of frames that must be stationary to reject
%                       Default: 0.75 (reject if >75% of frames are stationary)
%
% OUTPUT:
%   rep_data - [n_flies x n_frames] averaged data (NaN where both reps invalid)
%
% QUALITY CRITERIA:
%   Method 'mean_fv' (original):
%     A rep is marked invalid (set to NaN) if:
%     - Mean forward velocity < 3 mm/s (fly not walking)
%     - Minimum distance from center > 110 mm (fly stuck near edge)
%
%   Method 'quiescence':
%     A rep is marked invalid (set to NaN) if:
%     - Total velocity < vel_threshold for > quiescence_frac of frames
%       (fly truly stationary/dead — keeps spinning Dm4 flies)
%     - Minimum distance from center > 110 mm (fly stuck near edge)
%
% NOTES:
%   - Invalid reps are set to NaN before averaging
%   - Uses nanmean so valid rep data is preserved even if one rep is invalid
%   - Returns NaN for flies where both reps are invalid
%   - Existing callers with 6 positional args are unaffected (default = 'mean_fv')
%   - The quiescence method uses total velocity (vel_data), which is
%     direction-independent, unlike forward velocity (fv_data). A fly
%     spinning in place has low fv but non-zero vel. This retains flies
%     with genuine motor responses (e.g., Dm4 tight coils) while still
%     removing truly dead/stuck flies.
%
% EXAMPLES:
%   % Original method (backwards compatible):
%   avg_av = check_and_average_across_reps(r1_av, r2_av, r1_fv, r2_fv, r1_dist, r2_dist);
%
%   % Quiescence method:
%   avg_av = check_and_average_across_reps(r1_av, r2_av, r1_fv, r2_fv, ...
%       r1_dist, r2_dist, 'qc_method', 'quiescence', ...
%       'rep1_vel', r1_vel, 'rep2_vel', r2_vel);
%
%   % Quiescence with custom thresholds:
%   avg_av = check_and_average_across_reps(r1_av, r2_av, r1_fv, r2_fv, ...
%       r1_dist, r2_dist, 'qc_method', 'quiescence', ...
%       'rep1_vel', r1_vel, 'rep2_vel', r2_vel, ...
%       'vel_threshold', 1.0, 'quiescence_frac', 0.85);
%
% See also: comb_data_across_cohorts_cond, combine_timeseries_across_exp_check, nanmean

    %% Parse optional arguments
    p = inputParser;
    p.addParameter('qc_method', 'mean_fv', @(x) ismember(x, {'mean_fv', 'quiescence'}));
    p.addParameter('rep1_vel', [], @isnumeric);
    p.addParameter('rep2_vel', [], @isnumeric);
    p.addParameter('vel_threshold', 0.5, @(x) isnumeric(x) && isscalar(x) && x > 0);
    p.addParameter('quiescence_frac', 0.75, @(x) isnumeric(x) && isscalar(x) && x > 0 && x <= 1);
    p.parse(varargin{:});

    qc_method       = p.Results.qc_method;
    rep1_vel        = p.Results.rep1_vel;
    rep2_vel        = p.Results.rep2_vel;
    vel_threshold   = p.Results.vel_threshold;
    quiescence_frac = p.Results.quiescence_frac;

    % Validate: quiescence method requires vel_data
    if strcmp(qc_method, 'quiescence')
        assert(~isempty(rep1_vel) && ~isempty(rep2_vel), ...
            'check_and_average_across_reps: qc_method=''quiescence'' requires rep1_vel and rep2_vel');
        assert(isequal(size(rep1_vel, 1), size(rep1_data, 1)), ...
            'check_and_average_across_reps: rep1_vel must have same number of flies as rep1_data');
        assert(isequal(size(rep2_vel, 1), size(rep2_data, 1)), ...
            'check_and_average_across_reps: rep2_vel must have same number of flies as rep2_data');
    end

    % Distance threshold (same for both methods)
    DIST_THRESHOLD = 110;  % mm — fly stuck near edge

    % FV threshold (only used for mean_fv method)
    FV_THRESHOLD = 3;  % mm/s

    %% Initialise output
    rep_data = zeros(size(rep1_data));

    %% Apply QC and average
    for rr = 1:size(rep1_data, 1)

        % --- Rep 1 QC ---
        min_dcent_rep1 = min(rep1_data_dcent(rr, :));
        fail_dist_rep1 = min_dcent_rep1 > DIST_THRESHOLD;

        if strcmp(qc_method, 'mean_fv')
            % Original method: reject if mean forward velocity too low
            mean_fv_rep1 = mean(rep1_data_fv(rr, :));
            fail_activity_rep1 = mean_fv_rep1 < FV_THRESHOLD;
        else
            % Quiescence method: reject if stationary for >frac of frames
            n_frames_rep1 = size(rep1_vel, 2);
            n_stationary_rep1 = sum(rep1_vel(rr, :) < vel_threshold);
            frac_stationary_rep1 = n_stationary_rep1 / n_frames_rep1;
            fail_activity_rep1 = frac_stationary_rep1 > quiescence_frac;
        end

        if fail_activity_rep1 || fail_dist_rep1
            rep1_data(rr, :) = nan(size(rep1_data(rr, :)));
        end

        % --- Rep 2 QC ---
        min_dcent_rep2 = min(rep2_data_dcent(rr, :));
        fail_dist_rep2 = min_dcent_rep2 > DIST_THRESHOLD;

        if strcmp(qc_method, 'mean_fv')
            mean_fv_rep2 = mean(rep2_data_fv(rr, :));
            fail_activity_rep2 = mean_fv_rep2 < FV_THRESHOLD;
        else
            n_frames_rep2 = size(rep2_vel, 2);
            n_stationary_rep2 = sum(rep2_vel(rr, :) < vel_threshold);
            frac_stationary_rep2 = n_stationary_rep2 / n_frames_rep2;
            fail_activity_rep2 = frac_stationary_rep2 > quiescence_frac;
        end

        if fail_activity_rep2 || fail_dist_rep2
            rep2_data(rr, :) = nan(size(rep2_data(rr, :)));
        end

        % --- Average valid reps ---
        rep_data(rr, :) = nanmean(vertcat(rep1_data(rr, :), rep2_data(rr, :)));
    end

end
