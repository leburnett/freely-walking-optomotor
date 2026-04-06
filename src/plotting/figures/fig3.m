%% Figure 3 — Loop geometry, orientation bias, and centring
%
% Sections 1-3: Metric vs distance from centre / viewing distance (existing)
% Section 4: Polar histogram of loop vs segment orientation
% Section 5: Radial bias errorbar (cos(rel angle) vs distance)
% Section 6: Per-fly centring score vs mean loop outward bias (cond 1)
% Section 7: LMM plots — aspect ratio, bbox area, cos(rel angle) vs distance
%
% See also: LOOP_VS_SEGMENT_ORIENTATION_OVERLAY, LOOP_ORIENTATION_CENTRING,
%           control_loop_lmm

%% ================================================================
%  SECTION 1: Setup
%  ================================================================

cfg = get_config();
ROOT_DIR = cfg.project_root;

if ~exist('DATA', 'var')
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

%% Fixed parameters. 
protocol = "protocol_27";
data_types =  {'fv_data', 'av_data', 'curv_data', 'dist_data', 'dist_data_delta'};

params.save_figs = 0;
params.plot_sem = 1;
params.plot_sd = 0;
params.plot_individ = 0;
params.shaded_areas = 0;

%% These plots compare control flies' behaviour to moving and static gratings
cond_ids = [10, 1]; % 60 deg gratings (condition 1) and 60 deg flicker (condition 10).

%% ================================================================
%  SECTION 2: Timeseries - metrics versus distance from the centre.
%  ================================================================

ARENA_R = 120;
FPS = 30;

control_strain = "jfrc100_es_shibire_kir";
key_condition = 1;
sex = 'F';

STIM_ON  = 300;
STIM_OFF = 1200;
PRE_START = 1250; % use 15s within interval as baseline.
PRE_END   = 1700;

bin_edges = 0:10:ARENA_R;
bin_centres = bin_edges(1:end-1) + diff(bin_edges) / 2;

%% Load control data
data_ctrl = DATA.(control_strain).(sex);
av_ctrl   = combine_timeseries_across_exp_check(data_ctrl, key_condition, "av_data");
curv_ctrl = combine_timeseries_across_exp_check(data_ctrl, key_condition, "curv_data");
fv_ctrl   = combine_timeseries_across_exp_check(data_ctrl, key_condition, "fv_data");
dist_ctrl = combine_timeseries_across_exp_check(data_ctrl, key_condition, "dist_data");
x_ctrl    = combine_timeseries_across_exp_check(data_ctrl, key_condition, "x_data");
y_ctrl    = combine_timeseries_across_exp_check(data_ctrl, key_condition, "y_data");

%% Compute sliding-window metrics
opts_sw.short_window = 0.5;
opts_sw.long_window  = 1.6;
metrics_ctrl = compute_sliding_window_metrics(av_ctrl, curv_ctrl, fv_ctrl, ...
    dist_ctrl, x_ctrl, y_ctrl, ARENA_R, FPS, opts_sw);

stim_range = STIM_ON:STIM_OFF;
pre_range  = PRE_START:PRE_END;

%% Bin by distance from centre
[av_means_stim,   av_sems_stim]   = bin_metric_by_wall_distance(metrics_ctrl.abs_av,     metrics_ctrl.centre_dist, stim_range, bin_edges);
[curv_means_stim, curv_sems_stim] = bin_metric_by_wall_distance(metrics_ctrl.abs_curv,   metrics_ctrl.centre_dist, stim_range, bin_edges);
[fv_means_stim,   fv_sems_stim]   = bin_metric_by_wall_distance(metrics_ctrl.fwd_vel,    metrics_ctrl.centre_dist, stim_range, bin_edges);
[tort_means_stim, tort_sems_stim] = bin_metric_by_wall_distance(metrics_ctrl.tortuosity, metrics_ctrl.centre_dist, stim_range, bin_edges);

[av_means_pre,   av_sems_pre]   = bin_metric_by_wall_distance(metrics_ctrl.abs_av,     metrics_ctrl.centre_dist, pre_range, bin_edges);
[curv_means_pre, curv_sems_pre] = bin_metric_by_wall_distance(metrics_ctrl.abs_curv,   metrics_ctrl.centre_dist, pre_range, bin_edges);
[fv_means_pre,   fv_sems_pre]   = bin_metric_by_wall_distance(metrics_ctrl.fwd_vel,    metrics_ctrl.centre_dist, pre_range, bin_edges);
[tort_means_pre, tort_sems_pre] = bin_metric_by_wall_distance(metrics_ctrl.tortuosity, metrics_ctrl.centre_dist, pre_range, bin_edges);

