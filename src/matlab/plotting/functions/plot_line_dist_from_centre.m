function plot_line_dist_from_centre(data_path, save_figs, fig_save_path, mean_med)

    % Plot the distance from the centre of the arena per fly. 
    
    % Should work that you can either use an individual time/ experiment folder
    % or a folder containing the data collected across experiments after
    % running 'process_freely_walking_optomotor_dist_centre()'. 
    
    cd(data_path)
    
    % Check for 'dist_to_wall' files within the folder. 
    % If the 'data_path' is an experiment folder then this should find the appropriate file.  
    dist_wall_files = dir('**/dist_to_wall.mat');
    
    % Else, if no files are found then the 'data_path' is the combined results
    % path. 
    if isempty(dist_wall_files)
        dist_wall_files = dir('*dist2centre*');
    end 
    
    n_files = length(dist_wall_files);
    
     % Load the data
    load(fullfile(dist_wall_files(1).folder, dist_wall_files(1).name), 'Log');

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

            if dir_id <= 1.2
                cond_val = 1; 
            else 
                cond_val = Log.contrast(ii);
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
                col = [0 0 1 cond_val*0.75];
            elseif dir_id == -1
                col = [1 0 1 cond_val*0.75];
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
    
        ylim([-10 130])

    % Add data traces
    for idx = 1:n_files 
    
        % Load the data
        load(fullfile(dist_wall_files(idx).folder, dist_wall_files(idx).name), 'data', 'Log', 'save_str');
   
        n_flies = numel(data);
    
        for i = 1:n_flies
            plot(120 - data{1,i}, 'Color', [0.5 0.5 0.5], 'LineWidth', 0.01); 
            hold on 
        end
    end 
    
    load(fullfile(dist_wall_files(1).folder, dist_wall_files(1).name), 'data');
    if numel(data{1}) < 5200
        min_length = 5150;
    elseif numel(data{1}) < 6500
        min_length =6300;
    elseif numel(data{1}) < 14700
        min_length = 14500;
    elseif numel(data{1}) < 18900
        min_length = 18800;
    else 
        min_length = 5150;
    end 
    
    % Add mean 
    all_data = [];
    for ii = 1:n_files
        % Load the data
        load(fullfile(dist_wall_files(ii).folder, dist_wall_files(ii).name), 'data');
        n_flies = numel(data);
        for jj = 1: n_flies
            dtt = data{jj};
            if numel(dtt)<min_length
                disp('Number of frames less than min length - there will be missing data. Numel(dtt): ')
                disp(numel(dtt))
                continue
            else
                dtt = dtt(1:min_length);
                all_data = vertcat(all_data, dtt);
            end 
        end 
    end 

    n_flies_total = size(all_data, 1);
    
    if mean_med == "med"
        av_resp = 120 - nanmedian(all_data);
    elseif mean_med == "mean"
        av_resp = 120 - nanmean(all_data);
    end 
    plot(av_resp, 'k', 'LineWidth', 4)
    xlabel('frame')
    ylabel('Distance from centre (mm)')
    f = gcf;
    f.Position = [23  623  1716  403];
    ax = gca;
    ax.LineWidth = 1.2;
    ax.FontSize = 12;
    ax.TickDir = 'out';
    ax.TickLength  =[0.005 0.005];

    title(strcat('Distance from centre of arena - N = ', string(n_flies_total)))

    hold on
    plot([0 min_length], [0 0], 'k', 'LineWidth', 0.2)
    plot([0 min_length], [20 20], 'k', 'LineWidth', 0.2)
    plot([0 min_length], [40 40], 'k', 'LineWidth', 0.2)
    plot([0 min_length], [60 60], 'k', 'LineWidth', 0.2) 
    plot([0 min_length], [80 80], 'k', 'LineWidth', 0.2)
    plot([0 min_length], [100 100], 'k', 'LineWidth', 0.2) 
    plot([0 min_length], [120 120], 'k', 'LineWidth', 0.2) 
    
    if save_figs 
        savefig(gcf, fullfile(fig_save_path, strcat('Dist_from_centre_', save_str,'_', mean_med,'.fig')))
    end 

    % xlim([3250 12750])
    % f.Position = [15   590   761   447];
    % 
    % if save_figs 
    %     savefig(gcf, fullfile(fig_save_path, strcat('Dist_from_centre_', save_str,'CROP.fig')))
    % end 

end 