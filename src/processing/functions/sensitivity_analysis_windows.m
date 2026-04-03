function results = sensitivity_analysis_windows(av_data, curv_data, fv_data, ...
    dist_data, x_data, y_data, arena_radius, fps, frame_range, bin_edges, window_range)
% SENSITIVITY_ANALYSIS_WINDOWS  Vary window widths and compute metric vs wall distance.
%
%   results = SENSITIVITY_ANALYSIS_WINDOWS(av_data, curv_data, fv_data,
%       dist_data, x_data, y_data, arena_radius, fps, frame_range,
%       bin_edges, window_range)
%
%   Sweeps through a range of window widths. For each width, computes
%   sliding-window metrics and bins them by distance from arena centre.
%   Produces heatmap matrices showing how the metric-vs-centre-distance
%   relationship changes with window width.
%
%   INPUTS:
%     av_data, curv_data, fv_data, dist_data, x_data, y_data
%                   - [n_flies x n_frames] timeseries arrays
%     arena_radius  - scalar, arena radius in mm
%     fps           - scalar, frames per second
%     frame_range   - vector of frame indices (e.g. 300:1200)
%     bin_edges     - vector of centre distance bin edges (mm)
%     window_range  - vector of window widths to test (seconds),
%                     e.g. 0.1:0.1:3.0
%
%   OUTPUT:
%     results - struct with fields:
%       .window_range  - tested window values (seconds)
%       .bin_centres   - centre distance bin centres (mm)
%       .av_heatmap    - [n_windows x n_bins] mean |AV| per bin per window
%       .curv_heatmap  - [n_windows x n_bins] mean |curv| per bin per window
%       .fv_heatmap    - [n_windows x n_bins] mean FV per bin per window
%       .tort_heatmap  - [n_windows x n_bins] mean tortuosity per bin per window
%
%   EXAMPLE:
%     results = sensitivity_analysis_windows(av, curv, fv, dist, x, y, ...
%         120, 30, 300:1200, 0:10:120, 0.1:0.1:3.0);
%
% See also: compute_sliding_window_metrics, bin_metric_by_wall_distance

n_windows = numel(window_range);
n_bins = numel(bin_edges) - 1;
bin_centres = bin_edges(1:end-1) + diff(bin_edges) / 2;

% Pre-allocate heatmaps
av_heatmap   = NaN(n_windows, n_bins);
curv_heatmap = NaN(n_windows, n_bins);
fv_heatmap   = NaN(n_windows, n_bins);
tort_heatmap = NaN(n_windows, n_bins);

% Distance from arena centre (same for all windows) — dist_data is already centre distance
centre_dist = dist_data;

fprintf('Sensitivity analysis: %d windows from %.1fs to %.1fs\n', ...
    n_windows, window_range(1), window_range(end));

for w = 1:n_windows
    win_s = window_range(w);

    % Use the same window for all metrics at this sweep point
    opts.short_window = win_s;
    opts.long_window  = win_s;

    metrics = compute_sliding_window_metrics(av_data, curv_data, fv_data, ...
        dist_data, x_data, y_data, arena_radius, fps, opts);

    % Bin each metric
    av_heatmap(w, :)   = bin_metric_by_wall_distance(metrics.abs_av,    centre_dist, frame_range, bin_edges);
    curv_heatmap(w, :) = bin_metric_by_wall_distance(metrics.abs_curv,  centre_dist, frame_range, bin_edges);
    fv_heatmap(w, :)   = bin_metric_by_wall_distance(metrics.fwd_vel,   centre_dist, frame_range, bin_edges);
    tort_heatmap(w, :) = bin_metric_by_wall_distance(metrics.tortuosity, centre_dist, frame_range, bin_edges);

    if mod(w, 10) == 0
        fprintf('  Window %d/%d (%.1fs) done\n', w, n_windows, win_s);
    end
end

% Package results
results.window_range = window_range;
results.bin_centres  = bin_centres;
results.av_heatmap   = av_heatmap;
results.curv_heatmap = curv_heatmap;
results.fv_heatmap   = fv_heatmap;
results.tort_heatmap = tort_heatmap;

fprintf('Sensitivity analysis complete.\n');

end
