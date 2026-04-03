%% LOOP_ORIENTATION_ANALYSIS - Orientation of trajectory loops via PCA
%
%  Computes the long-axis orientation of self-intersection loops using PCA
%  and analyses whether loops systematically point toward or away from the
%  arena centre. Tests the hypothesis that flies make pivot-style loops
%  that reorient them toward the centre during optomotor stimulation.
%
%  The orientation is defined as the direction of the first principal
%  component (maximum variance axis) of the (x,y) points within a loop,
%  oriented AWAY from the self-intersection point (toward the "bulge").
%  Near-circular loops (bbox_aspect < threshold) are excluded because
%  their long axis is undefined.
%
%  FIGURES:
%    Fig 1:  Polar histogram of loop orientations relative to radial
%    Fig 2:  Orientation vs radial position (binned circular means)
%    Fig 3:  Orientation vs heading at loop entry
%    Fig 4:  Spatial quiver plot of loop orientations on the arena
%    Fig 5:  CW vs CCW split polar histograms
%    Fig 6:  Rose plots by radial zone (inner / middle / outer)
%    Fig 7:  Per-strain polar histograms
%    Fig 8:  cos/sin decomposition vs distance (radial + tangential bias)
%    Fig 9:  Condition 1 vs 7 cos/sin comparison (gratings vs reverse-phi)
%    Fig 10: Polar histograms — condition 1 vs condition 7
%
%  Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 27).
%
%  See also: compute_loop_orientation, find_trajectory_loops

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

key_condition = 1;
sex = 'F';

ASPECT_THRESHOLD = 1.1;  % loops with bbox_aspect below this are too circular

control_strain = "jfrc100_es_shibire_kir";

%% ================================================================
%  SECTION 2: Loop detection + orientation computation (all strains)
%  ================================================================

loop_opts.lookahead_frames = 75;
loop_opts.min_loop_frames  = 10;
loop_opts.fps              = FPS;
loop_opts.arena_center     = ARENA_CENTER;
loop_opts.arena_radius     = ARENA_R;

all_strain_names = fieldnames(DATA);
fprintf('=== Loop orientation analysis across %d strains ===\n', numel(all_strain_names));

% Flat table accumulators
flat_strain      = {};
flat_fly_id      = [];
flat_area        = [];
flat_dist        = [];
flat_aspect      = [];
flat_hdg         = [];
flat_orient      = [];   % absolute orientation angle (deg)
flat_rel         = [];   % orientation relative to radial (deg)
flat_lax_dx      = [];   % long axis direction x
flat_lax_dy      = [];   % long axis direction y
flat_cx          = [];   % loop centroid x
flat_cy          = [];   % loop centroid y
flat_heading_ent = [];   % heading at loop entry (deg, [0,360))

global_fly_counter = 0;

for si = 1:numel(all_strain_names)
    strain = all_strain_names{si};
    if ~isfield(DATA.(strain), sex), continue; end

    data_strain = DATA.(strain).(sex);
    n_exp = length(data_strain);
    rep1_str = strcat('R1_condition_', string(key_condition));
    rep2_str = strcat('R2_condition_', string(key_condition));
    if ~isfield(data_strain, rep1_str), continue; end

    n_loops_strain = 0;

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
            sr_end = min(STIM_OFF, n_frames_avail);
            sr = STIM_ON:sr_end;

            % QC
            vel_rep  = rep_data.vel_data(:, 1:n_frames_avail);
            dist_rep = rep_data.dist_data(:, 1:n_frames_avail);

            for f = 1:n_flies
                % Quiescence and edge-stuck checks
                if sum(vel_rep(f,:) < 0.5) / n_frames_avail > 0.75, continue; end
                if min(dist_rep(f,:)) > 110, continue; end

                global_fly_counter = global_fly_counter + 1;

                x_fly = rep_data.x_data(f, sr);
                y_fly = rep_data.y_data(f, sr);
                h_fly = rep_data.heading_data(f, sr);

                % NaN-mask reversal window in COPIES for loop detection
                x_det = x_fly;  y_det = y_fly;  h_det = h_fly;
                mask_s = max(MASK_START - STIM_ON + 1, 1);
                mask_e = min(MASK_END - STIM_ON + 1, numel(x_fly));
                x_det(mask_s:mask_e) = NaN;
                y_det(mask_s:mask_e) = NaN;
                h_det(mask_s:mask_e) = NaN;

                % Pass velocity for angular diff computation
                v_fly = vel_rep(f, sr);
                v_fly(mask_s:mask_e) = NaN;
                loop_opts.vel = v_fly;

                loops = find_trajectory_loops(x_det, y_det, h_det, loop_opts);
                if loops.n_loops == 0, continue; end

                n_l = loops.n_loops;
                n_loops_strain = n_loops_strain + n_l;

                % Compute orientation for each loop
                orient_ang = NaN(1, n_l);
                rel_ang    = NaN(1, n_l);
                lax_dx     = NaN(1, n_l);
                lax_dy     = NaN(1, n_l);
                cx_arr     = NaN(1, n_l);
                cy_arr     = NaN(1, n_l);
                h_entry    = NaN(1, n_l);

                for k = 1:n_l
                    sf = loops.start_frame(k);
                    ef = loops.end_frame(k);
                    x_seg = x_fly(sf:ef);
                    y_seg = y_fly(sf:ef);

                    if loops.bbox_aspect(k) >= ASPECT_THRESHOLD
                        [oa, ra, lad, mu] = compute_loop_orientation(x_seg, y_seg, ARENA_CENTER);
                        orient_ang(k) = oa;
                        rel_ang(k)    = ra;
                        lax_dx(k)     = lad(1);
                        lax_dy(k)     = lad(2);
                        cx_arr(k)     = mu(1);
                        cy_arr(k)     = mu(2);
                    end

                    % Heading at loop entry (wrapped to [0, 360))
                    h_entry(k) = mod(h_fly(sf), 360);
                end

                flat_strain      = [flat_strain; repmat({strain}, n_l, 1)];
                flat_fly_id      = [flat_fly_id; repmat(global_fly_counter, n_l, 1)];
                flat_area        = [flat_area;       loops.bbox_area(:)];
                flat_dist        = [flat_dist;       loops.bbox_dist_center(:)];
                flat_aspect      = [flat_aspect;     loops.bbox_aspect(:)];
                flat_hdg         = [flat_hdg;        loops.cum_heading(:)];
                flat_orient      = [flat_orient;     orient_ang(:)];
                flat_rel         = [flat_rel;        rel_ang(:)];
                flat_lax_dx      = [flat_lax_dx;     lax_dx(:)];
                flat_lax_dy      = [flat_lax_dy;     lax_dy(:)];
                flat_cx          = [flat_cx;         cx_arr(:)];
                flat_cy          = [flat_cy;         cy_arr(:)];
                flat_heading_ent = [flat_heading_ent; h_entry(:)];
            end
        end
    end

    if n_loops_strain > 0
        n_with_orient = sum(strcmp(flat_strain, strain) & ~isnan(flat_rel));
        fprintf('  %s: %d loops (%d with orientation)\n', strain, n_loops_strain, n_with_orient);
    end
