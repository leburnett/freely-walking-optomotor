function make_scatter_bar(data, feature)
% MAKE_SCATTER_BAR Create scatter plot with box plot overlay by condition
%
%   MAKE_SCATTER_BAR(data, feature) creates a combined scatter/box plot
%   showing individual fly data points with summary statistics.
%
% INPUTS:
%   data    - Per-condition data matrix [n_conditions x n_flies]
%   feature - String specifying data type: "dist", "angvel", "vel", or "ratio"
%
% FEATURE TYPES:
%   "dist"   - Distance from center (mm), ylim [0, 120]
%   "angvel" - Angular velocity (deg/s), ylim [0, 100]
%   "vel"    - Velocity (mm/s), ylim [0, 25]
%   "ratio"  - AV/V turning ratio (deg/mm), ylim [0, 40]
%
% CONDITIONS PLOTTED:
%   1. Off - Pattern off
%   2. On - Pattern displayed (static)
%   3. Opto - Optomotor (moving gratings)
%   4. Flicker - Temporal flicker control
%
% PLOT FEATURES:
%   - Individual data points with jittered x-positions
%   - Box plots showing median and quartiles
%   - Bold median line
%
% NOTES:
%   - Designed for protocol v1 data format
%   - Opto conditions averaged from rows 13:16 and 18:21
%   - Flicker from row 17
%
% See also: boxplot, scatter, plot_boxchart_metrics_xcond 

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