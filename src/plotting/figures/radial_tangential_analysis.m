%% RADIAL_TANGENTIAL_ANALYSIS - Velocity decomposition and heading-to-center analysis
%
% Decomposes fly velocity into radial (toward/away from arena center) and
% tangential (orbiting) components, and analyzes heading-to-center angle.
% Addresses the alternative explanation that centring is a geometric
% byproduct of curved walking paths rather than active behavior.
%
% FIGURES PRODUCED:
%   Figure 1 (3×1): Velocity decomposition timeseries for control, cond 1
%   Figure 2 (2×2): Heading-to-center analysis for control, cond 1
%   Figure 3 (3×2): Cross-strain comparison (T4/T5, Dm4, Tm5Y vs control)
%   Figure 4 (1×2): Geometric prediction test (partial correlation)
%
% MANUSCRIPT TASKS ADDRESSED (Phase 2):
%   - Radial/tangential velocity decomposition
%   - Heading-to-center analysis
%
% REQUIREMENTS:
%   - DATA struct from comb_data_across_cohorts_cond (Protocol 27)
%   - Functions: compute_radial_tangential, compute_heading_to_center,
%     combine_timeseries_across_exp_check
%
% See also: compute_radial_tangential, compute_heading_to_center,
%           add_dist_dt, plot_centring_rate_timeseries

%% 1 — Configuration

% DATA loading with workspace check
if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
    fprintf('Loaded DATA from %s\n', protocol_dir);
end

cfg = get_config();

% Arena geometry (from calculate_viewing_distance.m)
PPM = 4.1691;
CoA = [528, 520] / PPM;  % center of arena in mm: [126.6, 124.7]
CX = CoA(1);
CY = CoA(2);
FPS = 30;

% Key strains and conditions
control_strain = "jfrc100_es_shibire_kir";
key_strains = {"ss324_t4t5_shibire_kir", "ss00297_Dm4_shibire_kir", ...
               "ss03722_Tm5Y_shibire_kir"};
key_labels  = {"T4/T5", "Dm4", "Tm5Y"};
key_condition = 1;  % 60deg gratings 4Hz
sex = 'F';

% Stimulus timing (frames at 30 fps)
STIM_ON  = 300;   % 10s
STIM_MID = 750;   % 25s (direction change CW→CCW)
STIM_OFF = 1200;  % 40s

% Colors for strains
ctrl_col = [0 0 0];          % black for control
strain_cols = [0.2 0.4 0.8;  % blue for T4/T5
               0.8 0.2 0.2;  % red for Dm4
               0.2 0.7 0.3]; % green for Tm5Y

% Figure save toggle
save_figs = 0;
save_folder = fullfile(cfg.figures, 'FIGS');

%% 2 — Load and compute: control flies, condition 1

fprintf('\n=== Loading control data (condition %d) ===\n', key_condition);
data_ctrl = DATA.(control_strain).(sex);

x_ctrl    = combine_timeseries_across_exp_check(data_ctrl, key_condition, "x_data");
y_ctrl    = combine_timeseries_across_exp_check(data_ctrl, key_condition, "y_data");
hw_ctrl   = combine_timeseries_across_exp_check(data_ctrl, key_condition, "heading_wrap");
dist_ctrl = combine_timeseries_across_exp_check(data_ctrl, key_condition, "dist_data");
vel_ctrl  = combine_timeseries_across_exp_check(data_ctrl, key_condition, "vel_data");

n_ctrl = size(x_ctrl, 1);
fprintf('  Control: %d flies\n', n_ctrl);

% Radial/tangential decomposition
[vr_ctrl, vt_ctrl, ~, r_ctrl] = compute_radial_tangential(x_ctrl, y_ctrl, CX, CY, FPS);

% Heading-to-center analysis
[htc_ctrl, htc_cos_ctrl] = compute_heading_to_center(hw_ctrl, x_ctrl, y_ctrl, CX, CY);

%% 2b — Validation: compare v_rad with dist_dt

