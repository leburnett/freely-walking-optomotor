function [pvals, target_mean, control_mean] = make_pvalue_array_per_condition(DATA, strain, condition_n)
% MAKE_PVALUE_ARRAY_PER_CONDITION Compute metric p-values for one strain vs control.
%
% Takes in 'DATA' with the combined data from all experimental cohorts for
% a particular protocol. This is made using:
%   DATA = comb_data_across_cohorts_cond(protocol_dir);
%
% Uses combine_timeseries_across_exp_check to apply quiescence-based QC
% before computing metrics. Data has 1 row per fly (reps averaged after QC).
%
% Returned arrays are of the size [1 x n_metrics]. Since this is run for
% each condition. These arrays are then concatenated vertically in the
% function that calls this function: 'make_pvalue_heatmap_across_strains'.
%
% See also: combine_timeseries_across_exp_check, fv_metric_tests,
%           curv_metric_tests, dist_metric_tests

% Extract 'data' from the relevant strain / condition.
sex = 'F';
data = DATA.(strain).(sex);

control_strain = "jfrc100_es_shibire_kir";
data_control = DATA.(control_strain).(sex);

data_types = {'fv_data', 'av_data', 'curv_data', 'dist_data_delta'};
n_data_types = numel(data_types);

for typ_id = 1:n_data_types

    data_type = data_types{typ_id};

    % Resolve delta data types (e.g., 'dist_data_delta' → 'dist_data' + delta=1)
    [base_type, delta_flag] = resolve_delta_data_type(data_type);

    % Combine timeseries data across all experiments for one strain/condition.
    % Uses quiescence-based QC: each row = 1 fly (reps averaged after filtering).
    cond_data_control = combine_timeseries_across_exp_check(data_control, condition_n, base_type);
    cond_data = combine_timeseries_across_exp_check(data, condition_n, base_type);

    % Apply within-fly baseline subtraction if delta
    if delta_flag == 1
        cond_data_control = cond_data_control - cond_data_control(:, 300);
        cond_data = cond_data - cond_data(:, 300);
    elseif delta_flag == 2
        cond_data_control = cond_data_control - cond_data_control(:, 1200);
        cond_data = cond_data - cond_data(:, 1200);
    end

    % For the different data_types calculate different metrics.
    % Values for each metric are concatenated horizontally.
    % pre_averaged = true because _check returns 1 row per fly.
    if data_type == "fv_data"
        [pvals_fv, target_mean_fv, control_mean_fv] = fv_metric_tests(cond_data, cond_data_control, true);

    elseif data_type == "av_data"
        [pvals_av, target_mean_av, control_mean_av] = av_metric_tests(cond_data, cond_data_control, true);

    elseif data_type == "curv_data"
        [pvals_cv, target_mean_cv, control_mean_cv] = curv_metric_tests(cond_data, cond_data_control, true);

    % elseif data_type == "dist_data"
    %     [pvals_dist, target_mean_dist, control_mean_dist] = dist_metric_tests(cond_data, cond_data_control, 1, true);

    elseif data_type == "dist_data_delta"
        [pvals_delta, target_mean_delta, control_mean_delta] = dist_metric_tests(cond_data, cond_data_control, 2, true);

    % elseif data_type == "dist_data_delta_end"
    %     [pvals_dist_dt, target_mean_dist_dt, control_mean_dist_dt] = dist_metric_tests(cond_data, cond_data_control, 3, true);
    end

end

% Combine the arrays horizontally across metrics, Size: [1 x n_metrics]
% These arrays will then be combined vertically across strains.

pvals = horzcat(pvals_fv, pvals_av, pvals_cv, pvals_delta);

target_mean = horzcat(target_mean_fv, target_mean_av, target_mean_cv, target_mean_delta);

control_mean = horzcat(control_mean_fv, control_mean_av, control_mean_cv, control_mean_delta);

end
