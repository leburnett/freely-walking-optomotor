function process_data_features(path_to_folder, save_folder)

    % Inputs
    % ______
    
    % path_to_folder : Path
    %               Path of data to analyse.
    
    % save_folder : path 
    %          Path to save the processed data.        
   
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
    
    % Date
    date_str = path_to_folder(end-9:end);
    % date_str = strrep(path_to_folder(end-9:end), '_', '-');
    cd(path_to_folder)

    % Find times of experiments
    time_folders = dir('*_*');

    % Remove '.DS_Store' file if it exists.
    time_names = {time_folders.name};
    time_folders = time_folders(~strcmp(time_names, '.DS_Store'));

    n_time_exps = length(time_folders);
    
    for exp  = 1:n_time_exps
    
        clear feat Log trk

        time_str = time_folders(exp).name;
        disp(time_str)

        % Move into the experiment directory 
        cd(fullfile(time_folders(exp).folder, time_folders(exp).name))
      
        %% load the files that you need:
        
        % Open the LOG 
        log_files = dir('LOG_*');
        load(fullfile(log_files(1).folder, log_files(1).name), 'LOG');
    
        rec_folder = dir('REC_*');
        if isempty(rec_folder)
            warning('REC_... folder does not exist inside the time folder.')
        end 

        % Move into recording folder
        isdir = [rec_folder.isdir]==1;
        rec_folder = rec_folder(isdir);
        cd(fullfile(rec_folder(1).folder, rec_folder(1).name))

        movie_folder = dir();
        movie_folder = movie_folder([movie_folder.isdir]);
        mfolder = movie_folder(3).name;

        %% Load 'feat'
        if contains(mfolder, 'movie') % movie folder configuration
            feat_file_path = 'movie/movie-feat.mat';
        else
            feat_file_path = strcat(rec_folder(1).name, '-feat.mat');
        end

        if ~isfile(feat_file_path)
            warning('Experiment has not been processed using FlyTracker. Make sure the data has been processed and that "{moviename}-feat.mat" exists within the movie/movie_JAABA/ directory.')
        else
            load(feat_file_path, 'feat');
        end

        %% Load 'trk'
        if contains(mfolder, 'movie') % movie folder configuration
            trk_file_path = 'movie/movie-track.mat';
        else
            trk_file_path = strcat(rec_folder(1).name, '-track.mat');
        end

        if ~isfile(trk_file_path)
            warning('Experiment has not been processed using FlyTracker. Make sure the data has been processed and that "{moviename}-track.mat" exists within the movie/movie_JAABA/ directory.')
        else
            load(trk_file_path, 'trk');
        end

 
        % Number of flies tracked in the experiment
        n_flies = size(feat.data, 1);
    
        % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

        n_conditions = size(Log, 1);
   
        % Process data per CONDITION

        %% Process velocity data
        [vel_data_per_cond_mean, vel_data_per_cond_med] = make_mean_datapoints(Log, feat, trk, n_flies, n_conditions, "vel");

        %% Process angular velocity data
        [ang_vel_data_per_cond_mean, ang_vel_data_per_cond_med] = make_mean_datapoints(Log, feat, trk, n_flies, n_conditions, "angvel");
        
        %% Process angular velocity : velocity ratio data
        [ratio_data_per_cond] = make_mean_datapoints(Log, feat, trk, n_flies, n_conditions, "ratio");

        %% Process distance to wall data 
        [dist_data_per_cond_mean, dist_data_per_cond_med] = make_mean_datapoints(Log, feat, trk, n_flies, n_conditions, "dist");
        

        %% SAVE
        
        % save data
        save(fullfile(save_folder, strcat(date_str, '_', time_str, '_data.mat')) ...
            , 'Log' ...
            , 'feat' ...
            , 'trk' ...
            , 'vel_data_per_cond_mean' ...
            , 'vel_data_per_cond_med' ...
            , 'ang_vel_data_per_cond_mean' ...
            , 'ang_vel_data_per_cond_med' ...
            , 'ratio_data_per_cond' ...
            , 'dist_data_per_cond_mean' ...
            , 'dist_data_per_cond_med' ...
            );
    end

end 