% dist_dt convention: positive = centring (inward) = -diff(movmean(dist,5))*30
dist_dt_check = [NaN(n_ctrl, 1), -diff(movmean(dist_ctrl, 5, 2), 1, 2) * FPS];

% Our v_rad: positive = outward, so -v_rad = centring (inward)
neg_vr = -vr_ctrl;

% Correlation between mean timeseries (should be >0.99)
mean_neg_vr = nanmean(neg_vr, 1);
mean_dist_dt = nanmean(dist_dt_check, 1);
valid = ~isnan(mean_neg_vr) & ~isnan(mean_dist_dt);
r_corr = corr(mean_neg_vr(valid)', mean_dist_dt(valid)');
fprintf('\n=== Validation ===\n');
fprintf('  Correlation: mean(-v_rad) vs mean(dist_dt) = %.4f\n', r_corr);

% Speed check: sqrt(vr^2 + vt^2) vs vel_data
speed_decomp = sqrt(vr_ctrl.^2 + vt_ctrl.^2);
mean_speed_decomp = nanmean(speed_decomp, 1);
mean_vel = nanmean(vel_ctrl, 1);
valid2 = ~isnan(mean_speed_decomp) & ~isnan(mean_vel);
r_speed = corr(mean_speed_decomp(valid2)', mean_vel(valid2)');
fprintf('  Correlation: sqrt(vr^2 + vt^2) vs vel_data = %.4f\n', r_speed);

%% 3 — Figure 1: Velocity decomposition timeseries (3×1)

n_frames = size(vr_ctrl, 2);
x_frames = 1:n_frames;

% Centripetal velocity (positive = inward = centring)
centripetal_ctrl = -vr_ctrl;

fig1 = figure('Position', [50 50 900 800]);
sgtitle('Velocity Decomposition — Control, 60° Gratings 4Hz', 'FontSize', 18);

% Panel A: Centripetal velocity
subplot(3, 1, 1);
hold on;
mean_cp = nanmean(centripetal_ctrl, 1);
sem_cp  = nanstd(centripetal_ctrl, 0, 1) / sqrt(n_ctrl);
y1 = mean_cp + sem_cp;
y2 = mean_cp - sem_cp;
patch([x_frames fliplr(x_frames)], [y1 fliplr(y2)], ctrl_col, ...
    'FaceAlpha', 0.15, 'EdgeColor', 'none');
