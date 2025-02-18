function Log = present_optomotor_stimulus_curtain(current_condition, all_conditions, vidobj)

% set condition variables based on row in all conditions
 optomotor_pattern = all_conditions(current_condition, 1);
 flicker_pattern = all_conditions(current_condition, 2);
 optomotor_speed = all_conditions(current_condition, 3);
 flicker_speed = all_conditions(current_condition, 4);
 trial_len = all_conditions(current_condition, 5);
 which_condition = all_conditions(current_condition, 6);

t_flicker = 30; 
t_pause = 0.015;

if trial_len == 2
    num_trials = 15;
elseif trial_len == 15
    num_trials = 2;
end

idx_value = 1;
%%%%% 

% Set the pattern number
Panel_com('set_pattern_id', optomotor_pattern); pause(t_pause)

% Start stimulus 
dir_val = -1;

for tr_ind = 1:num_trials

    % If the pattern is a 'curtain' pattern - then change to the other
    % pattern for the opposite direction.
    if tr_ind == 2 && which_condition > 2 % For the reverse direction of a 'curtain' stimulus.

        if optomotor_pattern == 19
            reverse_pattern = 20; 
        elseif optomotor_pattern == 20 
            reverse_pattern = 19;
        end 
        
        Panel_com('set_pattern_id', reverse_pattern); pause(t_pause)
    end 

    disp(['trial number = ' num2str(tr_ind)])

    dir_val = dir_val*-1;

    % Log
    Log.trial(idx_value) = idx_value;
    Log.dir(idx_value) = dir_val;

    Panel_com('send_gain_bias', [optomotor_speed*dir_val 0 0 0]);
    pause(t_pause);
    Panel_com('set_position', [1 1]);
    pause(t_pause);
    Panel_com('start'); 
    pause(t_pause);

    % get frame and log it
    Log.start_t(idx_value) = vidobj.getTimeStamp().value;
    Log.start_f(idx_value) = vidobj.getFrameCount().value;

    pause(trial_len); % The pattern will run for this ‘Time’
    pause(t_pause); 
    Panel_com('stop'); 
    pause(t_pause);

    % get frame and log it 
    Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
    Log.stop_f(idx_value) = vidobj.getFrameCount().value;

    % Protocol parameters:
    Log.trial_len=trial_len;
    Log.t_flicker=t_flicker;
    Log.num_trials=num_trials;
    Log.optomotor_pattern = optomotor_pattern;
    Log.flicker_pattern = flicker_pattern;
    Log.optomotor_speed = optomotor_speed;
    Log.flicker_speed = flicker_speed;
    Log.which_condition = which_condition;

    idx_value = idx_value+1;

end

%% Flicker pattern 
disp('trial number = flicker 1')
% Panel_com('set_pattern_id', flicker_pattern);
Panel_com('all_off');
% idx_value = idx_value+1;
% set dir_val as positive (1)
dir_val = 0;

% Log
Log.trial(idx_value) = idx_value;
Log.dir(idx_value) = dir_val;

% Panel_com('send_gain_bias', [flicker_speed 0 0 0]); 
% pause(t_pause);
% Panel_com('set_position', [1 1]);
% pause(t_pause);
% Panel_com('start'); 
% pause(t_pause);

% get frame and log it
Log.start_t(idx_value) = vidobj.getTimeStamp().value;
Log.start_f(idx_value) = vidobj.getFrameCount().value;

pause(t_flicker); 
% pause(t_pause); % The pattern will run for this ‘Time’
% Panel_com('stop'); 
% pause(t_pause);

% % get frame and log it 
Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
Log.stop_f(idx_value) = vidobj.getFrameCount().value;
controller_mode = [0 0];
Panel_com('set_mode',controller_mode); pause(t_pause)

end

