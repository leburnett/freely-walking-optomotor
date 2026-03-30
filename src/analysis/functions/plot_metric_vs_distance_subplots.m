function [fig_scatter, fig_slopes] = plot_metric_vs_distance_subplots(flat_table, metric_field, opts)
% PLOT_METRIC_VS_DISTANCE_SUBPLOTS  Per-strain scatter subplots + slope bar chart.
%
%   [fig_scatter, fig_slopes] = PLOT_METRIC_VS_DISTANCE_SUBPLOTS(flat_table, metric_field)
%   [fig_scatter, fig_slopes] = PLOT_METRIC_VS_DISTANCE_SUBPLOTS(flat_table, metric_field, opts)
%
%   Creates two figures:
%     1. Grid of scatter subplots (one per strain) with linear trend line
%     2. Bar chart of the trend line slope per strain
%
%   INPUTS:
%     flat_table    - struct with at least:
%                       .strain           {n x 1} cell
%                       .bbox_dist_center [n x 1] distance from arena centre
%                       .(metric_field)   [n x 1] metric values
%     metric_field  - string, field name in flat_table to plot on y-axis
%     opts          - (optional) struct:
%       .control_strain - string (default: "jfrc100_es_shibire_kir")
%       .marker_size    - scalar (default: 20)
%       .arena_radius   - for x-axis limit (default: 120)
%       .ylabel_str     - y-axis label (default: metric_field)
%       .title_str      - sgtitle for scatter figure (default: auto)
%
%   OUTPUTS:
%     fig_scatter - figure handle for the scatter subplots
%     fig_slopes  - figure handle for the slope bar chart
%
% See also: plot_violin, plot_bbox_area_vs_distance

if nargin < 3, opts = struct(); end
control_strain = get_opt(opts, 'control_strain', "jfrc100_es_shibire_kir");
marker_size    = get_opt(opts, 'marker_size', 20);
arena_radius   = get_opt(opts, 'arena_radius', 120);
ylabel_str     = get_opt(opts, 'ylabel_str', strrep(metric_field, '_', ' '));
title_str      = get_opt(opts, 'title_str', ...
    sprintf('%s vs distance from arena centre', strrep(metric_field, '_', ' ')));

% Strain palette
strain_palette = [
    0.216 0.494 0.722;   0.894 0.102 0.110;   0.302 0.686 0.290;
    0.596 0.306 0.639;   1.000 0.498 0.000;   0.651 0.337 0.157;
    0.122 0.694 0.827;   0.890 0.467 0.761;   0.737 0.741 0.133;
    0.090 0.745 0.812;   0.682 0.780 0.910;   0.400 0.761 0.647;
    0.988 0.553 0.384;   0.553 0.627 0.796;   0.906 0.541 0.765;
    0.651 0.847 0.329;   0.463 0.380 0.482;   0.361 0.729 0.510;
    0.784 0.553 0.200];
n_palette = size(strain_palette, 1);
control_color = [0.7 0.7 0.7];

% Unique strains, control first
unique_strains = unique(flat_table.strain);
is_control = strcmp(unique_strains, control_strain);
strain_order = [unique_strains(is_control); unique_strains(~is_control)];
n_strains = numel(strain_order);

if n_strains == 0
    fig_scatter = figure(); fig_slopes = figure();
    return;
end

% Get metric values
metric_vals = flat_table.(metric_field);
dist_vals_all = flat_table.bbox_dist_center;

% Consistent y-limit
valid_all = ~isnan(metric_vals);
if any(valid_all)
    y_upper = prctile(metric_vals(valid_all), 98);
    y_upper = max(y_upper, 1);
else
    y_upper = 1;
end

% ===== Figure 1: scatter subplots =====
n_cols = ceil(sqrt(n_strains));
n_rows = ceil(n_strains / n_cols);

fig_scatter = figure('Position', [50 50 300*n_cols 250*n_rows]);
sgtitle(fig_scatter, title_str, 'FontSize', 18);

