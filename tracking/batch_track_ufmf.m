% Batch process with simple_noninteractive_flytracker.m
% 01/10/24
% Burnett
function tracking_log = batch_track_ufmf(date_folder)
    
    % date_folder = 'C:\Users\burnettl\Documents\oakey-cokey\DATA\00_unprocessed\1111_11_11\protocol_25\jfrc100_es_shibire_kir\F\15_44_35';
    
    cd(date_folder)
    % folder_parts = strsplit(date_folder, '\'); % \ if running manually in matlab, / if running automatically through python
   
    if contains(date_folder, '/') % Python
        folder_parts = strsplit(date_folder, '/');
    elseif contains(date_folder, '\') % MATLAB
        folder_parts = strsplit(date_folder, '\');
    end 
    
    % disp(folder_parts);
    % disp(length(folder_parts));
    date_str = folder_parts{end-4};

    % Find all ufmf video files within the date folder. 
    ufmf_files = dir(fullfile(date_folder, '**', '*.ufmf'));
    n_videos = height(ufmf_files);
    
    % set options (omit any or all to use default options)
    options.num_chunks   = 16;       % set either granularity or num_chunks
    options.num_cores    = 8;
    options.max_minutes  = Inf;
    options.save_JAABA   = 1;
    options.save_seg     = 0;
    options.force_calib  = 1;
    options.do_recompute_tracking = 1;
    
    % Set path to calibration file.
    % input_calibration_file_name = 'C:\Users\burnettl\Documents\GitHub\freely-walking-optomotor\tracking\calibration.mat';
    if ~exist('base_calib', 'var')
        base_calib = load("C:\Users\burnettl\Documents\GitHub\freely-walking-optomotor\tracking\calibration.mat");
    end

    video_names = cell(n_videos, 1);
    t2track = zeros(n_videos, 1);

    for f=1:n_videos
    
        cd(ufmf_files(f).folder);

        % Load the LOG file to get the number of flies in the experiment.
        log_files= dir('LOG*');
        if isempty(log_files)
            disp("No LOG file found in this folder.")
        else
            load(log_files(1).name, 'LOG')
        end

        output_folder_name = fullfile(ufmf_files(f).folder, ufmf_files(f).name(1:end-5));
        input_video_file_name = fullfile(ufmf_files(f).folder, ufmf_files(f).name);

        % set number of flies from LOG
        calib = base_calib.calib;
        % Update 'n_flies' in the calibration file for tracking.
        calib.n_flies = str2double(LOG.meta.n_flies);
        disp(strcat("Number of flies in calibration file: ", string(calib.n_flies)))

        input_calibration_file_name = fullfile(ufmf_files(f).folder, 'calibration.mat');
        
        % save as calibration.mat
        save(input_calibration_file_name, 'calib')

        if ~isfile(input_calibration_file_name)
            disp("Calibration file for the video does not exist. Please make the 'calibration.mat' file for this video.")
        end 
    
        tic
        simple_noninteractive_flytracker( ...
            output_folder_name ...
            , input_video_file_name ...
            , input_calibration_file_name ...
            , options ...
            )
        t2t = toc;
        disp(t2t)

        % For logging
        video_names{f, 1} = ufmf_files(f).folder;
        t2track(f, 1) = t2t;
    end

    tracking_log = table(video_names, t2track);

    log_fname = fullfile('C:\Users\burnettl\Documents\oakey-cokey\tracking_log', strcat('Tracked_', date_str, '.mat'));
    save(log_fname, 'tracking_log')
end 