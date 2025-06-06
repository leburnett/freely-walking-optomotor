% Analyse how the physical location of the fly within the arena -
% specifically its distance from the centre/ edge - affects it's turning /
% centring behaviour. 


%% Histograms for values within different frame ranges - no flies removed. 

strain = "ss00297_Dm4_shibire_kir";

condition_n = 1;

% Extract 'data' from the relevant strain / condition.
sex = 'F';
data = DATA.(strain).(sex);

control_strain = "jfrc100_es_shibire_kir";
data_control = DATA.(control_strain).(sex);

data_types = {'IFD_data', 'fv_data', 'av_data', 'curv_data', 'dist_data', 'dist_data_delta', 'straightness'};
n_data_types = numel(data_types);

control_col = [0.2 0.2 0.2];
target_col = [0.8 0.4 0.8];

for typ_id = 1% :n_data_types

    data_type = data_types{typ_id};

    cond_data_control = combine_timeseries_across_exp(data_control, condition_n, data_type);
    cond_data = combine_timeseries_across_exp(data, condition_n, data_type);

    figure; 

    tiledlayout(5, 1, 'TileSpacing', 'tight')
    nexttile
    % Before stimulus
    frame_rng = 1:300;
    plot_histogram_from_cond_data(cond_data_control, frame_rng, data_type, control_col);
    hold on;
    plot_histogram_from_cond_data(cond_data, frame_rng, data_type, target_col);
    title('10s before stimulus')

    nexttile
    % Entire stimulus
    frame_rng = 300:1200;
    plot_histogram_from_cond_data(cond_data_control, frame_rng, data_type, control_col);
    hold on;
    plot_histogram_from_cond_data(cond_data, frame_rng, data_type, target_col);
    title('During stimulus (30s)')

    nexttile
    % First 5s of stimulus
    frame_rng = 300:450;
    plot_histogram_from_cond_data(cond_data_control, frame_rng, data_type, control_col);
    hold on;
    plot_histogram_from_cond_data(cond_data, frame_rng, data_type, target_col);
    title('First 5s of stimulus')

    nexttile
    % Last 5s of stimulus
    frame_rng = 1000:1150;
    plot_histogram_from_cond_data(cond_data_control, frame_rng, data_type, control_col);
    hold on;
    plot_histogram_from_cond_data(cond_data, frame_rng, data_type, target_col);
    title('Last 5s of stimulus')

    nexttile
    % First 10s of interval
    frame_rng = 1200:1500;
    plot_histogram_from_cond_data(cond_data_control, frame_rng, data_type, control_col);
    hold on;
    plot_histogram_from_cond_data(cond_data, frame_rng, data_type, target_col);
    title('First 10s of interval')

    f = gcf;
    f.Position = [464    75   245   972];
    sgtitle(strrep(data_type, '_', '-'))

end 



%% Scatter plots
% For p27 - screen protocol.
% Only control flies
% Plot scatter plots of the fly's distance from the centre of the arena
% versus the centripetal distance moved by the fly during 5s periods. 

% Stimulus on from 300:1200
condition_n = 1;

bin_size = 150; % 5s
bin_edges = 150:bin_size:1350; % From 5s before the stimulust starts til 5s after the stimulus ends. 
n_bins = length(bin_edges)-1;

