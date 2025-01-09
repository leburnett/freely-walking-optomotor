function f = plot_all_features_filt(LOG, comb_data, protocol, title_str)

    % Generate a figure composed of n_flies x 1 subplots showing each fly's
    % heading angle over the course of the freely-walking, increasing
    % contrast optomotor experiment. 

    % Inputs
    % ______

    % Log : struct
    %       Struct of size [n_conditions x n_flies] with details about the
    %       contrast, direction, start and stop times and start and stop
    %       frames for each condition. 

    % comb_data : struct

    % title_str : str
    %       title to use in the plot.
    
    % Fixed paramters: 
    n_flies = length(trx);

    figure
    % % % % % % % % Subplot 1 = HEADING % % % % % % % % %

    heading_data = comb_data.heading_data;
    ang_vel_data = comb_data.av_data;

    subplot(4, 1, 1)

    max_val = max(max(heading_data));
    min_val = min(min(heading_data));
    xmax = size(heading_data, 2);
    
    % Plot the boundaries between when the stimulus changes.
    plot_pink_blue_rects(LOG, protocol, min_val, max_val)

    for idx = 1:n_flies
      % Plot the heading angle per fly
        plot(heading_data(idx, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 1)
    end 

    % Plot the heading angle
    plot(mean(heading_data), 'k', 'LineWidth', 2.5)
    ylabel('Heading (deg)')
    xlim([0 xmax])

    % % % % % % % % Subplot 2 = VELOCITY % % % % % % % % %

    velocity_data = comb_data.vel_data;
    subplot(4, 1, 2)
   
    % Plot the boundaries between when the stimulus changes.
    plot_pink_blue_rects(LOG, protocol, -2, 50)

    for idx = 1:n_flies
      % Plot the velocity per fly
        plot(velocity_data(idx, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 1)
    end 

    % Plot the velocity
    plot(mean(velocity_data), 'k', 'LineWidth', 2.5)
    ylabel('Velocity (mm s-1)')
    ylim([-2 50])
    xlim([0 xmax])
    % % % % % % % % Subplot 3 = ANG VEL % % % % % % % % %

    subplot(4, 1, 3)

    max_val = prctile(ang_vel_data(:), 99.5);
    min_val = prctile(ang_vel_data(:), 0.5);

    % Plot the boundaries between when the stimulus changes.
    plot_pink_blue_rects(LOG, protocol, min_val, max_val)

    for idx = 1:n_flies
      % Plot the ang vel per fly
        plot(ang_vel_data(idx, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 1)
    end 

    % Plot the ang vel
    plot(mean(ang_vel_data), 'k', 'LineWidth', 2.5)
    ylabel('Angular velocity (deg s-1)')
    xlim([0 xmax])

    % % % % % % % % Subplot 4 = DISTANCE FROM CENTRE % % % % % % % % %

    dist_data = comb_data.dist_data;

    subplot(4, 1, 4)
    min_val = -1;
    max_val = 120;
    
    % Plot the boundaries between when the stimulus changes.
    plot_pink_blue_rects(LOG, protocol, min_val, max_val)

    for idx = 1:n_flies
      % Plot the distance from the centre per fly
        plot(dist_data(idx, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 1)
    end 

    ylim([-1 121])
    plot([0 xmax], [120 120], 'LineWidth', 1, 'Color', [0 0 0])
    plot([0 xmax], [0 0], 'LineWidth', 1, 'Color', [0 0 0])

    % Plot the distance from the centre
    plot(mean(dist_data), 'k', 'LineWidth', 2.5)
    ylabel('Distance from the centre (mm)')
    xlim([0 xmax])

    title_str = strrep(title_str, '_', '-');
    sgtitle(strcat(title_str, ' - N=', string(n_flies)))
    f = gcf; 
    f.Position = [1234  71  567  976];
    han=axes(f, 'visible','off');
    han.XLabel.Visible='on';
    xlabel(han, 'Time / frames / conditions')

end 