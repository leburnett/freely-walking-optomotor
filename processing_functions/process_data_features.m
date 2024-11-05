function process_data_features(path_to_folder, save_folder, date_str)
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

        data_path = cd;
        subfolders = split(data_path, '/');
        sex = subfolders{end-1};
        strain = subfolders{end-2};
        protocol = subfolders{end-3};

        save_str = strcat(date_str, '_', time_str, '_', strain, '_', protocol, '_', sex);

        % Check in case there is something wrong with the folder structure.
        if protocol(1)~='p'
            disp('protocol string does not start with a p - check folder structure.')
        end

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

        Log = LOG.Log;

        n_conditions = size(Log, 1);
   
        % Process data per CONDITION

        %% Process velocity data
        [vel_data_per_cond_mean, vel_data_per_cond_med] = make_mean_datapoints(Log, feat, trx, n_flies, n_conditions, "vel");

        %% Process angular velocity data
        [ang_vel_data_per_cond_mean, ang_vel_data_per_cond_med] = make_mean_datapoints(Log, feat, trx, n_flies, n_conditions, "angvel");
        
        %% Process angular velocity : velocity ratio data
        [ratio_data_per_cond] = make_mean_datapoints(Log, feat, trx, n_flies, n_conditions, "ratio");

        %% Process distance to wall data 
        [dist_data_per_cond_mean, dist_data_per_cond_med] = make_mean_datapoints(Log, feat, trx, n_flies, n_conditions, "dist");
        
        % Generate quick overview plots:
        combined_data = combine_data_one_cohort(feat, trx);
        % 1 - histograms of locomotor parameters
        f_overview = make_overview(combined_data, strain, sex, protocol);

        hist_save_folder = '/Users/burnettl/Documents/Projects/oaky_cokey/results/overview_figs/loco_histograms';
        if ~isfolder(hist_save_folder)
            mkdir(hist_save_folder);
        end
        saveas(f_overview, fullfile(hist_save_folder, strcat(save_str, '_hist.png')), 'png')

        feat_save_folder = '/Users/burnettl/Documents/Projects/oaky_cokey/results/overview_figs/feat_overview';
        if ~isfolder(feat_save_folder)
            mkdir(feat_save_folder);
        end

        f_feat = plot_all_features(Log, feat, trx, save_str);
        saveas(f_feat, fullfile(feat_save_folder, strcat(save_str, '_feat.png')), 'png')

        %% SAVE
        if ~isfolder(save_folder)
            mkdir(save_folder);
        end
                
        % save data
        save(fullfile(save_folder, strcat(save_str, '_data.mat')) ...
            , 'LOG' ...
            , 'Log' ...
            , 'feat' ...
            , 'trx' ...
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



