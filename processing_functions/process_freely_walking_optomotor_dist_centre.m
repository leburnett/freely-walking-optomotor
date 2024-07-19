function process_freely_walking_optomotor_dist_centre(path_to_folder, data_save_folder, genotype)
    
    % Function to analyse the DISTANCE FROM THE CENTRE of the flies across the increasing
    % contrast optomotor experiments. 

    % Inputs
    % ______
    
    % path_to_folder : Path
    %               Path to data to analyse. e.g. '/Users/burnettl/Documents/Janelia/HMS_2024/DATA/2024_06_17';

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
    
    for exp = 1:n_time_exps
    
        clear data Log
    
        time_str = time_folders(exp).name;
        disp(time_str)
    
        % Move into the experiment directory
        cd(fullfile(time_folders(exp).folder, time_folders(exp).name))
    
        %% load the files that you need:

         % Open the LOG
        log_files = dir('LOG_*');
        n_logs = length(log_files);

        if n_logs > 1
            disp('More than 1 LOG file in the folder');
        else
            load(fullfile(log_files(1).folder, log_files(1).name), 'Log');
        end 
        
        % Open the DATA
        dist_wall_files = dir('**/dist_to_wall.mat');
        n_files = length(dist_wall_files);

        if n_files > 1
            disp('More than 1 "dist_to_wall" file in the folder');
        else
            load(fullfile(dist_wall_files(1).folder, dist_wall_files(1).name), 'data');
        end 
    
        % Saving paths and filenames
        save_str = strcat(date_str, '_', time_str, '_', genotype);
    
        % save data
        save(fullfile(data_save_folder, strcat(save_str, '_dist2centre_data.mat')), 'Log', 'data', 'save_str');

    end

end

