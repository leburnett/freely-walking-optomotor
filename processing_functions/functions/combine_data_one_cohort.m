function [combined_data, feat, trx] = combine_data_one_cohort(feat, trx)
    % Combine the data about different features together to use when plotting
    % quick overview plots while processing. 

    % Check tracking and ignore flies that have not been well tracked.
    flies2ignore = check_tracking_FlyTrk(trx);
    trx(flies2ignore) = [];
    feat.data(flies2ignore, :, :) = [];

    FPS = 30; % videos acquired at 30 FPS
    % pix_per_mm = 4.1691;
    smooth_kernel = [1 2 1]/4;
    
    % velocity % % % % % % % % % % % 
    vel_data = feat.data(:, :, 1);
    d_wall_data = feat.data(:, :, 9);
    heading_data = cell2mat(arrayfun(@(x) x.theta, trx, 'UniformOutput', false))';
    x_data = cell2mat(arrayfun(@(x) x.x_mm, trx, 'UniformOutput', false))';
    y_data = cell2mat(arrayfun(@(x) x.y_mm, trx, 'UniformOutput', false))';

    for k = 1:height(vel_data)
        dv = diff(vel_data(k, :));
        acc_data(k, :) = [dv(1), dv]; 

        %Cut off based on acceleration
        % vals_to_rm = abs(acc_data(k, :))>50;
        vals_to_rm = abs(vel_data(k, :))>50;

        % Fill with NaNs
        acc_data(k, vals_to_rm) = NaN;
        vel_data(k, vals_to_rm) = NaN;
        d_wall_data(k, vals_to_rm) = NaN;
        heading_data(k, vals_to_rm) = NaN;
        x_data(k, vals_to_rm) = NaN;
        y_data(k, vals_to_rm) = NaN;

        % Fill NaNs with spline. 
        acc_data(k, :) = fillmissing(acc_data(k, :), 'spline');
        vel_data(k, :) = fillmissing(vel_data(k, :), 'spline');
        d_wall_data(k, :) = fillmissing(d_wall_data(k, :), 'spline');
        heading_data(k, :) = fillmissing(heading_data(k, :), 'previous');
        x_data(k, :) = fillmissing(x_data(k, :), 'spline');
        y_data(k, :) = fillmissing(y_data(k, :), 'spline');
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

        % forward velocity
        x = x_data(idx, :); % x position in pixels.
        y = y_data(idx, :); % y position in pixels. 
        x(2:end-1) = conv(x,smooth_kernel,'valid');
        y(2:end-1) = conv(y,smooth_kernel,'valid');
        x_data(idx, :) = x;
        y_data(idx, :) = y;
        dx = diff(x);
        dy = diff(y);
        vx = dx / samp_rate;
        vy = dy / samp_rate;
        fv = (vx .* cos(D(1:end-1)) + vy .* sin(D(1:end-1))); % mm /s 
        fv(fv<0)=NaN; % remove negative forward velocity.
        fv(fv>50)=NaN; % remove forward velocity > 50mm/s - too high.
        fv = fillmissing(fv, 'linear');
        fv_data(idx, :) = [fv(1), fv];

        c_data = [];
        c_data = av_data(idx, :)./fv_data(idx, :);
        vals_fv_zero = abs(fv_data(idx, :))<0.1;
        c_data(abs(c_data)==Inf)=NaN;
        c_data(vals_fv_zero) = NaN;
        c_data = fillmissing(c_data, 'previous');
        curv_data(idx, :) = c_data;
    end

    % Combine the matrices into an overall struct
    combined_data.vel_data = vel_data;
    combined_data.dist_data = dist_data;
    combined_data.dist_trav = dist_trav;
    combined_data.av_data = av_data;
    combined_data.fv_data = fv_data;
    combined_data.curv_data = curv_data;
    combined_data.heading_data = heading_data_unwrap;
    combined_data.heading_wrap = heading_wrap;
    combined_data.x_data = x_data;
    combined_data.y_data = y_data;

end 
