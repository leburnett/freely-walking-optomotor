
% Plotting p34 / p33

% Plot the "none" in grey
% Plot the "left" in red
% Plot the "right" in blue
% Plot "both" in purple.

% Before runnning this script. The results files must be sorted into
% folders based on whether one, both or no eyes were painted. 


%% 1 - Create 'DATA' struct

protocol = "protocol_34";
ROOT_DIR = '/Users/burnettl/Documents/Projects/oaky_cokey';
% Move to the directory to where the results per experiment are saved:
protocol_dir = fullfile(ROOT_DIR, 'results', protocol);
cd(protocol_dir);

% Get all of the strain folders that are inside the protocol folder.
strain_folders = dir;
strain_folders = strain_folders([strain_folders.isdir]); % Keep only directories
strain_folders = strain_folders(~ismember({strain_folders.name}, {'.', '..'})); % Remove '.' and '..'

% Number of strains without ES.
n_strains = height(strain_folders);

% Generate the struct 'DATA' that combines data across experiments and
% separates data into conditions.
DATA = comb_data_across_cohorts_cond(protocol_dir);


%% PLOT TIMESERIES

 plot_sem = 1;
 data_types =  {'fv_data', 'av_data', 'curv_data', 'dist_data', 'dist_data_delta'};

% Convert names - dashes to underscore.
for i = 1:numel(strain_folders)
    if isfield(strain_folders(i), 'name') && ischar(strain_folders(i).name) || isstring(strain_folders(i).name)
        strain_folders(i).name = strrep(strain_folders(i).name, '-', '_');
    end
end

gp_data = {
    'csw1118_none', 'F', [0.7 0.7 0.7]; % light grey
    'csw1118_left', 'F', [0.8, 0, 0]; % red
    'csw1118_both', 'F', [0.52, 0.12, 0.57]; % purple
    'csw1118_right', 'F', [0, 0, 0.8]; % blue
    };

% p33
% cond_titles = {"60deg-gratings-4Hz-gsval3"...
%     , "60deg-flicker-4Hz-gsval3"...
%     };

% p34
cond_titles = {"60deg-gratings-4Hz-lowlum"...
    , "60deg-flicker-4Hz-lowlum"...
    };


for typ = 1:5

    % Data type to plot
    data_type = data_types{typ};

    % Plot the chosen strain against the ES controls.
    gps2plot = [1,2,3,4];

    % Data in time series are downsampled by 10.
    f_xgrp = plot_allcond_acrossgroups_tuning(DATA, gp_data, cond_titles, data_type, gps2plot, plot_sem);
    f_xgrp.Position = [26   731   862   273];

    % fname = fullfile(save_folder, strcat(grp_title, '_', data_type, ".pdf"));
    % exportgraphics(f_xgrp ...
    %     , fname ...
    %     , 'ContentType', 'vector' ...
    %     , 'BackgroundColor', 'none' ...
    %     ); 
    % close
end



%% OLD CODE %%%%%%%%%%%%%%%%%%%%

    % 
    % 
    % ROOT_DIR = '/Users/burnettl/Documents/Projects/oaky_cokey';
    % % Move to the directory to where the results per experiment are saved:
    % protocol_dir = fullfile(ROOT_DIR, 'results', protocol);
    % cd(protocol_dir);
    % 
    % % Generate the struct 'DATA' that combines data across experiments and
    % % separates data into conditions.
    % path_to_files = strcat("/Users/burnettl/Documents/Projects/oaky_cokey/results/", protocol, "/csw1118-");
    % 
    % sides = {"none", "left", "right"};
    % 
    % for side = 1:3
    %     a = comb_data_across_cohorts_cond(strcat(path_to_files, sides{side}));
    %     if side == 1
    %         DATA_NONE = a;
    %     elseif side == 2
    %         DATA_LEFT = a;
    %     elseif side == 3
    %         DATA_RIGHT = a;
    %     end 
    % end 
    % 
    % 
    % % % Store figures in folders of the day that they were created too. Can go
    % % % back and look at previous versions. 
    % % date_str = string(datetime('now','TimeZone','local','Format','yyyy_MM_dd'));
    % % 
    % % % If saving the figures - create a folder to save them in:
    % % save_folder = fullfile(ROOT_DIR, "figures", protocol, date_str);
    % % if ~isfolder(save_folder)
    % %     mkdir(save_folder);
    % % end
    % 
    % 
    % 
    % 
    % %% Plot the timeseries responses of different strains versus ES for different data metrics.
    % 
    % plot_sem = 0;
    % data_types =  {'fv_data', 'av_data', 'curv_data', 'dist_data', 'dist_data_delta'};
    % 
    % % % Convert names - dashes to underscore.
    % % for i = 1:numel(strain_folders)
    % %     if isfield(strain_folders(i), 'name') && ischar(strain_folders(i).name) || isstring(strain_folders(i).name)
    % %         strain_folders(i).name = strrep(strain_folders(i).name, '-', '_');
    % %     end
    % % end
    % 
    % for typ = 1:5
    %     figure
    % 
    %     % Data type to plot
    %     data_type = data_types{typ};
    % 
    %         for strain = 1:3
    % 
    %             if strain == 1
    %                 DATA = DATA_NONE;
    %                 col = [0.7 0.7 0.7];
    %             elseif strain == 2
    %                 DATA = DATA_LEFT;
    %                 col = [1 0.5 0.5];
    %             elseif strain == 3
    %                 DATA = DATA_RIGHT;
    %                 col = [0.5 0.5 1];
    %             end 
    % 
    % 
    %             gps2plot = 1;
    %             gp_data = {
    %                 "csw1118", 'F', col;
    %                 };
    % 
    %             % Data in time series are downsampled by 10.
    %             plot_timeseries_across_groups_all_cond(DATA, gp_data, cond_titles, data_type, gps2plot, plot_sem)
    % 
    %         end 
    % 
    %     f = gcf;
    %     f.Position = [925   572   792   205]; %[26   731   862   273];
    % 
    %     % fname = fullfile(save_folder, strcat(grp_title, '_', data_type, ".pdf"));
    %     % exportgraphics(f_xgrp ...
    %     %     , fname ...
    %     %     , 'ContentType', 'vector' ...
    %     %     , 'BackgroundColor', 'none' ...
    %     %     ); 
    %     % close
    % end
    % 
    % % end 