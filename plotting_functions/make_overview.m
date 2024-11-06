function f = make_overview(combined_data, strain, sex, protocol)
% Combined plot with subplots about the locomotion of flies during the
% optomotor freely walking behaviour experiments. 
% Uses the combined data from all flies across experiments. 

% Analysis of metrics across the entire experiment. 

data = combined_data.vel_data;
n_flies = height(data);
% Set any values > 300 mm s-1 as NaN.
data(data(:, :)>300) = NaN;

% Initialise figure
t = tiledlayout(3,2, 'TileSpacing', 'compact', 'Padding','loose');

% % % % Velocity % % % % 

% plot 1 - histogram of velocity over the entire experiment. 
nexttile
plot_hist(data, 20, "vel")

% plot 2 - the proportion of the experiment the flies spent < 2mm s-1
nexttile
plot_hist_prop(data, "slow")
ylabel('')

% % % % Ang Vel % % % % 

% plot 3 - histogram of angular velocity over the entire experiment. 
nexttile
plot_hist(combined_data.av_data, 20, "angvel")

% % % % Heading % % % % 

% plot 4 - histogram of heading over the entire experiment. 
nexttile
plot_hist(combined_data.heading_wrap, 20, "heading")
ylabel('')
% % % % Distance from centre % % % % 

% plot 5 - histogram of the distance from centre over the entire experiment. 
nexttile
plot_hist(combined_data.dist_data, 20, "dist")

% plot 6 - histogram prop of exp < 30mm from centre. 
nexttile
plot_hist_prop(combined_data.dist_data, "centre")
ylabel('')

f = gcf;
f.Position = [16   499   450   534];

title(t, strcat('FullExp-', strrep(strain, '_', '-'), '-',sex,'-', strrep(protocol, '_', '-'), '-n=', num2str(n_flies)), 'FontWeight', 'bold')

end