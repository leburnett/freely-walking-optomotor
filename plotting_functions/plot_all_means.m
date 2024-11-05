% script to plot 2 plots (one for 15 trials one for 2 trials)

% for testing
cd('C:\Users\deva\Documents\projects\oakey_cokey\results\protocol_10\csw1118\F')
load("2024_10_23_14_44_21_data.mat");

log_names = fieldnames(LOG);

%%%%%%%% plot all means in one plot, different colors and intensities %%%%%

% calculate the means
all_means.m1 = calc_mean_log_dist_seq_AD(LOG.log_1, LOG.log_9, feat, trx);
all_means.m2 = calc_mean_log_dist_seq_AD(LOG.log_2, LOG.log_10, feat, trx);
all_means.m3 = calc_mean_log_dist_seq_AD(LOG.log_3, LOG.log_11, feat, trx);
all_means.m4 = calc_mean_log_dist_seq_AD(LOG.log_4, LOG.log_12, feat, trx);
all_means.m5 = calc_mean_log_dist_seq_AD(LOG.log_5, LOG.log_13, feat, trx);
all_means.m6 = calc_mean_log_dist_seq_AD(LOG.log_6, LOG.log_14, feat, trx);
all_means.m7 = calc_mean_log_dist_seq_AD(LOG.log_7, LOG.log_15, feat, trx);
all_means.m8 = calc_mean_log_dist_seq_AD(LOG.log_8, LOG.log_16, feat, trx);

mean_names = fieldnames(all_means);

opt_patt = {};
opt_speed = {};
num_tri = {};

figure;

% f_15tri = figure;
% f_2tri = figure;

for i = 4:11
    current_log_name = log_names{i};
    current_log = LOG.(log_names{i});
    current_n_conditions = size(current_log.start_t, 2);
    
    % save opt_patt, opt_speed, num_tri
    opt_patt{end+1} = current_log.optomotor_pattern;
    opt_speed{end+1} = current_log.optomotor_speed;
    num_tri{end+1} = current_log.num_trials;
end

% plot pink and blue rectangles
for ii = 4:11

    current_log_name = log_names{ii};
    current_log = LOG.(log_names{ii});
    
    min_val = 0;
    max_val = 120;
    if current_log.num_trials == 15
        subplot(2, 1, 1);
        plot_pink_blue_rects_AD(current_log, min_val, max_val, 0);
        xlim([0, 1800])
    elseif current_log.num_trials == 2
        subplot(2, 1, 2);
        plot_pink_blue_rects_AD(current_log, min_val, max_val, 0);
        xlim ([0, 1800])
    end
end

for j = 1:length(opt_patt)

    if num_tri{j} == 15
        pos = 1;
    else 
        pos = 2;
    end

    hold on

    current_mean = all_means.(mean_names{j});
    current_opt_patt = opt_patt{j};
    current_opt_speed = opt_speed{j};

    if current_opt_patt == 6 && current_opt_speed == 127
        line_col = [0, 0.4, 0]; % dark green
        leg_val = 'thick, fast';
    elseif current_opt_patt == 6 && current_opt_speed == 64
        line_col = [0.6, 1, 0.6]; % light green
        leg_val = 'thick, slow';
    elseif current_opt_patt == 4 && current_opt_speed == 127
        line_col = [0, 0, 0]; % black
        leg_val = 'thin, fast';
    elseif current_opt_patt == 4 && current_opt_speed == 64
        line_col = [0.8, 0.8, 0.8]; % gray
        leg_val = 'thin, slow';
    end

    subplot(2, 1, pos)
    plot(current_mean, 'Color', line_col, 'LineWidth', 1);

end

hold off

%%%% have to figure out legend still %%%%%