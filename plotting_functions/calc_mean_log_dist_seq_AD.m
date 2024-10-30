function mean_dist_data = calc_mean_log_dist_seq_AD(current_log, feat, trx, title_str)


% use for testing
current_log = LOG.log_8;
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

current_start_f = min(current_log.start_f);
current_stop_f = max(current_log.stop_f);

flicker_start = max(current_log.start_f) - current_start_f;

dist_data = feat.data(:, current_start_f:current_stop_f, 9);
dist_data = 120-dist_data;

n_conditions = size(current_log.start_t, 2);

mean_dist_data = mean(dist_data);

end
