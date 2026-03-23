function fig = plot_bbox_area_vs_distance(flat_table, opts)
% PLOT_BBOX_AREA_VS_DISTANCE  Scatter subplots of loop bbox area vs distance from centre.
%
%   fig = PLOT_BBOX_AREA_VS_DISTANCE(flat_table)
%   fig = PLOT_BBOX_AREA_VS_DISTANCE(flat_table, opts)
%
%   One subplot per strain. Each subplot shows bbox_area vs bbox_dist_center
%   with a linear trend line.
%
%   INPUTS:
%     flat_table - struct with at least:
%                    .strain           {n x 1} cell of strain names
%                    .bbox_area        [n x 1] bounding box area (mm²)
%                    .bbox_dist_center [n x 1] distance from arena centre (mm)
%     opts       - (optional) struct:
%       .control_strain - string (default: "jfrc100_es_shibire_kir")
%       .marker_size    - scalar (default: 20)
%       .arena_radius   - for x-axis limit (default: 120)
%
%   OUTPUT:
%     fig - figure handle
%
% See also: find_trajectory_loops, temp_loop_segmentation_gui

if nargin < 2, opts = struct(); end
control_strain = get_opt(opts, 'control_strain', "jfrc100_es_shibire_kir");
marker_size    = get_opt(opts, 'marker_size', 20);
arena_radius   = get_opt(opts, 'arena_radius', 120);

% Strain palette (from CLAUDE.md)
strain_palette = [
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
n_palette = size(strain_palette, 1);
control_color = [0.7 0.7 0.7];

% Get unique strains, control first
unique_strains = unique(flat_table.strain);
is_control = strcmp(unique_strains, control_strain);
strain_order = [unique_strains(is_control); unique_strains(~is_control)];
n_strains = numel(strain_order);

if n_strains == 0
    fig = figure();
    text(0.5, 0.5, 'No data', 'HorizontalAlignment', 'center');
    return;
end

% Determine subplot grid
n_cols = ceil(sqrt(n_strains));
n_rows = ceil(n_strains / n_cols);

fig = figure('Position', [50 50 300*n_cols 250*n_rows]);
sgtitle('Loop bounding box area vs distance from arena centre', 'FontSize', 18);

% Find global y-limit for consistent axes
all_areas = flat_table.bbox_area(~isnan(flat_table.bbox_area));
if ~isempty(all_areas)
    y_upper = prctile(all_areas, 98);
    y_upper = max(y_upper, 50);
else
    y_upper = 100;
end

colour_idx = 0;

for si = 1:n_strains
    s_name = strain_order{si};
    idx = strcmp(flat_table.strain, s_name);
    n_loops = sum(idx);

    if strcmp(s_name, control_strain)
        col = control_color;
    else
        colour_idx = colour_idx + 1;
        col = strain_palette(mod(colour_idx - 1, n_palette) + 1, :);
    end

    ax = subplot(n_rows, n_cols, si);
    hold(ax, 'on');

    dist_vals = flat_table.bbox_dist_center(idx);
    area_vals = flat_table.bbox_area(idx);

    % Scatter
    scatter(ax, dist_vals, area_vals, marker_size, col, 'filled', ...
        'MarkerFaceAlpha', 0.4, 'MarkerEdgeColor', 'none');

    % Linear trend line
    valid = ~isnan(dist_vals) & ~isnan(area_vals);
    if sum(valid) >= 3
        p = polyfit(dist_vals(valid), area_vals(valid), 1);
        x_fit = linspace(0, arena_radius, 100);
        y_fit = polyval(p, x_fit);
        plot(ax, x_fit, y_fit, '-', 'Color', col, 'LineWidth', 2);

        % Annotate slope
        text(ax, 5, y_upper * 0.9, sprintf('slope = %.1f', p(1)), ...
            'FontSize', 9, 'Color', col, 'FontWeight', 'bold');
    end

    xlim(ax, [0 arena_radius + 5]);
    ylim(ax, [0 y_upper]);

    % Strain name as title (truncate for readability)
    display_name = strrep(s_name, '_shibire_kir', '');
    display_name = strrep(display_name, '_', '\_');
    title(ax, sprintf('%s (n=%d)', display_name, n_loops), 'FontSize', 11);

    set(ax, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

    if mod(si-1, n_cols) == 0
        ylabel(ax, 'Area (mm²)', 'FontSize', 11);
    end
    if si > (n_rows - 1) * n_cols
        xlabel(ax, 'Dist from centre (mm)', 'FontSize', 11);
    end
end

end

%% Helper
function val = get_opt(s, field, default)
if isfield(s, field)
    val = s.(field);
else
    val = default;
end
end
