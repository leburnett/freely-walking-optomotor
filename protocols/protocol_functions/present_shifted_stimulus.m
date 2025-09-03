function Log = present_shifted_stimulus(current_condition, all_conditions, vidobj)

% set condition variables based on row in all conditions
 optomotor_pattern = all_conditions(current_condition, 1);
 optomotor_speed = all_conditions(current_condition, 2);
 trial_len = all_conditions(current_condition, 3);
 which_condition = all_conditions(current_condition, 4);

t_flicker = 30;
t_pause = 0.015;

if trial_len == 2
    num_trials = 15;
elseif trial_len == 15
    num_trials = 2;
end

idx_value = 1;

%%%%% 

controller_mode = [0 0]; % double open loop
Panel_com('set_mode',controller_mode); pause(t_pause)

%%%%% 

Panel_com('set_pattern_id', optomotor_pattern); pause(t_pause)

% Start stimulus 
dir_val = -1;
for tr_ind = 1:num_trials

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
    Log.optomotor_speed = optomotor_speed;
    Log.which_condition = which_condition;

    idx_value = idx_value+1;

end

%% ALL OFF inbetween 
disp('trial number = OFF')
Panel_com('all_off');

% idx_value = idx_value+1;
% set dir_val as positive (1)
dir_val = 0;

% Log
Log.trial(idx_value) = idx_value;
Log.dir(idx_value) = dir_val;

% get frame and log it
Log.start_t(idx_value) = vidobj.getTimeStamp().value;
Log.start_f(idx_value) = vidobj.getFrameCount().value;

pause(t_flicker); 

% % get frame and log it 
Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
Log.stop_f(idx_value) = vidobj.getFrameCount().value;

end

