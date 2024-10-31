function plot_one_log_dist_seq_AD(current_log, feat, trx, title_str)

%% current_log 
    % pass in one of the sub logs that will be used to snip the trx and
    % feat data

%% feat
%% trx

% use for testing
% cd('C:\Users\deva\Documents\projects\oakey_cokey\data\2024_10_23\protocol_10\csw1118\F\14_44_21')
% load("LOG_2024_10_23_14_44_21.mat")
% current_log = LOG.log_8;
% title_str = '4pix, 64hx';
% figure;

% fixed_parameters
n_flies = length(trx);

fps = 30;
samp_rate = 1/fps; 
method = 'line_fit';
t_window = 16;
cutoff = [];

% plot the log's information in one log that you will bring into a subplot
% later

%%%%%% distance data %%%%%%%%%

current_start_f = min(current_log.start_f);
current_stop_f = max(current_log.stop_f);

flicker_start = max(current_log.start_f) - current_start_f;

dist_data = feat.data(:, current_start_f:current_stop_f, 9);
dist_data = 120-dist_data;

n_conditions = size(current_log.start_t, 2);

hold on

% add blue lines at each start and stop point for the conditions
for i = 1:n_conditions - 1
    temp_start_f = current_log.start_f(i) - current_start_f;
    xline(temp_start_f, '-b', 'LineWidth', 1);
end

for idx = 1:n_flies
  % Plot the distance from the centre per fly
    plot(dist_data(idx, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5)
end 

ylim([-15 135])
xlim([0, 1880])
% plot([0 current_log.stop_f(end)], [120 120], 'LineWidth', 1, 'Color', [0.7 0.7 0.7])
% plot([0 current_log.stop_f(end)], [0 0], 'LineWidth', 1, 'Color', [0.7 0.7 0.7])

% plot(mean(dist_data), 'k', 'LineWidth', 1)

title(title_str);

xline(flicker_start, '--r', 'LineWidth', 1);
% xlabel('time (f)')
% ylabel('distance (mm)')

% hold off

end