slopes = NaN(n_strains, 1);
slope_ci = NaN(n_strains, 2);  % 95% CI
strain_labels_short = cell(n_strains, 1);
strain_colors = zeros(n_strains, 3);
strain_n = zeros(n_strains, 1);
colour_idx = 0;

for si = 1:n_strains
    s_name = strain_order{si};
    idx = strcmp(flat_table.strain, s_name);
    n_loops = sum(idx);
    strain_n(si) = n_loops;

    if strcmp(s_name, control_strain)
        col = control_color;
    else
        colour_idx = colour_idx + 1;
        col = strain_palette(mod(colour_idx - 1, n_palette) + 1, :);
    end
    strain_colors(si, :) = col;

    % Short label for display
    display_name = strrep(s_name, '_shibire_kir', '');
    strain_labels_short{si} = display_name;

    ax = subplot(n_rows, n_cols, si);
    hold(ax, 'on');

    d = dist_vals_all(idx);
    m = metric_vals(idx);

    scatter(ax, d, m, marker_size, col, 'filled', ...
        'MarkerFaceAlpha', 0.4, 'MarkerEdgeColor', 'none');

    % Linear fit
    valid = ~isnan(d) & ~isnan(m);
    if sum(valid) >= 3
        p = polyfit(d(valid), m(valid), 1);
        slopes(si) = p(1);

        x_fit = linspace(0, arena_radius, 100);
        y_fit = polyval(p, x_fit);
        plot(ax, x_fit, y_fit, '-', 'Color', col, 'LineWidth', 2);

        % Bootstrap 95% CI for slope
        if sum(valid) >= 10
            n_boot = 500;
            boot_slopes = NaN(n_boot, 1);
            d_v = d(valid);
            m_v = m(valid);
            n_v = numel(d_v);
            for b = 1:n_boot
                bi = randi(n_v, n_v, 1);
                bp = polyfit(d_v(bi), m_v(bi), 1);
                boot_slopes(b) = bp(1);
            end
            slope_ci(si, :) = prctile(boot_slopes, [2.5 97.5]);
        end

        text(ax, 5, y_upper * 0.9, sprintf('slope = %.2f', p(1)), ...
            'FontSize', 9, 'Color', 'k', 'FontWeight', 'bold');
    end

    xlim(ax, [0 arena_radius + 5]);
    ylim(ax, [0 y_upper]);

    title(ax, sprintf('%s (n=%d)', strrep(display_name, '_', '\_'), n_loops), 'FontSize', 11);
    set(ax, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

    if mod(si-1, n_cols) == 0
        ylabel(ax, ylabel_str, 'FontSize', 11);
    end
    if si > (n_rows - 1) * n_cols
        xlabel(ax, 'Dist from centre (mm)', 'FontSize', 11);
    end
end

% ===== Figure 2: slope bar chart =====
fig_slopes = figure('Position', [100 100 max(200 + n_strains * 60, 600) 450]);
hold on;

for si = 1:n_strains
    bar_h = bar(si, slopes(si), 0.7);
    bar_h.FaceColor = strain_colors(si, :);
    bar_h.EdgeColor = 'none';

    % Error bars from bootstrap CI
    if ~isnan(slope_ci(si, 1))
        errorbar(si, slopes(si), ...
            slopes(si) - slope_ci(si, 1), ...
            slope_ci(si, 2) - slopes(si), ...
            'k', 'LineWidth', 1.2, 'CapSize', 6);
    end
end

% Zero line
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

set(gca, 'XTick', 1:n_strains, ...
    'XTickLabel', cellfun(@(s) strrep(s, '_', '\_'), strain_labels_short, 'UniformOutput', false), ...
    'XTickLabelRotation', 45);
xlim([0.3, n_strains + 0.7]);
ylabel(sprintf('Slope: %s per mm', ylabel_str), 'FontSize', 14);
title(sprintf('Trend slope: %s vs distance from centre', strrep(metric_field, '_', ' ')), ...
    'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
f = gcf;
f.Position = [54    47   634   260];

end

%% Helper
function val = get_opt(s, field, default)
if isfield(s, field)
    val = s.(field);
else
    val = default;
end
end