for b = 1:n_bins
   
    frame_rng = bin_edges(b):bin_edges(b+1);

    control_strain = "jfrc100_es_shibire_kir"; %"ss00297_Dm4_shibire_kir"; %
    data_control = DATA.(control_strain).(sex);
    
    data_type = "dist_data"; 
    cond_data_control1 = combine_timeseries_across_exp(data_control, condition_n, data_type);
    binned_vals_dist = bin_data_from_cond_data(cond_data_control1, frame_rng, data_type, bin_size);
    binned_vals_dist = binned_vals_dist(:);
    
    data_type = "dist_data_delta"; 
    binned_vals_delta = bin_data_from_cond_data(cond_data_control1, frame_rng, data_type, bin_size);
    binned_vals_delta = binned_vals_delta(:);

    % Use forward velocity for colour of markers. 
    data_type = "av_data"; 
    cond_data_control3 = combine_timeseries_across_exp(data_control, condition_n, data_type);
    binned_vals_fv = bin_data_from_cond_data(cond_data_control3, frame_rng, data_type, bin_size);
    binned_vals_fv = abs(binned_vals_fv(:));
    % c_array = (binned_vals_fv - min(binned_vals_fv)) / (max(binned_vals_fv) - min(binned_vals_fv));
    c_array = (binned_vals_fv - 0) / (300 - 0);
    c_array(c_array> 1) = 1;
    c_array(c_array<0) = 0;
    c = 1 - [c_array, c_array, c_array];

    figure; 
    plot([0 120], [0 0], 'Color', [1 0.6 0.6], 'LineWidth', 2); 
    hold on;
    scatter(binned_vals_dist, binned_vals_delta, 50, c, 'filled', 'MarkerEdgeColor', [0.2 0.2 0.2]); 
    title(sprintf('Dist %d-%d', bin_edges(b), bin_edges(b+1)));
    ylim([-100 100])
    f = gcf; 
    f.Position = [683   507   531   526];

end 

%% Scatter plots - angular velocity / turning rate
% For p27 - screen protocol.
% Only control flies
% Plot scatter plots of the fly's distance from the centre of the arena
% versus the centripetal distance moved by the fly during 5s periods. 

% Stimulus on from 300:1200
condition_n = 1;

bin_size = 150; % 5s
bin_edges = 150:bin_size:1350;
n_bins = length(bin_edges)-1;

% control_strain = "jfrc100_es_shibire_kir";
control_strain = "ss00297_Dm4_shibire_kir";
data_control = DATA.(control_strain).(sex);

for b = 1:n_bins
   
    frame_rng = bin_edges(b):bin_edges(b+1);

    data_type = "dist_data"; 
    cond_data_control1 = combine_timeseries_across_exp(data_control, condition_n, data_type);
    binned_vals_dist = bin_data_from_cond_data(cond_data_control1, frame_rng, data_type, bin_size);
    binned_vals_dist = binned_vals_dist(:);
    
    data_type = "curv_data"; 
    cond_data_control_curv = combine_timeseries_across_exp(data_control, condition_n, data_type);
    binned_vals_curv = bin_data_from_cond_data(cond_data_control_curv, frame_rng, data_type, bin_size);
    binned_vals_curv = binned_vals_curv(:);

    % Use forward velocity for colour of markers. 
    data_type = "fv_data"; 
    cond_data_control3 = combine_timeseries_across_exp(data_control, condition_n, data_type);
    binned_vals_fv = bin_data_from_cond_data(cond_data_control3, frame_rng, data_type, bin_size);
    binned_vals_fv = binned_vals_fv(:);
    c_array = (binned_vals_fv - min(binned_vals_fv)) / (max(binned_vals_fv) - min(binned_vals_fv));
    % c = 1 - [zeros(size(c_array)), c_array, c_array];
    c = 1 - [c_array, c_array, c_array];

            % % Plot timeseries of binned values with a given bin size:
            % figure; plot(mean(binned_vals_delta))
            % ylabel('Distance moved towards centre (mm)')
            % xticks('')
            % title(strcat("Bin size: ", string(bin_size/30), "s"))
            % f = gcf;
            % f.Position = [171   535   920   405];
   
    figure; 
    plot([0 120], [0 0], 'Color', [1 0.8 0.8]); 
    hold on;
    scatter(binned_vals_dist, binned_vals_curv, 50, c, 'filled', 'MarkerEdgeColor', [0.2 0.2 0.2]); 
    % scatter(binned_vals_dist, binned_vals_curv, 'o', 'MarkerEdgeColor', [0.2 0.2 0.2]); 
    title(sprintf('Dist %d-%d', bin_edges(b), bin_edges(b+1)));
    ylim([-450 450])
    ylabel('Turning rate (deg mm^-^1)')
    % ylabel('Angular velocity (deg s^-^1)')
    xlabel('Distance from the centre of the arena (mm)')
    % yscale log
    f = gcf; 
    f.Position = [683   507   531   526];

end 


