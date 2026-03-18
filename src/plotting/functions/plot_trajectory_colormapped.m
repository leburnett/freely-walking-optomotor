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
%       .arena_radius - for drawing arena boundary (default: 120)
%       .arena_center - [cx, cy] arena centre in mm (default: [126.6, 124.7])
%       .cmap         - colormap name or Nx3 matrix (default: 'parula')
%       .clim         - [min max] color limits (default: auto from data)
%       .title_str    - title string (default: '')
%       .cbar_label   - colorbar label (default: 'Metric')
%       .marker_size  - scatter dot size (default: 8, only used if line fails)
%       .clim_pct     - percentile range for auto clim (default: [1 99]).
%                       Ignored if .clim is set explicitly.
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
arena_r     = get_field(opts, 'arena_radius', 120);
arena_c     = get_field(opts, 'arena_center', [528, 520] / 4.1691);
cmap_name   = get_field(opts, 'cmap', 'parula');
clim_val    = get_field(opts, 'clim', []);
title_str   = get_field(opts, 'title_str', '');
cbar_label  = get_field(opts, 'cbar_label', 'Metric');
marker_size = get_field(opts, 'marker_size', 8);
clim_pct    = get_field(opts, 'clim_pct', [1 99]);
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
plot(ax_handle, arena_c(1) + arena_r * cos(theta), arena_c(2) + arena_r * sin(theta), '-', ...
    'Color', [0.7 0.7 0.7], 'LineWidth', 1);

%% Plot trajectory as a connected coloured line
% Uses patch with edge colors interpolated from vertex CData.
% Where NaN gaps exist, break into contiguous segments.
valid = ~isnan(x) & ~isnan(y) & ~isnan(metric_vals);

% Auto clim from percentiles if not set explicitly
if isempty(clim_val)
    vals_valid = metric_vals(valid);
    if ~isempty(vals_valid)
        clim_val = prctile(vals_valid, clim_pct);
        if clim_val(1) == clim_val(2)
            clim_val = [clim_val(1) - 1, clim_val(2) + 1];
        end
    end
end

% Find contiguous valid segments and plot each as a patch line
d_valid = diff([0, valid, 0]);
seg_starts = find(d_valid == 1);
seg_ends   = find(d_valid == -1) - 1;

for s = 1:numel(seg_starts)
    idx = seg_starts(s):seg_ends(s);
    if numel(idx) < 2, continue; end
    % patch trick: vertices = [x; y], faces connect consecutive vertices
    % CData on vertices gives interpolated edge color
    patch(ax_handle, [x(idx) NaN], [y(idx) NaN], 0, ...
        'EdgeColor', 'interp', 'FaceColor', 'none', ...
        'CData', [metric_vals(idx) NaN], 'LineWidth', 1.2);
end

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
colormap(ax_handle, cmap_name);

if ~isempty(clim_val)
    clim(ax_handle, clim_val);
end

cb = colorbar(ax_handle);
cb.Label.String = cbar_label;
cb.Label.FontSize = 12;

%% Formatting
axis(ax_handle, 'equal');
xlim(ax_handle, [arena_c(1)-arena_r-5, arena_c(1)+arena_r+5]);
ylim(ax_handle, [arena_c(2)-arena_r-5, arena_c(2)+arena_r+5]);
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
