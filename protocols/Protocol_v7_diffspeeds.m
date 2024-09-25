
%Protocol_v7.m - different speeds

% [16, 2]; 1 Hz
% [32, 4]; 2 Hz
% [64, 8]; 4 Hz
% [127, 16]; 8 Hz

speed_val = 127; % 64 = baseline
flicker_speed = 16;

% % gs_val = 3 - 2:7 patterns
% optomotor_pattern = 1;
% flicker_pattern = 2;

% gs_val = 1 - 0:1 patterns
% 8 pixel bars
optomotor_pattern = 6;
flicker_pattern = 7;

%% block of initializations

% BIAS settings:
ip = '127.0.0.1';
port = 5010;
config_path = 'C:\MatlabRoot\FreeWalkOptomotor\bias_config_ufmf.json';

vidobj = SimpleBiasCameraInterface(ip, port);
vidobj.connect();
vidobj.getStatus();

% Get date and time
date_str = datetime('now','TimeZone','local','Format','yyyy_MM_dd');
time_str = datetime('now','TimeZone','local','Format','HH:mm:ss');

% Path to project folder
project_data_folder = 'C:\MatlabRoot\FreeWalkOptomotor\data';

date_folder = fullfile(project_data_folder, string(date_str));
if ~isfolder(date_folder)
    mkdir(date_folder)
end 

t_str = strrep(string(time_str), ':', '_');
exp_folder = fullfile(date_folder, t_str);
if ~isfolder(exp_folder)
    mkdir(exp_folder)
end 

% exp_name = strcat(exp_str, string(date_str), '-', t_str);
exp_name = 'REC_';
v_fname =  fullfile(exp_folder, exp_name);

vidobj.enableLogging();
% vidobj.setConfiguration(config_path);
vidobj.loadConfiguration(config_path);
vidobj.setVideoFile(v_fname);

% Pattern settings
optomotor_speed = speed_val; % in frames per second
controller_mode = [0 0]; % double open loop
contrast_levels = [0.11 0.2 0.333 0.4 0.556 0.75 1.0];

trial_len = 10; 
t_acclim = 20; %60;
t_flicker = 30;

num_trials_per_block = 4; %7;
num_directions = 2; 
num_reps = 2;
num_flickers = 2; 
num_acclim = 3; 

idx_value = 1;

sz = [((num_trials_per_block*num_directions)*num_reps)+num_flickers+num_acclim, 7];
varTypes = {'double', 'double','double','double','double','double','double'};
varNames = {'trial', 'contrast', 'dir', 'start_t', 'start_f', 'stop_t', 'stop_f'};
Log = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

%% start camera
vidobj.startCapture();
disp('camera ON')
% Record the behaviour of the flies without any lights on in the arena
% before running the stimulus. 

% Acclim time with all panels OFF

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
Log.contrast(idx_value) = 0.11;
Log.dir(idx_value) = 0;
disp('Pattern ON')
Log.start_t(idx_value) = vidobj.getTimeStamp().value;
Log.start_f(idx_value) = vidobj.getFrameCount().value;

Panel_com('set_mode',controller_mode); pause(0.01)
Panel_com('set_pattern_id', optomotor_pattern); pause(0.01)
Panel_com('set_position', [1 1]); pause(0.01)
pause(t_acclim);

% get frame and log it 
Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
Log.stop_f(idx_value) = vidobj.getFrameCount().value;

%% sweeping up contrast block
disp('Acclim ended')

for tr_ind = 1:num_trials_per_block

    % If not the first trial then add one to idx_value
    if idx_value > 1
        idx_value = idx_value+1;
    end 
    % set dir_val as positive (1)
    dir_val = 1;

    % Log
    Log.trial(idx_value) = idx_value;
    Log.contrast(idx_value) = contrast_levels(tr_ind);
    Log.dir(idx_value) = dir_val;

    Panel_com('send_gain_bias', [optomotor_speed 0 0 0]);
    pause(0.01);
    % Panel_com('set_position', [1 tr_ind]);
    Panel_com('set_position', [1 1]);
    pause(0.01);
    Panel_com('start'); 
    pause(0.01);

    % get frame and log it
    Log.start_t(idx_value) = vidobj.getTimeStamp().value;
    Log.start_f(idx_value) = vidobj.getFrameCount().value;

    pause(trial_len); % The pattern will run for this ‘Time’
    pause(0.01); 
    Panel_com('stop'); 
    pause(0.01);

    % get frame and log it 
    Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
    Log.stop_f(idx_value) = vidobj.getFrameCount().value;

    % Add one to idx_value 
    idx_value = idx_value+1;
    % set dir_val as opposite (-1)
    dir_val = -1;

    % Log
    Log.trial(idx_value) = idx_value;
    Log.contrast(idx_value) = contrast_levels(tr_ind);
    Log.dir(idx_value) = dir_val;

    Panel_com('send_gain_bias', [-optomotor_speed 0 0 0]); 
    pause(0.01);
    % Panel_com('set_position', [1 tr_ind]); 
    Panel_com('set_position', [1 1]);
    pause(0.01);
    Panel_com('start'); 
    pause(0.01);

     % get frame and log it 
    Log.start_t(idx_value) = vidobj.getTimeStamp().value;
    Log.start_f(idx_value) = vidobj.getFrameCount().value;

    pause(trial_len); 
    pause(0.01); % The pattern will run for this ‘Time’
    Panel_com('stop'); 
    pause(0.01);

    % get frame and log it 
    Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
    Log.stop_f(idx_value) = vidobj.getFrameCount().value;

   disp(['trial number = ' num2str(tr_ind)])
