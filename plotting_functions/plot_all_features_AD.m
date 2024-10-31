function f = plot_all_features_AD(Log, feat, trx, title_str)

    % Generate a figure composed of n_flies x 1 subplots showing each fly's
    % heading angle over the course of the freely-walking, increasing
    % contrast optomotor experiment. 

    % Inputs
    % ______

    % Log : struct
    %       Struct of size [n_conditions x n_flies] with details about the
    %       contrast, direction, start and stop times and start and stop
    %       frames for each condition. 

    % trk : struct
    %       Struct of size [1 x n_flies] with details about each fly during
    %       the experiment, such as the x and y position, orientation of
    %       fitted ellipse. 

    % feat : struct
    
    % Fixed paramters: 
    n_flies = length(trx);
    % Log = log_2;
    % title_str = 'log_2_allfeatures';

    fps = 30;
    samp_rate = 1/fps; 
    method = 'line_fit';
    t_window = 16;
    cutoff = [];

    figure

    % % % % % % % % Subplot 1 = HEADING % % % % % % % % %

    heading_data = []; 
    ang_vel_data = [];
    for idx = 1:n_flies
        D = rad2deg(unwrap(trx(idx).theta)); 
        heading_data(idx, :) = D;
        ang_vel_data(idx, :) = vel_estimate(D, samp_rate, method, t_window, cutoff);
    end 
    
    subplot(4, 1, 1)

    max_val = max(max(heading_data));
    min_val = min(min(heading_data));
    h = max_val - min_val;
    
    n_conditions = height(Log);

    % Plot the pink and blue bckground rectangles. 

    for ii = 4:n_conditions

        % Get the timing of each condition
        st_fr = Log.start_f(ii);
        stop_fr = Log.stop_f(ii)-1;
        w = stop_fr - st_fr;

        % Use the Log.dir value to get the stimulus direction.
        dir_id = Log.dir(ii);
        con_val = 1;
        if con_val > 1.2
            con_val = 1;
        end 

        if dir_id == 0 
            if ii == 1 || ii == 33
                col = [0.5 0.5 0.5 0.3];
            elseif ii == 17 || ii == 32 %% gray for the flickers? i think?
                col = [0 0 0 0.3];
            else
                col = [1 1 1];
            end 

        elseif dir_id == 1
            col = [0 0 1 con_val*0.75];
        elseif dir_id == -1
            col = [1 0 1 con_val*0.75];
        end 

        % Plot rectangles in the background of when the stimulus changes. 
        rectangle('Position', [st_fr, min_val, w, h], 'FaceColor', col, 'EdgeColor', [0.6 0.6 0.6])
        ylim([min_val, max_val])
        hold on 
        box off
        ax = gca;
        ax.XAxis.Visible = 'off';
    end 

    for idx = 1:n_flies
      % Plot the heading angle per fly
        plot(heading_data(idx, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 1)
    end 

    % Plot the heading angle
    plot(mean(heading_data), 'k', 'LineWidth', 2.5)
    % title('Heading (deg)')
    ylabel('Heading (deg)')



    % % % % % % % % Subplot 2 = VELOCITY % % % % % % % % %

    velocity_data = feat.data(:, :, 1);
    subplot(4, 1, 2)

    max_val = max(max(velocity_data));
    min_val = min(min(velocity_data));
    h = max_val - min_val;
    
    n_conditions = height(Log);

    % Plot the pink and blue bckground rectangles. 

    for ii = 1:n_conditions

        % Get the timing of each condition
        st_fr = Log.start_f(ii);
        stop_fr = Log.stop_f(ii)-1;
        w = stop_fr - st_fr;

        % Use the Log.dir value to get the stimulus direction.
        dir_id = Log.dir(ii);
        con_val = 1;
        if con_val > 1.2
            con_val = 1;
        end 

        if dir_id == 0 
            if ii == 1 || ii == 33
                col = [0.5 0.5 0.5 0.3];
            elseif ii == 17 || ii == 32
                col = [0 0 0 0.3];
            else
                col = [1 1 1];
            end 

        elseif dir_id == 1
            col = [0 0 1 con_val*0.75];
        elseif dir_id == -1
            col = [1 0 1 con_val*0.75];
        end 

        % Plot rectangles in the background of when the stimulus changes. 
        rectangle('Position', [st_fr, min_val, w, h], 'FaceColor', col, 'EdgeColor', [0.6 0.6 0.6])
        ylim([min_val, max_val])
        hold on 
        box off
        ax = gca;
        ax.XAxis.Visible = 'off';
    end 

    for idx = 1:n_flies
      % Plot the velocity per fly
        plot(velocity_data(idx, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 1)
    end 

    % Plot the velocity
    plot(mean(velocity_data), 'k', 'LineWidth', 2.5)
    ylabel('Velocity (mm s-1)')

    % % % % % % % % Subplot 3 = ANG VEL % % % % % % % % %

    subplot(4, 1, 3)

    max_val = max(max(ang_vel_data));
    min_val = min(min(ang_vel_data));
    h = max_val - min_val;
    
    n_conditions = height(Log);

    % Plot the pink and blue bckground rectangles. 

    for ii = 1:n_conditions

        % Get the timing of each condition
        st_fr = Log.start_f(ii);
        stop_fr = Log.stop_f(ii)-1;
        w = stop_fr - st_fr;

        % Use the Log.dir value to get the stimulus direction.
        dir_id = Log.dir(ii);
        con_val = 1;
        if con_val > 1.2
            con_val = 1;
        end 

        if dir_id == 0 
            if ii == 1 || ii == 33
                col = [0.5 0.5 0.5 0.3];
            elseif ii == 17 || ii == 32
                col = [0 0 0 0.3];
            else
                col = [1 1 1];
            end 

        elseif dir_id == 1
            col = [0 0 1 con_val*0.75];
        elseif dir_id == -1
            col = [1 0 1 con_val*0.75];
        end 

        % Plot rectangles in the background of when the stimulus changes. 
        rectangle('Position', [st_fr, min_val, w, h], 'FaceColor', col, 'EdgeColor', [0.6 0.6 0.6])
        ylim([min_val, max_val])
        hold on 
        box off
        ax = gca;
        ax.XAxis.Visible = 'off';
    end 

    for idx = 1:n_flies
      % Plot the ang vel per fly
        plot(ang_vel_data(idx, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 1)
    end 

    % Plot the ang vel
    plot(mean(ang_vel_data), 'k', 'LineWidth', 2.5)
    ylabel('Angular velocity (deg s-1)')


    % % % % % % % % Subplot 4 = DISTANCE FROM CENTRE % % % % % % % % %

    dist_data = feat.data(:, :, 9);
    dist_data = 120-dist_data;
    subplot(4, 1, 4)
    
    n_conditions = height(Log);

    % Plot the pink and blue bckground rectangles. 

    for ii = 1:n_conditions

        % Get the timing of each condition
        st_fr = Log.start_f(ii);
        stop_fr = Log.stop_f(ii)-1;
        w = stop_fr - st_fr;

        % Use the Log.dir value to get the stimulus direction.
        dir_id = Log.dir(ii);
        con_val = 1;
        if con_val > 1.2
            con_val = 1;
        end 

        if dir_id == 0 
            if ii == 1 || ii == 33
                col = [0.5 0.5 0.5 0.3];
            elseif ii == 17 || ii == 32
                col = [0 0 0 0.3];
            else
                col = [1 1 1];
            end 

        elseif dir_id == 1
            col = [0 0 1 con_val*0.75];
        elseif dir_id == -1
            col = [1 0 1 con_val*0.75];
        end 

        % Plot rectangles in the background of when the stimulus changes. 
        rectangle('Position', [st_fr, -20, w, 170], 'FaceColor', col, 'EdgeColor', [0.6 0.6 0.6])
        ylim([min_val, max_val])
        hold on 
        box off
        ax = gca;
        ax.XAxis.Visible = 'off';
    end 

    for idx = 1:n_flies
      % Plot the distance from the centre per fly
        plot(dist_data(idx, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 1)
    end 

    ylim([-15 135])
    plot([0 Log.stop_f(end)], [120 120], 'LineWidth', 1, 'Color', [0.7 0.7 0.7])
    plot([0 Log.stop_f(end)], [0 0], 'LineWidth', 1, 'Color', [0.7 0.7 0.7])

    % Plot the distance from the centre
    plot(mean(dist_data), 'k', 'LineWidth', 2.5)
    ylabel('Distance from the centre (mm)')


    sgtitle(strcat(title_str, ' - N=', string(n_flies)))
    f = gcf; 
    % f.Position = [1234  71  567  976]; %% does something wierd,
    % uncommented for now
    han=axes(f, 'visible','off');
    han.XLabel.Visible='on';
    xlabel(han, 'Time / frames / conditions')

end 