function strain_info = discover_strains(protocol_dir, verbose)
% DISCOVER_STRAINS Automatically discover strains and experiments in a protocol directory
%
% This utility function scans a protocol results directory and returns
% information about all strains, sexes, and experiments found. Useful for:
%   - Understanding dataset composition before processing
%   - Validating data completeness
%   - Generating reports
%
% Inputs:
%   protocol_dir - String: path to protocol results directory
%                  e.g., '/path/to/results/protocol_27'
%   verbose      - (Optional) Logical: print summary to console (default: true)
%
% Returns:
%   strain_info - Struct with strain names as fields. Each strain contains:
%       .original_name  - String: original folder name
%       .path           - String: full path to strain folder
%       .F / .M         - Struct for each sex with:
%           .path           - String: full path to sex folder
%           .n_experiments  - Integer: number of data files
%           .data_files     - Cell array: list of data filenames
%           .total_flies    - Integer: estimated total flies (if parseable)
%
% Example:
%   % Discover strains in protocol_27
%   info = discover_strains('/path/to/results/protocol_27');
%
%   % List all strains
%   strains = fieldnames(info);
%   fprintf('Found %d strains\n', length(strains));
%
%   % Get experiment count for a specific strain/sex
%   n_exp = info.jfrc100_es_shibire_kir.F.n_experiments;
%
%   % Suppress console output
%   info = discover_strains('/path/to/results/protocol_27', false);
%
% Notes:
%   - Strain names are sanitized (hyphens replaced with underscores)
%   - Strain names starting with numbers get 'ss' prefix (for valid MATLAB field names)
%   - Only folders containing '*_data.mat' files are counted
%
% See also: comb_data_across_cohorts_cond_v2, get_protocol_config

    %% Handle arguments
    if nargin < 2
        verbose = true;
    end

    %% Validate directory
    if ~isfolder(protocol_dir)
        error('discover_strains:DirectoryNotFound', ...
            'Protocol directory not found: %s', protocol_dir);
    end

    %% Initialize output
    strain_info = struct();

    %% Get protocol name for display
    [~, protocol_name] = fileparts(protocol_dir);

    %% Get all subdirectories (potential strains)
    items = dir(protocol_dir);
    dirs = items([items.isdir]);
    % Filter out system directories
    strain_dirs = dirs(~ismember({dirs.name}, {'.', '..', '.DS_Store'}));

    if isempty(strain_dirs)
        if verbose
            fprintf('\nNo strain directories found in: %s\n', protocol_dir);
        end
        return;
    end

    %% Process each potential strain directory
    total_experiments = 0;
    total_strains = 0;

    for i = 1:length(strain_dirs)
        strain_name = strain_dirs(i).name;
        strain_path = fullfile(protocol_dir, strain_name);

        % Standardize strain name for MATLAB field
        clean_strain = strrep(strain_name, '-', '_');
        % Handle strain names starting with numbers
        if isstrprop(clean_strain(1), 'digit')
            clean_strain = strcat('ss', clean_strain);
        end

        % Initialize strain entry
        strain_info.(clean_strain).original_name = strain_name;
        strain_info.(clean_strain).path = strain_path;

        % Find sex directories (F, M, or other)
        sex_items = dir(strain_path);
        sex_dirs = sex_items([sex_items.isdir]);
        sex_dirs = sex_dirs(~ismember({sex_dirs.name}, {'.', '..', '.DS_Store'}));

        has_data = false;

        for j = 1:length(sex_dirs)
            sex = sex_dirs(j).name;
            sex_path = fullfile(strain_path, sex);

            % Count data files
            data_files = dir(fullfile(sex_path, '*_data.mat'));
            % Exclude any DATA aggregate files
            data_files = data_files(~contains({data_files.name}, 'DATA'));

            if ~isempty(data_files)
                has_data = true;

                strain_info.(clean_strain).(sex).path = sex_path;
                strain_info.(clean_strain).(sex).n_experiments = length(data_files);
                strain_info.(clean_strain).(sex).data_files = {data_files.name};

                total_experiments = total_experiments + length(data_files);

                % Try to estimate total flies from filenames or by loading
                % (This is optional - just provides a quick estimate)
                strain_info.(clean_strain).(sex).total_flies = NaN;
            end
        end

        if has_data
            total_strains = total_strains + 1;
        else
            % Remove strain entry if no data found
            strain_info = rmfield(strain_info, clean_strain);
        end
    end

    %% Print summary
    if verbose
        fprintf('\n');
        fprintf('================================================================================\n');
        fprintf('  STRAIN DISCOVERY SUMMARY\n');
        fprintf('================================================================================\n');
        fprintf('  Protocol: %s\n', protocol_name);
        fprintf('  Path: %s\n', protocol_dir);
        fprintf('--------------------------------------------------------------------------------\n');
        fprintf('  Total strains found: %d\n', total_strains);
        fprintf('  Total experiments: %d\n', total_experiments);
        fprintf('================================================================================\n\n');

        if total_strains > 0
            strains = fieldnames(strain_info);
            for i = 1:length(strains)
                strain = strains{i};
                fprintf('  %s:\n', strain);

                % Check for female data
                if isfield(strain_info.(strain), 'F')
                    fprintf('    F: %3d experiments\n', ...
                        strain_info.(strain).F.n_experiments);
                end

                % Check for male data
                if isfield(strain_info.(strain), 'M')
                    fprintf('    M: %3d experiments\n', ...
                        strain_info.(strain).M.n_experiments);
                end

                % Check for other sexes (rare but possible)
                other_fields = fieldnames(strain_info.(strain));
                other_fields = other_fields(~ismember(other_fields, ...
                    {'original_name', 'path', 'F', 'M'}));
                for k = 1:length(other_fields)
                    field = other_fields{k};
                    if isfield(strain_info.(strain).(field), 'n_experiments')
                        fprintf('    %s: %3d experiments\n', field, ...
                            strain_info.(strain).(field).n_experiments);
                    end
                end

                fprintf('\n');
            end
        end
    end

end
