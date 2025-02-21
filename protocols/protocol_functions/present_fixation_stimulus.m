function Log = present_fixation_stimulus(current_condition, all_conditions, vidobj)
% Used to display bar fixation pattern.
% We only really care about 'trial' length here. 
% The bar fixation pattern should only have 2 frames. 
% Show frame 1 for 'trial_len' then show frame 2 for 'trial_len'.

% THis

% set condition variables based on row in all conditions
 optomotor_pattern = all_conditions(current_condition, 1);
 flicker_pattern = all_conditions(current_condition, 2);
 optomotor_speed = all_conditions(current_condition, 3);
 flicker_speed = all_conditions(current_condition, 4);
 trial_len = all_conditions(current_condition, 5);
 interval_dur = all_conditions(current_condition, 6);
 which_condition = all_conditions(current_condition, 7);

t_interval = interval_dur; 
t_stim = trial_len*2; %30;
t_pause = 0.015;

num_trials = t_stim/trial_len; 
% if trial_len == 2
%     num_trials = 15;
% elseif trial_len == 15
%     num_trials = 2;
% end

idx_value = 1;
%%%%% 

Panel_com('set_pattern_id', optomotor_pattern); pause(t_pause)

% Start stimulus 
dir_val = -1;
for tr_ind = 1:num_trials

    disp(['trial number = ' num2str(tr_ind)])

    dir_val = dir_val*-1;
    % if dir_val > 0 
    %     frame_id = 1;
    % elseif dir_val < 0 
    %     frame_id = 2;
    % end 

    % Log
    Log.trial(idx_value) = idx_value;
    Log.dir(idx_value) = dir_val; % set direction as frame_id

    Panel_com('send_gain_bias', [0 0 0 0]); % set speed as zero. 
    pause(t_pause);
    Panel_com('set_position', [tr_ind 1]); % set frame
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
    Log.t_flicker=t_interval;
    Log.num_trials=num_trials;
    Log.optomotor_pattern = optomotor_pattern;
    Log.flicker_pattern = flicker_pattern;
    Log.optomotor_speed = optomotor_speed;
    Log.flicker_speed = flicker_speed;
    Log.which_condition = which_condition;

    idx_value = idx_value+1;

end

%% ALL OFF INTERVAL: 
% disp('trial number = all off interval')
% Panel_com('all_off');
% 
% % set dir_val as positive (1)
% dir_val = 0;
% 
% % Log
% Log.trial(idx_value) = idx_value;
% Log.dir(idx_value) = dir_val;
% 
% % get frame and log it
% Log.start_t(idx_value) = vidobj.getTimeStamp().value;
% Log.start_f(idx_value) = vidobj.getFrameCount().value;
% 
% % Set duration of interval
% pause(t_flicker); 
% 
% % % get frame and log it 
% Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
% Log.stop_f(idx_value) = vidobj.getFrameCount().value;
% % We need this to tell the controller to turn on again. 
% controller_mode = [0 0];
% Panel_com('set_mode',controller_mode); pause(t_pause)

%% GRATINGS INTERVAL:
disp('trial number = gratings interval')
Panel_com('set_pattern_id', flicker_pattern);

% set dir_val as positive (1)
dir_val = 1;

% Log
Log.trial(idx_value) = idx_value;
Log.dir(idx_value) = dir_val;

Panel_com('send_gain_bias', [flicker_speed 0 0 0]); 
pause(t_pause);
Panel_com('set_position', [1 1]);
pause(t_pause);
Panel_com('start'); 
pause(t_pause);

% get frame and log it
Log.start_t(idx_value) = vidobj.getTimeStamp().value;
Log.start_f(idx_value) = vidobj.getFrameCount().value;

% Set duration of interval
pause(t_interval); 

Panel_com('stop'); 
pause(t_pause);

% % get frame and log it 
Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
Log.stop_f(idx_value) = vidobj.getFrameCount().value;

end

