function meta = parse_pattern_metadata(pattern_filename)
% PARSE_PATTERN_METADATA Extract stimulus properties from pattern filename
%
% This function parses the standardized pattern filenames used in the
% freely-walking optomotor experiments to extract stimulus properties
% like spatial frequency, bar width, motion type, etc.
%
% Inputs:
%   pattern_filename - String: filename like 'Pattern_09_optomotor_16pixel_binary.mat'
%                      Can be just the filename or a full path.
%
% Returns:
%   meta - struct with fields:
%       .pattern_id      - Integer: pattern number (1-63)
%       .pattern_name    - String: original filename
%       .motion_type     - String: 'optomotor'|'flicker'|'curtain'|'reverse_phi'|
%                                  'field_of_expansion'|'bar_fixation'|'background'
%       .spatial_freq_deg - Float: degrees per cycle (NaN if not applicable)
%       .bar_width_px    - Integer: pixels (ON portion)
%       .bar_width_deg   - Float: degrees (ON portion)
%       .duty_cycle      - Float: ON/(ON+OFF) ratio (0.5 for standard gratings)
%       .step_size_px    - Integer: pixels per frame update
%       .step_size_deg   - Float: degrees per frame update
%       .gs_val          - Integer: grayscale value (1=binary, 3=4-level, etc.)
%       .contrast        - Float: Michelson contrast estimate
%       .shift_offset    - Float: center of rotation offset (for shifted patterns)
%       .polarity        - String: 'ON'|'OFF'|'both'
%       .n_frames        - Integer: total frames in pattern (if extractable)
%
% Display configuration constants (G3 arena):
%   - 24 panels around the arena, 8 pixels per panel = 192 total pixels
%   - 360 degrees / 192 pixels = 1.875 degrees per pixel
%
% Example:
%   meta = parse_pattern_metadata('Pattern_09_optomotor_16pixel_binary.mat');
%   % Returns: motion_type='optomotor', bar_width_px=16, spatial_freq_deg=60
%
%   meta = parse_pattern_metadata('Pattern_17_optomotor_skinny_2ON_14OFF_binary.mat');
%   % Returns: motion_type='optomotor', bar_width_px=2, duty_cycle=0.125
%
% See also: build_pattern_lookup

    % Display configuration constants
    PIXELS_PER_PANEL = 8;
    PANELS_AROUND = 24;
    TOTAL_PIXELS = PIXELS_PER_PANEL * PANELS_AROUND;  % 192
    DEGREES_PER_PIXEL = 360 / TOTAL_PIXELS;           % 1.875 deg/px

    % Initialize output struct with default values
    meta = struct(...
        'pattern_id', NaN, ...
        'pattern_name', '', ...
        'motion_type', 'unknown', ...
        'spatial_freq_deg', NaN, ...
        'bar_width_px', NaN, ...
        'bar_width_deg', NaN, ...
        'duty_cycle', NaN, ...
        'step_size_px', 1, ...
        'step_size_deg', DEGREES_PER_PIXEL, ...
        'gs_val', 1, ...
        'contrast', 1.0, ...
        'shift_offset', NaN, ...
        'polarity', 'both', ...
        'n_frames', NaN ...
    );

    % Handle full paths - extract just the filename
    [~, name, ext] = fileparts(pattern_filename);
    if isempty(ext)
        filename = name;
    else
        filename = strcat(name, ext);
    end
    meta.pattern_name = filename;

    % Extract pattern ID from filename
    tokens = regexp(filename, 'Pattern_(\d+)_(.+)\.mat', 'tokens');
    if isempty(tokens)
        % Try without .mat extension
        tokens = regexp(filename, 'Pattern_(\d+)_(.+)', 'tokens');
        if isempty(tokens)
            warning('parse_pattern_metadata:InvalidFormat', ...
                'Invalid pattern filename format: %s', filename);
            return;
        end
    end

    meta.pattern_id = str2double(tokens{1}{1});
    description = lower(tokens{1}{2});  % Convert to lowercase for easier matching

    %% Classify motion type
    if contains(description, 'optomotor') || contains(description, 'grating')
        meta.motion_type = 'optomotor';
    elseif contains(description, 'flicker')
        meta.motion_type = 'flicker';
    elseif contains(description, 'curtain')
        meta.motion_type = 'curtain';
    elseif contains(description, 'revphi') || contains(description, 'reverse')
        meta.motion_type = 'reverse_phi';
    elseif contains(description, 'foe') || contains(description, 'expansion')
        meta.motion_type = 'field_of_expansion';
    elseif contains(description, 'bar_fixation') || contains(description, 'fixation')
        meta.motion_type = 'bar_fixation';
    elseif contains(description, 'bkg') || contains(description, 'background')
        meta.motion_type = 'background';
    else
        meta.motion_type = 'unknown';
    end

    %% Extract bar width (pixels)
    % Match patterns like "16pixel", "16px", "8pixel"
    px_match = regexp(description, '(\d+)pixel|(\d+)px', 'tokens');
    if ~isempty(px_match)
        % Find the first non-empty match
        for i = 1:length(px_match)
            vals = px_match{i};
            for j = 1:length(vals)
                if ~isempty(vals{j})
                    meta.bar_width_px = str2double(vals{j});
                    meta.bar_width_deg = meta.bar_width_px * DEGREES_PER_PIXEL;
                    break;
                end
            end
            if ~isnan(meta.bar_width_px)
                break;
            end
        end
    end

    %% Extract ON/OFF ratio for skinny/wide bars
    % Match patterns like "2ON_14OFF", "12ON_4OFF", "2OFF_14ON"
    ratio_match = regexp(description, '(\d+)on_(\d+)off', 'tokens');
    if ~isempty(ratio_match)
        on_width = str2double(ratio_match{1}{1});
        off_width = str2double(ratio_match{1}{2});
        meta.bar_width_px = on_width;
        meta.bar_width_deg = on_width * DEGREES_PER_PIXEL;
        meta.duty_cycle = on_width / (on_width + off_width);
        meta.spatial_freq_deg = (on_width + off_width) * DEGREES_PER_PIXEL;
    else
        % Check for inverted pattern (OFF_ON)
        ratio_match = regexp(description, '(\d+)off_(\d+)on', 'tokens');
        if ~isempty(ratio_match)
            off_width = str2double(ratio_match{1}{1});
            on_width = str2double(ratio_match{1}{2});
            meta.bar_width_px = on_width;
            meta.bar_width_deg = on_width * DEGREES_PER_PIXEL;
            meta.duty_cycle = on_width / (on_width + off_width);
            meta.spatial_freq_deg = (on_width + off_width) * DEGREES_PER_PIXEL;
        elseif ~isnan(meta.bar_width_px)
            % Standard 50% duty cycle grating
            meta.duty_cycle = 0.5;
            meta.spatial_freq_deg = meta.bar_width_px * 2 * DEGREES_PER_PIXEL;
        end
    end

    %% Extract step size
    % Match patterns like "2pxsteps", "2px_step", "1-875step"
    step_match = regexp(description, '(\d+)pxstep|(\d+)px_step', 'tokens');
    if ~isempty(step_match)
        for i = 1:length(step_match)
            vals = step_match{i};
            for j = 1:length(vals)
                if ~isempty(vals{j})
                    meta.step_size_px = str2double(vals{j});
                    meta.step_size_deg = meta.step_size_px * DEGREES_PER_PIXEL;
                    break;
                end
            end
            if meta.step_size_px > 1
                break;
            end
        end
    else
        % Check for decimal step format like "1-875step" = 1.875
        step_match = regexp(description, '(\d+)-(\d+)step', 'tokens');
        if ~isempty(step_match)
            whole = str2double(step_match{1}{1});
            decimal = str2double(step_match{1}{2});
            % Reconstruct decimal (e.g., 1-875 -> 1.875)
            meta.step_size_deg = whole + decimal / (10^length(step_match{1}{2}));
            meta.step_size_px = meta.step_size_deg / DEGREES_PER_PIXEL;
        end
    end

    %% Extract grayscale value
    % Match patterns like "gsval3", "gs_val1"
    gs_match = regexp(description, 'gsval(\d+)|gs_val(\d+)', 'tokens');
    if ~isempty(gs_match)
        for i = 1:length(gs_match)
            vals = gs_match{i};
            for j = 1:length(vals)
                if ~isempty(vals{j})
                    meta.gs_val = str2double(vals{j});
                    break;
                end
            end
            if meta.gs_val > 1
                break;
            end
        end
    elseif contains(description, 'binary')
        meta.gs_val = 1;
    end

    %% Extract shift offset (for shifted center of rotation patterns)
    % Match patterns like "0-8shift" = 0.8 shift
    shift_match = regexp(description, '([-]?\d+)-?(\d*)shift', 'tokens');
    if ~isempty(shift_match)
        whole = str2double(shift_match{1}{1});
        if ~isempty(shift_match{1}{2})
            decimal = str2double(shift_match{1}{2});
            meta.shift_offset = whole + decimal / (10^length(shift_match{1}{2}));
        else
            meta.shift_offset = whole;
        end
    end

    %% Extract polarity for curtains/bars
    if contains(description, '_on_') || endsWith(description, '_on') || ...
       contains(description, 'on_curtain') || contains(description, 'on_bar')
        meta.polarity = 'ON';
    elseif contains(description, '_off_') || endsWith(description, '_off') || ...
           contains(description, 'off_curtain') || contains(description, 'off_bar')
        meta.polarity = 'OFF';
    end

    %% Extract number of frames
    % Match patterns like "32frames", "2frames"
    frames_match = regexp(description, '(\d+)frames', 'tokens');
    if ~isempty(frames_match)
        meta.n_frames = str2double(frames_match{1}{1});
    end

    %% Calculate contrast based on grayscale value
    if meta.gs_val == 1
        meta.contrast = 1.0;  % Binary = maximum contrast
    else
        % Grayscale patterns: estimate based on bit depth
        % Higher gs_val = more levels = potentially lower contrast
        max_levels = 2^meta.gs_val;
        meta.contrast = (max_levels - 1) / max_levels;
    end

    %% Extract angular spacing for FoE patterns
    % Match patterns like "30deg", "15deg", "60deg"
    if strcmp(meta.motion_type, 'field_of_expansion')
        deg_match = regexp(description, '(\d+)deg', 'tokens');
        if ~isempty(deg_match)
            meta.spatial_freq_deg = str2double(deg_match{1}{1});
        end
    end

end
