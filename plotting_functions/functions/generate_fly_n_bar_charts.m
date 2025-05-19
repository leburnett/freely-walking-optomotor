function generate_fly_n_bar_charts(exp_data, save_folder)
% From 'exp_data' generate bar plots 

    group_names = fieldnames(exp_data);  % Get names of experimental groups
    num_groups = numel(group_names);     % Number of groups
    
    %% 1 - Bar Chart - number of vials per strain. 
    
    % Preallocate array for n_vials values
    n_vials = zeros(num_groups, 1);
    
    % Extract n_vials from each group
    for i = 1:num_groups
        n_vials(i) = exp_data.(group_names{i}).n_vials;
    end
    
    % Create bar chart
    figure;
    b = bar(n_vials);
    b.FaceAlpha = 0.4;
    b.LineWidth = 0.8;
    
    % Add text labels on top of each bar
    for i = 1:num_groups
        % Get x position (center of the bar) and y position (height of the bar)
        x = i;
        y = n_vials(i);
        text(x, y + 0.5, num2str(y), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom')
    end
    
    set(gca, 'XTickLabel', strrep(group_names, '_', '-'), 'XTick', 1:num_groups, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 12)
    xlabel('Experimental Group')
    ylabel('Number of vials')
    title('Number of vials per experimental group')
    xtickangle(45) 
    ylim([0 25])
    box off
    
    f = gcf;
    f.Position = [73   431   626   347];

    fname = fullfile(save_folder, 'Number_of_vials_per_strain.pdf');
    exportgraphics(f, fname, 'ContentType', 'vector', 'BackgroundColor', 'none');
    close
    
    %% 2 - Total number of flies - after tracking and processing. 
    
    % Preallocate array for n_vials values
    n_flies = zeros(num_groups, 1);
    
    % Extract n_vials from each group
    for i = 1:num_groups
        n_flies(i) = sum(exp_data.(group_names{i}).n_flies);
    end
    
    % Create bar chart
    figure;
    b = bar(n_flies);
    b.FaceAlpha = 0.4;
    b.LineWidth = 0.8;
    
    % Add text labels on top of each bar
    for i = 1:num_groups
        % Get x position (center of the bar) and y position (height of the bar)
        x = i;
        y = n_flies(i);
        text(x, y + 0.5, num2str(y), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom')
    end
    
    set(gca, 'XTickLabel', strrep(group_names, '_', '-'), 'XTick', 1:num_groups, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 12)
    xlabel('Experimental Group')
    ylabel('Number of flies - post processing')
    title('Number of flies per experimental group')
    xtickangle(45) 
    ylim([0 325])
    box off
    
    f = gcf;
    f.Position = [73   431   626   347];
    fname = fullfile(save_folder, 'Number_of_flies_per_strain.pdf');
    exportgraphics(f, fname, 'ContentType', 'vector', 'BackgroundColor', 'none');
    close
end