%% Over the entire stimulus:


% Stimulus on from 300:1200
condition_n = 1;

bin_size = 150; % 5s

n_bins = length(bin_edges)-1;

frame_rng = 300:1200;

control_strain = "jfrc100_es_shibire_kir";
data_control = DATA.(control_strain).(sex);

data_type = "dist_data"; 
cond_data_control1 = combine_timeseries_across_exp(data_control, condition_n, data_type);
binned_vals_dist = bin_data_from_cond_data(cond_data_control1, frame_rng, data_type, bin_size);
binned_vals_dist = binned_vals_dist(:);

data_type = "dist_data_delta"; 
binned_vals_delta = bin_data_from_cond_data(cond_data_control1, frame_rng, data_type, bin_size);
binned_vals_delta = binned_vals_delta(:);

figure; 
plot([0 120], [0 0], 'Color', [1 0.8 0.8]); 
hold on;
scatter(binned_vals_dist, binned_vals_delta, 'o', 'MarkerEdgeColor', [0.2 0.2 0.2]); 
ylim([-100 100])
f = gcf; 
f.Position = [683   507   531   526];




%% QUESTION - can flies that are turning at a high turning rate also be walking forward at a high rate?

frame_rng = 300:1200; % Just look at the beginning of the stimulus
control_strain = "jfrc100_es_shibire_kir";
data_control = DATA.(control_strain).(sex);

data_type = "fv_data"; 
cond_data_control1 = combine_timeseries_across_exp(data_control, condition_n, data_type);
binned_vals1 = bin_data_from_cond_data(cond_data_control1, frame_rng, data_type, bin_size);
binned_vals1 = binned_vals1(:);

data_type = "curv_data"; 
cond_data_control2 = combine_timeseries_across_exp(data_control, condition_n, data_type);
binned_vals2 = bin_data_from_cond_data(cond_data_control2, frame_rng, data_type, bin_size);
binned_vals2 = binned_vals2(:);

figure; 
plot([0 30], [0 0], 'Color', [1 0.6 0.6], 'LineWidth', 2); 
hold on
plot([0 30], [90 90], 'Color', [1 0.6 0.6], 'LineWidth', 1); 
plot([0 30], [-90 -90], 'Color', [1 0.6 0.6], 'LineWidth', 1); 
scatter(binned_vals1, binned_vals2, 30, 'o', 'MarkerEdgeColor', [0.2 0.2 0.2])
xlabel('Forward velocity (mm s^-^1)')
ylabel('Turning rate (deg mm^-^1)')
box off
ax = gca;
ax.TickDir = 'out';
ax.LineWidth = 1.2;
ax.FontSize = 12;
title(strcat("Frame range: ", string(frame_rng(1)), ":", string(frame_rng(end))))


%%







figure; scatterhist(binned_vals_dist, binned_vals_delta)
%%

% Plot histograms of amount moved towards centre based on location in the
% arena. 

% 8 different distance bins (120/8 = 15mm)
dist_bins = 0:20:120;
bin_idx = discretize(binned_vals_dist, dist_bins);

figure;
for i = 1:length(dist_bins)-1

    % subplot(6,1,i)

    % Get the values in binned_vals_delta corresponding to the current bin
    delta_in_bin = binned_vals_delta(bin_idx == i);

    % Plot histogram in a subplot
    histogram(delta_in_bin,'Normalization', 'probability', 'BinWidth', 1);
    hold on;
    plot([mean(delta_in_bin), mean(delta_in_bin)], [0 0.25], 'r')
    
    % Label the plot
    title(sprintf('Dist %d-%d', dist_bins(i), dist_bins(i+1)));
    xlabel('Delta');
    ylabel('Count');
    xlim([-30 75])
end


%% Contour plot:

% Define colormap
cmap = parula(n_bins);

figure; hold on;
% plot([0 120], [0 0], 'Color', [1 0.6 0.6], 'LineWidth', 2); 
ylim([-100 100])
xlabel('Distance to edge');
ylabel('Delta distance to edge');
title('Behavioural contours over time bins');

