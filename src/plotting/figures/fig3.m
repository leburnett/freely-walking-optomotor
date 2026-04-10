%% Figure 3 — Trajectory segmentation, loop geometry, and orientation bias
%
% Figures generated:
%   1.  |Angular Velocity| vs distance from centre (stim vs baseline)
%   2.  Forward Velocity vs distance from centre (stim vs baseline)
%   3.  View-dist segments: Bbox area vs distance (stim vs acclim)
%   4.  View-dist segments: Aspect ratio vs distance (stim vs acclim)
%   5.  View-dist segments: Tortuosity vs distance (stim vs acclim)
%   6.  View-dist segments: Duration vs distance (stim vs acclim)
%   7.  Trajectory: view-dist peak segmentation (fly 26)
%   8.  Trajectory: self-intersection segmentation (fly 26)
%   9.  Trajectory: loop orientation arrows (fly 26, Loops view)
%   10. Trajectory: segment direction arrows (fly 26, Segments view)
%   11. Polar histogram: loop vs inter-loop segment orientation
%   12. Radial bias (cos) vs distance: loops and segments (shaded SEM)
%   13. Number of self-intersection loops vs distance (stim vs acclim)
%   14. Self-intersection loop bbox area vs distance (stim, control)
%
% Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 27).

%% ================================================================
%  SECTION 1: Setup
%  ================================================================

cfg = get_config();
if ~exist('DATA', 'var')
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

ARENA_CENTER = [528, 520] / 4.1691;
ARENA_R = 120;
FPS = 30;

control_strain = "jfrc100_es_shibire_kir";
sex = 'F';

STIM_ON   = 300;
STIM_OFF  = 1200;
PRE_START = 1250;   % 15s within interval as baseline
PRE_END   = 1700;
MASK_START = 750;
MASK_END   = 850;

ACCLIM_FRAMES = 900;  % 30s at 30fps for acclimation comparison

bin_edges = 0:10:ARENA_R;
bin_centres = bin_edges(1:end-1) + diff(bin_edges) / 2;

% Standard figure size for all single-panel plots
FIG_POS = [76    56   355   285];

%% ================================================================
%  FIGURES 1-2: |AV| and FV vs distance from centre (stim vs baseline)
%  ================================================================

data_ctrl = DATA.(control_strain).(sex);
av_ctrl   = combine_timeseries_across_exp_check(data_ctrl, 1, "av_data");
fv_ctrl   = combine_timeseries_across_exp_check(data_ctrl, 1, "fv_data");
dist_ctrl = combine_timeseries_across_exp_check(data_ctrl, 1, "dist_data");
x_ctrl    = combine_timeseries_across_exp_check(data_ctrl, 1, "x_data");
y_ctrl    = combine_timeseries_across_exp_check(data_ctrl, 1, "y_data");
curv_ctrl = combine_timeseries_across_exp_check(data_ctrl, 1, "curv_data");

opts_sw.short_window = 0.5;
opts_sw.long_window  = 1.6;
metrics_ctrl = compute_sliding_window_metrics(av_ctrl, curv_ctrl, fv_ctrl, ...
    dist_ctrl, x_ctrl, y_ctrl, ARENA_R, FPS, opts_sw);

stim_range = STIM_ON:STIM_OFF;
pre_range  = PRE_START:PRE_END;

% |Angular Velocity|
[av_m_s, av_s_s] = bin_metric_by_wall_distance(metrics_ctrl.abs_av, metrics_ctrl.centre_dist, stim_range, bin_edges);
[av_m_p, av_s_p] = bin_metric_by_wall_distance(metrics_ctrl.abs_av, metrics_ctrl.centre_dist, pre_range, bin_edges);
fig1 = plot_metric_vs_centre_distance(bin_centres, av_m_s, av_s_s, av_m_p, av_s_p, '|Angular Velocity| (deg/s)');
fig1.Position = FIG_POS;

% Forward Velocity
[fv_m_s, fv_s_s] = bin_metric_by_wall_distance(metrics_ctrl.fwd_vel, metrics_ctrl.centre_dist, stim_range, bin_edges);
[fv_m_p, fv_s_p] = bin_metric_by_wall_distance(metrics_ctrl.fwd_vel, metrics_ctrl.centre_dist, pre_range, bin_edges);
fig2 = plot_metric_vs_centre_distance(bin_centres, fv_m_s, fv_s_s, fv_m_p, fv_s_p, 'Forward Velocity (mm/s)');
fig2.Position = FIG_POS;

