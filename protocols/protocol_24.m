% Protocol_24.m  - Screen protocol 1
% Based on protocol 19

% Includes:
% - off background interval - pattern 47
% - 60 deg gratings - 2 speeds
% - thin non50:50 bars - 2 speeds
% - curtains - fast  - on / off
% - reverse phi - 2 speeds
% - flicker - 2 speeds
% - stationary bars - on / off

% 20s interval
% 30s trial duration - 2x trials
% stationary bars = 60s only one position

clear 
tic
% Initialize the temperature recording.
d = initialize_temp_recording();

% Protocol parameters: 
t_acclim_start = 300; %10; %300; % Make this 300 eventually. 
t_acclim_end = 30; %30;
t_interval = 30; %30;
t_pause = 0.01;

% [pattern_id, interval_id, speed_patt, speed_int, trial_dur, int_dur, condition_n]
all_conditions = [ 
    9, 47, 127, 1, 15, t_interval, 1; %  60 deg gratings - 4Hz - 1 px step pattern
    27, 47, 127, 1, 15, t_interval, 2; % 60 deg gratings - 8Hz - 2px step pattern
    17, 47, 127, 1, 15, t_interval, 3; % 2:14 ON bars - 4Hz
    24, 47, 127, 1, 15, t_interval, 4; % 2:14 OFF bars - 4Hz
    19, 47, 127, 1, 15, t_interval, 5; % ON curtains - 8Hz
    20, 47, 127, 1, 15, t_interval, 6; % OFF curtains - 8Hz
    32, 47, 32, 1, 15, t_interval, 7;  % Reverse Phi - 4px step - 4Hz
    32, 47, 64, 1, 15, t_interval, 8;  % Reverse Phi - 4px step - 8Hz
    10, 47, 8, 1, 15, t_interval, 9;  % Flicker - 4Hz
    10, 47, 16, 1, 15, t_interval, 10; % Flicker - 8Hz
    45, 47, 1, 1, 60, t_interval, 11; % bar fixation - 16px ON
    46, 47, 1, 1, 60, t_interval, 12; % bar fixation - 16px OFF
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
LOG = present_acclim_off(LOG, vidobj, t_pause, t_acclim_start, 1);
disp('Recording behaviour in darkness')

%% Present stimuli
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
            disp('Full field flashes')
            flash_pattern = 48; % Full field ON - OFF 
            flash_speed = 8; % fps
             
            % acclim_patt.condition = optomotor_pattern;
            acclim_patt.optomotor_pattern = flash_pattern;
            acclim_patt.dir = 0;
            acclim_patt.start_t = vidobj.getTimeStamp().value;
            acclim_patt.start_f = vidobj.getFrameCount().value;
            
            Panel_com('set_pattern_id', flash_pattern); pause(t_pause)
            Panel_com('send_gain_bias', [flash_speed 0 0 0]); pause(t_pause)
            Panel_com('set_position', [1 1]); pause(t_pause)
            Panel_com('start'); 
            pause(t_acclim_end); 
            Panel_com('stop'); pause(t_pause); 

            acclim_patt.stop_t = vidobj.getTimeStamp().value;
            acclim_patt.stop_f = vidobj.getFrameCount().value;

            LOG.acclim_patt = acclim_patt;
            disp('Flashes ended')

         end 

         % Display the number of the current condition
        disp (current_condition);
    
        if current_condition > 10 % Bar fixation stimuli
            Log = present_fixation_stimulus(current_condition, all_conditions, vidobj);
            fieldName = sprintf('log_%d', log_n);
            LOG.(fieldName) = Log;
        elseif current_condition == 5 || current_condition == 6
            Log = present_optomotor_stimulus_curtain(current_condition, all_conditions, vidobj);
            fieldName = sprintf('log_%d', log_n);
            LOG.(fieldName) = Log;
        else
            Log = present_optomotor_stimulus(current_condition, all_conditions, vidobj);
            % Add the 'Log' from each condition to the overall log 'LOG'.
            fieldName = sprintf('log_%d', log_n);
            LOG.(fieldName) = Log;
        end

        log_n = log_n+1;
     end
end 


%% Acclim at the end 
% Record the behaviour of the flies without any lights on in the arena
% after running the stimulus. 
LOG = present_acclim_off(LOG, vidobj, t_pause, t_acclim_end, 2);

%% stop camera
vidobj.stopCapture();
disp('Camera OFF')

% get end temp
[t_outside_end, t_ring_end] = get_temp_rec(d);

%% add parameters to LOG.meta
LOG.meta.start_temp_outside = t_outside_start;
LOG.meta.start_temp_ring = t_ring_start;
LOG.meta.end_temp_outside = t_outside_end;
LOG.meta.end_temp_ring = t_ring_end;
LOG.meta.cond_array = all_conditions;

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

toc
% clear temp
clear d ch1

