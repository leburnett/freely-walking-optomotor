
group_names = fieldnames(DATA);  % Get names of experimental groups
num_groups = numel(group_names); 

%% 1 - calculate the absolute turning of flies to gratings condition 1 
% Per group

for i = 1:num_groups

    means = [];
    all_data = [];
    
    % Index of order in which condition 1 was presented. 
    cond_mean = [];
    cond_all = []; 

    n_exp = length(DATA.(group_names{i}).F);
    for j = 1:n_exp
        data = abs(DATA.(group_names{i}).F(j).R1_condition_1.av_data);
        data2 = data(:, 300:1200);
        data3 = prctile(data2', 98);

        ord = DATA.(group_names{i}).F(j).meta.random_order;
        cond1_idx = find(ord ==1);

        cond_all = [cond_all, ones(1, height(data))*cond1_idx];
        cond_mean = [cond_mean, cond1_idx];

        all_data = [all_data, data3];
        means = [means, mean(data3)];
        
    end 

    % Plot one figure per experimental group
    figure; 
    scatter(cond_all, all_data, 'o', 'MarkerEdgeColor', [0.6 0.6 0.6]); hold on;
    scatter(cond_mean, means, 'ko', 'filled')

    set(gca, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 12)
    xlabel('Order of condition 1')
    ylabel('98th prctile ang vel (deg s^-^1)')
    xlim([0 13])

    title(strrep(group_names{i}, '_', '-'))
    f = gcf;
    f.Position = [246   685   678   298];
end



%% For all flies: 

means = [];
all_data = [];

% Index of order in which condition 1 was presented. 
cond_mean = [];
cond_all = []; 

for i = 1:num_groups

    n_exp = length(DATA.(group_names{i}).F);
    for j = 1:n_exp
        data = abs(DATA.(group_names{i}).F(j).R1_condition_1.av_data);
        data2 = data(:, 300:1200);
        data3 = prctile(data2', 98);

        ord = DATA.(group_names{i}).F(j).meta.random_order;
        cond1_idx = find(ord ==1);

        cond_all = [cond_all, ones(1, height(data))*cond1_idx];
        cond_mean = [cond_mean, cond1_idx];

        all_data = [all_data, data3];
        means = [means, mean(data3)];
        
    end 
end

% Plot one figure for all experimental groups
figure; 
scatter(cond_all, all_data, 'o', 'MarkerEdgeColor', [0.6 0.6 0.6]); hold on;
scatter(cond_mean, means, 'ko', 'filled')

set(gca, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 12)
xlabel('Order of condition 1')
ylabel('98th prctile ang vel (deg s^-^1)')
xlim([0 13])
% title(strrep(group_names{i}, '_', '-'))
f = gcf;
f.Position = [246   685   678   298];




%% 2  - turning to gratings versus group size. 
% Per group

for i = 1:num_groups

    means = [];
    all_data = [];
    
    % Index of order in which condition 1 was presented. 
    cond_mean = [];
    cond_all = []; 

    n_exp = length(DATA.(group_names{i}).F);
    for j = 1:n_exp
        % angulr velocity
        % data = abs(DATA.(group_names{i}).F(j).R1_condition_1.av_data);
        % data2 = data(:, 300:1200);
        % data3 = prctile(data2', 98);

        % centring
        data = abs(DATA.(group_names{i}).F(j).R1_condition_1.dist_data);
        data2 = data(:, 300:1200)-data(:, 300);
        data3 = prctile(data2', 2);

        cond1_idx = DATA.(group_names{i}).F(j).meta.n_flies_arena;

        cond_all = [cond_all, ones(1, height(data))*cond1_idx];
        cond_mean = [cond_mean, cond1_idx];

        all_data = [all_data, data3];
        means = [means, mean(data3)];
        
    end 

    % Plot one figure per experimental group
    figure; 
    scatter(cond_all, all_data, 'o', 'MarkerEdgeColor', [0.6 0.6 0.6]); hold on;
    scatter(cond_mean, means, 'ko', 'filled')

    set(gca, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 12)
    xlabel('Group size (flies)')
    % ylabel('98th prctile ang vel (deg s^-^1)')
    ylabel('Centring (2 perctile)')
    xlim([0 17])

    title(strrep(group_names{i}, '_', '-'))
    f = gcf;
    f.Position = [246   685   678   298];
end



%% For all flies: 

means = [];
all_data = [];

% Index of order in which condition 1 was presented. 
cond_mean = [];
cond_all = []; 

for i = 1:num_groups

    n_exp = length(DATA.(group_names{i}).F);
    for j = 1:n_exp
        % ang vel 
        % data = abs(DATA.(group_names{i}).F(j).R1_condition_1.av_data);
        % data2 = data(:, 300:1200);
        % data3 = prctile(data2', 98);

        % centring
        data = abs(DATA.(group_names{i}).F(j).R1_condition_1.dist_data);
        data2 = data(:, 300:1200)-data(:, 300);
        data3 = prctile(data2', 2);

        cond1_idx = DATA.(group_names{i}).F(j).meta.n_flies_arena;

        cond_all = [cond_all, ones(1, height(data))*cond1_idx];
        cond_mean = [cond_mean, cond1_idx];

        all_data = [all_data, data3];
        means = [means, mean(data3)];
        
    end 
end

% Plot one figure for all experimental groups
figure; 
scatter(cond_all, all_data, 'o', 'MarkerEdgeColor', [0.6 0.6 0.6]); hold on;
scatter(cond_mean, means, 'ko', 'filled')

set(gca, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 12)
xlabel('Group size (flies)')
% ylabel('98th prctile ang vel (deg s^-^1)')
ylabel('Centring (mm - 2 perctile)')
xlim([0 17])
% title(strrep(group_names{i}, '_', '-'))
f = gcf;
f.Position = [246   685   678   298];


%% 3  - turning to gratings versus temperature 
% Per group

for i = 1:num_groups

    means = [];
    all_data = [];
    
    % Index of order in which condition 1 was presented. 
    cond_mean = [];
    cond_all = []; 

    n_exp = length(DATA.(group_names{i}).F);
    for j = 1:n_exp
        % angulr velocity
        data = abs(DATA.(group_names{i}).F(j).R1_condition_1.av_data);
        data2 = data(:, 300:1200);
        data3 = prctile(data2', 98);

        % centring
        % data = abs(DATA.(group_names{i}).F(j).R1_condition_1.dist_data);
        % data2 = data(:, 300:1200)-data(:, 300);
        % data3 = prctile(data2', 2);

        cond1_idx = DATA.(group_names{i}).F(j).meta.start_temp_ring;

        cond_all = [cond_all, ones(1, height(data))*cond1_idx];
        cond_mean = [cond_mean, cond1_idx];

        all_data = [all_data, data3];
        means = [means, mean(data3)];
        
    end 

    % Plot one figure per experimental group
    figure; 
    scatter(cond_all, all_data, 'o', 'MarkerEdgeColor', [0.6 0.6 0.6]); hold on;
    scatter(cond_mean, means, 'ko', 'filled')

    set(gca, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 12)
    xlabel('Temperature at start (^oC)')
    ylabel('Ang Vel (deg s^-^1 - 98th)')
    % ylabel('Centring (2 perctile)')
    % xlim([0 17])

    title(strrep(group_names{i}, '_', '-'))
    f = gcf;
    f.Position = [246   685   678   298];
end



%% For all flies: 

means = [];
all_data = [];

% Index of order in which condition 1 was presented. 
cond_mean = [];
cond_all = []; 

for i = 1:num_groups

    n_exp = length(DATA.(group_names{i}).F);
    for j = 1:n_exp
        % ang vel 
        % data = abs(DATA.(group_names{i}).F(j).R1_condition_1.av_data);
        % data2 = data(:, 300:1200);
        % data3 = prctile(data2', 98);

        % centring
        data = abs(DATA.(group_names{i}).F(j).R1_condition_1.dist_data);
        data2 = data(:, 300:1200)-data(:, 300);
        data3 = prctile(data2', 2);

        cond1_idx = DATA.(group_names{i}).F(j).meta.start_temp_ring;

        cond_all = [cond_all, ones(1, height(data))*cond1_idx];
        cond_mean = [cond_mean, cond1_idx];

        all_data = [all_data, data3];
        means = [means, mean(data3)];
        
    end 
end

% Plot one figure for all experimental groups
figure; 
scatter(cond_all, all_data, 'o', 'MarkerEdgeColor', [0.6 0.6 0.6]); hold on;
scatter(cond_mean, means, 'ko', 'filled')

set(gca, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 12)
xlabel('Temperature at start (^oC)')
ylabel('Ang Vel (deg s^-^1 - 98th)')

f = gcf;
f.Position = [246   685   678   298];






