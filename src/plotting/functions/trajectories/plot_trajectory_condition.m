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
        p2 = plot(x(300:750), y(300:750), '-', 'Color', [0.231 0.510 0.965], 'LineWidth', 1.5, 'DisplayName', 'CW'); % line for trajectory
        p3 = plot(x(750:1200), y(750:1200), '-', 'Color', [0.925 0.282 0.600], 'LineWidth', 1.5, 'DisplayName', 'CCW'); % line for trajectory
        plot(x(1200:1500), y(1200:1500), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1.5);
    else
        plot(x, y, '-', 'Color', line_colour, 'LineWidth', 1.5, 'DisplayName', cond_name); % line for trajectory
    end 
    
    if start_stop == 1
        % Mark the start
        p5 = plot(x(1), y(1), 'o', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'DisplayName', 'Start'); % white start
    elseif start_stop == 2
        % Mark the end
        p6 = plot(x(end), y(end), 'o', 'MarkerFaceColor', [0 0 0], 'MarkerEdgeColor', 'k', 'DisplayName', 'End'); % dark grey end
    elseif start_stop == 3
        % Mark the start and end points
        p5 = plot(x(1), y(1), 'o', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'DisplayName', 'Start'); % white start
        p6 = plot(x(end), y(end), 'o', 'MarkerFaceColor', [0 0 0], 'MarkerEdgeColor', 'k', 'DisplayName', 'End'); % dary grey end
    end 
    
  if ~traj_only  
    % Mark the center of the arena
    p7 = plot(cx, cy, 'r+', 'MarkerSize', 18, 'LineWidth', 1.5, 'DisplayName', 'Centre');
  end 

    % Label the plot
    xlabel('X Position (mm)');
    ylabel('Y Position (mm)');
    axis equal;
    xlim([-2 247])
    ylim([0 248])

    if ~traj_only 
        legend([p1, p2, p3, p5, p6, p7], {'OFF', 'CW', 'CCW', 'Start', 'End', 'Centre'});
    end 

    % f = gcf;
    % f.Position = [4017 -504  576 1570]; %[ 223    64   571   961];

end 