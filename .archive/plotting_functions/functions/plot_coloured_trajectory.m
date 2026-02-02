function plot_coloured_trajectory(x_bin, y_bin, col_bin, flyId)
    % Extract trajectory for the specified fly
    x = x_bin(flyId, :);
    y = y_bin(flyId, :);
    
    % Number of time points
    n_timepoints = size(x, 2);

    % Draw the arena outline:
    PPM = 4.1691; % Pixels per millimeter calibration
    CoA = [528, 520] / PPM; % Center of Arena
    x_c = CoA(1);
    y_c = CoA(2);
    R = 496 / PPM; % Radius of Arena
    
    % Define position for rectangle with full curvature to create a circle
    pos = [x_c - R, y_c - R, 2 * R, 2 * R];
    
    % Make the arena area blue to be able to see the trajectory
    % rectangle('Position', pos, 'Curvature', [1, 1], 'FaceColor', [0.0667    0.2392    0.5216], 'EdgeColor', [0.8 0.8 0.8], 'FaceAlpha', 0.2);
    rectangle('Position', pos, 'Curvature', [1, 1], 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', [0.8 0.8 0.8], 'FaceAlpha', 0.2);
    hold on
    rectangle('Position', pos, 'Curvature', [1, 1], 'FaceColor', 'none', 'EdgeColor', [0.6 0.6 0.6]);

    % Loop through each time segment and plot with corresponding color
    for t = 1:n_timepoints-2
        plot(x(t:t+1), y(t:t+1), 'Color', col_bin(t, :), 'LineWidth', 2);
    end
    
    % Labels and formatting
    axis tight;
    axis off;
    hold off;

    % Set axis limits
    xlim([x_c-R-20, x_c+R+20]);
    ylim([y_c-R-20, y_c+R+20]);

end
