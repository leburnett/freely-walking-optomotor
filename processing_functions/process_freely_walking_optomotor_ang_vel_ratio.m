function process_freely_walking_optomotor_ang_vel_ratio(path_to_folder, save_figs, figure_save_folder, data_save_folder, genotype, mean_med)
    % Function to analyse the ANGULAR VELOCITY / VELOCITY RATIO of the flies across the increasing
    % contrast optomotor experiments. 

    % uses both 'trx' and 'feat'

    % Inputs
    % ______
    
    % path_to_folder : Path
    %               Path to data to analyse. e.g. '/Users/burnettl/Documents/Janelia/HMS_2024/DATA/2024_06_17';
    
    % save_figs : bool 
    %           Whether to save the figures and data or not. 

    % figure_save_folder : path 
    %          Path to save the figures to if 'save_figs' = true. 

    % data_save_folder : path 
    %          Path to save the data to if 'save_figs' = true. 
    
    % genotype : str
    %           string of the genotype of flies used. Default = 'CSW1118';

    % mean_med : str
    %       Either "mean" to use the mean value of "med" to use the median
    %       value per fly. 
    
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %

    if isempty(genotype)
        genotype = 'CSw1118';
    end
    
    if isempty(save_figs)
        save_figs = false;
    end
    
    % Date
    date_str = strrep(path_to_folder(end-9:end), '_', '-');
    
    % Find times of experiments
    cd(path_to_folder)
    time_folders = dir('*_*');

    % Remove '.DS_Store' file if it exists.
    time_names = {time_folders.name};
    time_folders = time_folders(~strcmp(time_names, '.DS_Store'));

    % Number of experiment folders for that day.
    n_time_exps = length(time_folders);
    
    % video recording rate in frames per second
    fps = 30;
    
    % number of experimental conditions
    n_conditions = 33;
    
    for exp = 1:n_time_exps
    
        clear trx Log feat
    
        time_str = time_folders(exp).name;
        disp(time_str)
    
        title_str = strcat(genotype, '-', date_str, '-', time_str);
        title_str = strrep(title_str, '_', '-');
    
        % Move into the experiment directory
        cd(fullfile(time_folders(exp).folder, time_folders(exp).name))
    
        %% load the files that you need:

        % Open the LOG
        log_files = dir('LOG_*');
        load(fullfile(log_files(1).folder, log_files(1).name), 'Log');
    
        rec_folder = dir('REC_*');
        if isempty(rec_folder)
            warning('REC_... folder does not exist inside the time folder.')
        end

        % Move into recording folder
        cd(fullfile(rec_folder(1).folder, rec_folder(1).name))
        
        % The data will be stored in the folder within that folder, then
        % that same folder name with 'JAABA' at the end.
    
        movie_folder = dir();
        movie_folder = movie_folder([movie_folder.isdir]);
        mfolder = movie_folder(3).name;
    
        if contains(mfolder, 'movie') % movie folder configuration
            trx_file_path = 'movie/movie_JAABA/trx.mat';
        else
            trx_file_path = strcat(mfolder, '/', 'trx.mat');
        end
    
        if ~isfile(trx_file_path)
            warning('Experiment has not been processed using FlyTracker. Make sure the data has been processed and that trx.mat exists within the movie/movie_JAABA/ directory.')
        else
            % load trx
            load(trx_file_path, 'trx');
        end

        % Load 'feat'
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
    
        % Saving paths and filenames
        save_str = strcat(date_str, '_', time_str, '_', genotype);
    
        fig_date_save_folder = fullfile(figure_save_folder, date_str);
        if ~isfolder(fig_date_save_folder)
            mkdir(fig_date_save_folder);
        end
    
        fig_exp_save_folder = fullfile(fig_date_save_folder, time_str);
        if ~isfolder(fig_exp_save_folder)
            mkdir(fig_exp_save_folder);
        end
    
        % Number of flies tracked in the experiment
        n_flies = length(trx);
    
        % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
    
        %% Plot the heading angle of each fly across the entire experiment
    
        % plot_heading_angle_per_fly(Log, trx, n_flies, n_conditions, title_str, save_str, fig_exp_save_folder, save_figs)
    
        %% Plot the angular velocity:
    
        % plot_ang_vel_per_fly(Log, trx, n_flies, n_conditions, fps, title_str, save_str, fig_exp_save_folder, save_figs)
    
        %% Make 'ang datapoints'
        [datapoints_mean, datapoints_med] = make_mean_ang_vel_ratio_datapoints(Log, trx, n_flies, n_conditions, fps);
        
        if mean_med == "mean"
            ang_datapoints = datapoints_mean;
        elseif mean_med == "med"
            ang_datapoints = datapoints_med;
        end 
        %% Plot the mean ang velocity per condition for all flies as scatter points. "Fish plot"
    
        % If you only want to plot the data from the conditions ramping up, up
        % until the first flicker, then use "data_to_use = datapoints(1:17, :)"
        % else use "data_to_use = datapoints".
    
        data_to_use = ang_datapoints; %(1:17, :);
    
        % Update contrast values for acclim / flickers for plotting:
        % OFF ACCLIM
        data_to_use(1,1) = -0.2;
        % ON ACCLIM
        data_to_use(2,1) = -0.1;
        % FLICKER 1
        data_to_use(17,1) = 1.2;
        % FLICKER 2
        data_to_use(32,1) = 1.3;
        % OFF ACCLIM 2
        data_to_use(33,1) = 1.4;
    
        plot_scatter_ang_vel_all_flies(data_to_use, n_flies, title_str, save_str, fig_exp_save_folder, save_figs)
    
        %% Generate a line plot for mean ang vel at each contrast level. "Lips plot"
    
        % Individual flies in light pink/blue.
        % Average across flies in bold.
    
        data_to_use = ang_datapoints; %(1:17, :);
    
        plot_line_ang_vel_all_flies(data_to_use, n_flies, title_str, save_str, fig_exp_save_folder, save_figs)
    
        %% SAVE
    
        % save data
        save(fullfile(data_save_folder, strcat(save_str, '_angvel_data.mat')), 'ang_datapoints', 'data_to_use', 'Log', 'trx', 'datapoints_med', 'datapoints_mean');

    end
    
    % Uncomment if you don't want to view the figures
    close all

end