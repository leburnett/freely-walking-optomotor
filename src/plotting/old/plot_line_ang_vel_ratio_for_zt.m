function plot_line_ang_vel_ratio_for_zt(data_folder, zt_file, save_figs, save_folder, mean_med)

    % Get data from ALL flies. This should be stored in the 'data'
    % subfolder of the 'save_folder'
    cd(data_folder)

    % List all data files
    all_data = dir();
    dnames = {all_data.name};
    all_data = all_data(~ismember(dnames, '.DS_Store'));
    all_data = all_data(3:end, :);
    
    % Load in the ZT time point file.
    zt_table = readtable(zt_file);
    
    unique_zt_conditions = unique(zt_table.ZT);
    n_conditions = numel(unique_zt_conditions);
    
    % Gather the names of the files that belong to each time point. 
    % Columns = ZT conditions. 
    zt_names = cell(7, n_conditions); %cell(n_zt_exp, n_conditions);
    for idx = 1:n_conditions
        zt_condition = unique_zt_conditions(idx);
        zt_rows = find(zt_table.ZT == zt_condition);
        n_zt_exp = numel(zt_rows);
        for i = 1:n_zt_exp
            row = zt_rows(i);
            exp_path = zt_table.path{row};
            zt_name = strrep(exp_path(end-18:end), '\', '_');
            zt_name(1:9) = strrep(zt_name(1:9), '_', '-');
            zt_names{i, idx} = zt_name;
        end 
    end 
    
    d_mean_zt = zeros(33, 6);
    % Load the data from each ZT point and combine. 

    % Path to save the figures
    fig_save_path = fullfile(save_folder, "zt_figs");
    if ~isfolder(fig_save_path)
        mkdir(fig_save_path)
    end 

    f1 = figure; % Both clock and anti-clock plotted
    f2 = figure; % Mean of clock and anticlock plotted.

    for idx = 1:n_conditions
    
        % Which ZT condition is being investigated. 
        zt_condition = unique_zt_conditions(idx);
        disp(strcat('ZT-', string(zt_condition)))
        % names corresponding to the dates/times that belong to that time
        % point. 
        zt_str = zt_names(:, idx);
        zt_str = zt_str(~cellfun('isempty', zt_str));
        
        matches = false(length(all_data), 1);
        
        % Loop through each element in zt_str
        for i = 1:length(zt_str)
            % Get the current string to match
            current_str = zt_str{i};
            
            % Loop through each row of all_data to check for matches
            for j = 1:length(all_data)
                % Check if the current all_data.name contains the current_str
                if contains(all_data(j).name, current_str)
                    matches(j) = true; % Mark this row as a match
                end
            end
        end
        
        cd(data_folder)
        % Get the rows that match
        matching_rows = all_data(matches);
        n_rows = length(matching_rows);
        d_all = []; 
        for j = 1:n_rows
            d = struct2array(load(matching_rows(j).name, 'datapoints'));
            d_all = horzcat(d_all, d(:, 2:end-1));
        end 

        d_all(d_all==Inf)= 0;
        
        n_flies = numel(d_all(1, :));
        disp(n_flies)
        data_to_use = [d(:, 1), d_all, d(:, end)];
        title_str = strcat('ZT ', string(zt_condition));
        save_str = strrep(title_str, '-', '_');

        %% 
        
        % mean of all ZT overlaid
        if mean_med == "med"
            d_mean = nanmedian(d_all, 2);
        elseif mean_med == "mean"
            d_mean = nanmean(d_all, 2);
        end 

        clock_idx = [1,2,3,5,7,9,11,13,15,17,18,20,22,24,26,28,30,32,33]; %blue
        anti_idx = [1,2,4,6,8,10,12,14,16,17,19,21,23,25,27,29,31,32,33]; % pink
    
        clock_data = d_mean(clock_idx);
        anti_data = d_mean(anti_idx);
        mean_data = nanmean(horzcat(clock_data, abs(anti_data))')';

        colours = [0.9, 0.9, 0; 1, 0.65, 0; 0.8, 0, 0; 0.8, 0, 0.8; 0.62, 0.13, 0.94; 0, 0, 1];
        col = colours(idx, :);

        figure(f1)
        plot(3:1:9, clock_data(3:9), 'Color', col, 'LineWidth', 2);
        hold on
        plot(11:1:18, clock_data(11:18), 'Color', col, 'LineWidth', 2);
        plot(3:1:9, anti_data(3:9), 'Color', col, 'LineWidth', 2);
        plot(11:1:18, anti_data(11:18), 'Color', col, 'LineWidth', 2);
        scatter(1:1:19, clock_data, 150, '.', 'MarkerEdgeColor', col, 'MarkerFaceColor',col);
        scatter(1:1:19, anti_data, 150, '.',  'MarkerEdgeColor', col, 'MarkerFaceColor',col);

        figure(f2)
        plot(3:1:9, mean_data(3:9), 'Color', col, 'LineWidth', 2);
        hold on 
        plot(11:1:18, mean_data(11:18), 'Color', col, 'LineWidth', 2);
        scatter(1:1:19, mean_data, 150, '.',  'MarkerEdgeColor', col, 'MarkerFaceColor',col);

        d_mean_zt(:, idx) = d_mean;

    end 

    figure(f1)
    box off
    ylim([-0.5 0.5])
    xlim([0 20])
    set(gcf, "Position", [469   658   562   348])
    set(gca, "LineWidth", 1, "TickDir", 'out', "FontSize", 12)
    xticks(1:1:19)
    xticklabels({'OFF', 'ON', '0.11', '0.20', '0.33', '0.40', '0.56', '0.75', '1', 'FLICKER', '1', '0.75', '0.56', '0.40', '0.33', '0.20', '0.11', 'FLICKER', 'OFF'})
    ylabel('Ang Vel / Vel (deg/mm)')
    xlabel('Condition / Contrast')

    figure(f2)
    box off
    ylim([0 0.5])
    xlim([0 20])
    set(gcf, "Position", [469   658   562   348])
    set(gca, "LineWidth", 1, "TickDir", 'out', "FontSize", 12)
    xticks(1:1:19)
    xticklabels({'OFF', 'ON', '0.11', '0.20', '0.33', '0.40', '0.56', '0.75', '1', 'FLICKER', '1', '0.75', '0.56', '0.40', '0.33', '0.20', '0.11', 'FLICKER', 'OFF'})
    ylabel('Ang Vel / Vel (deg/mm)')
    xlabel('Condition / Contrast')

    if save_figs == true
        savefig(f1, fullfile(fig_save_path, strcat('ZT_Vel_Line_clock_anti_', mean_med, '.fig')))
        savefig(f2, fullfile(fig_save_path, strcat('ZT_Vel_Line_average_', mean_med, '.fig')))
    end 

end 




