function cond_data = combine_timeseries_across_exp(data, condition_n, data_type, varargin)
% COMBINE_TIMESERIES_ACROSS_EXP Combine timeseries across reps and experiments
%
%   cond_data = COMBINE_TIMESERIES_ACROSS_EXP(data, condition_n, data_type)
%   combines timeseries data across two reps and all experiments for a given
%   strain, applying distance-only QC filtering (default) and averaging reps
%   to return one row per fly.
%
%   cond_data = COMBINE_TIMESERIES_ACROSS_EXP(..., 'qc', mode) selects QC:
%     'distance'   — (default) reject reps where min(dist_data) > 110 mm
%     'quiescence' — reject reps by distance OR quiescence (vel < threshold
%                    for > frac of frames). Delegates to
%                    check_and_average_across_reps.
%     'none'       — no filtering
%
%   cond_data = COMBINE_TIMESERIES_ACROSS_EXP(..., 'average_reps', false)
%   returns two rows per fly (interleaved: rep1, rep2) instead of averaging.
%
% OPTIONAL NAME-VALUE PAIRS:
%   'qc'              - QC method: 'distance' (default), 'quiescence', 'none'
%   'vel_threshold'   - Velocity below which a frame is stationary (mm/s).
%                       Default: 0.5. Only used when qc = 'quiescence'.
%   'quiescence_frac' - Fraction of stationary frames to trigger rejection.
%                       Default: 0.75. Only used when qc = 'quiescence'.
%   'average_reps'    - true (default): average reps (1 row/fly).
%                       false: interleave reps (2 rows/fly).
%
% See also: check_and_average_across_reps

%% Parse optional arguments
p = inputParser;
p.addParameter('qc', 'distance', @(x) ismember(x, {'distance', 'quiescence', 'none'}));
p.addParameter('vel_threshold', 0.5, @(x) isnumeric(x) && isscalar(x) && x > 0);
p.addParameter('quiescence_frac', 0.75, @(x) isnumeric(x) && isscalar(x) && x > 0 && x <= 1);
p.addParameter('average_reps', true, @(x) islogical(x) || (isnumeric(x) && isscalar(x)));
p.parse(varargin{:});

qc_mode         = p.Results.qc;
vel_threshold   = p.Results.vel_threshold;
quiescence_frac = p.Results.quiescence_frac;
do_average      = logical(p.Results.average_reps);

DIST_THRESHOLD = 110; % mm — fly stuck near edge

n_exp = length(data);
cond_data = [];

rep1_str = strcat('R1_condition_', string(condition_n));
rep2_str = strcat('R2_condition_', string(condition_n));

if ~isfield(data, rep1_str)
    return
end

