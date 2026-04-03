function [orient_angle, rel_angle, long_axis_dir, mu] = compute_loop_orientation(x_seg, y_seg, arena_center)
% COMPUTE_LOOP_ORIENTATION  PCA-based orientation of a trajectory loop.
%
%   [orient_angle, rel_angle, long_axis_dir, mu] = COMPUTE_LOOP_ORIENTATION(x_seg, y_seg, arena_center)
%
%   Fits a line along the long axis of a trajectory loop using PCA (first
%   principal component = direction of maximum spatial variance). The
%   direction is oriented AWAY from the start/end point of the loop (the
%   self-intersection), so it points toward the "bulge" — the part of the
%   trajectory where the fly deviated furthest before returning.
%
%   INPUTS:
%     x_seg        - [1 x N] x-positions of the loop segment (mm)
%     y_seg        - [1 x N] y-positions of the loop segment (mm)
%     arena_center - [1 x 2] arena centre coordinates [cx, cy] (mm)
%
%   OUTPUTS:
%     orient_angle  - absolute angle of the long axis in degrees (atan2d)
%     rel_angle     - angle relative to the radial direction from the arena
%                     centre through the loop centroid (degrees, [-180, 180]):
%                       0   = pointing radially outward (away from centre)
%                       ±180 = pointing radially inward (toward centre)
%                       ±90  = tangential to the arena
%     long_axis_dir - [1 x 2] unit direction vector of the oriented long axis
%     mu            - [1 x 2] centroid of the loop [mean_x, mean_y]
%
%   Returns all NaN if fewer than 3 valid (non-NaN) points.
%
%   See also: find_trajectory_loops, pca

% Stack coordinates and remove NaN
coords = [x_seg(:), y_seg(:)];
coords = coords(~any(isnan(coords), 2), :);

if size(coords, 1) < 3
    orient_angle  = NaN;
    rel_angle     = NaN;
    long_axis_dir = [NaN, NaN];
    mu            = [NaN, NaN];
    return;
end

% Centroid
mu = mean(coords, 1);

% PCA: first eigenvector = direction of maximum variance = long axis
[coeff, ~, ~] = pca(coords);
long_axis_dir = coeff(:, 1)';   % [dx, dy]

% Orient AWAY from the start/end point (the self-intersection).
% The start and end of a loop are approximately the same point. We use the
% start point. If the dot product of (start - centroid) with the axis
% direction is positive, the axis currently points TOWARD the start, so
% we flip it to point away (toward the bulge).
start_pt = coords(1, :);
if dot(start_pt - mu, long_axis_dir) > 0
    long_axis_dir = -long_axis_dir;
end

% Normalise to unit vector (PCA eigenvectors are already unit length, but
% be safe after potential sign flip)
long_axis_dir = long_axis_dir / norm(long_axis_dir);

% Absolute orientation angle
orient_angle = atan2d(long_axis_dir(2), long_axis_dir(1));

% Radial direction: from arena centre through the loop centroid
radial_vec = mu - arena_center;
radial_angle = atan2d(radial_vec(2), radial_vec(1));

% Relative angle: 0 = outward, ±180 = inward, ±90 = tangential
rel_angle = mod(orient_angle - radial_angle + 180, 360) - 180;

end
