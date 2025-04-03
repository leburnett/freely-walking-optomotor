function plot_trajectory_xy_tail(trx, frame_id, save_ttl, tail_length)
    % Plots the 2D trajectory of all flies on a given frame (frame_id).
    % Plot each fly's trajectory with a trailing tail fo 'tail_length'
    % frames.
    %
    % Inputs:
    %   trx - struct with the columns 'x' and 'y'. One row per fly. Output
    %   of FlyTracker.
    %
    % Example usage:
    %   plot_trajectory_xy_tail(trx, 1000, 10);

    if isempty(tail_length)
        tail_length = 90;
    end 

    n_flies = length(trx);
    rng = frame_id-tail_length:1:frame_id;

    figure; hold on

    % Plot a filled circle for the background:
    cent_arena = [528, -526]/4.1691;
    rad = 120;
    theta = linspace(0, 2*pi, 100); % 100 points for a smoother circle
    x_circ = rad * cos(theta) + cent_arena(1);
    y_circ = rad * sin(theta) + cent_arena(2);
    fill(x_circ, y_circ, 'w');

    cmap = autumn(15); % or jet(15)

    for f = 1:n_flies

        x = trx(f).x_mm;
        y = trx(f).y_mm;

        col = cmap(f, :);
      
        if length(x) ~= length(y)
            error('x and y must be the same length');
        end
    
        plot(x(rng), -y(rng), '-', 'Color', col, 'LineWidth', 2); % Plot trajectory   
        
        % Mark start and end points
        scatter(x(frame_id), -y(frame_id), 60, col, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.7); 

    end 
        
    % Add circle outline on top. 
    viscircles(cent_arena, rad, 'Color', [0.3 0.3 0.3], 'LineWidth', 1.5)

    % Formatting
    % xlim([0 250])
    % ylim([-250 0])
    hold off;
    axis off
    axis equal

    f = gcf;
    f.Position = [358   138   1025  905];

    fig_save_folder = "/Users/burnettl/Documents/Projects/oaky_cokey/figures/trajectories/p19";
    fname_pdf = fullfile(fig_save_folder, strcat("Traj_2025_0228_11-37_", save_ttl, ".pdf"));
    exportgraphics(f, fname_pdf ...
                    , 'ContentType', 'vector' ...
                    , 'BackgroundColor', 'none' ...
                    ); 
end
