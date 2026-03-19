function fig = plot_diagnostic_single_fly(x, y, metrics, heading, events, geom, opts)
% PLOT_DIAGNOSTIC_SINGLE_FLY  Multi-panel diagnostic figure for one fly.
%
%   fig = PLOT_DIAGNOSTIC_SINGLE_FLY(x, y, metrics, heading, events, geom, opts)
%
%   Produces a 3x3 diagnostic panel showing trajectory colormaps, metric
%   timeseries, cumulative heading, and turning event bounding boxes. This
%   is the key tool for validating that all computed metrics make sense for
%   a single fly.
%
%   INPUTS:
%     x, y       - [1 x n_frames] position in mm
%     metrics    - struct from compute_sliding_window_metrics (one fly's row):
%                  .abs_av, .abs_curv, .fwd_vel, .tortuosity, .wall_dist
%     heading    - [1 x n_frames] unwrapped heading (degrees)
%     events     - struct from detect_360_turning_events (one fly).
%                  Can be empty struct with .n_events = 0 if no events.
%     geom       - struct from compute_turning_event_geometry (one fly).
%                  Can be empty if no events.
%     opts       - struct with fields:
%       .fly_id      - scalar or string for display (default: 1)
%       .stim_on     - frame index of stimulus onset (default: 300)
%       .stim_off    - frame index of stimulus offset (default: 1200)
%       .arena_radius - arena radius in mm (default: 120)
%       .fps         - frames per second (default: 30)
%       .raw_av      - [1 x n_frames] raw (unsmoothed) |AV| for overlay
%       .raw_fv      - [1 x n_frames] raw forward velocity for overlay
%
%   OUTPUT:
%     fig - figure handle
%
%   LAYOUT (3x3 tiledlayout):
%     (1,1) Trajectory colored by |AV|
%     (1,2) Trajectory colored by tortuosity
%     (1,3) Trajectory colored by forward velocity
%     (2,1) |AV| timeseries (raw thin grey + smoothed black)
%     (2,2) Tortuosity timeseries
%     (2,3) Forward velocity timeseries (raw + smoothed)
%     (3,1) Cumulative heading with event boundaries
%     (3,2) Trajectory with turning event bounding boxes
%     (3,3) Trajectory colored by wall distance
%
% See also: plot_trajectory_colormapped, detect_360_turning_events

%% Parse options
if nargin < 7, opts = struct(); end
fly_id   = get_field(opts, 'fly_id', 1);
stim_on  = get_field(opts, 'stim_on', 300);
stim_off = get_field(opts, 'stim_off', 1200);
arena_r  = get_field(opts, 'arena_radius', 120);
arena_c  = get_field(opts, 'arena_center', [528, 520] / 4.1691);
fps      = get_field(opts, 'fps', 30);
raw_av   = get_field(opts, 'raw_av', []);
raw_fv   = get_field(opts, 'raw_fv', []);

n_frames = numel(x);
t_s = (1:n_frames) / fps;  % time in seconds

fig = figure('Position', [50 50 1600 1200]);
tl = tiledlayout(3, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
sgtitle(tl, sprintf('Diagnostic — Fly %s', string(fly_id)), 'FontSize', 18);

%% Row 1: Trajectory colormaps
% (1,1) |AV|
ax1 = nexttile(tl);
traj_opts.ax = ax1;
traj_opts.arena_radius = arena_r;
traj_opts.arena_center = arena_c;
traj_opts.cbar_label = '|AV| (deg/s)';
traj_opts.title_str = '|Angular velocity|';
traj_opts.marker_size = 6;
plot_trajectory_colormapped(x, y, metrics.abs_av, traj_opts);

% (1,2) Tortuosity
ax2 = nexttile(tl);
traj_opts.ax = ax2;
traj_opts.cbar_label = 'Tortuosity';
traj_opts.title_str = 'Tortuosity';
traj_opts.cmap = 'parula';
traj_opts.clim = [];
traj_opts.clim_pct = [1 75];  % tighter percentile — tortuosity has heavy tail
plot_trajectory_colormapped(x, y, metrics.tortuosity, traj_opts);
traj_opts = rmfield(traj_opts, 'clim_pct');  % reset for subsequent plots

% (1,3) Forward velocity
ax3 = nexttile(tl);
traj_opts.ax = ax3;
traj_opts.cbar_label = 'FV (mm/s)';
traj_opts.title_str = 'Forward velocity';
traj_opts.cmap = 'parula';
traj_opts.clim = [];
plot_trajectory_colormapped(x, y, metrics.fwd_vel, traj_opts);

%% Row 2: Timeseries
% (2,1) |AV| timeseries
ax4 = nexttile(tl);
hold(ax4, 'on');
if ~isempty(raw_av)
    plot(ax4, t_s, raw_av, '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 0.5);
end
plot(ax4, t_s, metrics.abs_av, '-k', 'LineWidth', 1.5);
add_stim_lines(ax4, stim_on, stim_off, fps);
ylabel(ax4, '|AV| (deg/s)', 'FontSize', 14);
title(ax4, '|AV| timeseries', 'FontSize', 16);
format_ts_axes(ax4);

% (2,2) Tortuosity timeseries
ax5 = nexttile(tl);
hold(ax5, 'on');
plot(ax5, t_s, metrics.tortuosity, '-k', 'LineWidth', 1.5);
add_stim_lines(ax5, stim_on, stim_off, fps);
% Clip y-axis at 95th percentile to show structure despite outlier peaks
tort_valid = metrics.tortuosity(~isnan(metrics.tortuosity));
if ~isempty(tort_valid)
    y_upper = prctile(tort_valid, 95);
    ylim(ax5, [0.8, max(y_upper, 2)]);
end
ylabel(ax5, 'Tortuosity', 'FontSize', 14);
title(ax5, 'Tortuosity timeseries', 'FontSize', 16);
format_ts_axes(ax5);

% (2,3) Forward velocity timeseries
ax6 = nexttile(tl);
hold(ax6, 'on');
if ~isempty(raw_fv)
    plot(ax6, t_s, raw_fv, '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 0.5);
end
plot(ax6, t_s, metrics.fwd_vel, '-k', 'LineWidth', 1.5);
add_stim_lines(ax6, stim_on, stim_off, fps);
ylabel(ax6, 'FV (mm/s)', 'FontSize', 14);
title(ax6, 'Forward velocity timeseries', 'FontSize', 16);
format_ts_axes(ax6);

%% Row 3: Heading and bounding boxes
% (3,1) Cumulative heading with event boundaries
ax7 = nexttile(tl);
hold(ax7, 'on');
cum_heading = heading - heading(1);  % relative to starting heading
plot(ax7, t_s, cum_heading, '-k', 'LineWidth', 1);
add_stim_lines(ax7, stim_on, stim_off, fps);

% Overlay event boundaries
if events.n_events > 0
    for e = 1:events.n_events
        sf = events.start_frame(e);
        ef = events.end_frame(e);
        if events.direction(e) > 0
            col = [0.216 0.494 0.722];  % blue for CCW
        else
            col = [0.894 0.102 0.110];  % red for CW
        end
        xline(ax7, sf/fps, '-', 'Color', col, 'LineWidth', 0.8, 'Alpha', 0.6);
        xline(ax7, ef/fps, '-', 'Color', col, 'LineWidth', 0.8, 'Alpha', 0.6);
    end
end
ylabel(ax7, 'Cumulative heading (deg)', 'FontSize', 14);
xlabel(ax7, 'Time (s)', 'FontSize', 14);
title(ax7, sprintf('Cumulative heading (%d events)', events.n_events), 'FontSize', 16);
format_ts_axes(ax7);

% (3,2) Trajectory with bounding boxes
ax8 = nexttile(tl);
hold(ax8, 'on');
theta = linspace(0, 2*pi, 200);
plot(ax8, arena_c(1)+arena_r*cos(theta), arena_c(2)+arena_r*sin(theta), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
plot(ax8, x, y, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);

if events.n_events == 0
    text(ax8, arena_c(1), arena_c(2), {'No turning events', '(run Approach B first)'}, ...
        'HorizontalAlignment', 'center', 'FontSize', 11, 'Color', [0.5 0.5 0.5]);
end

if events.n_events > 0
    cmap_events = lines(min(events.n_events, 12));
    for e = 1:events.n_events
        sf = events.start_frame(e);
        ef = events.end_frame(e);
        sf = max(sf, 1); ef = min(ef, n_frames);
        x_seg = x(sf:ef);
        y_seg = y(sf:ef);
        plot(ax8, x_seg, y_seg, '-', 'Color', cmap_events(mod(e-1,12)+1,:), 'LineWidth', 1.5);

        % Draw bounding box
        if ~isnan(geom.bbox_area(e))
            bx = [min(x_seg), max(x_seg)];
            by = [min(y_seg), max(y_seg)];
            rectangle(ax8, 'Position', [bx(1), by(1), diff(bx), diff(by)], ...
                'EdgeColor', cmap_events(mod(e-1,12)+1,:), 'LineWidth', 1, 'LineStyle', '--');
        end
    end
end
axis(ax8, 'equal');
xlim(ax8, [arena_c(1)-arena_r-5, arena_c(1)+arena_r+5]);
ylim(ax8, [arena_c(2)-arena_r-5, arena_c(2)+arena_r+5]);
title(ax8, 'Trajectory + bounding boxes', 'FontSize', 16);
set(ax8, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% (3,3) Trajectory colored by wall distance
ax9 = nexttile(tl);
traj_opts2.ax = ax9;
traj_opts2.arena_radius = arena_r;
traj_opts2.arena_center = arena_c;
traj_opts2.cbar_label = 'Wall dist (mm)';
traj_opts2.title_str = 'Wall distance';
traj_opts2.cmap = 'cool';
traj_opts2.marker_size = 6;
plot_trajectory_colormapped(x, y, metrics.wall_dist, traj_opts2);

end

%% Local helpers
function add_stim_lines(ax, stim_on, stim_off, fps)
    xline(ax, stim_on/fps,  '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    xline(ax, stim_off/fps, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
end

function format_ts_axes(ax)
    set(ax, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
    xlabel(ax, 'Time (s)', 'FontSize', 14);
end

function val = get_field(s, field, default)
    if isfield(s, field)
        val = s.(field);
    else
        val = default;
    end
end
