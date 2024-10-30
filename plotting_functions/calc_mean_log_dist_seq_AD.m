function mean_dist_data = calc_mean_log_dist_seq_AD(first_log, second_log, feat, trx, title_str)


% use for testing
first_log = LOG.log_1;
second_log = LOG.log_9;
title_str = '4pix, 64hx';
figure;

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

%% for first_log

first_start_f = min(first_log.start_f);
first_stop_f = max(first_log.stop_f);

% flicker_start = max(current_log.start_f) - current_start_f;

dist_data_1 = feat.data(:, first_start_f:first_stop_f, 9);
dist_data_1 = 120-dist_data_1;

%% for second_log
second_start_f = min(second_log.start_f);
second_stop_f = max(second_log.stop_f);

dist_data_2 = feat.data(:, second_start_f:second_stop_f, 9);
dist_data_2 = 120-dist_data_2;

all_dist_data = cell2mat({dist_data_1, dist_data_2}');

mean_dist_data = mean(all_dist_data);

end
