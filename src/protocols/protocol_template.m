% =========================================================================
% protocol_XX.m - [SHORT DESCRIPTIVE TITLE]
% =========================================================================
% Created:  [DATE]
% Author:   [YOUR NAME]
% Based on: protocol_27
%
% RATIONALE:
%   [Describe the scientific question this protocol addresses in 1-3
%    sentences. For example: "This protocol tests whether T4/T5 neurons
%    are required for the optomotor response at different temporal
%    frequencies by presenting gratings at 4 Hz and 8 Hz alongside
%    matched flicker controls."]
%
% DESCRIPTION:
%   [Brief description of the experimental session. For example:
%    "Flies are acclimated in darkness for 5 minutes, then presented with
%    10 stimulus conditions (2 repetitions each, randomized order) with
%    20-second dark intervals between stimuli."]
%
% STIMULI INCLUDED:
%   - 60 deg gratings at 4 Hz and 8 Hz (patterns 9, 27)
%   - Matched 60 deg flicker at 4 Hz (pattern 10)
%   - Dark interval between stimuli (pattern 47)
%
% CONDITIONS SUMMARY:
%   #  | Pattern | Speed (fps) | TF (Hz)  | Duration | Description
%   ---|---------|-------------|----------|----------|------------------------
%   1  | 9       | 127         | ~4 Hz    | 15s      | 60 deg grating, 1 px/f
%   2  | 27      | 127         | ~8 Hz    | 15s      | 60 deg grating, 2 px/f
%   3  | 10      | 8           | 4 Hz     | 15s      | 60 deg flicker
%
% TIMING:
%   Acclimation start:  300s (5 min darkness)
%   Calibration flash:  5s
%   Trial duration:     15s per direction (CW then CCW = 30s total)
%   Inter-stimulus:     20s (dark, pattern 47)
%   Repetitions:        2 (randomized order each time)
%   Acclimation end:    30s
%   Estimated total:    ~XX minutes
%     = 300 + 5 + 20 + (N_cond * 2 reps * (30 trial + 20 interval)) + 30
%
% STIMULUS ROUTING:
%   All conditions -> present_optomotor_stimulus
%   [Or describe mixed routing, e.g.:
%    Conditions 1-4  -> present_optomotor_stimulus (gratings)
%    Conditions 5-6  -> present_optomotor_stimulus_curtain (curtains)
%    Condition  7    -> present_fixation_stimulus (bar fixation)]
%
% SEE ALSO:
%   PROTOCOL_REFERENCE.md  — overview of all existing protocols
%   protocol_27.m          — the standard "screen protocol"
% =========================================================================

%% ========================================================================
%  SECTION 1: WORKSPACE CLEANUP AND HARDWARE INITIALIZATION
%  ========================================================================
%  Clear workspace and ensure camera is disconnected before starting.
%  SimpleBiasCameraInterface connects to BIAS camera software via TCP/IP.
%  initialize_temp_recording() sets up the Arduino thermocouple reader.

clear

% Load configuration (paths for rig, data, patterns, etc.)
cfg = get_config();

% Disconnect camera in case it was left connected from a previous session.
ip = '127.0.0.1';
port = 5010;
vidobj = SimpleBiasCameraInterface(ip, port);
vidobj.disconnect();

% Initialize the temperature recording (Arduino-based thermocouple).
d = initialize_temp_recording();

%% ========================================================================
%  SECTION 2: TIMING PARAMETERS
%  ========================================================================
%  These values control the duration of each experimental phase.
%  Adjust these to suit your protocol design.

t_acclim_start = 300;  % Pre-stimulus dark period (seconds). 300 = 5 min.
                       % Use 30 for development/testing runs.
t_flash = 5;           % Calibration flash duration (seconds).
t_acclim_end = 30;     % Post-stimulus dark period (seconds).
t_interval = 20;       % Inter-stimulus dark interval (seconds).
t_pause = 0.01;        % Hardware command pause (seconds). Do not change.
% t_one_dir = 30;      % Uncomment for single-direction protocols (see
%                      % present_optomotor_stimulus_one_direction).

%  SPEED REFERENCE
%  -----------------------------------------------------------------------
%  The speed_patt value in all_conditions (column 3) sets the frame rate
%  in frames per second (fps). The actual temporal frequency (TF) and
%  velocity depend on the pattern's spatial period and step size:
%
%    TF (Hz)       = fps * step_size / spatial_period_px
%    Velocity (d/s)= TF * spatial_period_deg
%
%  Arena geometry: 192 columns = 360 deg -> 1 pixel = 1.875 deg
%
%  PRECOMPUTED SPEEDS FOR COMMON PATTERNS:
%  Pattern | Type              | Period     | Step  | spd 8 | spd 16| spd 32| spd 64| spd 127
%  --------|-------------------|------------|-------|-------|-------|-------|-------|--------
%  4       | 15 deg grating    |  8 px      | 1px/f | 1 Hz  | 2 Hz  | 4 Hz  | 8 Hz  | ~16 Hz
%  6       | 30 deg grating    | 16 px      | 1px/f | 0.5Hz | 1 Hz  | 2 Hz  | 4 Hz  | ~8 Hz
%  9       | 60 deg grating    | 32 px      | 1px/f | 0.25Hz| 0.5Hz | 1 Hz  | 2 Hz  | ~4 Hz
%  27      | 60 deg grating    | 32 px      | 2px/f | 0.5Hz | 1 Hz  | 2 Hz  | 4 Hz  | ~8 Hz
%  63      | 15 deg grating    |  8 px      | 2px/f | 2 Hz  | 4 Hz  | 8 Hz  | 16 Hz | ~32 Hz
%  78      | 60 deg (half)     | 32 px      | 2px/f | 0.5Hz | 1 Hz  | 2 Hz  | 4 Hz  | ~8 Hz
%  79      | 60 deg (half)     | 32 px      | 3px/f | 0.75Hz| 1.5Hz | 3 Hz  | 6 Hz  | ~12 Hz
%  17      | 2ON:14OFF bar     | 16 px      | 1px/f | 0.5Hz | 1 Hz  | 2 Hz  | 4 Hz  | ~8 Hz
%  24      | 2OFF:14ON bar     | 16 px      | 1px/f | 0.5Hz | 1 Hz  | 2 Hz  | 4 Hz  | ~8 Hz
%  1       | 30 deg (contrast) | 16 px      | 1px/f | 0.5Hz | 1 Hz  | 2 Hz  | 4 Hz  | ~8 Hz
%
%  NON-GRATING PATTERNS (speed = presentation rate, not TF):
%  Pattern | Type                    | Notes
%  --------|-------------------------|------------------------------------------
%  7, 10   | Flicker (30/60 deg)     | 2-frame ON/OFF. fps = flicker rate.
%  65, 67  | Flicker (low luminance) | Same as above with reduced contrast.
%  19, 20  | Curtain ON/OFF (16px)   | Progressive edge. fps = expansion rate.
%  51, 52  | Curtain ON/OFF (32px)   | Progressive edge (wider bars).
%  57      | Bar fixation (32px)     | Static single bar. Speed ignored (use 1).
%  47      | Dark background         | 2-frame all-OFF. Used as interval pattern.
%  48      | Full field flash        | 2-frame ON/OFF. Calibration only.
%  25, 29  | Greyscale background    | 2-frame uniform grey. Alternative interval.
%
%  SHIFTED / OFFSET CoR PATTERNS:
%  Pattern | Type                    | Spatial Period  | Step
%  --------|-------------------------|-----------------|------
%  21      | 60 deg, 0.8 shift       | 32 px (warped)  | 1 px/f
%  70, 71  | 30 deg, 0.75 offset     | 16 px (warped)  | 1 px/f
%  72, 73  | 60 deg, 0.75 offset     | 32 px (warped)  | 1 px/f
%
%  REVERSE PHI PATTERNS (contrast-reversing motion):
%  Pattern | Bar Width  | Step   | Notes
%  --------|------------|--------|---------------------------
%  32      | 8+8 px     | 4 px/f | gs_val=4, values 0/3/8
%  60      | 16+16 px   | 8 px/f | gs_val=3, values 0/3/7
%  58      | 8+24 px    | 4 px/f | gs_val=3, asymmetric bars
%  59      | 16+16 px   | 4 px/f | gs_val=3, values 0/3/7
%  61      | 16+16 px   | 4 px/f | gs_val=3, values 0/2/7
%  62      | 16+16 px   | 4 px/f | gs_val=2, values 0/1/3

%% ========================================================================
%  SECTION 3: EXPERIMENTAL CONDITIONS
%  ========================================================================
%  The all_conditions matrix defines every stimulus condition.
%  Each row is one condition. The columns are:
%
%  Col | Variable     | Description
%  ----|--------------|---------------------------------------------------
%  1   | pattern_id   | Pattern number (from Patterns_optomotor/ folder)
%  2   | interval_id  | Interval pattern number (47 = dark, 25 = grey)
%  3   | speed_patt   | Stimulus speed in fps (see speed table above)
%  4   | speed_int    | Interval speed (typically 1 = minimal)
%  5   | trial_dur    | Duration per direction in seconds
%  6   | int_dur      | Interval duration in seconds
%
%  The row number identifies the condition. The presentation functions
%  receive the row index as 'current_condition' and use it to look up
%  parameters and for routing.
%
%  NOTE: Older protocols have a redundant 7th column (condition_n) that
%  duplicates the row number. This template omits it. The condition
%  number is automatically derived from the row index.

% [pattern_id, interval_id, speed_patt, speed_int, trial_dur, int_dur]
all_conditions = [
    9, 47, 127, 1, 15, t_interval;   % 60 deg grating - ~4 Hz (1 px/f)
    27, 47, 127, 1, 15, t_interval;   % 60 deg grating - ~8 Hz (2 px/f)
    10, 47, 8, 1, 15, t_interval;     % 60 deg flicker - 4 Hz
];

% Append condition number as column 7 (required by presentation functions).
% This is automatic — you do not need to maintain it manually.
all_conditions(:, 7) = (1:height(all_conditions))';

num_conditions = height(all_conditions);

% Optional: labels for the progress display (one per condition row).
% If omitted, the progress display shows the pattern number instead.
% Edit these to match your conditions above.
condition_labels = {
    '60 deg grating — ~4 Hz (Pattern 9)';
    '60 deg grating — ~8 Hz (Pattern 27)';
    '60 deg flicker — 4 Hz (Pattern 10)';
};

% Number of repetitions (each condition is presented this many times).
n_reps = 2;

% Estimate total experiment duration for the progress display.
% This sums the timing of all phases to give a rough ETA.
total_stim_time = 0;
for c = 1:num_conditions
    % Each condition: 2 directions * trial_dur + interval_dur
    total_stim_time = total_stim_time + 2*all_conditions(c,5) + all_conditions(c,6);
end
t_total_est = t_acclim_start + t_flash + t_interval + ...
              n_reps * total_stim_time + t_acclim_end;

%% ========================================================================
%  SECTION 4: SESSION INITIALIZATION
%  ========================================================================
%  Sets up video recording, creates output folders, and collects
%  experimenter metadata via the get_input_parameters() GUI dialog.
%  You will be prompted for: strain, age, sex, number of flies, notes.

%% Protocol name (auto-detected from filename — do not hardcode)
func_name = string(mfilename());

%% Initialize video, folders, and collect experimenter metadata
[LOG, vidobj, exp_folder, date_str, t_str, params] = ...
    initialize_video_and_folders(cfg.rig_data_folder, func_name);

% Panel controller mode: [0 0] = double open loop (standard for all protocols)
controller_mode = [0 0];

%% Record starting temperature
[t_outside_start, t_ring_start] = get_temp_rec(d);

%% Start experiment timer (for progress display)
exp_start = tic;

%% Start camera recording
vidobj.startCapture();
pause(t_pause)

%% Create randomized condition order
random_order = randperm(num_conditions);

print_progress(func_name, 'setup', 0, n_reps, 0, num_conditions, ...
               exp_start, t_total_est, '');

%% ========================================================================
%  SECTION 5: STIMULUS PRESENTATION
%  ========================================================================
%  The experiment runs all conditions twice (j = [1,2]).
%  Condition order is randomized within each repetition.
%  Before the very first condition, a calibration flash is presented.
%
%  AVAILABLE PRESENTATION FUNCTIONS:
%  (all in src/protocols/protocol_functions/)
%
%  Function                                       | Use when...
%  -------|---------------------------------------|---------------------------
%  present_optomotor_stimulus(cc, ac, v, d)       | Standard gratings, flicker,
%                                                 |   reverse phi, static patterns
%  present_optomotor_stimulus_curtain(cc,ac,v,d)  | Progressive edge / curtain
%                                                 |   stimuli (ON/OFF)
%  present_fixation_stimulus(cc, ac, v, d)        | Stationary bar / fixation
%                                                 |   patterns (no motion)
%  present_optomotor_stimulus_one_direction(..)   | Single direction only (no
%                                                 |   CW + CCW alternation)
%  present_optomotor_stimulus_w_interval(..)      | Grating with dark interval
%                                                 |   inserted between CW and CCW
%  present_optomotor_stimulus_curtain_w_interval..| Curtain with interval between
%                                                 |   CW and CCW directions
%  present_optomotor_stimulus_diff_contrasts(..)  | Varying contrast levels
%                                                 |   (uses y_num dimension)
%  present_shifted_stimulus(cc, ac, v)            | Shifted centre of rotation
%                                                 |   NOTE: no 'd' parameter!
%
%  All functions share the signature:
%    Log = present_*(current_condition, all_conditions, vidobj, d, verbose)
%  except present_shifted_stimulus which omits 'd'.
%  Pass verbose=false to suppress trial-by-trial disp() output
%  (the progress display handles user feedback instead).

%% Pre-stimulus dark acclimation
print_progress(func_name, 'acclimation_start', 0, n_reps, 0, num_conditions, ...
               exp_start, t_total_est, '');
LOG = present_acclim_off(LOG, vidobj, t_pause, t_acclim_start, 1, d, false);

%% Begin stimulus loop
log_n = 1;
Panel_com('set_mode', controller_mode); pause(t_pause)

% Run through all conditions twice
for j = [1,2]

    %start LOOP
     for i = 1:num_conditions
         % get the current condition
         current_condition = random_order(i);

         if j == 1 && i == 1 % Before the first condition:

             % % ACCLIM PATT
            print_progress(func_name, 'flash', 0, n_reps, 0, num_conditions, ...
                           exp_start, t_total_est, '');
            flash_pattern = 48; % Full field ON - OFF
            flash_speed = 4; % fps

            % acclim_patt.condition = optomotor_pattern;
            acclim_patt.flash_pattern = flash_pattern;
            acclim_patt.flash_speed = flash_speed;
            acclim_patt.flash_dur = t_flash;
            acclim_patt.dir = 0;
            acclim_patt.start_t = vidobj.getTimeStamp().value;
            acclim_patt.start_f = vidobj.getFrameCount().value;

            Panel_com('set_pattern_id', flash_pattern); pause(t_pause)
            Panel_com('send_gain_bias', [flash_speed 0 0 0]); pause(t_pause)
            Panel_com('set_position', [1 1]); pause(t_pause)
            Panel_com('start');
            pause(t_flash);
            Panel_com('stop'); pause(t_pause);

            acclim_patt.stop_t = vidobj.getTimeStamp().value;
            acclim_patt.stop_f = vidobj.getFrameCount().value;

            LOG.acclim_patt = acclim_patt;

            % % Interval after flashes
            Panel_com('set_pattern_id', 47); % bkg pattern with 0.
            pause(t_pause);
            Panel_com('send_gain_bias', [0 0 0 0]);
            pause(t_pause);
            Panel_com('set_position', [1 1]);
            pause(t_pause);
            Panel_com('start');
            pause(t_pause);

            % get frame and log it
            acclim_patt.start_t_int = vidobj.getTimeStamp().value;
            acclim_patt.start_f_int = vidobj.getFrameCount().value;

            % Set duration and stop.
            pause(t_interval);
            Panel_com('stop');

            acclim_patt.stop_t_int = vidobj.getTimeStamp().value;
            acclim_patt.stop_f_int = vidobj.getFrameCount().value;

         end

         % Update progress display for this condition
        if current_condition <= numel(condition_labels)
            label = condition_labels{current_condition};
        else
            label = sprintf('Pattern %d', all_conditions(current_condition, 1));
        end
        print_progress(func_name, 'stimulus', j, n_reps, i, num_conditions, ...
                       exp_start, t_total_est, label);

        % --- STIMULUS ROUTING ---------------------------------------------------
        % Choose ONE of the routing patterns below and modify to suit your
        % protocol. Delete or comment out the patterns you don't need.

        % OPTION A: Simple routing (all conditions use the same function)
        % Use this when all conditions are standard gratings/flicker/reverse phi.
        Log = present_optomotor_stimulus(current_condition, all_conditions, vidobj, d, false);

        % OPTION B: Mixed routing (different functions for different conditions)
        % Use this when your protocol mixes stimulus types (e.g., gratings +
        % curtains + fixation). Route by condition number.
        % if current_condition == 5 || current_condition == 6
        %     % Curtain stimuli
        %     Log = present_optomotor_stimulus_curtain(current_condition, all_conditions, vidobj, d, false);
        % elseif current_condition > 10
        %     % Bar fixation stimuli
        %     Log = present_fixation_stimulus(current_condition, all_conditions, vidobj, d, false);
        % else
        %     % Standard gratings / flicker / reverse phi
        %     Log = present_optomotor_stimulus(current_condition, all_conditions, vidobj, d, false);
        % end
        % -----------------------------------------------------------------------

        % Add the Log from this condition to the overall LOG structure.
        fieldName = sprintf('log_%d', log_n);
        LOG.(fieldName) = Log;

        log_n = log_n+1;
     end
end

%% ========================================================================
%  SECTION 6: POST-EXPERIMENT CLEANUP AND DATA SAVING
%  ========================================================================
%  Records the final dark period, stops the camera, saves the LOG file,
%  and exports metadata to the Google Sheets experiment log.
%  Do not modify this section unless changing the logging structure.

%% Post-stimulus dark acclimation
print_progress(func_name, 'acclimation_end', 0, n_reps, 0, num_conditions, ...
               exp_start, t_total_est, '');
LOG = present_acclim_off(LOG, vidobj, t_pause, t_acclim_end, 2, d, false);

%% Stop camera
vidobj.stopCapture();

%% Record ending temperature
[t_outside_end, t_ring_end] = get_temp_rec(d);

%% Save metadata to LOG structure
LOG.meta.t_acclim_start = t_acclim_start;
LOG.meta.t_flash = t_flash;
LOG.meta.t_acclim_end = t_acclim_end;
LOG.meta.start_temp_outside = t_outside_start;
LOG.meta.start_temp_ring = t_ring_start;
LOG.meta.end_temp_outside = t_outside_end;
LOG.meta.end_temp_ring = t_ring_end;
LOG.meta.cond_array = all_conditions;
LOG.meta.random_order = random_order;

%% Save LOG.mat file
log_fname = fullfile(exp_folder, strcat('LOG_', string(date_str), '_', t_str, '.mat'));
save(log_fname, 'LOG');

print_progress(func_name, 'complete', n_reps, n_reps, num_conditions, num_conditions, ...
               exp_start, t_total_est, '');

%% Notes and Google Sheets export
prompt = "Notes at end: ";
notes_str_end = input(prompt, 's');
params.NotesEnd = notes_str_end;

if params.Strain == "test"
    disp("Data not sent to google sheet since this is a test.")
else
    % Export to the google sheet log:
    export_to_google_sheets(params)
end

%% Clear temperature sensor
clear d ch1
