%% LOOP_ORIENTATION_CENTRING - Link loop orientation to centring behaviour
%
%  Tests whether the outward bias in loop orientation (cos component) is
%  related to centring behaviour at two levels:
%
%  1. PER-FLY: Does a fly that centres more also show a stronger outward
%     loop bias? Correlates each fly's "centring score" (inward displacement
%     during the stimulus) with their mean cos(rel_angle).
%
%  2. PER-LOOP: After a given loop, does the fly move closer to or further
%     from the centre? Correlates the cos(rel_angle) of each loop with the
%     centripetal displacement to the NEXT consecutive loop:
%       centripetal_disp = dist_centre(loop_k) - dist_centre(loop_k+1)
%       positive = fly moved inward between loops
%       negative = fly moved outward
%
%  This tests whether more outward-pointing loops are followed by more
%  inward movement — i.e., whether the loop is part of a centring manoeuvre.
%
%  FIGURES:
%    Fig 1: Per-fly centring score vs mean cos(rel_angle) scatter
%    Fig 2: Per-loop cos(rel_angle) vs centripetal displacement to next loop
%    Fig 3: Binned centripetal displacement by cos quartile
%    Fig 4: Condition 1 vs 7 per-loop comparison
%
%  Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 27).
%
%  See also: compute_loop_orientation, find_trajectory_loops, loop_orientation_analysis

%% ================================================================
%  SECTION 1: Setup and loop detection
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
ASPECT_THRESHOLD = 1.1;

control_strain = "jfrc100_es_shibire_kir";

loop_opts.lookahead_frames = 75;
loop_opts.min_loop_frames  = 10;
loop_opts.fps              = FPS;
loop_opts.arena_center     = ARENA_CENTER;
loop_opts.arena_radius     = ARENA_R;

%% ================================================================
%  SECTION 2: Detect loops + compute orientation + centring scores
%  ================================================================
%
%  For each fly we compute:
%    - Per-loop: cos(rel_angle), bbox_dist_center
%    - Per-fly: centring_score = dist_from_centre(stim_onset) - dist_from_centre(stim_offset)
%               (positive = fly moved inward during the stimulus)

fprintf('=== Loop orientation & centring analysis ===\n');

% Helper function to process one condition
    function [fly_data, loop_data] = detect_loops_for_condition(DATA, strain, sex, cond, opts)
        % Returns per-fly and per-loop data tables for one condition.
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

        STIM_ON_  = 300;  STIM_OFF_ = 1200;
        MASK_S_ = 750;  MASK_E_ = 850;
        ARENA_C_ = opts.arena_center;

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

                    % Centring score: distance from centre at stim onset
                    % vs stim offset (using dist_data which = distance from centre)
                    % Use mean of first/last 30 frames to be robust to noise
                    d_onset  = mean(dist_rep(f, STIM_ON_:min(STIM_ON_+29, n_frames_avail)), 'omitnan');
                    d_offset = mean(dist_rep(f, max(sr_end-29, STIM_ON_):sr_end), 'omitnan');
                    centring_score = d_onset - d_offset;  % positive = moved inward

                    % NaN-mask reversal window for detection
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
                        % Still record fly with no loops for completeness
                        fly_data.fly_id(end+1)        = fly_counter;
                        fly_data.centring_score(end+1) = centring_score;
                        fly_data.mean_cos(end+1)       = NaN;
                        fly_data.mean_sin(end+1)       = NaN;
                        fly_data.n_loops(end+1)        = 0;
                        fly_data.mean_dist(end+1)      = NaN;
                        continue;
                    end

                    % Compute orientation for each loop
                    cos_vals = NaN(1, loops.n_loops);
                    sin_vals = NaN(1, loops.n_loops);
                    dist_vals = loops.bbox_dist_center;

                    for k = 1:loops.n_loops
                        if loops.bbox_aspect(k) < 1.1, continue; end  % aspect threshold
                        sf = loops.start_frame(k);
                        ef = loops.end_frame(k);
                        [~, ra, ~, ~] = compute_loop_orientation( ...
                            x_fly(sf:ef), y_fly(sf:ef), ARENA_C_);
                        if ~isnan(ra)
                            cos_vals(k) = cosd(ra);
                            sin_vals(k) = sind(ra);
                        end
                    end

                    % Per-fly summary
                    fly_data.fly_id(end+1)        = fly_counter;
                    fly_data.centring_score(end+1) = centring_score;
                    fly_data.mean_cos(end+1)       = mean(cos_vals, 'omitnan');
                    fly_data.mean_sin(end+1)       = mean(sin_vals, 'omitnan');
                    fly_data.n_loops(end+1)        = loops.n_loops;
                    fly_data.mean_dist(end+1)      = mean(dist_vals, 'omitnan');

                    % Per-loop data with centripetal displacement to NEXT loop
                    for k = 1:loops.n_loops
                        loop_data.fly_id(end+1)    = fly_counter;
                        loop_data.cos_rel(end+1)   = cos_vals(k);
                        loop_data.sin_rel(end+1)   = sin_vals(k);
                        loop_data.dist_center(end+1) = dist_vals(k);
                        loop_data.bbox_area(end+1) = loops.bbox_area(k);

                        % Centripetal displacement to the NEXT loop:
                        % positive = next loop is closer to centre (fly moved inward)
                        if k < loops.n_loops && ~isnan(dist_vals(k)) && ~isnan(dist_vals(k+1))
                            loop_data.centrip_disp_next(end+1) = dist_vals(k) - dist_vals(k+1);
                        else
                            loop_data.centrip_disp_next(end+1) = NaN;  % last loop or missing data
                        end
                    end
                end
            end
        end
    end