%% ================================================================
%  FIGURES 3-6: View-dist segment metrics vs distance (stim vs acclim)
%  ================================================================

SMOOTH_WIN     = 10;
MIN_PROMINENCE = 5;
MIN_SEG_FRAMES = 5;
MAX_DIST_CENTER = 110;

% --- Stimulus segments ---
data_types_vd = {'heading_data', 'x_data', 'y_data', 'dist_data', 'vel_data', 'view_dist'};
[rep_data_vd, n_flies_vd] = load_per_rep_data(DATA, control_strain, sex, 1, data_types_vd);

x_stim_vd  = rep_data_vd.x_data(:, stim_range);
y_stim_vd  = rep_data_vd.y_data(:, stim_range);
vd_stim_vd = rep_data_vd.view_dist(:, stim_range);

[flat_stim, n_stim, ~] = segment_viewdist_peaks( ...
    x_stim_vd, y_stim_vd, vd_stim_vd, ARENA_CENTER, FPS, ...
    SMOOTH_WIN, MIN_PROMINENCE, MIN_SEG_FRAMES, MAX_DIST_CENTER);

% --- Acclimation segments ---
x_acc = [];  y_acc = [];  vd_acc = [];
for exp_idx = 1:length(data_ctrl)
    acc = data_ctrl(exp_idx).acclim_off1;
    if isempty(acc) || ~isfield(acc, 'view_dist'), continue; end
    n_f_acc = size(acc.x_data, 1);
    n_fr_acc = size(acc.x_data, 2);
    if n_fr_acc < ACCLIM_FRAMES
        ar = 1:n_fr_acc;
    else
        ar = (n_fr_acc - ACCLIM_FRAMES + 1):n_fr_acc;
    end
    for f = 1:n_f_acc
        if sum(acc.vel_data(f,:) < 0.5) / n_fr_acc > 0.75, continue; end
        if min(acc.dist_data(f,:)) > 110, continue; end
        x_acc  = [x_acc;  acc.x_data(f, ar)];
        y_acc  = [y_acc;  acc.y_data(f, ar)];
        vd_acc = [vd_acc; acc.view_dist(f, ar)];
    end
end

[flat_acc, n_acc, ~] = segment_viewdist_peaks( ...
    x_acc, y_acc, vd_acc, ARENA_CENTER, FPS, ...
    SMOOTH_WIN, MIN_PROMINENCE, MIN_SEG_FRAMES, MAX_DIST_CENTER);

fprintf('View-dist segments: %d stim, %d acclim\n', n_stim, n_acc);

% --- Plot each metric as a separate figure ---
vd_bin_edges = linspace(0, MAX_DIST_CENTER, 11);
vd_bin_centres = (vd_bin_edges(1:end-1) + vd_bin_edges(2:end)) / 2;

metric_data_s = {flat_stim.area, flat_stim.aspect, flat_stim.tort, flat_stim.dur};
metric_data_a = {flat_acc.area,  flat_acc.aspect,  flat_acc.tort,  flat_acc.dur};
metric_labels = {'Bbox area (mm^2)', 'Aspect ratio', ...
                 'Tortuosity (path/displacement)', 'Duration (s)'};

cmaps = cmap_config();
col_stim      = cmaps.stim_baseline.colors(1,:);
col_stim_fill = cmaps.stim_baseline.colors(2,:);
col_acc       = cmaps.stim_baseline.colors(3,:);
col_acc_fill  = cmaps.stim_baseline.colors(4,:);

