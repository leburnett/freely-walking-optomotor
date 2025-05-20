function [comb_data, feat, trx] = combine_data_one_cohort(feat, trx)
    % Combine the timeseries data of different features per fly for a
    % single cohort into a single struct 'comb_data'. This struct is then
    % saved per experiment in the "results" folder and then combined across
    % experiments to form the larger structure 'DATA' with the timeseries
    % data for all flies, across all strains and experiments for a single
    % protocol.

    % Check tracking and ignore flies that have not been well tracked.
    flies2ignore = check_tracking_FlyTrk(trx);
    trx(flies2ignore) = [];
    feat.data(flies2ignore, :, :) = [];

    FPS = 30; % videos acquired at 30 FPS
    
    % velocity % % % % % % % % % % % 
    vel_data = feat.data(:, :, 1);
    d_wall_data = feat.data(:, :, 9);
    heading_data = cell2mat(arrayfun(@(x) x.theta, trx, 'UniformOutput', false))';
    x_data = cell2mat(arrayfun(@(x) x.x_mm, trx, 'UniformOutput', false))'; % x position in mm. 
    y_data = cell2mat(arrayfun(@(x) x.y_mm, trx, 'UniformOutput', false))'; % y position in mm.

    for k = 1:height(vel_data)
        dv = diff(vel_data(k, :));
        acc_data(k, :) = [dv(1), dv]; 

        %Cut off based on acceleration
        % vals_to_rm = abs(acc_data(k, :))>50;
        vals_to_rm = abs(vel_data(k, :))>50;

        % Fill with NaNs
        acc_data(k, vals_to_rm) = NaN;
        % vel_data(k, vals_to_rm) = NaN;
        d_wall_data(k, vals_to_rm) = NaN;
        heading_data(k, vals_to_rm) = NaN;
        x_data(k, vals_to_rm) = NaN;
        y_data(k, vals_to_rm) = NaN;

        % Fill NaNs with spline. 
        acc_data(k, :) = fillmissing(acc_data(k, :)', 'spline')';
        % vel_data(k, :) = fillmissing(vel_data(k, :)', 'spline');
        d_wall_data(k, :) = fillmissing(d_wall_data(k, :)', 'spline');
        heading_data(k, :) = fillmissing(heading_data(k, :)', 'previous');
        x_data(k, :) = fillmissing(x_data(k, :)', 'spline');
        y_data(k, :) = fillmissing(y_data(k, :)', 'spline');
    end 

    dist_trav = vel_data/FPS;

    % distance from centre % % % % % % % % % % % 

    dist_data  = 120 - d_wall_data; % raw data is distance from wall. Must subtract from 120. 

    % angular velocity % heading% % % % % % % % % % % 

    % Fixed paramters: 
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

        % three point velocity in any direction
        v = calculate_three_point_velocity(x,y);
        v_data(idx, :) = v;

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
        % direction of heading. 
        view_dist = calculate_viewing_distance(x_data, y_data, heading_data);

    end

    % Add interfly distance and interfly angle. Only to the one nearest
    % fly. 
    [IFD_data, IFA_data] = calculate_distance_to_nearest_fly(x_data, y_data, heading_wrap);

    % Combine the matrices into an overall struct
    comb_data.vel_data = v_data; 
    comb_data.dist_data = dist_data;
    comb_data.dist_trav = dist_trav;
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
