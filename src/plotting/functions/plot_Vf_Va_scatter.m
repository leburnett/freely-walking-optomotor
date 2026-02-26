function plot_Vf_Va_scatter(Vf_bin, Va_bin, col_bin, log_scale, flyId)

    % Plot guidelines
    hold on

    guideline_color = [0.8 0.8 0.8];
    linewidth = 0.5;

    % 1mm s-1
    plot([1 1], [0.1 1000], 'Color', guideline_color, 'LineWidth', linewidth);
    % 10 mm s-1
    plot([10 10], [0.1 1000], 'Color', guideline_color, 'LineWidth', linewidth);
    % 10 deg s-1
    plot([0.1 30], [10 10], 'Color', guideline_color, 'LineWidth', linewidth);
    % 90 deg s-1
    plot([0.1 30], [90 90], 'Color', guideline_color, 'LineWidth', linewidth);

    % Plot the data 
    scatter(Vf_bin(flyId, :), abs(Va_bin(flyId, :)), 50, col_bin, 'filled', 'LineWidth', 0.5, 'MarkerEdgeColor', [0.5 0.5 0.5]);

    % Add axis labels
    xlabel('Vf (mm s^-^1)')
    ylabel('Abs. Va (deg s^-^1)')

    % Format axes
    ax = gca; 
    ax.TickDir = 'out'; 
    ax.LineWidth = 1.2; 

    % Set axes to log scale if desired
    if log_scale
        ax.XScale = 'log'; 
        ax.YScale = 'log';
    else
        ax.XScale = 'linear'; 
        ax.YScale = 'linear';
    end 

    ax.FontSize = 14;
    ax.Position  = [0.13 0.165 0.3 0.7];
    ax.XLim = [0.1 30];
    ax.YLim = [0.1 1000];

end 