%% Plot each metric as a separate figure
metric_names = {'|Angular Velocity| (deg/s)', '|Curvature| (deg/mm)', ...
                'Forward Velocity (mm/s)', 'Tortuosity'};
stim_means = {av_means_stim, curv_means_stim, fv_means_stim, tort_means_stim};
stim_sems  = {av_sems_stim,  curv_sems_stim,  fv_sems_stim,  tort_sems_stim};
pre_means  = {av_means_pre,  curv_means_pre,  fv_means_pre,  tort_means_pre};
pre_sems   = {av_sems_pre,   curv_sems_pre,   fv_sems_pre,   tort_sems_pre};

for p = 1:4
    plot_metric_vs_centre_distance(bin_centres, ...
        stim_means{p}, stim_sems{p}, pre_means{p}, pre_sems{p}, metric_names{p});
end




%% ================================================================
%  SECTION 3: Timeseries - versus viewing distance?? 
%  ================================================================

%% Load control data
data_ctrl = DATA.(control_strain).(sex);
av_ctrl   = combine_timeseries_across_exp_check(data_ctrl, key_condition, "av_data");
curv_ctrl = combine_timeseries_across_exp_check(data_ctrl, key_condition, "curv_data");
fv_ctrl   = combine_timeseries_across_exp_check(data_ctrl, key_condition, "fv_data");
dist_ctrl = combine_timeseries_across_exp_check(data_ctrl, key_condition, "dist_data");
vd_ctrl   = combine_timeseries_across_exp_check(data_ctrl, key_condition, "view_dist");
x_ctrl    = combine_timeseries_across_exp_check(data_ctrl, key_condition, "x_data");
y_ctrl    = combine_timeseries_across_exp_check(data_ctrl, key_condition, "y_data");

%% Compute sliding-window metrics
opts_sw.short_window = 0.5;
opts_sw.long_window  = 1.6;
metrics_ctrl = compute_sliding_window_metrics(av_ctrl, curv_ctrl, fv_ctrl, ...
    dist_ctrl, x_ctrl, y_ctrl, ARENA_R, FPS, opts_sw);

stim_range = STIM_ON:STIM_OFF;
pre_range  = PRE_START:PRE_END;

%% Bin by viewing distance
% view_dist ranges from ~0 to ~240 mm (diameter); use 10 mm bins
vd_bin_edges = 0:10:240;
vd_bin_centres = vd_bin_edges(1:end-1) + diff(vd_bin_edges) / 2;

[av_means_stim,   av_sems_stim]   = bin_metric_by_wall_distance(metrics_ctrl.abs_av,     vd_ctrl, stim_range, vd_bin_edges);
[curv_means_stim, curv_sems_stim] = bin_metric_by_wall_distance(metrics_ctrl.abs_curv,   vd_ctrl, stim_range, vd_bin_edges);
[fv_means_stim,   fv_sems_stim]   = bin_metric_by_wall_distance(metrics_ctrl.fwd_vel,    vd_ctrl, stim_range, vd_bin_edges);
[tort_means_stim, tort_sems_stim] = bin_metric_by_wall_distance(metrics_ctrl.tortuosity, vd_ctrl, stim_range, vd_bin_edges);

[av_means_pre,   av_sems_pre]   = bin_metric_by_wall_distance(metrics_ctrl.abs_av,     vd_ctrl, pre_range, vd_bin_edges);
[curv_means_pre, curv_sems_pre] = bin_metric_by_wall_distance(metrics_ctrl.abs_curv,   vd_ctrl, pre_range, vd_bin_edges);
[fv_means_pre,   fv_sems_pre]   = bin_metric_by_wall_distance(metrics_ctrl.fwd_vel,    vd_ctrl, pre_range, vd_bin_edges);
[tort_means_pre, tort_sems_pre] = bin_metric_by_wall_distance(metrics_ctrl.tortuosity, vd_ctrl, pre_range, vd_bin_edges);

%% Plot each metric as a separate figure
metric_names = {'|Angular Velocity| (deg/s)', '|Curvature| (deg/mm)', ...
                'Forward Velocity (mm/s)', 'Tortuosity'};
