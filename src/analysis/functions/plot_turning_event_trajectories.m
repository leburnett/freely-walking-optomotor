function fig = plot_turning_event_trajectories(events, geom, x, y, opts)
% PLOT_TURNING_EVENT_TRAJECTORIES  Small multiples of individual turning events.
%
%   fig = PLOT_TURNING_EVENT_TRAJECTORIES(events, geom, x, y, opts)
%
%   Shows individual 360-degree turning events as separate small panels with
%   bounding boxes. Useful for checking whether the 360-degree criterion
%   produces sensible trajectory segments.
%
%   INPUTS:
%     events - struct from detect_360_turning_events (one fly)
%     geom   - struct from compute_turning_event_geometry (one fly)
%     x, y   - [1 x n_frames] trajectory for this fly (mm)
%     opts   - struct with optional fields:
%       .max_events   - max panels to show (default: 12)
%       .arena_radius - arena radius in mm (default: 119)
%       .fps          - frames per second (default: 30)
%
%   OUTPUT:
%     fig - figure handle
%
%   Each panel shows:
%     - Trajectory segment colored by time within the event
%     - Bounding box rectangle (dashed grey)
%     - Centre of mass marker (x)
%     - Duration and area annotation
%
% See also: detect_360_turning_events, compute_turning_event_geometry

%% Parse options
if nargin < 5, opts = struct(); end
max_events = get_field(opts, 'max_events', 12);
arena_r    = get_field(opts, 'arena_radius', 120);
fps        = get_field(opts, 'fps', 30);

n_events = min(events.n_events, max_events);

if n_events == 0
    fig = figure;
    text(0.5, 0.5, 'No turning events detected', ...
        'HorizontalAlignment', 'center', 'FontSize', 16);
    axis off;
    return;
end

% Grid layout
n_cols = min(4, n_events);
n_rows = ceil(n_events / n_cols);

fig = figure('Position', [50 50 300*n_cols 300*n_rows]);
tl = tiledlayout(n_rows, n_cols, 'TileSpacing', 'compact', 'Padding', 'compact');
sgtitle(tl, sprintf('Turning Events (showing %d of %d)', n_events, events.n_events), ...
    'FontSize', 16);

for e = 1:n_events
    ax = nexttile(tl);
    hold(ax, 'on');

    sf = max(events.start_frame(e), 1);
    ef = min(events.end_frame(e), numel(x));

    x_seg = x(sf:ef);
    y_seg = y(sf:ef);

    % Remove NaN
    valid = ~isnan(x_seg) & ~isnan(y_seg);
    x_v = x_seg(valid);
    y_v = y_seg(valid);
    n_pts = sum(valid);

    if n_pts < 3
        text(ax, 0.5, 0.5, 'Too few points', 'HorizontalAlignment', 'center');
        axis(ax, 'off');
        continue;
    end

    % Color by time within event
    time_color = (1:n_pts)' / n_pts;
    scatter(ax, x_v, y_v, 12, time_color, 'filled');
    colormap(ax, 'copper');

    % Bounding box
    if ~isnan(geom.bbox_area(e))
        bx_min = min(x_v); bx_max = max(x_v);
        by_min = min(y_v); by_max = max(y_v);
        rectangle(ax, 'Position', [bx_min, by_min, bx_max-bx_min, by_max-by_min], ...
            'EdgeColor', [0.5 0.5 0.5], 'LineWidth', 1, 'LineStyle', '--');

        % Centre of mass marker
        plot(ax, geom.bbox_center_x(e), geom.bbox_center_y(e), 'x', ...
            'Color', [0.8 0.2 0.2], 'MarkerSize', 10, 'LineWidth', 2);
    end

    % Start/end markers
    plot(ax, x_v(1), y_v(1), 'o', 'MarkerSize', 8, ...
        'MarkerFaceColor', [0.2 0.7 0.2], 'MarkerEdgeColor', 'none');
    plot(ax, x_v(end), y_v(end), 'o', 'MarkerSize', 8, ...
        'MarkerFaceColor', [0.8 0.2 0.2], 'MarkerEdgeColor', 'none');

    % Annotation
    dur_s = events.duration_s(e);
    area_mm2 = geom.bbox_area(e);
    aspect = geom.bbox_aspect(e);
    dir_str = ternary(events.direction(e) > 0, 'CCW', 'CW');

    title(ax, sprintf('#%d %s  %.1fs  AR=%.1f', e, dir_str, dur_s, aspect), 'FontSize', 12);

    axis(ax, 'equal');
    set(ax, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1);
end

end

%% Local helpers
function val = get_field(s, field, default)
    if isfield(s, field)
        val = s.(field);
    else
        val = default;
    end
end

function result = ternary(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end
