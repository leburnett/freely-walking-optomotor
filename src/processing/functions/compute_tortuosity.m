function tort = compute_tortuosity(x_data, y_data, window_frames, fps)
% COMPUTE_TORTUOSITY  Sliding-window path tortuosity index.
%
%   tort = COMPUTE_TORTUOSITY(x_data, y_data, window_frames, fps)
%
%   Computes the ratio of path length to displacement over a sliding window.
%   Values of 1 indicate perfectly straight movement; values > 1 indicate
%   increasingly tortuous paths. NaN is assigned at edges where the full
%   window cannot fit, or where the fly is effectively stationary (see
%   minimum-movement guards below).
%
%   INPUTS:
%     x_data       - [n_flies x n_frames] x position in mm
%     y_data       - [n_flies x n_frames] y position in mm
%     window_frames - scalar, window size in frames (should be odd; will be
%                     rounded up to nearest odd number if even)
%     fps          - scalar, acquisition frame rate (Hz). Default: 30.
%
%   OUTPUT:
%     tort - [n_flies x n_frames] tortuosity index >= 1. NaN at edges
%            where the window extends beyond the data, or where the fly
%            is near-stationary.
%
%   MINIMUM-MOVEMENT GUARDS:
%     When a fly is barely moving, tracking noise dominates: tiny frame-to-
%     frame jitters accumulate into a nonzero path_length while the net
%     displacement stays near zero, producing spurious tortuosity values
%     of 50-1000+. Two complementary guards set the result to NaN:
%       1) Displacement < 0.5 mm over the window
%       2) Mean speed < 1.0 mm/s over the window
%
%   EXAMPLE:
%     tort = compute_tortuosity(x_data, y_data, 60, 30);  % 2s window at 30fps
%
% See also: compute_sliding_window_metrics

if nargin < 4 || isempty(fps)
    fps = 30;
end

[n_flies, n_frames] = size(x_data);

% Ensure odd window
if mod(window_frames, 2) == 0
    window_frames = window_frames + 1;
end
half_win = floor(window_frames / 2);

% Pre-compute inter-frame step distances for all flies
% step_dist(:, i) = distance from frame i to frame i+1
dx = diff(x_data, 1, 2);
dy = diff(y_data, 1, 2);
step_dist = sqrt(dx.^2 + dy.^2);  % [n_flies x (n_frames-1)]

% Cumulative path length along trajectory (0 at frame 1)
cum_path = [zeros(n_flies, 1), cumsum(step_dist, 2)];  % [n_flies x n_frames]

% Minimum-movement thresholds
min_displacement = 0.5;  % mm — net movement must exceed this
min_mean_speed   = 1.0;  % mm/s — average speed must exceed this
window_duration  = window_frames / fps;  % seconds

% Initialise output with NaN
tort = NaN(n_flies, n_frames);

% Compute tortuosity for each frame where full window fits
for i = (half_win + 1):(n_frames - half_win)
    i_start = i - half_win;
    i_end   = i + half_win;

    % Displacement: straight-line distance from window start to end
    displacement = sqrt((x_data(:, i_end) - x_data(:, i_start)).^2 + ...
                        (y_data(:, i_end) - y_data(:, i_start)).^2);

    % Path length: sum of step distances within the window
    path_length = cum_path(:, i_end) - cum_path(:, i_start);

    % Mean speed over the window
    mean_speed = path_length / window_duration;

    % Tortuosity = path_length / displacement  (>=1, 1 = straight)
    ratio = path_length ./ displacement;

    % NaN out near-stationary windows where noise dominates
    ratio(displacement < min_displacement) = NaN;
    ratio(mean_speed < min_mean_speed) = NaN;

    tort(:, i) = ratio;
end

end
