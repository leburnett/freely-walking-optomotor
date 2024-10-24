% script to process all logs in v10 protocol


% have to basically cycle through all of the logs and run
% plot_all_logs_seq_AD() to plot into different subplots

% for testing
cd('C:\Users\deva\Documents\projects\oakey_cokey\results\Protocol_v10_all_tests\CS_w1118');
load("2024_10_03_11_19_53_data.mat");

log_names = fieldnames(LOG);

% loop through all of the logs and change current_log

% % % % % DISTANCE FROM CENTER % % % % % 

count = 0;
figure;
hold on

for i = 4:(length(log_names) - 1)
    current_log_name = log_names{i};
    current_log = LOG.(log_names{i});
    current_n_conditions = size(current_log.start_t, 2);
    
    % determine which condition it is to put into title_subplot
    if current_log.optomotor_pattern == 4 && current_log.optomotor_speed == 64 && current_log.trial_len == 2
        current_condition_name = '1. thin, slow, short';
    elseif current_log.optomotor_pattern == 4 && current_log.optomotor_speed == 127 && current_log.trial_len == 15
        current_condition_name = '2. thin, fast, long';
    elseif current_log.optomotor_pattern == 4 && current_log.optomotor_speed == 64 && current_log.trial_len == 15
        current_condition_name = '3. thin, slow, long';   
    elseif current_log.optomotor_pattern == 4 && current_log.optomotor_speed == 127 && current_log.trial_len == 2
        current_condition_name = '4. thin, fast, short';
    elseif current_log.optomotor_pattern == 6 && current_log.optomotor_speed == 64 && current_log.trial_len == 2
        current_condition_name = '5. thick, slow, short';
    elseif current_log.optomotor_pattern == 6 && current_log.optomotor_speed == 127 && current_log.trial_len == 15
        current_condition_name = '6. thick, fast, long';
    elseif current_log.optomotor_pattern == 6 && current_log.optomotor_speed == 64 && current_log.trial_len == 15
        current_condition_name = '7. thick, slow, long';   
    elseif current_log.optomotor_pattern == 6 && current_log.optomotor_speed == 127 && current_log.trial_len == 2
        current_condition_name = '8. thick, fast, short';
    end

    count = count + 1;

    % Determine the correct position
    if count <= 8
        % Fill the first column (positions 1 to 8)
        position = count;
    else
        % Fill the second column (positions 9 to 16)
        position = count - 8; % Shift positions by 8 to move to second column
    end

    subplot(8, 1, position);

    plot_one_log_dist_seq_AD(current_log, feat, trx, current_condition_name);
    
    % han = axes(figure,'visible','off'); % Create an invisible axis
    % han.XLabel.Visible = 'on';
    % han.YLabel.Visible = 'on';
    % xlabel(han, 'time (frames)');
    % ylabel(han, 'dist-from-center (mm)');

end

sgtitle(strcat('V10-distance-from-center'))

hold off
% % % % % ANGULAR VELOCITY % % % % % 

count = 0;
figure; 
hold on
for i = 4:(length(log_names) - 1)
    current_log_name = log_names{i};
    current_log = LOG.(log_names{i});
    current_n_conditions = size(current_log.start_t, 2);
    
    % determine which condition it is to put into title_subplot
    if current_log.optomotor_pattern == 4 && current_log.optomotor_speed == 64 && current_log.trial_len == 2
        current_condition_name = '1. thin, slow, short';
    elseif current_log.optomotor_pattern == 4 && current_log.optomotor_speed == 127 && current_log.trial_len == 15
        current_condition_name = '2. thin, fast, long';
    elseif current_log.optomotor_pattern == 4 && current_log.optomotor_speed == 64 && current_log.trial_len == 15
        current_condition_name = '3. thin, slow, long';   
    elseif current_log.optomotor_pattern == 4 && current_log.optomotor_speed == 127 && current_log.trial_len == 2
        current_condition_name = '4. thin, fast, short';
    elseif current_log.optomotor_pattern == 6 && current_log.optomotor_speed == 64 && current_log.trial_len == 2
        current_condition_name = '5. thick, slow, short';
    elseif current_log.optomotor_pattern == 6 && current_log.optomotor_speed == 127 && current_log.trial_len == 15
        current_condition_name = '6. thick, fast, long';
    elseif current_log.optomotor_pattern == 6 && current_log.optomotor_speed == 64 && current_log.trial_len == 15
        current_condition_name = '7. thick, slow, long';   
    elseif current_log.optomotor_pattern == 6 && current_log.optomotor_speed == 127 && current_log.trial_len == 2
        current_condition_name = '8. thick, fast, short';
    end

    count = count + 1;

    % Determine the correct position
    if count <= 8
        % Fill the first column (positions 1 to 8)
        position = count;
    else
        % Fill the second column (positions 9 to 16)
        position = count - 8; % Shift positions by 8 to move to second column
    end

    subplot(8, 1, position);

    plot_one_log_ang_vel_seq_AD(current_log, feat, trx, current_condition_name);



end

sgtitle(strcat('V10-angvel'))

hold off
% % Create an invisible axis that spans the whole figure
% han = axes(figure, 'visible', 'off'); 
% han.XLabel.Visible = 'on';
% han.YLabel.Visible = 'on';
% 
% % Set the shared x-axis and y-axis labels
% xlabel(han, 'time (f)', 'FontSize', 16, 'FontWeight', 'bold');
% ylabel(han, 'ang-vel (rad/s)', 'FontSize', 16, 'FontWeight', 'bold');
% sgtitle(strcat('V10-ANG-VEL', ' - n='));
% 
% hold off

% sgtitle(strcat('V10-distance-from-center', ' - N=', string(n_flies)))







% current_log = log_2;
% 
% plot_all_logs_seq_AD(LOG.log_4, feat, trx, 'log2')