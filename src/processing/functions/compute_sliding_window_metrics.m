function metrics = compute_sliding_window_metrics(av_data, curv_data, fv_data, ...
    dist_data, x_data, y_data, arena_radius, fps, opts)
% COMPUTE_SLIDING_WINDOW_METRICS  Sliding-window turning and locomotion metrics.
%
%   metrics = COMPUTE_SLIDING_WINDOW_METRICS(av_data, curv_data, fv_data,
%       dist_data, x_data, y_data, arena_radius, fps, opts)
%
%   Computes four smoothed metrics using sliding windows:
%     - |angular velocity| and |curvature| (short window)
%     - forward velocity (short window)
%     - path tortuosity (long window)
%   Also computes wall distance from dist_data.
%
%   INPUTS:
%     av_data      - [n_flies x n_frames] angular velocity (deg/s)
%     curv_data    - [n_flies x n_frames] curvature (deg/mm)
%     fv_data      - [n_flies x n_frames] forward velocity (mm/s)
%     dist_data    - [n_flies x n_frames] distance from arena center (mm)
%     x_data       - [n_flies x n_frames] x position (mm)
%     y_data       - [n_flies x n_frames] y position (mm)
%     arena_radius - scalar, arena radius in mm
%     fps          - scalar, frames per second
%     opts         - struct with optional fields:
%         .short_window - window for AV, curvature, FV (seconds). Default: 0.5
%         .long_window  - window for tortuosity (seconds). Default: 2.0
%
%   OUTPUT:
%     metrics - struct with fields, each [n_flies x n_frames]:
%       .abs_av      - sliding mean of |angular velocity| (deg/s)
%       .abs_curv    - sliding mean of |curvature| (deg/mm)
%       .fwd_vel     - sliding mean of forward velocity (mm/s)
%       .tortuosity  - path tortuosity index [0, 1]
%       .wall_dist   - distance from wall (mm): arena_radius - dist_data
%
%   EXAMPLE:
%     opts.short_window = 0.5;
%     opts.long_window  = 2.0;
%     metrics = compute_sliding_window_metrics(av, curv, fv, dist, x, y, 119, 30, opts);
%
% See also: compute_tortuosity, bin_metric_by_wall_distance

%% Parse options
if nargin < 9 || isempty(opts)
    opts = struct();
end
if ~isfield(opts, 'short_window'), opts.short_window = 0.5; end
if ~isfield(opts, 'long_window'),  opts.long_window  = 2.0; end

short_win_frames = round(opts.short_window * fps);
long_win_frames  = round(opts.long_window * fps);

% Ensure odd window sizes for symmetry
if mod(short_win_frames, 2) == 0, short_win_frames = short_win_frames + 1; end
if mod(long_win_frames, 2) == 0,  long_win_frames  = long_win_frames + 1;  end

%% Compute smoothed metrics
% movmean handles NaN via 'omitnan' by default in recent MATLAB
metrics.abs_av   = movmean(abs(av_data),   short_win_frames, 2, 'omitnan');
metrics.abs_curv = movmean(abs(curv_data), short_win_frames, 2, 'omitnan');
metrics.fwd_vel  = movmean(fv_data,        short_win_frames, 2, 'omitnan');

%% Compute tortuosity (separate function, longer window)
metrics.tortuosity = compute_tortuosity(x_data, y_data, long_win_frames);

%% Wall distance
metrics.wall_dist = arena_radius - dist_data;

end
