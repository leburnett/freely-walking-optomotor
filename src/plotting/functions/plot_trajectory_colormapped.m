function fig = plot_trajectory_colormapped(x, y, metric_vals, opts)
% PLOT_TRAJECTORY_COLORMAPPED  Plot fly trajectory colored by a metric.
%
%   fig = PLOT_TRAJECTORY_COLORMAPPED(x, y, metric_vals, opts)
%
%   Plots a single fly's trajectory in arena coordinates with scatter points
%   colored by a computed metric value. Essential for visually validating
%   that metric computations make spatial sense.
%
%   INPUTS:
%     x, y         - [1 x n_frames] position in mm (single fly)
%     metric_vals  - [1 x n_frames] metric to encode as color
%     opts         - struct with optional fields:
%       .arena_radius - for drawing arena boundary (default: 119)
%       .cmap         - colormap name or Nx3 matrix (default: 'parula')
%       .clim         - [min max] color limits (default: auto from data)
%       .title_str    - title string (default: '')
%       .cbar_label   - colorbar label (default: 'Metric')
%       .marker_size  - scatter dot size (default: 8)
%       .ax           - existing axes handle (for subplot use)
%
%   OUTPUT:
%     fig - figure handle (empty if opts.ax was provided)
%
%   EXAMPLE:
%     opts.cbar_label = '|AV| (deg/s)';
%     opts.title_str = 'Fly 1 — Angular Velocity';
%     plot_trajectory_colormapped(x(1,:), y(1,:), abs(av(1,:)), opts);
%
% See also: plot_diagnostic_single_fly

%% Parse options
if nargin < 4, opts = struct(); end
arena_r     = get_field(opts, 'arena_radius', 119);
cmap_name   = get_field(opts, 'cmap', 'parula');
clim_val    = get_field(opts, 'clim', []);
title_str   = get_field(opts, 'title_str', '');
cbar_label  = get_field(opts, 'cbar_label', 'Metric');
marker_size = get_field(opts, 'marker_size', 8);
ax_handle   = get_field(opts, 'ax', []);

%% Set up axes
if isempty(ax_handle)
    fig = figure('Position', [100 100 500 500]);
    ax_handle = gca;
else
    fig = [];
    axes(ax_handle);
end

hold(ax_handle, 'on');

%% Draw arena boundary
theta = linspace(0, 2*pi, 200);
plot(ax_handle, arena_r * cos(theta), arena_r * sin(theta), '-', ...
    'Color', [0.7 0.7 0.7], 'LineWidth', 1);

%% Plot trajectory colored by metric
valid = ~isnan(x) & ~isnan(y) & ~isnan(metric_vals);
scatter(ax_handle, x(valid), y(valid), marker_size, metric_vals(valid), 'filled');

%% Start/end markers
if any(valid)
    first_valid = find(valid, 1, 'first');
    last_valid  = find(valid, 1, 'last');
    plot(ax_handle, x(first_valid), y(first_valid), 'o', ...
        'MarkerSize', 10, 'MarkerFaceColor', [0.2 0.7 0.2], ...
        'MarkerEdgeColor', 'none');
    plot(ax_handle, x(last_valid), y(last_valid), 'o', ...
        'MarkerSize', 10, 'MarkerFaceColor', [0.8 0.2 0.2], ...
        'MarkerEdgeColor', 'none');
end

%% Colormap and limits
if ischar(cmap_name) || isstring(cmap_name)
    colormap(ax_handle, cmap_name);
else
    colormap(ax_handle, cmap_name);
end

if ~isempty(clim_val)
    clim(ax_handle, clim_val);
end

cb = colorbar(ax_handle);
cb.Label.String = cbar_label;
cb.Label.FontSize = 12;

%% Formatting
axis(ax_handle, 'equal');
xlim(ax_handle, [-arena_r-5, arena_r+5]);
ylim(ax_handle, [-arena_r-5, arena_r+5]);
xlabel(ax_handle, 'x (mm)', 'FontSize', 14);
ylabel(ax_handle, 'y (mm)', 'FontSize', 14);
if ~isempty(title_str)
    title(ax_handle, title_str, 'FontSize', 16);
end
set(ax_handle, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

end

%% Helper
function val = get_field(s, field, default)
    if isfield(s, field)
        val = s.(field);
    else
        val = default;
    end
end
