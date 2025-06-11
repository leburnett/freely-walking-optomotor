function plot_trajectory_simple(x, y, cx, cy)
% 'x' and 'y' are the x and y values of the fly over the period you would
% like to plot the trajectory for. Arena centre is [cx, cy].

    rectangle('Position',[1, 1, 245, 245], 'Curvature', [1,1], 'FaceColor', [0.95 0.95 0.95], 'EdgeColor', 'none')
    viscircles([cx, cy], 110, 'Color', [0.8 0.8 0.8], 'LineStyle', '--', 'LineWidth',1)
    viscircles([cx, cy], 63, 'Color', [0.8 0.8 0.8], 'LineStyle', '--', 'LineWidth',1)
    hold on;
    plot(x, y, 'k-', 'LineWidth', 1.5, 'DisplayName', 'Path'); % black line for trajectory
    
    % Mark the start and end points
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

    % f = gcf;
    % f.Position = [4017 -504  576 1570]; %[ 223    64   571   961];

end 