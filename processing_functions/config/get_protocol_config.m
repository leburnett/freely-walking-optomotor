function config = get_protocol_config(protocol_name)
% GET_PROTOCOL_CONFIG Return configuration for a specific experimental protocol
%
% This function centralizes protocol-specific parameters, making it easy to
% add new protocols without modifying core processing code. Each protocol
% defines its conditions, timing, and stimulus parameters.
%
% Inputs:
%   protocol_name - String: protocol identifier (e.g., 'protocol_27', 'protocol_31')
%
% Returns:
%   config - Struct with fields:
%       .protocol_name      - String: protocol identifier
%       .description        - String: human-readable description
%       .fps                - Integer: video frame rate (30)
%       .n_conditions       - Integer: number of unique conditions
%       .n_reps             - Integer: repetitions per condition
%       .trial_duration_s   - Float: stimulus duration in seconds
%       .interval_duration_s - Float: inter-trial interval in seconds
%       .baseline_duration_s - Float: pre-stimulus baseline (default 10s)
%       .baseline_frames    - Integer: baseline in frames
%       .acclim_start_s     - Float: initial acclimatization duration
%       .acclim_end_s       - Float: final acclimatization duration
%       .flash_duration_s   - Float: flash stimulus duration
%       .uses_cond_array    - Logical: whether LOG.meta.cond_array is used
%       .condition_labels   - Cell array: human-readable condition names
%       .stimulus_speeds    - Array: stimulus speeds (protocol-specific)
%
% Example:
%   config = get_protocol_config('protocol_27');
%   fprintf('Protocol has %d conditions\n', config.n_conditions);
%   fprintf('Condition 1: %s\n', config.condition_labels{1});
%
% Adding a new protocol:
%   1. Add a new 'case' block in the switch statement below
%   2. Define all required fields (see protocol_27 as template)
%   3. The new protocol will automatically work with comb_data_across_cohorts_cond_v2
%
% See also: comb_data_across_cohorts_cond_v2, discover_strains

    %% Initialize common defaults
    config = struct();
    config.protocol_name = protocol_name;
    config.fps = 30;  % Video frame rate (constant across protocols)
    config.baseline_duration_s = 10;  % Pre-stimulus baseline
    config.baseline_frames = config.baseline_duration_s * config.fps;  % 300 frames

    %% Protocol-specific configuration
    switch protocol_name

        case 'protocol_10'
            config.description = 'Speed and spatial frequency testing';
            config.n_conditions = 12;
            config.n_reps = 2;
            config.trial_duration_s = 15;
            config.interval_duration_s = 20;
            config.uses_cond_array = false;  % Hardcoded in comb_data_one_cohort_cond
            config.condition_labels = {
                '60deg slow 2s'
                '60deg fast 15s'
                '60deg slow 15s'
                '60deg fast 2s'
                '30deg slow 2s'
                '30deg fast 15s'
                '30deg slow 15s'
                '30deg fast 2s'
                '15deg slow 2s'
                '15deg fast 15s'
                '15deg slow 15s'
                '15deg fast 2s'
            };

        case 'protocol_15'
            config.description = 'Duty cycle comparison (ON/OFF ratios)';
            config.n_conditions = 3;
            config.n_reps = 2;
            config.trial_duration_s = 15;
            config.interval_duration_s = 20;
            config.uses_cond_array = false;
            config.condition_labels = {
                '4ON_4OFF (50% duty)'
                '4ON_12OFF (25% duty)'
                '12ON_4OFF (75% duty)'
            };

        case 'protocol_18'
            config.description = 'Gratings vs curtains comparison';
            config.n_conditions = 6;
            config.n_reps = 2;
            config.trial_duration_s = 15;
            config.interval_duration_s = 20;
            config.uses_cond_array = false;
            config.condition_labels = {
                'Gratings 60deg fast'
                'Gratings 60deg slow'
                'ON curtain slow'
                'ON curtain fast'
                'OFF curtain slow'
                'OFF curtain fast'
            };

        case 'protocol_19'
            config.description = 'Extended gratings and curtains with thin bars';
            config.n_conditions = 12;
            config.n_reps = 2;
            config.trial_duration_s = 15;
            config.interval_duration_s = 20;
            config.uses_cond_array = false;
            config.condition_labels = {
                '60deg grating slow'
                '60deg grating fast'
                'ON curtain slow'
                'ON curtain fast'
                'OFF curtain slow'
                'OFF curtain fast'
                '2ON_14OFF grating slow'
                '2ON_14OFF grating fast'
                '2OFF_14ON grating slow'
                '2OFF_14ON grating fast'
                '15deg grating slow'
                '15deg grating fast'
            };

        case 'protocol_21'
            config.description = 'Double-step gratings with curtains and flicker';
            config.n_conditions = 10;
            config.n_reps = 2;
            config.trial_duration_s = 15;
            config.interval_duration_s = 20;
            config.uses_cond_array = false;
            config.condition_labels = {
                '60deg 2px-step slow'
                '60deg 2px-step fast'
                '30deg 2px-step slow'
                '30deg 2px-step fast'
                'ON curtain slow'
                'ON curtain fast'
                'OFF curtain slow'
                'OFF curtain fast'
                'Flicker 60deg slow'
                'Flicker 60deg fast'
            };

        case 'protocol_22'
            config.description = 'Bar fixation, reverse phi, and field of expansion';
            config.n_conditions = 7;
            config.n_reps = 2;
            config.trial_duration_s = 15;
            config.interval_duration_s = 20;
            config.uses_cond_array = false;
            config.condition_labels = {
                'Bar fixation'
                'Reverse phi 1px step'
                'Reverse phi 4px step'
                'Reverse phi 8px step'
                'FoE 30deg'
                'FoE 15deg'
                'FoE 60deg'
            };

        case 'protocol_23'
            config.description = 'Extended bar fixation (60s trials)';
            config.n_conditions = 2;
            config.n_reps = 2;
            config.trial_duration_s = 60;
            config.interval_duration_s = 7;
            config.uses_cond_array = false;
            config.condition_labels = {
                'ON bar fixation 60s'
                'OFF bar fixation 60s'
            };

        case {'protocol_24', 'protocol_27'}
            % Screen protocol 2 - uses built-in cond_array
            config.description = 'Standard optomotor screen with multiple stimulus types';
            config.n_conditions = 12;
            config.n_reps = 2;
            config.trial_duration_s = 15;
            config.interval_duration_s = 20;
            config.acclim_start_s = 300;
            config.acclim_end_s = 30;
            config.flash_duration_s = 5;
            config.uses_cond_array = true;  % Uses LOG.meta.cond_array

            % Condition labels (order matches cond_array)
            config.condition_labels = {
                '60deg gratings 4Hz'
                '60deg gratings 8Hz'
                '2ON_14OFF bars 4Hz'
                '2ON_14OFF bars 8Hz'
                'ON curtains 4Hz'
                'ON curtains 8Hz'
                'OFF curtains 4Hz'
                'OFF curtains 8Hz'
                'Reverse phi slow'
                'Reverse phi fast'
                'Flicker 60deg'
                'Static pattern'
            };

        case 'protocol_30'
            config.description = 'Contrast sensitivity testing';
            config.n_conditions = 8;
            config.n_reps = 2;
            config.trial_duration_s = 15;
            config.interval_duration_s = 20;
            config.uses_cond_array = true;
            config.condition_labels = {
                'High contrast fast'
                'High contrast slow'
                'Medium contrast fast'
                'Medium contrast slow'
                'Low contrast fast'
                'Low contrast slow'
                'Very low contrast fast'
                'Very low contrast slow'
            };

        case 'protocol_31'
            config.description = 'Speed tuning with multiple velocities';
            config.n_conditions = 10;
            config.n_reps = 2;
            config.trial_duration_s = 20;
            config.interval_duration_s = 20;
            config.uses_cond_array = true;

            config.condition_labels = {
                '60deg 60dps'
                '60deg 120dps'
                '60deg 240dps'
                '60deg 480dps'
                '60deg flicker'
                '15deg 60dps'
                '15deg 120dps'
                '15deg 240dps'
                '15deg 480dps'
                '15deg flicker'
            };

            % Stimulus speeds in degrees per second
            config.stimulus_speeds = [60, 120, 240, 480, 0, 60, 120, 240, 480, 0];

        otherwise
            warning('get_protocol_config:UnknownProtocol', ...
                'Unknown protocol: %s. Using default configuration.', protocol_name);
            config.description = 'Unknown protocol (default configuration)';
            config.n_conditions = 12;
            config.n_reps = 2;
            config.trial_duration_s = 15;
            config.interval_duration_s = 20;
            config.uses_cond_array = true;
            config.condition_labels = {};
    end

    %% Set defaults for optional fields if not specified
    if ~isfield(config, 'acclim_start_s')
        config.acclim_start_s = 300;
    end
    if ~isfield(config, 'acclim_end_s')
        config.acclim_end_s = 30;
    end
    if ~isfield(config, 'flash_duration_s')
        config.flash_duration_s = 5;
    end
    if ~isfield(config, 'stimulus_speeds')
        config.stimulus_speeds = [];
    end

end