end

%% Flicker pattern 

Panel_com('set_pattern_id', flicker_pattern);

idx_value = idx_value+1;
% set dir_val as positive (1)
dir_val = 0;

% Log
Log.trial(idx_value) = idx_value;
Log.contrast(idx_value) = 1.2;
Log.dir(idx_value) = dir_val;

Panel_com('send_gain_bias', [flicker_speed 0 0 0]); 
pause(0.01);
Panel_com('set_position', [1 1]);
pause(0.01);
Panel_com('start'); 
pause(0.01);

% get frame and log it
Log.start_t(idx_value) = vidobj.getTimeStamp().value;
Log.start_f(idx_value) = vidobj.getFrameCount().value;

pause(t_flicker); 
pause(0.01); % The pattern will run for this ‘Time’
Panel_com('stop'); 
pause(0.01);

% get frame and log it 
Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
Log.stop_f(idx_value) = vidobj.getFrameCount().value;

disp('trial number = flicker 1')

%% sweeping down contrast block

Panel_com('set_mode',controller_mode);
Panel_com('set_pattern_id', optomotor_pattern);

for tr_ind = 7+[1:num_trials_per_block]

    idx_value = idx_value+1;
    % set dir_val as positive (1)
    dir_val = 1;

    % Log
    Log.trial(idx_value) = idx_value;
    Log.contrast(idx_value) = contrast_levels(15-tr_ind);
    Log.dir(idx_value) = dir_val;

    Panel_com('send_gain_bias', [optomotor_speed 0 0 0]); 
    pause(0.01);
    % Panel_com('set_position', [1 15-tr_ind]);
    Panel_com('set_position', [1 1]);
    pause(0.01);
    Panel_com('start'); 
    pause(0.01);

    % get frame and log it
    Log.start_t(idx_value) = vidobj.getTimeStamp().value;
    Log.start_f(idx_value) = vidobj.getFrameCount().value;

    pause(trial_len); 
    pause(0.01); % The pattern will run for this ‘Time’
    Panel_com('stop'); 
    pause(0.01);

    % get frame and log it 
    Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
    Log.stop_f(idx_value) = vidobj.getFrameCount().value;

    % Add one to idx_value 
    idx_value = idx_value+1;
    % set dir_val as opposite (-1)
    dir_val = -1;
    
    % Log
    Log.trial(idx_value) = idx_value;
    Log.contrast(idx_value) = contrast_levels(15-tr_ind);
    Log.dir(idx_value) = dir_val;

    Panel_com('send_gain_bias', [-optomotor_speed 0 0 0]); 
    pause(0.01);
    % Panel_com('set_position', [1 15-tr_ind]);
    Panel_com('set_position', [1 1]);
    pause(0.01);
    Panel_com('start'); 
    pause(0.01);

    % get frame and log it 
    Log.start_t(idx_value) = vidobj.getTimeStamp().value;
    Log.start_f(idx_value) = vidobj.getFrameCount().value;

    pause(trial_len); 
    pause(0.01); % The pattern will run for this ‘Time’
    Panel_com('stop'); 
    pause(0.01);

    % get frame and log it
    Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
    Log.stop_f(idx_value) = vidobj.getFrameCount().value;

    disp(['trial number = ' num2str(tr_ind)])
end

%% Flicker pattern 

Panel_com('set_pattern_id', flicker_pattern);

idx_value = idx_value+1;
% set dir_val as positive (1)
dir_val = 0;

% Log
Log.trial(idx_value) = idx_value;
Log.contrast(idx_value) = 1.2;
Log.dir(idx_value) = dir_val;

Panel_com('send_gain_bias', [flicker_speed 0 0 0]); 
pause(0.01);
Panel_com('set_position', [1 1]);
pause(0.01);
Panel_com('start'); 
pause(0.01);

% get frame and log it
Log.start_t(idx_value) = vidobj.getTimeStamp().value;
Log.start_f(idx_value) = vidobj.getFrameCount().value;

pause(t_flicker); 
pause(0.01); % The pattern will run for this ‘Time’
Panel_com('stop'); 
pause(0.01);

% get frame and log it 
Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
Log.stop_f(idx_value) = vidobj.getFrameCount().value;

disp('trial number = flicker 2')

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
disp('Acclim OFF')

pause(t_acclim); 

% get frame and log it 
Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
Log.stop_f(idx_value) = vidobj.getFrameCount().value;


%% stop camera
vidobj.stopCapture();
disp('Camera OFF')
log_fname =  fullfile(exp_folder, strcat('LOG_', string(date_str), '_', t_str, '.mat'));
save(log_fname, 'Log');
disp('Log saved')


%%
% 
% vid_fname = 'C:\MatlabRoot\FreeWalkOptomotor\data\2024_06_11\16_41_58\REC__cam_0_date_2024_06_11_time_16_41_58_v001.avi';
% v = VideoReader(vid_fname);