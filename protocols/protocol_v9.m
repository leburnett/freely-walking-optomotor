
%Protocol_v9.m file - different spatial frequecies
clear

% Set pixel width
pixel_width = 4; 

%% Input parameters:
% These parameters will be saved in the log file. 
fly_strain = 'csw1118';
fly_age = 2; % days
fly_sex = 'F';
n_flies = 15;
lights_ON = datetime('20:00', 'Format', 'HH:mm');
lights_OFF = datetime('12:00', 'Format', 'HH:mm');
arena_temp = 24.9;

% Protocol parameters:
trial_len = 10;  
t_acclim = 20; 
t_flicker = 30; 
num_trials_per_block = 4; 
num_directions = 2; 
num_reps = 2;
num_flickers = 2; 
num_acclim = 3; 

% Pattern settings:
if pixel_width == 4
    % 4 pixel bars
    optomotor_pattern = 4;
    flicker_pattern = 5;
    optomotor_speed = 32; 
elseif pixel_width == 8 
    % 8 pixel bars
    optomotor_pattern = 6;
    flicker_pattern = 7;
    optomotor_speed = 64; % in frames per second - was 64
elseif pixel_width == 16
    % 16 pixel bars
    optomotor_pattern = 9;
    flicker_pattern = 10;
    optomotor_speed = 127; 
end 

% Flicker speed stays consistent.
flicker_speed = 8;

%% Protocol name
func_name = string(mfilename());
% func_name = lower(func_name(1:11));

%% SD card pattern information
load('C:\MatlabRoot\Patterns\patterns_oaky\SD_copy.mat', 'SD');
patterns = SD.pattern.pattNames;
% cell array with the name of the patterns used.
pattern_names = patterns(optomotor_pattern: flicker_pattern);

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

%% Save the data in date-folder -- protocol_folder -- strain_folder -- time_folder
project_data_folder = 'C:\MatlabRoot\FreeWalkOptomotor\data';

date_folder = fullfile(project_data_folder, string(date_str));
if ~isfolder(date_folder)
    mkdir(date_folder)
end 

protocol_folder = fullfile(date_folder, func_name);
if ~isfolder(protocol_folder)
    mkdir(protocol_folder)
end

strain_folder = fullfile(protocol_folder, fly_strain);
if ~isfolder(strain_folder)
    mkdir(strain_folder)
end

sex_folder = fullfile(strain_folder, fly_sex);
if ~isfolder(sex_folder)
    mkdir(sex_folder)
end

cond_folder = fullfile(sex_folder, string(pixel_width));
if ~isfolder(cond_folder)
    mkdir(cond_folder)
end

t_str = strrep(string(time_str), ':', '_');
exp_folder = fullfile(cond_folder, t_str);
if ~isfolder(exp_folder)
    mkdir(exp_folder)
end 

exp_name = 'REC_';
v_fname =  fullfile(exp_folder, exp_name);

vidobj.enableLogging();
vidobj.loadConfiguration(config_path);
vidobj.setVideoFile(v_fname);

% Pattern settings
controller_mode = [0 0]; % double open loop

idx_value = 1;
con_val = 1; 

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
Log.contrast(idx_value) = 1.0; 
Log.dir(idx_value) = 0;
disp('Pattern ON')
Log.start_t(idx_value) = vidobj.getTimeStamp().value;
Log.start_f(idx_value) = vidobj.getFrameCount().value;

Panel_com('set_mode',controller_mode); pause(0.01)
Panel_com('set_pattern_id', optomotor_pattern); pause(0.01)
Panel_com('set_position', [1 con_val]); pause(0.01) 
pause(t_acclim);

% get frame and log it 
Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
Log.stop_f(idx_value) = vidobj.getFrameCount().value;

%% sweeping up contrast block
disp('Acclim ended')

for tr_ind = 1:num_trials_per_block

    disp(['trial number = ' num2str(tr_ind)])

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
    pause(0.01);
    Panel_com('set_position', [1 con_val]);
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
    Log.contrast(idx_value) = 1;
    Log.dir(idx_value) = dir_val;

    Panel_com('send_gain_bias', [optomotor_speed*dir_val 0 0 0]); 
    pause(0.01);
    Panel_com('set_position', [1 con_val]);  
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

end

%% Flicker pattern 

disp('trial number = flicker 1')

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


%% sweeping down contrast block

Panel_com('set_mode',controller_mode);
Panel_com('set_pattern_id', optomotor_pattern);

for tr_ind = 7+[1:num_trials_per_block]

    disp(['trial number = ' num2str(tr_ind)])

    idx_value = idx_value+1;
    % set dir_val as positive (1)
    dir_val = 1;

    % Log
    Log.trial(idx_value) = idx_value;
    Log.contrast(idx_value) = 1;
    Log.dir(idx_value) = dir_val;

    Panel_com('send_gain_bias', [optomotor_speed*dir_val 0 0 0]); 
    pause(0.01);
    Panel_com('set_position', [1 con_val]); 
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
    Log.contrast(idx_value) = 1;
    Log.dir(idx_value) = dir_val;

    Panel_com('send_gain_bias', [optomotor_speed*dir_val 0 0 0]); 
    pause(0.01);
    Panel_com('set_position', [1 con_val]); 
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

end

%% Flicker pattern 

disp('trial number = flicker 2')
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

%% Add parameters to log file. 
LOG.date = date_str;
LOG.time = time_str;

LOG.fly_strain = fly_strain;
LOG.fly_age = fly_age;
LOG.fly_sex = fly_sex;
LOG.n_flies=n_flies;
LOG.lights_ON = lights_ON;
LOG.lights_OFF = lights_OFF;
LOG.arena_temp= arena_temp;

% Protocol name
LOG.func_name = func_name;
LOG.pixel_width = pixel_width;

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

% Add log file of timings per condition
LOG.Log = Log;

%% save LOG file
log_fname =  fullfile(exp_folder, strcat('LOG_', string(date_str), '_', t_str, '.mat'));
save(log_fname, 'LOG');
disp('Log saved')


%%
% 
% vid_fname = 'C:\MatlabRoot\FreeWalkOptomotor\data\2024_06_11\16_41_58\REC__cam_0_date_2024_06_11_time_16_41_58_v001.avi';
% v = VideoReader(vid_fname);