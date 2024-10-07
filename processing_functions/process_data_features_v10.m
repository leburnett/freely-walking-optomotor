% function process_data_features(path_to_folder, save_folder, date_str)

    % Processes optomotor freely-walking data from FlyTracker and saves the
    % mean/ med values per 'condition' within the experiment in arrays. it
    % also saves all of the variables with the full data across the entrie
    % experiments, such as velocity, angular velocity, distance from the
    % wall and heading in the same file. 

    % ADDS THE SCRIPT TO PROCESS ONLY THE V10 PROTCOL
    
    % Inputs
    % ______
    
    % path_to_folder : Path
    %               Path of data to analyse.
    
    % save_folder : path 
    %          Path to save the processed data.        
   
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

    % cd(path_to_folder) % when function

    path_to_folder = 'C:\Users\deva\Documents\projects\oakey_cokey\data\2024_10_03\Protocol_v10_all_tests\CS_w1118';
    cd(path_to_folder);
    time_folders = dir('*_*');
    save_folder = 'savig_for_now';

    % Remove '.DS_Store' file if it exists.
    time_names = {time_folders.name};
    time_folders = time_folders(~strcmp(time_names, '.DS_Store'));

    n_time_exps = length(time_folders);

    num_conditions = 19; % includes the acclim off/patt and acclim off at end

    for exp  = 1:n_time_exps
    
        clear feat LOG trx

        time_str = time_folders(exp).name;
        disp(time_str)

        % Move into the experiment directory 
        cd(fullfile(time_folders(exp).folder, time_folders(exp).name))
        
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

        %% Load 'trx'
        if contains(mfolder, 'movie') % movie folder configuration
            trx_file_path = 'movie/movie_JAABA/trx.mat';
        else
            trx_file_path = strcat(mfolder, '/', 'trx.mat');
        end

        if ~isfile(trx_file_path)
            warning('Experiment has not been processed using FlyTracker. Make sure the data has been processed and that "{moviename}-track.mat" exists within the movie/movie_JAABA/ directory.')
        else
            load(trx_file_path, 'trx');
        end

 
        % Number of flies tracked in the experiment
        n_flies = size(feat.data, 1);
    
        % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

        % new loop to process all of the conditions 5 NTO WORKING
     
        Log_to_process = LOG.acclim_off1;
        n_trials = size(Log_to_process, 1);

        %% Process velocity data
        [vel_data_per_cond_mean, vel_data_per_cond_med] = make_mean_datapoints(Log_to_process, feat, trx, n_flies, n_trials, "vel");

        %% Process angular velocity data
        [ang_vel_data_per_cond_mean, ang_vel_data_per_cond_med] = make_mean_datapoints(Log_to_process, feat, trx, n_flies, n_trials, "angvel");
        
        %% Process angular velocity : velocity ratio data
        [ratio_data_per_cond] = make_mean_datapoints(Log_to_process, feat, trx, n_flies, n_trials, "ratio");

        %% Process distance to wall data 
        [dist_data_per_cond_mean, dist_data_per_cond_med] = make_mean_datapoints(Log_to_process, feat, trx, n_flies, n_trials, "dist");
       




%% HOW YOU GET THE LOGS 'log_%d'

        % % open the log
        % big_LOG = dir('LOG_*');
        % load(fullfile(big_LOG(1).folder, big_LOG(1).name), 'LOG');
        % 
        % % load each indiv log file
        % for condition = 1:15
        %     big_LOG = dir('LOG_*');
        %     load(fullfile(big_LOG(1).folder, big_LOG(1).name), 'LOG');
        % 
        % 
        % end
        % 
        % 
        % rec_folder = dir('REC_*');
        % if isempty(rec_folder)
        %     warning('REC_... folder does not exist inside the time folder.')
        % end 
        % 
        % % move into recording folder
        % isdir = [rec_folder.isdir]==1;
        % rec_folder = rec_folder(isdir);
        % cd(fullfile(rec_folder(1).folder, rec_folder(1).name))
        % 
        % movie_folder = dir();
        % movie_folder = movie_folder([movie_folder.isdir]);
        % mfolder = movie_folder(3).name;


    end
