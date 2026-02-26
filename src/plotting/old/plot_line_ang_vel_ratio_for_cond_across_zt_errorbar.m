function plot_line_ang_vel_ratio_for_cond_across_zt_errorbar(data_folder, zt_file, save_figs, save_folder, mean_med, ebar)

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
    
    % For saving data across ZT timepoints
    d_mean_zt = zeros(33, 6);

    d_mean_comb_zt = zeros(19, 6);
    d_med_comb_zt = zeros(19, 6);
    ebar_comb_zt = zeros(19*2, 6);

    % Path to save the figures
    fig_save_path = fullfile(save_folder, "zt_figs");
    if ~isfolder(fig_save_path)
        mkdir(fig_save_path)
    end 

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
        
        % mean of all ZT overlaid
        if mean_med == "med"
            d_mean = nanmedian(d_all, 2);
        elseif mean_med == "mean"
            d_mean = nanmean(d_all, 2);
        end 
        
        d_mean_zt(:, idx) = d_mean;

        % Finding SEM / CI / STD for errorbar
        clock_idx = [1,2,3,5,7,9,11,13,15,17,18,20,22,24,26,28,30,32,33]; %blue
        anti_idx = [1,2,4,6,8,10,12,14,16,17,19,21,23,25,27,29,31,32,33]; % pink

        d_clock = abs(d_all(clock_idx, :));
        d_anti = abs(d_all(anti_idx, :));

        % Data where clock and anti data are combined:
        combined_dir_data = horzcat(d_clock, d_anti);
        len_comb_data = numel(combined_dir_data(1, :));

        eb_cond_data = zeros(19, 2);
        mean_comb_data = zeros(19, 1);
        med_comb_data = zeros(19, 1);

        if ebar == "CI"
            for jj = 1:19
                if jj <3
                    SEM = std(combined_dir_data(jj, 1:len_comb_data/2))/sqrt(len_comb_data/2);         
                    ts = tinv([0.025  0.975],(len_comb_data/2)-1);      
                    eb_cond_data(jj, 1:2) = abs(nanmean(combined_dir_data(jj, 1:len_comb_data/2)) + ts*SEM); 
                    mean_comb_data(jj, 1) = nanmean(combined_dir_data(jj, 1:len_comb_data/2));
                    med_comb_data(jj, 1) = nanmedian(combined_dir_data(jj, 1:len_comb_data/2));
                else
                    SEM = std(combined_dir_data(jj, :))/sqrt(length(combined_dir_data(jj, :)));         
                    ts = tinv([0.025  0.975],length(combined_dir_data(jj, :))-1);      
                    eb_cond_data(jj, 1:2) = abs(nanmean(combined_dir_data(jj, :)) + ts*SEM); 
                    mean_comb_data(jj, 1) = nanmean(combined_dir_data(jj, 1:len_comb_data));
                    med_comb_data(jj, 1) = nanmedian(combined_dir_data(jj, 1:len_comb_data));
                end 
            end 
        elseif ebar == "SEM"
    
            for jj = 1:19
                if jj <3
                    SEM = nanstd(combined_dir_data(jj, 1:len_comb_data/2))/sqrt(len_comb_data/2);              
                    eb_cond_data(jj, 1:2) = SEM; 
                    mean_comb_data(jj, 1) = nanmean(combined_dir_data(jj, 1:len_comb_data/2));
                    med_comb_data(jj, 1) = nanmedian(combined_dir_data(jj, 1:len_comb_data/2));
                else
                    SEM = nanstd(combined_dir_data(jj, :))/sqrt(length(combined_dir_data(jj, :)));               
                    eb_cond_data(jj, 1:2) = SEM; 
                    mean_comb_data(jj, 1) = nanmean(combined_dir_data(jj, 1:len_comb_data));
                    med_comb_data(jj, 1) = nanmedian(combined_dir_data(jj, 1:len_comb_data));
                end 
            end 
        elseif ebar == "STD"
            for jj = 1:19
                if jj <3
                    STD = nanstd(combined_dir_data(jj, 1:len_comb_data/2));              
                    eb_cond_data(jj, 1:2) = STD; 
                    mean_comb_data(jj, 1) = nanmean(combined_dir_data(jj, 1:len_comb_data/2));
                    med_comb_data(jj, 1) = nanmedian(combined_dir_data(jj, 1:len_comb_data/2));
                else
                    STD = nanstd(combined_dir_data(jj, :));               
                    eb_cond_data(jj, 1:2) = STD; 
                    mean_comb_data(jj, 1) = nanmean(combined_dir_data(jj, 1:len_comb_data));
                    med_comb_data(jj, 1) = nanmedian(combined_dir_data(jj, 1:len_comb_data));
                end 
            end 
        elseif ebar == "IQR"
            for jj = 1:19
                if jj <3
                    Q1 = prctile(combined_dir_data(jj, 1:len_comb_data/2), 25);
                    Q3 = prctile(combined_dir_data(jj, 1:len_comb_data/2), 75);
                    mean_comb_data(jj, 1) = nanmean(combined_dir_data(jj, 1:len_comb_data/2));
                    med_comb_data(jj, 1) = nanmedian(combined_dir_data(jj, 1:len_comb_data/2));
                else
                    Q1 = prctile(combined_dir_data(jj, 1:len_comb_data), 25);
                    Q3 = prctile(combined_dir_data(jj, 1:len_comb_data), 75);
                    mean_comb_data(jj, 1) = nanmean(combined_dir_data(jj, 1:len_comb_data));
                    med_comb_data(jj, 1) = nanmedian(combined_dir_data(jj, 1:len_comb_data));
                end 
                eb_cond_data(jj, 1:2) = [Q1, Q3];
            end 
        end 

        eb_cond_data = reshape(eb_cond_data', 19*2, 1);

        d_mean_comb_zt(:, idx) = mean_comb_data;
        d_med_comb_zt(:, idx) = med_comb_data;
        ebar_comb_zt(:, idx) = eb_cond_data;


    end 

%% Now we have the data - plot it. 
colours = [0.9, 0.9, 0; 1, 0.65, 0; 0.8, 0, 0; 0.8, 0, 0.8; 0.62, 0.13, 0.94; 0, 0, 1];

figure
for cond_num = 1:9
    subplot(9,1,cond_num)
    % cond_num = 1;
    d_zt = d_med_comb_zt(cond_num, :);
    eb_zt = ebar_comb_zt(cond_num*2-1:cond_num*2, :);
    % figure
    errorbar(1:1:6, d_zt, eb_zt(1, :), eb_zt(2, :), 'k')
    hold on
    for jj = 1:6
        scatter(jj, d_zt(jj), 75, 'filled','MarkerFaceColor', colours(jj, :))
    end 
    xlim([0.5 6.5])
    box off
    ylim([0, 1.2])
    % yticks([0, 0.2, 0.4, 0.6, 0.8, 1, 1.2])
    yticks([0, 1])
    xticks([1,2,3,4,5,6])
    xticklabels({'1', '5', '9', '13', '17', '21'})
    set(gca, "LineWidth", 1, "TickDir", 'out', "FontSize", 12)
    % ylabel('Ang Vel / Vel (deg/mm)')
    if cond_num<9
        ax = gca;
        ax.XAxis.Visible = false;
    else
         xlabel('ZT timepoint')
    end 
end 

f = gcf;
f.Position = [569    69   457   978];
% title('11% contrast')
% title('Acclim in dark')

if save_figs == true
    % savefig(f1, fullfile(fig_save_path, strcat('ZT_AngVelRatio_Line_clock_anti_', mean_med, '.fig')))
    savefig(f2, fullfile(fig_save_path, strcat('ZT_AngVelRatio_Line_norm_average_shaded_', mean_med, '_', ebar,'.fig')))
end 

end 




