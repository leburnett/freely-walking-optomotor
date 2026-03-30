function fig = plot_metric_correlations(metrics, frame_range, opts)
% PLOT_METRIC_CORRELATIONS  Pairwise scatter/correlation matrix of metrics.
%
%   fig = PLOT_METRIC_CORRELATIONS(metrics, frame_range, opts)
%
%   Creates a 4x4 pairwise scatter/histogram matrix of the four sliding-
%   window metrics: |AV|, |curvature|, forward velocity, and tortuosity.
%   Uses MATLAB's plotmatrix for the scatter layout.
%
%   INPUTS:
%     metrics     - struct from compute_sliding_window_metrics, with fields:
%                   .abs_av, .abs_curv, .fwd_vel, .tortuosity [n_flies x n_frames]
%     frame_range - vector of frame indices to include (e.g. 300:1200)
%     opts        - struct with optional fields:
%       .subsample  - subsample factor to reduce points (default: 10)
%       .title_str  - figure title (default: 'Metric Correlations')
%       .max_points - max total points to plot (default: 50000)
%
%   OUTPUT:
%     fig - figure handle
%
% See also: compute_sliding_window_metrics, plotmatrix

%% Parse options
if nargin < 3, opts = struct(); end
subsample  = get_field(opts, 'subsample', 10);
title_str  = get_field(opts, 'title_str', 'Metric Correlations');
max_points = get_field(opts, 'max_points', 50000);

%% Extract stimulus-period data
av_roi   = metrics.abs_av(:, frame_range);
curv_roi = metrics.abs_curv(:, frame_range);
fv_roi   = metrics.fwd_vel(:, frame_range);
tort_roi = metrics.tortuosity(:, frame_range);

% Flatten to column vectors
av_flat   = av_roi(:);
curv_flat = curv_roi(:);
fv_flat   = fv_roi(:);
tort_flat = tort_roi(:);

% Remove rows where any metric is NaN
valid = ~isnan(av_flat) & ~isnan(curv_flat) & ~isnan(fv_flat) & ~isnan(tort_flat);
av_flat   = av_flat(valid);
curv_flat = curv_flat(valid);
fv_flat   = fv_flat(valid);
tort_flat = tort_flat(valid);

% Subsample
n_total = numel(av_flat);
if n_total > max_points
    subsample = max(subsample, ceil(n_total / max_points));
end
idx = 1:subsample:n_total;

data_mat = [av_flat(idx), curv_flat(idx), fv_flat(idx), tort_flat(idx)];
labels = {'|AV| (deg/s)', '|Curv| (deg/mm)', 'FV (mm/s)', 'Tortuosity'};

%% Plot
fig = figure('Position', [50 50 1000 900]);
[~, ax_array, ~, ~] = plotmatrix(data_mat, '.');

% Label axes
n_vars = size(data_mat, 2);
for i = 1:n_vars
    ylabel(ax_array(i, 1), labels{i}, 'FontSize', 11);
    xlabel(ax_array(n_vars, i), labels{i}, 'FontSize', 11);
end

% Format all axes
for i = 1:n_vars
    for j = 1:n_vars
        set(ax_array(i,j), 'FontSize', 9, 'TickDir', 'out', 'Box', 'off');
    end
end

sgtitle(title_str, 'FontSize', 18);

%% Print correlation coefficients
fprintf('\n=== Pairwise Pearson Correlations ===\n');
R = corrcoef(data_mat);
for i = 1:n_vars
    for j = (i+1):n_vars
        fprintf('  %s vs %s: r = %.3f\n', labels{i}, labels{j}, R(i,j));
    end
end

end

%% Helper
function val = get_field(s, field, default)
    if isfield(s, field)
        val = s.(field);
    else
        val = default;
    end
end
