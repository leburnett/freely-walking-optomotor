function [rep_data, n_flies_total] = load_per_rep_data(DATA, strain, sex, condition_n, data_types)
% LOAD_PER_REP_DATA  Load individual rep data without averaging across reps.
%
%   [rep_data, n_flies_total] = LOAD_PER_REP_DATA(DATA, strain, sex, condition_n, data_types)
%
%   Unlike combine_timeseries_across_exp_check (which averages R1 and R2),
%   this function returns each rep as a separate fly observation. This is
%   essential for analyses that depend on trajectory structure (e.g.,
%   turning event detection), where averaging heading across reps would
%   destroy the data.
%
%   Applies the same quiescence-based QC as combine_timeseries_across_exp_check:
%     - Reject a fly-rep if vel_data < 0.5 mm/s for >75% of frames
%     - Reject a fly-rep if min(dist_data) > 110 mm (stuck at edge)
%
%   INPUTS:
%     DATA        - struct from comb_data_across_cohorts_cond
%     strain      - string, e.g. "jfrc100_es_shibire_kir"
%     sex         - string, "F" or "M"
%     condition_n - scalar, condition number (e.g. 1)
%     data_types  - cell array of field names to extract,
%                   e.g. {'heading_data', 'x_data', 'y_data', 'dist_data'}
%
%   OUTPUTS:
%     rep_data      - struct with fields matching data_types, each
%                     [n_flies_total x n_frames]. Rows from R1 and R2
%                     across all experiments, concatenated vertically.
%                     QC-failed fly-reps are excluded.
%     n_flies_total - scalar, total number of valid fly-rep observations
%
%   EXAMPLE:
%     [rd, n] = load_per_rep_data(DATA, "jfrc100_es_shibire_kir", "F", 1, ...
%         {'heading_data', 'x_data', 'y_data', 'dist_data', 'vel_data'});
%
% See also: combine_timeseries_across_exp_check, detect_360_turning_events

%% QC thresholds (match combine_timeseries_across_exp_check defaults)
VEL_THRESHOLD   = 0.5;   % mm/s
QUIESCENCE_FRAC = 0.75;  % fraction of stationary frames
DIST_THRESHOLD  = 110;   % mm from center

%% Access strain/sex data
data = DATA.(strain).(sex);
n_exp = length(data);

rep1_str = strcat('R1_condition_', string(condition_n));
rep2_str = strcat('R2_condition_', string(condition_n));

if ~isfield(data, rep1_str)
    error('load_per_rep_data: condition %d not found in DATA.%s.%s', condition_n, strain, sex);
end

%% First pass: determine minimum frame count across all reps
min_frames = Inf;
for idx = 1:n_exp
    if ~isempty(data(idx).(rep1_str))
        nf1 = size(data(idx).(rep1_str).(data_types{1}), 2);
        nf2 = size(data(idx).(rep2_str).(data_types{1}), 2);
        min_frames = min([min_frames, nf1, nf2]);
    end
end

%% Second pass: collect all valid fly-rep rows
% Initialise cell arrays to accumulate data
collected = struct();
for d = 1:numel(data_types)
    collected.(data_types{d}) = {};
end

for idx = 1:n_exp
    rep1_struct = data(idx).(rep1_str);
    if isempty(rep1_struct)
        continue;
    end
    rep2_struct = data(idx).(rep2_str);

    % Process each rep independently
    for rep_idx = 1:2
        if rep_idx == 1
            rep_struct = rep1_struct;
        else
            rep_struct = rep2_struct;
        end

        n_flies = size(rep_struct.(data_types{1}), 1);

        % Get QC fields
        vel_rep  = rep_struct.vel_data(:, 1:min_frames);
        dist_rep = rep_struct.dist_data(:, 1:min_frames);

        for f = 1:n_flies
            % Quiescence check
            n_stationary = sum(vel_rep(f, :) < VEL_THRESHOLD);
            frac_stationary = n_stationary / min_frames;
            if frac_stationary > QUIESCENCE_FRAC
                continue;
            end

            % Edge-stuck check
            if min(dist_rep(f, :)) > DIST_THRESHOLD
                continue;
            end

            % Fly passed QC — collect all requested data types
            for d = 1:numel(data_types)
                row = rep_struct.(data_types{d})(f, 1:min_frames);
                collected.(data_types{d}){end+1} = row;
            end
        end
    end
end

%% Package output
rep_data = struct();
for d = 1:numel(data_types)
    if isempty(collected.(data_types{d}))
        rep_data.(data_types{d}) = [];
    else
        rep_data.(data_types{d}) = vertcat(collected.(data_types{d}){:});
    end
end

if isempty(collected.(data_types{1}))
    n_flies_total = 0;
else
    n_flies_total = size(rep_data.(data_types{1}), 1);
end

fprintf('load_per_rep_data: %s.%s condition %d — %d valid fly-rep observations\n', ...
    strain, sex, condition_n, n_flies_total);

end
