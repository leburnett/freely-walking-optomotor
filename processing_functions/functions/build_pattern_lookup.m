function PATTERN_LUT = build_pattern_lookup(pattern_dir, save_lut)
% BUILD_PATTERN_LOOKUP Create lookup table for all patterns in a directory
%
% This function scans a directory for pattern files and builds a lookup
% table (LUT) containing metadata for each pattern. The LUT enables fast
% O(1) lookups of pattern properties by pattern ID.
%
% Inputs:
%   pattern_dir - (Optional) String: path to patterns folder
%                 Default: '../patterns/Patterns_optomotor/' relative to this file
%   save_lut    - (Optional) Logical: whether to save PATTERN_LUT.mat
%                 Default: true
%
% Returns:
%   PATTERN_LUT - Struct with fields P01, P02, ..., P63
%                 Each field contains the output of parse_pattern_metadata()
%
% Example:
%   % Build and save lookup table
%   PATTERN_LUT = build_pattern_lookup();
%
%   % Access pattern 9 metadata
%   meta = PATTERN_LUT.P09;
%   disp(meta.spatial_freq_deg);  % 60 degrees
%
%   % Build without saving
%   PATTERN_LUT = build_pattern_lookup('/path/to/patterns', false);
%
% The lookup table is saved to PATTERN_LUT.mat in the pattern directory.
% This file can be loaded directly for faster access:
%   load('PATTERN_LUT.mat', 'PATTERN_LUT');
%
% See also: parse_pattern_metadata, comb_data_across_cohorts_cond_v2

    %% Handle default arguments
    if nargin < 1 || isempty(pattern_dir)
        % Default to the standard pattern directory relative to this file
        this_file = mfilename('fullpath');
        [this_dir, ~, ~] = fileparts(this_file);
        pattern_dir = fullfile(this_dir, '..', '..', 'patterns', 'Patterns_optomotor');
        pattern_dir = char(pattern_dir);  % Ensure it's a char array
    end

    if nargin < 2
        save_lut = true;
    end

    %% Validate directory exists
    if ~isfolder(pattern_dir)
        error('build_pattern_lookup:DirectoryNotFound', ...
            'Pattern directory not found: %s', pattern_dir);
    end

    %% Find all pattern files
    pattern_files = dir(fullfile(pattern_dir, 'Pattern_*.mat'));
    n_patterns = length(pattern_files);

    if n_patterns == 0
        warning('build_pattern_lookup:NoPatternsFound', ...
            'No pattern files found in: %s', pattern_dir);
        PATTERN_LUT = struct();
        return;
    end

    fprintf('Building pattern lookup table from %d files in:\n  %s\n', ...
        n_patterns, pattern_dir);

    %% Initialize lookup table
    PATTERN_LUT = struct();

    %% Process each pattern file
    for i = 1:n_patterns
        fname = pattern_files(i).name;

        try
            meta = parse_pattern_metadata(fname);

            % Store by pattern_id for O(1) lookup
            % Format: P01, P02, ..., P63
            field_name = sprintf('P%02d', meta.pattern_id);
            PATTERN_LUT.(field_name) = meta;

        catch ME
            warning('build_pattern_lookup:ParseError', ...
                'Failed to parse %s: %s', fname, ME.message);
        end
    end

    %% Print summary
    fields = fieldnames(PATTERN_LUT);
    n_parsed = length(fields);

    fprintf('\nPattern Lookup Table Summary:\n');
    fprintf('  Total files found: %d\n', n_patterns);
    fprintf('  Successfully parsed: %d\n', n_parsed);
    fprintf('\n');

    % Count by motion type
    motion_types = {};
    for i = 1:n_parsed
        mt = PATTERN_LUT.(fields{i}).motion_type;
        motion_types{end+1} = mt; %#ok<AGROW>
    end
    unique_types = unique(motion_types);

    fprintf('  Patterns by motion type:\n');
    for i = 1:length(unique_types)
        count = sum(strcmp(motion_types, unique_types{i}));
        fprintf('    %-20s: %d\n', unique_types{i}, count);
    end
    fprintf('\n');

    %% Save lookup table
    if save_lut
        output_file = fullfile(pattern_dir, 'PATTERN_LUT.mat');
        save(output_file, 'PATTERN_LUT');
        fprintf('Saved lookup table to:\n  %s\n', output_file);
    end

end
