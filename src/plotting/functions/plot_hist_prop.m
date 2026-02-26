function plot_hist_prop(data, feature)

    % Histogram of prop of exp spend < 2mms-1 per fly
    n_flies = numel(data(:,1));
    p = zeros(n_flies, 1);

    if feature == "slow"
        val = 2; 
    elseif feature == "centre"
        val = 30; 
    end 

    for j = 1:n_flies
        data_fly = data(j, :);
        frames_slow = find(data_fly<val);
        frames_all = data_fly(~isnan(data_fly));
        p(j,1) = numel(frames_slow)/numel(frames_all);
    end

    med_val = nanmedian(p);
    mean_val = nanmean(p);

    histogram(p, 'BinEdges', [0:0.05:1], 'Normalization', 'probability', 'FaceColor', [0.7 0.7 0.7]);
    box off
    if feature == "slow"
        xlabel('Proportion of exp < 2mm s-1')
    elseif feature == "centre"
        xlabel('Proportion of exp <30mm from centre')
    end 
    ylabel('Probability')
    ylim([0 0.5])
    set(gca, 'TickDir', 'out')
    hold on
    % Plot lines with mean and median values.
    plot([med_val, med_val], [0, 1], 'k')
    plot([mean_val, mean_val], [0, 1], 'r')
    % Add text with mean and median values. 
    text(0.95, 0.45, strcat('Med:', num2str(med_val, 3)), 'HorizontalAlignment','right')
    text(0.95, 0.4, strcat('Mean:', num2str(mean_val, 3)),"Color", 'r', 'HorizontalAlignment','right')

end 