function [fig, ax] = plot_violin(group_data, group_labels, opts)
% PLOT_VIOLIN  Violin plot with individual data points overlaid.
%
%   [fig, ax] = PLOT_VIOLIN(group_data, group_labels, opts)
%
%   Creates a violin plot similar to the dashboard style: kernel density
%   estimate on each side, with individual data points jittered on top.
%
%   INPUTS:
%     group_data   - {n_groups x 1} cell array, each cell contains a numeric
%                    vector of values for that group
%     group_labels - {n_groups x 1} cell array of display labels (strings)
%     opts         - (optional) struct:
%       .colors          [n_groups x 3] RGB per group (default: strain palette)
%       .ylabel_str      y-axis label (default: '')
%       .title_str       title (default: '')
%       .marker_size     individual point size (default: 15)
%       .marker_alpha    individual point alpha (default: 0.4)
%       .violin_alpha    violin fill alpha (default: 0.3)
%       .bandwidth       KDE bandwidth (default: auto)
%       .show_median     show median line (default: true)
%       .show_mean       show mean diamond (default: false)
%       .ax              existing axes handle (default: create new figure)
%       .violin_width    max half-width of violin (default: 0.35)
%       .n_kde_points    number of KDE evaluation points (default: 100)
%
%   OUTPUTS:
%     fig - figure handle (empty if opts.ax was provided)
%     ax  - axes handle
%
% See also: plot_bbox_area_vs_distance, temp_loop_metrics_plots

if nargin < 3, opts = struct(); end

% Defaults
marker_size   = get_opt(opts, 'marker_size', 15);
marker_alpha  = get_opt(opts, 'marker_alpha', 0.4);
violin_alpha  = get_opt(opts, 'violin_alpha', 0.3);
ylabel_str    = get_opt(opts, 'ylabel_str', '');
title_str     = get_opt(opts, 'title_str', '');
show_median   = get_opt(opts, 'show_median', true);
show_mean     = get_opt(opts, 'show_mean', false);
violin_width  = get_opt(opts, 'violin_width', 0.3);
n_kde         = get_opt(opts, 'n_kde_points', 100);

% Strain palette
default_colors = [
    0.7   0.7   0.7;     % grey (control)
    0.216 0.494 0.722;   % blue
    0.894 0.102 0.110;   % red
    0.302 0.686 0.290;   % green
    0.596 0.306 0.639;   % purple
    1.000 0.498 0.000;   % orange
    0.651 0.337 0.157;   % brown
    0.122 0.694 0.827;   % cyan
    0.890 0.467 0.761;   % pink
    0.737 0.741 0.133;   % olive
    0.090 0.745 0.812;   % teal
    0.682 0.780 0.910;   % light blue
    0.400 0.761 0.647;   % mint
    0.988 0.553 0.384;   % salmon
    0.553 0.627 0.796;   % slate blue
    0.906 0.541 0.765;   % orchid
    0.651 0.847 0.329;   % lime
    0.463 0.380 0.482;   % plum
    0.361 0.729 0.510;   % jade
    0.784 0.553 0.200;   % amber
];
colors = get_opt(opts, 'colors', default_colors);
n_colors = size(colors, 1);

n_groups = numel(group_data);

% Create figure or use existing axes
if isfield(opts, 'ax') && ~isempty(opts.ax)
    ax = opts.ax;
    fig = [];
else
    fig = figure('Position', [100 100 max(200 + n_groups * 80, 600) 500]);
    ax = gca;
end
hold(ax, 'on');

medians = NaN(1, n_groups);  % for annotation after ylim is set

for g = 1:n_groups
    vals = group_data{g};
    vals = vals(~isnan(vals));
    x_center = g;
    col = colors(mod(g - 1, n_colors) + 1, :);

    if numel(vals) < 3
        % Too few points for KDE — just plot individual points
        if ~isempty(vals)
            jitter = (rand(size(vals)) - 0.5) * 0.3;
            scatter(ax, x_center + jitter, vals, marker_size, col, 'filled', ...
                'MarkerFaceAlpha', marker_alpha);
        end
        continue;
    end

    % Kernel density estimate
    [f_kde, xi] = ksdensity(vals, 'NumPoints', n_kde);
    if isfield(opts, 'bandwidth') && ~isempty(opts.bandwidth)
        [f_kde, xi] = ksdensity(vals, 'NumPoints', n_kde, 'Bandwidth', opts.bandwidth);
    end

    % Normalise density to desired violin width
    f_kde = f_kde / max(f_kde) * violin_width;

    % Draw violin (symmetric halves)
    fill(ax, [x_center + f_kde, x_center - fliplr(f_kde)], ...
         [xi, fliplr(xi)], col, ...
         'FaceAlpha', violin_alpha, 'EdgeColor', col, 'LineWidth', 1);

    % Individual points with jitter (proportional to local density)
    jitter = zeros(size(vals));
    for j = 1:numel(vals)
        [~, closest] = min(abs(xi - vals(j)));
        local_w = f_kde(closest) * 0.8;
        jitter(j) = (rand - 0.5) * 2 * local_w;
    end
    scatter(ax, x_center + jitter, vals, marker_size, col, 'filled', ...
        'MarkerFaceAlpha', marker_alpha);

    % Median line
    if show_median
        med_val = median(vals);
        [~, closest] = min(abs(xi - med_val));
        med_w = f_kde(closest);
        plot(ax, [x_center - med_w, x_center + med_w], [med_val, med_val], ...
            '-', 'Color', col * 0.6, 'LineWidth', 2.5);
        % Store median for annotation (added after ylim is set)
        medians(g) = med_val;
    end

    % Mean diamond
    % if show_mean
    %     mean_val = mean(vals);
    %     plot(ax, x_center, mean_val, 'd', 'MarkerSize', 8, ...
    %         'MarkerFaceColor', 'w', 'MarkerEdgeColor', col * 0.6, 'LineWidth', 1.5);
    % end
end

% Formatting
set(ax, 'XTick', 1:n_groups, 'XTickLabel', group_labels, ...
    'XTickLabelRotation', 45);
xlim(ax, [0.3, n_groups + 0.7]);
ylabel(ax, ylabel_str, 'FontSize', 18);
% title(ax, title_str, 'FontSize', 16);
set(ax, 'FontSize', 18, 'TickDir', 'out', 'TickLength', [0.02 0.02], 'Box', 'off', 'LineWidth', 1.5);

% Add median value text above each violin at the y-axis upper limit
if show_median && exist('medians', 'var')
    yl = ylim(ax);
    for g = 1:n_groups
        if ~isnan(medians(g))
            text(ax, g, yl(2), sprintf('%.1f', medians(g)), ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', ...
                'FontSize', 18, 'FontWeight', 'bold', 'Color', [0.3 0.3 0.3]);
        end
    end
end

f = gcf;
f.Position = [53    47   751   260];

end

%% Helper
function val = get_opt(s, field, default)
if isfield(s, field)
    val = s.(field);
else
    val = default;
end
end
