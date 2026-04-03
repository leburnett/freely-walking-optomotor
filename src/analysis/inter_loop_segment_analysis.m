%% INTER_LOOP_SEGMENT_ANALYSIS - Orientation of trajectory segments between loops
%
%  Analyses the straight-line direction of fly movement BETWEEN consecutive
%  loops. For each pair of consecutive loops in a fly's trajectory, the
%  inter-loop segment is extracted (from end of loop k to start of loop k+1)
%  and a direction vector is fitted from the earlier to the later time point.
%
%  The "distance from centre" of each segment is the distance from the
%  midpoint of the fitted line to the arena centre.
%
%  The direction is decomposed into radial and tangential components
%  relative to the arena centre:
%    cos(rel_angle) = radial component (+1 = outward, -1 = inward)
%    sin(rel_angle) = tangential component
%
%  Compares condition 1 (standard gratings, centring) with condition 7
%  (reverse-phi, no centring).
%
%  FIGURES:
%    Fig 1: Polar histogram of inter-loop segment directions (cond 1)
%    Fig 2: cos/sin decomposition vs distance from centre
%    Fig 3: Condition 1 vs 7 comparison (cos/sin vs distance)
%    Fig 4: Polar histograms side-by-side (cond 1 vs 7)
%    Fig 5: Polar histograms by radial zone (cond 1)
%
%  Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 27).
%
%  See also: find_trajectory_loops, loop_orientation_analysis

%% ================================================================
%  SECTION 1: Setup
%  ================================================================

if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

ARENA_CENTER = [528, 520] / 4.1691;
ARENA_R  = 120;
FPS      = 30;
STIM_ON  = 300;
STIM_OFF = 1200;
MASK_START = 750;
MASK_END   = 850;

sex = 'F';
control_strain = "jfrc100_es_shibire_kir";

MIN_SEGMENT_FRAMES = 5;  % segments shorter than this are too brief to have a direction

loop_opts.lookahead_frames = 75;
loop_opts.min_loop_frames  = 10;
loop_opts.fps              = FPS;
loop_opts.arena_center     = ARENA_CENTER;
loop_opts.arena_radius     = ARENA_R;

