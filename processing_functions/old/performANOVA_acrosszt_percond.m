function [p, tbl, stats, c] = performANOVA_acrosszt_percond(data_folder, zt_file, cond_to_investigate)
% perform one-way ANOVA for one condition across zt time points. 

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
n_timepoints = numel(unique_zt_conditions);

% Gather the names of the files that belong to each time point. 
% Columns = ZT conditions. 
zt_names = cell(7, n_timepoints); %cell(n_zt_exp, n_conditions);
for idx = 1:n_timepoints
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

d_cond = [];
zt_cond = [];

for idx = 1:n_timepoints
    
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

        % Get the rows that match for the zt timepoint of interest
        matching_rows = all_data(matches);
        n_rows = length(matching_rows);
        d_all = []; 
        for j = 1:n_rows
            d = struct2array(load(matching_rows(j).name, 'datapoints'));
            d_all = horzcat(d_all, d(:, 2:end-1));
        end 
        
        n_flies = numel(d_all(1, :)); 

        % Convert Inf to zeros
        d_all(d_all==Inf)=0;
        d_all(d_all==-Inf)=0;
        
        % Finding SEM / CI / STD for errorbar
        clock_idx = [1,2,3,5,7,9,11,13,15,17,18,20,22,24,26,28,30,32,33]; %blue
        anti_idx = [1,2,4,6,8,10,12,14,16,17,19,21,23,25,27,29,31,32,33]; % pink

        d_clock = abs(d_all(clock_idx, :));
        d_anti = abs(d_all(anti_idx, :));

        % Data where clock and anti data are combined:
        combined_dir_data = horzcat(d_clock, d_anti);
        len_comb_data = numel(combined_dir_data(1, :));

        if cond_to_investigate <3 
            d_cond = vertcat(d_cond, combined_dir_data(cond_to_investigate, 1:len_comb_data/2)');
            zt_cond = vertcat(zt_cond, ones(len_comb_data/2, 1)*idx);
        else
            d_cond = vertcat(d_cond, combined_dir_data(cond_to_investigate, 1:len_comb_data)');
            zt_cond = vertcat(zt_cond, ones(len_comb_data, 1)*idx);
        end 

end 

%% PERFORM ONE WAY ANOVA 

% One way ANOVA + Tukey's post-hoc test 
[p, tbl, stats] = anova1(d_cond, zt_cond);
title(string(cond_to_investigate))

% if p < 0.005 - post-hoc test 
[c, m, h, nms] = multcompare(stats);

end 




