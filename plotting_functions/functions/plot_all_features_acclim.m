function f = plot_all_features_acclim(LOG, comb_data, title_str)

    % Inputs
    % ______

    % Log : struct
    %       Struct of size [n_conditions x n_flies] with details about the
    %       contrast, direction, start and stop times and start and stop
    %       frames for each condition. 

    % comb_data : struct

    % title_str : str
    %       title to use in the plot.
    
    acclim_end = LOG.acclim_off1.stop_f;

    % Fixed paramters: 
    figure

    % % % % % % % % Subplot 1 = VELOCITY % % % % % % % % %
    velocity_data = comb_data.fv_data(:, 1:acclim_end);
    [n_flies, xmax] = size(velocity_data);
    velocity_data = bin_data(velocity_data, 15, 5, 1, xmax);
    [~, xmax_bin] = size(velocity_data);

    subplot(5, 5, 1:4)
    hold on;
    for idx = 1:n_flies
        plot(velocity_data(idx, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 0.2)
    end 
    % Plot the mean velocity
    mean_X_flies = nanmean(velocity_data);
    plot(mean_X_flies, 'w', 'LineWidth', 1.25)
    plot(smoothdata(mean_X_flies, 'lowess'), 'k', 'LineWidth', 1.25)
    ylabel('Forward velocity (mm s-1)')
    max_val = max(velocity_data(:));
    ylim([-2 max_val])
    xlim([0 xmax_bin])
    ax = gca; ax.XAxis.Visible = 'off'; ax.TickDir = 'out'; box off

    % Boxplot & scatter - one datapoint per fly.
    mean_per_fly = nanmean(velocity_data, 2);
    max_y_per_fly = max(mean_per_fly)*1.1;

    subplot(5,5,5)
    boxchart(mean_per_fly)
    hold on
    scatter(ones(1, n_flies), mean_per_fly, 40, 'o', 'MarkerEdgeColor', [0.2 0.2 0.2], 'LineWidth', 1.5)
    ylim([0 ceil(max_y_per_fly)])
    yticks([0 ceil(max_y_per_fly)])
    ax = gca; ax.TickDir = 'out'; ax.LineWidth = 1.2; ax.FontSize = 12; box off; ax.XAxis.Visible = 'off'; 
    title(sprintf('%0.2f', mean(mean_per_fly)))

    % % % % % % % % Subplot 2 = ANG VEL % % % % % % % % %

    ang_vel_data = abs(comb_data.av_data(:, 1:acclim_end));
    ang_vel_data = bin_data(ang_vel_data, 15, 5, 1, xmax);

    max_val = prctile(ang_vel_data(:), 98.5);
    % min_val = prctile(ang_vel_data(:), 1.5);

    subplot(5, 5, 6:9)
    hold on;
    for idx = 1:n_flies
        plot(ang_vel_data(idx, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 0.2); 
    end 

    % Plot the ang vel
    mean_X_flies = nanmean(ang_vel_data);
    plot(mean_X_flies, 'w', 'LineWidth', 1.25)
    plot(smoothdata(mean_X_flies, 'lowess'), 'k', 'LineWidth', 1.25)
    ylabel('Angular velocity (deg s-1)')
    ylim([0, max_val])
    xlim([0 xmax_bin])
    ax = gca; ax.XAxis.Visible = 'off'; ax.TickDir = 'out'; box off

    % Boxplot & scatter - one datapoint per fly.
    mean_per_fly = nanmean(ang_vel_data, 2);
    max_y_per_fly = max(mean_per_fly)*1.1;
    % min_y_per_fly = min(mean_per_fly)*1.1;

    subplot(5, 5, 10)
    boxchart(mean_per_fly)
    hold on
    scatter(ones(1, n_flies), mean_per_fly, 40, 'o', 'MarkerEdgeColor', [0.2 0.2 0.2], 'LineWidth', 1.5)
    ylim([0 ceil(max_y_per_fly)])
    yticks([0 ceil(max_y_per_fly)])
    ax = gca; ax.TickDir = 'out'; ax.LineWidth = 1.2; ax.FontSize = 12; box off; ax.XAxis.Visible = 'off'; 
    title(sprintf('%0.2f', mean(mean_per_fly)))

    % % % % % % % Subplot 3 = CURVATURE / Turning rate % % % % % % % % %

    curv_data = abs(comb_data.curv_data(:,  1:acclim_end));
    curv_data = bin_data(curv_data, 15, 5, 1, xmax);

    max_val = prctile(curv_data(:), 98.5);
    % min_val = prctile(curv_data(:), 1.5);

    subplot(5, 5, 11:14); 
    hold on;
    for idx = 1:n_flies
        plot(curv_data(idx, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5)
    end 

    % Plot 
    mean_X_flies = nanmean(curv_data);
    plot(mean_X_flies, 'w', 'LineWidth', 1.25)
    plot(smoothdata(mean_X_flies, 'lowess'), 'k', 'LineWidth', 1.25)
    ylabel('Curvature (deg/mm)')
    xlim([0 xmax_bin])
    ylim([0, max_val])
    ax = gca; ax.XAxis.Visible = 'off'; ax.TickDir = 'out'; box off

    % Boxplot & scatter - one datapoint per fly.
    mean_per_fly = nanmean(curv_data, 2);
    max_y_per_fly = max(mean_per_fly)*1.1;
    % min_y_per_fly = min(mean_per_fly)*1.1;

    subplot(5, 5, 15)
    boxchart(mean_per_fly)
    hold on
    scatter(ones(1, n_flies), mean_per_fly, 40, 'o', 'MarkerEdgeColor', [0.2 0.2 0.2], 'LineWidth', 1.5)
    ylim([0, ceil(max_y_per_fly)])
    yticks([0 ceil(max_y_per_fly)])
    ax = gca; ax.TickDir = 'out'; ax.LineWidth = 1.2; ax.FontSize = 12; box off; ax.XAxis.Visible = 'off'; 
    title(sprintf('%0.2f', mean(mean_per_fly)))

    % % % % % % % % Subplot 4 = DISTANCE FROM CENTRE - absolute % % % % % % % % %

    dist_data = comb_data.dist_data(:, 1:acclim_end);
    dist_data = bin_data(dist_data, 15, 5, 1, xmax);

    subplot(5, 5, 16:19)
    hold on;
    for idx = 1:n_flies
        plot(dist_data(idx, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 1)
    end 

    % Plot 
    mean_X_flies = nanmean(dist_data);
    plot(mean_X_flies, 'w', 'LineWidth', 1.25)
    plot(smoothdata(mean_X_flies, 'lowess'), 'k', 'LineWidth', 1.25)
    plot([0 xmax], [120 120], 'LineWidth', 1, 'Color', [0 0 0])
    plot([0 xmax], [0 0], 'LineWidth', 1, 'Color', [0 0 0])

    ylabel('Dist from the centre - abs (mm)')
    xlim([0 xmax_bin])
    ylim([-1, 120])
    ax = gca; ax.XAxis.Visible = 'off'; ax.TickDir = 'out'; box off

    % Boxplot & scatter - one datapoint per fly.
    mean_per_fly = nanmean(dist_data, 2);
    max_y_per_fly = max(mean_per_fly)*1.1;
    min_y_per_fly = min(mean_per_fly)*1.1;

    subplot(5, 5, 20)
    boxchart(mean_per_fly)
    hold on
    scatter(ones(1, n_flies), mean_per_fly, 40, 'o', 'MarkerEdgeColor', [0.2 0.2 0.2], 'LineWidth', 1.5)
    ylim([floor(min_y_per_fly) ceil(max_y_per_fly)])
    yticks([floor(min_y_per_fly) ceil(max_y_per_fly)])
    ax = gca; ax.TickDir = 'out'; ax.LineWidth = 1.2; ax.FontSize = 12; box off; ax.XAxis.Visible = 'off'; 
    title(sprintf('%0.2f', mean(mean_per_fly)))

    % % % % % % % % Subplot 5 = DISTANCE FROM CENTRE - DELTA - relative % % % % % % % % %

    dist_data = comb_data.dist_data(:, 1:acclim_end);
    dist_data = bin_data(dist_data, 15, 5, 1, xmax);
    dist_data_d= nan(size(dist_data));
    for fl = 1:n_flies
        dist_data_d(fl, :) = dist_data(fl, :) - dist_data(fl, 1);
    end 

    subplot(5, 5, 21:24)
    hold on;
    for idx = 1:n_flies
        plot(dist_data_d(idx, :), 'Color', [0.7 0.7 0.7], 'LineWidth', 1)
    end 

    % Plot 
    mean_X_flies = nanmean(dist_data_d);
    plot(mean_X_flies, 'w', 'LineWidth', 1.25)
    plot(smoothdata(mean_X_flies, 'lowess'), 'k', 'LineWidth', 1.25)
    plot([0 xmax], [0 0], 'LineWidth', 1, 'Color', [0 0 0])

    ylabel('Dist from the centre - rel (mm)')
    xlim([0 xmax_bin])
    ylim([min(dist_data_d(:)), max(dist_data_d(:))])
    ax = gca; ax.XAxis.Visible = 'off'; ax.TickDir = 'out'; box off

    % Boxplot & scatter - one datapoint per fly.
    mean_per_fly = nanmean(dist_data_d, 2);
    max_y_per_fly = max(mean_per_fly)*1.1;
    min_y_per_fly = min(mean_per_fly)*1.1;

    subplot(5, 5, 25)
    boxchart(mean_per_fly)
    hold on
    scatter(ones(1, n_flies), mean_per_fly, 40, 'o', 'MarkerEdgeColor', [0.2 0.2 0.2], 'LineWidth', 1.5)
    ylim([floor(min_y_per_fly) ceil(max_y_per_fly)])
    yticks([floor(min_y_per_fly), 0, ceil(max_y_per_fly)])
    ax = gca; ax.TickDir = 'out'; ax.LineWidth = 1.2; ax.FontSize = 12; box off; ax.XAxis.Visible = 'off'; 
    title(sprintf('%0.2f', mean(mean_per_fly)))

    title_str = strrep(title_str, '_', '-');
    sgtitle(strcat(title_str, ' - N=', string(n_flies)))
    f = gcf; 
    f.Position = [487    76   568   971]; 

end 