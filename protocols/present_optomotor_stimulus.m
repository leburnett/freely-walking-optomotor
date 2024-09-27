function present_optomotor_stimulus(current_condition, all_conditions)

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

% Add 'if' clause for trial_len
if trial_len == 2
    num_trials = 30;
elseif trial_len == 20
    num_trials = 3;
end
%%%%% 

Panel_com('set_pattern_id', optomotor_pattern); pause(0.01)

% Start stimulus 
dir_val = -1;
for tr_ind = 1:num_trials

    disp(['trial number = ' num2str(tr_ind)])

    % If not the first trial then add one to idx_value
    % if idx_value > 1
    %     idx_value = idx_value+1;
    % end 
    dir_val = dir_val*-1;
    
    % Log
    % Log.trial(idx_value) = idx_value;
    % Log.dir(idx_value) = dir_val;

    Panel_com('send_gain_bias', [optomotor_speed*dir_val 0 0 0]);
    pause(0.01);
    Panel_com('set_position', [1 1]);
    pause(0.01);
    Panel_com('start'); 
    pause(0.01);

    % get frame and log it
    % Log.start_t(idx_value) = vidobj.getTimeStamp().value;
    % Log.start_f(idx_value) = vidobj.getFrameCount().value;

    pause(trial_len); % The pattern will run for this ‘Time’
    pause(0.01); 
    Panel_com('stop'); 
    pause(0.01);

    % get frame and log it 
    % Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
    % Log.stop_f(idx_value) = vidobj.getFrameCount().value;

    % Add one to idx_value 
    % idx_value = idx_value+1;
    % set dir_val as opposite (-1)
    % dir_val = -1;

    % Log
    % Log.trial(idx_value) = idx_value;
    % Log.dir(idx_value) = dir_val;

    % Panel_com('send_gain_bias', [optomotor_speed*dir_val 0 0 0]); 
    % pause(0.01);
    % Panel_com('set_position', [1 1]);
    % pause(0.01);
    % Panel_com('start'); 
    % pause(0.01);
    % 
    %  % get frame and log it 
    % % Log.start_t(idx_value) = vidobj.getTimeStamp().value;
    % % Log.start_f(idx_value) = vidobj.getFrameCount().value;
    % 
    % pause(trial_len); 
    % pause(0.01); % The pattern will run for this ‘Time’
    % Panel_com('stop'); 
    % pause(0.01);

    % % get frame and log it 
    % Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
    % Log.stop_f(idx_value) = vidobj.getFrameCount().value;

end

%% Flicker pattern 
disp('trial number = flicker 1')
Panel_com('set_pattern_id', flicker_pattern);

% idx_value = idx_value+1;
% set dir_val as positive (1)
% dir_va-+----l = 0;

% Log
% Log.trial(idx_value) = idx_value;
% Log.dir(idx_value) = dir_val;

Panel_com('send_gain_bias', [flicker_speed 0 0 0]); 
pause(0.01);
Panel_com('set_position', [1 1]);
pause(0.01);
Panel_com('start'); 
pause(0.01);

% get frame and log it
% Log.start_t(idx_value) = vidobj.getTimeStamp().value;
% Log.start_f(idx_value) = vidobj.getFrameCount().value;

pause(t_flicker); 
pause(0.01); % The pattern will run for this ‘Time’
Panel_com('stop'); 
pause(0.01);

% % get frame and log it 
% Log.stop_t(idx_value) = vidobj.getTimeStamp().value;
% Log.stop_f(idx_value) = vidobj.getFrameCount().value;