for b = 1:n_bins

    frame_rng = bin_edges(b):bin_edges(b+1);

    control_strain = "jfrc100_es_shibire_kir"; 
    data_control = DATA.(control_strain).(sex);
    
    % Dist to edge
    data_type = "dist_data"; 
    cond_data_control1 = combine_timeseries_across_exp(data_control, condition_n, data_type);
    binned_vals_dist = bin_data_from_cond_data(cond_data_control1, frame_rng, data_type, bin_size);
    binned_vals_dist = binned_vals_dist(:);

    % Delta distance to edge
    data_type = "dist_data_delta"; 
    binned_vals_delta = bin_data_from_cond_data(cond_data_control1, frame_rng, data_type, bin_size);
    binned_vals_delta = binned_vals_delta(:);

    % Remove NaNs
    valid_idx = ~isnan(binned_vals_dist) & ~isnan(binned_vals_delta);
    x = binned_vals_dist(valid_idx);
    y = binned_vals_delta(valid_idx);

    % Compute boundary (use convex hull or alpha shape)
    try
        k = boundary(x, y, 0.1); % 0.9 is a tightness parameter (0 = tightest, 1 = convex hull)
        plot(x(k), y(k), '-', 'Color', cmap(b,:), 'LineWidth', 2);
    catch
        % If not enough points for boundary
        warning('Not enough points in bin %d for contour.', b);
    end
end

legend(arrayfun(@(b) sprintf('%d-%d', bin_edges(b), bin_edges(b+1)), 1:n_bins, 'UniformOutput', false), ...
       'Location', 'bestoutside');



%% Histogram of the distance of the fly from the edge of the arena when its centripetal displacement is highest. 

% Stimulus on from 300:1200
condition_n = 1;

bin_size = 15; % 0.5s

n_bins = length(bin_edges)-1;

frame_rng = 300:1200;

control_strain = "ss00297_Dm4_shibire_kir"; %"jfrc100_es_shibire_kir";

data_control = DATA.(control_strain).(sex);

data_type = "dist_data"; 
cond_data_control1 = combine_timeseries_across_exp(data_control, condition_n, data_type);
binned_vals_dist = bin_data_from_cond_data(cond_data_control1, frame_rng, data_type, bin_size);
binned_vals_dist = squeeze(binned_vals_dist);

data_type = "dist_data_delta"; 
binned_vals_delta = bin_data_from_cond_data(cond_data_control1, frame_rng, data_type, bin_size);

dist_w_max_centring = zeros(height(binned_vals_delta), 1);
for ii = 1:height(binned_vals_delta)
    max_idx = find(binned_vals_delta(ii, :) == max(binned_vals_delta(ii, :)));
    dist_max = binned_vals_dist(ii, max_idx);
    if numel(max_idx)>1
        % disp(dist_max)
        dist_w_max_centring(ii, 1) = mean(dist_max);
    else
        dist_w_max_centring(ii, 1) = dist_max;
    end 
end 


figure; 
histogram(dist_w_max_centring, 'BinEdges', 0:5:120, 'FaceColor', 'r', 'FaceAlpha',0.1)
format_figure
f = gcf; 
f.Position = [620   741   486   226];
xlabel('Distance from the centre of the arena (mm)')
ylabel('Number of flies')
title('Distance of the fly with max centripetal displacement - 0.5s bins')

mean(dist_w_max_centring)

%'Normalization','pdf', 

%% Histogram of the distance of the fly from the edge of the arena when its angular velocity is highest. 

% Stimulus on from 300:1200
condition_n = 1;

bin_size = 30; % 0.5s

n_bins = length(bin_edges)-1;

frame_rng = 300:1200;

control_strain = "ss00297_Dm4_shibire_kir"; %"jfrc100_es_shibire_kir";
data_control = DATA.(control_strain).(sex);

data_type = "dist_data"; 
cond_data_control1 = combine_timeseries_across_exp(data_control, condition_n, data_type);
binned_vals_dist = bin_data_from_cond_data(cond_data_control1, frame_rng, data_type, bin_size);
binned_vals_dist = squeeze(binned_vals_dist);

