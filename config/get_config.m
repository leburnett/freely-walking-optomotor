function cfg = get_config()
% GET_CONFIG  Return project-wide path configuration.
%
%   cfg = GET_CONFIG() returns a struct containing all project paths.
%   Edit cfg.project_root once when setting up on a new computer.
%   All other paths are derived automatically.
%
%   Fields:
%     cfg.project_root      - Root of the data project folder (oaky-cokey)
%     cfg.repo_root         - Root of this git repository (auto-detected)
%     cfg.data_unprocessed  - 00_unprocessed data directory
%     cfg.data_tracked      - 01_tracked data directory
%     cfg.data_processed    - 02_processed data directory
%     cfg.results           - results directory
%     cfg.figures           - figures directory
%     cfg.patterns          - LED patterns directory (inside repo)
%     cfg.calibration_file  - camera calibration .mat file (inside repo)
%
%   Example:
%     cfg = get_config();
%     data_path = cfg.data_tracked;

    %% === EDIT THIS LINE FOR YOUR COMPUTER ===
    % cfg.project_root = '/Users/burnettl/Documents/Projects/oaky_cokey';
    % Windows example:
    cfg.project_root = 'C:\Users\labadmin\Documents\freely-walking-optomotor';

    %% === DO NOT EDIT BELOW THIS LINE ===

    % Repo root is two levels up from this file's location: config/ -> repo root
    cfg.repo_root = fileparts(fileparts(mfilename('fullpath')));

    % Data directories (derived from project_root)
    cfg.data_unprocessed = fullfile(cfg.project_root, 'DATA', '00_unprocessed');
    cfg.data_tracked     = fullfile(cfg.project_root, 'DATA', '01_tracked');
    cfg.data_processed   = fullfile(cfg.project_root, 'DATA', '02_processed');
    cfg.results          = fullfile(cfg.project_root, 'results');
    cfg.figures          = fullfile(cfg.project_root, 'figures');

    % Repo asset paths (derived from repo_root)
    cfg.patterns = fullfile(cfg.repo_root, 'src', 'patterns', 'Patterns_optomotor');
    cfg.calibration_file = fullfile(cfg.repo_root, 'src', 'tracking', 'calibration.mat');

end
