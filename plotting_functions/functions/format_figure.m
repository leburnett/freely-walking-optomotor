function format_figure()
    box off
    ax = gca;
    ax.TickDir = 'out'; 
    ax.TickLength = [0.02, 0.02];
    ax.LineWidth = 1.2;
    ax.FontSize = 12;
end 