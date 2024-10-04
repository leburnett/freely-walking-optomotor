function track_videos(date_or_list, folder_path, video_type)
    % Track videos of the freely-moving optomotor experiments using the
    % FlyTracker programme. 

    % Add function's path to path
    cd('C:\MatlabRoot\FreeWalkOptomotor'); 
    modpath;
    savepath;

    % Set path to data
    project_data_folder = 'C:\MatlabRoot\FreeWalkOptomotor\data';
    
    if date_or_list == "list"
        % Option 1 - list of paths 
        % list of all folders to be processed
        folders = folder_path;
        
    elseif date_or_list == "date"
        % Option 2 - date folder and track all videos within all folders.
    
        date_folder = fullfile(project_data_folder, folder_path);
        cd(date_folder)
    
        exp_folders = dir('*_*');
        n_exp_folders = length(exp_folders);
        
        folders = cell(n_exp_folders, 1);
        for i = 1:n_exp_folders
            folders{i} = string(fullfile(exp_folders(i).folder, exp_folders(i).name));
        end 
    
    end 
    
    % set options (omit any or all to use default options)
    options.granularity  = 10000;
    %options.num_chunks   = 4;       % set either granularity or num_chunks
    options.num_cores    = 1; % was 4
    options.max_minutes  = Inf;
    options.save_JAABA   = 1;
    options.save_seg     = 0;
    
    % loop through all folders
    for f=1:numel(folders)
        
        % set calibration file for each folder
        exp_folder = folders{f}; 
        cd(exp_folder)
        % rec_dir = dir('REC*');
        % rec_folder = fullfile(rec_dir(1).folder, rec_dir(1).name);
        f_calib = fullfile(exp_folder, 'calibration.mat');

        % set parameters for specific folder
        videos.dir_in  = exp_folder; %folders{f};
        videos.dir_out = exp_folder; % folders{f}; % save results into video folder
        videos.filter = strcat('*.', string(video_type));     % extension of the videos to process
        
        % track all videos within folder
        tracker(videos,options, f_calib);
    end

end 


% folders = {'C:\MatlabRoot\FreeWalkOptomotor\data\2024_06_25\10_15_29','C:\MatlabRoot\FreeWalkOptomotor\data\2024_06_25\10_29_37'}; 
                   % 'C:\MatlabRoot\FreeWalkOptomotor\data\2024_06_25\13_36_50',...
                   % 'C:\MatlabRoot\FreeWalkOptomotor\data\2024_06_25\13_52_39',...
                   % 'C:\MatlabRoot\FreeWalkOptomotor\data\2024_06_25\14_10_55',...
                   % 'C:\MatlabRoot\FreeWalkOptomotor\data\2024_06_25\17_30_29',...
                   % 'C:\MatlabRoot\FreeWalkOptomotor\data\2024_06_25\18_00_28'};

% track_videos('list', folders, 'ufmf')


% track_videos('date', '2024_06_25', 'ufmf')













