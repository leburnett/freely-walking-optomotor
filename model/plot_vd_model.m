
figure
tiledlayout(1,5,"TileSpacing","compact");

for k = 1:5

    [x_traj, y_traj, theta_traj, v_traj, g_traj, vd_traj] = simulate_walking_viewdist_gain(k*2);
    
    nexttile
    plot(x_traj, y_traj, 'k', 'LineWidth', 1.2);
    hold on;
    plot(x_traj(1), y_traj(1), 'o', 'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'DisplayName', 'Start'); % green start
    plot(x_traj(end), y_traj(end), 'o', 'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerEdgeColor', 'k', 'DisplayName', 'End'); % red end
    viscircles([0 0], arena_radius, 'LineStyle', '--', 'Color', [0.5 0.5 0.5]);
    % axis equal;
    axis off;
    title(strcat("k = ", string(k)))
end

f = gcf;
f.Position = [14         604        1734         277];



figure; 
plot(vd_traj, g_traj, 'ko')