function plot_traj_vd_av(fly_id, rng, vd_data, av_data, x_data, y_data, cx, cy)

    sz = 40; 
    
    figure
    tiledlayout(1,2,"TileSpacing", "tight", "Padding","loose")
    
    nexttile
    scatter(vd_data(fly_id, rng), abs(av_data(fly_id, rng)), sz, rng, 'filled');
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
    if cx ~= 0 
        rectangle('Position',[0.25, 2.5, 245, 245], 'Curvature', [1,1], 'FaceColor', [0.95 0.95 0.95], 'EdgeColor', 'none')
    else
        rectangle('Position',[-121.25, -121.5, 244, 244], 'Curvature', [1,1], 'FaceColor', [0.95 0.95 0.95], 'EdgeColor', 'none')
    end 
    viscircles([cx, cy], 121, 'Color', [0.8 0.8 0.8], 'LineStyle', '-', 'LineWidth', 1) % Edge
    viscircles([cx, cy], 110, 'Color', [0.8 0.8 0.8], 'LineStyle', '--', 'LineWidth',1) % 10mm from edge
    viscircles([cx, cy], 63, 'Color', [0.8 0.8 0.8], 'LineStyle', '--', 'LineWidth',1) % Half way
    hold on;
    scatter(x_data(fly_id, rng), y_data(fly_id, rng), sz/2, rng, 'filled');
    hold on 
    plot(cx, cy, 'r+', 'MarkerSize', 18, 'LineWidth', 1.5, 'DisplayName', 'Centre');
    axis off
    title(fly_id)
    
    f = gcf;
    f.Position = [ 240   592   829   388];


end 