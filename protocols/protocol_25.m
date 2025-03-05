% Protocol_25.m  - short protocol for testing individual flies.

% Includes:
% - off background interval - pattern 47
% - 60 deg gratings - 2 speeds
% - flicker - 1 speed

% 20s interval
% 30s trial duration - 2x15s trials

clear 

% Make sure to disconnect camera before start - in case accidentally still
% connected.
ip = '127.0.0.1';
port = 5010;
vidobj = SimpleBiasCameraInterface(ip, port);
vidobj.disconnect();

% Initialize the temperature recording.
d = initialize_temp_recording();

% Protocol parameters: 
t_acclim_start = 300; %00; %300; % 5 minutes of recording behaviour in the dark before the experiment begins.
t_flash = 10; % 10s of full field flashing 
t_acclim_end = 30; %30;
t_interval = 20; % 30s interval between stimuli
t_pause = 0.01;

% [pattern_id, interval_id, speed_patt, speed_int, trial_dur, int_dur, condition_n]
all_conditions = [ 
    27, 47, 64, 1, 15, t_interval, 1; %  60 deg gratings - 4Hz - 2 px step pattern
    27, 47, 127, 1, 15, t_interval, 2; % 60 deg gratings - 8Hz - 2px step pattern
    10, 47, 8, 1, 15, t_interval, 3;  % Flicker - 4Hz
    10, 47, 16, 1, 15, t_interval, 4; % Flicker - 8Hz
];  

num_conditions = height(all_conditions); 

%% Protocol name
func_name = string(mfilename());

%% block of initializations
project_data_folder = 'C:\MatlabRoot\FreeWalkOptomotor\data';

[LOG, vidobj, exp_folder, date_str, t_str, params] = initialize_video_and_folders(project_data_folder, func_name);
% Pattern settings
controller_mode = [0 0]; % double open loop

%% get start temperature
[t_outside_start, t_ring_start] = get_temp_rec(d);

%% start camera
vidobj.startCapture();
disp('camera ON')
pause(t_pause)

%% create random number order of the conditions
random_order = randperm(num_conditions);
display (random_order);

%% % ACCLIM OFF
LOG = present_acclim_off(LOG, vidobj, t_pause, t_acclim_start, 1, d);
disp('Recording behaviour in darkness')

%% Present stimuli
log_n = 1;
Panel_com('set_mode', controller_mode); pause(t_pause)

% Run through all conditions three times
n_reps = 2;
for j = 1:n_reps 

    %start LOOP
     for i = 1:num_conditions
         % get the current condition
         current_condition = random_order(i);

         if j == 1 && i == 1 % Before the first condition:

             % % ACCLIM PATT
            disp('Full field flashes')
            flash_pattern = 48; % Full field ON - OFF 
            flash_speed = 2; % fps
             
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
            disp('Flashes ended')

            % % Interval after flashes
            disp('Interval')
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

         % Display the number of the current condition
        disp (current_condition);
  
        Log = present_optomotor_stimulus(current_condition, all_conditions, vidobj, d);
        
        % Add the 'Log' from each condition to the overall log 'LOG'.
        fieldName = sprintf('log_%d', log_n);
        LOG.(fieldName) = Log;

        log_n = log_n+1;
     end
end 


%% Acclim at the end 
% Record the behaviour of the flies without any lights on in the arena
% after running the stimulus. 
LOG = present_acclim_off(LOG, vidobj, t_pause, t_acclim_end, 2, d);

%% stop camera
vidobj.stopCapture();
disp('Camera OFF')

% get end temp
[t_outside_end, t_ring_end] = get_temp_rec(d);

%% add parameters to LOG.meta
LOG.meta.t_acclim_start = t_acclim_start;
LOG.meta.t_flash = t_flash;
LOG.meta.t_acclim_end = t_acclim_end;
LOG.meta.start_temp_outside = t_outside_start;
LOG.meta.start_temp_ring = t_ring_start;
LOG.meta.end_temp_outside = t_outside_end;
LOG.meta.end_temp_ring = t_ring_end;
LOG.meta.cond_array = all_conditions;
LOG.meta.random_order = random_order;

%% save LOG file
log_fname =  fullfile(exp_folder, strcat('LOG_', string(date_str), '_', t_str, '.mat'));
save(log_fname, 'LOG');
disp('Log saved') 

% Add notes at the end:
prompt = "Notes at end: ";
notes_str_end = input(prompt, 's');
params.NotesEnd = notes_str_end;

% Export to the google sheet log:
export_to_google_sheets(params)

% clear temp
clear d ch1

