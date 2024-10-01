% Batch process with simle_noninteractive_flytracker.m
% 01/10/24
% Burnett
function batch_track_ufmf(date_folder)
    
    % date_folder = 'C:\MatlabRoot\FreeWalkOptomotor\data\2024_09_30\Protocol_v11_OFF_no_flicker';
    
    cd(date_folder)
    
    % Find all ufmf video files within the date folder. 
    ufmf_files = dir(fullfile(date_folder, '**', '*.ufmf'));
    
    % set options (omit any or all to use default options)
    options.num_chunks   = 16;       % set either granularity or num_chunks
    options.num_cores    = 8;
    options.max_minutes  = Inf;
    options.save_JAABA   = 1;
    options.save_seg     = 0;
    
    % Set path to calibration file.
    input_calibration_file_name = 'C:\MatlabRoot\FreeWalkOptomotor\data\calibration.mat';
    
    for f=1:height(ufmf_files)
    
        output_folder_name  = ufmf_files(f).folder;
        input_video_file_name = fullfile(ufmf_files(f).folder, ufmf_files(f).name);
    
        tic
        simple_noninteractive_flytracker(output_folder_name ...
            , input_video_file_name ...
            , input_calibration_file_name ...
            , options ...
            )
        toc
    
    end

end 