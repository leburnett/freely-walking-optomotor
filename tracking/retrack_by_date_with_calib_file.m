% script to rerun tracking with embedded calibration file (3/10-5/08)
reprocessing_folder = "F:\oakey-cokey\DATA\0000_reprocessing_local";

% enter reprocessing folder
cd(reprocessing_folder)

% make list of all date folder names
date_folder_array = dir(reprocessing_folder);
is_dir = [date_folder_array.isdir];
folder_names = {date_folder_array(is_dir).name};
folder_names = folder_names(~ismember(folder_names, {'.', '..'}));

% loop through each folder, passing it into the batch_track_ufmf function
for i = 1:length(folder_names)
    date_folder = fullfile(reprocessing_folder, folder_names{i});
    fprintf('Processing folder: %s\n', date_folder);
    
    tracking_log = batch_track_ufmf_p27(date_folder);
    
end