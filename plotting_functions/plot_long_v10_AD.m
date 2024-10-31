% script to plot_long_v10_AD

% for testing
cd('C:\Users\deva\Documents\projects\oakey_cokey\results\protocol_10\csw1118\F')
load("2024_10_23_14_44_21_data.mat");
% Log = LOG.log_1;
% protocol = protocol_10;\

% Fixed paramters: 
n_flies = length(trx);
% Log = log_2;
% title_str = 'log_2_allfeatures';

fps = 30;
samp_rate = 1/fps; 
method = 'line_fit';
t_window = 16;
cutoff = [];

figure;

log_names = fieldnames(LOG);

% % % % % % % % DISTANCE FROM CENTER % % % % % % % % %

for i = 4:(length(log_names) - 1)
    current_log_name = log_names{i};
    current_log = LOG.(log_names{i});
    % current_n_conditions = size(current_log.start_t, 2);

    min_val = 0;
    max_val = 120;
    protcol10 = 'protocol10';
    plot_pink_blue_rects_AD(current_log, min_val, max_val, 1);

end

dist_data = feat.data(:, :, 9);
dist_data = 120-dist_data;

hold on
for idx = 1:n_flies
  % Plot the distance from the centre per fly
    plot(dist_data(idx, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 1)
end 

ylim([0 120])
plot([0 Log.stop_f(end)], [120 120], 'LineWidth', 1, 'Color', [0.7 0.7 0.7])
plot([0 Log.stop_f(end)], [0 0], 'LineWidth', 1, 'Color', [0.7 0.7 0.7])

% Plot the distance from the centre
plot(mean(dist_data), 'k', 'LineWidth', 2.5)

% create bracket ticks for each condition change
xticks(LOG.acclim_off1.start_f, LOG.acclim_off1.stop_f)

ylabel('Distance from the centre (mm)')


sgtitle(strcat(title_str, ' - N=', string(n_flies)))
f = gcf; 
% f.Position = [1234  71  567  976]; %% does something wierd,
% uncommented for now
han=axes(f, 'visible','off');
han.XLabel.Visible='on';
xlabel(han, 'Time / frames / conditions')