% setup_path.m
% Configure the MATLAB path for the freely-walking-optomotor repository.
%
% Run this once at the start of each MATLAB session, or add it to your
% MATLAB startup file:
%   edit(fullfile(userpath, 'startup.m'))
%   % Then add: run('/path/to/freely-walking-optomotor/setup_path.m')
%
% Usage:
%   run('setup_path.m')         % from repo root
%   run('/full/path/to/setup_path.m')   % from anywhere

REPO_ROOT = fileparts(mfilename('fullpath'));

addpath(genpath(fullfile(REPO_ROOT, 'config')));
addpath(genpath(fullfile(REPO_ROOT, 'src', 'processing')));
addpath(genpath(fullfile(REPO_ROOT, 'src', 'plotting')));
addpath(genpath(fullfile(REPO_ROOT, 'src', 'tracking')));
addpath(genpath(fullfile(REPO_ROOT, 'src', 'analysis')));
addpath(genpath(fullfile(REPO_ROOT, 'src', 'model')));
addpath(genpath(fullfile(REPO_ROOT, 'src', 'shared')));
addpath(genpath(fullfile(REPO_ROOT, 'src', 'patterns', 'make_patterns')));

% Note: src/protocols/ is intentionally excluded from the path.
% Protocol files are run-scripts, not callable functions.

% FlyTracker (external dependency, expected as sibling repo)
FLYTRACKER_ROOT = fullfile(fileparts(REPO_ROOT), 'FlyTracker');
if exist(FLYTRACKER_ROOT, 'dir')
    addpath(genpath(FLYTRACKER_ROOT));
end

disp('MATLAB path configured for freely-walking-optomotor.')
