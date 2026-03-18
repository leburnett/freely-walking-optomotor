function fig = plot_tortuosity_multiwindow(x_data, y_data, fps, opts)
% PLOT_TORTUOSITY_MULTIWINDOW  Tortuosity timeseries at multiple window widths.
%
%   fig = PLOT_TORTUOSITY_MULTIWINDOW(x_data, y_data, fps, opts)
%
%   Computes and plots tortuosity timeseries for a single fly using several
%   different window widths, overlaid on the same axes. Useful for
%   understanding how window choice affects the tortuosity signal.
%
%   INPUTS:
%     x_data  - [1 x n_frames] x position (mm), single fly
%     y_data  - [1 x n_frames] y position (mm), single fly
%     fps     - scalar, frames per second
%     opts    - struct with optional fields:
%       .windows    - vector of window widths in seconds (default: [0.5, 1, 2, 3])
%       .stim_on    - stimulus onset frame (default: 300)
%       .stim_off   - stimulus offset frame (default: 1200)
%       .title_str  - title (default: 'Tortuosity — Multiple Windows')
%       .ylim_pct   - percentile for y-axis upper limit (default: 95)
%       .ax         - existing axes handle
%
%   OUTPUT:
%     fig - figure handle (empty if opts.ax was provided)
%
% See also: compute_tortuosity

%% Parse options
if nargin < 4, opts = struct(); end
windows   = get_field(opts, 'windows', [0.5, 1, 2, 3]);
stim_on   = get_field(opts, 'stim_on', 300);
stim_off  = get_field(opts, 'stim_off', 1200);
title_str = get_field(opts, 'title_str', 'Tortuosity — Multiple Windows');
ylim_pct  = get_field(opts, 'ylim_pct', 95);
ax_handle = get_field(opts, 'ax', []);

n_frames = numel(x_data);
t_s = (1:n_frames) / fps;

%% Set up axes
if isempty(ax_handle)
    fig = figure('Position', [100 100 800 400]);
    ax_handle = gca;
else
    fig = [];
    axes(ax_handle);
end
hold(ax_handle, 'on');

%% Compute and plot for each window
n_win = numel(windows);
% Blue gradient from light to dark
colors = interp1([1; n_win], [0.75 0.85 0.95; 0.10 0.25 0.54], 1:n_win);

all_vals = [];
legend_entries = cell(1, n_win);

for w = 1:n_win
    win_frames = round(windows(w) * fps);
    tort = compute_tortuosity(x_data, y_data, win_frames, fps);

    plot(ax_handle, t_s, tort, '-', 'Color', colors(w,:), 'LineWidth', 1.2);
    legend_entries{w} = sprintf('%.1fs (%d frames)', windows(w), win_frames);

    all_vals = [all_vals, tort(~isnan(tort))]; %#ok<AGROW>
end

%% Stimulus markers
xline(ax_handle, stim_on/fps,  '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'HandleVisibility', 'off');
xline(ax_handle, stim_off/fps, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'HandleVisibility', 'off');

%% Formatting
% Set y-axis to clip outliers
if ~isempty(all_vals)
    y_upper = prctile(all_vals, ylim_pct);
    ylim(ax_handle, [0.8, max(y_upper, 2)]);
end

xlabel(ax_handle, 'Time (s)', 'FontSize', 14);
ylabel(ax_handle, 'Tortuosity', 'FontSize', 14);
title(ax_handle, title_str, 'FontSize', 16);
legend(ax_handle, legend_entries, 'Location', 'best');
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
