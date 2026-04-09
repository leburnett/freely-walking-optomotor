function fig = plot_loop_orientation_trajectory(DATA, strain, fly_idx, view_mode, condition)
% PLOT_LOOP_ORIENTATION_TRAJECTORY  Plot a fly trajectory with loop/segment orientation arrows.
%
%   fig = PLOT_LOOP_ORIENTATION_TRAJECTORY(DATA, strain, fly_idx, view_mode)
%   fig = PLOT_LOOP_ORIENTATION_TRAJECTORY(DATA, strain, fly_idx, view_mode, condition)
%
%   Generates a single-panel trajectory plot showing:
%     "Loops"    — self-intersection loops with PCA orientation arrows
%     "Segments" — inter-loop segments with direction arrows
%
%   Arrow colours: red = outward, blue = inward (relative to radial).
%
%   INPUTS:
%     DATA      - struct from comb_data_across_cohorts_cond
%     strain    - string, e.g. "jfrc100_es_shibire_kir"
%     fly_idx   - scalar, index into QC-passed fly-rep list
%     view_mode - string: "Loops" or "Segments"
%     condition - (optional) scalar, condition number (default: 1)
%
%   OUTPUT:
%     fig - figure handle
%
%   See also: plot_segmented_trajectory, compute_loop_orientation, find_trajectory_loops

if nargin < 5, condition = 1; end

%% Constants
ARENA_CENTER = [528, 520] / 4.1691;
ARENA_R = 120;
FPS = 30;
STIM_ON  = 300;
STIM_OFF = 1200;

ASPECT_THRESHOLD = 1.1;
MIN_SEG_FRAMES = 5;

loop_opts.lookahead_frames = 75;
loop_opts.min_loop_frames  = 5;
loop_opts.fps              = FPS;
loop_opts.arena_center     = ARENA_CENTER;
loop_opts.arena_radius     = ARENA_R;

seg_colors = [
    0.216 0.494 0.722;   0.894 0.102 0.110;   0.302 0.686 0.290;
    0.596 0.306 0.639;   1.000 0.498 0.000;   0.651 0.337 0.157;
    0.122 0.694 0.827;   0.890 0.467 0.761;   0.498 0.498 0.498;
    0.737 0.741 0.133;   0.090 0.745 0.812;   0.682 0.780 0.910;
];
n_colors = size(seg_colors, 1);

%% Load data
data_types = {'heading_data', 'x_data', 'y_data', 'dist_data', 'vel_data'};
[rep_data, n_flies] = load_per_rep_data(DATA, strain, 'F', condition, data_types);

if fly_idx > n_flies
    error('fly_idx (%d) exceeds number of valid flies (%d)', fly_idx, n_flies);
end

sr = STIM_ON:STIM_OFF;
x   = rep_data.x_data(fly_idx, sr);
y   = rep_data.y_data(fly_idx, sr);
h   = rep_data.heading_data(fly_idx, sr);
vel = rep_data.vel_data(fly_idx, sr);

%% Detect loops and compute orientations
loop_opts.vel = vel;
loops = find_trajectory_loops(x, y, h, loop_opts);

% Loop orientations
orient_angle = NaN(1, max(loops.n_loops, 0));
rel_angle    = NaN(1, max(loops.n_loops, 0));
lax_dx       = NaN(1, max(loops.n_loops, 0));
lax_dy       = NaN(1, max(loops.n_loops, 0));
cx           = NaN(1, max(loops.n_loops, 0));
cy           = NaN(1, max(loops.n_loops, 0));

for k = 1:loops.n_loops
    sf = loops.start_frame(k);  ef = loops.end_frame(k);
    [oa, ra, lad, mu] = compute_loop_orientation(x(sf:ef), y(sf:ef), ARENA_CENTER);
    orient_angle(k) = oa;
    rel_angle(k)    = ra;
    lax_dx(k)       = lad(1);
    lax_dy(k)       = lad(2);
    cx(k)           = mu(1);
    cy(k)           = mu(2);
end

% Inter-loop segments
n_segs = max(loops.n_loops - 1, 0);
seg_start = NaN(1, n_segs);
seg_end   = NaN(1, n_segs);
seg_rel   = NaN(1, n_segs);
seg_dx    = NaN(1, n_segs);
seg_dy    = NaN(1, n_segs);
seg_mx    = NaN(1, n_segs);
seg_my    = NaN(1, n_segs);

for k = 1:n_segs
    ss = loops.end_frame(k) + 1;
    se = loops.start_frame(k+1) - 1;
    if se - ss + 1 < MIN_SEG_FRAMES, continue; end

    x_s = x(ss:se);  y_s = y(ss:se);
    valid = ~isnan(x_s) & ~isnan(y_s);
    x_v = x_s(valid);  y_v = y_s(valid);
    if numel(x_v) < MIN_SEG_FRAMES, continue; end

    ddx = x_v(end) - x_v(1);  ddy = y_v(end) - y_v(1);
    seg_len = sqrt(ddx^2 + ddy^2);
    if seg_len < 0.5, continue; end

    dir_ang = atan2d(ddy, ddx);
    dir_unit = [ddx, ddy] / seg_len;
    mmx = (x_v(1) + x_v(end)) / 2;
    mmy = (y_v(1) + y_v(end)) / 2;
    rad_ang = atan2d(mmy - ARENA_CENTER(2), mmx - ARENA_CENTER(1));
    rel = mod(dir_ang - rad_ang + 180, 360) - 180;

    seg_start(k) = ss;
    seg_end(k)   = se;
    seg_rel(k)   = rel;
    seg_dx(k)    = dir_unit(1);
    seg_dy(k)    = dir_unit(2);
    seg_mx(k)    = mmx;
    seg_my(k)    = mmy;
