function fig = plot_metric_vs_wall_distance(bin_centres, bin_means, bin_sems, opts)
% PLOT_METRIC_VS_WALL_DISTANCE  Line + SEM shading of metric vs distance from centre.
%
%   fig = PLOT_METRIC_VS_WALL_DISTANCE(bin_centres, bin_means, bin_sems, opts)
%
%   Plots one or more groups as mean lines with SEM shading, binned by
%   distance from the arena centre. Optionally overlays a linear fit with
%   slope annotation.
%
%   NOTE: Despite the legacy function name, bin_centres should now represent
%   distance from arena centre (mm), not distance from wall.
%
%   INPUTS:
%     bin_centres - [1 x n_bins] distance-from-centre bin centres (mm)
%     bin_means   - [1 x n_bins] or [n_groups x n_bins] mean metric values
%     bin_sems    - [1 x n_bins] or [n_groups x n_bins] SEM values
%     opts        - struct with optional fields:
%       .colors      - [n_groups x 3] RGB colors (default: black or blue gradient)
%       .labels      - cell array of group labels for legend
%       .ylabel_str  - y-axis label (default: 'Metric')
%       .title_str   - title string (default: '')
%       .show_fit    - logical, overlay linear fit (default: false)
%       .ax          - existing axes handle (for subplot use)
%       .alpha       - SEM shading alpha (default: 0.15)
%
%   OUTPUT:
%     fig - figure handle (empty if opts.ax was provided)
%
%   EXAMPLE:
%     opts.ylabel_str = '|AV| (deg/s)';
%     opts.title_str = 'Angular Velocity vs Distance from Centre';
%     opts.show_fit = true;
%     plot_metric_vs_wall_distance(bin_centres, means, sems, opts);
%
% See also: bin_metric_by_wall_distance

%% Parse options
if nargin < 4, opts = struct(); end
ylabel_str = get_field(opts, 'ylabel_str', 'Metric');
title_str  = get_field(opts, 'title_str', '');
show_fit   = get_field(opts, 'show_fit', false);
ax_handle  = get_field(opts, 'ax', []);
alpha_val  = get_field(opts, 'alpha', 0.15);

n_groups = size(bin_means, 1);

% Default colors
if isfield(opts, 'colors')
    colors = opts.colors;
else
    if n_groups == 1
        colors = [0 0 0];
    else
        colors = interp1([1; n_groups], [0.75 0.85 0.95; 0.10 0.25 0.54], 1:n_groups);
    end
end

labels = get_field(opts, 'labels', {});

%% Set up axes
if isempty(ax_handle)
    fig = figure('Position', [100 100 600 450]);
    ax_handle = gca;
else
    fig = [];
    axes(ax_handle);
end

hold(ax_handle, 'on');

%% Plot each group
for g = 1:n_groups
    m = bin_means(g, :);
    s = bin_sems(g, :);

    % SEM shading
    valid = ~isnan(m) & ~isnan(s);
    bc_v = bin_centres(valid);
    m_v  = m(valid);
    s_v  = s(valid);

    if numel(bc_v) >= 2
        y_upper = m_v + s_v;
        y_lower = m_v - s_v;
        patch(ax_handle, [bc_v fliplr(bc_v)], [y_upper fliplr(y_lower)], ...
            colors(g, :), 'FaceAlpha', alpha_val, 'EdgeColor', 'none');
    end

    % Mean line
    if ~isempty(labels) && g <= numel(labels)
        plot(ax_handle, bc_v, m_v, '-', 'Color', colors(g, :), ...
            'LineWidth', 1.5, 'DisplayName', labels{g});
    else
        plot(ax_handle, bc_v, m_v, '-', 'Color', colors(g, :), 'LineWidth', 1.5);
    end

    % Linear fit overlay
    if show_fit && numel(bc_v) >= 3
        p = polyfit(bc_v, m_v, 1);
        y_fit = polyval(p, bc_v);
        plot(ax_handle, bc_v, y_fit, '-', 'Color', colors(g, :), ...
            'LineWidth', 1, 'LineStyle', '--', 'HandleVisibility', 'off');
        % Slope annotation (top-right of this line)
        text(ax_handle, bc_v(end)*0.85, m_v(end)*1.05, ...
            sprintf('slope=%.3f', p(1)), 'Color', colors(g, :), 'FontSize', 10);
    end
end

%% Formatting
xlabel(ax_handle, 'Distance from arena centre (mm)', 'FontSize', 14);
ylabel(ax_handle, ylabel_str, 'FontSize', 14);
if ~isempty(title_str)
    title(ax_handle, title_str, 'FontSize', 16);
end
% if ~isempty(labels) && n_groups > 1
%     legend(ax_handle, 'Location', 'best');
% end
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
