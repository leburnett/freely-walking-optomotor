function plot_ang_vel_ratio(Log, feat, trx, n_flies, n_conditions, fps, save_str, title_str, fig_exp_save_folder, save_figs)

% Plot for the angular velocity and velocity ratio of all flies
% in one experiment

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
%       Number of flies in the experiment.

% n_conditions : int
%       Number of conditions in the experiment.

% fps : int
%       acquisition rate of the camera in frames per second (fps).

% save_str : str
%       string used when saving the figure.

% fig_exp_save_folder : Path
%        Path to save the figure.

% save_figs : bool
%        Whether to save the figures and data or not.


% Fixed paramters:
samp_rate = 1/fps;
method = 'line_fit';
t_window = 16;
cutoff = [];
ang_vel_ratio = zeros(n_flies, length(feat.data))

figure
for idx = 1:n_flies
    % unwrap the heading data from trx
    D = unwrap(trx(idx).theta);
    % convert heading to angular velocity
    ang_vel = vel_estimate(D, samp_rate, method, t_window, cutoff);
    
    % pull velocity data from feat
    vel = feat.data(idx,:,1);

    % create angular velocity vs. velocity ratio
    ang_vel_ratio(idx, :) = ang_vel./vel;
    ang_vel_ratio(idx, vel==0) = 0

    subplot(n_flies, 1, idx)
    max_val = max(ang_vel_ratio(idx, :) );
    min_val = min(ang_vel_ratio(idx, :) );
    h = max_val - min_val;

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
        rectangle('Position', [st_fr, min_val, w, h], 'FaceColor', col, 'EdgeColor', [0.6 0.6 0.6])
        %ylim([min_val, max_val])
        hold on
        box off
        ax = gca;
        ax.XAxis.Visible = 'off';
    end

    plot(ang_vel_ratio(idx, :) , 'k', 'LineWidth', 1)

end

sgtitle(strcat(title_str, ' - N=', string(n_flies)))
f = gcf;
f.Position = [2162  -476  794  1520];

if save_figs == true
    savefig(gcf, fullfile(fig_exp_save_folder, strcat('AngVel_perfly_', save_str)))
end

end