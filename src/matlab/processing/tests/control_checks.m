
% Control checks for p27 screen data:

% Plots to check the number of vials, flies, age, how many were discarded,
% the average group size. 

% Assume exp_data is your struct
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
ylim([0 20])
box off

f = gcf;
f.Position = [73   431   626   347];


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
ylim([0 270])
box off

f = gcf;
f.Position = [73   431   626   347];


%% 3 - Number of flies in the arena per experiment. 
% Plot the mean number of flies in the arena per experiment with the
% individual data points added on top. 

% Preallocate
means = zeros(num_groups, 1);
all_data = cell(num_groups, 1);

% Collect data
for i = 1:num_groups
    data = exp_data.(group_names{i}).n_arena;
    all_data{i} = data;
    means(i) = mean(data);
end

% Create figure
figure
hold on

% Bar plot of means
b = bar(means, 'FaceAlpha', 0.4);  % Slightly transparent bars

% Overlay individual data points
for i = 1:num_groups
    x_vals = repmat(i, size(all_data{i}));  % X-position for scatter
    scatter(x_vals, all_data{i}, 60, [0.5 0.5 0.5], ...
        'jitter','on', 'jitterAmount', 0.15);  % Add jitter for visibility
end

% Add text labels on top of each bar
for i = 1:num_groups
    % Get x position (center of the bar) and y position (height of the bar)
    x = i;
    y = means(i);
    text(x, y + 1, num2str(y, '%.2f'), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom')
end

% Aesthetics
set(gca, 'XTickLabel', strrep(group_names, '_', '-'), 'XTick', 1:num_groups, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 12)
xlabel('Experimental Group')
ylabel('n\_arena (per experiment)')
title('Number of flies in the arena per experiment')
xtickangle(45)
ylim([0 17])

f = gcf;
f.Position = [73   431   626   347];

%% 4 - Number of flies per experiment after processing 

% Preallocate
means = zeros(num_groups, 1);
all_data = cell(num_groups, 1);

% Collect data
for i = 1:num_groups
    data = exp_data.(group_names{i}).n_flies;
    all_data{i} = data;
    means(i) = mean(data);
end

% Create figure
figure
hold on

% Bar plot of means
b = bar(means, 'FaceAlpha', 0.4);  % Slightly transparent bars

% Overlay individual data points
for i = 1:num_groups
    x_vals = repmat(i, size(all_data{i}));  % X-position for scatter
    scatter(x_vals, all_data{i}, 60, [0.5 0.5 0.5], ...
        'jitter','on', 'jitterAmount', 0.15);  % Add jitter for visibility
end

% Add text labels on top of each bar
for i = 1:num_groups
    % Get x position (center of the bar) and y position (height of the bar)
    x = i;
    y = means(i);
    text(x, 16, num2str(y, '%.2f'), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom')
end

% Aesthetics
set(gca, 'XTickLabel', strrep(group_names, '_', '-'), 'XTick', 1:num_groups, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 12)
xlabel('Experimental Group')
ylabel('n\_flies (per experiment)')
title('Number of flies in the arena - post processing')
xtickangle(45)
ylim([0 18])

f = gcf;
f.Position = [73   431   626   347];


%% 5 - Number of flies removed per experiment

% Preallocate
means = zeros(num_groups, 1);
all_data = cell(num_groups, 1);

% Collect data
for i = 1:num_groups
    data = exp_data.(group_names{i}).n_rm;
    all_data{i} = data;
    means(i) = mean(data);
end

% Create figure
figure
hold on

% Bar plot of means
b = bar(means, 'FaceAlpha', 0.4);  % Slightly transparent bars

% Overlay individual data points
for i = 1:num_groups
    x_vals = repmat(i, size(all_data{i}));  % X-position for scatter
    scatter(x_vals, all_data{i}, 60, [0.5 0.5 0.5], ...
        'jitter','on', 'jitterAmount', 0.15);  % Add jitter for visibility
end

% Add text labels on top of each bar
for i = 1:num_groups
    % Get x position (center of the bar) and y position (height of the bar)
    x = i;
    y = means(i);
    text(x, 9, num2str(y, '%.2f'), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom')
end

% Aesthetics
set(gca, 'XTickLabel', strrep(group_names, '_', '-'), 'XTick', 1:num_groups, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 12)
xlabel('Experimental Group')
ylabel('n\_flies removed (per experiment)')
title('Number of flies removed - post processing')
xtickangle(45)
ylim([0 10])

f = gcf;
f.Position = [73   431   626   347];


%% 6 - Fly Age

% Preallocate
means = zeros(num_groups, 1);
all_data = cell(num_groups, 1);

% Collect data
for i = 1:num_groups
    data = exp_data.(group_names{i}).fly_age;
    all_data{i} = data;
    means(i) = mean(data);
end

% Create figure
figure
hold on

% Bar plot of means
b = bar(means, 'FaceAlpha', 0.4);  % Slightly transparent bars

% Overlay individual data points
for i = 1:num_groups
    x_vals = repmat(i, size(all_data{i}));  % X-position for scatter
    scatter(x_vals, all_data{i}, 60, [0.5 0.5 0.5], ...
        'jitter','on', 'jitterAmount', 0.15);  % Add jitter for visibility
end

% Add text labels on top of each bar
for i = 1:num_groups
    % Get x position (center of the bar) and y position (height of the bar)
    x = i;
    y = means(i);
    text(x, 6, num2str(y, '%.2f'), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom')
end

% Aesthetics
set(gca, 'XTickLabel', strrep(group_names, '_', '-'), 'XTick', 1:num_groups, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 12)
xlabel('Experimental Group')
ylabel('Fly age (days)')
title('Average age of flies per experimental group')
xtickangle(45)
ylim([0 7])

f = gcf;
f.Position = [73   431   626   347];


%% 7 - Temp start 

% Preallocate
means = zeros(num_groups, 1);
all_data = cell(num_groups, 1);

% Collect data
for i = 1:num_groups
    data = exp_data.(group_names{i}).temp_start;
    all_data{i} = data;
    means(i) = mean(data);
end

% Create figure
figure
hold on

% Bar plot of means
b = bar(means, 'FaceAlpha', 0.4);  % Slightly transparent bars

% Overlay individual data points
for i = 1:num_groups
    x_vals = repmat(i, size(all_data{i}));  % X-position for scatter
    scatter(x_vals, all_data{i}, 60, [0.5 0.5 0.5], ...
        'jitter','on', 'jitterAmount', 0.15);  % Add jitter for visibility
end

% Add text labels on top of each bar
for i = 1:num_groups
    % Get x position (center of the bar) and y position (height of the bar)
    x = i;
    y = means(i);
    text(x, 45, num2str(y, '%.2f'), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom')
end

% Aesthetics
set(gca, 'XTickLabel', strrep(group_names, '_', '-'), 'XTick', 1:num_groups, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 12)
xlabel('Experimental Group')
ylabel('Temperature at the start (^oc)')
title('Start temperature')
xtickangle(45)
ylim([0 48])

f = gcf;
f.Position = [73   431   626   347];

%% 8 - Temp end 

% Preallocate
means = zeros(num_groups, 1);
all_data = cell(num_groups, 1);

% Collect data
for i = 1:num_groups
    data = exp_data.(group_names{i}).temp_end;
    all_data{i} = data;
    means(i) = mean(data);
end

% Create figure
figure
hold on

% Bar plot of means
b = bar(means, 'FaceAlpha', 0.4);  % Slightly transparent bars

% Overlay individual data points
for i = 1:num_groups
    x_vals = repmat(i, size(all_data{i}));  % X-position for scatter
    scatter(x_vals, all_data{i}, 60, [0.5 0.5 0.5], ...
        'jitter','on', 'jitterAmount', 0.15);  % Add jitter for visibility
end

% Add text labels on top of each bar
for i = 1:num_groups
    % Get x position (center of the bar) and y position (height of the bar)
    x = i;
    y = means(i);
    text(x, 45, num2str(y, '%.2f'), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom')
end

% Aesthetics
set(gca, 'XTickLabel', strrep(group_names, '_', '-'), 'XTick', 1:num_groups, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 12)
xlabel('Experimental Group')
ylabel('Temperature at the end (^oc)')
title('End temperature')
xtickangle(45)
ylim([0 48])

f = gcf;
f.Position = [73   431   626   347];


%% 9 - Time of day 

% Preallocate
means = zeros(num_groups, 1);
all_data = cell(num_groups, 1);

% Collect data
for i = 1:num_groups
    data = exp_data.(group_names{i}).time_start;
    all_data{i} = data;
    means(i) = mean(data);
end

% Create figure
figure
hold on

% Bar plot of means
b = bar(means, 'FaceAlpha', 0.4);  % Slightly transparent bars

% Overlay individual data points
for i = 1:num_groups
    x_vals = repmat(i, size(all_data{i}));  % X-position for scatter
    scatter(x_vals, all_data{i}, 60, [0.5 0.5 0.5], ...
        'jitter','on', 'jitterAmount', 0.15);  % Add jitter for visibility
end

% Add text labels on top of each bar
for i = 1:num_groups
    % Get x position (center of the bar) and y position (height of the bar)
    x = i;
    y = means(i);
    text(x, 17, num2str(y, '%.2f'), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom')
end

% Aesthetics
set(gca, 'XTickLabel', strrep(group_names, '_', '-'), 'XTick', 1:num_groups, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 12)
xlabel('Experimental Group')
ylabel('Hour of day (24h)')
title('Start hour of experiment.')
xtickangle(45)
ylim([9 19])

f = gcf;
f.Position = [73   431   626   347];


%% 10 - Does the temperature of the arena affect how many flies don't make it through processing? i.e. are they dying due to the heat?

temp_data = [];
rm_data = []; 

% Extract n_vials from each group
for i = 1:num_groups
    temp_data = [temp_data, exp_data.(group_names{i}).temp_end];
    rm_data = [rm_data, exp_data.(group_names{i}).n_rm];
end

figure; 
scatterhist(rm_data, temp_data, 'Direction','out', 'NBins', 20)
xlabel('Number of flies removed post-processing')
ylabel('Temperature at the end (^oC)')

    figure
    for j = 1:n_strains
        strain = strain_names{j};
        plot(exp_data.(strain).temp_end, exp_data.(strain).n_rm, 'ko', 'MarkerSize', 20)
        hold on;
    end 


        figure
    for j = 1:n_strains
        figure
        strain = strain_names{j};
        scatterhist(exp_data.(strain).temp_end, exp_data.(strain).n_rm, 'Direction','out')
        % plot(exp_data.(strain).temp_end, exp_data.(strain).n_rm, 'ko', 'MarkerSize', 20)
        hold on;
    end 


%% How much do the different fly strains walk during the acclimatisation period?

    means = [];
    all_data = [];
    
    temp_mean = [];
    temp_all = []; 

for i = 1:num_groups

    n_exp = length(DATA.(group_names{i}).F);
    for j = 1:n_exp
        data = DATA.(group_names{i}).F(j).acclim_off1.fv_data;

        t_start = DATA.(group_names{i}).F(j).meta.start_temp_ring;
        t_end = DATA.(group_names{i}).F(j).meta.end_temp_ring;

        temp_all = [temp_all, ones(1, height(data))*t_start];
        all_data = [all_data, mean(data, 2)'];
        means = [means, mean(mean(data, 2))];
        temp_mean = [temp_mean, t_start];
    end 

    % % Plot one figure per experimental group
    % figure; 
    % scatter(temp_all, all_data, 'o', 'MarkerEdgeColor', [0.6 0.6 0.6]); hold on;
    % scatter(temp_mean, means, 'ko', 'filled')
    % 
    % set(gca, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 12)
    % xlabel('Ring temperature at the start (^oC)')
    % ylabel('Average forward velocity (mm s^-^1)')
    % ylim([0 23])
    % title(strrep(group_names{i}, '_', '-'))
    % f = gcf;
    % f.Position = [246   685   678   298];
end

    % Plot one figure for all experimental groups
    figure; 
    scatter(temp_all, all_data, 'o', 'MarkerEdgeColor', [0.6 0.6 0.6]); hold on;
    scatter(temp_mean, means, 'ko', 'filled')
   
    set(gca, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 12)
    xlabel('Ring temperature at the start (^oC)')
    ylabel('Average forward velocity (mm s^-^1)')
    ylim([0 23])
    % title(strrep(group_names{i}, '_', '-'))
    f = gcf;
    f.Position = [246   685   678   298];


%% Plot the temperature over date. 

figure; hold on;
for i = 1:num_groups

    n_exp = length(DATA.(group_names{i}).F);
    for j = 1:n_exp
        d = DATA.(group_names{i}).F(j).meta.date;
        t_start = DATA.(group_names{i}).F(j).meta.start_temp_ring;
        t_end = DATA.(group_names{i}).F(j).meta.end_temp_ring;
        plot(d, t_start, 'ko');
        plot(d, t_end, 'ro');
    end 
end 
set(gca, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 12)
ylabel('Temperature (^oC) - start (k) - end (r)')
xlabel('Date')

