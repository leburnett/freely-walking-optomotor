%% Viewing distance versus angular velocity:

% For condition 1 - 60 deg gratings. Empty Split flies. 

strain = "jfrc100_es_shibire_kir";
sex = 'F';
condition_n = 1;

%% Extract data

data = DATA.(strain).(sex);

data_type = "x_data"; 
cond_data_x = combine_timeseries_across_exp(data, condition_n, data_type);

data_type = "y_data"; 
cond_data_y = combine_timeseries_across_exp(data, condition_n, data_type);

data_type = "view_dist"; 
cond_data_vd = combine_timeseries_across_exp(data, condition_n, data_type);

data_type = "av_data"; 
cond_data_av = combine_timeseries_across_exp(data, condition_n, data_type);

%% Set frame range

rng = 350:600;
% rng = 300:1200;

%% Plot the trajectory of the fly over a given frame range

% Define the center of the arena
cx = 122.8079; %calib.centroids(1)/calib.PPM; 
cy = 124.7267; %calib.centroids(2)/calib.PPM;

fly_id_rng = 31:40;

for id = fly_id_rng
    x = cond_data_x(id, rng);
    y = cond_data_y(id, rng);
    
    figure
    plot_trajectory_simple(x, y, cx, cy)
    title(id)
end 

%% PLOT: Trajectory and viewing distance versus angular velocity - both coloured by time.  

% % % % Set marker size proportional to the forward speed of the animal. 
% data_type = "fv_data"; 
% cond_data_vel = combine_timeseries_across_exp(data, condition_n, data_type);
% sz = cond_data_vel(id, rng)*5; 
id = 178;

% % % % Constant marker size:
sz = 40; 

figure
tiledlayout(1,2,"TileSpacing", "tight", "Padding","loose")

nexttile
scatter(cond_data_vd(id, rng), abs(cond_data_av(id, rng)), sz, rng, 'filled');
ax = gca;
ylims = ax.YLim;
hold on 
plot([120 120], [0 max(ylims)], "Color", [0.8 0.8 0.8], "LineWidth", 1)
xlabel('Viewing distance (mm)')
ylabel('Angular velocity (deg/s)')
xlim([0 240])

ax.TickDir = 'out';
ax.LineWidth = 1;
ax.FontSize = 12;

nexttile
rectangle('Position',[0.25, 2.5, 245, 245], 'Curvature', [1,1], 'FaceColor', [0.95 0.95 0.95], 'EdgeColor', 'none')
viscircles([cx, cy], 121, 'Color', [0.8 0.8 0.8], 'LineStyle', '-', 'LineWidth', 1) % Edge
viscircles([cx, cy], 110, 'Color', [0.8 0.8 0.8], 'LineStyle', '--', 'LineWidth',1) % 10mm from edge
viscircles([cx, cy], 63, 'Color', [0.8 0.8 0.8], 'LineStyle', '--', 'LineWidth',1) % Half way
hold on;
scatter(cond_data_x(id, rng), cond_data_y(id, rng), sz/2, rng, 'filled');
hold on 
plot(cx, cy, 'r+', 'MarkerSize', 18, 'LineWidth', 1.5, 'DisplayName', 'Centre');
xlabel('x')
ylabel('y')
% axis equal
axis off
title(id)

f = gcf;
f.Position = [ 240   592   829   388];

%% From behavioural data (DATA):

fly_id = 178;
vd_data = cond_data_vd;
av_data = cond_data_av;
x_data = cond_data_x;
y_data = cond_data_y;

plot_traj_vd_av(fly_id, rng, vd_data, av_data, x_data, y_data, cx, cy)

%% Extract data only during the stimulus:

% cdata_vd = cond_data_vd(:, 301:1200);
% cdata_av = cond_data_av(:, 301:1200);
% 
% bin_size = 5; % 5 frame bins. 
% n_bins = floor(length(cdata_vd(1, :))/bin_size);
% 
% % Reshape and average: result is n_flies x n_bins
% data_reshaped = reshape(cdata_vd, size(cdata_vd,1), bin_size, n_bins);
% binned_data_vd = squeeze(mean(data_reshaped, 2));
% % rows_with_negatives = any(binned_data < 0, 2);  % logical index of rows that contain negatives
% % binned_data_cleaned_vd = binned_data(~rows_with_negatives, :);
% 
% % Reshape and average: result is n_flies x n_bins
% data_reshaped = reshape(cdata_av, size(cdata_av,1), bin_size, n_bins);
% binned_data_av = squeeze(mean(data_reshaped, 2));
% % Remove the same rows as for the viewing distance. 
% % binned_data_cleaned_av = binned_data(~rows_with_negatives, :);
% 
% figure; scatter(binned_data_cleaned_vd(:), abs(binned_data_cleaned_av(:)), 5, 'k');
% hold on
% plot([120, 120], [0, 2500], 'r', 'LineWidth', 1.2)
% ylim([0 400])
% xlabel('Viewing distance (mm)')
% ylabel('Angular velocity (deg s^-^1)')
% ax = gca;
% ax.TickDir = 'out';
% ax.LineWidth = 1;
% ax.FontSize = 12;
% 
% title(strcat(string(bin_size), " frame bin size - 300:1200"))
% 
% f = gcf;
% f.Position = [620   522   932   445];


