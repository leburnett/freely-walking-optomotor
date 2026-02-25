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
addpath(genpath(fullfile(REPO_ROOT, 'src', 'matlab', 'processing')));
addpath(genpath(fullfile(REPO_ROOT, 'src', 'matlab', 'plotting')));
addpath(genpath(fullfile(REPO_ROOT, 'src', 'matlab', 'tracking')));
addpath(genpath(fullfile(REPO_ROOT, 'src', 'matlab', 'analysis')));
addpath(genpath(fullfile(REPO_ROOT, 'src', 'matlab', 'model')));
addpath(genpath(fullfile(REPO_ROOT, 'src', 'matlab', 'shared')));
addpath(genpath(fullfile(REPO_ROOT, 'src', 'matlab', 'patterns', 'make_patterns')));

% Note: src/matlab/protocols/ is intentionally excluded from the path.
% Protocol files are run-scripts, not callable functions.

disp('MATLAB path configured for freely-walking-optomotor.')
