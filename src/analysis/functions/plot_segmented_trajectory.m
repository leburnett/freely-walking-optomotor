function fig = plot_segmented_trajectory(DATA, strain, fly_idx, method, condition)
% PLOT_SEGMENTED_TRAJECTORY  Two-panel plot of a segmented fly trajectory.
%
%   fig = PLOT_SEGMENTED_TRAJECTORY(DATA, strain, fly_idx, method)
%   fig = PLOT_SEGMENTED_TRAJECTORY(DATA, strain, fly_idx, method, condition)
%
%   Top panel:  Trajectory in the arena, colour-coded by detected segments.
%   Bottom panel: View distance timeseries with coloured shading behind
%                 each segment and black arrows marking the peaks used for
%                 segmentation (view-dist peaks method only).
%
%   INPUTS:
%     DATA      - struct from comb_data_across_cohorts_cond (protocol 27)
%     strain    - string, e.g. "jfrc100_es_shibire_kir"
%     fly_idx   - scalar, index into the QC-passed fly-rep list (same
%                 ordering as load_per_rep_data output)
%     method    - string: "self-intersection" or "viewdist-peaks"
%     condition - (optional) scalar, condition number (default: 1)
%
%   OUTPUT:
%     fig - figure handle
%
%   Segmentation parameters (fixed):
%     View-dist peaks: 10-frame smoothing, 5 mm min prominence
%     Self-intersection: 75-frame lookahead, 5-frame min loop
%
%   EXAMPLE:
%     fig = plot_segmented_trajectory(DATA, "jfrc100_es_shibire_kir", 42, "viewdist-peaks");
%     fig = plot_segmented_trajectory(DATA, "jfrc100_es_shibire_kir", 42, "self-intersection");
%
%   See also: find_trajectory_loops, load_per_rep_data, findpeaks

if nargin < 5, condition = 1; end

%% Constants
ARENA_CENTER = [528, 520] / 4.1691;
ARENA_R = 120;
FPS = 30;
STIM_ON  = 300;
STIM_OFF = 1200;

% View-dist peak parameters
SMOOTH_WIN     = 10;
MIN_PROMINENCE = 5;

% Self-intersection parameters
loop_opts.lookahead_frames = 75;
loop_opts.min_loop_frames  = 5;
loop_opts.fps              = FPS;
loop_opts.arena_center     = ARENA_CENTER;
loop_opts.arena_radius     = ARENA_R;

% Colour palette
seg_colors = [
    0.216 0.494 0.722;   0.894 0.102 0.110;   0.302 0.686 0.290;
    0.596 0.306 0.639;   1.000 0.498 0.000;   0.651 0.337 0.157;
    0.122 0.694 0.827;   0.890 0.467 0.761;   0.498 0.498 0.498;
    0.737 0.741 0.133;   0.090 0.745 0.812;   0.682 0.780 0.910;
];
n_colors = size(seg_colors, 1);

%% Load data for this fly
data_types = {'heading_data', 'x_data', 'y_data', 'dist_data', 'vel_data', 'view_dist'};
[rep_data, n_flies] = load_per_rep_data(DATA, strain, 'F', condition, data_types);

if fly_idx > n_flies
    error('fly_idx (%d) exceeds number of valid flies (%d) for %s condition %d', ...
        fly_idx, n_flies, strain, condition);
end

stim_range = STIM_ON:STIM_OFF;
x     = rep_data.x_data(fly_idx, stim_range);
y     = rep_data.y_data(fly_idx, stim_range);
h     = rep_data.heading_data(fly_idx, stim_range);
vd    = rep_data.view_dist(fly_idx, stim_range);
vel   = rep_data.vel_data(fly_idx, stim_range);

n_frames = numel(x);
t_s = (0:n_frames-1) / FPS;

%% Segment the trajectory
method = lower(method);

if strcmp(method, 'self-intersection')
    % Self-intersection loop detection
    loops = find_trajectory_loops(x, y, h, loop_opts);
    seg_starts = loops.start_frame;
    seg_ends   = loops.end_frame;
    n_segs     = loops.n_loops;
    pk_locs    = [];  % no peaks to show
    vd_smooth  = [];

elseif strcmp(method, 'viewdist-peaks')
    % View-dist peak segmentation
    vd_clean = vd;
    vd_clean(isnan(vd_clean)) = 0;
    vd_smooth = movmean(vd_clean, SMOOTH_WIN, 'omitnan');
    vd_smooth(isnan(vd)) = NaN;

    [pk_vals, pk_locs] = findpeaks(vd_smooth, ...
        'MinPeakProminence', MIN_PROMINENCE, 'MinPeakDistance', 5);

    n_segs = max(numel(pk_locs) - 1, 0);
    seg_starts = pk_locs(1:end-1);
    seg_ends   = pk_locs(2:end);
else
    error('Unknown method "%s". Use "self-intersection" or "viewdist-peaks".', method);
end

%% Create figure — use manual axes positioning for consistent width
fig = figure('Position', [50 50 800 750]);

% Both panels share the same left edge and width
left = 0.10;  w = 0.82;

% Top panel: trajectory (takes ~65% of figure height)
ax_traj = axes(fig, 'Position', [left 0.32 w 0.62]);
hold(ax_traj, 'on');
axis(ax_traj, 'equal');

