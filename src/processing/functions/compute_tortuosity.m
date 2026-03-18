function tort = compute_tortuosity(x_data, y_data, window_frames)
% COMPUTE_TORTUOSITY  Sliding-window path tortuosity index.
%
%   tort = COMPUTE_TORTUOSITY(x_data, y_data, window_frames)
%
%   Computes the ratio of displacement to path length over a sliding window.
%   Values near 1 indicate straight movement; values near 0 indicate highly
%   tortuous paths. NaN is assigned at edges where the full window cannot fit.
%
%   INPUTS:
%     x_data       - [n_flies x n_frames] x position in mm
%     y_data       - [n_flies x n_frames] y position in mm
%     window_frames - scalar, window size in frames (should be odd; will be
%                     rounded up to nearest odd number if even)
%
%   OUTPUT:
%     tort - [n_flies x n_frames] tortuosity index in [0, 1]. NaN at edges
%            where the window extends beyond the data.
%
%   EXAMPLE:
%     tort = compute_tortuosity(x_data, y_data, 60);  % 2s window at 30fps
%
% See also: compute_sliding_window_metrics

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

    % Tortuosity = displacement / path_length
    % Guard against zero path length (stationary fly)
    ratio = displacement ./ path_length;
    ratio(path_length < 1e-6) = NaN;

    tort(:, i) = ratio;
end

end
