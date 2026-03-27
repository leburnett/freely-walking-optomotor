%% TRAVELLING_DIRECTION_ANALYSIS - Angular difference between heading and travel direction
%
%  Quantifies the discrepancy between body heading angle (from FlyTracker)
%  and actual travelling direction (from position displacement) for the
%  control strain (jfrc100_es_shibire_kir) during condition 1 (60 deg
%  gratings, 4 Hz) of protocol 27.
%
%  A ~90 deg difference indicates the fly is moving sideways relative to
%  its body axis ("crabbing"). This script produces:
%    Fig 1: Histogram of |heading - travel direction| (+ signed version)
%    Fig 2: Time course of mean angular difference over the stimulus
%    Fig 3: Sideways fraction vs distance from arena centre
%    GUI:   Interactive trajectory browser (browse_trajectories_by_slip)
%
%  Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 27).
%
%  NEXT STEPS / SUGGESTIONS:
%    1. Sideways vs turning: filter by angular velocity to distinguish
%       sustained crabbing (low AV) from transient mid-turn sideslip (high AV).
%    2. Stimulus dependence: compare condition 1 (moving gratings) vs
%       condition 10 (static grating) — does visual motion drive sideways walking?
%    3. Wall proximity: flies near the wall may show more sideslip as they
%       follow the curved boundary — Fig 3 tests this.
%    4. Per-fly variability: individual fly histograms to see if crabbing
%       is a consistent strategy or a per-fly trait.

%% ================================================================
%  SECTION 1: Data loading
%  ================================================================

if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

PPM = 4.1691;
ARENA_CENTER = [520, 520] / PPM;  % x adjusted from 528 to 520 to better match trajectory data
ARENA_R = 120;
FPS = 30;
dt = 1 / FPS;

control_strain = "jfrc100_es_shibire_kir";
key_condition = 1;
sex = 'F';

STIM_ON  = 300;   % frame index: stimulus onset (10 s into trial)
STIM_OFF = 1200;  % frame index: stimulus offset

SPEED_THRESHOLD = 0.5;  % mm/s — below this, travel direction is undefined

data_types = {'heading_wrap', 'x_data', 'y_data', 'vel_data', 'dist_data'};
[rep_data, n_flies] = load_per_rep_data( ...
    DATA, control_strain, sex, key_condition, data_types);

fprintf('Loaded %d fly-rep observations for %s condition %d\n', ...
    n_flies, control_strain, key_condition);

%% ================================================================
%  SECTION 2: Compute travelling direction (three-point central difference)
%  ================================================================

n_frames = size(rep_data.x_data, 2);

% Compute vx, vy using three-point central difference
% (matches calculate_three_point_velocity.m convention)
vx = zeros(n_flies, n_frames);
vy = zeros(n_flies, n_frames);

% Forward difference at first frame
vx(:, 1) = (rep_data.x_data(:, 2) - rep_data.x_data(:, 1)) / dt;
vy(:, 1) = (rep_data.y_data(:, 2) - rep_data.y_data(:, 1)) / dt;

% Central difference for intermediate frames
vx(:, 2:end-1) = (rep_data.x_data(:, 3:end) - rep_data.x_data(:, 1:end-2)) / (2 * dt);
vy(:, 2:end-1) = (rep_data.y_data(:, 3:end) - rep_data.y_data(:, 1:end-2)) / (2 * dt);

% Backward difference at last frame
vx(:, end) = (rep_data.x_data(:, end) - rep_data.x_data(:, end-1)) / dt;
vy(:, end) = (rep_data.y_data(:, end) - rep_data.y_data(:, end-1)) / dt;

% Travelling direction in degrees
travel_dir = atan2d(vy, vx);

%% ================================================================
%  SECTION 3: Compute angular difference
%  ================================================================

% Signed angular difference: heading_wrap - travel_dir, wrapped to [-180, 180]
ang_diff = mod(rep_data.heading_wrap - travel_dir + 180, 360) - 180;
abs_ang_diff = abs(ang_diff);

% Speed mask: only consider frames where the fly is actually moving
speed_mask = rep_data.vel_data >= SPEED_THRESHOLD;

%% ================================================================
%  SECTION 4: Extract stimulus period
%  ================================================================

stim_range = STIM_ON:STIM_OFF;

abs_diff_stim = abs_ang_diff(:, stim_range);
signed_diff_stim = ang_diff(:, stim_range);
speed_mask_stim = speed_mask(:, stim_range);
dist_stim = rep_data.dist_data(:, stim_range);

% Pool valid frames
valid = speed_mask_stim & ~isnan(abs_diff_stim);
abs_diff_valid = abs_diff_stim(valid);
signed_diff_valid = signed_diff_stim(valid);

fprintf('Valid frames (speed > %g mm/s): %d / %d (%.1f%%)\n', ...
    SPEED_THRESHOLD, sum(valid(:)), numel(valid), 100 * sum(valid(:)) / numel(valid));

%% ================================================================
%  SECTION 5: Figure 1 — Histogram of angular difference
%  ================================================================

figure('Position', [50 50 700 800]);

% --- Top: absolute angular difference ---
subplot(2, 1, 1);
edges_abs = 0:5:180;
h_counts = histcounts(abs_diff_valid, edges_abs, 'Normalization', 'probability');
bar_centers = edges_abs(1:end-1) + 2.5;
bar(bar_centers, h_counts, 1, 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'none');
hold on;

