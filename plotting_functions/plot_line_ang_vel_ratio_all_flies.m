function plot_line_ang_vel_ratio_all_flies(data_to_use, n_flies, title_str, save_str, fig_exp_save_folder, save_figs)

    data_to_use(3:end, :) = (abs(data_to_use(3:end, :)));

    n_cond_to_use = size(data_to_use, 1);
    mean_data = zeros(n_cond_to_use, 1);
    for idx = 1:n_cond_to_use
        mean_data(idx) = mean(mean(data_to_use(idx, 2:n_flies+1)));
    end 

    % make new mean matrix
    new_mean_data = zeros(19, size(data_to_use, 2));

    % keep acclimitization periods and flickers the same
    new_mean_data(1, :) = data_to_use(1, :); 
    new_mean_data(2, :) = data_to_use(2, :);
    new_mean_data(10,:) = data_to_use(17,:);
    new_mean_data(18, :) = data_to_use(32, :);
    new_mean_data(19, :) = data_to_use(33, :);

    % averaging between conditions
    first = 3;
    second = 4;
    for row = 3:2:18
        new_mean_data(row, 2) = mean(data_to_use(row:row+1, :));
        % first = first + 2;
        % second = second + 1;
    end

    % grab indexes and data from the indexes

    clock_idx = [1,2,3,5,7,9,11,13,15,17,18,20,22,24,26,28,30,32,33]; % blue
    anti_idx = [1,2,4,6,8,10,12,14,16,17,19,21,23,25,27,29,31,32,33]; % pink
    
    clock_data = new_mean_data(clock_idx);
    anti_data = new_mean_data(anti_idx);
    
    
    % Generate plot:
    
    sz1 = 550; 
    sz2 = 100;
    
    figure
    for idx = 1:n_flies
        data_fly = data_to_use(:, idx+1);
        fly_clock_data = data_fly(clock_idx);
        fly_anti_data = data_fly(anti_idx); 
        plot(fly_clock_data, 'Color', [0.7 0.7 1 0.4], 'LineWidth', 1);
        hold on 
        plot(fly_anti_data, 'Color', [1 0.7 1 0.4], 'LineWidth', 1);
    end 

    % Add Blobs
    % plot(clock_data, 'b', 'LineWidth', 1.5);
    plot(new_mean_data, 'm', 'LineWidth', 1.5);

    hold on 
    % plot(anti_data, 'm', 'LineWidth', 1.5);
    scatter(1:1:19, new_mean_data, sz1, 'm');
        
    % Acclim OFF
    scatter([1,10,18, 19], new_mean_data([1,17,32,33]), sz2, 'o', 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k');
    % ACCLIM ON
    scatter(2, new_mean_data(2), sz2, 'o', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
    % FLCIKER 
    scatter([10, 18], new_mean_data([17,32]), sz2, 'o', 'MarkerFaceColor', [0.75 0.75 0.75], 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
    
    box off
    xlim([0 20])
    ylim([0 30])
    set(gcf, "Position", [469   658   562   348])
    set(gca, "LineWidth", 1, "TickDir", 'out', "FontSize", 12)
    xticks(1:1:19)
    xticklabels({'OFF', 'ON', '0.11', '0.20', '0.33', '0.40', '0.56', '0.75', '1', 'FLICKER', '1', '0.75', '0.56', '0.40', '0.33', '0.20', '0.11', 'FLICKER', 'OFF'})
    ylabel('Angular Velocity/Velocity (deg/mm)')
    xlabel('Condition / Contrast')
    title(strcat(title_str, ' - N=', string(n_flies)))
    
    if save_figs == true
        savefig(gcf, fullfile(fig_exp_save_folder, strcat('AngVel_Line_', save_str)))
    end 

end 