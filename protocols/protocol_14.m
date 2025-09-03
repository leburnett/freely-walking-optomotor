
%Protocol_14.m file 

% Short, all high contrast, protocol. 
% Different 'interval' stimuli - flicker - static gratings - all ON - all
% OFF

clear 

% Initialize the temperature recording.
d = initialize_temp_recording();

% Protocol parameters:
t_acclim = 10; 

trial_len = 10; % x 2 directions - 20s gratings total
t_flicker = 20; % 20s interval
t_pause = 0.015; 

num_trials_per_block = 8;
num_directions = 2; 
num_reps = 2;
num_flickers = 2; 
num_acclim = 3; 

% Pattern settings - binary
optomotor_pattern = 6;
flicker_pattern = 7;

optomotor_speed = 64; % in frames per second
flicker_speed = 8;

%% Protocol name
func_name = string(mfilename());

%% SD card pattern information
load('C:\MatlabRoot\Patterns\patterns_oaky\SD_copy.mat', 'SD');
patterns = SD.pattern.pattNames;
% cell array with the name of the patterns used.
pattern_names = patterns(optomotor_pattern: flicker_pattern);

%% block of initializations
project_data_folder = 'C:\MatlabRoot\FreeWalkOptomotor\data';
[LOG, vidobj, exp_folder, date_str, t_str, params] = initialize_video_and_folders(project_data_folder, func_name);

controller_mode = [0 0]; % double open loop
idx_value = 1;

sz = [27, 7];
varTypes = {'double', 'double','double','double','double','double','double'};
varNames = {'trial', 'contrast', 'dir', 'start_t', 'start_f', 'stop_t', 'stop_f'};
Log = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

%% get start temperature
[t_outside_start, t_ring_start] = get_temp_rec(d);

%% start camera
vidobj.startCapture();
disp('camera ON')

Log.trial(idx_value) = idx_value;
Log.contrast(idx_value) = 0;
Log.dir(idx_value) = 0;
% get frame and log it
Log.start_t(idx_value) = vidobj.getTimeStamp().value;
Log.start_f(idx_value) = vidobj.getFrameCount().value;
Panel_com('all_off'); 
disp('Acclim OFF')
pause(t_acclim); 
% get frame and log it 
Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
Log.stop_f(idx_value) = vidobj.getFrameCount().value;

% Acclim time with all panels ON
idx_value = idx_value+1; 
Log.trial(idx_value) = idx_value;
Log.contrast(idx_value) = 1; 
Log.dir(idx_value) = 0;
disp('Pattern ON')
Log.start_t(idx_value) = vidobj.getTimeStamp().value;
Log.start_f(idx_value) = vidobj.getFrameCount().value;

Panel_com('set_mode', controller_mode); pause(t_pause)
Panel_com('set_pattern_id', optomotor_pattern); pause(t_pause)
Panel_com('set_position', [1 1]); pause(t_pause) 
pause(t_acclim);

% get frame and log it 
Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
Log.stop_f(idx_value) = vidobj.getFrameCount().value;

%% sweeping up contrast block
disp('Acclim ended')