% Reference lines
xline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(90, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

% Median and mean
med_val = median(abs_diff_valid, 'omitnan');
mean_val = mean(abs_diff_valid, 'omitnan');
xline(med_val, '-', 'Color', 'k', 'LineWidth', 1.5);
xline(mean_val, '-', 'Color', 'r', 'LineWidth', 1.5);

% Sideways fraction annotation
sideways_frac = sum(abs_diff_valid >= 75 & abs_diff_valid <= 105) / numel(abs_diff_valid);
text(0.97, 0.92, sprintf('Sideways (75-105°): %.1f%%', 100 * sideways_frac), ...
    'Units', 'normalized', 'HorizontalAlignment', 'right', 'FontSize', 11);
text(0.97, 0.82, sprintf('Median: %.1f°', med_val), ...
    'Units', 'normalized', 'HorizontalAlignment', 'right', 'FontSize', 11);
text(0.97, 0.72, sprintf('Mean: %.1f°', mean_val), ...
    'Units', 'normalized', 'HorizontalAlignment', 'right', 'FontSize', 11, 'Color', 'r');

xlabel('|Heading − Travelling Direction| (deg)', 'FontSize', 14);
ylabel('Fraction of frames', 'FontSize', 14);
title('Angular Difference — Absolute', 'FontSize', 16);
xlim([0 180]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% --- Bottom: signed angular difference ---
subplot(2, 1, 2);
edges_signed = -180:5:180;
h_counts_s = histcounts(signed_diff_valid, edges_signed, 'Normalization', 'probability');
bar_centers_s = edges_signed(1:end-1) + 2.5;
bar(bar_centers_s, h_counts_s, 1, 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'none');
hold on;

xline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(90, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(-90, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

med_val_s = median(signed_diff_valid, 'omitnan');
xline(med_val_s, '-', 'Color', 'k', 'LineWidth', 1.5);

xlabel('Heading − Travelling Direction (deg)', 'FontSize', 14);
ylabel('Fraction of frames', 'FontSize', 14);
title('Angular Difference — Signed', 'FontSize', 16);
xlim([-180 180]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

sgtitle(sprintf('%s — Condition %d — %d flies, speed > %g mm/s', ...
    strrep(char(control_strain), '_', ' '), key_condition, n_flies, SPEED_THRESHOLD), ...
    'FontSize', 18);

%% ================================================================
%  SECTION 6: Figure 2 — Time course of angular difference
%  ================================================================

% Per-frame mean across flies (only speed-valid frames contribute)
abs_diff_stim_masked = abs_diff_stim;
abs_diff_stim_masked(~speed_mask_stim) = NaN;

frame_mean = mean(abs_diff_stim_masked, 1, 'omitnan');
frame_sem  = std(abs_diff_stim_masked, 0, 1, 'omitnan') ./ ...
    sqrt(sum(~isnan(abs_diff_stim_masked), 1));

time_s = (0:numel(frame_mean)-1) / FPS;

figure('Position', [100 100 900 400]);
fill([time_s, fliplr(time_s)], ...
    [frame_mean + frame_sem, fliplr(frame_mean - frame_sem)], ...
    [0.85 0.85 0.85], 'EdgeColor', 'none');
hold on;
plot(time_s, frame_mean, '-k', 'LineWidth', 1.5);
yline(90, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

xlabel('Time from stimulus onset (s)', 'FontSize', 14);
ylabel('Mean |Heading − Travel Dir| (deg)', 'FontSize', 14);
title('Time Course of Angular Difference During Stimulus', 'FontSize', 16);
xlim([0 time_s(end)]);
ylim([0 135]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

%% ================================================================
%  SECTION 7: Figure 3 — Sideways fraction vs distance from centre
%  ================================================================

dist_bin_edges = 0:10:120;
n_bins = numel(dist_bin_edges) - 1;
sideways_by_dist = NaN(1, n_bins);
n_frames_by_dist = zeros(1, n_bins);

for b = 1:n_bins
    in_bin = dist_stim >= dist_bin_edges(b) & dist_stim < dist_bin_edges(b+1) & valid;
    n_frames_by_dist(b) = sum(in_bin(:));
    if n_frames_by_dist(b) > 100  % require minimum frame count
        sideways_by_dist(b) = sum(abs_diff_stim(in_bin) >= 75 & abs_diff_stim(in_bin) <= 105) ...
            / n_frames_by_dist(b);
    end
end

dist_bin_centers = dist_bin_edges(1:end-1) + 5;

figure('Position', [150 150 700 450]);

yyaxis left
bar(dist_bin_centers, 100 * sideways_by_dist, 1, ...
    'FaceColor', [0.45 0.62 0.80], 'EdgeColor', 'none');
ylabel('Sideways Frames (75-105°) (%)', 'FontSize', 14);
ylim([0 max(100 * sideways_by_dist) * 1.3]);

yyaxis right
plot(dist_bin_centers, n_frames_by_dist, '-o', 'Color', [0.7 0.7 0.7], ...
    'MarkerFaceColor', [0.7 0.7 0.7], 'MarkerSize', 5, 'LineWidth', 1);
ylabel('Frame count', 'FontSize', 14);

xlabel('Distance from arena centre (mm)', 'FontSize', 14);
title('Sideways Movement vs Arena Position', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

%% ================================================================
%  SECTION 8: Launch interactive trajectory browser
%  ================================================================

browse_trajectories_by_slip(rep_data, travel_dir, abs_ang_diff, ...
    speed_mask, STIM_ON, STIM_OFF, ARENA_CENTER, ARENA_R, SPEED_THRESHOLD);
