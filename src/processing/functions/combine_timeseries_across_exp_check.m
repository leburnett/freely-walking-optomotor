function cond_data = combine_timeseries_across_exp_check(data, condition_n, data_type)
% Combines the timeseries data across the two reps and across all
% experiments for a given strain, with quiescence-based QC filtering.
%
% Uses check_and_average_across_reps with 'quiescence' method:
%   - Rejects reps where vel_data < 0.5 mm/s for >75% of frames
%   - Rejects reps where min(dist_data) > 110 mm
%
% See also: check_and_average_across_reps

n_exp = length(data);

cond_data = [];

rep1_str = strcat('R1_condition_', string(condition_n));
rep2_str = strcat('R2_condition_', string(condition_n));

    if isfield(data, rep1_str)

        for idx = 1:n_exp

            rep1_struct = data(idx).(rep1_str);

            if ~isempty(rep1_struct) % check that the row is not empty.

                rep1_data_fv = rep1_struct.fv_data;
                rep2_data_fv = data(idx).(rep2_str).fv_data;
                rep1_data_dcent = rep1_struct.dist_data;
                rep2_data_dcent = data(idx).(rep2_str).dist_data;

                % Extract vel_data for quiescence-based QC
                rep1_data_vel = rep1_struct.vel_data;
                rep2_data_vel = data(idx).(rep2_str).vel_data;

                % Extract the relevant data
                rep1_data = rep1_struct.(data_type);
                rep2_data = data(idx).(rep2_str).(data_type);

                % Number of frames in each rep
                nf1 = size(rep1_data, 2);
                nf2 = size(rep2_data, 2);

                if nf1>nf2
                    nf = nf2;
                elseif nf2>nf1
                    nf = nf1;
                else
                    nf = nf1;
                end

                % Trim data to same length
                rep1_data = rep1_data(:, 1:nf);
                rep2_data = rep2_data(:, 1:nf);

                nf_comb = size(cond_data, 2);

                if idx == 1 || nf_comb == 0

                    % QC filter and average across the two reps using
                    % quiescence-based method (vel_data < 0.5 mm/s for
                    % >75% of frames = stationary/dead fly)

                    [rep_data] = check_and_average_across_reps(rep1_data, rep2_data, ...
                        rep1_data_fv, rep2_data_fv, rep1_data_dcent, rep2_data_dcent, ...
                        'qc_method', 'quiescence', ...
                        'rep1_vel', rep1_data_vel, 'rep2_vel', rep2_data_vel);

                    cond_data = vertcat(cond_data, rep_data);

                else

                    if nf>=nf_comb % trim incoming data
                        rep1_data = rep1_data(:, 1:nf_comb);
                        rep2_data = rep2_data(:, 1:nf_comb);
                        rep1_data_fv = rep1_data_fv(:, 1:nf_comb);
                        rep2_data_fv = rep2_data_fv(:, 1:nf_comb);
                        rep1_data_dcent = rep1_data_dcent(:, 1:nf_comb);
                        rep2_data_dcent = rep2_data_dcent(:, 1:nf_comb);
                        rep1_data_vel = rep1_data_vel(:, 1:nf_comb);
                        rep2_data_vel = rep2_data_vel(:, 1:nf_comb);

                    elseif nf_comb>nf % Add NaNs to end

                        diff_f = nf_comb-nf+1;
                        n_flies = size(rep1_data, 1);
                        rep1_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
                        rep2_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
                        rep1_data_fv(:, nf:nf_comb) = NaN(n_flies, diff_f);
                        rep2_data_fv(:, nf:nf_comb) = NaN(n_flies, diff_f);
                        rep1_data_dcent(:, nf:nf_comb) = NaN(n_flies, diff_f);
                        rep2_data_dcent(:, nf:nf_comb) = NaN(n_flies, diff_f);
                        rep1_data_vel(:, nf:nf_comb) = NaN(n_flies, diff_f);
                        rep2_data_vel(:, nf:nf_comb) = NaN(n_flies, diff_f);
                    end

                    [rep_data] = check_and_average_across_reps(rep1_data, rep2_data, ...
                        rep1_data_fv, rep2_data_fv, rep1_data_dcent, rep2_data_dcent, ...
                        'qc_method', 'quiescence', ...
                        'rep1_vel', rep1_data_vel, 'rep2_vel', rep2_data_vel);

                    cond_data = vertcat(cond_data, rep_data);
                end
            end
        end

    end

end
