function make_scatter_bar(data, feature)
% data can be one of the 'data_per_cond' arrays. 

if feature == "dist"
    data = 120-dist_data_per_cond_mean;
    ylims = [0 120];
elseif feature == "angvel"
    data = abs(rad2deg(ang_vel_data_per_cond_mean));
    ylims = [0 100];
elseif feature == "vel"
    data = vel_data_per_cond_mean;
    ylims = [0 25];
elseif feature == "ratio"
    data = abs(rad2deg(ratio_data_per_cond));
    ylims = [0 40];
end 

data_off = data(1, 2:end-1);
data_on = data(2, 2:end-1);

% protocol v1 
data_opto = data([13:16, 18:21], 2:end-1);
data_opto = mean(data_opto, 1);

data_flicker = data(17, 2:end-1);
% data_flicker = data([17,32], 2:end-1);
% data_flicker = mean(data_flicker, 1);

n_flies = size(data_off, 2);

% data
xvals = [ones(1,n_flies), ones(1,n_flies)*2, ones(1,n_flies)*3, ones(1,n_flies)*4];
yvals = [data_off, data_on, data_opto, data_flicker];

% plot
figure;
scatter(xvals ...
    , yvals ...
    , 50 ...
    , [0.6 0.6 0.6] ...
    , 'o' ...
    , 'XJitter', 'density' ...
    , 'XJitterWidth', 0.5 ...
    )
hold on
boxplot(yvals ...
    , xvals ...
    , 'Color', 'k' ...
    , 'Symbol', '' ...
    )
% plot median as darker
h = findobj(gca,'tag','Median');
set(h,'LineWidth',2.2)
box off
set(gca ...
    , 'TickDir', 'out' ...
    , 'TickLength', [0.02 0.02] ...
    , 'LineWidth', 1 ...
    , 'FontSize', 14 ...
    , 'FontName', 'Arial' ...
    , 'YLim', ylims ...
    )
set(gcf, 'Position', [37   590   255   438])
xticks([1,2,3,4])
xticklabels({'Off', 'On', 'Opto', 'Flicker'})
xtickangle(45)
if feature == "dist"
    ylabel('Distance from centre (mm)')
elseif feature == "angvel"
    ylabel('Angular velocity (deg s-1)')
elseif feature == "vel"
    ylabel('Velocity (mm s-1)')
elseif feature == "ratio"
    ylabel('AV/V ratio (deg/mm)')
end 


end 