for tr_ind = 1:num_trials_per_block

    disp('clockwise')

    Panel_com('set_mode',controller_mode); pause(t_pause)
    Panel_com('set_pattern_id', optomotor_pattern); pause(t_pause)
    Panel_com('set_position', [1 1]); pause(t_pause)

    % If not the first trial then add one to idx_value
    if idx_value > 1
        idx_value = idx_value+1;
    end 
    % set dir_val as positive (1)
    dir_val = 1;

    % Log
    Log.trial(idx_value) = idx_value;
    Log.contrast(idx_value) = 1;
    Log.dir(idx_value) = dir_val;

    Panel_com('send_gain_bias', [optomotor_speed*dir_val 0 0 0]);
    pause(t_pause)
    Panel_com('set_position', [1 1]);
    pause(t_pause)
    Panel_com('start'); 
    pause(t_pause)

    % get frame and log it
    Log.start_t(idx_value) = vidobj.getTimeStamp().value;
    Log.start_f(idx_value) = vidobj.getFrameCount().value;

    pause(trial_len); % The pattern will run for this ‘Time’
    Panel_com('stop'); 
    pause(t_pause)

    % get frame and log it 
    Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
    Log.stop_f(idx_value) = vidobj.getFrameCount().value;

    % Add one to idx_value 
    idx_value = idx_value+1;
    % set dir_val as opposite (-1)
    dir_val = -1;
    disp('anticlockwise')

    % Log
    Log.trial(idx_value) = idx_value;
    Log.contrast(idx_value) = 1;
    Log.dir(idx_value) = dir_val;

    Panel_com('send_gain_bias', [optomotor_speed*dir_val 0 0 0]); 
    pause(t_pause)
    Panel_com('set_position', [1 1]);  
    pause(t_pause)
    Panel_com('start'); 
    pause(t_pause)

     % get frame and log it 
    Log.start_t(idx_value) = vidobj.getTimeStamp().value;
    Log.start_f(idx_value) = vidobj.getFrameCount().value;

    pause(trial_len); 
    Panel_com('stop'); 
    pause(t_pause)

    % get frame and log it 
    Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
    Log.stop_f(idx_value) = vidobj.getFrameCount().value;

    %% INTERVAL - Flicker, static, all ON, all OFF

    if tr_ind == 1 || tr_ind == 5 % flicker
        disp('flicker')
        Panel_com('set_pattern_id', flicker_pattern);
        idx_value = idx_value+1;
        
        % Log
        Log.trial(idx_value) = idx_value;
        Log.contrast(idx_value) = 1.2;
        Log.dir(idx_value) = 0;
        
        Panel_com('send_gain_bias', [flicker_speed 0 0 0]); 
        pause(t_pause)
        Panel_com('set_position', [1 1]);
        pause(t_pause)
        Panel_com('start'); 
        pause(t_pause)
        
        Log.start_t(idx_value) = vidobj.getTimeStamp().value;
        Log.start_f(idx_value) = vidobj.getFrameCount().value;
        
        pause(t_flicker);  
        Panel_com('stop'); 
        pause(t_pause)

        Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
        Log.stop_f(idx_value) = vidobj.getFrameCount().value;

    elseif tr_ind == 2 || tr_ind == 6 % static stripes
        disp('static grating')
        Panel_com('set_pattern_id', flicker_pattern);
        idx_value = idx_value+1;
        
        % Log
        Log.trial(idx_value) = idx_value;
        Log.contrast(idx_value) = 1.3; % % % % % % % 1.3 
        Log.dir(idx_value) = 0;
        
        Panel_com('send_gain_bias', [0 0 0 0]); % % % % % % speed = 0
        pause(t_pause)
        Panel_com('set_position', [1 1]);
        pause(t_pause)
        Panel_com('start'); 
        pause(t_pause)
        
        % get frame and log it
        Log.start_t(idx_value) = vidobj.getTimeStamp().value;
        Log.start_f(idx_value) = vidobj.getFrameCount().value;
        
        pause(t_flicker);  
        Panel_com('stop'); 
        pause(t_pause)
        
        % get frame and log it 
        Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
        Log.stop_f(idx_value) = vidobj.getFrameCount().value;

    elseif tr_ind == 3 || tr_ind == 7 % all ON
        disp('all on')
        Panel_com('all_on');
        idx_value = idx_value+1;
        
        % Log
        Log.trial(idx_value) = idx_value;
        Log.contrast(idx_value) = 1.4; % % % % % % % 
        Log.dir(idx_value) = 0;

        Log.start_t(idx_value) = vidobj.getTimeStamp().value;
        Log.start_f(idx_value) = vidobj.getFrameCount().value;
        
        pause(t_flicker);  

        % get frame and log it 
        Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
        Log.stop_f(idx_value) = vidobj.getFrameCount().value;

    elseif tr_ind == 4 || tr_ind == 8 % all OFF
        disp('all off')
        Panel_com('all_off');
        idx_value = idx_value+1;
        
        % Log
        Log.trial(idx_value) = idx_value;
        Log.contrast(idx_value) = 1.5; % % % % % % % 
        Log.dir(idx_value) = 0;

        Log.start_t(idx_value) = vidobj.getTimeStamp().value;
        Log.start_f(idx_value) = vidobj.getFrameCount().value;
        
        pause(t_flicker);  

        Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
        Log.stop_f(idx_value) = vidobj.getFrameCount().value;
    end 
end

%% Acclim at the end 
% Record the behaviour of the flies without any lights on in the arena
% after running the stimulus. 
idx_value = idx_value+1;

% Log - for acclim
Log.trial(idx_value) = idx_value;
Log.contrast(idx_value) = 0;
Log.dir(idx_value) = 0;
% get frame and log it
Log.start_t(idx_value) = vidobj.getTimeStamp().value;
Log.start_f(idx_value) = vidobj.getFrameCount().value;
Panel_com('all_off'); 
pause(t_pause)
disp('Acclim OFF')

pause(t_acclim); 

% get frame and log it 
Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
Log.stop_f(idx_value) = vidobj.getFrameCount().value;

% get end temp
[t_outside_end, t_ring_end] = get_temp_rec(d);

%% stop camera
vidobj.stopCapture();
disp('Camera OFF')

%% Add parameters to log file. 

% Protocol parameters:
LOG.trial_len=trial_len;
LOG.t_acclim=t_acclim;
LOG.t_flicker=t_flicker;
LOG.num_trials_per_block=num_trials_per_block;
LOG.num_directions=num_directions; 
LOG.num_reps=num_reps;
LOG.num_flickers=num_flickers; 
LOG.num_acclim=num_acclim; 

% Pattern settings
LOG.optomotor_pattern=optomotor_pattern;
LOG.flicker_pattern=flicker_pattern;
LOG.optomotor_speed=optomotor_speed; % in frames per second
LOG.flicker_speed = flicker_speed;
LOG.pattern_names=pattern_names;

% Temperature
LOG.start_temp_outside = t_outside_start;
LOG.start_temp_ring = t_ring_start;
LOG.end_temp_outside = t_outside_end;
LOG.end_temp_ring = t_ring_end;

% Add log file of timings per condition
LOG.Log = Log;

%% save LOG file
log_fname =  fullfile(exp_folder, strcat('LOG_', string(date_str), '_', t_str, '.mat'));
save(log_fname, 'LOG');
disp('Log saved')

% clear temp
clear d ch1 ch2