stim_means = {av_means_stim, curv_means_stim, fv_means_stim, tort_means_stim};
stim_sems  = {av_sems_stim,  curv_sems_stim,  fv_sems_stim,  tort_sems_stim};
pre_means  = {av_means_pre,  curv_means_pre,  fv_means_pre,  tort_means_pre};
pre_sems   = {av_sems_pre,   curv_sems_pre,   fv_sems_pre,   tort_sems_pre};

for p = 1:4
    plot_metric_vs_viewing_distance(vd_bin_centres, ...
        stim_means{p}, stim_sems{p}, pre_means{p}, pre_sems{p}, metric_names{p});
end

%% ================================================================
%  SECTION 4: Polar histogram — loop vs inter-loop segment orientation
%  (from LOOP_VS_SEGMENT_ORIENTATION_OVERLAY)
%  ================================================================

ARENA_CENTER = [528, 520] / 4.1691;
ASPECT_THRESHOLD = 1.1;
MIN_SEG_FRAMES = 5;
MASK_START = 750;  MASK_END = 850;

loop_opts_fig3.lookahead_frames = 75;
loop_opts_fig3.min_loop_frames  = 10;
loop_opts_fig3.fps              = FPS;
loop_opts_fig3.arena_center     = ARENA_CENTER;
loop_opts_fig3.arena_radius     = ARENA_R;

loop_rel   = [];   loop_dist  = [];
seg_rel    = [];   seg_dist   = [];

data_strain = DATA.(control_strain).(sex);
n_exp = length(data_strain);

for exp_idx = 1:n_exp
    for rep_idx = 1:2
        rep_str = sprintf('R%d_condition_1', rep_idx);
        if ~isfield(data_strain(exp_idx), rep_str); continue; end
        rep_data = data_strain(exp_idx).(rep_str);
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
            mask_s = max(MASK_START - STIM_ON + 1, 1);
            mask_e = min(MASK_END - STIM_ON + 1, numel(x_fly));
            x_det(mask_s:mask_e) = NaN;
            y_det(mask_s:mask_e) = NaN;
            h_det(mask_s:mask_e) = NaN;

            v_fly = vel_rep(f, sr);
            v_fly(mask_s:mask_e) = NaN;
            loop_opts_fig3.vel = v_fly;

            loops = find_trajectory_loops(x_det, y_det, h_det, loop_opts_fig3);

            for k = 1:loops.n_loops
                if loops.bbox_aspect(k) < ASPECT_THRESHOLD, continue; end
                sf = loops.start_frame(k);  ef = loops.end_frame(k);
                [~, ra, ~, ~] = compute_loop_orientation(x_fly(sf:ef), y_fly(sf:ef), ARENA_CENTER);
                if ~isnan(ra)
                    loop_rel  = [loop_rel, ra]; %#ok<AGROW>
                    loop_dist = [loop_dist, loops.bbox_dist_center(k)]; %#ok<AGROW>
                end
            end

            for k = 1:(loops.n_loops - 1)
                s_start = loops.end_frame(k) + 1;
                s_end   = loops.start_frame(k+1) - 1;
                if s_end - s_start + 1 < MIN_SEG_FRAMES, continue; end
                x_s = x_fly(s_start:s_end);  y_s = y_fly(s_start:s_end);
                valid = ~isnan(x_s) & ~isnan(y_s);
                x_v = x_s(valid);  y_v = y_s(valid);
                if numel(x_v) < MIN_SEG_FRAMES, continue; end
                dx = x_v(end) - x_v(1);  dy = y_v(end) - y_v(1);
                if sqrt(dx^2 + dy^2) < 0.5, continue; end
                dir_ang = atan2d(dy, dx);
                mx = (x_v(1) + x_v(end)) / 2;  my = (y_v(1) + y_v(end)) / 2;
                d_center = sqrt((mx - ARENA_CENTER(1))^2 + (my - ARENA_CENTER(2))^2);
                radial_ang = atan2d(my - ARENA_CENTER(2), mx - ARENA_CENTER(1));
                rel = mod(dir_ang - radial_ang + 180, 360) - 180;
                seg_rel  = [seg_rel, rel]; %#ok<AGROW>
                seg_dist = [seg_dist, d_center]; %#ok<AGROW>
            end
        end
    end
