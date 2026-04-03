function fig = plot_sensitivity_heatmap(results, metric_name, opts)
% PLOT_SENSITIVITY_HEATMAP  Window-width sensitivity as a heatmap.
%
%   fig = PLOT_SENSITIVITY_HEATMAP(results, metric_name, opts)
%
%   Displays a heatmap showing how a metric's relationship with distance
%   from arena centre changes across different sliding window widths.
%
%   INPUTS:
%     results     - struct from sensitivity_analysis_windows, with fields:
%                   .window_range, .bin_centres, .av_heatmap, etc.
%     metric_name - string: 'av', 'curv', 'fv', or 'tort'
%     opts        - struct with optional fields:
%       .title_str - override title (default: auto-generated)
%       .cmap      - colormap name (default: 'viridis' if available, else 'parula')
%       .ax        - existing axes handle
%
%   OUTPUT:
%     fig - figure handle (empty if opts.ax was provided)
%
% See also: sensitivity_analysis_windows

%% Parse options
if nargin < 3, opts = struct(); end
ax_handle = get_field(opts, 'ax', []);
cmap_name = get_field(opts, 'cmap', 'parula');

%% Select heatmap data and label
switch lower(metric_name)
    case 'av'
        hmap = results.av_heatmap;
        default_title = 'Sensitivity: |Angular Velocity|';
        cbar_label = 'Mean |AV| (deg/s)';
    case 'curv'
        hmap = results.curv_heatmap;
        default_title = 'Sensitivity: |Curvature|';
        cbar_label = 'Mean |curvature| (deg/mm)';
    case 'fv'
        hmap = results.fv_heatmap;
        default_title = 'Sensitivity: Forward Velocity';
        cbar_label = 'Mean FV (mm/s)';
    case 'tort'
        hmap = results.tort_heatmap;
        default_title = 'Sensitivity: Tortuosity';
        cbar_label = 'Mean tortuosity';
    otherwise
        error('plot_sensitivity_heatmap: unknown metric "%s". Use av, curv, fv, or tort.', metric_name);
end

title_str = get_field(opts, 'title_str', default_title);

%% Set up axes
if isempty(ax_handle)
    fig = figure('Position', [100 100 600 450]);
    ax_handle = gca;
else
    fig = [];
    axes(ax_handle);
end

%% Plot heatmap
imagesc(ax_handle, results.bin_centres, results.window_range, hmap);
set(ax_handle, 'YDir', 'normal');

colormap(ax_handle, cmap_name);
cb = colorbar(ax_handle);
cb.Label.String = cbar_label;
cb.Label.FontSize = 12;

%% Formatting
xlabel(ax_handle, 'Distance from arena centre (mm)', 'FontSize', 14);
ylabel(ax_handle, 'Window width (s)', 'FontSize', 14);
title(ax_handle, title_str, 'FontSize', 16);
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
