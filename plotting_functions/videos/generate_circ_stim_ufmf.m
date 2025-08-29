function generate_circ_stim_ufmf(varargin)
  
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

test_data_path = "/Users/burnettl/Documents/Projects/oaky_cokey/data/2025_07_07/protocol_27/ss26283_H1_shibire_kir/F/14_01_24";
cd(test_data_path);

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

% If the condition IDs are not given as an input to the function, default
% to all conditions. 
if numel(varargin) >= 1
    cond_to_plot = varargin{1};
else
    cond_to_plot = 1:1:n_cond;
end 

% Run through each condition 
for condition_n = cond_to_plot

    disp(strcat("Video for condition ", string(condition_n)))
    
    for i = 1:length(log_fields)

        log_field = log_fields{i};
        log = LOG.(log_field);
    
        if i > n_cond
            rep = 2;
        else
            rep = 1;
        end 

        % Create the videos. 
        create_stim_video_loop(log, trx, video_filename, rep)

    end
end
       