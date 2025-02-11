%Protocol_21.m  - follow up protocol 1 after protocol 19 double effector test screen. 
% Based on protocol 19
% Includes:
% - greyscale interval frame. 
% - slower curtain stimuli
% - fast grating stimuli 
% - slower grating stimuli.

% Created new:
% - greyscale background pattern for interval
% - 30 deg and 60 deg grating patterns that move by 2 pixels every frame
% instead of 1 in order to mimic double the speed. 

clear 

% Initialize the temperature recording.
d = initialize_temp_recording();

% Protocol parameters: 
t_acclim = 20; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
t_pause = 0.015;

% [pattern_id, interval_id, speed_patt, speed_int, trial_dur, condition_n]
all_conditions = [ 
    27, 29, 64, 1, 15, 1; % grating - 60 deg
    27, 29, 127, 1, 15, 2;
    26, 29, 64, 1, 15, 3; % grating - 30 deg - - 3
    26, 29, 127, 1, 15, 4; % - - 4
    19, 29, 16, 1, 15, 5; % ON curtain - - 5
    19, 29, 32, 1, 15, 6; % - - 6
    20, 29, 16, 1, 15, 7; % OFF curtain - - 7
    20, 29, 32, 1, 15, 8; % - - 8
    10, 29, 4, 1, 15, 9; % Flicker as a stimulus - 60 deg - slow
    10, 29, 8, 1, 15, 10; % Flicker as a stimulus - 60 deg - fast
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
LOG = present_acclim_off(LOG, vidobj, t_pause, t_acclim, 1);

%% Present stimuli
log_n = 1;

% Run through all 8 conditions twice
for j = [1,2] 

    %start LOOP
     for i = 1:num_conditions
         % get the current condition
         current_condition = random_order(i);
         disp (current_condition);

         if j == 1 && i == 1

            optomotor_pattern = all_conditions(current_condition, 1);
             
            % % ACCLIM PATT
            disp('Pattern ON')
            pause(t_pause)
            acclim_patt.condition = random_order(1);
            acclim_patt.optomotor_pattern = optomotor_pattern;
            acclim_patt.dir = 0;
            acclim_patt.start_t = vidobj.getTimeStamp().value;
            acclim_patt.start_f = vidobj.getFrameCount().value;
            
            Panel_com('set_mode',controller_mode); pause(t_pause)
            Panel_com('set_pattern_id', optomotor_pattern); pause(t_pause)
            Panel_com('set_position', [1 1]); pause(t_pause)
            pause(t_acclim); 
            acclim_patt.stop_t = vidobj.getTimeStamp().value;
            acclim_patt.stop_f = vidobj.getFrameCount().value;

            LOG.acclim_patt = acclim_patt;
            disp('Acclim ended')

         end 
    
        if current_condition < 5 || current_condition > 8
            Log = present_optomotor_stimulus(current_condition, all_conditions, vidobj);
            % Add the 'Log' from each condition to the overall log 'LOG'.
            fieldName = sprintf('log_%d', log_n);
            LOG.(fieldName) = Log;
        else
            Log = present_optomotor_stimulus_curtain(current_condition, all_conditions, vidobj);
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
LOG = present_acclim_off(LOG, vidobj, t_pause, t_acclim, 2);

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

%% save LOG file
log_fname =  fullfile(exp_folder, strcat('LOG_', string(date_str), '_', t_str, '.mat'));
save(log_fname, 'LOG');
disp('Log saved')

% clear temp
clear d ch1

