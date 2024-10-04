%% Looking at distance from centre depending on ZT condition and the number of flies in the chamber. 


data_path = '/Users/burnettl/Documents/Janelia/HMS_2024/DATA'; 
cd(data_path)

% Find all files called 'dist_to_wall.mat' in any subfolder of this folder.
dist_wall_files = dir('**/dist_to_wall.mat');
n_files = length(dist_wall_files);

% Load ZT file names
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
        zt_names{i, idx} = strrep(exp_path(end-18:end), '\', '/');
    end 
end 
    
d_mean_zt = zeros(33, 6);
% Load the data from each ZT point and combine. 

f1 = figure;

d_all_zt = [];

for idx = 1:n_conditions

    % Which ZT condition is being investigated. 
    zt_condition = unique_zt_conditions(idx);
    disp(strcat('ZT-', string(zt_condition)))
    % names corresponding to the dates/times that belong to that time
    % point. 
    zt_str = zt_names(:, idx);
    zt_str = zt_str(~cellfun('isempty', zt_str));
    
    matches = false(length(dist_wall_files), 1);
    
    % Loop through each element in zt_str
    for i = 1:length(zt_str)
        % Get the current string to match
        current_str = zt_str{i};
        
        % Loop through each row of all_data to check for matches
        for j = 1:length(dist_wall_files)
            % Check if the current all_data.name contains the current_str
            if contains(dist_wall_files(j).folder, current_str)
                matches(j) = true; % Mark this row as a match
            end
        end
    end
    
    % Get the rows that match
    matching_rows = dist_wall_files(matches);
    n_rows = length(matching_rows);
    d_all = cell(n_rows, 3); 

    for j = 1:n_rows
        d = struct2array(load(fullfile(matching_rows(j).folder, matching_rows(j).name), 'data'));
        d_all(j, 1) = {d};
        d_all(j, 2) = {length(d)};
        d_all(j, 3) = {zt_condition};
    end 

    d_all_zt = vertcat(d_all_zt, d_all);

end 

save('/Users/burnettl/Documents/Janelia/HMS_2024/RESULTS/distance_from_wall_all_data.mat', 'd_all_zt');






















%% Plot average distance from centre of arena by ZT condition. 

figure

colours = [0.9, 0.9, 0; 1, 0.65, 0; 0.8, 0, 0; 0.8, 0, 0.8; 0.62, 0.13, 0.94; 0, 0, 1];     

all_conditions = unique(cell2mat(d_all_zt(:, 3)));
n_conditions = numel(all_conditions);

for cond = 1:n_conditions

    all_data = [];
    cond_val = all_conditions(cond); 
    
    rows_condition = find(cell2mat(d_all_zt(:, 3)) == cond_val);
    n_rows_con = numel(rows_condition);
    
    for ii = 1:n_rows_con
    
        row = rows_condition(ii);
        data = d_all_zt{row};
        n_flies = numel(data);
    
        for jj = 1: n_flies
            dtt = data{jj};
            if numel(dtt)<14500
                continue
            else
                dtt = dtt(1:14500);
                all_data = vertcat(all_data, dtt);
            end 
        end 
    end 

    col = colours(cond, :);
    av_resp = 120 - nanmean(all_data);
    plot(av_resp, 'Color', col, 'LineWidth', 3)
    hold on
end 


xlabel('frame')
ylabel('Distance from centre (mm)')
f = gcf;
f.Position = [23  623  1716  403];
ax = gca;
ax.LineWidth = 1.2;
ax.FontSize = 12;
ax.TickDir = 'out';
ax.TickLength  =[0.005 0.005];
title('Distance from centre of arena - by ZT')
box off
xticks([])
% ylim([0 120])


%% By number of flies


row = 16;
data = d_all_zt{row};
n_flies = numel(data);

all_data = []; 
for jj = 1: n_flies
    dtt = data{jj};
    if numel(dtt)<14500
        continue
    else
        dtt = dtt(1:14500);
        all_data = vertcat(all_data, dtt);
    end 
end 
  
% figure
col = colours(cond, :);
av_resp = 120 - nanmean(all_data);
plot(av_resp, 'Color', 'm', 'LineWidth', 3)
hold on

% red = 26 flies. 
% b = 8 
% cyan = 7 