%% Dynamic plot - viewing distance versus angualr velocity. 

% n_points = numel(rng);
% % figure
% for kk = 1:n_points
%     subplot(1,2,1)
%     scatter(cdata_vd(id, rng(kk)), abs(cdata_av(id, rng(kk))), 15, 'k');
%     hold on
%     subplot(1,2,2)
%     scatter(cond_data_x(id, rng(kk)), abs(cond_data_y(id, rng(kk))), 15, 'k');
%     hold on
%     pause(0.01)
% end 
% xlabel('Viewing distance (mm)')
% ylabel('Angular velocity (deg/s)')
% ax = gca;
% ax.TickDir = 'out';
% ax.LineWidth = 1;


%% CHECK VIEWING DISTANCE. Visualisation of viewing distance. 

% data_type = "heading_wrap"; 
% cond_data_theta = combine_timeseries_across_exp(data, condition_n, data_type);
% 
% rng = 380:440;
% 
% x = cond_data_x(id, rng);
% y = cond_data_y(id, rng);
% theta = deg2rad(cond_data_theta(id, rng));
% r = 121;
% 
% % Number of time points
% N = length(x);
% % t_vals = zeros(1,N);
% 
% % Prepare figure
% figure;
% hold on;
% axis equal;
% viscircles([cx, cy], r, 'LineStyle', '--', 'Color', [0.7 0.7 0.7]);
% 
% % Scatter agent positions
% scatter(x, y, 10, 'k', 'filled');
% 
% % For each time step, compute arrow endpoint at wall
% for i = 1:N
%     % Agent position
%     x0 = x(i);
%     y0 = y(i);
% 
%     % Heading vector
%     dx = cos(theta(i));
%     dy = sin(theta(i));
% 
%     % Solve for intersection of ray (x0 + t*dx, y0 + t*dy) with circle
%     % (x - cx)^2 + (y - cy)^2 = r^2
% 
%     % Shift coordinates relative to center
%     x_rel = x0 - cx;
%     y_rel = y0 - cy;
% 
%     A = dx^2 + dy^2;
%     B = 2 * (x_rel*dx + y_rel*dy);
%     C = x_rel^2 + y_rel^2 - r^2;
% 
%     discriminant = B^2 - 4*A*C;
% 
%     if discriminant >= 0
%         t1 = (-B + sqrt(discriminant)) / (2*A);
%         t2 = (-B - sqrt(discriminant)) / (2*A);
% 
%         % Choose smallest positive t
%         t_candidates = [t1, t2];
%         t_candidates(t_candidates < 0) = inf;
%         t = min(t_candidates);
%         % t_vals(i) = t;
% 
%         t_norm = t/250;
% 
%         if isfinite(t)
%             % Compute intersection point
%             x_edge = x0 + t * dx;
%             y_edge = y0 + t * dy;
% 
%             % Draw arrow using a line (or use quiver for short arrows)
%             plot([x0, x_edge], [y0, y_edge], '-', 'Color', [1, t_norm, t_norm], 'LineWidth', 1);
%         end
%     end
% end
% 
% % Scatter agent positions
% scatter(x, y, 5, 'k', 'filled');
% axis equal
% axis off


%% Include turning rate versus viewing distance as a subplot too

% data_type = "curv_data"; 
% cond_data_curv = combine_timeseries_across_exp(data, condition_n, data_type);
% 
% rng = 300:550;
% sz = 40;
% 
% figure
% subplot(1,3,1)
% scatter(cond_data_vd(id, rng), abs(cond_data_curv(id, rng)), sz, rng, 'filled');
% xlabel('Viewing distance (mm)')
% ylabel('Turning rate (deg/mm)')
% % axis equal
% xlim([0 250])
% 
% subplot(1,3,2)
% scatter(cond_data_vd(id, rng), abs(cond_data_av(id, rng)), sz, rng, 'filled');
% xlabel('Viewing distance (mm)')
% ylabel('Angular velocity (deg/s)')
% % axis equal
% xlim([0 250])
% 
% subplot(1,3,3)
% scatter(cond_data_x(id, rng), abs(cond_data_y(id, rng)), sz, rng, 'filled');
% hold on 
% plot(cx, cy, 'r+', 'MarkerSize', 18, 'LineWidth', 1.5, 'DisplayName', 'Centre');
% xlabel('x')
% ylabel('y')
% axis equal
% xlim([80 160])
% 
% f = gcf;
% f.Position = [17 482  1750 500];






