end

%% Plot
fig = figure('Position', [50 50 548 500]);
hold on;

% Arena circle
theta = linspace(0, 2*pi, 200);
plot(ARENA_CENTER(1) + ARENA_R*cos(theta), ...
     ARENA_CENTER(2) + ARENA_R*sin(theta), '-', ...
     'Color', [0.7 0.7 0.7], 'LineWidth', 1);

% Full trajectory
plot(x, y, '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 0.8);

n_arrows = 0;

if strcmpi(view_mode, 'Loops')
    % ---- Draw loops with orientation arrows ----
    for k = 1:loops.n_loops
        sf = loops.start_frame(k);  ef = loops.end_frame(k);
        col = seg_colors(mod(k-1, n_colors) + 1, :);

        plot(x(sf:ef), y(sf:ef), '-', 'Color', col, 'LineWidth', 2.5);
        plot(x(sf), y(sf), 'o', 'MarkerSize', 7, ...
            'MarkerFaceColor', col, 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
        plot(x(ef), y(ef), 's', 'MarkerSize', 7, ...
            'MarkerFaceColor', col, 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);

        % Bounding box
        x_seg = x(sf:ef);  y_seg = y(sf:ef);
        xv = x_seg(~isnan(x_seg));  yv = y_seg(~isnan(y_seg));
        if numel(xv) >= 2
            bx = [min(xv), max(xv)];
            by = [min(yv), max(yv)];
            rectangle('Position', [bx(1), by(1), diff(bx), diff(by)], ...
                'EdgeColor', col, 'LineWidth', 1, 'LineStyle', '--');
        end

        % Orientation arrow
        if loops.bbox_aspect(k) >= ASPECT_THRESHOLD && ~isnan(orient_angle(k))
            t = abs(rel_angle(k)) / 180;
            arrow_col = (1-t) * [0.8 0.15 0.15] + t * [0.15 0.3 0.7];
            quiver(cx(k), cy(k), lax_dx(k)*6, lax_dy(k)*6, 0, ...
                'Color', arrow_col, 'LineWidth', 2.5, 'MaxHeadSize', 1.5);
            n_arrows = n_arrows + 1;
        end
    end
    n_items = loops.n_loops;
    mode_label = 'Loops';

elseif strcmpi(view_mode, 'Segments')
    % ---- Draw inter-loop segments with direction arrows ----
    for k = 1:n_segs
        if isnan(seg_start(k)), continue; end

        ss = seg_start(k);  se = seg_end(k);
        plot(x(ss:se), y(ss:se), '-', 'Color', [0.3 0.75 0.3], 'LineWidth', 2);

        if ~isnan(seg_rel(k))
            t = abs(seg_rel(k)) / 180;
            arrow_col = (1-t) * [0.8 0.15 0.15] + t * [0.15 0.3 0.7];
            quiver(seg_mx(k), seg_my(k), seg_dx(k)*6, seg_dy(k)*6, 0, ...
                'Color', arrow_col, 'LineWidth', 2, 'MaxHeadSize', 1.5);
            n_arrows = n_arrows + 1;
        end
    end
    % n_items = sum(~isnan(seg_start));
    mode_label = 'Segments';
else
    error('view_mode must be "Loops" or "Segments"');
end

% Trajectory start/end markers
fv = find(~isnan(x), 1, 'first');
lv = find(~isnan(x), 1, 'last');
if ~isempty(fv)
    plot(x(fv), y(fv), 'p', 'MarkerSize', 14, ...
        'MarkerFaceColor', [0.2 0.7 0.2], 'MarkerEdgeColor', 'none');
end
if ~isempty(lv)
    plot(x(lv), y(lv), 'p', 'MarkerSize', 14, ...
        'MarkerFaceColor', [0.8 0.2 0.2], 'MarkerEdgeColor', 'none');
end

axis equal;
xlim([ARENA_CENTER(1)-ARENA_R-5, ARENA_CENTER(1)+ARENA_R+5]);
ylim([ARENA_CENTER(2)-ARENA_R-5, ARENA_CENTER(2)+ARENA_R+5]);
xlabel('x (mm)', 'FontSize', 12);
ylabel('y (mm)', 'FontSize', 12);

% Info text box
text(0.02, 0.98, sprintf('%s\nFly = %d\nCondition = %d', ...
    mode_label, fly_idx, condition), ...
    'Units', 'normalized', 'VerticalAlignment', 'top', ...
    'FontSize', 11, 'FontWeight', 'bold');

set(gca, 'FontSize', 11, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

end
