function plot_histogram_metrics_xcond(DATA, cond_ids, strain_names, data_type, rng, delta, cmap)
% PLOT_HISTOGRAM_METRICS_XCOND Horizontal histograms comparing conditions
%
%   PLOT_HISTOGRAM_METRICS_XCOND(DATA, cond_ids, strain_names, data_type, rng, delta, cmap)
%   creates overlaid horizontal histograms comparing behavioral metrics across
%   stimulus conditions. Designed as a companion plot to plot_boxchart_metrics_xcond
%   with matching y-axis range and identical data extraction.
%
% INPUTS:
%   DATA         - DATA struct from comb_data_across_cohorts_cond
%   cond_ids     - Vector of condition indices to plot (e.g., [1,7])
%   strain_names - Cell array of strain names to include
%   data_type    - String specifying metric: 'av_data', 'fv_data', 'dist_data', etc.
%   rng          - Frame range to average over (e.g., 300:1200)
%   delta        - 0=raw values, 1=relative to frame 300, 2=relative to frame 1200
%   cmap         - Colormap array (colours indexed by condition_id)
%
% See also: plot_boxchart_metrics_xcond, combine_timeseries_across_exp

% Resolve delta data types (e.g., 'fv_data_delta' -> 'fv_data' + delta=1)
[data_type, resolved_delta] = resolve_delta_data_type(data_type);
if resolved_delta > 0, delta = resolved_delta; end

box_colours = cmap(cond_ids, :);
sex = 'F';
n_bins = 20;

% --- Collect per-fly means for each condition ---
cond_means = cell(1, numel(cond_ids));

for c = 1:numel(cond_ids)
    condition_n = cond_ids(c);
    all_vals = [];

    for strain_id = 1:numel(strain_names)
        strain = strain_names{strain_id};
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

        all_vals = [all_vals; mean_data];
    end

    cond_means{c} = all_vals;
end

% --- Y-axis limits (must match plot_boxchart_metrics_xcond) ---
if data_type == "fv_data"
    if delta, yrng = [-15 15]; else, yrng = [0 27]; end
elseif data_type == "dist_data"
    if delta == 1 || delta == 2
        yrng = [-100 120];
    else
        yrng = [0 125];
    end
elseif data_type == "view_dist"
    yrng = [60 140];
elseif data_type == "dist_dt"
    yrng = [-7 5];
elseif data_type == "av_data"
    if delta, yrng = [-200 200]; else, yrng = [-20 225]; end
elseif data_type == "curv_data"
    if delta, yrng = [-200 200]; else, yrng = [-40 210]; end
else
    % Fallback: derive from data
    all_data = vertcat(cond_means{:});
    yrng = [min(all_data) max(all_data)];
end

bin_edges = linspace(yrng(1), yrng(2), n_bins + 1);

% --- Plot horizontal histograms ---
hold on
for c = 1:numel(cond_ids)
    histogram(cond_means{c}, ...
        'BinEdges', bin_edges, ...
        'Orientation', 'horizontal', ...
        'Normalization', 'probability', ...
        'FaceColor', box_colours(c, :), ...
        'FaceAlpha', 0.5, ...
        'EdgeColor', [0.3 0.3 0.3], ...
        'LineWidth', 0.7);
end

ylim(yrng)
xlabel('Probability')

% Format plot
set(gca, 'FontSize', 14, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
f = gcf;
f.Position = [620   547   205   420];

end
