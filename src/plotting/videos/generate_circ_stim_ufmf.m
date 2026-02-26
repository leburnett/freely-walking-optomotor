function generate_circ_stim_ufmf(delayed_generation, results_path)
  
% Make videos per condition with the stimulus around the outside of the 
% behavioural video in a loop.

% - Generate movie from ufmf file. Works within the folder that it is called. 
% - Requires JAABA code from kristenBranson. 'get_readframe_fcn' is from this repo. 
% - Load patterns from GitHub folder: "/Users/burnettl/Documents/GitHub/freely-walking-optomotor/patterns"
% - Stimulus derived from pattern.Pats

% Inputs 
%       delayed_generation: bool
%               Whether the videos are being made during the standard processing "process_freely_walking_data", 
%               or afterwards, in which case "delayed_generation" = 1. 
%               If the stimulus videos are made after the processing, this
%               script needs to read in the updated "trx" from the results
%               file - otherwise the videos will be made with the raw
%               tracking data.

% NOTE: the path to the patterns, the JAABA directory and the output saving folder are
% HARD-CODED within "create_stim_video_loop". Please update these paths for
% your own system.

%%  Initialise paths 

% Add JAABA folder to the path
% JAABA_folder = "/Users/burnettl/Documents/Non-GitHub-Repos/JAABA-master"; %laptop
JAABA_folder = "C:\Users\burnettl\Documents\GitHub\JAABA-master"; % processing computer
JAABA_paths = genpath(JAABA_folder);
addpath(JAABA_paths)

% Get video file name.  
video_files = dir('*.ufmf');
if isempty(video_files)
    disp('No .ufmf video files found in this folder.')
else
    video_filename = video_files(1).name;
end

if nargin == 0
    delayed_generation = 0;
    results_path = "C:\Users\burnettl\Documents\oakey-cokey\results";
end


exp_folder = cd;
if contains(exp_folder, '\')
    delimm = "\";
else 
    delimm = "/";
end 
path_strs = strsplit(exp_folder, delimm);
time_str = strrep(path_strs{end}, '_', '-');
sex = path_strs{end-1};
strain = path_strs{end-2};
protocol = path_strs{end-3};
date_str = strrep(path_strs{end-4}, '_', '-');

metadata.time_str = time_str;
metadata.sex = sex;
metadata.strain = strain;
metadata.protocol = protocol;
metadata.date_str = date_str;

if delayed_generation == 0
    % Load the LOG file. 
    log_files = dir('LOG*');
    if isempty(log_files)
        disp('No LOG files found in this folder.')
    else
        load(log_files(1).name, 'LOG');
    end 
    % fly_strain = LOG.meta.fly_strain;
    
    trx_files = dir('**/trx.mat');
    if isempty(trx_files)
        disp('No trx file found in this folder.')
    else
        load(fullfile(trx_files(1).folder, trx_files(1).name), 'trx');
    end

else
    save_str = strcat(date_str, '_', time_str, '_', strain, '_', protocol, '_', sex);
    save_folder = fullfile(results_path, protocol, strain, sex);
    
    load(fullfile(save_folder, strcat(save_str, '_data.mat')), 'LOG', 'trx');
    % fly_strain = LOG.meta.fly_strain;

end 

%% Find the appropriate logs for the condition and make the videos.

% Find the number of conditions:
fields = fieldnames(LOG);
log_fields = fields(startsWith(fields, 'log_'));
n_cond = numel(log_fields)/2;

for i = 1:length(log_fields)

    disp(strcat("Video for condition ", string(i)))

    log_field = log_fields{i};
    log = LOG.(log_field);

    if i > n_cond
        rep = 2;
    else
        rep = 1;
    end 

    % Create the videos. 
    create_stim_video_loop(log, trx, video_filename, rep, metadata)

end


end
       