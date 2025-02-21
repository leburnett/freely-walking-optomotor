function Log = present_fixation_stimulus(current_condition, all_conditions, vidobj)
% For the presentation of the bar stimuli at 180 degrees apart. 
% Only show the first frame (bar positions) for 60s. 

% set condition variables based on row in all conditions
 optomotor_pattern = all_conditions(current_condition, 1);
 interval_pattern = all_conditions(current_condition, 2);
 optomotor_speed = all_conditions(current_condition, 3);
 interval_speed = all_conditions(current_condition, 4);
 trial_len = all_conditions(current_condition, 5);
 interval_dur = all_conditions(current_condition, 6);
 which_condition = all_conditions(current_condition, 7);

t_pause = 0.01; % Duration in seconds to pause to give the controller time.
idx_value = 1;

% Set the pattern number:
Panel_com('set_pattern_id', optomotor_pattern); pause(t_pause)

% Log
Log.trial(idx_value) = idx_value;
Log.dir(idx_value) = 1; 

Panel_com('send_gain_bias', [0 0 0 0]); % set speed as zero. 
pause(t_pause);
Panel_com('set_position', [1 1]); % set frame - frame 1. 
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
Log.optomotor_pattern = optomotor_pattern;
Log.interval_pattern = interval_pattern;
Log.optomotor_speed = optomotor_speed;
Log.interval_speed = interval_speed;
Log.which_condition = which_condition;

% Add one to save the interval info in the log
idx_value = idx_value +1;

%% GRATINGS INTERVAL:
disp('Interval')
Panel_com('set_pattern_id', interval_pattern);

% Log
Log.trial(idx_value) = idx_value;
Log.dir(idx_value) = 0;

Panel_com('send_gain_bias', [interval_speed 0 0 0]); 
pause(t_pause);
Panel_com('set_position', [1 1]);
pause(t_pause);
Panel_com('start'); 
pause(t_pause);

% get frame and log it
Log.start_t(idx_value) = vidobj.getTimeStamp().value;
Log.start_f(idx_value) = vidobj.getFrameCount().value;

% Set duration of interval
pause(interval_dur); 

Panel_com('stop'); 
pause(t_pause);

% % get frame and log it 
Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
Log.stop_f(idx_value) = vidobj.getFrameCount().value;

end

