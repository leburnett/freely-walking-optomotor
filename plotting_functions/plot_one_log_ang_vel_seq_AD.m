function plot_one_log_ang_vel_seq_AD(current_log, feat, trx, title_str)

%% current_log 
    % pass in one of the sub logs that will be used to snip the trx and
    % feat data

%% feat
%% trx

% use for testing
% current_log = LOG.log_4;
% title_str = 'log_4';

% fixed_parameters
n_flies = length(trx);

fps = 30;
samp_rate = 1/fps; 
method = 'line_fit';
t_window = 16;
cutoff = [];

% figure;

% plot the log's information in one log that you will bring into a subplot
% later

%%%%%% angular velocity data %%%%%%%%%

current_start_f = min(current_log.start_f);
current_stop_f = max(current_log.stop_f);

ang_vel_data = feat.data(:, current_start_f:current_stop_f, 2);

max_val = max(max(ang_vel_data));
min_val = min(min(ang_vel_data));
h = max_val - min_val;

flicker_start = max(current_log.start_f) - current_start_f;

% subplot(4, 1, 4)

n_conditions = size(current_log.start_t, 2);

hold on

% for ii = 1:n_conditions
% 
%     % Get the timing of each condition
%     st_fr = current_log.start_f(ii);
%     stop_fr = current_log.stop_f(ii)-1;
%     w = stop_fr - st_fr;
% 
%     % Use the Log.dir value to get the stimulus direction.
%     dir_id = current_log.dir(ii);
%     con_val = 1;
%     if con_val > 1.2
%         con_val = 1;
%     end 
% 
%     if dir_id == 0 
%         if ii == 1 || ii == 33
%             col = [0.5 0.5 0.5 0.3];
%         elseif ii == 17 || ii == 32
%             col = [0 0 0 0.3];
%         else
%             col = [1 1 1];
%         end 
% 
%     elseif dir_id == 1
%         col = [0 0 1 con_val*0.75];
%     elseif dir_id == -1
%         col = [1 0 1 con_val*0.75];
%     end 
% 
%     % Plot rectangles in the background of when the stimulus changes. 
%     rectangle('Position', [st_fr, min_val, w, h], 'FaceColor', col, 'EdgeColor', [0.6 0.6 0.6])
%     ylim([min_val, max_val])
%     hold on 
%     box off
%     ax = gca;
%     ax.XAxis.Visible = 'off';
% end 

for idx = 1:n_flies
  % Plot the distance from the centre per fly
    plot(ang_vel_data(idx, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5)
end 

% ylim([-2 2])
% plot([0 current_log.stop_f(end)], [120 120], 'LineWidth', 1, 'Color', [0.7 0.7 0.7])
% plot([0 current_log.stop_f(end)], [0 0], 'LineWidth', 1, 'Color', [0.7 0.7 0.7])

plot(mean(ang_vel_data), 'k', 'LineWidth', 1)

xline(flicker_start, '--r', 'LineWidth', 1);

title(title_str);

hold off

%%%%%% ang_vel_data %%%%%%%%%
end
