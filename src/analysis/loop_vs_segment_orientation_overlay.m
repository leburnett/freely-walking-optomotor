%% LOOP_VS_SEGMENT_ORIENTATION_OVERLAY - Overlaid loop and inter-loop orientation
%
%  Generates two figures comparing the orientation of loops (PCA long axis)
%  with the direction of inter-loop segments (start→end displacement),
%  both relative to the radial direction from the arena centre.
%
%  FIGURES:
%    Fig 1: Overlaid polar histogram (normalised to proportion)
%    Fig 2: Radial and tangential bias vs distance from centre (cos/sin)
%
%  Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 27).
%
%  See also: compute_loop_orientation, find_trajectory_loops

%% Setup

if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

ARENA_CENTER = [528, 520] / 4.1691;
ARENA_R = 120;
FPS = 30;
STIM_ON = 300;  STIM_OFF = 1200;
MASK_START = 750;  MASK_END = 850;

sex = 'F';
control_strain = "jfrc100_es_shibire_kir";
ASPECT_THRESHOLD = 1.1;
MIN_SEG_FRAMES = 5;

loop_opts.lookahead_frames = 75;
loop_opts.min_loop_frames  = 10;
loop_opts.fps              = FPS;
loop_opts.arena_center     = ARENA_CENTER;
loop_opts.arena_radius     = ARENA_R;

%% Extract loop orientations and inter-loop segment directions

fprintf('=== Extracting loop and inter-loop segment orientations (control, cond 1) ===\n');

loop_rel   = [];   % relative angle for loops
loop_dist  = [];   % distance from centre for loops
seg_rel    = [];   % relative angle for inter-loop segments
seg_dist   = [];   % distance from centre for segments

data_strain = DATA.(control_strain).(sex);
n_exp = length(data_strain);
rep1_str = strcat('R1_condition_', string(1));
rep2_str = strcat('R2_condition_', string(1));

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

            % --- Loop orientations ---
            for k = 1:loops.n_loops
                if loops.bbox_aspect(k) < ASPECT_THRESHOLD, continue; end
                sf = loops.start_frame(k);
                ef = loops.end_frame(k);
                [~, ra, ~, ~] = compute_loop_orientation(x_fly(sf:ef), y_fly(sf:ef), ARENA_CENTER);
                if ~isnan(ra)
                    loop_rel  = [loop_rel, ra];
                    loop_dist = [loop_dist, loops.bbox_dist_center(k)];
                end
            end

            % --- Inter-loop segments ---
            for k = 1:(loops.n_loops - 1)
                s_start = loops.end_frame(k) + 1;
                s_end   = loops.start_frame(k+1) - 1;
                if s_end - s_start + 1 < MIN_SEG_FRAMES, continue; end

                x_s = x_fly(s_start:s_end);
                y_s = y_fly(s_start:s_end);
                valid = ~isnan(x_s) & ~isnan(y_s);
                x_v = x_s(valid);  y_v = y_s(valid);
                if numel(x_v) < MIN_SEG_FRAMES, continue; end

                dx = x_v(end) - x_v(1);
                dy = y_v(end) - y_v(1);
                seg_len = sqrt(dx^2 + dy^2);
                if seg_len < 0.5, continue; end

                dir_ang = atan2d(dy, dx);
                mx = (x_v(1) + x_v(end)) / 2;
                my = (y_v(1) + y_v(end)) / 2;
                d_center = sqrt((mx - ARENA_CENTER(1))^2 + (my - ARENA_CENTER(2))^2);
                radial_ang = atan2d(my - ARENA_CENTER(2), mx - ARENA_CENTER(1));
                rel = mod(dir_ang - radial_ang + 180, 360) - 180;

                seg_rel  = [seg_rel, rel];
                seg_dist = [seg_dist, d_center];
            end
        end
    end
end

fprintf('  Loops with orientation: %d\n', numel(loop_rel));
fprintf('  Inter-loop segments:    %d\n', numel(seg_rel));

%% ================================================================
%  Figure 1: Overlaid polar histograms
%  ================================================================

% Colours
col_loop = [0.6 0.6 0.6];          % grey for loops
col_seg  = [0.133 0.545 0.133];    % forest green for segments

figure('Position', [50 50 650 650], ...
    'Name', 'Fig 1: Loop vs Segment Orientation (Polar)');

% Loops — grey filled
h1 = polarhistogram(deg2rad(loop_rel), 36, ...
    'FaceColor', col_loop, 'EdgeColor', 'w', 'FaceAlpha', 0.5);
hold on;

% Inter-loop segments — forest green, semi-transparent
h2 = polarhistogram(deg2rad(seg_rel), 36, ...
    'FaceColor', col_seg, 'EdgeColor', 'w', 'FaceAlpha', 0.5);

pax = gca;
pax.ThetaZeroLocation = 'top';
pax.ThetaDir = 'clockwise';

title(sprintf(['Loop orientation (grey, n=%d) vs' newline ...
    'inter-loop segment direction (green, n=%d)'], ...
    numel(loop_rel), numel(seg_rel)), 'FontSize', 14);