%% ================================================================
%  SECTION 3: Run detection for conditions 1 and 7
%  ================================================================

fprintf('\n--- Condition 1 (standard gratings, centring) ---\n');
[fly_c1, loop_c1] = detect_loops_for_condition(DATA, control_strain, sex, 1, loop_opts);
n_flies_c1 = numel(fly_c1.fly_id);
n_loops_c1 = numel(loop_c1.fly_id);
fprintf('  %d flies, %d loops\n', n_flies_c1, n_loops_c1);

fprintf('\n--- Condition 7 (reverse-phi, no centring) ---\n');
[fly_c7, loop_c7] = detect_loops_for_condition(DATA, control_strain, sex, 7, loop_opts);
n_flies_c7 = numel(fly_c7.fly_id);
n_loops_c7 = numel(loop_c7.fly_id);
fprintf('  %d flies, %d loops\n', n_flies_c7, n_loops_c7);

%% ================================================================
%  SECTION 4: Per-fly centring score vs mean cos(rel_angle) (Figure 1)
%  ================================================================
%
%  Each fly contributes one point. The centring score is the inward
%  displacement during the stimulus (positive = moved toward centre).
%  The mean cos(rel_angle) summarises how outward-biased that fly's
%  loops were on average.
%
%  If outward loop bias is linked to centring, we expect a positive
%  correlation: flies that centre more have more outward-pointing loops.

MIN_LOOPS_PER_FLY = 3;

% Condition 1
has_data_c1 = fly_c1.n_loops >= MIN_LOOPS_PER_FLY & ~isnan(fly_c1.mean_cos);
cs_c1  = fly_c1.centring_score(has_data_c1);
mc_c1  = fly_c1.mean_cos(has_data_c1);
n_f_c1 = sum(has_data_c1);

% Condition 7
has_data_c7 = fly_c7.n_loops >= MIN_LOOPS_PER_FLY & ~isnan(fly_c7.mean_cos);
cs_c7  = fly_c7.centring_score(has_data_c7);
mc_c7  = fly_c7.mean_cos(has_data_c7);
n_f_c7 = sum(has_data_c7);

figure('Position', [50 50 1200 500], 'Name', 'Fig 1: Per-Fly Centring vs Cos');
sgtitle('Per-fly: centring score vs mean loop outward bias', 'FontSize', 18);

for ci = 1:2
    subplot(1, 2, ci);
    hold on;

    if ci == 1
        x_p = cs_c1; y_p = mc_c1; n_p = n_f_c1;
        col = [0.1 0.1 0.1]; lbl = 'Cond 1 (gratings)';
    else
        x_p = cs_c7; y_p = mc_c7; n_p = n_f_c7;
        col = [0.894 0.102 0.110]; lbl = 'Cond 7 (reverse-phi)';
    end

    scatter(x_p, y_p, 20, col, 'filled', 'MarkerFaceAlpha', 0.4);

    % OLS fit + correlation
    v = ~isnan(x_p) & ~isnan(y_p);
    if sum(v) >= 5
        [r, p_r] = corr(x_p(v)', y_p(v)', 'Type', 'Spearman');
        p_fit = polyfit(x_p(v), y_p(v), 1);
        x_line = linspace(min(x_p), max(x_p), 100);
        plot(x_line, polyval(p_fit, x_line), '-', 'Color', col, 'LineWidth', 2);
        text(0.05, 0.92, sprintf('Spearman r=%.3f\np=%.3e\nn=%d flies', r, p_r, n_p), ...
            'Units', 'normalized', 'FontSize', 11, 'FontWeight', 'bold', ...
            'VerticalAlignment', 'top');
    end

    yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    xline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    xlabel('Centring score (mm inward)', 'FontSize', 14);
    ylabel('Mean cos(rel angle) — outward bias', 'FontSize', 14);
    title(lbl, 'FontSize', 14);
    set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