end

fprintf('Loop orientations: %d, inter-loop segments: %d\n', numel(loop_rel), numel(seg_rel));

% --- Polar histogram ---
col_loop = [0.6 0.6 0.6];
col_seg  = [0.133 0.545 0.133];

figure('Position', [50 50 650 650], 'Name', 'Polar: Loop vs Segment Orientation');
h1 = polarhistogram(deg2rad(loop_rel), 36, 'FaceColor', col_loop, 'EdgeColor', 'w', 'FaceAlpha', 0.5);
hold on;
h2 = polarhistogram(deg2rad(seg_rel), 36, 'FaceColor', col_seg, 'EdgeColor', 'w', 'FaceAlpha', 0.5);
pax = gca;
pax.ThetaZeroLocation = 'top';
pax.ThetaDir = 'clockwise';
title(sprintf('Loop orientation (grey, n=%d) vs\ninter-loop segment direction (green, n=%d)', ...
    numel(loop_rel), numel(seg_rel)), 'FontSize', 14);
legend([h1, h2], 'Loops', 'Inter-loop segments', 'Location', 'southoutside', 'FontSize', 11);

%% ================================================================
%  SECTION 5: Radial bias (cos) errorbar — loops vs segments vs distance
%  ================================================================

loop_cos = cosd(loop_rel);
seg_cos  = cosd(seg_rel);

n_dist_bins = 10;
bin_edges_d = linspace(0, ARENA_R, n_dist_bins + 1);
bin_centres_d = (bin_edges_d(1:end-1) + bin_edges_d(2:end)) / 2;

cos_bin_l = NaN(1, n_dist_bins);  cos_sem_l = NaN(1, n_dist_bins);
cos_bin_s = NaN(1, n_dist_bins);  cos_sem_s = NaN(1, n_dist_bins);

for bi = 1:n_dist_bins
    in_l = loop_dist >= bin_edges_d(bi) & loop_dist < bin_edges_d(bi+1);
    if sum(in_l) >= 5
        cos_bin_l(bi) = mean(loop_cos(in_l));
        cos_sem_l(bi) = std(loop_cos(in_l)) / sqrt(sum(in_l));
    end
    in_s = seg_dist >= bin_edges_d(bi) & seg_dist < bin_edges_d(bi+1);
    if sum(in_s) >= 5
        cos_bin_s(bi) = mean(seg_cos(in_s));
        cos_sem_s(bi) = std(seg_cos(in_s)) / sqrt(sum(in_s));
    end
end

figure('Position', [50 50 600 450], 'Name', 'Radial Bias vs Distance');
hold on;
errorbar(bin_centres_d, cos_bin_l, cos_sem_l, '-o', 'Color', col_loop * 0.6, ...
    'LineWidth', 2, 'MarkerFaceColor', col_loop * 0.6, 'MarkerSize', 6, 'CapSize', 4);