data_type = "curv_data"; 
cond_data_control2 = combine_timeseries_across_exp(data_control, condition_n, data_type);
binned_vals_av = bin_data_from_cond_data(cond_data_control2, frame_rng, data_type, bin_size);
binned_vals_av = squeeze(binned_vals_av);

dist_w_max_turning = zeros(height(binned_vals_av), 1);
for ii = 1:height(binned_vals_av)
    max_idx = find(binned_vals_av(ii, :) == max(binned_vals_av(ii, :)));
    dist_max = binned_vals_dist(ii, max_idx);
    if numel(max_idx)>1
        dist_w_max_turning(ii, 1) = mean(dist_max);
    else
        dist_w_max_turning(ii, 1) = dist_max;
    end 
end 

figure; 
histogram(dist_w_max_turning, 'BinEdges', 0:5:120, 'FaceColor', 'r', 'FaceAlpha',0.1)
format_figure
f = gcf; 
f.Position = [620   741   486   226];
xlabel('Distance from the centre of the arena (mm)')
ylabel('Number of flies')
title('Distance of the fly with max angular velocity - 0.5s bins')
% title('Distance of the fly with max turning rate - 0.5s bins')

mean(dist_w_max_turning)


%%

control_strain = "jfrc100_es_shibire_kir";
data_control = DATA.(control_strain).(sex);

data_type = "x_data"; 
cond_data_x = combine_timeseries_across_exp(data_control, condition_n, data_type);

data_type = "y_data"; 
cond_data_y = combine_timeseries_across_exp(data_control, condition_n, data_type);

data_type = "dist_data"; 
cond_data_dist = combine_timeseries_across_exp(data_control, condition_n, data_type);

% Define the center of the arena
cx = calib.centroids(1)/calib.PPM; 
cy = calib.centroids(2)/calib.PPM;


for i = 300:320
    x_data = cond_data_x(i, :);
    y_data = cond_data_y(i, :);
    d_data = cond_data_dist(i, :);
    
    % Example inputs
    x = x_data(300:1200); % x position over time (1 x n)
    y = y_data(300:1200); % y position over time (1 x n)
    t = 1:numel(x); % time vector (1 x n) or assume uniform sampling
    
    time_or_dist = "dist";
    centring_turning_traj_plots(x, y, t, d_data, cx, cy, time_or_dist)
end 




%% Plot the last position of all of the flies

data_type = "curv_data"; 
cond_data_fv = combine_timeseries_across_exp(data_control, condition_n, data_type);

x_all = cond_data_x(:, 1190);
y_all = cond_data_y(:, 1190);

