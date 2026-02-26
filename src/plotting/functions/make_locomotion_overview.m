function f = make_locomotion_overview(combined_data, strain, protocol)
% Combined plot with subplots about the locomotion of flies during the
% optomotor freely walking behaviour experiments. 
% Uses the combined data from all flies across experiments. 

data = combined_data.vel_data;
% Set any values > 300 mm s-1 as NaN.
data(data(:, :)>300) = NaN;

% Initialise figure
t = tiledlayout(3,2, 'TileSpacing', 'compact', 'Padding','loose');

% % % % Full experiment % % % % 

% plot 1 - histogram of velocity over the entire experiment. 
nexttile
plot_hist_vel(data, 20)

% plot 2 - the proportion of the experiment the flies spent < 2mm s-1
nexttile
plot_hist_prop_slow(data)

% Only data from when lights are off at the beginning of the experiment.
data_acclim = data(:, 1:900);
data_exp = data(:, 1800:end-900);

% % % % ACCLIM OFF % % % % 

% plot 3 - histogram of velocity . 
nexttile
plot_hist_vel(data_acclim, 20)

% plot 4 - the proportion of the experiment the flies spent < 2mm s-1
nexttile
plot_hist_prop_slow(data_acclim)

% % % % Excluding ACCLIM % % % % 

% plot 5 - histogram of velocity . 
nexttile
plot_hist_vel(data_exp, 20)

% plot 6 - the proportion of the experiment the flies spent < 2mm s-1
nexttile
plot_hist_prop_slow(data_exp)

f = gcf;
f.Position = [16   568   450   465];
ylabel(t,'During exp                  Acclim in dark                 Full experiment', 'FontWeight', 'bold');
title(t, strcat('Locomotion - ', strrep(strain, '_', '-'), ' - ', strrep(protocol, '_', '-')), 'FontWeight', 'bold')

end