legend([h1, h2], 'Loops', 'Inter-loop segments', ...
    'Location', 'southoutside', 'FontSize', 11);

%% ================================================================
%  Figure 2: Radial and tangential bias vs distance
%  ================================================================

loop_cos = cosd(loop_rel);
loop_sin = sind(loop_rel);
seg_cos  = cosd(seg_rel);
seg_sin  = sind(seg_rel);

n_dist_bins = 10;
bin_edges_d = linspace(0, ARENA_R, n_dist_bins + 1);
bin_centres_d = (bin_edges_d(1:end-1) + bin_edges_d(2:end)) / 2;

% Bin loops
cos_bin_l = NaN(1, n_dist_bins);  cos_sem_l = NaN(1, n_dist_bins);
sin_bin_l = NaN(1, n_dist_bins);  sin_sem_l = NaN(1, n_dist_bins);
% Bin segments
cos_bin_s = NaN(1, n_dist_bins);  cos_sem_s = NaN(1, n_dist_bins);
sin_bin_s = NaN(1, n_dist_bins);  sin_sem_s = NaN(1, n_dist_bins);

for bi = 1:n_dist_bins
    % Loops
    in_l = loop_dist >= bin_edges_d(bi) & loop_dist < bin_edges_d(bi+1);
    if sum(in_l) >= 5
        cos_bin_l(bi) = mean(loop_cos(in_l));
        cos_sem_l(bi) = std(loop_cos(in_l)) / sqrt(sum(in_l));
        sin_bin_l(bi) = mean(loop_sin(in_l));
        sin_sem_l(bi) = std(loop_sin(in_l)) / sqrt(sum(in_l));
    end
    % Segments
    in_s = seg_dist >= bin_edges_d(bi) & seg_dist < bin_edges_d(bi+1);
    if sum(in_s) >= 5
        cos_bin_s(bi) = mean(seg_cos(in_s));
        cos_sem_s(bi) = std(seg_cos(in_s)) / sqrt(sum(in_s));
        sin_bin_s(bi) = mean(seg_sin(in_s));
        sin_sem_s(bi) = std(seg_sin(in_s)) / sqrt(sum(in_s));
    end
end

figure('Position', [50 50 1200 500], ...
    'Name', 'Fig 2: Radial & Tangential Bias vs Distance');
sgtitle('Loop orientation vs inter-loop segment direction (control, cond 1)', 'FontSize', 16);

% --- Radial bias (cos) ---
subplot(1, 2, 1);
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

% --- Tangential bias (sin) ---
subplot(1, 2, 2);
hold on;

errorbar(bin_centres_d, sin_bin_l, sin_sem_l, '-o', 'Color', col_loop * 0.6, ...
    'LineWidth', 2, 'MarkerFaceColor', col_loop * 0.6, 'MarkerSize', 6, 'CapSize', 4);
errorbar(bin_centres_d, sin_bin_s, sin_sem_s, '-s', 'Color', col_seg, ...
    'LineWidth', 2, 'MarkerFaceColor', col_seg, 'MarkerSize', 6, 'CapSize', 4);
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

xlabel('Distance from centre (mm)', 'FontSize', 14);
ylabel('sin(rel angle) — tangential component', 'FontSize', 14);
title('Tangential bias', 'FontSize', 14);
legend('Loops', 'Inter-loop segments', 'Location', 'best', 'FontSize', 11);
ylim([-0.3 0.3]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

%% Print summary

fprintf('\n--- Summary ---\n');
fprintf('  %-25s %-12s %-12s\n', '', 'Loops', 'Segments');
fprintf('  %-25s %-12d %-12d\n', 'n', numel(loop_rel), numel(seg_rel));
fprintf('  %-25s %-+12.3f %-+12.3f\n', 'mean(cos) [radial]', ...
    mean(loop_cos), mean(seg_cos));
fprintf('  %-25s %-+12.3f %-+12.3f\n', 'mean(sin) [tangential]', ...
    mean(loop_sin), mean(seg_sin));

S_l = mean(sind(loop_rel));  C_l = mean(cosd(loop_rel));
S_s = mean(sind(seg_rel));   C_s = mean(cosd(seg_rel));
fprintf('  %-25s %-12.1f %-12.1f\n', 'circ mean (deg)', ...
    atan2d(S_l, C_l), atan2d(S_s, C_s));
fprintf('  %-25s %-12.3f %-12.3f\n', 'resultant length (r)', ...
    sqrt(S_l^2 + C_l^2), sqrt(S_s^2 + C_s^2));
fprintf('  %-25s %-12.1f %-12.1f\n', '%% inward', ...
    100*mean(abs(loop_rel) > 90), 100*mean(abs(seg_rel) > 90));

fprintf('\n--- Binned cos comparison ---\n');
fprintf('  %-12s %-10s %-10s\n', 'Bin', 'Loops', 'Segments');
for bi = 1:n_dist_bins
    fprintf('  %-12s %-+10.3f %-+10.3f\n', ...
        sprintf('%.0f-%.0f mm', bin_edges_d(bi), bin_edges_d(bi+1)), ...
        cos_bin_l(bi), cos_bin_s(bi));
end