% fv_all = mean(cond_data_fv(:, 300:1200), 2);
fv_all = abs(cond_data_fv(:, 1190));
% fv_all = prctile(cond_data_fv(:, 300:1200)', 98);

figure;
rectangle('Position',[1, 1, 248, 248], 'Curvature', [1,1], 'FaceColor', [0.95 0.95 0.95], 'EdgeColor', 'none') 
hold on;
viscircles([cx, cy], 110, 'Color', [0.8 0.8 0.8], 'LineStyle', '--', 'LineWidth',1)
viscircles([cx, cy], 63, 'Color', [0.8 0.8 0.8], 'LineStyle', '--', 'LineWidth',1)
scatter(x_all, y_all, 60, fv_all, 'filled', 'MarkerEdgeColor', 'k') %, 'MarkerFaceColor', 'w', 
colormap(turbo); 
axis equal;
xlim([0 246])
ylim([0 246])
% Mark the center of the arena
plot(cx, cy, 'k+', 'MarkerSize', 28, 'LineWidth', 3.5, 'DisplayName', 'Centre');
    

title('Final position of each fly - cmap - instantaneous turning rate')


%% Generate plots of centring grouped by walking speed:

data_type = "dist_data"; 
cond_data_dist = combine_timeseries_across_exp(data_control, condition_n, data_type);

data_type = "fv_data"; 
cond_data_fv = combine_timeseries_across_exp(data_control, condition_n, data_type);


% Extract time window
fv_window = cond_data_fv(:, 300:1200);
dist_window = cond_data_dist(:, 1:1800);

% Compute mean fv values per fly in the time window
mean_fv = mean(fv_window, 2);

% Define bin edges (you can adjust these as needed)
bin_edges = [-inf, 1, 5, 10, 15, 20, inf]; % e.g. <2, 2–5, 5–8, >8
n_bins = length(bin_edges) - 1;

col = [0.8 0.8 0.8];
% Create figure
figure;

for i = 1:n_bins
    % Get indices of flies in this bin
    in_bin = mean_fv >= bin_edges(i) & mean_fv < bin_edges(i+1);
    
    % Get corresponding dist data
    dist_group = cond_data_dist_delta(in_bin, :);
    
    % Compute mean across flies in this bin
    if ~isempty(dist_group)
        mean_dist = mean(dist_group, 1);
    else
        mean_dist = nan(1, size(cond_data_dist_delta, 2)); % placeholder if no data
    end
    
    % Plot in subplot
    % subplot(n_bins, 1, i);
    plot(mean_dist, 'LineWidth', 1.75, 'Color', col); hold on

    % title(sprintf('Starting dist in [%g, %g)', bin_edges(i), bin_edges(i+1)));
    col = col - 0.12;
end

ylim([-60 20])
ylabel('Distance');
format_figure()

plot([300 300], [-60 40], 'k-', 'LineWidth', 0.7);
plot([1200 1200], [-60 40], 'k-', 'LineWidth', 0.7);
plot([0 1800], [0 0], 'r-', 'LineWidth', 0.7);
xlim([0 1800])
ax = gca;
ax.XAxis.Visible = 'off';


%% Generate plots of centring grouped by distance from the centre at the time of stimulus start

data_type = "dist_data"; 
cond_data_dist = combine_timeseries_across_exp(data_control, condition_n, data_type);
cond_data_dist_delta = cond_data_dist - cond_data_dist(:, 300);

% Compute mean fv values per fly in the time window
location_start = cond_data_dist(:, 302);

% Define bin edges (you can adjust these as needed)
bin_edges = [0, 20, 40, 60, 80, 100, 120]; % e.g. <2, 2–5, 5–8, >8
n_bins = length(bin_edges) - 1;

col = [0.8 0.8 0.8];
% Create figure
figure;

for i = 1:n_bins
    % Get indices of flies in this bin
    in_bin = location_start >= bin_edges(i) & location_start < bin_edges(i+1);
    
    % Get corresponding dist data
    dist_group = cond_data_dist_delta(in_bin, :);
    
    % Compute mean across flies in this bin
    if ~isempty(dist_group)
        mean_dist = mean(dist_group, 1);
    else
        mean_dist = nan(1, size(cond_data_dist_delta, 2)); % placeholder if no data
    end
    
    % Plot in subplot
    % subplot(n_bins, 1, i);
    plot(mean_dist, 'LineWidth', 1.75, 'Color', col); hold on

    % title(sprintf('Starting dist in [%g, %g)', bin_edges(i), bin_edges(i+1)));
    col = col - 0.12;
end

ylim([-60 40])
xlabel('Timepoint');
ylabel('Distance');
format_figure()

plot([300 300], [-60 40], 'k-', 'LineWidth', 0.7);
plot([1200 1200], [-60 40], 'k-', 'LineWidth', 0.7);
plot([0 1800], [0 0], 'r-', 'LineWidth', 0.7);
xlim([0 1800])
ax = gca;
ax.XAxis.Visible = 'off';


%% Generate plots of centring grouped by turning speed:

data_type = "dist_data"; 
cond_data_dist = combine_timeseries_across_exp(data_control, condition_n, data_type);
cond_data_dist_delta = cond_data_dist - cond_data_dist(:, 300);

data_type = "curv_data"; 
cond_data_fv = combine_timeseries_across_exp(data_control, condition_n, data_type);

% Extract time window
fv_window = abs(cond_data_fv(:, 300:1200));

% Compute mean fv values per fly in the time window
mean_fv = mean(fv_window, 2);

% Define bin edges (you can adjust these as needed)
bin_edges = [0, 50, 100, 150, 200, 250, 350]; % e.g. <2, 2–5, 5–8, >8
n_bins = length(bin_edges) - 1;

col = [0.8 0.8 0.8];
% Create figure
figure;

for i = 1:n_bins
    % Get indices of flies in this bin
    in_bin = mean_fv >= bin_edges(i) & mean_fv < bin_edges(i+1);
    
    % Get corresponding dist data
    dist_group = cond_data_dist_delta(in_bin, :);
    
    % Compute mean across flies in this bin
    if ~isempty(dist_group)
        mean_dist = mean(dist_group, 1);
    else
        mean_dist = nan(1, size(cond_data_dist_delta, 2)); % placeholder if no data
    end
    
    % Plot in subplot
    % subplot(n_bins, 1, i);
    plot(mean_dist, 'LineWidth', 1.75, 'Color', col); hold on

    % title(sprintf('Starting dist in [%g, %g)', bin_edges(i), bin_edges(i+1)));
    col = col - 0.12;
end

ylim([-60 20])
ylabel('Distance');
format_figure()

plot([300 300], [-60 40], 'k-', 'LineWidth', 0.7);
plot([1200 1200], [-60 40], 'k-', 'LineWidth', 0.7);
plot([0 1800], [0 0], 'r-', 'LineWidth', 0.7);
xlim([0 1800])
ax = gca;
ax.XAxis.Visible = 'off';


%%  Turning over stimulus grouped by the distance of the flies from the centre of the arena. 

data_type = "dist_data"; 
cond_data_dist = combine_timeseries_across_exp(data_control, condition_n, data_type);

data_type = "curv_data"; 
cond_data_fv = combine_timeseries_across_exp(data_control, condition_n, data_type);

% Compute mean fv values per fly in the time window
location_start = cond_data_dist(:, 500);

% Define bin edges (you can adjust these as needed)
bin_edges = [0, 20, 50, 75, 120]; % e.g. <2, 2–5, 5–8, >8

n_bins = length(bin_edges) - 1;

col = [0.8 0.8 0.8];

figure;

for i = 1:n_bins
    % Get indices of flies in this bin
    in_bin = location_start >= bin_edges(i) & location_start < bin_edges(i+1);
    
    % Get corresponding dist data
    dist_group = cond_data_fv(in_bin, :);
    
    % Compute mean across flies in this bin
    if ~isempty(dist_group)
        mean_dist = mean(dist_group, 1);
    else
        mean_dist = nan(1, size(cond_data_fv, 2)); % placeholder if no data
    end
    
    % Plot in subplot
    % subplot(n_bins, 1, i);
    plot(movmean(mean_dist, 5), 'LineWidth', 1.75, 'Color', col); hold on

    % title(sprintf('Starting dist in [%g, %g)', bin_edges(i), bin_edges(i+1)));
    col = col - 0.22;
end

ylim([-200 200])
% ylabel('Turning rate (deg mm^-^1)');
ylabel('Angular velocity (deg s^-^1)');
format_figure()

plot([300 300], [-310 310], 'k-', 'LineWidth', 0.7);
plot([1200 1200], [-310 310], 'k-', 'LineWidth', 0.7);
plot([0 1800], [0 0], 'r-', 'LineWidth', 0.7);
xlim([0 1800])
ax = gca;
ax.XAxis.Visible = 'off';



%% Ethogram - collisions - when fly < 1mm IFD. 

data_type = "IFD_data"; 
cond_data_ifd = combine_timeseries_across_exp(data_control, condition_n, data_type);

ifd2 = cond_data_ifd;
ifd2(ifd2<2) = 1;
ifd2(ifd2>=2) = 0;

figure; imagesc(ifd2)

strain = "ss00297_Dm4_shibire_kir";
data = DATA.(strain).(sex);
data_type = "IFD_data"; 
cond_data_ifd = combine_timeseries_across_exp(data, condition_n, data_type);

ifd2 = cond_data_ifd;
ifd2(ifd2<2) = 1;
ifd2(ifd2>=2) = 0;

figure; imagesc(ifd2)



figure; plot(mean(cond_data_ifd)) % at 1200 - ~ 20 mm distance between flies. 
figure; plot(cond_data_ifd(4, :))