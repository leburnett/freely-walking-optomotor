function f = plot_dist_2_centre_per_fly(Log, feat, title_str)

% Inputs
% ______

% Log : struct
%       Struct of size [n_conditions x n_flies] with details about the
%       contrast, direction, start and stop times and start and stop
%       frames for each condition. 

% feat : struct
%       Struct of size [1 x n_flies] with details about each fly during
%       the experiment, such as the x and y position, orientation of
%       fitted ellipse. 

% title_str : str
%       string used for the title of the plot.

    n_flies = numel(feat.data(:,1,1));

    figure
    for idx = 1:n_flies
        subplot(n_flies, 1, idx)
        V = feat.data(idx,:,9);
        n_conditions = height(Log);

        for ii = 1:n_conditions
        
            % create the plot
            st_fr = Log.start_f(ii);
            stop_fr = Log.stop_f(ii)-1;
            w = stop_fr - st_fr;
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
            
            % Add rectangles denoting the different types of experiment.
            rectangle('Position', [st_fr, -20, w, 170], 'FaceColor', col, 'EdgeColor', [0.6 0.6 0.6]);
            % ylim([-20, max_val])
            hold on 
            box off
            ax = gca;
            ax.XAxis.Visible = 'off';
        end 

        plot(120-V, 'k', 'LineWidth', 1)
        ylim([-15 135])
        plot([0 8500], [120 120], 'LineWidth', 1, 'Color', [0.7 0.7 0.7])
        plot([0 8500], [0 0], 'LineWidth', 1, 'Color', [0.7 0.7 0.7])

    end 

    sgtitle(strcat(title_str, ' - N=', string(n_flies)))
    f = gcf; 
    % f.Position = [2162  -476  794  1520];
    f.Position = [1183 75 618 972];

    han=axes(f, 'visible','off');
    han.YLabel.Visible='on';
    han.XLabel.Visible='on';
    ylabel(han, 'Distance from centre of arena (mm)', 'Position', [-0.06 0.5])
    xlabel(han, 'Time / frames / conditions')
    
end 