end

n_total = numel(flat_area);
has_orient = ~isnan(flat_rel);
fprintf('\nTotal: %d loops, %d with orientation (aspect >= %.1f)\n', ...
    n_total, sum(has_orient), ASPECT_THRESHOLD);

%% ================================================================
%  SECTION 3: Polar histogram of loop orientations (Figure 1)
%  ================================================================
%
%  Relative angle convention:
%    0°    = loop bulge points radially outward (away from centre)
%    ±180° = loop bulge points radially inward (toward centre)
%    ±90°  = tangential to the arena

% Control strain only for the primary figure
is_ctrl = strcmp(flat_strain, control_strain) & has_orient;

figure('Position', [50 50 600 600], 'Name', 'Fig 1: Polar Orientation (Control)');
polarhistogram(deg2rad(flat_rel(is_ctrl)), 24, ...
    'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'w', 'FaceAlpha', 0.8);
hold on;

% 0° at top = outward (facing the wall), 180° at bottom = inward
pax = gca;
pax.ThetaZeroLocation = 'top';
pax.ThetaDir = 'clockwise';
title(sprintf('Loop orientation relative to radial\n(control, n=%d)', sum(is_ctrl)), ...
    'FontSize', 16);

%% ================================================================
%  SECTION 4: Orientation vs radial position (Figure 2)
%  ================================================================
%
%  Tests whether loop orientation changes with distance from the centre.
%  Binned circular means avoid the CircStat dependency.

ctrl_rel  = flat_rel(is_ctrl);
ctrl_dist = flat_dist(is_ctrl);

bin_edges_rad = linspace(0, ARENA_R, 6);  % 5 bins
bin_centres   = (bin_edges_rad(1:end-1) + bin_edges_rad(2:end)) / 2;
n_bins = numel(bin_centres);

circ_mean_bin = NaN(1, n_bins);
circ_r_bin    = NaN(1, n_bins);
n_per_bin     = zeros(1, n_bins);

for bi = 1:n_bins
    in_bin = ctrl_dist >= bin_edges_rad(bi) & ctrl_dist < bin_edges_rad(bi+1);
    angles = ctrl_rel(in_bin);
    angles = angles(~isnan(angles));
    n_per_bin(bi) = numel(angles);
    if n_per_bin(bi) >= 5
        % Vector mean for circular data
        S = mean(sind(angles));
        C = mean(cosd(angles));
        circ_mean_bin(bi) = atan2d(S, C);
        circ_r_bin(bi) = sqrt(S^2 + C^2);  % resultant length (0-1)
    end
end

figure('Position', [50 50 800 500], 'Name', 'Fig 2: Orientation vs Distance');

subplot(1, 2, 1);
hold on;
scatter(ctrl_dist, ctrl_rel, 8, [0.7 0.7 0.7], 'filled', ...
    'MarkerFaceAlpha', 0.15, 'MarkerEdgeColor', 'none');
plot(bin_centres, circ_mean_bin, '-ok', 'LineWidth', 2, 'MarkerFaceColor', 'k', 'MarkerSize', 6);
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xlabel('Distance from centre (mm)', 'FontSize', 14);
ylabel('Orientation rel. radial (deg)', 'FontSize', 14);
title('Circular mean orientation by distance', 'FontSize', 14);
ylim([-180 180]);
set(gca, 'YTick', -180:90:180);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Resultant length per bin (concentration measure)
subplot(1, 2, 2);
hold on;
bar(bin_centres, circ_r_bin, 0.7, 'FaceColor', [0.216 0.494 0.722], 'EdgeColor', 'none');
for bi = 1:n_bins
    text(bin_centres(bi), circ_r_bin(bi) + 0.02, sprintf('n=%d', n_per_bin(bi)), ...
        'HorizontalAlignment', 'center', 'FontSize', 9);
end
xlabel('Distance from centre (mm)', 'FontSize', 14);
ylabel('Resultant length (r)', 'FontSize', 14);
title('Concentration of orientation by distance', 'FontSize', 14);
ylim([0 max(circ_r_bin(~isnan(circ_r_bin))) * 1.3 + 0.01]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

%% ================================================================
%  SECTION 5: Orientation vs heading at loop entry (Figure 3)
%  ================================================================
%
%  If this clusters near 0°, the loop's long axis is aligned with the
%  fly's heading at entry (the fly turns back on itself). If near ±180°,
%  the bulge points opposite to the entry heading.

ctrl_orient  = flat_orient(is_ctrl);
ctrl_h_entry = flat_heading_ent(is_ctrl);

% Difference between loop orientation and entry heading
orient_vs_heading = mod(ctrl_orient - ctrl_h_entry + 180, 360) - 180;

figure('Position', [50 50 600 600], 'Name', 'Fig 3: Orientation vs Entry Heading');
polarhistogram(deg2rad(orient_vs_heading(~isnan(orient_vs_heading))), 24, ...
    'FaceColor', [0.216 0.494 0.722], 'EdgeColor', 'w', 'FaceAlpha', 0.7);
pax3 = gca; pax3.ThetaZeroLocation = 'top'; pax3.ThetaDir = 'clockwise';
title(sprintf('Loop orientation relative to entry heading\n(0° = aligned, 180° = opposite)'), ...
    'FontSize', 14);

%% ================================================================
%  SECTION 6: Spatial quiver plot (Figure 4)
%  ================================================================
%
%  Arrows at each loop's centroid show the orientation direction.
%  Colour-coded by relative angle: red = outward, blue = inward.

figure('Position', [50 50 700 700], 'Name', 'Fig 4: Spatial Quiver');
hold on;

% Arena circle
theta = linspace(0, 2*pi, 200);
plot(ARENA_CENTER(1) + ARENA_R*cos(theta), ...
     ARENA_CENTER(2) + ARENA_R*sin(theta), '-', ...
     'Color', [0.7 0.7 0.7], 'LineWidth', 1);

% Arrows for control strain only
idx_q = find(is_ctrl & ~isnan(flat_cx));
arrow_len = 4;  % mm visual length

for qi = 1:numel(idx_q)
    ii = idx_q(qi);
    % Colour: red (outward, |rel| near 0) → blue (inward, |rel| near 180)
    t = abs(flat_rel(ii)) / 180;
    col = (1-t) * [0.8 0.15 0.15] + t * [0.15 0.3 0.7];

    quiver(flat_cx(ii), flat_cy(ii), ...
        flat_lax_dx(ii) * arrow_len, flat_lax_dy(ii) * arrow_len, 0, ...
        'Color', col, 'LineWidth', 1, 'MaxHeadSize', 1.5);
end

axis equal;
xlim([ARENA_CENTER(1)-ARENA_R-5, ARENA_CENTER(1)+ARENA_R+5]);
ylim([ARENA_CENTER(2)-ARENA_R-5, ARENA_CENTER(2)+ARENA_R+5]);
xlabel('x (mm)', 'FontSize', 14);
ylabel('y (mm)', 'FontSize', 14);
title('Loop orientations on arena (red=outward, blue=inward)', 'FontSize', 14);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Colorbar
colormap(interp1([0; 1], [0.8 0.15 0.15; 0.15 0.3 0.7], linspace(0,1,256)));
cb = colorbar;
cb.Label.String = '|Rel. angle| (0°=out, 180°=in)';
cb.Label.FontSize = 12;
clim([0 180]);

%% ================================================================
%  SECTION 7: CW vs CCW split (Figure 5)
%  ================================================================

is_cw_ctrl  = is_ctrl & flat_hdg < 0;
is_ccw_ctrl = is_ctrl & flat_hdg > 0;

figure('Position', [50 50 1100 500], 'Name', 'Fig 5: CW vs CCW');
sgtitle('Loop orientation by turning direction', 'FontSize', 18);

subplot(1, 2, 1);
polarhistogram(deg2rad(flat_rel(is_cw_ctrl & ~isnan(flat_rel))), 24, ...
    'FaceColor', [0.216 0.494 0.722], 'EdgeColor', 'w', 'FaceAlpha', 0.7);
pax5a = gca; pax5a.ThetaZeroLocation = 'top'; pax5a.ThetaDir = 'clockwise';
title(sprintf('CW loops (n=%d)', sum(is_cw_ctrl & ~isnan(flat_rel))), 'FontSize', 14);

subplot(1, 2, 2);
polarhistogram(deg2rad(flat_rel(is_ccw_ctrl & ~isnan(flat_rel))), 24, ...
    'FaceColor', [0.894 0.102 0.110], 'EdgeColor', 'w', 'FaceAlpha', 0.7);
pax5b = gca; pax5b.ThetaZeroLocation = 'top'; pax5b.ThetaDir = 'clockwise';
title(sprintf('CCW loops (n=%d)', sum(is_ccw_ctrl & ~isnan(flat_rel))), 'FontSize', 14);

%% ================================================================
%  SECTION 8: Rose plots by radial zone (Figure 6)
%  ================================================================

zone_edges  = [0 40 80 120];
zone_labels = {'Inner (0-40 mm)', 'Middle (40-80 mm)', 'Outer (80-120 mm)'};
zone_colors = [0.75 0.85 0.95; 0.40 0.58 0.78; 0.10 0.25 0.54];

figure('Position', [50 50 1400 450], 'Name', 'Fig 6: Orientation by Zone');
sgtitle('Loop orientation by radial zone (control)', 'FontSize', 18);

for zi = 1:3
    subplot(1, 3, zi);
    in_zone = is_ctrl & flat_dist >= zone_edges(zi) & flat_dist < zone_edges(zi+1);
    angles_z = flat_rel(in_zone & ~isnan(flat_rel));
    polarhistogram(deg2rad(angles_z), 24, ...
        'FaceColor', zone_colors(zi,:), 'EdgeColor', 'w', 'FaceAlpha', 0.7);
    pax_z = gca; pax_z.ThetaZeroLocation = 'top'; pax_z.ThetaDir = 'clockwise';
    title(sprintf('%s\n(n=%d)', zone_labels{zi}, numel(angles_z)), 'FontSize', 13);
end

%% ================================================================
%  SECTION 9: Per-strain polar histograms (Figure 7)
%  ================================================================

unique_strains = unique(flat_strain);
is_ctrl_strain = strcmp(unique_strains, control_strain);
strain_order = [unique_strains(is_ctrl_strain); unique_strains(~is_ctrl_strain)];
n_strains = numel(strain_order);

n_cols = ceil(sqrt(n_strains));
n_rows = ceil(n_strains / n_cols);

strain_palette = [
    0.7   0.7   0.7;     % control (grey)
    0.216 0.494 0.722;   0.894 0.102 0.110;   0.302 0.686 0.290;
    0.596 0.306 0.639;   1.000 0.498 0.000;   0.651 0.337 0.157;
    0.122 0.694 0.827;   0.890 0.467 0.761;   0.737 0.741 0.133;
    0.090 0.745 0.812;   0.682 0.780 0.910;   0.400 0.761 0.647;
    0.988 0.553 0.384;   0.553 0.627 0.796;   0.906 0.541 0.765;
    0.651 0.847 0.329;   0.463 0.380 0.482;   0.361 0.729 0.510];

figure('Position', [30 30 n_cols*280, n_rows*280], 'Name', 'Fig 7: Per-Strain Orientations');
sgtitle('Loop orientation by strain', 'FontSize', 18);

colour_idx = 0;
for si = 1:n_strains
    s_name = strain_order{si};
    idx_s = strcmp(flat_strain, s_name) & has_orient;
    angles_s = flat_rel(idx_s);

    if strcmp(s_name, control_strain)
        col = strain_palette(1, :);
    else
        colour_idx = colour_idx + 1;
        col = strain_palette(mod(colour_idx, size(strain_palette,1)-1) + 2, :);
    end

    subplot(n_rows, n_cols, si);
    if sum(~isnan(angles_s)) > 0
        polarhistogram(deg2rad(angles_s(~isnan(angles_s))), 24, ...
            'FaceColor', col, 'EdgeColor', 'w', 'FaceAlpha', 0.7);
    end
    pax_si = gca; pax_si.ThetaZeroLocation = 'top'; pax_si.ThetaDir = 'clockwise';
    display_name = strrep(strrep(s_name, '_shibire_kir', ''), '_', '\_');
    title(sprintf('%s (n=%d)', display_name, sum(~isnan(angles_s))), 'FontSize', 9);
end

%% ================================================================
%  SECTION 10: Cosine and sine decomposition vs distance (Figs 8-9)
%  ================================================================
%
%  Decomposing the relative angle into cos and sin components lets us
%  quantify the radial and tangential biases separately:
%
%    cos(rel_angle) = RADIAL component
%      +1 = pointing outward (away from centre)
%      -1 = pointing inward (toward centre)
%       0 = purely tangential
%
%    sin(rel_angle) = TANGENTIAL component
%      +1 = tangential clockwise around the arena
%      -1 = tangential anticlockwise
%       0 = purely radial
%
%  Plotting these against distance from the arena centre reveals whether
%  the radial or tangential bias changes with position.

ctrl_cos = cosd(flat_rel(is_ctrl));
ctrl_sin = sind(flat_rel(is_ctrl));
ctrl_d   = flat_dist(is_ctrl);

% --- Figure 8: cos(rel_angle) vs distance --- radial component ---
figure('Position', [50 50 1200 500], 'Name', 'Fig 8: Cos/Sin vs Distance (Control)');
sgtitle('Loop orientation decomposition vs distance (control)', 'FontSize', 18);

subplot(1, 2, 1);
hold on;
scatter(ctrl_d, ctrl_cos, 8, [0.7 0.7 0.7], 'filled', ...
    'MarkerFaceAlpha', 0.1, 'MarkerEdgeColor', 'none');

% Binned means
n_dist_bins = 10;
bin_edges_cs = linspace(0, ARENA_R, n_dist_bins + 1);
bin_centres_cs = (bin_edges_cs(1:end-1) + bin_edges_cs(2:end)) / 2;
cos_bin_mean = NaN(1, n_dist_bins);
cos_bin_sem  = NaN(1, n_dist_bins);
sin_bin_mean = NaN(1, n_dist_bins);
sin_bin_sem  = NaN(1, n_dist_bins);

for bi = 1:n_dist_bins
    in_b = ctrl_d >= bin_edges_cs(bi) & ctrl_d < bin_edges_cs(bi+1) & ~isnan(ctrl_cos);
    if sum(in_b) >= 5
        cos_bin_mean(bi) = mean(ctrl_cos(in_b));
        cos_bin_sem(bi)  = std(ctrl_cos(in_b)) / sqrt(sum(in_b));
        sin_bin_mean(bi) = mean(ctrl_sin(in_b));
        sin_bin_sem(bi)  = std(ctrl_sin(in_b)) / sqrt(sum(in_b));
    end
end

errorbar(bin_centres_cs, cos_bin_mean, cos_bin_sem, '-ok', 'LineWidth', 2, ...
    'MarkerFaceColor', 'k', 'MarkerSize', 6, 'CapSize', 4);
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xlabel('Distance from centre (mm)', 'FontSize', 14);
ylabel('cos(rel angle) — radial component', 'FontSize', 14);
title('Radial bias (+1=outward, -1=inward)', 'FontSize', 14);
ylim([-1 1]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% --- sin(rel_angle) vs distance --- tangential component ---
subplot(1, 2, 2);
hold on;
scatter(ctrl_d, ctrl_sin, 8, [0.7 0.7 0.7], 'filled', ...
    'MarkerFaceAlpha', 0.1, 'MarkerEdgeColor', 'none');
errorbar(bin_centres_cs, sin_bin_mean, sin_bin_sem, '-ok', 'LineWidth', 2, ...
    'MarkerFaceColor', 'k', 'MarkerSize', 6, 'CapSize', 4);
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xlabel('Distance from centre (mm)', 'FontSize', 14);
ylabel('sin(rel angle) — tangential component', 'FontSize', 14);
title('Tangential bias (+1=CW, -1=CCW)', 'FontSize', 14);
ylim([-1 1]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Print cos/sin results
fprintf('\n--- Fig 8: Cos/sin decomposition by distance (control) ---\n');
fprintf('  %-12s %-6s %-10s %-10s %-10s %-10s\n', ...
    'Bin', 'n', 'mean(cos)', 'SEM(cos)', 'mean(sin)', 'SEM(sin)');
for bi = 1:n_dist_bins
    in_b = ctrl_d >= bin_edges_cs(bi) & ctrl_d < bin_edges_cs(bi+1) & ~isnan(ctrl_cos);
    if sum(in_b) >= 5
        fprintf('  %-12s %-6d %-+10.3f %-10.3f %-+10.3f %-10.3f\n', ...
            sprintf('%.0f-%.0f mm', bin_edges_cs(bi), bin_edges_cs(bi+1)), ...
            sum(in_b), cos_bin_mean(bi), cos_bin_sem(bi), sin_bin_mean(bi), sin_bin_sem(bi));
    end
end
fprintf('\n  Overall: mean(cos)=%.3f (outward bias), mean(sin)=%.3f (tangential bias)\n', ...
    mean(ctrl_cos, 'omitnan'), mean(ctrl_sin, 'omitnan'));

%% ================================================================
%  SECTION 11: Condition 7 (reverse-phi) comparison (Figs 9-10)
%  ================================================================
%
%  Condition 7 is a reverse-phi stimulus: flies turn but do NOT centre.
%  Comparing the loop orientation between condition 1 (standard gratings,
%  flies centre) and condition 7 (reverse-phi, flies do not centre) tests
%  whether the outward loop bias is specific to centring behaviour or a
%  general feature of optomotor turning.
%
%  If the radial bias (cos component) is similar in both conditions, the
%  loop geometry is a general consequence of turning near the wall.
%  If it differs, the centring behaviour shapes the loop orientation.

cond7 = 7;
fprintf('\n=== Condition 7 (reverse-phi) loop detection ===\n');

% Detect loops for condition 7 using the same pipeline
flat_rel_c7   = [];
flat_dist_c7  = [];
flat_cos_c7   = [];
flat_sin_c7   = [];
n_loops_c7    = 0;

for si = 1:numel(all_strain_names)
    strain = all_strain_names{si};
    if ~strcmp(strain, control_strain), continue; end  % control only
    if ~isfield(DATA.(strain), sex), continue; end

    data_strain = DATA.(strain).(sex);
    n_exp = length(data_strain);
    rep1_str_c7 = strcat('R1_condition_', string(cond7));
    rep2_str_c7 = strcat('R2_condition_', string(cond7));
    if ~isfield(data_strain, rep1_str_c7), continue; end

    for exp_idx = 1:n_exp
        for rep_idx = 1:2
            if rep_idx == 1
                rep_data = data_strain(exp_idx).(rep1_str_c7);
            else
                rep_data = data_strain(exp_idx).(rep2_str_c7);
            end
            if isempty(rep_data), continue; end

            n_flies = size(rep_data.x_data, 1);
            n_frames_avail = size(rep_data.x_data, 2);
            sr_end = min(STIM_OFF, n_frames_avail);
            sr = STIM_ON:sr_end;

            vel_rep  = rep_data.vel_data(:, 1:n_frames_avail);
            dist_rep = rep_data.dist_data(:, 1:n_frames_avail);

            for f = 1:n_flies
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
                loop_opts.vel = v_fly;

                loops = find_trajectory_loops(x_det, y_det, h_det, loop_opts);
                if loops.n_loops == 0, continue; end

                for k = 1:loops.n_loops
                    if loops.bbox_aspect(k) < ASPECT_THRESHOLD, continue; end

                    sf = loops.start_frame(k);
                    ef = loops.end_frame(k);
                    [~, ra, ~, ~] = compute_loop_orientation(x_fly(sf:ef), y_fly(sf:ef), ARENA_CENTER);

                    if ~isnan(ra)
                        flat_rel_c7  = [flat_rel_c7;  ra];
                        flat_dist_c7 = [flat_dist_c7; loops.bbox_dist_center(k)];
                        flat_cos_c7  = [flat_cos_c7;  cosd(ra)];
                        flat_sin_c7  = [flat_sin_c7;  sind(ra)];
                        n_loops_c7   = n_loops_c7 + 1;
                    end
                end
            end
        end
    end
end

fprintf('  Condition 7: %d loops with orientation\n', n_loops_c7);

% --- Figure 9: Condition 1 vs 7 cos(rel_angle) vs distance ---
figure('Position', [50 50 1200 500], ...
    'Name', 'Fig 9: Radial bias — Cond 1 (gratings) vs Cond 7 (reverse-phi)');
sgtitle('Radial bias: standard gratings (centres) vs reverse-phi (no centring)', 'FontSize', 16);

% Bin condition 7
cos_bin_c7 = NaN(1, n_dist_bins);
cos_sem_c7 = NaN(1, n_dist_bins);
sin_bin_c7 = NaN(1, n_dist_bins);
sin_sem_c7 = NaN(1, n_dist_bins);

for bi = 1:n_dist_bins
    in_b = flat_dist_c7 >= bin_edges_cs(bi) & flat_dist_c7 < bin_edges_cs(bi+1);
    if sum(in_b) >= 5
        cos_bin_c7(bi) = mean(flat_cos_c7(in_b));
        cos_sem_c7(bi) = std(flat_cos_c7(in_b)) / sqrt(sum(in_b));
        sin_bin_c7(bi) = mean(flat_sin_c7(in_b));
        sin_sem_c7(bi) = std(flat_sin_c7(in_b)) / sqrt(sum(in_b));
    end
end

subplot(1, 2, 1);
hold on;
errorbar(bin_centres_cs, cos_bin_mean, cos_bin_sem, '-o', 'Color', [0.1 0.1 0.1], ...
    'LineWidth', 2, 'MarkerFaceColor', [0.1 0.1 0.1], 'MarkerSize', 6, 'CapSize', 4);
errorbar(bin_centres_cs, cos_bin_c7, cos_sem_c7, '-s', 'Color', [0.894 0.102 0.110], ...
    'LineWidth', 2, 'MarkerFaceColor', [0.894 0.102 0.110], 'MarkerSize', 6, 'CapSize', 4);
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xlabel('Distance from centre (mm)', 'FontSize', 14);
ylabel('cos(rel angle) — radial component', 'FontSize', 14);
title('Radial bias (+1=outward, -1=inward)', 'FontSize', 14);
legend('Cond 1 (gratings)', 'Cond 7 (reverse-phi)', 'Location', 'best');
ylim([-0.5 1]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

subplot(1, 2, 2);
hold on;
errorbar(bin_centres_cs, sin_bin_mean, sin_bin_sem, '-o', 'Color', [0.1 0.1 0.1], ...
    'LineWidth', 2, 'MarkerFaceColor', [0.1 0.1 0.1], 'MarkerSize', 6, 'CapSize', 4);
errorbar(bin_centres_cs, sin_bin_c7, sin_sem_c7, '-s', 'Color', [0.894 0.102 0.110], ...
    'LineWidth', 2, 'MarkerFaceColor', [0.894 0.102 0.110], 'MarkerSize', 6, 'CapSize', 4);
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xlabel('Distance from centre (mm)', 'FontSize', 14);
ylabel('sin(rel angle) — tangential component', 'FontSize', 14);
title('Tangential bias', 'FontSize', 14);
legend('Cond 1 (gratings)', 'Cond 7 (reverse-phi)', 'Location', 'best');
ylim([-0.5 0.5]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% --- Figure 10: Polar histograms side by side ---
figure('Position', [50 50 1100 500], ...
    'Name', 'Fig 10: Polar — Cond 1 vs Cond 7');
sgtitle('Loop orientation: gratings (centres) vs reverse-phi (no centring)', 'FontSize', 16);

subplot(1, 2, 1);
polarhistogram(deg2rad(flat_rel(is_ctrl)), 24, ...
    'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'w', 'FaceAlpha', 0.8);
pax_c1 = gca; pax_c1.ThetaZeroLocation = 'top'; pax_c1.ThetaDir = 'clockwise';
title(sprintf('Cond 1 — standard gratings\n(n=%d, centres)', sum(is_ctrl)), 'FontSize', 13);

subplot(1, 2, 2);
polarhistogram(deg2rad(flat_rel_c7), 24, ...
    'FaceColor', [0.894 0.102 0.110], 'EdgeColor', 'w', 'FaceAlpha', 0.7);
pax_c7 = gca; pax_c7.ThetaZeroLocation = 'top'; pax_c7.ThetaDir = 'clockwise';
title(sprintf('Cond 7 — reverse-phi\n(n=%d, no centring)', n_loops_c7), 'FontSize', 13);

% --- Print condition 7 results ---
fprintf('\n--- Condition 7 (reverse-phi) orientation results ---\n');
S_c7 = mean(sind(flat_rel_c7), 'omitnan');
C_c7 = mean(cosd(flat_rel_c7), 'omitnan');
mean_rel_c7 = atan2d(S_c7, C_c7);
r_c7 = sqrt(S_c7^2 + C_c7^2);
fprintf('  n loops: %d\n', n_loops_c7);
fprintf('  Circular mean: %.1f°\n', mean_rel_c7);
fprintf('  Resultant length: %.3f\n', r_c7);
fprintf('  mean(cos): %.3f (radial bias, +ve=outward)\n', mean(flat_cos_c7, 'omitnan'));
fprintf('  mean(sin): %.3f (tangential bias)\n', mean(flat_sin_c7, 'omitnan'));
fprintf('  Fraction inward (|angle| > 90°): %.1f%%\n', ...
    100 * sum(abs(flat_rel_c7) > 90) / numel(flat_rel_c7));

fprintf('\n--- Condition 1 vs 7 comparison ---\n');
fprintf('  %-25s %-12s %-12s\n', '', 'Cond 1', 'Cond 7');
fprintf('  %-25s %-12d %-12d\n', 'n loops', sum(is_ctrl), n_loops_c7);
fprintf('  %-25s %-+12.3f %-+12.3f\n', 'mean(cos) [radial]', ...
    mean(ctrl_cos, 'omitnan'), mean(flat_cos_c7, 'omitnan'));
fprintf('  %-25s %-+12.3f %-+12.3f\n', 'mean(sin) [tangential]', ...
    mean(ctrl_sin, 'omitnan'), mean(flat_sin_c7, 'omitnan'));
fprintf('  %-25s %-12.1f %-12.1f\n', 'circ mean (deg)', mean_rel_all, mean_rel_c7);
fprintf('  %-25s %-12.3f %-12.3f\n', 'resultant length (r)', r_all, r_c7);
fprintf('  %-25s %-12.1f %-12.1f\n', '%% inward', ...
    100*sum(abs(ctrl_angles)>90)/sum(~isnan(ctrl_angles)), ...
    100*sum(abs(flat_rel_c7)>90)/numel(flat_rel_c7));

% Wilcoxon rank-sum test on cos values (radial bias)
[p_cos, ~] = ranksum(ctrl_cos(~isnan(ctrl_cos)), flat_cos_c7(~isnan(flat_cos_c7)));
% Wilcoxon rank-sum test on sin values (tangential bias)
[p_sin, ~] = ranksum(ctrl_sin(~isnan(ctrl_sin)), flat_sin_c7(~isnan(flat_sin_c7)));
fprintf('\n  Wilcoxon rank-sum (Cond 1 vs 7):\n');
fprintf('    cos (radial bias):     p = %.3e\n', p_cos);
fprintf('    sin (tangential bias): p = %.3e\n', p_sin);
fprintf('    (p < 0.05 means the conditions differ in that component)\n');

% Binned comparison table
fprintf('\n--- Binned cos (radial bias) comparison ---\n');
fprintf('  %-12s %-6s %-10s %-6s %-10s\n', 'Bin', 'n(C1)', 'cos(C1)', 'n(C7)', 'cos(C7)');
for bi = 1:n_dist_bins
    in_b1 = ctrl_d >= bin_edges_cs(bi) & ctrl_d < bin_edges_cs(bi+1) & ~isnan(ctrl_cos);
    in_b7 = flat_dist_c7 >= bin_edges_cs(bi) & flat_dist_c7 < bin_edges_cs(bi+1);
    n1 = sum(in_b1); n7 = sum(in_b7);
    c1 = cos_bin_mean(bi); c7 = cos_bin_c7(bi);
    if n1 >= 5 || n7 >= 5
        fprintf('  %-12s %-6d %-+10.3f %-6d %-+10.3f\n', ...
            sprintf('%.0f-%.0f mm', bin_edges_cs(bi), bin_edges_cs(bi+1)), ...
            n1, c1, n7, c7);
    end
end

%% ================================================================
%  RESULTS SUMMARY
%  ================================================================

fprintf('\n======================================================================\n');
fprintf('  LOOP ORIENTATION ANALYSIS — RESULTS\n');
fprintf('======================================================================\n');

fprintf('\n--- Data summary ---\n');
fprintf('  Total loops across all strains: %d\n', n_total);
fprintf('  Loops with orientation (aspect >= %.1f): %d (%.0f%%)\n', ...
    ASPECT_THRESHOLD, sum(has_orient), 100*sum(has_orient)/n_total);
fprintf('  Control strain (%s): %d loops with orientation\n', ...
    control_strain, sum(is_ctrl));

% --- Control: overall orientation distribution ---
ctrl_angles = flat_rel(is_ctrl);
S_all = mean(sind(ctrl_angles), 'omitnan');
C_all = mean(cosd(ctrl_angles), 'omitnan');
mean_rel_all = atan2d(S_all, C_all);
r_all = sqrt(S_all^2 + C_all^2);

fprintf('\n--- Fig 1: Overall orientation (control, relative to radial) ---\n');
fprintf('  Convention: 0° = outward (toward wall), ±180° = inward (toward centre)\n');
fprintf('  Circular mean: %.1f°\n', mean_rel_all);
fprintf('  Resultant length (r): %.3f  (0=uniform, 1=perfectly aligned)\n', r_all);
fprintf('  Median: %.1f°\n', median(ctrl_angles, 'omitnan'));
fprintf('  Fraction pointing inward (|angle| > 90°): %.1f%%\n', ...
    100 * sum(abs(ctrl_angles) > 90) / sum(~isnan(ctrl_angles)));
fprintf('  Fraction pointing outward (|angle| <= 90°): %.1f%%\n', ...
    100 * sum(abs(ctrl_angles) <= 90) / sum(~isnan(ctrl_angles)));

% Rayleigh test for non-uniformity (tests if distribution is significantly
% non-uniform, i.e. loops have a preferred direction)
n_orient = sum(~isnan(ctrl_angles));
R = r_all * n_orient;  % resultant length * n
p_rayleigh = exp(-R^2 / n_orient) * (1 + (2*R^2 - R^4) / (4*n_orient) ...
    - (24*R^2 - 132*R^4 + 76*R^6 - 9*R^8) / (288*n_orient^2));
fprintf('  Rayleigh test (H0: uniform): R=%.1f, p=%.3e\n', R, p_rayleigh);
fprintf('  (p < 0.05 means loops have a significantly preferred orientation)\n');

% --- Per-zone breakdown ---
fprintf('\n--- Fig 6: Orientation by radial zone (control) ---\n');
for zi = 1:3
    in_zone = is_ctrl & flat_dist >= zone_edges(zi) & flat_dist < zone_edges(zi+1);
    az = flat_rel(in_zone & ~isnan(flat_rel));
    n_z = numel(az);
    if n_z >= 3
        S_z = mean(sind(az));
        C_z = mean(cosd(az));
        mean_z = atan2d(S_z, C_z);
        r_z = sqrt(S_z^2 + C_z^2);
        pct_inward = 100 * sum(abs(az) > 90) / n_z;
        fprintf('  %s: n=%d, circ mean=%.1f°, r=%.3f, %.0f%% inward\n', ...
            zone_labels{zi}, n_z, mean_z, r_z, pct_inward);
    else
        fprintf('  %s: n=%d (too few for stats)\n', zone_labels{zi}, n_z);
    end
end

% --- Orientation vs heading at entry ---
ovh = orient_vs_heading(~isnan(orient_vs_heading));
S_h = mean(sind(ovh));
C_h = mean(cosd(ovh));
mean_ovh = atan2d(S_h, C_h);
r_ovh = sqrt(S_h^2 + C_h^2);

fprintf('\n--- Fig 3: Orientation vs entry heading (control) ---\n');
fprintf('  Convention: 0° = loop axis aligned with entry heading\n');
fprintf('  Circular mean: %.1f°\n', mean_ovh);
fprintf('  Resultant length: %.3f\n', r_ovh);
fprintf('  Fraction within ±45° of entry heading: %.1f%%\n', ...
    100 * sum(abs(ovh) <= 45) / numel(ovh));
fprintf('  Fraction opposite (|diff| > 135°): %.1f%%\n', ...
    100 * sum(abs(ovh) > 135) / numel(ovh));

% --- CW vs CCW ---
cw_angles  = flat_rel(is_cw_ctrl & ~isnan(flat_rel));
ccw_angles = flat_rel(is_ccw_ctrl & ~isnan(flat_rel));

fprintf('\n--- Fig 5: CW vs CCW orientation (control) ---\n');
if numel(cw_angles) >= 3
    fprintf('  CW loops (n=%d):  circ mean=%.1f°, r=%.3f, %.0f%% inward\n', ...
        numel(cw_angles), atan2d(mean(sind(cw_angles)), mean(cosd(cw_angles))), ...
        sqrt(mean(sind(cw_angles))^2 + mean(cosd(cw_angles))^2), ...
        100*sum(abs(cw_angles) > 90)/numel(cw_angles));
end
if numel(ccw_angles) >= 3
    fprintf('  CCW loops (n=%d): circ mean=%.1f°, r=%.3f, %.0f%% inward\n', ...
        numel(ccw_angles), atan2d(mean(sind(ccw_angles)), mean(cosd(ccw_angles))), ...
        sqrt(mean(sind(ccw_angles))^2 + mean(cosd(ccw_angles))^2), ...
        100*sum(abs(ccw_angles) > 90)/numel(ccw_angles));
end

% --- Binned orientation vs distance ---
fprintf('\n--- Fig 2: Binned circular mean orientation by distance (control) ---\n');
fprintf('  %-20s %-8s %-12s %-8s %-10s\n', 'Bin', 'n', 'Circ mean', 'r', '%% inward');
for bi = 1:n_bins
    in_bin = ctrl_dist >= bin_edges_rad(bi) & ctrl_dist < bin_edges_rad(bi+1);
    az = ctrl_rel(in_bin & ~isnan(ctrl_rel));
    if numel(az) >= 3
        fprintf('  %-20s %-8d %-12.1f %-8.3f %-10.0f\n', ...
            sprintf('%.0f-%.0f mm', bin_edges_rad(bi), bin_edges_rad(bi+1)), ...
            numel(az), circ_mean_bin(bi), circ_r_bin(bi), ...
            100*sum(abs(az) > 90)/numel(az));
    end
end

fprintf('\n======================================================================\n');
fprintf('  10 figures generated\n');
fprintf('======================================================================\n');
