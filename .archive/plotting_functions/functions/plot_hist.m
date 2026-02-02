function plot_hist(data, nbins, feature)

    max_val = max(max(max(data, 2)));
    med_val = nanmedian(nanmedian(data, 2));
    mean_val = nanmean(nanmean(data, 2));

    if feature == "angvel" || feature == "heading"
        min_val = min(min(data,2));
    else
        min_val = 0;
    end 

    edges = min_val:ceil(max_val/nbins):max_val;
    txt_val = prctile(edges, 95);
    histogram(data, 'BinEdges', edges, 'Normalization', 'probability', 'FaceColor', [0.7 0.7 0.7]);
    box off
    if feature == "vel"
        xlabel('Forward velocity (mm s-1)')
        lims =[0 1];
    elseif feature == "angvel"
        xlabel('Angular velocity (deg s-1)') 
        lims =[0 0.25];
    elseif feature == "dist"
        xlabel('Distance from centre (mm)')
        lims = [0 0.25];
    elseif feature == "heading"
        xlabel('Heading (deg)')
        lims =[0 0.25];
    end 
    ylim(lims)
    ylabel('Probability')
    set(gca, 'TickDir', 'out')
    hold on
    % Plot lines with mean and median values.
    plot([med_val, med_val], [0, 1], 'k')
    plot([mean_val, mean_val], [0, 1], 'r')
    % Add text with mean and median values. 
    text(txt_val, lims(2)*0.9, strcat('Med:', num2str(med_val,3)), 'HorizontalAlignment','right')
    text(txt_val, lims(2)*0.8, strcat('Mean:', num2str(mean_val,3)),"Color", 'r', 'HorizontalAlignment','right')

end 