function [v_rad, v_tan, alpha, r] = compute_radial_tangential(x_data, y_data, cx, cy, fps)
% COMPUTE_RADIAL_TANGENTIAL Decompose velocity into radial and tangential.
%
%   [v_rad, v_tan, alpha, r] = COMPUTE_RADIAL_TANGENTIAL(x_data, y_data, cx, cy, fps)
%
%   Decomposes the 2D velocity vector of each fly at each timepoint into
%   radial (toward/away from arena center) and tangential (orbiting around
%   center) components. Uses forward difference with 5-frame moving mean
%   smoothing (consistent with dist_dt computation in add_dist_dt.m).
%
%   INPUTS:
%     x_data  - [n_flies × n_frames] X position in mm
%     y_data  - [n_flies × n_frames] Y position in mm
%     cx      - Arena center X coordinate (mm)
%     cy      - Arena center Y coordinate (mm)
%     fps     - Frame rate (Hz), typically 30
%
%   OUTPUTS:
%     v_rad   - [n_flies × n_frames] Radial velocity (mm/s).
%               Positive = moving AWAY from center.
%               Negative = moving TOWARD center (centring).
%     v_tan   - [n_flies × n_frames] Tangential velocity (mm/s).
%               Positive = CCW rotation around center.
%     alpha   - [n_flies × n_frames] Angle from fly to arena center (rad).
%               Computed as atan2(cy - y, cx - x).
%     r       - [n_flies × n_frames] Distance from arena center (mm).
%
%   NOTES:
%     - First frame of v_rad and v_tan is NaN (no velocity from diff).
%     - Smoothing: 5-frame moving mean on velocity, matching add_dist_dt.m.
%     - Validation: mean(-v_rad) should closely match dist_dt from
%       add_dist_dt.m (Pearson r > 0.99).
%
%   EXAMPLE:
%     PPM = 4.1691; CoA = [528, 520] / PPM;
%     [vr, vt, ~, r] = compute_radial_tangential(x, y, CoA(1), CoA(2), 30);
%     centripetal = -vr;  % positive = moving toward center
%
% See also: add_dist_dt, compute_heading_to_center, centring_turning_traj_plots

    % Displacement from center
    dx = x_data - cx;
    dy = y_data - cy;
    r = sqrt(dx.^2 + dy.^2);

    % Radial unit vector (outward from center) at each frame
    r_hat_x = dx ./ r;
    r_hat_y = dy ./ r;

    % Velocity components (mm/s) via forward difference
    % Prepend NaN column so output size matches input
    vx = [NaN(size(x_data, 1), 1), diff(x_data, 1, 2)] * fps;
    vy = [NaN(size(y_data, 1), 1), diff(y_data, 1, 2)] * fps;

    % 5-frame moving mean for smoothing (match dist_dt convention)
    vx = movmean(vx, 5, 2, 'omitnan');
    vy = movmean(vy, 5, 2, 'omitnan');

    % Project velocity onto radial direction
    % v_rad > 0 means moving outward (away from center)
    v_rad = vx .* r_hat_x + vy .* r_hat_y;

    % Project velocity onto tangential direction
    % Tangential unit vector: 90° CCW rotation of radial unit vector
    % t_hat = (-r_hat_y, r_hat_x) → positive = CCW
    v_tan = -vx .* r_hat_y + vy .* r_hat_x;

    % Angle from fly to arena center (for heading-to-center analysis)
    alpha = atan2(cy - y_data, cx - x_data);

end
