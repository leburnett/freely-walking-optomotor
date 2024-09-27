function Log = present_optomotor_stimulus(current_condition, all_conditions, vidobj)

% set condition variables based on row in all conditions
 optomotor_pattern = all_conditions(current_condition, 1);
 flicker_pattern = all_conditions(current_condition, 2);
 optomotor_speed = all_conditions(current_condition, 3);
 flicker_speed = all_conditions(current_condition, 4);
 trial_len = all_conditions(current_condition, 5);

 % disp (optomotor_pattern); 
 % disp (flicker_pattern);
 % disp (optomotor_speed);
 % disp (flicker_speed);
 % disp (trial_len);

t_flicker = 30;

if trial_len == 2
    num_trials = 30;
elseif trial_len == 20
    num_trials = 3;
end

idx_value = 1;
%%%%% 

Panel_com('set_pattern_id', optomotor_pattern); pause(0.01)

% Start stimulus 
dir_val = -1;
for tr_ind = 1:num_trials

    disp(['trial number = ' num2str(tr_ind)])

    dir_val = dir_val*-1;
    
    % Log
    Log.trial(idx_value) = idx_value;
    Log.dir(idx_value) = dir_val;

    Panel_com('send_gain_bias', [optomotor_speed*dir_val 0 0 0]);
    pause(0.01);
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

    % Protocol parameters:
    Log.trial_len=trial_len;
    Log.t_flicker=t_flicker;
    Log.num_trials=num_trials;
    Log.optomotor_pattern = optomotor_pattern;
    Log.flicker_pattern = flicker_pattern;
    Log.optomotor_speed = optomotor_speed;
    Log.flicker_speed = flicker_speed;

    idx_value = idx_value+1;

end

%% Flicker pattern 
disp('trial number = flicker 1')
Panel_com('set_pattern_id', flicker_pattern);

% idx_value = idx_value+1;
% set dir_val as positive (1)
dir_val = 0;

% Log
Log.trial(idx_value) = idx_value;
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

% % get frame and log it 
Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
Log.stop_f(idx_value) = vidobj.getFrameCount().value;

end