% Arena circle
theta = linspace(0, 2*pi, 200);
plot(ax_traj, ARENA_CENTER(1) + ARENA_R*cos(theta), ...
     ARENA_CENTER(2) + ARENA_R*sin(theta), '-', ...
     'Color', [0.7 0.7 0.7], 'LineWidth', 1);

% Full trajectory in light grey
plot(ax_traj, x, y, '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 0.8);

% Colour-coded segments
for k = 1:n_segs
    sf = seg_starts(k);
    ef = seg_ends(k);
    col = seg_colors(mod(k-1, n_colors) + 1, :);

    plot(ax_traj, x(sf:ef), y(sf:ef), '-', 'Color', col, 'LineWidth', 2.5);
    plot(ax_traj, x(sf), y(sf), 'o', 'MarkerSize', 7, ...
        'MarkerFaceColor', col, 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
    plot(ax_traj, x(ef), y(ef), 's', 'MarkerSize', 7, ...
        'MarkerFaceColor', col, 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);

    % Bounding box (self-intersection only)
    if strcmp(method, 'self-intersection')
        x_seg = x(sf:ef);  y_seg = y(sf:ef);
        xv = x_seg(~isnan(x_seg));  yv = y_seg(~isnan(y_seg));
        if numel(xv) >= 2
            bx = [min(xv), max(xv)];
            by = [min(yv), max(yv)];
            rectangle(ax_traj, 'Position', [bx(1), by(1), diff(bx), diff(by)], ...
                'EdgeColor', col, 'LineWidth', 1, 'LineStyle', '--');
        end
    end

    mid_frame = round((sf + ef) / 2);
    text(ax_traj, x(mid_frame)+1, y(mid_frame)+1, sprintf('#%d', k), ...
        'FontSize', 7, 'Color', col, 'FontWeight', 'bold');
end

% Trajectory start/end markers
fv = find(~isnan(x), 1, 'first');
lv = find(~isnan(x), 1, 'last');
if ~isempty(fv)
    plot(ax_traj, x(fv), y(fv), 'p', 'MarkerSize', 14, ...
        'MarkerFaceColor', [0.2 0.7 0.2], 'MarkerEdgeColor', 'none');
end
if ~isempty(lv)
    plot(ax_traj, x(lv), y(lv), 'p', 'MarkerSize', 14, ...
        'MarkerFaceColor', [0.8 0.2 0.2], 'MarkerEdgeColor', 'none');
end

xlim(ax_traj, [ARENA_CENTER(1)-ARENA_R-5, ARENA_CENTER(1)+ARENA_R+5]);
ylim(ax_traj, [ARENA_CENTER(2)-ARENA_R-5, ARENA_CENTER(2)+ARENA_R+5]);
xlabel(ax_traj, 'x (mm)', 'FontSize', 12);
ylabel(ax_traj, 'y (mm)', 'FontSize', 12);

% Info text box in top-left corner
text(ax_traj, 0.02, 0.98, ...
    sprintf('Fly = %d\nCondition = %d', fly_idx, condition), ...
    'Units', 'normalized', 'VerticalAlignment', 'top', ...
    'FontSize', 11, 'FontWeight', 'bold');
set(ax_traj, 'FontSize', 11, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% --- Bottom panel: view distance timeseries (same width as trajectory) ---
ax_vd = axes(fig, 'Position', [left 0.06 w 0.20]);
hold(ax_vd, 'on');

% Raw view_dist
plot(ax_vd, t_s, vd, '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.8);

% Smoothed view_dist (viewdist-peaks only)
if strcmp(method, 'viewdist-peaks') && ~isempty(vd_smooth)
    plot(ax_vd, t_s, vd_smooth, '-k', 'LineWidth', 1.2);
end

% Shaded rectangles for each segment
yl = [0 max(vd(~isnan(vd))) * 1.1];
for k = 1:n_segs
    sf = seg_starts(k);
    ef = seg_ends(k);
    col = seg_colors(mod(k-1, n_colors) + 1, :);

    fill(ax_vd, [t_s(sf) t_s(ef) t_s(ef) t_s(sf)], ...
        [yl(1) yl(1) yl(2) yl(2)], col, ...
        'FaceAlpha', 0.2, 'EdgeColor', 'none');
end

% Peak markers (viewdist-peaks only)
if strcmp(method, 'viewdist-peaks') && ~isempty(pk_locs)
    plot(ax_vd, t_s(pk_locs), vd_smooth(pk_locs), 'v', 'MarkerSize', 8, ...
        'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'none');
end

xlim(ax_vd, [0 t_s(end)]);
ylim(ax_vd, yl);
xlabel(ax_vd, 'Time (s)', 'FontSize', 12);
ylabel(ax_vd, 'View distance (mm)', 'FontSize', 12);

if strcmp(method, 'viewdist-peaks')
    % title(ax_vd, sprintf('View distance (smooth=%d fr, prom=%d mm, %d peaks)', ...
        % SMOOTH_WIN, MIN_PROMINENCE, numel(pk_locs)), 'FontSize', 11);
else
    % title(ax_vd, sprintf('View distance with %d loop boundaries', n_segs), 'FontSize', 11);
end
set(ax_vd, 'FontSize', 11, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

end
