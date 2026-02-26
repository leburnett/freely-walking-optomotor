function plot_trajectory_xy(x, y, fly_ID)
    % Plots the 2D trajectory of an object given x, y coordinates
    %
    % Inputs:
    %   x - Vector of x-coordinates over time
    %   y - Vector of y-coordinates over time
    %
    % Example usage:
    %   plotTrajectory(x, y);
    
    if length(x) ~= length(y)
        error('x and y must be the same length');
    end

    figure; hold on;
    for r = 1:4
        switch r
            case 1 % Before stimulus starts
                rng = 1:300; 
                col = [0.75 0.75 0.75];
            case 2 % Stimulus turning in one direction
                rng = 301:750;
                col = [1 0.7 0.7];
            case 3 
                rng = 751:1200;
                col = [0.7 0.7 1];
            case 4 
                rng = 1201:length(x); 
                col = [0.75 0.75 0.75];
        end 
        plot(x(rng), y(rng), '-', 'Color', col, 'LineWidth', 1.4); % Plot trajectory
    end    
    
    % Mark start and end points
    scatter(x(1), y(1), 100, 'w', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.2, 'DisplayName', 'Start'); % Green start point
    scatter(x(end), y(end), 100, 'k', 'filled', 'DisplayName', 'End'); % Red end point
    cent_arena = [528, 526]/4.1691;
    viscircles(cent_arena, 120, 'Color', 'k', 'LineWidth', 0.5)

    % Formatting
    xlim([0 240])
    ylim([0 250])
    xlabel('X Position');
    ylabel('Y Position');
    title(strcat("Fly - ", string(fly_ID)));
    legend('Pre', 'CW', 'CCW', 'Post', 'Start', 'End');
    axis equal; % Ensures correct aspect ratio
    hold off;
    axis off
end
