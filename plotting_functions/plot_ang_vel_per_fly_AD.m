function f = plot_ang_vel_per_fly_AD(Log, trx, title_str)
    
    % Inputs
    % ______

    % Log : struct
    %       Struct of size [n_conditions x n_flies] with details about the
    %       contrast, direction, start and stop times and start and stop
    %       frames for each condition. 

    % trx : struct
    %       Struct of size [1 x n_flies] with details about each fly during
    %       the experiment, such as the x and y position, orientation of
    %       fitted ellipse. 

    % title_str : str
    %       string used for the title of the plot.

    n_flies = length(trx);
    % Log = log_2;
    % title_str = 'log1plot'; %% for test plotting

    % Fixed paramters: 
    fps = 30;
    samp_rate = 1/fps; 
    method = 'line_fit';
    t_window = 16;
    cutoff = []; 

    figure
    for idx = 1:n_flies
        % unwrap the heading data
        D = rad2deg(unwrap(trx(idx).theta));
        % convert heading to angular velocity
        V = vel_estimate(D, samp_rate, method, t_window, cutoff);
    
        subplot(n_flies, 1, idx)
        max_val = max(V);
        min_val = min(V);
        h = max_val - min_val;
        
        n_conditions = height(Log);

        for ii = 1:n_conditions
        
            % create the plot
            st_fr = Log.start_f(ii);
            stop_fr = Log.stop_f(ii)-1;
            w = stop_fr - st_fr;
            dir_id = Log.dir(ii);
            con_val = 1; %% changed to 1 (instead of Log.contrast(ii))
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
            
            % Add rectangles denoting the different types of experiment.
            rectangle('Position', [st_fr, min_val, w, h], 'FaceColor', col, 'EdgeColor', [0.6 0.6 0.6])
            ylim([min_val, max_val])
            hold on 
            box off
            ax = gca;
            ax.XAxis.Visible = 'off';
        end 

        plot(V, 'k', 'LineWidth', 1)

    end 

    sgtitle(strcat(title_str, ' - N=', string(n_flies)))
    f = gcf; 
    % f.Position = [2162  -476  794  1520]; % dont know why this doesn't
    % work, look into it
    
    han=axes(f, 'visible','off');
    han.YLabel.Visible='on';
    han.XLabel.Visible='on';
    ylabel(han, 'Angular velocity (deg s-1)', 'Position', [-0.06 0.5])
    xlabel(han, 'Time / frames / conditions')


end 