for idx = 1:n_exp

    rep1_struct = data(idx).(rep1_str);

    if isempty(rep1_struct)
        continue
    end

    % Extract the requested data type
    rep1_data = rep1_struct.(data_type);
    rep2_data = data(idx).(rep2_str).(data_type);

    % Trim to same frame count
    nf = min(size(rep1_data, 2), size(rep2_data, 2));
    rep1_data = rep1_data(:, 1:nf);
    rep2_data = rep2_data(:, 1:nf);

    % Handle frame-count mismatch with accumulated cond_data
    nf_comb = size(cond_data, 2);

    if idx > 1 && nf_comb > 0
        if nf >= nf_comb
            rep1_data = rep1_data(:, 1:nf_comb);
            rep2_data = rep2_data(:, 1:nf_comb);
            nf = nf_comb;
        else
            diff_f = nf_comb - nf + 1;
            n_flies = size(rep1_data, 1);
            rep1_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
            rep2_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
            nf = nf_comb;
        end
    end

    % --- Apply QC and combine reps ---
    switch qc_mode

        case 'quiescence'
            % Extract auxiliary data for check_and_average_across_reps
            rep1_data_fv    = rep1_struct.fv_data;
            rep2_data_fv    = data(idx).(rep2_str).fv_data;
            rep1_data_dcent = rep1_struct.dist_data;
            rep2_data_dcent = data(idx).(rep2_str).dist_data;
            rep1_data_vel   = rep1_struct.vel_data;
            rep2_data_vel   = data(idx).(rep2_str).vel_data;

            % Trim/pad auxiliary arrays to match nf
            rep1_data_fv    = trim_or_pad(rep1_data_fv, nf);
            rep2_data_fv    = trim_or_pad(rep2_data_fv, nf);
            rep1_data_dcent = trim_or_pad(rep1_data_dcent, nf);
            rep2_data_dcent = trim_or_pad(rep2_data_dcent, nf);
            rep1_data_vel   = trim_or_pad(rep1_data_vel, nf);
            rep2_data_vel   = trim_or_pad(rep2_data_vel, nf);

            if do_average
                rep_data = check_and_average_across_reps(rep1_data, rep2_data, ...
                    rep1_data_fv, rep2_data_fv, rep1_data_dcent, rep2_data_dcent, ...
                    'qc_method', 'quiescence', ...
                    'rep1_vel', rep1_data_vel, 'rep2_vel', rep2_data_vel, ...
                    'vel_threshold', vel_threshold, 'quiescence_frac', quiescence_frac);
            else
                % Apply QC (NaN invalid reps) then interleave
                rep1_data = apply_quiescence_qc(rep1_data, rep1_data_vel, rep1_data_dcent, ...
                    vel_threshold, quiescence_frac, DIST_THRESHOLD);
                rep2_data = apply_quiescence_qc(rep2_data, rep2_data_vel, rep2_data_dcent, ...
                    vel_threshold, quiescence_frac, DIST_THRESHOLD);
                rep_data = interleave_reps(rep1_data, rep2_data);
            end

        case 'distance'
            % Extract distance data only
            rep1_data_dcent = rep1_struct.dist_data;
            rep2_data_dcent = data(idx).(rep2_str).dist_data;
            rep1_data_dcent = trim_or_pad(rep1_data_dcent, nf);
            rep2_data_dcent = trim_or_pad(rep2_data_dcent, nf);

            % NaN reps where fly is stuck near edge
            for rr = 1:size(rep1_data, 1)
                if min(rep1_data_dcent(rr, :), [], 'omitnan') > DIST_THRESHOLD
                    rep1_data(rr, :) = NaN;
                end
                if min(rep2_data_dcent(rr, :), [], 'omitnan') > DIST_THRESHOLD
                    rep2_data(rr, :) = NaN;
                end
            end

            if do_average
                rep_data = nanmean(cat(3, rep1_data, rep2_data), 3);
            else
                rep_data = interleave_reps(rep1_data, rep2_data);
            end

        case 'none'
            if do_average
                rep_data = nanmean(cat(3, rep1_data, rep2_data), 3);
            else
                rep_data = interleave_reps(rep1_data, rep2_data);
            end
    end

    cond_data = vertcat(cond_data, rep_data); %#ok<AGROW>
end

end

%% ===== Local helper functions =====

function arr = trim_or_pad(arr, nf_target)
%TRIM_OR_PAD Trim or NaN-pad an array to nf_target columns.
    nf_current = size(arr, 2);
    if nf_current > nf_target
        arr = arr(:, 1:nf_target);
    elseif nf_current < nf_target
        n_rows = size(arr, 1);
        arr(:, nf_current+1:nf_target) = NaN(n_rows, nf_target - nf_current);
    end
end

function rep_data = interleave_reps(rep1_data, rep2_data)
%INTERLEAVE_REPS Interleave rep1 and rep2 rows (2 rows per fly).
    n_flies = size(rep1_data, 1);
    nf = size(rep1_data, 2);
    rep_data = zeros(n_flies * 2, nf);
    rep_data(1:2:end, :) = rep1_data;
    rep_data(2:2:end, :) = rep2_data;
end

function data = apply_quiescence_qc(data, vel_data, dist_data, vel_threshold, quiescence_frac, dist_threshold)
%APPLY_QUIESCENCE_QC NaN rows that fail quiescence or distance checks.
    for rr = 1:size(data, 1)
        n_frames = size(vel_data, 2);
        frac_stationary = sum(vel_data(rr, :) < vel_threshold) / n_frames;
        fail_quiescence = frac_stationary > quiescence_frac;
        fail_dist = min(dist_data(rr, :), [], 'omitnan') > dist_threshold;
        if fail_quiescence || fail_dist
            data(rr, :) = NaN;
        end
    end
end
