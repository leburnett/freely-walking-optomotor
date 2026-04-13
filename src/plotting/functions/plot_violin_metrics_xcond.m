function plot_violin_metrics_xcond(DATA, cond_ids, strain_names, data_type, rng, delta, cmap)
% PLOT_VIOLIN_METRICS_XCOND  Violin plots comparing conditions.
%
%   PLOT_VIOLIN_METRICS_XCOND(DATA, cond_ids, strain_names, data_type, rng, delta, cmap)
%
%   Same data preparation as plot_boxchart_metrics_xcond but renders as
%   violin plots using plot_violin.
%
%   INPUTS:
%     DATA         - DATA struct from comb_data_across_cohorts_cond
%     cond_ids     - vector of condition indices (e.g. [1, 10])
%     strain_names - cell array of strain names
%     data_type    - string: 'av_data', 'fv_data', 'dist_data', etc.
%     rng          - frame range to average over (e.g. 300:1200)
%     delta        - 0=raw, 1=relative to frame 300, 2=relative to frame 1200
%     cmap         - [n x 3] colour map, indexed by condition number
%
%   See also: plot_boxchart_metrics_xcond, plot_violin

% Resolve delta data types
[data_type, resolved_delta] = resolve_delta_data_type(data_type);
if resolved_delta > 0, delta = resolved_delta; end

sex = 'F';

% Collect per-condition data into cell arrays for plot_violin
n_conds = numel(cond_ids);
group_data = cell(n_conds, 1);

for strain_id = 1:numel(strain_names)
    strain = strain_names{strain_id};

    for c = 1:n_conds
        condition_n = cond_ids(c);
        data = DATA.(strain).(sex);

        cond_data = combine_timeseries_across_exp(data, condition_n, data_type);

        if delta == 1
            cond_data = (cond_data - cond_data(:, 300)) * -1;
        end
        if delta == 2
            cond_data = (cond_data - cond_data(:, 1200)) * -1;
        end

        if data_type == "av_data" || data_type == "curv_data"
            cond_data(:, 750:1200) = cond_data(:, 750:1200) * -1;
        end

        cond_data = cond_data(:, rng);
        mean_data = nanmean(cond_data, 2);

        if condition_n == 7 || condition_n == 8
            mean_data = mean_data * -1;
        end

        group_data{c} = [group_data{c}; mean_data];
    end
end

% Labels
group_labels = arrayfun(@(c) sprintf('Cond %d', c), cond_ids, 'UniformOutput', false);

% Colours from cmap
violin_colors = cmap(cond_ids, :);

% Plot
vopts.colors       = violin_colors;
vopts.ylabel_str   = char(get_ylb_from_data_type(data_type, delta));
vopts.show_median  = true;
vopts.show_mean    = true;
vopts.marker_size  = 10;
vopts.marker_alpha = 0.3;
vopts.violin_alpha = 0.4;
vopts.med_text_sz = 14;

[fig_v, ~] = plot_violin(group_data, group_labels, vopts);
fig_v.Position = [138 432 230 413];

end
