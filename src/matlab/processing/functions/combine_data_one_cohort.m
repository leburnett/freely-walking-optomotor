function [comb_data, feat, trx] = combine_data_one_cohort(feat, trx)
% COMBINE_DATA_ONE_COHORT Combine behavioral metrics for a single cohort
%
%   [comb_data, feat, trx] = COMBINE_DATA_ONE_COHORT(feat, trx) processes
%   FlyTracker output and computes derived behavioral metrics for all flies
%   in a single experimental cohort.
%
% INPUTS:
%   feat - FlyTracker feature struct (from *-feat.mat)
%   trx  - FlyTracker trajectory struct (from trx.mat)
%
% OUTPUTS:
%   comb_data - Struct containing all behavioral metrics:
%               .vel_data      - Three-point velocity (mm/s)
%               .dist_data     - Distance from arena center (mm)
%               .av_data       - Angular velocity (deg/s)
%               .fv_data       - Forward velocity in heading direction (mm/s)
%               .curv_data     - Turning rate (deg/mm)
%               .heading_data  - Unwrapped heading (deg)
%               .heading_wrap  - Wrapped heading (deg)
%               .x_data        - X position (mm)
%               .y_data        - Y position (mm)
%               .view_dist     - Viewing distance to wall (mm)
%               .IFD_data      - Inter-fly distance (mm)
%               .IFA_data      - Inter-fly angle (deg)
%   feat      - Modified feat struct (bad flies removed)
%   trx       - Modified trx struct (bad flies removed)
%
% PROCESSING STEPS:
%   1. Remove flies with incomplete/bad tracking (check_tracking_FlyTrk)
%   2. Filter high-velocity frames (>50mm/s) as tracking errors
%   3. Fill missing values using spline/linear interpolation
%   4. Compute angular velocity using least-squares line fit
%   5. Compute forward velocity from position derivatives
%   6. Compute turning rate as av_data/fv_data
%   7. Calculate viewing distance and inter-fly metrics
%
% PARAMETERS (hardcoded):
%   FPS = 30 (frames per second)
%   t_window = 16 (smoothing window for angular velocity)
%   Max forward velocity = 50 mm/s (higher values set to NaN)
%
% See also: process_data_features, comb_data_across_cohorts_cond, check_tracking_FlyTrk

    % Check tracking and ignore flies that have incomplete tracking.
    flies2ignore = check_tracking_FlyTrk(trx);
    trx(flies2ignore) = [];
    feat.data(flies2ignore, :, :) = [];

    % Video acquisition rate:
    FPS = 30; % frames per second
    
    % Data extracted directly from FlyTracker output:
    d_wall_data = feat.data(:, :, 9);
    heading_data = cell2mat(arrayfun(@(x) x.theta, trx, 'UniformOutput', false))';
    x_data = cell2mat(arrayfun(@(x) x.x_mm, trx, 'UniformOutput', false))'; % x position in mm. 
    y_data = cell2mat(arrayfun(@(x) x.y_mm, trx, 'UniformOutput', false))'; % y position in mm.

    % Velocity data from FlyTracker only used to coarsely filter when the
    % tracking has gone wrong. 
    vel_data = feat.data(:, :, 1);

    for k = 1:height(d_wall_data)
        
        % Use very high velocities as indicators of incorrect tracking.
        vals_to_rm = abs(vel_data(k, :))>50;

        % Fill removed datapoints with NaNs
        d_wall_data(k, vals_to_rm) = NaN;
        heading_data(k, vals_to_rm) = NaN;
        x_data(k, vals_to_rm) = NaN;
        y_data(k, vals_to_rm) = NaN;

        % Fill NaNs
        d_wall_data(k, :) = fillmissing(d_wall_data(k, :)', 'spline');
        heading_data(k, :) = fillmissing(heading_data(k, :)', 'previous');
        x_data(k, :) = fillmissing(x_data(k, :)', 'spline');
        y_data(k, :) = fillmissing(y_data(k, :)', 'spline');
    end 

    % distance from centre % % % % % % % % % % % 
    dist_data  = 120 - d_wall_data; % raw data is distance from wall. Must subtract from 120. 

    % Fixed parameters for finding angular velocity from heading:
    n_flies = length(trx);
    samp_rate = 1/FPS; 
    method = 'line_fit';
    t_window = 16; % % % % increase to get more smoothing 
    cutoff = [];

    heading_data_unwrap = []; 
    heading_wrap = [];
    av_data = [];
    fv_data = [];
    curv_data = [];
    view_dist = [];
    v_data = [];

    for idx = 1:n_flies

        % heading
        D = heading_data(idx, :); % retrieve heading data (wrapped, rad) and fill missing. 
        D_unwr = unwrap(D); % unwrapped in radians
        heading_data_unwrap(idx, :) = rad2deg(D_unwr); % unwrapped in deg
        heading_wrap(idx, :) = rad2deg(D); % wrapped deg

        % angular velocity using least squares line fit to data from
        % t_window. Takes in wrapped data - unwraps within func.
        av_data_rad = vel_estimate(D, samp_rate, method, t_window, cutoff);
        av_data(idx, :) = rad2deg(av_data_rad); %convert to deg/s.

        % forward velocity - speed in the direction of heading
        x = x_data(idx, :); % x position in mm.
        y = y_data(idx, :); % y position in mm. 

        x = gaussian_conv(x);
        y = gaussian_conv(y);

        x_data(idx, :) = x;
        y_data(idx, :) = y;

        dx = diff(x);
        dy = diff(y);

        vx = dx / samp_rate;
        vy = dy / samp_rate;

        fv = (vx .* cos(D(1:end-1)) + vy .* sin(D(1:end-1))); % mm /s 
        fv(fv<0)=NaN; % remove negative forward velocity.
        fv(fv>50)=NaN; % remove forward velocity > 50mm/s - too high.
        fv = fillmissing(fv', 'linear')';

        fv_data(idx, :) = [fv(1), fv];

        % Three point velocity in any direction
        v = calculate_three_point_velocity(x,y);
        v_data(idx, :) = v;

        % Acceleration based on three point velocity.
        % dv = diff(v_data(idx, :));
        % acc_data(idx, :) = [dv(1), dv]; 

        % turning rate
        c_data = [];
        c_data = av_data(idx, :)./fv_data(idx, :);
        vals_fv_zero = abs(fv_data(idx, :))<0.1;
        c_data(abs(c_data)==Inf)=NaN;
        c_data(vals_fv_zero) = NaN;
        % c_data = fillmissing(c_data', 'previous')'; % Do not fill missing
        % for frames where turning rate is undefined / unreliable. 
        curv_data(idx, :) = c_data;

        % viewing distance - distance from fly centre to edge of arena in
        % the direction of heading. 
        view_dist = calculate_viewing_distance(x_data, y_data, heading_data);

    end

    % Add interfly distance and interfly angle. Only to the one nearest
    % fly. 
    [IFD_data, IFA_data] = calculate_distance_to_nearest_fly(x_data, y_data, heading_wrap);

    % Combine the matrices into an overall struct
    comb_data.vel_data = v_data; 
    comb_data.dist_data = dist_data;
    comb_data.av_data = av_data;
    comb_data.fv_data = fv_data;
    comb_data.curv_data = curv_data;
    comb_data.heading_data = heading_data_unwrap;
    comb_data.heading_wrap = heading_wrap;
    comb_data.x_data = x_data;
    comb_data.y_data = y_data;
    comb_data.view_dist = view_dist; % distance to wall in direction of heading.
    comb_data.IFD_data = IFD_data;
    comb_data.IFA_data = IFA_data;
end 
