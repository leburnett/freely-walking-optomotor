function plot_heading_angle_per_fly(Log, trx, n_flies, n_conditions, title_str, save_str, fig_exp_save_folder, save_figs)
    % Generate a figure composed of n_flies x 1 subplots showing each fly's
    % heading angle over the course of the freely-walking, increasing
    % contrast optomotor experiment. 

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

    % n_flies : int
    %       Number of flies in the experiment

    % n_conditions : int
    %       Number of conditions in the experiment.    

    % title_str : str
    %       string used for the title of the plot

    % save_str : str
    %       string used when saving the figure

    % fig_exp_save_folder : Path
    %        Path to save the figure    
    
    % save_figs : bool 
    %        Whether to save the figures and data or not. 

    figure
    for idx = 1:n_flies
    
        subplot(n_flies, 1, idx)

        % Heading angle data from 'trx'
        data = rad2deg(unwrap(trx(idx).theta));
    
        max_val = max(data);
        min_val = min(data);
        h = max_val - min_val;
    
        for ii = 1:n_conditions
    
            % Get the timing of each condition
            st_fr = Log.start_f(ii);
            stop_fr = Log.stop_f(ii)-1;
            w = stop_fr - st_fr;
    
            % Use the Log.dir value to get the stimulus direction.
            dir_id = Log.dir(ii);
    
            if dir_id == 0 
                if ii == 1 || ii == 33
                    col = [0.5 0.5 0.5 0.3];
                elseif ii == 17 || ii == 32
                    col = [0 0 0 0.3];
                else
                    col = [1 1 1];
                end 
            elseif dir_id == 1
                col = [0 0 1 Log.contrast(ii)*0.75];
            elseif dir_id == -1
                col = [1 0 1 Log.contrast(ii)*0.75];
            end 
    
            % Plot rectangles in the background of when the stimulus changes. 
            rectangle('Position', [st_fr, min_val, w, h], 'FaceColor', col, 'EdgeColor', [0.6 0.6 0.6])
            ylim([min_val, max_val])
            hold on 
            box off
            ax = gca;
            ax.XAxis.Visible = 'off';
            
            % Plot the heading angle
            plot(data, 'k', 'LineWidth', 1)
        end 
    
    end 
    sgtitle(strcat(title_str, ' - N=', string(n_flies)))
    f = gcf; 
    f.Position = [2162  -476  794  1520];
    
    if save_figs == true
        savefig(gcf, fullfile(fig_exp_save_folder, strcat('HeadingAngle_perfly_', save_str)))
    end 

end 