plot(x_frames, mean_cp, '-', 'Color', ctrl_col, 'LineWidth', 1.5);
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(STIM_ON,  '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(STIM_MID, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(STIM_OFF, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
ylabel('Centripetal velocity (mm/s)', 'FontSize', 14);
title('A — Radial velocity (positive = centring)', 'FontSize', 16);
xticks([0, 300, 600, 900, 1200, 1500]);
xticklabels({'0', '10', '20', '30', '40', '50'});
xlim([0 1800]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Panel B: Tangential speed (absolute)
subplot(3, 1, 2);
hold on;
abs_vt = abs(vt_ctrl);
mean_vt = nanmean(abs_vt, 1);
sem_vt  = nanstd(abs_vt, 0, 1) / sqrt(n_ctrl);
y1 = mean_vt + sem_vt;
y2 = mean_vt - sem_vt;
patch([x_frames fliplr(x_frames)], [y1 fliplr(y2)], ctrl_col, ...
    'FaceAlpha', 0.15, 'EdgeColor', 'none');
plot(x_frames, mean_vt, '-', 'Color', ctrl_col, 'LineWidth', 1.5);
xline(STIM_ON,  '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(STIM_MID, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(STIM_OFF, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
ylabel('Tangential speed (mm/s)', 'FontSize', 14);
title('B — Tangential speed (magnitude of orbiting)', 'FontSize', 16);
xticks([0, 300, 600, 900, 1200, 1500]);
xticklabels({'0', '10', '20', '30', '40', '50'});
xlim([0 1800]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Panel C: Total speed (from vel_data)
subplot(3, 1, 3);
hold on;
mean_vel_ts = nanmean(vel_ctrl, 1);
sem_vel_ts  = nanstd(vel_ctrl, 0, 1) / sqrt(n_ctrl);
y1 = mean_vel_ts + sem_vel_ts;
y2 = mean_vel_ts - sem_vel_ts;
patch([x_frames fliplr(x_frames)], [y1 fliplr(y2)], ctrl_col, ...
    'FaceAlpha', 0.15, 'EdgeColor', 'none');
plot(x_frames, mean_vel_ts, '-', 'Color', ctrl_col, 'LineWidth', 1.5);
xline(STIM_ON,  '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(STIM_MID, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(STIM_OFF, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
ylabel('Total speed (mm/s)', 'FontSize', 14);
xlabel('Time (s)', 'FontSize', 14);
title('C — Total speed (3-point velocity)', 'FontSize', 16);
xticks([0, 300, 600, 900, 1200, 1500]);
xticklabels({'0', '10', '20', '30', '40', '50'});
xlim([0 1800]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

if save_figs
    exportgraphics(fig1, fullfile(save_folder, 'radial_tangential_timeseries.pdf'), ...
        'ContentType', 'vector');
    close(fig1);
end

%% 4 — Figure 2: Heading-to-center analysis (2×2)

fig2 = figure('Position', [50 50 1000 800]);
sgtitle('Heading-to-Center Analysis — Control, 60° Gratings 4Hz', 'FontSize', 18);

% Panel A: Heading-to-center alignment timeseries
subplot(2, 2, 1);
hold on;
mean_htc = nanmean(htc_cos_ctrl, 1);
sem_htc  = nanstd(htc_cos_ctrl, 0, 1) / sqrt(n_ctrl);
y1 = mean_htc + sem_htc;
y2 = mean_htc - sem_htc;
patch([x_frames fliplr(x_frames)], [y1 fliplr(y2)], ctrl_col, ...
    'FaceAlpha', 0.15, 'EdgeColor', 'none');
plot(x_frames, mean_htc, '-', 'Color', ctrl_col, 'LineWidth', 1.5);
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(STIM_ON,  '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(STIM_MID, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(STIM_OFF, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
ylabel('Alignment index (cos)', 'FontSize', 14);
xlabel('Time (s)', 'FontSize', 14);
title('A — Heading-to-center alignment', 'FontSize', 16);
xticks([0, 300, 600, 900, 1200, 1500]);
xticklabels({'0', '10', '20', '30', '40', '50'});
xlim([0 1800]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Panel B: Polar histogram of heading-to-center angle during stimulus
subplot(2, 2, 2);
% Collect all heading-to-center angles during stimulus (per-frame, all flies)
htc_stim = htc_ctrl(:, STIM_ON:STIM_OFF);
htc_stim_vec = htc_stim(:);
htc_stim_vec = htc_stim_vec(~isnan(htc_stim_vec));
polarhistogram(deg2rad(htc_stim_vec), 36, 'Normalization', 'probability', ...
    'FaceColor', [0.3 0.3 0.3], 'FaceAlpha', 0.6, 'EdgeColor', 'w');
title('B — HTC angle distribution (stimulus)', 'FontSize', 16);
set(gca, 'FontSize', 12);

% Panel C: Scatter — alignment vs centripetal velocity (per-fly means during stim)
subplot(2, 2, 3);
hold on;
mean_htc_per_fly = nanmean(htc_cos_ctrl(:, STIM_ON:STIM_OFF), 2);
mean_cp_per_fly  = nanmean(centripetal_ctrl(:, STIM_ON:STIM_OFF), 2);
valid_flies = ~isnan(mean_htc_per_fly) & ~isnan(mean_cp_per_fly);
scatter(mean_htc_per_fly(valid_flies), mean_cp_per_fly(valid_flies), ...
    40, [0.3 0.3 0.3], 'filled', 'MarkerFaceAlpha', 0.5);

% Add regression line
if sum(valid_flies) > 2
    p = polyfit(mean_htc_per_fly(valid_flies), mean_cp_per_fly(valid_flies), 1);
    x_fit = linspace(min(mean_htc_per_fly(valid_flies)), max(mean_htc_per_fly(valid_flies)), 100);
    plot(x_fit, polyval(p, x_fit), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1.5);
    [rho_sc, pval_sc] = corr(mean_htc_per_fly(valid_flies), mean_cp_per_fly(valid_flies));
    text(0.05, 0.95, sprintf('r = %.2f, p = %.1e', rho_sc, pval_sc), ...
        'Units', 'normalized', 'FontSize', 11, 'VerticalAlignment', 'top');
end
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xlabel('Mean alignment index', 'FontSize', 14);
ylabel('Mean centripetal velocity (mm/s)', 'FontSize', 14);
title('C — Alignment vs centring per fly', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Panel D: Alignment timeseries by distance bins
subplot(2, 2, 4);
hold on;

% Bin flies by pre-stimulus distance from center
start_dist = nanmean(r_ctrl(:, 270:300), 2);
bin_edges = [0, 40, 80, 120];
bin_labels = {'Near (0-40 mm)', 'Mid (40-80 mm)', 'Far (80-120 mm)'};
bin_colors = [0.2 0.6 0.2; 0.8 0.5 0.1; 0.6 0.1 0.6];

for b = 1:3
    in_bin = start_dist >= bin_edges(b) & start_dist < bin_edges(b+1);
    if sum(in_bin) < 3
        continue;
    end
    n_bin = sum(in_bin);
    mean_htc_bin = nanmean(htc_cos_ctrl(in_bin, :), 1);
    sem_htc_bin  = nanstd(htc_cos_ctrl(in_bin, :), 0, 1) / sqrt(n_bin);
    y1 = mean_htc_bin + sem_htc_bin;
    y2 = mean_htc_bin - sem_htc_bin;
    patch([x_frames fliplr(x_frames)], [y1 fliplr(y2)], bin_colors(b,:), ...
        'FaceAlpha', 0.1, 'EdgeColor', 'none');
    plot(x_frames, mean_htc_bin, '-', 'Color', bin_colors(b,:), 'LineWidth', 1.5, ...
        'DisplayName', sprintf('%s (n=%d)', bin_labels{b}, n_bin));
end

yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(STIM_ON,  '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(STIM_MID, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(STIM_OFF, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
legend('Location', 'southeast', 'FontSize', 10);
ylabel('Alignment index (cos)', 'FontSize', 14);
xlabel('Time (s)', 'FontSize', 14);
title('D — Alignment by starting distance', 'FontSize', 16);
xticks([0, 300, 600, 900, 1200, 1500]);
xticklabels({'0', '10', '20', '30', '40', '50'});
xlim([0 1800]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

if save_figs
    exportgraphics(fig2, fullfile(save_folder, 'heading_to_center_analysis.pdf'), ...
        'ContentType', 'vector');
    close(fig2);
end

%% 5 — Load and compute: key strains

fprintf('\n=== Loading key strains ===\n');

% Preallocate struct arrays for strain data
strain_data = struct();

for s = 1:numel(key_strains)
    sname = key_strains{s};
    slabel = key_labels{s};

    data_s = DATA.(sname).(sex);

    x_s    = combine_timeseries_across_exp_check(data_s, key_condition, "x_data");
    y_s    = combine_timeseries_across_exp_check(data_s, key_condition, "y_data");
    hw_s   = combine_timeseries_across_exp_check(data_s, key_condition, "heading_wrap");

    n_s = size(x_s, 1);
    fprintf('  %s: %d flies\n', slabel, n_s);

    [vr_s, vt_s, ~, r_s] = compute_radial_tangential(x_s, y_s, CX, CY, FPS);
    [~, htc_cos_s] = compute_heading_to_center(hw_s, x_s, y_s, CX, CY);

    strain_data(s).name = sname;
    strain_data(s).label = slabel;
    strain_data(s).n = n_s;
    strain_data(s).centripetal = -vr_s;   % positive = centring
    strain_data(s).vt = vt_s;
    strain_data(s).htc_cos = htc_cos_s;
    strain_data(s).r = r_s;
end

%% 6 — Figure 3: Cross-strain comparison (3×2)

fig3 = figure('Position', [50 50 1100 900]);
sgtitle('Cross-Strain Comparison — Condition 1 (60° Gratings 4Hz)', 'FontSize', 18);

for s = 1:numel(key_strains)

    % Determine common frame range (strain may have different frame count)
    nf_s = size(strain_data(s).centripetal, 2);
    nf_common = min(n_frames, nf_s);
    x_common = 1:nf_common;

    % Row 1: Centripetal velocity
    subplot(numel(key_strains), 2, (s-1)*2 + 1);
    hold on;

    % Control (grey shading + black line) — trimmed to common frames
    mean_cp_c = nanmean(centripetal_ctrl(:, 1:nf_common), 1);
    sem_cp_c  = nanstd(centripetal_ctrl(:, 1:nf_common), 0, 1) / sqrt(n_ctrl);
    patch([x_common fliplr(x_common)], [mean_cp_c+sem_cp_c fliplr(mean_cp_c-sem_cp_c)], ...
        [0.5 0.5 0.5], 'FaceAlpha', 0.1, 'EdgeColor', 'none');
    plot(x_common, mean_cp_c, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 1);

    % Strain (colored shading + line) — trimmed to common frames
    n_s = strain_data(s).n;
    mean_cp_s = nanmean(strain_data(s).centripetal(:, 1:nf_common), 1);
    sem_cp_s  = nanstd(strain_data(s).centripetal(:, 1:nf_common), 0, 1) / sqrt(n_s);
    patch([x_common fliplr(x_common)], [mean_cp_s+sem_cp_s fliplr(mean_cp_s-sem_cp_s)], ...
        strain_cols(s,:), 'FaceAlpha', 0.15, 'EdgeColor', 'none');
    plot(x_common, mean_cp_s, '-', 'Color', strain_cols(s,:), 'LineWidth', 1.5);

    yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    xline(STIM_ON,  '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    xline(STIM_MID, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    xline(STIM_OFF, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    ylabel('Centripetal vel (mm/s)', 'FontSize', 14);
    title(sprintf('%s — Centripetal velocity (n=%d)', strain_data(s).label, n_s), 'FontSize', 16);
    xticks([0, 300, 600, 900, 1200, 1500]);
    xticklabels({'0', '10', '20', '30', '40', '50'});
    xlim([0 1800]);
    if s == numel(key_strains)
        xlabel('Time (s)', 'FontSize', 14);
    end
    set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

    % Row 2: Heading-to-center alignment
    subplot(numel(key_strains), 2, (s-1)*2 + 2);
    hold on;

    % Control — trimmed to common frames
    mean_htc_c = nanmean(htc_cos_ctrl(:, 1:nf_common), 1);
    sem_htc_c  = nanstd(htc_cos_ctrl(:, 1:nf_common), 0, 1) / sqrt(n_ctrl);
    patch([x_common fliplr(x_common)], [mean_htc_c+sem_htc_c fliplr(mean_htc_c-sem_htc_c)], ...
        [0.5 0.5 0.5], 'FaceAlpha', 0.1, 'EdgeColor', 'none');
    plot(x_common, mean_htc_c, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 1);

    % Strain — trimmed to common frames
    mean_htc_s = nanmean(strain_data(s).htc_cos(:, 1:nf_common), 1);
    sem_htc_s  = nanstd(strain_data(s).htc_cos(:, 1:nf_common), 0, 1) / sqrt(n_s);
    patch([x_common fliplr(x_common)], [mean_htc_s+sem_htc_s fliplr(mean_htc_s-sem_htc_s)], ...
        strain_cols(s,:), 'FaceAlpha', 0.15, 'EdgeColor', 'none');
    plot(x_common, mean_htc_s, '-', 'Color', strain_cols(s,:), 'LineWidth', 1.5);

    yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    xline(STIM_ON,  '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    xline(STIM_MID, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    xline(STIM_OFF, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    ylabel('Alignment index (cos)', 'FontSize', 14);
    title(sprintf('%s — Heading alignment (n=%d)', strain_data(s).label, n_s), 'FontSize', 16);
    xticks([0, 300, 600, 900, 1200, 1500]);
    xticklabels({'0', '10', '20', '30', '40', '50'});
    xlim([0 1800]);
    if s == numel(key_strains)
        xlabel('Time (s)', 'FontSize', 14);
    end
    set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
end

if save_figs
    exportgraphics(fig3, fullfile(save_folder, 'cross_strain_radial_tangential.pdf'), ...
        'ContentType', 'vector');
    close(fig3);
end

%% 7 — Figure 4: Geometric prediction test (1×2)

fig4 = figure('Position', [50 50 1000 450]);
sgtitle('Geometric Prediction Test — Is centring a byproduct of curved paths?', 'FontSize', 18);

% Per-fly summary metrics during stimulus
start_dist_ctrl  = nanmean(r_ctrl(:, 270:300), 2);
mean_vt_ctrl     = nanmean(abs(vt_ctrl(:, STIM_ON:STIM_OFF)), 2);
mean_cp_fly_ctrl = nanmean(centripetal_ctrl(:, STIM_ON:STIM_OFF), 2);

valid_ctrl = ~isnan(start_dist_ctrl) & ~isnan(mean_vt_ctrl) & ~isnan(mean_cp_fly_ctrl);

% Panel A: Scatter — tangential speed vs centripetal velocity, colored by distance
subplot(1, 2, 1);
hold on;
scatter(mean_vt_ctrl(valid_ctrl), mean_cp_fly_ctrl(valid_ctrl), ...
    40, start_dist_ctrl(valid_ctrl), 'filled', 'MarkerFaceAlpha', 0.6);
colormap(gca, turbo);
cb = colorbar;
ylabel(cb, 'Starting distance (mm)', 'FontSize', 12);
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xlabel('Mean tangential speed (mm/s)', 'FontSize', 14);
ylabel('Mean centripetal velocity (mm/s)', 'FontSize', 14);
title('A — Tangential speed vs centring', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Panel B: Partial correlation — centripetal velocity with distance, controlling for tangential speed
subplot(1, 2, 2);
hold on;

% Partial correlation: remove effect of tangential speed from both variables
if sum(valid_ctrl) > 5
    [rho_partial, pval_partial] = partialcorr( ...
        mean_cp_fly_ctrl(valid_ctrl), ...
        start_dist_ctrl(valid_ctrl), ...
        mean_vt_ctrl(valid_ctrl));

    % Visualise: residuals after regressing out tangential speed
    X = [ones(sum(valid_ctrl), 1), mean_vt_ctrl(valid_ctrl)];
    beta_cp   = X \ mean_cp_fly_ctrl(valid_ctrl);
    beta_dist = X \ start_dist_ctrl(valid_ctrl);
    resid_cp   = mean_cp_fly_ctrl(valid_ctrl) - X * beta_cp;
    resid_dist = start_dist_ctrl(valid_ctrl) - X * beta_dist;

    scatter(resid_dist, resid_cp, 40, [0.3 0.3 0.3], 'filled', 'MarkerFaceAlpha', 0.5);

    % Regression line
    p_fit = polyfit(resid_dist, resid_cp, 1);
    x_fit = linspace(min(resid_dist), max(resid_dist), 100);
    plot(x_fit, polyval(p_fit, x_fit), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1.5);

    yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    xline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

    text(0.05, 0.95, ...
        sprintf('Partial r = %.3f\np = %.1e', rho_partial, pval_partial), ...
        'Units', 'normalized', 'FontSize', 12, 'VerticalAlignment', 'top');
end

xlabel('Starting distance (residual)', 'FontSize', 14);
ylabel('Centripetal velocity (residual)', 'FontSize', 14);
title('B — Partial corr (controlling for tangential speed)', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

if save_figs
    exportgraphics(fig4, fullfile(save_folder, 'geometric_prediction_test.pdf'), ...
        'ContentType', 'vector');
    close(fig4);
end

%% 8 — Statistics & console output

fprintf('\n=== Statistics Summary ===\n');
fprintf('%-12s  %6s  %10s  %10s  %10s  %10s  %10s  %10s\n', ...
    'Strain', 'N', 'MeanCpVel', 'CpVel_p', 'MeanAlign', 'Align_p', 'dCpVel', 'dAlign');
fprintf('%s\n', repmat('-', 1, 92));

% Helper: compute stats for one group
all_strains = [{control_strain}, key_strains];
all_labels  = [{"Control"}, key_labels];

% Store control metrics for Welch tests
ctrl_cp_mean = nanmean(centripetal_ctrl(:, STIM_ON:STIM_OFF), 2);
ctrl_htc_mean = nanmean(htc_cos_ctrl(:, STIM_ON:STIM_OFF), 2);

for s = 1:numel(all_labels)

    if s == 1
        % Control
        cp_vals  = ctrl_cp_mean;
        htc_vals = ctrl_htc_mean;
        n_s = n_ctrl;
    else
        nf_si = size(strain_data(s-1).centripetal, 2);
        stim_end = min(STIM_OFF, nf_si);
        cp_vals  = nanmean(strain_data(s-1).centripetal(:, STIM_ON:stim_end), 2);
        htc_vals = nanmean(strain_data(s-1).htc_cos(:, STIM_ON:stim_end), 2);
        n_s = strain_data(s-1).n;
    end

    % Remove NaN
    cp_vals  = cp_vals(~isnan(cp_vals));
    htc_vals = htc_vals(~isnan(htc_vals));

    % One-sample t-test vs 0
    [~, p_cp]  = ttest(cp_vals, 0);
    [~, p_htc] = ttest(htc_vals, 0);

    % Cohen's d vs control (skip for control itself)
    if s == 1
        d_cp = NaN;
        d_htc = NaN;
    else
        ctrl_clean = ctrl_cp_mean(~isnan(ctrl_cp_mean));
        pooled_sd = sqrt(((numel(ctrl_clean)-1)*var(ctrl_clean) + (numel(cp_vals)-1)*var(cp_vals)) / ...
                         (numel(ctrl_clean) + numel(cp_vals) - 2));
        d_cp = (mean(cp_vals) - mean(ctrl_clean)) / pooled_sd;

        ctrl_htc_clean = ctrl_htc_mean(~isnan(ctrl_htc_mean));
        pooled_sd_htc = sqrt(((numel(ctrl_htc_clean)-1)*var(ctrl_htc_clean) + (numel(htc_vals)-1)*var(htc_vals)) / ...
                              (numel(ctrl_htc_clean) + numel(htc_vals) - 2));
        d_htc = (mean(htc_vals) - mean(ctrl_htc_clean)) / pooled_sd_htc;
    end

    fprintf('%-12s  %6d  %10.3f  %10.1e  %10.3f  %10.1e  %10.3f  %10.3f\n', ...
        all_labels{s}, n_s, mean(cp_vals), p_cp, mean(htc_vals), p_htc, d_cp, d_htc);
end

% Partial correlation result
if exist('rho_partial', 'var')
    fprintf('\nPartial correlation (centripetal vel ~ starting distance | tangential speed):\n');
    fprintf('  rho = %.4f, p = %.2e\n', rho_partial, pval_partial);
    if pval_partial < 0.05
        fprintf('  SIGNIFICANT: Centring depends on starting distance even after\n');
        fprintf('  controlling for tangential speed. This argues against purely\n');
        fprintf('  geometric explanation.\n');
    else
        fprintf('  NOT SIGNIFICANT at p<0.05.\n');
    end
end

% Welch t-tests: strain vs control
fprintf('\n--- Welch t-tests: strain vs control ---\n');
fprintf('%-12s  %10s  %10s  %10s  %10s\n', 'Strain', 'CpVel_t', 'CpVel_p', 'Align_t', 'Align_p');

for s = 1:numel(key_strains)
    nf_si = size(strain_data(s).centripetal, 2);
    stim_end = min(STIM_OFF, nf_si);
    cp_s  = nanmean(strain_data(s).centripetal(:, STIM_ON:stim_end), 2);
    htc_s = nanmean(strain_data(s).htc_cos(:, STIM_ON:stim_end), 2);
    cp_s  = cp_s(~isnan(cp_s));
    htc_s = htc_s(~isnan(htc_s));

    ctrl_cp_clean  = ctrl_cp_mean(~isnan(ctrl_cp_mean));
    ctrl_htc_clean = ctrl_htc_mean(~isnan(ctrl_htc_mean));

    [~, p_cp_w, ~, stats_cp]   = ttest2(cp_s, ctrl_cp_clean, 'Vartype', 'unequal');
    [~, p_htc_w, ~, stats_htc] = ttest2(htc_s, ctrl_htc_clean, 'Vartype', 'unequal');

    fprintf('%-12s  %10.2f  %10.1e  %10.2f  %10.1e\n', ...
        key_labels{s}, stats_cp.tstat, p_cp_w, stats_htc.tstat, p_htc_w);
end

%% 9 — Export CSV

% Per-fly summary table
all_fly_data = [];

% Control flies
for f = 1:n_ctrl
    all_fly_data = [all_fly_data; ...
        {char(control_strain), 'Control', n_ctrl, ...
         start_dist_ctrl(f), ...
         mean_cp_fly_ctrl(f), ...
         mean_vt_ctrl(f), ...
         nanmean(htc_cos_ctrl(f, STIM_ON:STIM_OFF)), ...
         nanmean(vel_ctrl(f, STIM_ON:STIM_OFF))}]; %#ok<AGROW>
end

% Key strains
for s = 1:numel(key_strains)
    n_s = strain_data(s).n;
    nf_si = size(strain_data(s).centripetal, 2);
    stim_end = min(STIM_OFF, nf_si);
    pre_end = min(300, nf_si);
    start_d = nanmean(strain_data(s).r(:, 270:pre_end), 2);
    mean_cp_s = nanmean(strain_data(s).centripetal(:, STIM_ON:stim_end), 2);
    mean_vt_s = nanmean(abs(strain_data(s).vt(:, STIM_ON:stim_end)), 2);
    mean_htc_s = nanmean(strain_data(s).htc_cos(:, STIM_ON:stim_end), 2);

    % Need fv data for export — load it
    data_s = DATA.(key_strains{s}).(sex);
    fv_s = combine_timeseries_across_exp_check(data_s, key_condition, "fv_data");
    nf_fv = size(fv_s, 2);
    stim_end_fv = min(STIM_OFF, nf_fv);
    mean_fv_s = nanmean(fv_s(:, STIM_ON:stim_end_fv), 2);

    for f = 1:n_s
        all_fly_data = [all_fly_data; ...
            {char(key_strains{s}), char(key_labels{s}), n_s, ...
             start_d(f), mean_cp_s(f), mean_vt_s(f), ...
             mean_htc_s(f), mean_fv_s(f)}]; %#ok<AGROW>
    end
end

T = cell2table(all_fly_data, 'VariableNames', ...
    {'Strain', 'Label', 'N', 'StartDist_mm', 'MeanCentripetalVel_mms', ...
     'MeanTangentialSpeed_mms', 'MeanAlignmentIndex', 'MeanForwardVel_mms'});

csv_path = fullfile(save_folder, 'radial_tangential_per_fly.csv');
writetable(T, csv_path);
fprintf('\nExported per-fly summary to: %s\n', csv_path);
fprintf('Total flies in export: %d\n', height(T));