%% ================================================================
%  SECTION 2: Extract inter-loop segments for a given condition
%  ================================================================

    function seg = extract_inter_loop_segments(DATA, strain, sex, cond, loop_opts, min_frames)
        % Detects loops then extracts trajectory segments between consecutive
        % loops. Returns a struct with per-segment data.
        %
        % For a fly with loops at frames [s1,e1], [s2,e2], [s3,e3], the
        % inter-loop segments are: [e1+1, s2-1] and [e2+1, s3-1].

        seg = struct('fly_id', [], 'orient_angle', [], 'rel_angle', [], ...
            'cos_rel', [], 'sin_rel', [], 'dist_center', [], ...
            'midpoint_x', [], 'midpoint_y', [], 'seg_length_mm', [], ...
            'duration_s', []);

        if ~isfield(DATA, strain), return; end
        if ~isfield(DATA.(strain), sex), return; end
        data_strain = DATA.(strain).(sex);
        n_exp = length(data_strain);
        rep1_str = strcat('R1_condition_', string(cond));
        rep2_str = strcat('R2_condition_', string(cond));
        if ~isfield(data_strain, rep1_str), return; end

        STIM_ON_ = 300;  STIM_OFF_ = 1200;
        MASK_S_ = 750;  MASK_E_ = 850;
        ARENA_C_ = loop_opts.arena_center;
        fps_ = loop_opts.fps;

        fly_counter = 0;

        for exp_idx = 1:n_exp
            for rep_idx = 1:2
                if rep_idx == 1
                    rep_data = data_strain(exp_idx).(rep1_str);
                else
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

                    % NaN-mask reversal window for detection only
                    x_det = x_fly;  y_det = y_fly;  h_det = h_fly;
                    mask_s = max(MASK_S_ - STIM_ON_ + 1, 1);
                    mask_e = min(MASK_E_ - STIM_ON_ + 1, numel(x_fly));
                    x_det(mask_s:mask_e) = NaN;
                    y_det(mask_s:mask_e) = NaN;
                    h_det(mask_s:mask_e) = NaN;

                    v_fly = vel_rep(f, sr);
                    v_fly(mask_s:mask_e) = NaN;
                    loop_opts.vel = v_fly;

                    loops = find_trajectory_loops(x_det, y_det, h_det, loop_opts);
                    if loops.n_loops < 2, continue; end  % need at least 2 loops

                    % Extract segments between consecutive loops
                    for k = 1:(loops.n_loops - 1)
                        seg_start = loops.end_frame(k) + 1;
                        seg_end   = loops.start_frame(k+1) - 1;

                        if seg_end - seg_start + 1 < min_frames
                            continue;  % segment too short
                        end

                        x_seg = x_fly(seg_start:seg_end);
                        y_seg = y_fly(seg_start:seg_end);

                        % Remove NaN frames
                        valid = ~isnan(x_seg) & ~isnan(y_seg);
                        x_v = x_seg(valid);
                        y_v = y_seg(valid);
                        if numel(x_v) < min_frames, continue; end

                        % Direction: from first valid point to last valid point
                        % (time-ordered: earlier → later)
                        dx = x_v(end) - x_v(1);
                        dy = y_v(end) - y_v(1);
                        seg_len = sqrt(dx^2 + dy^2);

                        if seg_len < 0.5  % fly didn't move (< 0.5 mm)
                            continue;
                        end

                        % Absolute direction angle
                        orient_ang = atan2d(dy, dx);

                        % Midpoint of the segment (middle of the fitted line)
                        mid_x = (x_v(1) + x_v(end)) / 2;
                        mid_y = (y_v(1) + y_v(end)) / 2;

                        % Distance from midpoint to arena centre
                        d_center = sqrt((mid_x - ARENA_C_(1))^2 + (mid_y - ARENA_C_(2))^2);

                        % Radial direction from arena centre through midpoint
                        radial_ang = atan2d(mid_y - ARENA_C_(2), mid_x - ARENA_C_(1));

                        % Relative angle: 0 = outward, ±180 = inward
                        rel_ang = mod(orient_ang - radial_ang + 180, 360) - 180;

                        seg.fly_id(end+1)       = fly_counter;
                        seg.orient_angle(end+1)  = orient_ang;
                        seg.rel_angle(end+1)     = rel_ang;
                        seg.cos_rel(end+1)       = cosd(rel_ang);
                        seg.sin_rel(end+1)       = sind(rel_ang);
                        seg.dist_center(end+1)   = d_center;
                        seg.midpoint_x(end+1)    = mid_x;
                        seg.midpoint_y(end+1)    = mid_y;
                        seg.seg_length_mm(end+1)  = seg_len;
                        seg.duration_s(end+1)     = (seg_end - seg_start + 1) / fps_;
                    end
                end
            end
        end
    end

%% ================================================================
%  SECTION 3: Run extraction for conditions 1 and 7
%  ================================================================

fprintf('=== Inter-loop segment analysis ===\n');

fprintf('\n--- Condition 1 (standard gratings) ---\n');
seg_c1 = extract_inter_loop_segments(DATA, control_strain, sex, 1, loop_opts, MIN_SEGMENT_FRAMES);
n_seg_c1 = numel(seg_c1.fly_id);
fprintf('  %d inter-loop segments\n', n_seg_c1);
fprintf('  Mean segment length: %.1f mm\n', mean(seg_c1.seg_length_mm));
fprintf('  Mean segment duration: %.2f s\n', mean(seg_c1.duration_s));

fprintf('\n--- Condition 7 (reverse-phi) ---\n');
seg_c7 = extract_inter_loop_segments(DATA, control_strain, sex, 7, loop_opts, MIN_SEGMENT_FRAMES);
n_seg_c7 = numel(seg_c7.fly_id);
fprintf('  %d inter-loop segments\n', n_seg_c7);
fprintf('  Mean segment length: %.1f mm\n', mean(seg_c7.seg_length_mm));
fprintf('  Mean segment duration: %.2f s\n', mean(seg_c7.duration_s));

%% ================================================================
%  SECTION 4: Polar histogram of inter-loop directions (Figure 1)
%  ================================================================
%
%  Convention (same as loop orientation analysis):
%    0° (top)  = segment points radially outward
%    180° (bottom) = segment points radially inward (toward centre)
%    ±90° = tangential

