function plot_line_velocity(data_path, save_figs, fig_save_path, mean_med, vel_or_ang)

    % Plot the velocity per fly over the course of the experiment. 
    
    % Should work that you can either use an individual time/ experiment folder
    % or a folder containing the data collected across experiments after
    % running 'process_freely_walking_optomotor_vel()'. 
    
    cd(data_path)
    
    % Check for 'dist_to_wall' files within the folder. 
    % If the 'data_path' is an experiment folder then this should find the appropriate file.  
    vel_files = dir('*-feat.mat');
    
    % Else, if no files are found then the 'data_path' is the combined results
    % path. 
    if isempty(vel_files)
        vel_files = dir('*velocity*');
    end 
    
    n_files = length(vel_files);
    
     % Load the data
    load(fullfile(vel_files(1).folder, vel_files(1).name), 'Log', 'feat');

    % Generate figure: 
    figure

    % Add background
        n_conditions = height(Log);
        h = 570000;
        min_val = -10;
        max_val = 570000;
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
            ylim([min_val, max_val])
            hold on 
            box off
            % ax = gca;
            % ax.XAxis.Visible = 'off';
            xticks([])
        end 
    
        % ylim([-10 130])

    % Add data traces
    for idx = 1:n_files 

        % Load the data
        load(fullfile(vel_files(idx).folder, vel_files(idx).name), 'feat'); % add 'save_str' back here eventually. 

        if vel_or_ang == "vel" % velocity
            data = feat.data(:, :, 1);
        elseif vel_or_ang == "ang" %angular velocity
            data = feat.data(:, :, 2);
        end 
        n_flies = size(data, 1);

        for i = 1:n_flies
            plot(data(i, :), 'Color', [0.5 0.5 0.5], 'LineWidth', 0.01); 
            hold on 
        end
    end 
    
    data = feat.data(:, :, 1);

    if numel(data(1, :)) < 5200
        min_length = 5150;
    elseif numel(data(1, :)) < 6500
        min_length =6300;
    elseif numel(data(1, :)) < 14700
        min_length = 14500;
    elseif numel(data(1, :)) < 18900
        min_length = 18840;
    else 
        min_length = 5150;
    end 
    
    % Add mean 
    all_data = [];
    for ii = 1:n_files
        % Load the data
        load(fullfile(vel_files(ii).folder, vel_files(ii).name), 'feat');
        if vel_or_ang == "vel" % velocity
            data = feat.data(:, :, 1);
        elseif vel_or_ang == "ang" % ang velocity
            data = feat.data(:, :, 2);
        end 

        n_flies = size(data, 1);

        for jj = 1: n_flies
            dtt = data(jj, :);
            if numel(dtt)<min_length 
                continue
            else
                dtt = dtt(1:min_length);
                all_data = vertcat(all_data, dtt);
            end 
        end 
    end 

    % Remove entries with unrealistic velcoity values (>200mm/s)
    if vel_or_ang == "vel"
        all_data(all_data>200)=0;
        % Remove flies that don't move during the trial...
        mean_vel_per_fly = nanmean(all_data,2);
        all_data(mean_vel_per_fly<0.1, :) = [];
    end 

    n_flies_total = size(all_data, 1);
    
    if mean_med == "med"
        av_resp = nanmedian(all_data);
    elseif mean_med == "mean"
        av_resp = nanmean(all_data);
    end 
    plot(av_resp, 'k', 'LineWidth', 2)
    xlabel('frame')
    if vel_or_ang == "vel"
        ylabel('Velocity (mm/s)')
    elseif vel_or_ang == "ang"
        ylabel('Angular velocity (rad/s)')
    end 
    f = gcf;
    f.Position = [23  623  1716  403];
    ax = gca;
    ax.LineWidth = 1.2;
    ax.FontSize = 12;
    ax.TickDir = 'out';
    ax.TickLength  =[0.005 0.005];

    if vel_or_ang == "vel"
        title(strcat('Velocity - N = ', string(n_flies_total)))
    elseif vel_or_ang == "ang"
        title(strcat('Angular velocity - N = ', string(n_flies_total)))
    end 

    % hold on
    % plot([0 min_length], [0 0], 'k', 'LineWidth', 0.2)
    % plot([0 min_length], [20 20], 'k', 'LineWidth', 0.2)
    % plot([0 min_length], [40 40], 'k', 'LineWidth', 0.2)
    % plot([0 min_length], [60 60], 'k', 'LineWidth', 0.2) 
    % plot([0 min_length], [80 80], 'k', 'LineWidth', 0.2)
    % plot([0 min_length], [100 100], 'k', 'LineWidth', 0.2) 
    % plot([0 min_length], [120 120], 'k', 'LineWidth', 0.2) 
    
    ylim([0 15])
    
    if save_figs 
        if vel_or_ang == "vel"
            savefig(gcf, fullfile(fig_save_path, strcat('Velocity_', save_str,'_', mean_med,'.fig')))
        elseif vel_or_ang == "ang"
            savefig(gcf, fullfile(fig_save_path, strcat('AngVel_', save_str,'_', mean_med,'.fig')))
        end 

    end 

end 