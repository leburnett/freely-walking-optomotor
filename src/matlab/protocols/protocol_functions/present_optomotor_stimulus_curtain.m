function Log = present_optomotor_stimulus_curtain(current_condition, all_conditions, vidobj, d)

% Get temp at the start:
[t_outside_start, t_ring_start] = get_temp_rec(d);

% set condition variables based on row in all conditions
 optomotor_pattern = all_conditions(current_condition, 1);
 interval_pattern = all_conditions(current_condition, 2);
 optomotor_speed = all_conditions(current_condition, 3);
 interval_speed = all_conditions(current_condition, 4);
 trial_len = all_conditions(current_condition, 5);
 interval_dur = all_conditions(current_condition, 6);
 which_condition = all_conditions(current_condition, 7);

t_pause = 0.01;

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
    % pattern for the opposite direction during the second trial.
    if tr_ind == 2

        switch optomotor_pattern
            case 19
                reverse_pattern = 20; 
            case 20 
                reverse_pattern = 19;
            case 51 
                reverse_pattern = 52;
            case 52 
                reverse_pattern = 51;
            case 53
                reverse_pattern = 54;
            case 55
                reverse_pattern = 56;
            case 56
                reverse_pattern = 55;
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
    Log.interval_dur=interval_dur;
    Log.num_trials=num_trials;
    Log.optomotor_pattern = optomotor_pattern;
    Log.interval_pattern = interval_pattern;
    Log.optomotor_speed = optomotor_speed;
    Log.interval_speed = interval_speed;
    Log.which_condition = which_condition;

    idx_value = idx_value+1;

end

%% Flicker pattern 
disp('Interval')
Panel_com('set_pattern_id', interval_pattern);

dir_val = 0;

% Log
Log.trial(idx_value) = idx_value;
Log.dir(idx_value) = dir_val;

Panel_com('send_gain_bias', [interval_speed 0 0 0]); 
pause(t_pause);
Panel_com('set_position', [1 1]);
pause(t_pause);
Panel_com('start'); 
pause(t_pause);

% get frame and log it
Log.start_t(idx_value) = vidobj.getTimeStamp().value;
Log.start_f(idx_value) = vidobj.getFrameCount().value;

pause(interval_dur); 

Panel_com('stop'); 
pause(t_pause);

% % get frame and log it 
Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
Log.stop_f(idx_value) = vidobj.getFrameCount().value;

% Get the temp at the end
[t_outside_end, t_ring_end] = get_temp_rec(d);

% Log temperature:
Log.t_outside_start = t_outside_start;
Log.t_ring_start = t_ring_start;
Log.t_outside_end = t_outside_end;
Log.t_ring_end = t_ring_end;

end

