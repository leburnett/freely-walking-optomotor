function fig = plot_metric_vs_centre_distance(bin_centres, stim_means, stim_sems, pre_means, pre_sems, metric_name, opts)
% PLOT_METRIC_VS_CENTRE_DISTANCE  Single-panel metric vs distance from centre.
%
%   fig = PLOT_METRIC_VS_CENTRE_DISTANCE(bin_centres, stim_means, stim_sems,
%       pre_means, pre_sems, metric_name, opts)
%
%   Plots stimulus and baseline as mean lines with SEM shading and small
%   markers at each bin centre, with distance from arena centre on the x-axis.
%
%   INPUTS:
%     bin_centres  - [1 x n_bins] distance-from-centre bin centres (mm)
%     stim_means   - [1 x n_bins] stimulus period mean
%     stim_sems    - [1 x n_bins] stimulus period SEM
%     pre_means    - [1 x n_bins] baseline period mean
%     pre_sems     - [1 x n_bins] baseline period SEM
%     metric_name  - string for y-axis label and title
%                    (e.g. '|Angular Velocity| (deg/s)')
%     opts         - (optional) struct with fields:
%       .stim_color  - [1x3] RGB for stimulus (default: black)
%       .pre_color   - [1x3] RGB for baseline (default: light grey)
%       .alpha       - SEM shading alpha (default: 0.15)
%       .show_legend - logical (default: true)
%
%   OUTPUT:
%     fig - figure handle
%
% See also: plot_metric_vs_wall_distance, bin_metric_by_wall_distance

if nargin < 7, opts = struct(); end

stim_col  = get_opt(opts, 'stim_color', [0 0 0]);
pre_col   = get_opt(opts, 'pre_color', [0.7 0.7 0.7]);
alpha_val = get_opt(opts, 'alpha', 0.15);
show_leg  = get_opt(opts, 'show_legend', true);

fig = figure('Position', [100 100 500 400]);
hold on

% --- Baseline ---
draw_line(gca, bin_centres, pre_means, pre_sems, pre_col, alpha_val, 'Baseline');

% --- Stimulus ---
draw_line(gca, bin_centres, stim_means, stim_sems, stim_col, alpha_val, 'Stimulus');

xlabel('Distance from arena centre (mm)', 'FontSize', 14);
ylabel(metric_name, 'FontSize', 14);
title(metric_name, 'FontSize', 16);

if show_leg
    legend('Location', 'best');
end

set(gca, 'FontSize', 15, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

end

%% Helpers
function draw_line(ax, bc, m, s, col, alpha_val, label)
    valid = ~isnan(m) & ~isnan(s);
    bc_v = bc(valid);
    m_v  = m(valid);
    s_v  = s(valid);

    if numel(bc_v) >= 2
        patch(ax, [bc_v fliplr(bc_v)], [m_v+s_v fliplr(m_v-s_v)], ...
            col, 'FaceAlpha', alpha_val, 'EdgeColor', 'none', ...
            'HandleVisibility', 'off');
    end

    plot(ax, bc_v, m_v, '-o', 'Color', col, ...
        'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', col, ...
        'DisplayName', label);
end

function val = get_opt(s, field, default)
    if isfield(s, field), val = s.(field); else, val = default; end
end
