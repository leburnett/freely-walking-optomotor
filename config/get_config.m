function cfg = get_config()
% GET_CONFIG  Return project-wide path configuration.
%
%   cfg = GET_CONFIG() returns a struct containing all project paths.
%   Edit cfg.project_root once when setting up on a new computer.
%   All other paths are derived automatically.
%
%   This config is used on three machines:
%     1. Acquisition rig (Windows) — uses cfg.rig_data_folder, cfg.bias_config
%     2. Processing machine (Windows) — uses cfg.project_root + derived paths
%     3. Analysis computer (Mac/any) — uses cfg.project_root + derived paths
%
%   Only cfg.project_root needs to change between machines (2) and (3).
%   The rig paths are only used on the acquisition rig and can be ignored
%   on processing/analysis machines.
%
%   Fields — Local data (derived from project_root):
%     cfg.project_root      - Root of the local data folder (EDIT THIS)
%     cfg.data_unprocessed  - DATA/00_unprocessed/
%     cfg.data_tracked      - DATA/01_tracked/
%     cfg.data_processed    - DATA/02_processed/
%     cfg.results           - results/
%     cfg.figures           - figures/
%
%   Fields — Repository assets (auto-detected):
%     cfg.repo_root         - Root of this git repository
%     cfg.patterns          - LED pattern .mat files
%     cfg.calibration_file  - Camera calibration .mat
%
%   Fields — Acquisition rig only:
%     cfg.rig_data_folder   - Where BIAS saves raw video on the rig
%     cfg.bias_config       - BIAS camera config file on the rig
%
%   Fields — Network drive:
%     cfg.group_drive       - Network/shared drive data root (SMB)
%
%   See also: config/config.py (Python equivalent),
%             setup_path.m (adds src/ to MATLAB path)
%
%   Example:
%     cfg = get_config();
%     data_path = cfg.data_tracked;

    %% === EDIT THIS LINE FOR YOUR COMPUTER ===
    cfg.project_root = '/Users/burnettl/Documents/Projects/oaky_cokey';
    % Windows example:
    % cfg.project_root = 'C:\Users\labadmin\Documents\freely-walking-optomotor';

    %% ====================================================================
    %  ACQUISITION RIG PATHS (only used on the rig computer)
    %  ====================================================================
    %  These paths are only relevant when running protocols on the
    %  acquisition rig. They can be ignored on processing/analysis machines.

    % Where BIAS saves raw video and LOG files during experiments
    cfg.rig_data_folder = 'C:\MatlabRoot\FreeWalkOptomotor\data';

    % BIAS camera configuration file
    cfg.bias_config = 'C:\MatlabRoot\FreeWalkOptomotor\bias_config_ufmf.json';

    %% ====================================================================
    %  NETWORK DRIVE (shared storage)
    %  ====================================================================
    %  The group network drive where data is archived. Used by automation
    %  scripts on the processing machine. The Python config (config/config.py)
    %  has the equivalent Windows UNC paths (\\server\share format).

    cfg.group_drive = 'smb://prfs.hhmi.org/reiserlab/oaky-cokey/data/';

    %% ====================================================================
    %  DERIVED PATHS — DO NOT EDIT BELOW THIS LINE
    %  ====================================================================

    % Repo root is one level up from this file: config/ -> repo root
    cfg.repo_root = fileparts(fileparts(mfilename('fullpath')));

    % --- Local data directories (derived from project_root) ---
    %
    %  project_root/
    %    DATA/
    %      00_unprocessed/   <- raw data staged for tracking
    %      01_tracked/       <- tracked data awaiting processing
    %      02_processed/     <- fully processed data archive
    %    results/            <- processing output (.mat result files)
    %    figures/            <- generated figures
    cfg.data_unprocessed = fullfile(cfg.project_root, 'DATA', '00_unprocessed');
    cfg.data_tracked     = fullfile(cfg.project_root, 'DATA', '01_tracked');
    cfg.data_processed   = fullfile(cfg.project_root, 'DATA', '02_processed');
    cfg.results          = fullfile(cfg.project_root, 'results');
    cfg.figures          = fullfile(cfg.project_root, 'figures');

    % --- Repo asset paths (derived from repo_root) ---
    cfg.patterns = fullfile(cfg.repo_root, 'src', 'patterns', 'Patterns_optomotor');
    cfg.calibration_file = fullfile(cfg.repo_root, 'src', 'tracking', 'calibration.mat');

end