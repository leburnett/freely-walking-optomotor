function Log = present_optomotor_stimulus_diff_contrasts(current_condition, all_conditions, vidobj, d)

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

 contrast_levels = [0.11 0.2 0.333 0.4 0.556 0.75 1.0];

t_stim = trial_len*2; %30;
t_pause = 0.01;

num_trials = t_stim/trial_len; 

idx_value = 1;

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
    Panel_com('set_position', [1 which_condition]);
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
    Log.contrast = contrast_levels(which_condition);

    idx_value = idx_value+1;

end

%% Flicker pattern 
disp('Interval')
Panel_com('set_pattern_id', interval_pattern);

% set dir_val as positive (1)
dir_val = 0;

% Log
Log.trial(idx_value) = idx_value;
Log.dir(idx_value) = dir_val;

Panel_com('send_gain_bias', [interval_speed 0 0 0]); 
pause(t_pause);
Panel_com('set_position', [1 which_condition]);
pause(t_pause);
Panel_com('start'); 
pause(t_pause);

% get frame and log it
Log.start_t(idx_value) = vidobj.getTimeStamp().value;
Log.start_f(idx_value) = vidobj.getFrameCount().value;

pause(interval_dur); 
Panel_com('stop'); 

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

