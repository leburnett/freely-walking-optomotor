function plot_line_ang_vel_for_zt_MEAN_SEM(save_figs, med_mean)

    data_path = '/Users/burnettl/Documents/Janelia/HMS_2024/RESULTS/ProcessedData'; 
    cd(data_path)
    all_data = dir();
    dnames = {all_data.name};
    all_data = all_data(~ismember(dnames, '.DS_Store'));
    all_data = all_data(3:end, :);
    
    zt_file = '/Users/burnettl/Documents/Janelia/HMS_2024/zt_conditions.xlsx';
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
            zt_names{i, idx} = strrep(exp_path(end-18:end), '\', '_');
        end 
    end 
    
    d_mean_zt = zeros(33, 6);
    % Load the data from each ZT point and combine. 

    f1 = figure;
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
        
        cd(data_path)
        % Get the rows that match
        matching_rows = all_data(matches);
        n_rows = length(matching_rows);
        d_all = []; 
        for j = 1:n_rows
            if med_mean == "median"
                d = struct2array(load(matching_rows(j).name, 'datapoints_median'));
            elseif med_mean == "mean"
                d = struct2array(load(matching_rows(j).name, 'datapoints'));
            end 
            d_all = horzcat(d_all, d(:, 2:end-1));
        end 
        
        n_flies = numel(d_all(1, :));
        disp(n_flies)
        % data_to_use = [d(:, 1), d_all, d(:, end)];

        title_str = strcat('ZT ', string(zt_condition));
        save_str = strrep(title_str, '-', '_');
        fig_exp_save_folder = '/Users/burnettl/Documents/Janelia/HMS_2024/RESULTS/Figures/ZT_figs';
  
        if med_mean == "mean"
            sem_data = nanstd(d_all')/sqrt(size(d_all,2));
        elseif med_mean == "median"
            sem_data = nanstd(d_all');
        end 
        
        % mean of all ZT overlaid
        if med_mean == "median"
            d_mean = nanmedian(d_all, 2);
        elseif med_mean == "mean"
            d_mean = nanmean(d_all, 2);
        end 

        clock_idx = [1,2,3,5,7,9,11,13,15,17,18,20,22,24,26,28,30,32,33]; %blue
        anti_idx = [1,2,4,6,8,10,12,14,16,17,19,21,23,25,27,29,31,32,33]; % pink
    
        clock_data = d_mean(clock_idx);
        
        clock_sem = sem_data(clock_idx);
        y1 = clock_data'+clock_sem;
        y2 = clock_data'-clock_sem;

        anti_data = d_mean(anti_idx);
        anti_sem = sem_data(anti_idx);
        y3 = anti_data'+anti_sem;
        y4 = anti_data'-anti_sem;

        colours = [0.9, 0.9, 0; 1, 0.65, 0; 0.8, 0, 0; 0.8, 0, 0.8; 0.62, 0.13, 0.94; 0, 0, 1];
        col = colours(idx, :);
        x = 1:1:19; 

        figure(f1)

        % plot SEM for clockwise movement
        plot(x, y1, 'w', 'LineWidth', 1)
        hold on
        plot(x, y2, 'w', 'LineWidth', 1)
        patch([x fliplr(x)], [y1 fliplr(y2)], col, 'FaceAlpha', 0.125, 'EdgeColor', 'none')

        % plot SEM for anticlockwise movement
        plot(x, y3, 'w', 'LineWidth', 1)
        hold on
        plot(x, y4, 'w', 'LineWidth', 1)
        patch([x fliplr(x)], [y3 fliplr(y4)], col, 'FaceAlpha', 0.125, 'EdgeColor', 'none')


        plot(clock_data, 'Color', col, 'LineWidth', 2);
        hold on 
        plot(anti_data, 'Color', col, 'LineWidth', 2);
        scatter(x, clock_data, 150, '.', 'MarkerEdgeColor', col, 'MarkerFaceColor',col);
        scatter(x, anti_data, 150, '.',  'MarkerEdgeColor', col, 'MarkerFaceColor',col);

        d_mean_zt(:, idx) = d_mean;

    end 
    box off
    ylim([-2 2])
    xlim([0 20])
    set(gcf, "Position", [469   658   562   348])
    set(gca, "LineWidth", 1, "TickDir", 'out', "FontSize", 12)
    xticks(1:1:19)
    xticklabels({'OFF', 'ON', '0.11', '0.20', '0.33', '0.40', '0.56', '0.75', '1', 'FLICKER', '1', '0.75', '0.56', '0.40', '0.33', '0.20', '0.11', 'FLICKER', 'OFF'})
    ylabel('Angular Velocity')
    xlabel('Condition / Contrast')

    if save_figs == true
        savefig(f1, fullfile(fig_exp_save_folder, strcat('ZT_AngVel_Line_wSEM',med_mean, '.fig')))
    end 

end 









        
 

