function centring_turning_traj_plots(x, y, t, d_data, cx, cy, time_or_dist)

    figure
    subplot(5,1,1)
    plot(d_data)
    ylabel('Distance from the centre of arena (mm)')
    
    % Calculate displacement from center
    dx = x - cx;
    dy = y - cy;
    
    % Radial distance from center
    r = sqrt(dx.^2 + dy.^2);
    
    % Angle (in radians) relative to center
    theta = atan2(dy, dx);
    
    % Compute time step (if uniform)
    if length(t) == length(x)
        dt = diff(t);
    else
        dt = ones(size(x)-1); % default: assume dt = 1
    end
    
    % Compute centripetal velocity (radial speed)
    vr = diff(r) ./ dt; % positive = moving outward, negative = inward
    
    % Compute angular velocity
    dtheta = diff(unwrap(theta)); % unwrap to avoid discontinuities
    omega = dtheta ./ dt; % radians per second (or per frame)
 
    % Compute change in position per frame (Euclidean distance)
    dx_step = diff(x);
    dy_step = diff(y);
    dr = sqrt(dx_step.^2 + dy_step.^2);  % actual movement distance per frame

    % Compute turning rate
    turning_rate = rad2deg(dtheta) ./ dr;
    
    % Optional: smoothing (to reduce noise)
    vr_smooth = movmean(vr, 5);
    omega_smooth = movmean(omega, 5);
    turning_rate_smooth = movmean(turning_rate, 5);
    
    t_mid = t(2:end); 
    d_mid = d_data(300:1199);
    
    % Plot relationship
    subplot(5,1,2)
    if time_or_dist == "time"
        scatter(vr_smooth, abs(turning_rate_smooth), 75, t_mid, 'filled');
        ylabel(colorbar, 'Time (frame)');
    else
        scatter(vr_smooth, abs(turning_rate_smooth), 75, d_mid, 'filled');
        ylabel(colorbar, 'Distance from C (mm)');
        clim([20 110])
    end 
    xlabel('Centripetal Velocity (mm/frame)');
    % ylabel('Angular Velocity (rad/frame)');
    ylabel('Turning rate (deg/mm)');
    % title('Centripetal vs Rotational Movement');
    colorbar;
    colormap(turbo); % or use 'parula', 'jet', 'viridis', etc.
    grid on;
    
    subplot(5,1,3)
    plot(vr_smooth)
    ylabel('Centripetal displacement (mm)')
   
    % Plot the trajectory
    % figure
    subplot(5,1,4:5)
    rectangle('Position',[1, 1, 245, 245], 'Curvature', [1,1], 'FaceColor', [0.95 0.95 0.95], 'EdgeColor', 'none')
    viscircles([cx, cy], 110, 'Color', [0.8 0.8 0.8], 'LineStyle', '--', 'LineWidth',1)
    viscircles([cx, cy], 63, 'Color', [0.8 0.8 0.8], 'LineStyle', '--', 'LineWidth',1)
    % viscircles([cx, cy], 40, 'Color', [1 0.8 0.8])
    hold on;
    plot(x, y, 'k-', 'LineWidth', 1.5, 'DisplayName', 'Path'); % black line for trajectory
    
    % Optionally, mark the start and end points
    plot(x(1), y(1), 'go', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'DisplayName', 'Start'); % green start
    plot(x(end), y(end), 'ro', 'MarkerFaceColor', 'r', 'DisplayName', 'End'); % red end
    
    % Mark the center of the arena
    plot(cx, cy, 'r+', 'MarkerSize', 18, 'LineWidth', 1.5, 'DisplayName', 'Centre');
    
    % Label the plot
    xlabel('X Position (mm)');
    ylabel('Y Position (mm)');
    axis equal;
    xlim([0 246])
    ylim([0 246])
    legend;

    f = gcf;
    f.Position = [4017 -504  576 1570]; %[ 223    64   571   961];
    

end 