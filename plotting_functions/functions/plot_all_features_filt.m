function f = plot_all_features_filt(LOG, comb_data, protocol, title_str)
% Generates figure with 4 timeseries subplots (velocity, angular velocity,
% turning rate and distance from the centre) over the entire course of the
% experiment. The data from each fly is plotted in light grey and the mean
% across all flies is in black. 
% 
% Rectangles are plotted behind the data to show the different conditions. 
% Dark grey rectangles represent acclim periods, white rectangles for
% intervals between conditions, pink rectangles for clockwise stimuli and
% blue rectangles for counter-clockwise stimuli.

    % Inputs
    % ______

    % LOG : struct
    %       Struct of size [n_conditions x n_flies] with details about the
    %       contrast, direction, start and stop times and start and stop
    %       frames for each condition. 

    % comb_data : struct

    % protocol : string 
    %       String in the format "protocol_X" where X is an integer.

    % title_str : str
    %       title to use in the plot.
    
    figure

    % % % % % % % % Subplot 1 = VELOCITY % % % % % % % % %
    
    velocity_data = comb_data.fv_data;
    [n_flies, xmax] = size(velocity_data);

    subplot(4, 1, 1)
   
    % Plot the boundaries between when the stimulus changes.
    plot_pink_blue_rects(LOG, protocol, -2, 50)

    for idx = 1:n_flies
      % Plot the velocity per fly
        plot(velocity_data(idx, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 0.2)
    end 

    % Plot the velocity
    plot(mean(velocity_data), 'w', 'LineWidth', 1.25)
    plot(smoothdata(mean(velocity_data), 'lowess'), 'k', 'LineWidth', 1.25)
    ylabel('Forward velocity (mm s-1)')
    ylim([-2 30])
    xlim([0 xmax])

    % % % % % % % % Subplot 2 = ANG VEL % % % % % % % % %

    subplot(4, 1, 2)
    
    ang_vel_data = comb_data.av_data;

    max_val = prctile(ang_vel_data(:), 98.5);
    min_val = prctile(ang_vel_data(:), 1.5);

    % Plot the boundaries between when the stimulus changes.
    plot_pink_blue_rects(LOG, protocol, min_val, max_val)

    for idx = 1:n_flies
      % Plot the ang vel per fly
        plot(ang_vel_data(idx, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 0.2)
    end 

    % Plot the ang vel
    plot(mean(ang_vel_data), 'w', 'LineWidth', 1.25)
    plot(smoothdata(mean(ang_vel_data), 'lowess'), 'k', 'LineWidth', 1.25)
    ylabel('Angular velocity (deg s-1)')
    xlim([0 xmax])

    % % % % % % % Subplot 3 = CURVATURE / Turning rate % % % % % % % % %

    curv_data = comb_data.curv_data;

    subplot(4, 1, 3)

    max_val = prctile(curv_data(:), 98.5);
    min_val = prctile(curv_data(:), 1.5);
    
    % Plot the boundaries between when the stimulus changes.
    plot_pink_blue_rects(LOG, protocol, min_val, max_val)

    for idx = 1:n_flies
        plot(curv_data(idx, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5)
    end 

    % Plot 
    plot(mean(curv_data), 'w', 'LineWidth', 1.25)
    % plot(smoothdata(mean(curv_data), 'lowess'), 'k', 'LineWidth', 1)
    plot(smoothdata(mean(curv_data), 'movmedian'), 'k', 'LineWidth', 1.25)
    ylabel('Curvature (deg/mm)')
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
    plot(mean(dist_data), 'Color', 'k', 'LineWidth', 1.5)
    % plot(smoothdata(mean(dist_data), 'lowess'), 'k', 'LineWidth', 1.5)
    ylabel('Distance from the centre (mm)')
    xlim([0 xmax])

    title_str = strrep(title_str, '_', '-');
    sgtitle(strcat(title_str, ' - N=', string(n_flies)))
    f = gcf; 
    f.Position = [6  289  1321  757]; %[1234  71  567  976];
    han=axes(f, 'visible','off');
    han.XLabel.Visible='on';
    xlabel(han, 'Time / frames / conditions')

end 