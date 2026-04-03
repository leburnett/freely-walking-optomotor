function [bin_means, bin_sems, bin_n, per_fly_means] = ...
    bin_metric_by_wall_distance(metric_data, wall_dist, frame_range, bin_edges)
% BIN_METRIC_BY_WALL_DISTANCE  Bin any metric by a spatial distance array.
%
%   [bin_means, bin_sems, bin_n, per_fly_means] = ...
%       BIN_METRIC_BY_WALL_DISTANCE(metric_data, wall_dist, frame_range, bin_edges)
%
%   For each fly, computes the mean metric value within each distance
%   bin (across frames in frame_range). Then computes the across-fly mean
%   and SEM for each bin.
%
%   NOTE: Despite the legacy function name, the second argument is now
%   typically distance from arena centre (dist_data), not wall distance.
%
%   INPUTS:
%     metric_data - [n_flies x n_frames] metric values
%     wall_dist   - [n_flies x n_frames] distance array (mm), e.g. dist from centre
%     frame_range - vector of frame indices to include (e.g. 300:1200)
%     bin_edges   - vector of bin edges (mm), e.g. 0:10:120
%
%   OUTPUTS:
%     bin_means     - [1 x n_bins] mean across flies of per-fly bin means
%     bin_sems      - [1 x n_bins] SEM across flies
%     bin_n         - [1 x n_bins] number of flies contributing to each bin
%     per_fly_means - [n_flies x n_bins] per-fly bin averages (NaN if < 5 frames)
%
%   EXAMPLE:
%     bin_edges = 0:10:119;
%     [means, sems] = bin_metric_by_wall_distance(abs(av), wall_d, 300:1200, bin_edges);
%
% See also: compute_sliding_window_metrics

n_flies = size(metric_data, 1);
n_bins = numel(bin_edges) - 1;
per_fly_means = NaN(n_flies, n_bins);

MIN_FRAMES = 5;  % minimum frames per bin per fly

% Extract frames of interest
metric_roi = metric_data(:, frame_range);
wd_roi     = wall_dist(:, frame_range);

for f = 1:n_flies
    m_f  = metric_roi(f, :);
    wd_f = wd_roi(f, :);

    for b = 1:n_bins
        in_bin = wd_f >= bin_edges(b) & wd_f < bin_edges(b+1);
        valid  = in_bin & ~isnan(m_f);

        if sum(valid) >= MIN_FRAMES
            per_fly_means(f, b) = mean(m_f(valid));
        end
    end
end

% Across-fly statistics
bin_means = nanmean(per_fly_means, 1);
bin_n     = sum(~isnan(per_fly_means), 1);
bin_sems  = nanstd(per_fly_means, 0, 1) ./ sqrt(max(bin_n, 1));

end