errorbar(bin_centres_d, cos_bin_s, cos_sem_s, '-s', 'Color', col_seg, ...
    'LineWidth', 2, 'MarkerFaceColor', col_seg, 'MarkerSize', 6, 'CapSize', 4);
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xlabel('Distance from centre (mm)', 'FontSize', 14);
ylabel('cos(rel angle) — radial component', 'FontSize', 14);
title('Radial bias (+1 = outward, -1 = inward)', 'FontSize', 14);
legend('Loops', 'Inter-loop segments', 'Location', 'best', 'FontSize', 11);
ylim([-0.7 0.8]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

%% ================================================================
%  SECTION 6: Per-fly centring score vs mean loop outward bias (cond 1)
%  (from LOOP_ORIENTATION_CENTRING, Figure 1 left subplot)
%  ================================================================

[fly_c1, ~] = detect_loops_for_condition(DATA, control_strain, sex, 1, loop_opts_fig3);

MIN_LOOPS_PER_FLY = 3;
has_data_c1 = fly_c1.n_loops >= MIN_LOOPS_PER_FLY & ~isnan(fly_c1.mean_cos);
cs_c1  = fly_c1.centring_score(has_data_c1);
mc_c1  = fly_c1.mean_cos(has_data_c1);
n_f_c1 = sum(has_data_c1);

figure('Position', [50 50 550 450], 'Name', 'Centring vs Loop Outward Bias (Cond 1)');
hold on;
scatter(cs_c1, mc_c1, 20, [0.1 0.1 0.1], 'filled', 'MarkerFaceAlpha', 0.4);

v = ~isnan(cs_c1) & ~isnan(mc_c1);
if sum(v) >= 5
    [r_sp, p_sp] = corr(cs_c1(v)', mc_c1(v)', 'Type', 'Spearman');
    p_fit = polyfit(cs_c1(v), mc_c1(v), 1);
    x_line = linspace(min(cs_c1), max(cs_c1), 100);
    plot(x_line, polyval(p_fit, x_line), '-', 'Color', [0.1 0.1 0.1], 'LineWidth', 2);
    text(0.05, 0.92, sprintf('Spearman r=%.3f\np=%.3e\nn=%d flies', r_sp, p_sp, n_f_c1), ...
        'Units', 'normalized', 'FontSize', 11, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
end

yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xlabel('Centring score (mm inward)', 'FontSize', 14);
ylabel('Mean cos(rel angle) — outward bias', 'FontSize', 14);
title('Per-fly: centring score vs outward loop bias (gratings)', 'FontSize', 14);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

%% ================================================================
%  SECTION 7: LMM plots — aspect ratio, bbox area, cos(rel angle) vs distance
%  (from control_loop_lmm.m)
%  ================================================================

% Load per-rep data and detect loops (same setup as control_loop_lmm.m)
data_types_lmm = {'heading_data', 'x_data', 'y_data', 'dist_data', 'vel_data'};
[rep_data_lmm, n_flies_lmm] = load_per_rep_data( ...
    DATA, control_strain, 'F', 1, data_types_lmm);

rep_data_lmm.x_data(:, MASK_START:MASK_END)       = NaN;
rep_data_lmm.y_data(:, MASK_START:MASK_END)       = NaN;
rep_data_lmm.heading_data(:, MASK_START:MASK_END) = NaN;

stim_range_lmm = STIM_ON:STIM_OFF;
x_stim_lmm       = rep_data_lmm.x_data(:, stim_range_lmm);
y_stim_lmm       = rep_data_lmm.y_data(:, stim_range_lmm);
heading_stim_lmm = rep_data_lmm.heading_data(:, stim_range_lmm);
vel_stim_lmm     = rep_data_lmm.vel_data(:, stim_range_lmm);

% Build flat arrays for LMM
flat_fly_id = [];  flat_area = [];  flat_aspect = [];
flat_dist_lmm = [];  flat_loop_cos_lmm = [];

for f = 1:n_flies_lmm
    loop_opts_fig3.vel = vel_stim_lmm(f,:);
    loops = find_trajectory_loops( ...
        x_stim_lmm(f,:), y_stim_lmm(f,:), heading_stim_lmm(f,:), loop_opts_fig3);

    if loops.n_loops > 0
        n_l = loops.n_loops;
        flat_fly_id = [flat_fly_id; repmat(f, n_l, 1)]; %#ok<AGROW>
        flat_area   = [flat_area; loops.bbox_area(:)]; %#ok<AGROW>
        flat_aspect = [flat_aspect; loops.bbox_aspect(:)]; %#ok<AGROW>
        flat_dist_lmm = [flat_dist_lmm; loops.bbox_dist_center(:)]; %#ok<AGROW>

        % Compute cos(rel_angle) for each loop
        for k = 1:n_l
            if loops.bbox_aspect(k) >= ASPECT_THRESHOLD
                sf = loops.start_frame(k);  ef = loops.end_frame(k);
                [~, ra, ~, ~] = compute_loop_orientation( ...
                    x_stim_lmm(f, sf:ef), y_stim_lmm(f, sf:ef), ARENA_CENTER);
                flat_loop_cos_lmm = [flat_loop_cos_lmm; cosd(ra)]; %#ok<AGROW>
            else
                flat_loop_cos_lmm = [flat_loop_cos_lmm; NaN]; %#ok<AGROW>
            end
        end
    end
end

fprintf('LMM data: %d loops from %d flies\n', numel(flat_area), n_flies_lmm);

% --- Fit and plot LMMs for aspect ratio, bbox area, cos(rel angle) ---
lmm_metric_data   = {flat_aspect, flat_area, flat_loop_cos_lmm};
lmm_metric_labels = {'Aspect ratio', 'Bbox area (mm^2)', 'cos(rel angle)'};
lmm_metric_vars   = {'bbox_aspect', 'bbox_area', 'cos_rel'};

x_pred_lmm = linspace(0, ARENA_R, 100)';
col_fly  = [0.216 0.494 0.722];
col_pop  = [0.10 0.25 0.54];

for mi = 1:3
    % Build table (remove NaN rows)
    valid_rows = ~isnan(flat_dist_lmm) & ~isnan(lmm_metric_data{mi});
    tbl = table( ...
        categorical(flat_fly_id(valid_rows)), ...
        flat_dist_lmm(valid_rows), ...
        lmm_metric_data{mi}(valid_rows), ...
        'VariableNames', {'fly_id', 'distance', lmm_metric_vars{mi}});

    formula = sprintf('%s ~ 1 + distance + (1 + distance | fly_id)', lmm_metric_vars{mi});
    mdl = fitlme(tbl, formula);

    fe = fixedEffects(mdl);
    [~, ~, fe_stats] = fixedEffects(mdl, 'DFMethod', 'satterthwaite');

    [~, ~, re_stats] = randomEffects(mdl);
    re_int = re_stats.Estimate(strcmp(re_stats.Name, '(Intercept)'));
    re_slp = re_stats.Estimate(strcmp(re_stats.Name, 'distance'));
    n_flies_re = numel(re_int);

    figure('Position', [50+mi*30 50+mi*30 750 550], ...
        'Name', sprintf('LMM: %s vs distance', lmm_metric_labels{mi}));
    hold on;

    % Per-fly predicted lines
    for fi = 1:n_flies_re
        y_fly = (fe(1) + re_int(fi)) + (fe(2) + re_slp(fi)) * x_pred_lmm;
        plot(x_pred_lmm, y_fly, '-', 'Color', [col_fly 0.15], 'LineWidth', 0.8);
    end

    % Population line
    y_pop = fe(1) + fe(2) * x_pred_lmm;
    plot(x_pred_lmm, y_pop, '-', 'Color', col_pop, 'LineWidth', 3);

    % 95% CI
    cov_fe = mdl.CoefficientCovariance;
    var_pred = cov_fe(1,1) + x_pred_lmm.^2 * cov_fe(2,2) + 2 * x_pred_lmm * cov_fe(1,2);
    se_pred = sqrt(var_pred);
    fill([x_pred_lmm; flipud(x_pred_lmm)], ...
        [y_pop + 1.96*se_pred; flipud(y_pop - 1.96*se_pred)], ...
        col_fly, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

    xlim([0 ARENA_R+5]);
    xlabel('Distance from centre (mm)', 'FontSize', 14);
    ylabel(lmm_metric_labels{mi}, 'FontSize', 14);
    title(sprintf('LMM: %s vs distance\nslope = %.4f [%.4f, %.4f], p = %.2e', ...
        lmm_metric_labels{mi}, fe_stats.Estimate(2), fe_stats.Lower(2), ...
        fe_stats.Upper(2), fe_stats.pValue(2)), 'FontSize', 14);
    text(5, max(ylim)*0.92, ...
        sprintf('Fixed slope: %.4f, p=%.2e\nn=%d loops, %d flies', ...
        fe(2), fe_stats.pValue(2), height(tbl), n_flies_re), ...
        'FontSize', 11, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
    set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
end

%% ================================================================
%  Local function: detect_loops_for_condition
%  (from LOOP_ORIENTATION_CENTRING.m)
%  ================================================================

function [fly_data, loop_data] = detect_loops_for_condition(DATA, strain, sex, cond, opts)
    fly_data  = struct('fly_id', [], 'centring_score', [], 'mean_cos', [], ...
        'mean_sin', [], 'n_loops', [], 'mean_dist', []);
    loop_data = struct('fly_id', [], 'cos_rel', [], 'sin_rel', [], ...
        'dist_center', [], 'centrip_disp_next', [], 'bbox_area', []);

    if ~isfield(DATA, strain), return; end
    if ~isfield(DATA.(strain), sex), return; end
    data_strain = DATA.(strain).(sex);
    n_exp = length(data_strain);
    rep1_str = strcat('R1_condition_', string(cond));
    rep2_str = strcat('R2_condition_', string(cond));
    if ~isfield(data_strain, rep1_str), return; end

    STIM_ON_ = 300;  STIM_OFF_ = 1200;
    MASK_S_  = 750;  MASK_E_   = 850;
    ARENA_C_ = opts.arena_center;

    fly_counter = 0;

    for exp_idx = 1:n_exp
        for rep_idx = 1:2
            if rep_idx == 1
                rep_data = data_strain(exp_idx).(rep1_str);
            else
                if ~isfield(data_strain(exp_idx), rep2_str), continue; end
                rep_data = data_strain(exp_idx).(rep2_str);
            end
            if isempty(rep_data), continue; end

            n_flies = size(rep_data.x_data, 1);
            n_frames_avail = size(rep_data.x_data, 2);
            sr_end = min(STIM_OFF_, n_frames_avail);
            sr = STIM_ON_:sr_end;

            vel_rep  = rep_data.vel_data(:, 1:n_frames_avail);
            dist_rep = rep_data.dist_data(:, 1:n_frames_avail);

            for f = 1:n_flies
                if sum(vel_rep(f,:) < 0.5) / n_frames_avail > 0.75, continue; end
                if min(dist_rep(f,:)) > 110, continue; end

                fly_counter = fly_counter + 1;

                x_fly = rep_data.x_data(f, sr);
                y_fly = rep_data.y_data(f, sr);
                h_fly = rep_data.heading_data(f, sr);

                d_onset  = mean(dist_rep(f, STIM_ON_:min(STIM_ON_+29, n_frames_avail)), 'omitnan');
                d_offset = mean(dist_rep(f, max(sr_end-29, STIM_ON_):sr_end), 'omitnan');
                centring_score = d_onset - d_offset;

                x_det = x_fly;  y_det = y_fly;  h_det = h_fly;
                mask_s = max(MASK_S_ - STIM_ON_ + 1, 1);
                mask_e = min(MASK_E_ - STIM_ON_ + 1, numel(x_fly));
                x_det(mask_s:mask_e) = NaN;
                y_det(mask_s:mask_e) = NaN;
                h_det(mask_s:mask_e) = NaN;

                v_fly = vel_rep(f, sr);
                v_fly(mask_s:mask_e) = NaN;
                opts.vel = v_fly;

                loops = find_trajectory_loops(x_det, y_det, h_det, opts);
                if loops.n_loops == 0
                    fly_data.fly_id(end+1)         = fly_counter;
                    fly_data.centring_score(end+1)  = centring_score;
                    fly_data.mean_cos(end+1)        = NaN;
                    fly_data.mean_sin(end+1)        = NaN;
                    fly_data.n_loops(end+1)         = 0;
                    fly_data.mean_dist(end+1)       = NaN;
                    continue;
                end

                cos_vals = NaN(1, loops.n_loops);
                sin_vals = NaN(1, loops.n_loops);
                dist_vals = loops.bbox_dist_center;

                for k = 1:loops.n_loops
                    if loops.bbox_aspect(k) < 1.1, continue; end
                    sf = loops.start_frame(k);  ef = loops.end_frame(k);
                    [~, ra, ~, ~] = compute_loop_orientation(x_fly(sf:ef), y_fly(sf:ef), ARENA_C_);
                    if ~isnan(ra)
                        cos_vals(k) = cosd(ra);
                        sin_vals(k) = sind(ra);
                    end
                end

                fly_data.fly_id(end+1)         = fly_counter;
                fly_data.centring_score(end+1)  = centring_score;
                fly_data.mean_cos(end+1)        = mean(cos_vals, 'omitnan');
                fly_data.mean_sin(end+1)        = mean(sin_vals, 'omitnan');
                fly_data.n_loops(end+1)         = loops.n_loops;
                fly_data.mean_dist(end+1)       = mean(dist_vals, 'omitnan');

                for k = 1:loops.n_loops
                    loop_data.fly_id(end+1)      = fly_counter;
                    loop_data.cos_rel(end+1)     = cos_vals(k);
                    loop_data.sin_rel(end+1)     = sin_vals(k);
                    loop_data.dist_center(end+1) = dist_vals(k);
                    loop_data.bbox_area(end+1)   = loops.bbox_area(k);
                    if k < loops.n_loops && ~isnan(dist_vals(k)) && ~isnan(dist_vals(k+1))
                        loop_data.centrip_disp_next(end+1) = dist_vals(k) - dist_vals(k+1);
                    else
                        loop_data.centrip_disp_next(end+1) = NaN;
                    end
                end
            end
        end
    end
end

