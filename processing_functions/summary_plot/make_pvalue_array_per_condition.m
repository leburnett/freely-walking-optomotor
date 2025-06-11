function [pvals, target_mean, control_mean] = make_pvalue_array_per_condition(DATA, strain, condition_n)
% This function takes in 'DATA' with the combined data from all of the
% experimental cohorts for a particular protocol. This is made using the
% function: "DATA = comb_data_across_cohorts_cond(protocol_dir);" where
% "protocol_dir" contains the results files per experiment after
% processing. 

% Returned arrays are of the size [1 x n_metrics]. Since this is run for
% each condition. These arrays are then concatenated vertically in the
% function that calls this function: 'make_pvalue_heatmap_across_strains'.

% Extract 'data' from the relevant strain / condition.
sex = 'F';
data = DATA.(strain).(sex);

control_strain = "jfrc100_es_shibire_kir";
data_control = DATA.(control_strain).(sex);

data_types = {'fv_data', 'av_data', 'curv_data', 'dist_data', 'dist_data_delta', 'straightness'};
n_data_types = numel(data_types);

    for typ_id = 1:n_data_types

        data_type = data_types{typ_id};
    
        if data_type ~= "straightness"
            % Combine timeseries data across all of the experiments of a single
            % strain for one condition. Each row = 1 rep for one fly. 
            % 2 reps per fly - sequential rows.
            if data_type == "dist_data_delta"
                cond_data_control = combine_timeseries_across_exp(data_control, condition_n, "dist_data");
                cond_data = combine_timeseries_across_exp(data, condition_n, "dist_data");
                cond_data_control = cond_data_control - cond_data_control(:, 300);
                cond_data = cond_data - cond_data(:, 300);
            else
                cond_data_control = combine_timeseries_across_exp(data_control, condition_n, data_type);
                cond_data = combine_timeseries_across_exp(data, condition_n, data_type);
            end 
            
            % For the different data_types calculate different metrics. 
            % Values for each metric are concatenated horizontally.
            if data_type == "fv_data"
                [pvals_fv, target_mean_fv, control_mean_fv] = fv_metric_tests(cond_data, cond_data_control); % 17 metrics
                
            elseif data_type == "av_data"
                [pvals_av, target_mean_av, control_mean_av] = av_metric_tests(cond_data, cond_data_control); % 7 metrics
    
            elseif data_type == "curv_data"
                [pvals_cv, target_mean_cv, control_mean_cv] = curv_metric_tests(cond_data, cond_data_control); % 9 metrics
    
            elseif data_type == "dist_data"
                [pvals_dist, target_mean_dist, control_mean_dist] = dist_metric_tests(cond_data, cond_data_control, 0); % 3 metrics
    
            elseif data_type == "dist_data_delta"
                [pvals_delta, target_mean_delta, control_mean_delta] = dist_metric_tests(cond_data, cond_data_control, 1); % 3 metrics

            end 

        elseif data_type == "straightness"

            x_data_control = combine_timeseries_across_exp(data_control, condition_n, "x_data");
            x_data = combine_timeseries_across_exp(data, condition_n, "x_data");
            y_data_control = combine_timeseries_across_exp(data_control, condition_n, "y_data");
            y_data = combine_timeseries_across_exp(data, condition_n, "y_data");

            [pvals_str, target_mean_str, control_mean_str] = straightness_metric_tests(x_data, x_data_control, y_data, y_data_control); % 6 metrics

        end 
    
    end

% Combine the arrays horizontally across metrics, Size: [1 x n_metrics]
% These arrays will then be combined vertically across strains. 

pvals = horzcat(pvals_fv, pvals_av,  pvals_cv,  pvals_dist, pvals_delta, pvals_str);

target_mean = horzcat(target_mean_fv, target_mean_av, target_mean_cv, target_mean_dist, target_mean_delta, target_mean_str);

control_mean = horzcat(control_mean_fv, control_mean_av, control_mean_cv, control_mean_dist, control_mean_delta, control_mean_str);

end 