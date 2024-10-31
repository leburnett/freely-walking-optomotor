function mean_dist_data = calc_mean_log_dist_seq_AD(first_log, second_log, feat, trx)


% use for testing
% first_log = LOG.log_2;
% second_log = LOG.log_10;
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

%% for first_log

first_start_f = min(first_log.start_f);
first_stop_f = max(first_log.stop_f);

% flicker_start = max(current_log.start_f) - current_start_f;

dist_data_1 = feat.data(:, first_start_f:first_stop_f, 9);
dist_data_1 = 120-dist_data_1;
temp_size_1 = size(dist_data_1, 2);

%% for second_log
second_start_f = min(second_log.start_f);
second_stop_f = max(second_log.stop_f);

dist_data_2 = feat.data(:, second_start_f:second_stop_f, 9);
dist_data_2 = 120-dist_data_2;
temp_size_2 = size(dist_data_2, 2);

% determine if logs are different sizes
if temp_size_1 ~= temp_size_2
    % which is smaller
    if temp_size_1 < temp_size_2
        % set new_size as temp_size_1
        new_size = temp_size_1;
        % change the size of dist_data_2
        dist_data_2 = dist_data_2(:, 1:new_size);
    elseif temp_size_2 < temp_size_1
        % set new_size as temp_size_1
        new_size = temp_size_2;
        % change the size of dist_data_1
        dist_data_1 = dist_data_1(:, 1:new_size);
    end
end


all_dist_data = cell2mat({dist_data_1, dist_data_2}');

mean_dist_data = mean(all_dist_data);
plot(mean_dist_data);

end