figure('Position', [50 50 600 600], 'Name', 'Fig 1: Inter-Loop Polar (Cond 1)');
polarhistogram(deg2rad(seg_c1.rel_angle), 36, ...
    'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'w', 'FaceAlpha', 0.8);
pax = gca;
pax.ThetaZeroLocation = 'top';
pax.ThetaDir = 'clockwise';
title(sprintf('Inter-loop segment direction (cond 1)\n0° = outward, 180° = inward, n=%d', n_seg_c1), ...
    'FontSize', 14);

%% ================================================================
%  SECTION 5: Cos/sin decomposition vs distance (Figure 2)
%  ================================================================

n_dist_bins = 10;
bin_edges = linspace(0, ARENA_R, n_dist_bins + 1);
bin_centres = (bin_edges(1:end-1) + bin_edges(2:end)) / 2;

% Bin condition 1
cos_bin_c1 = NaN(1, n_dist_bins);
cos_sem_c1 = NaN(1, n_dist_bins);
sin_bin_c1 = NaN(1, n_dist_bins);
sin_sem_c1 = NaN(1, n_dist_bins);
n_bin_c1   = zeros(1, n_dist_bins);

for bi = 1:n_dist_bins
    in_b = seg_c1.dist_center >= bin_edges(bi) & seg_c1.dist_center < bin_edges(bi+1);
    n_bin_c1(bi) = sum(in_b);
    if n_bin_c1(bi) >= 5
        cos_bin_c1(bi) = mean(seg_c1.cos_rel(in_b));
        cos_sem_c1(bi) = std(seg_c1.cos_rel(in_b)) / sqrt(n_bin_c1(bi));
        sin_bin_c1(bi) = mean(seg_c1.sin_rel(in_b));
        sin_sem_c1(bi) = std(seg_c1.sin_rel(in_b)) / sqrt(n_bin_c1(bi));
    end
end

figure('Position', [50 50 1200 500], 'Name', 'Fig 2: Cos/Sin vs Distance (Cond 1)');
sgtitle('Inter-loop segment direction vs distance (condition 1)', 'FontSize', 18);

subplot(1, 2, 1);
hold on;
scatter(seg_c1.dist_center, seg_c1.cos_rel, 8, [0.7 0.7 0.7], 'filled', ...
    'MarkerFaceAlpha', 0.1, 'MarkerEdgeColor', 'none');
errorbar(bin_centres, cos_bin_c1, cos_sem_c1, '-ok', 'LineWidth', 2, ...
    'MarkerFaceColor', 'k', 'MarkerSize', 6, 'CapSize', 4);
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xlabel('Distance from centre (mm)', 'FontSize', 14);
ylabel('cos(rel angle) — radial component', 'FontSize', 14);
title('Radial bias (+1=outward, -1=inward)', 'FontSize', 14);
ylim([-1 1]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

subplot(1, 2, 2);
hold on;
scatter(seg_c1.dist_center, seg_c1.sin_rel, 8, [0.7 0.7 0.7], 'filled', ...
    'MarkerFaceAlpha', 0.1, 'MarkerEdgeColor', 'none');
errorbar(bin_centres, sin_bin_c1, sin_sem_c1, '-ok', 'LineWidth', 2, ...
    'MarkerFaceColor', 'k', 'MarkerSize', 6, 'CapSize', 4);
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xlabel('Distance from centre (mm)', 'FontSize', 14);
ylabel('sin(rel angle) — tangential component', 'FontSize', 14);
title('Tangential bias', 'FontSize', 14);
ylim([-1 1]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

%% ================================================================
%  SECTION 6: Condition 1 vs 7 comparison (Figure 3)
%  ================================================================

% Bin condition 7
cos_bin_c7 = NaN(1, n_dist_bins);
cos_sem_c7 = NaN(1, n_dist_bins);
sin_bin_c7 = NaN(1, n_dist_bins);
sin_sem_c7 = NaN(1, n_dist_bins);

for bi = 1:n_dist_bins
    in_b = seg_c7.dist_center >= bin_edges(bi) & seg_c7.dist_center < bin_edges(bi+1);
    if sum(in_b) >= 5
        cos_bin_c7(bi) = mean(seg_c7.cos_rel(in_b));
        cos_sem_c7(bi) = std(seg_c7.cos_rel(in_b)) / sqrt(sum(in_b));
        sin_bin_c7(bi) = mean(seg_c7.sin_rel(in_b));
        sin_sem_c7(bi) = std(seg_c7.sin_rel(in_b)) / sqrt(sum(in_b));
    end
end

figure('Position', [50 50 1200 500], ...
    'Name', 'Fig 3: Cond 1 vs 7 Segment Direction');
sgtitle('Inter-loop segment direction: gratings vs reverse-phi', 'FontSize', 16);

subplot(1, 2, 1);
hold on;
errorbar(bin_centres, cos_bin_c1, cos_sem_c1, '-o', 'Color', [0.1 0.1 0.1], ...
    'LineWidth', 2, 'MarkerFaceColor', [0.1 0.1 0.1], 'MarkerSize', 6, 'CapSize', 4);
errorbar(bin_centres, cos_bin_c7, cos_sem_c7, '-s', 'Color', [0.894 0.102 0.110], ...
    'LineWidth', 2, 'MarkerFaceColor', [0.894 0.102 0.110], 'MarkerSize', 6, 'CapSize', 4);
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xlabel('Distance from centre (mm)', 'FontSize', 14);
ylabel('cos(rel angle) — radial component', 'FontSize', 14);
title('Radial bias (+1=outward, -1=inward)', 'FontSize', 14);
legend('Cond 1 (gratings)', 'Cond 7 (reverse-phi)', 'Location', 'best');
ylim([-0.8 0.5]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

subplot(1, 2, 2);
hold on;
errorbar(bin_centres, sin_bin_c1, sin_sem_c1, '-o', 'Color', [0.1 0.1 0.1], ...
    'LineWidth', 2, 'MarkerFaceColor', [0.1 0.1 0.1], 'MarkerSize', 6, 'CapSize', 4);
errorbar(bin_centres, sin_bin_c7, sin_sem_c7, '-s', 'Color', [0.894 0.102 0.110], ...
    'LineWidth', 2, 'MarkerFaceColor', [0.894 0.102 0.110], 'MarkerSize', 6, 'CapSize', 4);
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xlabel('Distance from centre (mm)', 'FontSize', 14);
ylabel('sin(rel angle) — tangential component', 'FontSize', 14);
title('Tangential bias', 'FontSize', 14);
legend('Cond 1 (gratings)', 'Cond 7 (reverse-phi)', 'Location', 'best');
ylim([-0.5 0.5]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

%% ================================================================
%  SECTION 7: Polar histograms side-by-side (Figure 4)
%  ================================================================

figure('Position', [50 50 1100 500], 'Name', 'Fig 4: Polar Cond 1 vs 7');
sgtitle('Inter-loop segment direction: gratings vs reverse-phi', 'FontSize', 16);

subplot(1, 2, 1);
polarhistogram(deg2rad(seg_c1.rel_angle), 36, ...
    'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'w', 'FaceAlpha', 0.8);
pax1 = gca; pax1.ThetaZeroLocation = 'top'; pax1.ThetaDir = 'clockwise';
title(sprintf('Cond 1 — gratings\n(n=%d, centres)', n_seg_c1), 'FontSize', 13);

subplot(1, 2, 2);
polarhistogram(deg2rad(seg_c7.rel_angle), 36, ...
    'FaceColor', [0.894 0.102 0.110], 'EdgeColor', 'w', 'FaceAlpha', 0.7);
pax7 = gca; pax7.ThetaZeroLocation = 'top'; pax7.ThetaDir = 'clockwise';
title(sprintf('Cond 7 — reverse-phi\n(n=%d, no centring)', n_seg_c7), 'FontSize', 13);

%% ================================================================
%  SECTION 8: Polar histograms by radial zone (Figure 5)
%  ================================================================

zone_edges  = [0 40 80 120];
zone_labels = {'Inner (0-40 mm)', 'Middle (40-80 mm)', 'Outer (80-120 mm)'};
zone_colors = [0.75 0.85 0.95; 0.40 0.58 0.78; 0.10 0.25 0.54];

figure('Position', [50 50 1400 450], 'Name', 'Fig 5: Segments by Zone (Cond 1)');
sgtitle('Inter-loop segment direction by radial zone (condition 1)', 'FontSize', 16);

for zi = 1:3
    subplot(1, 3, zi);
    in_zone = seg_c1.dist_center >= zone_edges(zi) & seg_c1.dist_center < zone_edges(zi+1);
    angles_z = seg_c1.rel_angle(in_zone);
    polarhistogram(deg2rad(angles_z), 36, ...
        'FaceColor', zone_colors(zi,:), 'EdgeColor', 'w', 'FaceAlpha', 0.7);
    pax_z = gca; pax_z.ThetaZeroLocation = 'top'; pax_z.ThetaDir = 'clockwise';
    title(sprintf('%s\n(n=%d)', zone_labels{zi}, numel(angles_z)), 'FontSize', 13);
end

%% ================================================================
%  RESULTS
%  ================================================================

fprintf('\n======================================================================\n');
fprintf('  INTER-LOOP SEGMENT ANALYSIS — RESULTS\n');
fprintf('======================================================================\n');

% --- Overall direction ---
for ci = 1:2
    if ci == 1
        s = seg_c1; lbl = 'Cond 1 (gratings)';
    else
        s = seg_c7; lbl = 'Cond 7 (reverse-phi)';
    end
    n_s = numel(s.fly_id);
    mc = mean(s.cos_rel, 'omitnan');
    ms = mean(s.sin_rel, 'omitnan');
    S = mean(sind(s.rel_angle), 'omitnan');
    C = mean(cosd(s.rel_angle), 'omitnan');
    cm = atan2d(S, C);
    r  = sqrt(S^2 + C^2);

    fprintf('\n--- %s ---\n', lbl);
    fprintf('  n segments: %d\n', n_s);
    fprintf('  Mean segment length: %.1f mm\n', mean(s.seg_length_mm));
    fprintf('  Mean segment duration: %.2f s\n', mean(s.duration_s));
    fprintf('  Circular mean direction: %.1f°\n', cm);
    fprintf('  Resultant length (r): %.3f\n', r);
    fprintf('  mean(cos) [radial]:     %+.3f  (+ve = outward)\n', mc);
    fprintf('  mean(sin) [tangential]: %+.3f\n', ms);
    fprintf('  Fraction pointing inward (|angle| > 90°): %.1f%%\n', ...
        100 * sum(abs(s.rel_angle) > 90) / n_s);
end

% --- Binned comparison ---
fprintf('\n--- Binned cos (radial bias) comparison ---\n');
fprintf('  %-12s %-6s %-10s %-6s %-10s\n', 'Bin', 'n(C1)', 'cos(C1)', 'n(C7)', 'cos(C7)');
for bi = 1:n_dist_bins
    in_b1 = seg_c1.dist_center >= bin_edges(bi) & seg_c1.dist_center < bin_edges(bi+1);
    in_b7 = seg_c7.dist_center >= bin_edges(bi) & seg_c7.dist_center < bin_edges(bi+1);
    n1 = sum(in_b1); n7 = sum(in_b7);
    c1 = cos_bin_c1(bi); c7 = cos_bin_c7(bi);
    if n1 >= 5 || n7 >= 5
        fprintf('  %-12s %-6d %-+10.3f %-6d %-+10.3f\n', ...
            sprintf('%.0f-%.0f mm', bin_edges(bi), bin_edges(bi+1)), n1, c1, n7, c7);
    end
end

% --- Wilcoxon comparison ---
[p_cos, ~] = ranksum(seg_c1.cos_rel', seg_c7.cos_rel');
[p_sin, ~] = ranksum(seg_c1.sin_rel', seg_c7.sin_rel');
fprintf('\n--- Wilcoxon rank-sum (Cond 1 vs 7) ---\n');
fprintf('  cos (radial bias):     p = %.3e\n', p_cos);
fprintf('  sin (tangential bias): p = %.3e\n', p_sin);

% --- Per-zone breakdown (Cond 1) ---
fprintf('\n--- Per-zone direction (Cond 1) ---\n');
for zi = 1:3
    in_zone = seg_c1.dist_center >= zone_edges(zi) & seg_c1.dist_center < zone_edges(zi+1);
    az = seg_c1.rel_angle(in_zone);
    n_z = numel(az);
    if n_z >= 5
        S_z = mean(sind(az)); C_z = mean(cosd(az));
        fprintf('  %s: n=%d, circ mean=%.1f°, r=%.3f, mean(cos)=%+.3f, %% inward=%.0f%%\n', ...
            zone_labels{zi}, n_z, atan2d(S_z, C_z), sqrt(S_z^2 + C_z^2), ...
            mean(seg_c1.cos_rel(in_zone)), 100*sum(abs(az)>90)/n_z);
    end
end

fprintf('\n======================================================================\n');
fprintf('  5 figures generated\n');
fprintf('======================================================================\n');