for mi = 1:4
    figure('Position', FIG_POS);
    hold on;

    % Acclimation first (behind)
    plot_shaded_line(gca, vd_bin_centres, metric_data_a{mi}, flat_acc.dist, ...
        vd_bin_edges, col_acc, col_acc_fill, 'Acclimation');
    % Stimulus on top
    plot_shaded_line(gca, vd_bin_centres, metric_data_s{mi}, flat_stim.dist, ...
        vd_bin_edges, col_stim, col_stim_fill, 'Stimulus');

    xlabel('Distance from centre (mm)', 'FontSize', 14);
    ylabel(metric_labels{mi}, 'FontSize', 14);
    xlim([0 MAX_DIST_CENTER + 5]);
    legend('Location', 'best', 'FontSize', 10);
    set(gca, 'FontSize', 15, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
end

%% ================================================================
%  FIGURES 7-8: Example trajectory segmentation plots (fly 26)
%  ================================================================

fig7 = plot_segmented_trajectory(DATA, control_strain, 26, "viewdist-peaks", 1);
fig7.Position = [50 50 548 711];

fig8 = plot_segmented_trajectory(DATA, control_strain, 26, "self-intersection", 1);
fig8.Position = [50 50 548 711];

%% ================================================================
%  FIGURES 9-10: Loop orientation trajectory — Loops and Segments views
%  ================================================================

fig9 = plot_loop_orientation_trajectory(DATA, control_strain, 26, "Loops", 1);
fig9.Position = [50 50 548 500];

fig10 = plot_loop_orientation_trajectory(DATA, control_strain, 26, "Segments", 1);
fig10.Position = [50 50 548 500];

%% ================================================================
%  FIGURE 11: Polar histogram — loop vs inter-loop segment orientation
%  ================================================================

ASPECT_THRESHOLD = 1.1;
MIN_SEG_FR = 5;

loop_opts_fig3.lookahead_frames = 75;
loop_opts_fig3.min_loop_frames  = 10;
loop_opts_fig3.fps              = FPS;
loop_opts_fig3.arena_center     = ARENA_CENTER;
loop_opts_fig3.arena_radius     = ARENA_R;

loop_rel = [];  loop_dist = [];
seg_rel  = [];  seg_dist  = [];

% Also count loops per distance bin for Figure 11
loop_count_per_fly_stim = {};  % cell array, one vector per fly
loop_dist_per_fly_stim  = {};
loop_area_per_fly_stim  = {};

for exp_idx = 1:length(data_ctrl)
    for rep_idx = 1:2
        rep_str = sprintf('R%d_condition_1', rep_idx);
        if ~isfield(data_ctrl(exp_idx), rep_str), continue; end
        rep_data = data_ctrl(exp_idx).(rep_str);
        if isempty(rep_data), continue; end

        n_flies_rep = size(rep_data.x_data, 1);
        n_frames_avail = size(rep_data.x_data, 2);
        sr_end = min(STIM_OFF, n_frames_avail);
        sr = STIM_ON:sr_end;
        vel_rep  = rep_data.vel_data(:, 1:n_frames_avail);
        dist_rep = rep_data.dist_data(:, 1:n_frames_avail);

        for f = 1:n_flies_rep
            if sum(vel_rep(f,:) < 0.5) / n_frames_avail > 0.75, continue; end
            if min(dist_rep(f,:)) > 110, continue; end

            x_fly = rep_data.x_data(f, sr);
            y_fly = rep_data.y_data(f, sr);
            h_fly = rep_data.heading_data(f, sr);

            x_det = x_fly;  y_det = y_fly;  h_det = h_fly;
            ms = max(MASK_START - STIM_ON + 1, 1);
            me = min(MASK_END - STIM_ON + 1, numel(x_fly));
            x_det(ms:me) = NaN;  y_det(ms:me) = NaN;  h_det(ms:me) = NaN;

            v_fly = vel_rep(f, sr);
            v_fly(ms:me) = NaN;
            loop_opts_fig3.vel = v_fly;

            loops = find_trajectory_loops(x_det, y_det, h_det, loop_opts_fig3);

            % Store per-fly loop distances and areas
            if loops.n_loops > 0
                loop_dist_per_fly_stim{end+1} = loops.bbox_dist_center(:);
                loop_area_per_fly_stim{end+1} = loops.bbox_area(:);
            end

            % Loop orientations
            for k = 1:loops.n_loops
                if loops.bbox_aspect(k) < ASPECT_THRESHOLD, continue; end
                sf = loops.start_frame(k);  ef = loops.end_frame(k);
                [~, ra, ~, ~] = compute_loop_orientation(x_fly(sf:ef), y_fly(sf:ef), ARENA_CENTER);
                if ~isnan(ra)
                    loop_rel  = [loop_rel, ra];
                    loop_dist = [loop_dist, loops.bbox_dist_center(k)];
                end
            end

            % Inter-loop segments
            for k = 1:(loops.n_loops - 1)
                s_start = loops.end_frame(k) + 1;
                s_end   = loops.start_frame(k+1) - 1;
                if s_end - s_start + 1 < MIN_SEG_FR, continue; end
                x_s = x_fly(s_start:s_end);  y_s = y_fly(s_start:s_end);
                valid = ~isnan(x_s) & ~isnan(y_s);
                x_v = x_s(valid);  y_v = y_s(valid);
                if numel(x_v) < MIN_SEG_FR, continue; end
                dx = x_v(end)-x_v(1);  dy = y_v(end)-y_v(1);
                if sqrt(dx^2+dy^2) < 0.5, continue; end
                dir_ang = atan2d(dy, dx);
                mx = (x_v(1)+x_v(end))/2;  my = (y_v(1)+y_v(end))/2;
                dc = sqrt((mx-ARENA_CENTER(1))^2 + (my-ARENA_CENTER(2))^2);
                ra_ang = atan2d(my-ARENA_CENTER(2), mx-ARENA_CENTER(1));
                rel = mod(dir_ang - ra_ang + 180, 360) - 180;
                seg_rel  = [seg_rel, rel];
                seg_dist = [seg_dist, dc];
            end
        end
    end
end

fprintf('Orientations: %d loops, %d segments\n', numel(loop_rel), numel(seg_rel));

% --- Polar histogram ---
col_loop = cmaps.loop_segment.colors(1,:);
col_seg  = cmaps.loop_segment.colors(2,:);

figure('Position', FIG_POS);
h1 = polarhistogram(deg2rad(loop_rel), 36, 'FaceColor', col_loop, 'EdgeColor', 'w', 'FaceAlpha', 0.5);
hold on;
h2 = polarhistogram(deg2rad(seg_rel), 36, 'FaceColor', col_seg, 'EdgeColor', 'w', 'FaceAlpha', 0.5);
pax = gca;
pax.ThetaZeroLocation = 'top';
pax.ThetaDir = 'clockwise';
legend([h1, h2], 'Loops', 'Inter-loop segments', 'Location', 'southoutside', 'FontSize', 11);

%% ================================================================
%  FIGURE 10: Radial bias (cos) vs distance — shaded SEM style
%  ================================================================

loop_cos = cosd(loop_rel);
seg_cos  = cosd(seg_rel);

n_db = 10;
be_d = linspace(0, ARENA_R, n_db + 1);
bc_d = (be_d(1:end-1) + be_d(2:end)) / 2;

figure('Position', FIG_POS);
hold on;

% Loops
plot_shaded_line(gca, bc_d, loop_cos', loop_dist', be_d, ...
    col_loop * 0.6, col_loop, 'Loops');
% Segments
plot_shaded_line(gca, bc_d, seg_cos', seg_dist', be_d, ...
    col_seg, col_seg, 'Inter-loop segments');

yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1, 'HandleVisibility', 'off');
xlabel('Distance from centre (mm)', 'FontSize', 14);
ylabel('cos(rel angle) — radial component', 'FontSize', 14);
ylim([-0.7 0.8]);
legend('Location', 'best', 'FontSize', 11);
set(gca, 'FontSize', 15, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

%% ================================================================
%  FIGURE 11: Number of self-intersection loops vs distance
%             (stimulus vs acclimation)
%  ================================================================
%
%  For each fly, count how many loops fall in each distance bin. Then
%  compute the mean count per bin across flies. This shows where in the
%  arena loops are most frequent.

% --- Stimulus: already collected in loop_dist_per_fly_stim ---
n_flies_stim_loops = numel(loop_dist_per_fly_stim);
count_bins_stim = zeros(n_flies_stim_loops, n_db);
for fi = 1:n_flies_stim_loops
    dists_fi = loop_dist_per_fly_stim{fi};
    for bi = 1:n_db
        count_bins_stim(fi, bi) = sum(dists_fi >= be_d(bi) & dists_fi < be_d(bi+1));
    end
end
mean_count_stim = mean(count_bins_stim, 1);
sem_count_stim  = std(count_bins_stim, 0, 1) / sqrt(n_flies_stim_loops);

% --- Acclimation: detect loops in acclim_off1 ---
loop_dist_per_fly_acc = {};
loop_area_per_fly_acc = {};
loop_opts_acc = loop_opts_fig3;

for exp_idx = 1:length(data_ctrl)
    acc = data_ctrl(exp_idx).acclim_off1;
    if isempty(acc), continue; end
    n_f_a = size(acc.x_data, 1);
    n_fr_a = size(acc.x_data, 2);
    if n_fr_a < ACCLIM_FRAMES
        ar_a = 1:n_fr_a;
    else
        ar_a = (n_fr_a - ACCLIM_FRAMES + 1):n_fr_a;
    end

    for f = 1:n_f_a
        if sum(acc.vel_data(f,:) < 0.5) / n_fr_a > 0.75, continue; end
        if min(acc.dist_data(f,:)) > 110, continue; end

        x_a = acc.x_data(f, ar_a);
        y_a = acc.y_data(f, ar_a);
        h_a = acc.heading_data(f, ar_a);
        v_a = acc.vel_data(f, ar_a);
        loop_opts_acc.vel = v_a;

        loops_a = find_trajectory_loops(x_a, y_a, h_a, loop_opts_acc);
        if loops_a.n_loops > 0
            loop_dist_per_fly_acc{end+1} = loops_a.bbox_dist_center(:);
            loop_area_per_fly_acc{end+1} = loops_a.bbox_area(:);
        end
    end
end

n_flies_acc_loops = numel(loop_dist_per_fly_acc);
count_bins_acc = zeros(n_flies_acc_loops, n_db);
for fi = 1:n_flies_acc_loops
    dists_fi = loop_dist_per_fly_acc{fi};
    for bi = 1:n_db
        count_bins_acc(fi, bi) = sum(dists_fi >= be_d(bi) & dists_fi < be_d(bi+1));
    end
end
mean_count_acc = mean(count_bins_acc, 1);
sem_count_acc  = std(count_bins_acc, 0, 1) / sqrt(n_flies_acc_loops);

fprintf('Loop counts: %d stim flies, %d acclim flies\n', n_flies_stim_loops, n_flies_acc_loops);

% --- Plot ---
figure('Position', FIG_POS);
hold on;

% Acclimation (grey, behind)
valid_a = ~isnan(mean_count_acc);
if any(valid_a)
    patch([bc_d(valid_a) fliplr(bc_d(valid_a))], ...
        [mean_count_acc(valid_a)+sem_count_acc(valid_a) ...
         fliplr(mean_count_acc(valid_a)-sem_count_acc(valid_a))], ...
        col_acc_fill, 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    plot(bc_d(valid_a), mean_count_acc(valid_a), '-o', 'Color', col_acc, ...
        'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', col_acc, ...
        'DisplayName', 'Acclimation');
end

% Stimulus (black, on top)
valid_s = ~isnan(mean_count_stim);
if any(valid_s)
    patch([bc_d(valid_s) fliplr(bc_d(valid_s))], ...
        [mean_count_stim(valid_s)+sem_count_stim(valid_s) ...
         fliplr(mean_count_stim(valid_s)-sem_count_stim(valid_s))], ...
        col_stim_fill, 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    plot(bc_d(valid_s), mean_count_stim(valid_s), '-o', 'Color', col_stim, ...
        'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', col_stim, ...
        'DisplayName', 'Stimulus');
end

xlabel('Distance from centre (mm)', 'FontSize', 14);
ylabel('Loops per fly (mean)', 'FontSize', 14);
legend('Location', 'best', 'FontSize', 11);
set(gca, 'FontSize', 15, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

%% ================================================================
%  FIGURE 14: Bbox area of self-intersection loops vs distance
%  ================================================================
%
%  For each loop detected via self-intersection, bin the bbox area by
%  the loop's distance from the arena centre. Plot mean + SEM shading.

% --- Stimulus ---
all_loop_areas_stim = vertcat(loop_area_per_fly_stim{:});
all_loop_dists_stim = vertcat(loop_dist_per_fly_stim{:});

area_bin_mean_stim = NaN(1, n_db);
area_bin_sem_stim  = NaN(1, n_db);
for bi = 1:n_db
    in_b = all_loop_dists_stim >= be_d(bi) & all_loop_dists_stim < be_d(bi+1) & ~isnan(all_loop_areas_stim);
    if sum(in_b) >= 5
        area_bin_mean_stim(bi) = mean(all_loop_areas_stim(in_b));
        area_bin_sem_stim(bi)  = std(all_loop_areas_stim(in_b)) / sqrt(sum(in_b));
    end
end

% --- Acclimation ---
all_loop_areas_acc = vertcat(loop_area_per_fly_acc{:});
all_loop_dists_acc = vertcat(loop_dist_per_fly_acc{:});

area_bin_mean_acc = NaN(1, n_db);
area_bin_sem_acc  = NaN(1, n_db);
for bi = 1:n_db
    in_b = all_loop_dists_acc >= be_d(bi) & all_loop_dists_acc < be_d(bi+1) & ~isnan(all_loop_areas_acc);
    if sum(in_b) >= 5
        area_bin_mean_acc(bi) = mean(all_loop_areas_acc(in_b));
        area_bin_sem_acc(bi)  = std(all_loop_areas_acc(in_b)) / sqrt(sum(in_b));
    end
end

% --- Plot ---
fig14 = plot_metric_vs_centre_distance(bc_d, ...
    area_bin_mean_stim, area_bin_sem_stim, ...
    area_bin_mean_acc, area_bin_sem_acc, ...
    'Bbox area (mm^2)');
fig14.Position = FIG_POS;

fprintf('\n=== fig3.m complete: 14 figures generated ===\n');

%% ================================================================
%  LOCAL FUNCTIONS
%  ================================================================

function plot_shaded_line(ax, bin_centres, m_vals, d_vals, bin_edges, col_line, col_fill, label)
% Plot a binned mean line with SEM shading on the given axes.
    n_bins = numel(bin_centres);
    bm = NaN(1, n_bins);
    bs = NaN(1, n_bins);
    for bi = 1:n_bins
        in_b = d_vals >= bin_edges(bi) & d_vals < bin_edges(bi+1) & ~isnan(m_vals);
        if sum(in_b) >= 5
            bm(bi) = mean(m_vals(in_b));
            bs(bi) = std(m_vals(in_b)) / sqrt(sum(in_b));
        end
    end
    valid = ~isnan(bm);
    if sum(valid) >= 2
        patch(ax, [bin_centres(valid) fliplr(bin_centres(valid))], ...
            [bm(valid)+bs(valid) fliplr(bm(valid)-bs(valid))], ...
            col_fill, 'FaceAlpha', 0.15, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    end
    plot(ax, bin_centres(valid), bm(valid), '-o', 'Color', col_line, ...
        'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', col_line, ...
        'DisplayName', label);
end

function [flat, n_segs, n_excluded] = segment_viewdist_peaks( ...
        x_all, y_all, vd_all, arena_center, fps, ...
        smooth_win, min_prom, min_seg_frames, max_dist)
% Extract peak-to-peak segments from view_dist signal.
    flat.fly_id = [];  flat.area = [];  flat.aspect = [];
    flat.tort = [];    flat.dist = [];  flat.dur = [];
    n_segs = 0;  n_excluded = 0;

    for f = 1:size(x_all, 1)
        vd = vd_all(f,:);  xf = x_all(f,:);  yf = y_all(f,:);
        vdc = vd; vdc(isnan(vdc)) = 0;
        vds = movmean(vdc, smooth_win, 'omitnan');
        vds(isnan(vd)) = NaN;
        [~, pl] = findpeaks(vds, 'MinPeakProminence', min_prom, 'MinPeakDistance', 5);
        if numel(pl) < 2, continue; end

        for k = 1:(numel(pl)-1)
            sf = pl(k); ef = pl(k+1);
            if ef-sf+1 < min_seg_frames, continue; end
            xs = xf(sf:ef); ys = yf(sf:ef);
            v = ~isnan(xs) & ~isnan(ys);
            xv = xs(v); yv = ys(v);
            if numel(xv) < min_seg_frames, continue; end

            w = max(xv)-min(xv); h = max(yv)-min(yv);
            mx = (min(xv)+max(xv))/2; my = (min(yv)+max(yv))/2;
            dc = sqrt((mx-arena_center(1))^2 + (my-arena_center(2))^2);
            if dc > max_dist, n_excluded = n_excluded+1; continue; end

            dxs = diff(xv); dys = diff(yv);
            pl_len = sum(sqrt(dxs.^2+dys.^2));
            disp_len = sqrt((xv(end)-xv(1))^2+(yv(end)-yv(1))^2);
            if disp_len > 0.5, tort = pl_len/disp_len; else, tort = NaN; end

            flat.fly_id = [flat.fly_id; f];
            flat.area   = [flat.area; w*h];
            flat.aspect = [flat.aspect; max(w,h)/max(min(w,h),0.01)];
            flat.tort   = [flat.tort; tort];
            flat.dist   = [flat.dist; dc];
            flat.dur    = [flat.dur; (ef-sf)/fps];
            n_segs = n_segs+1;
        end
    end
end
