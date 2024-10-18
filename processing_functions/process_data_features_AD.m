function process_data_features_AD(path_to_folder, save_folder, date_str)
    % Processes optomotor freely-walking data from FlyTracker and saves the
    % mean/ med values per 'condition' within the experiment in arrays. it
    % also saves all of the variables with the full data across the entrie
    % experiments, such as velocity, angular velocity, distance from the
    % wall and heading in the same file. 
    
    % Inputs
    % ______
    
    % path_to_folder : Path
    %               Path of data to analyse.
    
    % save_folder : path 
    %          Path to save the processed data.        
   
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

    cd(path_to_folder)

    % Find times of experiments
    time_folders = dir('*_*');

    % Remove '.DS_Store' file if it exists.
    time_names = {time_folders.name};
    time_folders = time_folders(~strcmp(time_names, '.DS_Store'));

    n_time_exps = length(time_folders);
    
    for exp  = 1:n_time_exps
    
        clear feat LOG trx

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

        % create array with all log names so that can refer to them

        log_meta = LOG.meta;
        log_acclim_off1 = LOG.acclim_off1;
        log_acclim_patt = LOG.acclim_patt;
        log_1 = LOG.log_1;
        log_2 = LOG.log_2;
        log_3 = LOG.log_3;
        log_4 = LOG.log_4;
        log_5 = LOG.log_5;
        log_6 = LOG.log_6;
        log_7 = LOG.log_7;
        log_8 = LOG.log_8;
        log_9 = LOG.log_9;
        log_10 = LOG.log_10;
        log_11 = LOG.log_11;
        log_12 = LOG.log_12;
        log_13 = LOG.log_13;
        log_14 = LOG.log_14;
        log_15 = LOG.log_15;
        log_16 = LOG.log_16;
        log_acclimoff2 = LOG.acclim_off2;

        log_names = fieldnames(LOG);

        % create struct to store results of make_mean_datapoints for each
        % log

        log_results = struct();

        % % create figure to make subplots within
        % figure;

        for i = 2:length(log_names) % starting at 3 to just get all the conditional logs, and subtracting 1 to remove acclim off2
            % get current log

            current_log = LOG.(log_names{i});
            current_n_conditions = size(current_log.start_t, 2);

            % needed for v10 pre-10/17/2024, sets acclim_patt.dir
            if i == 3
                current_log.dir = 0;
            end

            % process velocity for each log
            [vel_data_per_cond_mean, vel_data_per_cond_med] = make_mean_datapoints(current_log, feat, trx, n_flies, current_n_conditions, "vel");

            log_results.(log_names{i}).vel_data_per_cond_mean = vel_data_per_cond_mean;
            log_results.(log_names{i}).vel_data_per_cond_med = vel_data_per_cond_med;

            % process angular velocity for each log
            [ang_vel_data_per_cond_mean, ang_vel_data_per_cond_med] = make_mean_datapoints(current_log, feat, trx, n_flies, current_n_conditions, "angvel");
           
            log_results.(log_names{i}).ang_vel_data_per_cond_mean = ang_vel_data_per_cond_mean;
            log_results.(log_names{i}).ang_vel_data_per_cond_med = ang_vel_data_per_cond_med;

            % process angular velocity : velocity ratio
            [ratio_data_per_cond] = make_mean_datapoints(current_log, feat, trx, n_flies, current_n_conditions, "ratio");

            log_results.(log_names{i}).ratio_data_per_cond = ratio_data_per_cond;

            % process distance to wall
            [dist_data_per_cond_mean, dist_data_per_cond_med] = make_mean_datapoints(current_log, feat, trx, n_flies, current_n_conditions, "dist");

            log_results.(log_names{i}).dist_data_per_cond_mean = dist_data_per_cond_mean;
            log_results.(log_names{i}).dist_data_per_cond_med = dist_data_per_cond_med;

            % % create subplot
            % subplot(length(log_names), 1, i);
            % 
            % % plot ang_vel_mean
            % plot(ang_vel_data_per_cond_mean);
            % 
            % % create title for each subplot
            % title([log_names{i}, ' - Angular Velocity Mean']);
        end

                %% SAVE
        if ~isfolder(save_folder)
            mkdir(save_folder);
        end
                
        % save data
        save(fullfile(save_folder, strcat(date_str, '_', time_str, '_data.mat')) ...
            , 'LOG' ...
            , 'log_meta' ...
            , 'log_acclim_off1' ...
            , 'log_acclim_patt' ...
            , 'log_1' ...
            , 'log_2' ...
            , 'log_3' ...
            , 'log_4' ...
            , 'log_5' ...
            , 'log_6' ...
            , 'log_7' ...
            , 'log_8' ...
            , 'log_9' ...
            , 'log_10' ...
            , 'log_11' ...
            , 'log_12' ...
            , 'log_13' ...
            , 'log_14' ...
            , 'log_15' ...
            , 'log_16' ...
            , 'log_acclimoff2'...
            , 'feat' ...
            , 'trx' ...
            , 'log_results'...
            );
    end


        % Log = LOG.Log;
        
        % n_conditions = 14;

        % n_conditions = size(LOG.log_2.start_t, 2); %% have to figure out what this will be now, unsure if its each condition within the log or whether each condition is the log itself
   
        %%%%%%% NOT V10 LOG FORMAT %%%%%%%%%%%%%%%%%

        % Process data per CONDITION
        % 
        % %% Process velocity data
        % % now need to make_mean_datapoints for every single log and have to
        % % save it in some sort of array format
        % [vel_data_per_cond_mean, vel_data_per_cond_med] = make_mean_datapoints(Log, feat, trx, n_flies, n_conditions, "vel");
        % 
        % %% Process angular velocity data
        % [ang_vel_data_per_cond_mean, ang_vel_data_per_cond_med] = make_mean_datapoints(Log, feat, trx, n_flies, n_conditions, "angvel");
        % 
        % %% Process angular velocity : velocity ratio data
        % [ratio_data_per_cond] = make_mean_datapoints(Log, feat, trx, n_flies, n_conditions, "ratio");
        % 
        % %% Process distance to wall data 
        % [dist_data_per_cond_mean, dist_data_per_cond_med] = make_mean_datapoints(Log, feat, trx, n_flies, n_conditions, "dist");
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % for i = 3:length(log_names) %%%%%%%%% change to i = 2:length(log_names) so that it starts at log_1
            % % process velocity for each log
            % [vel_data_per_cond_mean, vel_data_per_cond_med] = make_mean_datapoints(LOG.(log_names{i}), feat, trx, n_flies, n_conditions, "vel");

            % process angular velocity for each log
            % [ang_vel_data_per_cond_mean, ang_vel_data_per_cond_med] = make_mean_datapoints(LOG.log_2, feat, trx, n_flies, n_conditions, "angvel");

            % % process angular velocity : velocity ratio
            % [ratio_data_per_cond] = make_mean_datapoints(LOG.(log_names{i}), feat, trx, n_flies, n_conditions, "ratio");
            % 
            % % process distance to wall
            % [dist_data_per_cond_mean, dist_data_per_cond_med] = make_mean_datapoints(LOG.(log_names{i}), feat, trx, n_flies, n_conditions, "dist");


            %% save these somehow individually for each log? or all in one? not sure or have to create one big array?
    
        % end


end 



