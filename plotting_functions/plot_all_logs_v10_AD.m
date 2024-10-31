% script to process all logs in v10 protocol


% have to basically cycle through all of the logs and run
% plot_all_logs_seq_AD() to plot into different subplots

% for testing
cd('C:\Users\deva\Documents\projects\oakey_cokey\results\protocol_10\csw1118\F')
load("2024_10_23_14_44_21_data.mat");

log_names = fieldnames(LOG);

% loop through all of the logs and change current_log

% % % % % DISTANCE FROM CENTER % % % % % 

count = 0;
figure;
hold on

% plot colored rectangles



%%%%%%

% plot all flies

for i = 4:(length(log_names) - 1)
    current_log_name = log_names{i};
    current_log = LOG.(log_names{i});
    current_n_conditions = size(current_log.start_t, 2);
    
    % determine which condition it is to put into title_subplot
    if current_log.optomotor_pattern == 4 && current_log.optomotor_speed == 64 && current_log.trial_len == 2
        current_condition_name = '1. 4pix, 64hz';
    elseif current_log.optomotor_pattern == 4 && current_log.optomotor_speed == 127 && current_log.trial_len == 15
        current_condition_name = '2. 4pix, 127hz';
    elseif current_log.optomotor_pattern == 4 && current_log.optomotor_speed == 64 && current_log.trial_len == 15
        current_condition_name = '3. 4pix, 64hz';   
    elseif current_log.optomotor_pattern == 4 && current_log.optomotor_speed == 127 && current_log.trial_len == 2
        current_condition_name = '4. 4pix, 127hz';
    elseif current_log.optomotor_pattern == 6 && current_log.optomotor_speed == 64 && current_log.trial_len == 2
        current_condition_name = '5. 8pix, 64hz';
    elseif current_log.optomotor_pattern == 6 && current_log.optomotor_speed == 127 && current_log.trial_len == 15
        current_condition_name = '6. 8pix, 127hz';
    elseif current_log.optomotor_pattern == 6 && current_log.optomotor_speed == 64 && current_log.trial_len == 15
        current_condition_name = '7. 8pix, 64hz';   
    elseif current_log.optomotor_pattern == 6 && current_log.optomotor_speed == 127 && current_log.trial_len == 2
        current_condition_name = '8. 8pix, 127hz';
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

    subplot(4, 2, position);

    plot_one_log_dist_seq_AD(current_log, feat, trx, current_condition_name);
    
    % han = axes(figure,'visible','off'); % Create an invisible axis
    % han.XLabel.Visible = 'on';
    % han.YLabel.Visible = 'on';
    % xlabel(han, 'time (frames)');
    % ylabel(han, 'dist-from-center (mm)');

end

% plot mean of all flies

% calculate and plot mean for 1/9, 2/10, 3/11, 4/12, 5/13, 6/14, 7/15, 9/16
hold on

subplot(4, 2, 1)
m1 = calc_mean_log_dist_seq_AD(LOG.log_1, LOG.log_9, feat, trx);
plot(m1, 'k', 'LineWidth', 1);

subplot(4, 2, 2)
m2 = calc_mean_log_dist_seq_AD(LOG.log_2, LOG.log_10, feat, trx);
plot(m2, 'k', 'LineWidth', 1);

subplot(4, 2, 3)
m3 = calc_mean_log_dist_seq_AD(LOG.log_3, LOG.log_11, feat, trx);
plot(m3, 'k', 'LineWidth', 1);

subplot(4, 2, 4)
m4 = calc_mean_log_dist_seq_AD(LOG.log_4, LOG.log_12, feat, trx);
plot(m4, 'k', 'LineWidth', 1);

subplot(4, 2, 5)
m5 = calc_mean_log_dist_seq_AD(LOG.log_5, LOG.log_13, feat, trx);
plot(m5, 'k', 'LineWidth', 1);

subplot(4, 2, 6)
m6 = calc_mean_log_dist_seq_AD(LOG.log_6, LOG.log_14, feat, trx);
plot(m6, 'k', 'LineWidth', 1);

subplot(4, 2, 7)
m7 = calc_mean_log_dist_seq_AD(LOG.log_7, LOG.log_15, feat, trx);
plot(m7, 'k', 'LineWidth', 1);

subplot(4, 2, 8)
m8 = calc_mean_log_dist_seq_AD(LOG.log_8, LOG.log_16, feat, trx);
plot(m8, 'k', 'LineWidth', 1);

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