end

%% ================================================================
%  SECTION 5: Per-loop cos vs centripetal displacement to next loop (Fig 2)
%  ================================================================
%
%  For each loop (except the last in each fly's trajectory), we ask:
%  "After this loop, did the fly move closer to the centre?"
%
%    centripetal_disp = dist_centre(this_loop) - dist_centre(next_loop)
%      positive = fly moved inward (centring)
%      negative = fly moved outward
%
%  If outward-pointing loops are followed by inward movement, we expect
%  a positive correlation between cos(rel_angle) and centripetal_disp.

% Filter to loops with valid orientation AND a next loop
has_next_c1 = ~isnan(loop_c1.cos_rel) & ~isnan(loop_c1.centrip_disp_next);
cos_loop_c1    = loop_c1.cos_rel(has_next_c1);
cdisp_c1       = loop_c1.centrip_disp_next(has_next_c1);
dist_loop_c1   = loop_c1.dist_center(has_next_c1);

has_next_c7 = ~isnan(loop_c7.cos_rel) & ~isnan(loop_c7.centrip_disp_next);
cos_loop_c7    = loop_c7.cos_rel(has_next_c7);
cdisp_c7       = loop_c7.centrip_disp_next(has_next_c7);
dist_loop_c7   = loop_c7.dist_center(has_next_c7);

figure('Position', [50 50 1200 500], ...
    'Name', 'Fig 2: Per-Loop Cos vs Centripetal Displacement');
sgtitle('Per-loop: outward bias vs centripetal displacement to next loop', 'FontSize', 16);

for ci = 1:2
    subplot(1, 2, ci);
    hold on;

    if ci == 1
        xd = cos_loop_c1; yd = cdisp_c1;
        col = [0.1 0.1 0.1]; lbl = 'Cond 1 (gratings)';
    else
        xd = cos_loop_c7; yd = cdisp_c7;
        col = [0.894 0.102 0.110]; lbl = 'Cond 7 (reverse-phi)';
    end

    scatter(xd, yd, 8, col, 'filled', 'MarkerFaceAlpha', 0.1);

    % Binned means
    bin_edges_cos = linspace(-1, 1, 9);  % 8 bins across cos range
    bin_c_cos = (bin_edges_cos(1:end-1) + bin_edges_cos(2:end)) / 2;
    mean_disp = NaN(1, 8);
    sem_disp  = NaN(1, 8);
    n_bin     = zeros(1, 8);
    for bi = 1:8
        in_b = xd >= bin_edges_cos(bi) & xd < bin_edges_cos(bi+1);
        n_bin(bi) = sum(in_b);
        if n_bin(bi) >= 10
            mean_disp(bi) = mean(yd(in_b));
            sem_disp(bi)  = std(yd(in_b)) / sqrt(n_bin(bi));
        end
    end
    errorbar(bin_c_cos, mean_disp, sem_disp, '-ok', 'LineWidth', 2, ...
        'MarkerFaceColor', col, 'MarkerSize', 6, 'CapSize', 4);

    yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    xline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

    % Spearman correlation
    v = ~isnan(xd) & ~isnan(yd);
    [r, p_r] = corr(xd(v)', yd(v)', 'Type', 'Spearman');
    text(0.05, 0.92, sprintf('Spearman r=%.3f\np=%.3e\nn=%d loops', r, p_r, sum(v)), ...
        'Units', 'normalized', 'FontSize', 11, 'FontWeight', 'bold', ...
        'VerticalAlignment', 'top');

    xlabel('cos(rel angle) — outward bias of this loop', 'FontSize', 13);
    ylabel('Centripetal disp to next loop (mm)', 'FontSize', 13);
    title(lbl, 'FontSize', 14);
    set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
end

%% ================================================================
%  SECTION 6: Centripetal displacement by cos quartile (Figure 3)
%  ================================================================
%
%  Bins loops into quartiles by cos(rel_angle) and shows the mean
%  centripetal displacement to the next loop for each quartile.
%  This makes the relationship easier to see than the raw scatter.

figure('Position', [50 50 800 500], ...
    'Name', 'Fig 3: Centripetal Displacement by Cos Quartile');

quartile_edges = [-1, -0.5, 0, 0.5, 1];
quartile_labels = {"Inward", "Slight inward", "Slight outward", "Outward"};

% Compute means for both conditions into a [4 x 2] matrix for grouped bar
means_both = NaN(4, 2);
sems_both  = NaN(4, 2);
ns_both    = zeros(4, 2);

for ci = 1:2
    if ci == 1
        xd = cos_loop_c1; yd = cdisp_c1;
    else
        xd = cos_loop_c7; yd = cdisp_c7;
    end

    for qi = 1:4
        if qi < 4
            in_q = xd >= quartile_edges(qi) & xd < quartile_edges(qi+1);
        else
            in_q = xd >= quartile_edges(qi) & xd <= quartile_edges(qi+1);
        end
        vals = yd(in_q & ~isnan(yd));
        ns_both(qi, ci) = numel(vals);
        if numel(vals) >= 10
            means_both(qi, ci) = mean(vals);
            sems_both(qi, ci)  = std(vals) / sqrt(numel(vals));
        end
    end
end

% Grouped bar: each row = one quartile, each column = one condition
bh = bar(1:4, means_both, 'grouped');
bh(1).FaceColor = [0.85 0.85 0.85];        % Cond 1 — light grey
bh(1).EdgeColor = 'none';
bh(2).FaceColor = [0.95 0.6 0.6];          % Cond 7 — light red
bh(2).EdgeColor = 'none';

hold on;

% Error bars — use the actual XEndPoints from each bar series
for ci = 1:2
    errorbar(bh(ci).XEndPoints, means_both(:,ci), sems_both(:,ci), 'k', ...
        'LineStyle', 'none', 'LineWidth', 1.2, 'CapSize', 5);
end

yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
set(gca, 'XTick', 1:4, 'XTickLabel', quartile_labels);
ylabel('Centripetal disp to next loop (mm)', 'FontSize', 14);
xlabel('Loop orientation quartile (cos of relative angle)', 'FontSize', 14);
title('Centripetal displacement by loop orientation quartile', 'FontSize', 16);
legend([bh(1), bh(2)], 'Cond 1 (gratings)', 'Cond 7 (reverse-phi)', 'Location', 'best');
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

%% ================================================================
%  SECTION 7: Distance-controlled analysis (Figure 4)
%  ================================================================
%
%  The per-loop correlation could be confounded by distance: loops near
%  the wall tend to be outward AND the fly tends to move inward simply
%  because it's near the wall. To control for this, we split by radial
%  zone and check if the cos-centripetal relationship holds within zones.

zone_edges  = [0 40 80 120];
zone_labels = {'Inner (0-40 mm)', 'Middle (40-80 mm)', 'Outer (80-120 mm)'};

figure('Position', [50 50 1400 450], ...
    'Name', 'Fig 4: Cos vs Centripetal Disp by Zone (Cond 1)');
sgtitle('Condition 1: cos vs centripetal displacement within radial zones', 'FontSize', 16);

for zi = 1:3
    subplot(1, 3, zi);
    hold on;

    in_zone = dist_loop_c1 >= zone_edges(zi) & dist_loop_c1 < zone_edges(zi+1);
    xz = cos_loop_c1(in_zone);
    yz = cdisp_c1(in_zone);

    scatter(xz, yz, 8, [0.3 0.3 0.3], 'filled', 'MarkerFaceAlpha', 0.1);

    % Binned means within zone
    for bi = 1:8
        in_b = xz >= bin_edges_cos(bi) & xz < bin_edges_cos(bi+1);
        if sum(in_b) >= 10
            m = mean(yz(in_b));
            s = std(yz(in_b)) / sqrt(sum(in_b));
            errorbar(bin_c_cos(bi), m, s, 'ok', 'LineWidth', 1.5, ...
                'MarkerFaceColor', 'k', 'MarkerSize', 5, 'CapSize', 3);
        end
    end

    yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    xline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

    v = ~isnan(xz) & ~isnan(yz);
    if sum(v) >= 10
        [r, p_r] = corr(xz(v)', yz(v)', 'Type', 'Spearman');
        text(0.05, 0.92, sprintf('r=%.3f, p=%.2e\nn=%d', r, p_r, sum(v)), ...
            'Units', 'normalized', 'FontSize', 10, 'FontWeight', 'bold', ...
            'VerticalAlignment', 'top');
    end

    xlabel('cos(rel angle)', 'FontSize', 12);
    if zi == 1, ylabel('Centripetal disp (mm)', 'FontSize', 12); end
    title(zone_labels{zi}, 'FontSize', 13);
    set(gca, 'FontSize', 11, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
end

%% ================================================================
%  RESULTS
%  ================================================================

fprintf('\n======================================================================\n');
fprintf('  LOOP ORIENTATION & CENTRING — RESULTS\n');
fprintf('======================================================================\n');

% --- Per-fly results ---
fprintf('\n--- Per-fly: centring score vs mean cos(rel_angle) ---\n');
fprintf('  (centring score = mm moved inward during stimulus)\n\n');

for ci = 1:2
    if ci == 1
        x_p = cs_c1; y_p = mc_c1; n_p = n_f_c1; lbl = 'Cond 1 (gratings)';
    else
        x_p = cs_c7; y_p = mc_c7; n_p = n_f_c7; lbl = 'Cond 7 (reverse-phi)';
    end
    v = ~isnan(x_p) & ~isnan(y_p);
    [r, p_r] = corr(x_p(v)', y_p(v)', 'Type', 'Spearman');
    fprintf('  %s:\n', lbl);
    fprintf('    n flies (>=%d loops): %d\n', MIN_LOOPS_PER_FLY, n_p);
    fprintf('    Mean centring score: %.1f mm\n', mean(x_p, 'omitnan'));
    fprintf('    Mean cos(rel angle): %.3f\n', mean(y_p, 'omitnan'));
    fprintf('    Spearman r = %.3f, p = %.3e\n', r, p_r);
    fprintf('    (positive r = flies that centre more have more outward loops)\n\n');
end

% --- Per-loop results ---
fprintf('--- Per-loop: cos(rel_angle) vs centripetal displacement to next loop ---\n');
fprintf('  (centripetal disp = mm the fly moved inward between this loop and next)\n\n');

for ci = 1:2
    if ci == 1
        xd = cos_loop_c1; yd = cdisp_c1; lbl = 'Cond 1 (gratings)';
    else
        xd = cos_loop_c7; yd = cdisp_c7; lbl = 'Cond 7 (reverse-phi)';
    end
    v = ~isnan(xd) & ~isnan(yd);
    [r, p_r] = corr(xd(v)', yd(v)', 'Type', 'Spearman');
    fprintf('  %s:\n', lbl);
    fprintf('    n loop pairs: %d\n', sum(v));
    fprintf('    Mean centripetal disp: %.2f mm\n', mean(yd(v)));
    fprintf('    Spearman r(cos, disp) = %.3f, p = %.3e\n', r, p_r);
    fprintf('    (positive r = more outward loops are followed by more inward movement)\n\n');
end

% --- Per-loop by cos quartile ---
fprintf('--- Centripetal displacement by cos quartile (Cond 1) ---\n');
fprintf('  %-20s %-8s %-12s %-10s\n', 'Quartile', 'n', 'Mean disp', 'SEM');
for qi = 1:4
    if qi < 4
        in_q = cos_loop_c1 >= quartile_edges(qi) & cos_loop_c1 < quartile_edges(qi+1);
    else
        in_q = cos_loop_c1 >= quartile_edges(qi) & cos_loop_c1 <= quartile_edges(qi+1);
    end
    vals = cdisp_c1(in_q);
    vals = vals(~isnan(vals));
    if numel(vals) >= 5
        fprintf('  %-20s %-8d %-+12.2f %-10.2f\n', ...
            sprintf('[%.1f, %.1f)', quartile_edges(qi), quartile_edges(qi+1)), ...
            numel(vals), mean(vals), std(vals)/sqrt(numel(vals)));
    end
end

% --- Within-zone correlations ---
fprintf('\n--- Within-zone correlations (Cond 1, controlling for distance) ---\n');
for zi = 1:3
    in_zone = dist_loop_c1 >= zone_edges(zi) & dist_loop_c1 < zone_edges(zi+1);
    xz = cos_loop_c1(in_zone);
    yz = cdisp_c1(in_zone);
    v = ~isnan(xz) & ~isnan(yz);
    if sum(v) >= 10
        [r, p_r] = corr(xz(v)', yz(v)', 'Type', 'Spearman');
        fprintf('  %s: r=%.3f, p=%.3e, n=%d\n', zone_labels{zi}, r, p_r, sum(v));
    else
        fprintf('  %s: too few data points (n=%d)\n', zone_labels{zi}, sum(v));
    end
end

fprintf('\n======================================================================\n');
fprintf('  4 figures generated\n');
fprintf('======================================================================\n');
