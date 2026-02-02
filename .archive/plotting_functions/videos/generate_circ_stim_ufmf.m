function generate_circ_stim_ufmf()
  
% Make videos per condition with the stimulus around the outside of the 
% behavioural video in a loop.

% - Generate movie from ufmf file. Works within the folder that it is called. 
% - Requires JAABA code from kristenBranson. 'get_readframe_fcn' is from this repo. 
% - Load patterns from GitHub folder: "/Users/burnettl/Documents/GitHub/freely-walking-optomotor/patterns"
% - Stimulus derived from pattern.Pats

% Inputs 
%       condition_n : int or list. 
%           The single condition, or list of conditions for which stimulus
%           videos should be made. If empty, then the function defaults to
%           making videos for all conditions. 

% NOTE: the path to the patterns, the JAABA directory and the output saving folder are
% HARD-CODED within "create_stim_video_loop". Please update these paths for
% your own system.

%%  Initialise paths 

% Add JAABA folder to the path
JAABA_folder = "/Users/burnettl/Documents/Non-GitHub-Repos/JAABA-master";
JAABA_paths = genpath(JAABA_folder);
addpath(JAABA_paths)

% Get video file name.  
video_files = dir('*.ufmf');
if isempty(video_files)
    disp('No .ufmf video files found in this folder.')
else
    video_filename = video_files(1).name;
end 

% Load the LOG file. 
log_files = dir('LOG*');
if isempty(log_files)
    disp('No LOG files found in this folder.')
else
    load(log_files(1).name, 'LOG');
end 
fly_strain = LOG.meta.fly_strain;

trx_files = dir('**/trx.mat');
if isempty(trx_files)
    disp('No trx file found in this folder.')
else
    load(fullfile(trx_files(1).folder, trx_files(1).name), 'trx');
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
    create_stim_video_loop(log, trx, video_filename, rep, fly_strain)

end


end
       