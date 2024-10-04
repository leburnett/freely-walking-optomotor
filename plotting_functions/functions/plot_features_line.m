function f = plot_features_line(combined_data, strain, sex, protocol)
% Generates subplot across all flies from a particular strain over one type
% of protocol. 
% Plots all individual flies as light gry lines and the mean of all the
% flies in black. 

    % % % % % % % 
    PROJECT_ROOT = '/Users/burnettl/Documents/Projects/oaky_cokey/'; %% Update for your computer. 
    disp(strcat('Project root: ', PROJECT_ROOT))
    % % % % % % % % 

    vel_data = combined_data.vel_data;
    % Set any values > 300 mm s-1 as NaN.
    vel_data(vel_data(:, :)>300) = NaN;

    av_data = combined_data.av_data;
    heading_data = combined_data.heading_data;
    dist_data = combined_data.dist_data;

    n_flies = height(vel_data);

    % Load an example Log file - for blue/pink stripes in bkg. 
    load(fullfile(PROJECT_ROOT, strcat('/example_logs/', protocol,'_log.mat')), 'Log');

     % % % % % % % % Subplot 1 = HEADING % % % % % % % % %

    t = tiledlayout(4,1, 'TileSpacing', 'loose', 'Padding','loose');
    nexttile

    ylim([-5000 5000])

    max_val = 5000; %max(max(heading_data));
    min_val = -5000; %min(min(heading_data));
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
        con_val = Log.contrast(ii);
        if con_val > 1.2
            con_val = 1;
        end 

        if dir_id == 0 
            if ii == 1 || ii == 33
                col = [0.5 0.5 0.5 0.3];
            elseif ii == 17 || ii == 32
                col = [0 0 0 0.5];
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
    plot(nanmean(heading_data), 'k', 'LineWidth', 2.5)
    ylabel('Heading (deg)')

    % % % % % % % % Subplot 2 = VELOCITY % % % % % % % % %

    nexttile

    ylim([0 200])
    max_val = 200; %max(max(vel_data));
    min_val = 0; %min(min(vel_data));
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
        con_val = Log.contrast(ii);
        if con_val > 1.2
            con_val = 1;
        end 

        if dir_id == 0 
            if ii == 1 || ii == 33
                col = [0.5 0.5 0.5 0.3];
            elseif ii == 17 || ii == 32
                col = [0 0 0 0.5];
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
        plot(vel_data(idx, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 1)
    end 

    % Plot the velocity
    plot(nanmean(vel_data), 'k', 'LineWidth', 2.5)
    ylabel('Velocity (mm s-1)')
    ylim([0 200])

    % % % % % % % % Subplot 3 = ANG VEL % % % % % % % % %

    nexttile

    ylim([-60 60])

    max_val = 60; %max(max(av_data));
    min_val = -60; %min(min(av_data));
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
        con_val = Log.contrast(ii);
        if con_val > 1.2
            con_val = 1;
        end 

        if dir_id == 0 
            if ii == 1 || ii == 33
                col = [0.5 0.5 0.5 0.3];
            elseif ii == 17 || ii == 32
                col = [0 0 0 0.5];
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
        plot(av_data(idx, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 1)
    end 

    % Plot the ang vel
    plot(nanmean(av_data), 'k', 'LineWidth', 2.5)
    ylabel('Angular velocity (deg s-1)')
   

    % % % % % % % % Subplot 4 = DISTANCE FROM CENTRE % % % % % % % % %

    nexttile

    n_conditions = height(Log);

    % Plot the pink and blue bckground rectangles. 

    for ii = 1:n_conditions

        % Get the timing of each condition
        st_fr = Log.start_f(ii);
        stop_fr = Log.stop_f(ii)-1;
        w = stop_fr - st_fr;

        % Use the Log.dir value to get the stimulus direction.
        dir_id = Log.dir(ii);
        con_val = Log.contrast(ii);
        if con_val > 1.2
            con_val = 1;
        end 

        if dir_id == 0 
            if ii == 1 || ii == 33
                col = [0.5 0.5 0.5 0.3];
            elseif ii == 17 || ii == 32
                col = [0 0 0 0.5];
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

    ylim([-5 125])
    plot([0 Log.stop_f(end)], [120 120], 'LineWidth', 1, 'Color', [0.3 0.3 0.3])
    plot([0 Log.stop_f(end)], [0 0], 'LineWidth', 1, 'Color', [0.3 0.3 0.3])

    % Plot the distance from the centre
    plot(nanmean(dist_data), 'k', 'LineWidth', 2.5)
    ylabel('Distance from the centre (mm)')


    title(t, strcat('FullExp-', strrep(strain, '_', '-'), '-',sex,'-', strrep(protocol, '_', '-'), '-n=', num2str(n_flies)), 'FontWeight', 'bold')
    f = gcf; 
    f.Position = [28   161   513   886];
    han=axes(f, 'visible','off');
    han.XLabel.Visible='on';
    xlabel(han, 'Time / frames / conditions')

end 