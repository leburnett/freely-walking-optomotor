function [dist_from_wall_mm, r_crit_mm, theta_eff_deg] = criticalDistanceFromWall( ...
            flyTurnSpeed_deg_s, varargin)
% criticalDistanceFromWall
%   Compute distance from arena wall at which an 8-pixel bar is just
%   resolvable, given fly turning speed and moving grating.
%
% [dist_from_wall_mm, r_crit_mm, theta_eff_deg] = criticalDistanceFromWall(flyTurnSpeed_deg_s, ...)
%
% Required input:
%   flyTurnSpeed_deg_s : fly yaw rate in deg/s (positive = same direction
%                        as grating, negative = opposite)
%
% Optional name-value args:
%   'ArenaDiameter'    : arena diameter in mm (default 210)
%   'NumLED'           : number of LEDs around (default 192)
%   'BarPixels'        : bar width in pixels (default 8)
%   'GratingSpeed'     : grating speed in deg/s (default 128)
%   'StaticResDeg'     : static resolution limit in deg (default 4)
%   'Tau'              : temporal integration time in s (default 0.02)
%
% Outputs:
%   dist_from_wall_mm  : distance from arena wall (mm) where bar is just
%                        resolvable; fly must be >= this far from wall
%   r_crit_mm          : radial distance from center (mm) at threshold
%   theta_eff_deg      : effective resolution limit used (deg)
%
% If theta_eff_deg is higher than the bar angle at the arena center,
% dist_from_wall_mm = NaN (fly cannot resolve the bars anywhere).

    % Defaults
    p = inputParser;
    addParameter(p, 'ArenaDiameter', 210);
    addParameter(p, 'NumLED',        192);
    addParameter(p, 'BarPixels',     8);
    addParameter(p, 'GratingSpeed',  128);  % deg/s
    addParameter(p, 'StaticResDeg',  4);    % deg
    addParameter(p, 'Tau',           0.02); % seconds
    parse(p, varargin{:});
    prm = p.Results;

    % Geometry
    R_arena = prm.ArenaDiameter / 2;  % radius in mm
    C_arena = 2*pi*R_arena;           % circumference in mm

    % Bar angular width on the wall (in radians)
    bar_arc    = C_arena * (prm.BarPixels / prm.NumLED);  % physical arc
    dphi_bar   = bar_arc / R_arena;                       % radians

    % Retinal speed (deg/s) and effective resolution limit
    v_retinal_deg_s = prm.GratingSpeed - flyTurnSpeed_deg_s;
    v_retinal_deg_s = abs(v_retinal_deg_s);

    theta_eff_deg = sqrt(prm.StaticResDeg^2 + (v_retinal_deg_s * prm.Tau)^2);

    % --- Helper to compute bar angle at a given radius r (from center) ---
    function theta_deg = barAngleAtRadius(r_mm)
        % Fly at (r, 0), bar centered at phi0 = 0 on the wall
        xf = r_mm; yf = 0;
        phi0 = 0;

        phi1 = phi0 - dphi_bar/2;
        phi2 = phi0 + dphi_bar/2;

        p1 = [R_arena*cos(phi1); R_arena*sin(phi1)];
        p2 = [R_arena*cos(phi2); R_arena*sin(phi2)];
        pe = [xf; yf];

        v1 = p1 - pe;
        v2 = p2 - pe;

        denom = norm(v1)*norm(v2);
        if denom < 1e-12
            theta_deg = NaN;
            return;
        end

        cosang = dot(v1, v2) / denom;
        cosang = max(min(cosang, 1), -1);
        theta_deg = acos(cosang) * 180/pi;
    end

    % --- Check if resolution is possible at all (center case) ---
    theta_center_deg = barAngleAtRadius(0);  % bar angle at arena center

    if theta_eff_deg > theta_center_deg
        % Bars are too small even at center; no position allows resolution
        dist_from_wall_mm = NaN;
        r_crit_mm = NaN;
        return;
    end

    % --- Root finding: find r such that barAngleAtRadius(r) = theta_eff_deg ---
    f = @(r) barAngleAtRadius(r) - theta_eff_deg;

    % Evaluate at center and near wall to ensure sign change
    f0 = f(0);
    fR = f(R_arena - 1e-3);

    if f0 < 0
        error('Unexpected: at center barAngle < theta_eff. Check parameters.');
    end
    if fR > 0
        % Even very close to wall, angle still >= theta_eff; effectively
        % you can resolve everywhere. Set distance-from-wall ~0.
        r_crit_mm = R_arena;
        dist_from_wall_mm = 0;
        return;
    end

    % Use fzero with a bracket
    r_crit_mm = fzero(f, [0, R_arena - 1e-3]);

    % Distance from wall
    dist_from_wall_mm = R_arena - r_crit_mm;
end
