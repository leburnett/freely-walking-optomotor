% Batch process with simle_noninteractive_flytracker.m
% 01/10/24
% Burnett
function tracking_log = batch_track_ufmf(date_folder)
    
    % date_folder = 'C:\Users\burnettl\Documents\oakey-cokey\DATA\00_unprocessed\1111_11_11\protocol_25\jfrc100_es_shibire_kir\F\15_44_35';
    
    cd(date_folder)
    folder_parts = strsplit(date_folder, '/');
    disp(folder_parts);
    disp(length(folder_parts));
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
    
    % Set path to calibration file.
    input_calibration_file_name = 'C:\Users\burnettl\Documents\GitHub\freely-walking-optomotor\tracking\calibration.mat';

    video_names = cell(n_videos, 1);
    t2track = zeros(n_videos, 1);

    for f=1:n_videos
    
        % output_folder_name  = ufmf_files(f).folder;
        output_folder_name = fullfile(ufmf_files(f).folder, ufmf_files(f).name(1:end-5));
        input_video_file_name = fullfile(ufmf_files(f).folder, ufmf_files(f).name);
    
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