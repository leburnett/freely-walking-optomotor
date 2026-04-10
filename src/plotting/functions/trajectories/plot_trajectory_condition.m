function plot_trajectory_condition(x, y, cx, cy, line_colour, cond_name, traj_only, start_stop, show_phases)
% 'x' and 'y' are the x and y values of the fly over the period you would
% like to plot the trajectory for. Arena centre is [cx, cy].

if ~traj_only
    rectangle('Position',[0.25, 2.5, 245, 245], 'Curvature', [1,1], 'FaceColor', [0.95 0.95 0.95], 'EdgeColor', 'none')
    viscircles([cx, cy], 121, 'Color', [0.8 0.8 0.8], 'LineStyle', '-', 'LineWidth', 1) % Edge
    viscircles([cx, cy], 110, 'Color', [0.8 0.8 0.8], 'LineStyle', '-', 'LineWidth', 0.8) % 10mm from edge
    % viscircles([cx, cy], 63, 'Color', [0.8 0.8 0.8], 'LineStyle', '--', 'LineWidth',1) % Half way
end 
    hold on;
    if show_phases
        p1= plot(x(1:300), y(1:300), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1.5, 'DisplayName', 'OFF');
        p2 = plot(x(300:750), y(300:750), '-', 'Color', [0.231 0.510 0.965], 'LineWidth', 1.5, 'DisplayName', 'CCW'); % line for trajectory
        p3 = plot(x(750:1200), y(750:1200), '-', 'Color', [0.925 0.282 0.600], 'LineWidth', 1.5, 'DisplayName', 'CW'); % line for trajectory
        plot(x(1200:1500), y(1200:1500), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1.5);
    else
        plot(x, y, '-', 'Color', line_colour, 'LineWidth', 1.5, 'DisplayName', cond_name); % line for trajectory
    end 
    
    if start_stop == 1
        % Mark the start
        p5 = plot(x(1), y(1), 'o', 'MarkerSize', 13, 'MarkerFaceColor', [0.3 0.6 0.6], 'MarkerEdgeColor', 'k', 'DisplayName', 'Start'); % white start
    elseif start_stop == 2
        % Mark the end
        p6 = plot(x(end), y(end), 'o', 'MarkerSize', 13, 'MarkerFaceColor', [0.9 0 0], 'MarkerEdgeColor', 'k', 'DisplayName', 'End'); % dark grey end
    elseif start_stop == 3
        % Mark the start and end points
        p5 = plot(x(1), y(1), 'o', 'MarkerSize', 13, 'MarkerFaceColor', [0.3 0.6 0.6], 'MarkerEdgeColor', 'k', 'DisplayName', 'Start'); % white start
        p6 = plot(x(end), y(end), 'o', 'MarkerSize', 13, 'MarkerFaceColor', [0.9 0 0], 'MarkerEdgeColor', 'k', 'DisplayName', 'End'); % dary grey end
    end 
    
  if ~traj_only  
    % Mark the center of the arena
    p7 = plot(cx, cy, 'k+', 'MarkerSize', 18, 'LineWidth', 1.5, 'DisplayName', 'Centre');
  end 

    % Label the plot
    xlabel('X Position (mm)');
    ylabel('Y Position (mm)');
    axis equal;
    xlim([-2 247])
    ylim([0 248])

    % Text labels for phases and start/end markers
    if show_phases
        % Legend-style labels in bottom-left corner
        text(0.01, 0.05, 'No stimulus', 'Units', 'normalized', ...
            'FontSize', 16, 'FontWeight', 'bold', 'Color', [0.5 0.5 0.5]);
        text(0.01, 0.1, 'CCW', 'Units', 'normalized', ...
            'FontSize', 16, 'FontWeight', 'bold', 'Color', [0.231 0.510 0.965]);
        text(0.01, 0.15, 'CW', 'Units', 'normalized', ...
            'FontSize', 16, 'FontWeight', 'bold', 'Color', [0.925 0.282 0.600]);

        % Start label above and to the right of start point
        x_start = x(find(~isnan(x), 1, 'first'));
        y_start = y(find(~isnan(y), 1, 'first'));
        text(x_start + 8, y_start, 'Start', ...
            'FontSize', 16, 'Color', [0.3 0.6 0.6]);

        % End label to the right of end point
        x_end = x(find(~isnan(x), 1, 'last'));
        y_end = y(find(~isnan(y), 1, 'last'));
        text(x_end + 8, y_end, 'End', ...
            'FontSize', 16, 'Color', [0.9 0 0]);
    end

end