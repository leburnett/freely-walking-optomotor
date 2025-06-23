
figure
tiledlayout(1,5,"TileSpacing","compact");
base_bias = 0.1;

for k = 1:5

    if k>4 
        disp_params=1;
    else
        disp_params=0;
    end 

    [x_traj, y_traj, theta_traj, v_traj, g_traj, vd_traj] = simulate_walking_viewdist_gain(k, base_bias, disp_params);
    
    nexttile
    plot(x_traj, y_traj, 'k', 'LineWidth', 1.2);
    hold on;
    plot(x_traj(1), y_traj(1), 'o', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'DisplayName', 'Start'); % green start
    plot(x_traj(end), y_traj(end), 'o', 'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerEdgeColor', 'k', 'DisplayName', 'End'); % red end
    viscircles([0 0], arena_radius, 'LineStyle', '--', 'Color', [0.5 0.5 0.5]);
    plot(0, 0, 'r+', 'LineWidth', 1.2);
    % axis equal;
    axis off;
    title(strcat("k = ", string(k)))

end

f = gcf;
f.Position = [5         562        1795         336];



figure; 
plot(vd_traj, g_traj, 'ko')
xlabel('Viewing distance')
ylabel('Turning gain')


% 
% figure
% [x_traj, y_traj, theta_traj, v_traj, g_traj, vd_traj] = simulate_walking_viewdist_gain(k*2, base_bias);
% plot(x_traj, y_traj, 'k', 'LineWidth', 1.2);
% hold on;
% plot(x_traj(1), y_traj(1), 'o', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'DisplayName', 'Start'); % green start
% plot(x_traj(end), y_traj(end), 'o', 'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerEdgeColor', 'k', 'DisplayName', 'End'); % red end
% viscircles([0 0], arena_radius, 'LineStyle', '--', 'Color', [0.5 0.5 0.5]);
% plot(0, 0, 'r+', 'LineWidth', 1.2);
% % axis equal;
% axis off;
% title(strcat("k = ", string(k)))
% 
% 
% % 
% figure
% plot(vd_traj, g_traj, 'ko')

%% Viewing distance wrt x position - constant y and constant heading angle.

% % Parameters
% arena_radius = 12.5;
% theta = pi;  % 180 degrees, facing left
% y = 0;       % fixed vertical position
% 
% % Range of x-positions from -arena_radius to +arena_radius
% x_vals = linspace(-arena_radius, arena_radius, 500);
% viewing_dists = nan(size(x_vals));  % preallocate
% 
% % Loop over x positions
% for i = 1:length(x_vals)-1
%     x = x_vals(i);
% 
%     % Heading direction vector
%     dx = cos(theta);
%     dy = sin(theta);
% 
%     % Ray-circle intersection from (x, y) along heading
%     A = dx^2 + dy^2;
%     B = 2 * (x*dx + y*dy);
%     C = x^2 + y^2 - arena_radius^2;
%     discriminant = B^2 - 4*A*C;
% 
%     if discriminant >= 0
%         t1 = (-B + sqrt(discriminant)) / (2*A);
%         t2 = (-B - sqrt(discriminant)) / (2*A);
%         t_candidates = [t1, t2];
%         t_candidates(t_candidates < 0) = inf;  % only forward solutions
%         viewing_dists(i) = min(t_candidates);
%     else
%         viewing_dists(i) = NaN;  % no intersection
%     end
% end
% 
% % Plot
% figure;
% plot(x_vals, viewing_dists, 'LineWidth', 2);
% xlabel('x-position (y = 0)');
% ylabel('Viewing distance to arena wall');
% title('Viewing Distance Along Horizontal Midline (Heading = 180°)');
% grid off;
% xline(0, '--k');
% yline(0, '--k');
% 
% 

