function DATA = comb_data_across_cohorts_cond(protocol_dir, pattern_dir, verbose)
% COMB_DATA_ACROSS_COHORTS_COND Combine data across experiments with pattern metadata
%
% This function combines behavioral data across all experiments for a protocol,
% organizing it into a hierarchical structure with enhanced metadata including:
%   - Protocol-level metadata (_metadata field)
%   - Pattern lookup table (_pattern_lut field)
%   - Phase markers for trial segmentation
%   - Linked pattern metadata per condition
%
% Inputs:
%   protocol_dir - String: path to protocol results directory
%                  e.g., '/path/to/results/protocol_27'
%   pattern_dir  - (Optional) String: path to pattern files
%                  Default: '../patterns/Patterns_optomotor/' relative to this file
%   verbose      - (Optional) Logical: print progress messages (default: true)
%
% Returns:
%   DATA - Struct with hierarchical organization:
%       ._metadata          - Protocol-level information
%       ._pattern_lut       - Pattern metadata lookup table
%       .{strain}.{sex}(n)  - Experiment data arrays
%
% Structure of DATA._metadata:
%   .protocol_name      - String: protocol identifier
%   .protocol_version   - String: '2.0' for this version
%   .created_date       - Datetime: when DATA was created
%   .n_strains          - Integer: number of unique strains
%   .n_total_experiments - Integer: total experiments processed
%   .n_total_flies      - Integer: total flies across all experiments
%   .cond_array         - Matrix: condition parameters (from first file)
%   .config             - Struct: protocol configuration
%
% Structure of each experiment DATA.{strain}.{sex}(n):
%   .meta               - Experiment metadata (from LOG.meta)
%   .acclim_off1        - Pre-acclimatization data
%   .acclim_patt        - Pattern acclimatization data
%   .acclim_off2        - Post-acclimatization data
%   .R1_condition_N     - Repetition 1, Condition N data
%   .R2_condition_N     - Repetition 2, Condition N data
%
% Structure of each condition (R1_condition_N):
%   .trial_len          - Trial duration in seconds
%   .interval_dur       - Inter-trial interval in seconds
%   .optomotor_pattern  - Pattern ID used
%   .optomotor_speed    - Stimulus speed parameter
%   .interval_pattern   - Pattern during interval
%   .interval_speed     - Speed during interval
%   .start_flicker_f    - Frame where inter-trial begins (relative to condition start)
%   .phase_markers      - Frame boundaries for baseline/dir1/dir2/interval
%   .pattern_meta       - Linked pattern metadata from _pattern_lut
%   .vel_data           - Velocity (mm/s), size [n_flies x n_frames]
%   .fv_data            - Forward velocity (mm/s)
%   .av_data            - Angular velocity (deg/s)
%   .curv_data          - Curvature (deg/mm)
%   .dist_data          - Distance from center (mm)
%   .dist_trav          - Cumulative distance traveled (mm)
%   .heading_data       - Heading unwrapped (deg)
%   .heading_wrap       - Heading wrapped (deg)
%   .x_data             - X position (mm)
%   .y_data             - Y position (mm)
%   .view_dist          - Viewing distance to wall (mm)
%   .IFD_data           - Inter-fly distance (mm)
%   .IFA_data           - Inter-fly angle (deg)
%
% Example:
%   % Process all data for protocol_27
%   DATA = comb_data_across_cohorts_cond('/path/to/results/protocol_27');
%
%   % Access condition 1 data for a strain
%   cond_data = DATA.jfrc100_es_shibire_kir.F(1).R1_condition_1;
%   av = cond_data.av_data;  % Angular velocity
%   markers = cond_data.phase_markers;  % Phase boundaries
%
%   % Extract direction 1 data
%   dir1_av = av(:, markers.dir1_start:markers.dir1_end);
%
% See also: parse_pattern_metadata, build_pattern_lookup, discover_strains,
%           get_protocol_config

    %% Handle arguments
    if nargin < 2 || isempty(pattern_dir)
        this_file = mfilename('fullpath');
        [this_dir, ~, ~] = fileparts(this_file);
        pattern_dir = fullfile(this_dir, '..', '..', 'patterns', 'Patterns_optomotor');
    end

    if nargin < 3
        verbose = true;
    end

    %% Validate directories
    if ~isfolder(protocol_dir)
        error('comb_data_across_cohorts_cond:DirectoryNotFound', ...
            'Protocol directory not found: %s', protocol_dir);
    end

    %% Extract protocol name
    [~, protocol_name] = fileparts(protocol_dir);

    %% Load or build pattern lookup table
    if isfolder(pattern_dir)
        lut_file = fullfile(pattern_dir, 'PATTERN_LUT.mat');
        if exist(lut_file, 'file')
            if verbose
                fprintf('Loading pattern lookup table from: %s\n', lut_file);
            end
            load(lut_file, 'PATTERN_LUT');
        else
            if verbose
                fprintf('Building pattern lookup table...\n');
            end
            PATTERN_LUT = build_pattern_lookup(pattern_dir, true);
        end
    else
        if verbose
            warning('Pattern directory not found, pattern metadata will not be linked.');
        end
        PATTERN_LUT = struct();
    end

    %% Get protocol configuration
    protocol_config = get_protocol_config(protocol_name);

    %% Find all processed data files
    filelist = dir(fullfile(protocol_dir, '**/*.mat'));
    % Remove DATA aggregate files
    idxToRemove = contains({filelist.name}, 'DATA');
    filelist(idxToRemove) = [];
    n_files = length(filelist);

    if n_files == 0
        error('comb_data_across_cohorts_cond:NoDataFiles', ...
            'No data files found in: %s', protocol_dir);
    end

    if verbose
        fprintf('\nProcessing %d data files from %s\n', n_files, protocol_name);
        fprintf('================================================================================\n');
    end

    %% Initialize DATA struct with metadata
    DATA = struct();
    DATA._metadata.protocol_name = protocol_name;
    DATA._metadata.protocol_version = '2.0';
    DATA._metadata.created_date = datetime('now');
    DATA._metadata.n_strains = 0;
    DATA._metadata.n_total_experiments = n_files;
    DATA._metadata.n_total_flies = 0;
    DATA._metadata.cond_array = [];
    DATA._metadata.config = protocol_config;
    DATA._pattern_lut = PATTERN_LUT;

    %% Behavioral data fields to extract
    data_fields = {'vel_data', 'fv_data', 'av_data', 'curv_data', 'dist_data', ...
                   'dist_trav', 'heading_data', 'heading_wrap', 'x_data', 'y_data', ...
                   'view_dist', 'IFD_data', 'IFA_data'};

    %% Process each file
    for idx = 1:n_files

        fname = filelist(idx).name;
        f_folder = filelist(idx).folder;

        if verbose
            fprintf('  [%d/%d] %s\n', idx, n_files, fname);
        end

        % Load experiment data
        try
            loaded = load(fullfile(f_folder, fname), 'comb_data', 'LOG', 'n_fly_data');
            comb_data = loaded.comb_data;
            LOG = loaded.LOG;
            n_fly_data = loaded.n_fly_data;
        catch ME
            warning('Failed to load %s: %s', fname, ME.message);
            continue;
        end

        % Get strain and sex
        strain = LOG.meta.fly_strain;
        strain = check_strain_typos(strain);
        strain = strrep(strain, '-', '_');
        sex = LOG.meta.fly_sex;

        % Determine experiment index within strain/sex
        if isfield(DATA, strain) && isfield(DATA.(strain), sex)
            sz = length(DATA.(strain).(sex)) + 1;
        else
            sz = 1;
        end

        %% Store experiment metadata
        DATA.(strain).(sex)(sz).meta = LOG.meta;
        DATA.(strain).(sex)(sz).meta.n_flies_arena = n_fly_data(1);
        DATA.(strain).(sex)(sz).meta.n_flies = n_fly_data(2);
        DATA.(strain).(sex)(sz).meta.n_flies_rm = n_fly_data(3);
        DATA.(strain).(sex)(sz).meta.source_file = fname;

        DATA._metadata.n_total_flies = DATA._metadata.n_total_flies + n_fly_data(2);

        % Store cond_array from first file
        if isempty(DATA._metadata.cond_array) && isfield(LOG.meta, 'cond_array')
            DATA._metadata.cond_array = LOG.meta.cond_array;
        end

        %% Process acclimatization periods
        DATA.(strain).(sex)(sz) = extract_acclim_data(...
            DATA.(strain).(sex)(sz), LOG, comb_data, 'acclim_off1', data_fields);
        DATA.(strain).(sex)(sz) = extract_acclim_data(...
            DATA.(strain).(sex)(sz), LOG, comb_data, 'acclim_patt', data_fields);
        DATA.(strain).(sex)(sz) = extract_acclim_data(...
            DATA.(strain).(sex)(sz), LOG, comb_data, 'acclim_off2', data_fields);

        %% Process conditions
        fields = fieldnames(LOG);
        logfields = fields(startsWith(fields, 'log_'));
        n_cond = length(logfields);

        for log_n = 1:n_cond

            Log = LOG.(logfields{log_n});

            % Determine repetition and condition
            if log_n <= n_cond/2
                rep_str = sprintf('R1_condition_%d', Log.which_condition);
            else
                rep_str = sprintf('R2_condition_%d', Log.which_condition);
            end

            % Calculate frame boundaries with baseline
            if LOG.acclim_off1.stop_t(end) < 3 && log_n == 1
                framesb4 = 0;
            else
                framesb4 = protocol_config.baseline_frames;  % 300 frames = 10s
            end

            start_f = Log.start_f(1) - framesb4;
            stop_f = Log.stop_f(end);

            %% Store condition metadata
            DATA.(strain).(sex)(sz).(rep_str).trial_len = Log.trial_len;
            if isfield(Log, 'interval_dur')
                DATA.(strain).(sex)(sz).(rep_str).interval_dur = Log.interval_dur;
            end
            DATA.(strain).(sex)(sz).(rep_str).optomotor_pattern = Log.optomotor_pattern;
            DATA.(strain).(sex)(sz).(rep_str).optomotor_speed = Log.optomotor_speed;
            DATA.(strain).(sex)(sz).(rep_str).interval_pattern = Log.interval_pattern;
            DATA.(strain).(sex)(sz).(rep_str).interval_speed = Log.interval_speed;
            DATA.(strain).(sex)(sz).(rep_str).start_flicker_f = Log.start_f(end) - start_f;

            %% Create phase markers
            phase_markers = struct();
            phase_markers.baseline_start = 1;
            phase_markers.baseline_end = framesb4;
            phase_markers.dir1_start = framesb4 + 1;
            phase_markers.dir1_end = Log.start_f(2) - start_f;
            phase_markers.dir2_start = Log.start_f(2) - start_f + 1;
            if length(Log.start_f) >= 3
                phase_markers.dir2_end = Log.start_f(3) - start_f;
                phase_markers.interval_start = Log.start_f(3) - start_f + 1;
            else
                phase_markers.dir2_end = stop_f - start_f + 1;
                phase_markers.interval_start = stop_f - start_f + 1;
            end
            phase_markers.interval_end = stop_f - start_f + 1;

            DATA.(strain).(sex)(sz).(rep_str).phase_markers = phase_markers;

            %% Link pattern metadata
            patt_id = Log.optomotor_pattern;
            patt_field = sprintf('P%02d', patt_id);
            if isfield(PATTERN_LUT, patt_field)
                DATA.(strain).(sex)(sz).(rep_str).pattern_meta = PATTERN_LUT.(patt_field);
            else
                DATA.(strain).(sex)(sz).(rep_str).pattern_meta = [];
            end

            %% Extract behavioral data
            for f = 1:length(data_fields)
                field = data_fields{f};
                if isfield(comb_data, field)
                    DATA.(strain).(sex)(sz).(rep_str).(field) = ...
                        comb_data.(field)(:, start_f:stop_f);
                end
            end
        end
    end

    %% Count unique strains
    all_fields = fieldnames(DATA);
    strain_fields = all_fields(~startsWith(all_fields, '_'));
    DATA._metadata.n_strains = length(strain_fields);

    %% Print summary
    if verbose
        fprintf('================================================================================\n');
        fprintf('  Processing complete!\n');
        fprintf('  Strains: %d\n', DATA._metadata.n_strains);
        fprintf('  Total experiments: %d\n', DATA._metadata.n_total_experiments);
        fprintf('  Total flies: %d\n', DATA._metadata.n_total_flies);
        fprintf('================================================================================\n');
    end

end


%% Helper function: Extract acclimatization period data
function exp_data = extract_acclim_data(exp_data, LOG, comb_data, period_name, data_fields)
% Extract behavioral data for an acclimatization period

    Log = LOG.(period_name);

    % Determine frame boundaries based on period type
    if strcmp(period_name, 'acclim_off1')
        start_f = max(Log.start_f(1), 1);
        if Log.stop_t(end) < 3
            stop_f = 600;  % Short acclim period
        else
            stop_f = Log.stop_f(end);
        end
    elseif strcmp(period_name, 'acclim_off2')
        start_f = Log.start_f(1);
        stop_f = size(comb_data.vel_data, 2);  % End of recording
    else  % acclim_patt
        start_f = Log.start_f(1);
        stop_f = Log.stop_f(end);
    end

    % Extract each data field
    for f = 1:length(data_fields)
        field = data_fields{f};
        if isfield(comb_data, field)
            exp_data.(period_name).(field) = comb_data.(field)(:, start_f:stop_f);
        end
    end

end
