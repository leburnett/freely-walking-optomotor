function plot_hist_vel(data, nbins)

    max_vel = max(max(data, 2));
    med_vel = nanmedian(nanmedian(data, 2));
    mean_vel = nanmean(nanmean(data, 2));
    
    edges = [0:max_vel/nbins:max_vel];
    txt_val = prctile(edges, 60);
    histogram(data, 'BinEdges', edges, 'Normalization', 'probability', 'FaceColor', [0.7 0.7 0.7]);
    box off
    xlabel('Velocity (mm s-1)')
    ylabel('Probability')
    ylim([0 1])
    set(gca, 'TickDir', 'out')
    hold on
    % Plot lines with mean and median values.
    plot([med_vel, med_vel], [0, 1], 'k')
    plot([mean_vel, mean_vel], [0, 1], 'r')
    % Add text with mean and median values. 
    text(txt_val, 0.85, strcat('Med:', string(med_vel)))
    text(txt_val, 0.72, strcat('Mean:', string(mean_vel)),"Color", 'r')

end 