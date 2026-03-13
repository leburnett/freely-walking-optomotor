%% CENTRING_NULL_MODEL — Heading-shuffle permutation test for centring
%
% SCRIPT CONTENTS:
%   - Section 1: Load Protocol 27 DATA (control, condition 1)
%   - Section 2: Compute observed centring metric per fly
%   - Section 3: Heading-shuffle null model (N=1000 permutations)
%   - Section 4: Statistical comparison
%   - Section 5: Figures (histogram, timeseries envelope, per-fly scatter)
%   - Local helper: reconstruct_trajectory_shuffled
%
% DESCRIPTION:
%   Tests whether observed centring exceeds geometric expectations from
%   random walking in a bounded circular arena. For each fly, the
%   frame-to-frame heading changes (dtheta) during the stimulus are
%   randomly permuted, and the trajectory is reconstructed using the
%   original speeds and starting position. This preserves each fly's
%   turning rate distribution and speed profile but breaks any temporal
%   correlation between position and heading direction.
%
%   If centring is an active behaviour, observed centring should far
%   exceed the null distribution from shuffled heading changes.
%
% REQUIREMENTS:
%   - DATA struct from comb_data_across_cohorts_cond (Protocol 27)
%   - Functions: combine_timeseries_across_exp_check
%
% See also: simulate_walking_viewdist_gain, radial_tangential_analysis,
%           compute_radial_tangential

%% 1 — Load P27 DATA

if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
    fprintf('Loaded P27 DATA from %s\n', protocol_dir);
end

cfg = get_config();

% Arena geometry (from calculate_viewing_distance.m)
PPM = 4.1691;
CoA = [528, 520] / PPM;  % center of arena in mm
CX = CoA(1);
CY = CoA(2);
ARENA_R = 496 / PPM;     % ~119.0 mm
FPS = 30;
DT = 1 / FPS;

% Stimulus timing
STIM_ON  = 300;   % frame 300 = stimulus onset
STIM_OFF = 1200;  % frame 1200 = stimulus offset
N_STIM = STIM_OFF - STIM_ON;  % 900 frames of stimulus

% Null model parameters
N_SHUF = 1000;  % number of shuffle iterations

% Load control data — condition 1 (60deg gratings 4Hz)
control_strain = "jfrc100_es_shibire_kir";
condition_n = 1;
sex = 'F';

data_ctrl = DATA.(control_strain).(sex);

x_all    = combine_timeseries_across_exp_check(data_ctrl, condition_n, "x_data");
y_all    = combine_timeseries_across_exp_check(data_ctrl, condition_n, "y_data");
hw_all   = combine_timeseries_across_exp_check(data_ctrl, condition_n, "heading_wrap");
vel_all  = combine_timeseries_across_exp_check(data_ctrl, condition_n, "vel_data");
dist_all = combine_timeseries_across_exp_check(data_ctrl, condition_n, "dist_data");

n_flies = size(x_all, 1);
n_frames = size(x_all, 2);
fprintf('Loaded %d control flies, %d frames\n', n_flies, n_frames);

% Convert x/y from pixels to mm
x_mm = x_all / PPM;
y_mm = y_all / PPM;

%% 2 — Compute observed centring metric

% Per-fly dist_delta: change from stimulus onset baseline
observed_dist_delta = dist_all - dist_all(:, STIM_ON);

% Per-fly summary: mean dist_delta during stimulus
observed_centring = nanmean(observed_dist_delta(:, STIM_ON:STIM_OFF), 2);

% Population summary
obs_mean = nanmean(observed_centring);
obs_sem  = nanstd(observed_centring) / sqrt(n_flies);

fprintf('\nObserved centring: mean = %.1f mm, SEM = %.1f mm (N=%d)\n', ...
    obs_mean, obs_sem, n_flies);

%% 3 — Heading shuffle null model

fprintf('\nRunning %d shuffle iterations for %d flies...\n', N_SHUF, n_flies);

% Preallocate: per-fly null centring values
null_centring = NaN(n_flies, N_SHUF);

% Also store one full timeseries per shuffle for envelope plot
% (store mean across flies per shuffle)
null_dist_delta_mean = NaN(N_SHUF, N_STIM + 1);

tic;
for f = 1:n_flies
    if mod(f, 50) == 0
        fprintf('  Fly %d/%d...\n', f, n_flies);
    end

    % Extract this fly's data during stimulus period
    x_fly = x_mm(f, :);
    y_fly = y_mm(f, :);
    hw_fly = hw_all(f, :);  % heading in degrees
    vel_fly = vel_all(f, :);  % mm/s

    % Check for NaN flies (QC-rejected)
    if all(isnan(x_fly(STIM_ON:STIM_OFF)))
        continue;
    end

    % Starting position and heading at stimulus onset
    x0 = x_fly(STIM_ON);
    y0 = y_fly(STIM_ON);
    theta0 = hw_fly(STIM_ON) * pi / 180;  % convert to radians

    % Frame-to-frame heading changes during stimulus (radians)
    hw_rad = hw_fly * pi / 180;
    dtheta_stim = diff(hw_rad(STIM_ON:STIM_OFF));
    % Wrap to [-pi, pi]
    dtheta_stim = mod(dtheta_stim + pi, 2*pi) - pi;

    % Speeds during stimulus (mm per frame)
    speeds_stim = vel_fly(STIM_ON:STIM_OFF-1) * DT;

    n_stim_frames = length(dtheta_stim);

    for shuf = 1:N_SHUF
        % Randomly permute heading changes
        perm_idx = randperm(n_stim_frames);
        dtheta_shuffled = dtheta_stim(perm_idx);

        % Reconstruct trajectory
        [~, ~, dist_shuf] = reconstruct_trajectory_shuffled( ...
            x0, y0, theta0, dtheta_shuffled, speeds_stim, CX, CY, ARENA_R);

        % Centring metric: change from starting distance
        dist_delta_shuf = dist_shuf - dist_shuf(1);

        % Summary value
        null_centring(f, shuf) = nanmean(dist_delta_shuf);
    end
end
elapsed = toc;
fprintf('Shuffle complete in %.1f s\n', elapsed);

% Compute null timeseries envelope (run a small batch for the plot)
fprintf('Computing null timeseries envelope (100 shuffles)...\n');
null_ts_all = NaN(100, N_STIM + 1);
for shuf = 1:100
    % For each shuffle, reconstruct ALL flies and take the mean
    dist_delta_this_shuf = NaN(n_flies, N_STIM + 1);
    for f = 1:n_flies
        x_fly = x_mm(f, :);
        hw_fly = hw_all(f, :);
        vel_fly = vel_all(f, :);

        if all(isnan(x_fly(STIM_ON:STIM_OFF)))
            continue;
        end

        x0 = x_fly(STIM_ON);
        y0 = y_mm(f, STIM_ON);
        theta0 = hw_fly(STIM_ON) * pi / 180;

        hw_rad = hw_fly * pi / 180;
        dtheta_stim = diff(hw_rad(STIM_ON:STIM_OFF));
        dtheta_stim = mod(dtheta_stim + pi, 2*pi) - pi;
        speeds_stim = vel_fly(STIM_ON:STIM_OFF-1) * DT;

        perm_idx = randperm(length(dtheta_stim));
        dtheta_shuffled = dtheta_stim(perm_idx);

        [~, ~, dist_shuf] = reconstruct_trajectory_shuffled( ...
            x0, y0, theta0, dtheta_shuffled, speeds_stim, CX, CY, ARENA_R);

        dist_delta_this_shuf(f, :) = dist_shuf - dist_shuf(1);
    end
    null_ts_all(shuf, :) = nanmean(dist_delta_this_shuf, 1);
end

%% 4 — Statistical comparison

% Per-fly p-values: fraction of shuffles with centring >= observed
% (more negative = more centring, so test how many nulls are <= observed)
perfly_pvals = NaN(n_flies, 1);
for f = 1:n_flies
    if ~all(isnan(null_centring(f, :)))
        perfly_pvals(f) = sum(null_centring(f, :) <= observed_centring(f)) / N_SHUF;
    end
end

% Population-level test
null_means = nanmean(null_centring, 1);  % mean across flies per shuffle
null_grand_mean = nanmean(null_means);
null_grand_sd = nanstd(null_means);
z_score = (obs_mean - null_grand_mean) / null_grand_sd;
% Empirical p-value
pop_pval = sum(null_means <= obs_mean) / N_SHUF;

fprintf('\n========================================\n');
fprintf('  NULL MODEL RESULTS\n');
fprintf('========================================\n');
fprintf('\nObserved centring:   %.1f ± %.1f mm (mean ± SEM, N=%d flies)\n', ...
    obs_mean, obs_sem, n_flies);
fprintf('Null centring:       %.1f ± %.1f mm (mean ± SD of shuffle means)\n', ...
    null_grand_mean, null_grand_sd);
fprintf('Z-score:             %.1f\n', z_score);
fprintf('Population p-value:  %.1e (empirical, %d shuffles)\n', pop_pval, N_SHUF);

n_valid = sum(~isnan(perfly_pvals));
n_sig = sum(perfly_pvals < 0.05);
fprintf('\nPer-fly results (N=%d valid):\n', n_valid);
fprintf('  Significant (p<0.05): %d/%d (%.0f%%)\n', n_sig, n_valid, 100*n_sig/n_valid);
fprintf('  Median p-value: %.4f\n', nanmedian(perfly_pvals));
fprintf('  Mean null centring per fly: %.1f mm\n', nanmean(nanmean(null_centring, 2)));

%% 5 — Figures

fig = figure('Position', [50 50 1400 450]);

% --- Panel A: Histogram of observed vs null ---
subplot(1, 3, 1);
hold on;

% Null distribution (mean across shuffles per fly)
null_mean_per_fly = nanmean(null_centring, 2);
histogram(null_mean_per_fly, 30, 'FaceColor', [0.85 0.85 0.85], ...
    'EdgeColor', 'w', 'FaceAlpha', 0.8);
histogram(observed_centring, 30, 'FaceColor', [0.22 0.42 0.69], ...
    'EdgeColor', 'w', 'FaceAlpha', 0.7);

xline(obs_mean, '-', 'Color', [0.22 0.42 0.69], 'LineWidth', 2);
xline(nanmean(null_mean_per_fly), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 2);

xlabel('Mean centring (mm)', 'FontSize', 14);
ylabel('Number of flies', 'FontSize', 14);
title('Observed vs Null', 'FontSize', 14);
legend({'Null (shuffled)', 'Observed', '', ''}, 'Box', 'off', 'FontSize', 9);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% --- Panel B: Timeseries with null envelope ---
subplot(1, 3, 2);
hold on;

% Null envelope (2.5th–97.5th percentile across shuffles)
null_lo = prctile(null_ts_all, 2.5, 1);
null_hi = prctile(null_ts_all, 97.5, 1);
null_med = nanmedian(null_ts_all, 1);
t_stim = (0:N_STIM) / FPS;  % time in seconds from stimulus onset

fill([t_stim, fliplr(t_stim)], [null_lo, fliplr(null_hi)], ...
    [0.85 0.85 0.85], 'EdgeColor', 'none', 'FaceAlpha', 0.6);
plot(t_stim, null_med, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

% Observed
obs_ts = nanmean(observed_dist_delta(:, STIM_ON:STIM_OFF), 1);
obs_ts_sem = nanstd(observed_dist_delta(:, STIM_ON:STIM_OFF), 0, 1) / sqrt(n_flies);
plot(t_stim, obs_ts, '-', 'Color', [0.22 0.42 0.69], 'LineWidth', 2);

xlabel('Time from stimulus onset (s)', 'FontSize', 14);
ylabel('Distance change (mm)', 'FontSize', 14);
title('Centring timeseries vs null 95% CI', 'FontSize', 14);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% --- Panel C: Per-fly observed vs null scatter ---
subplot(1, 3, 3);
hold on;

plot([-80 40], [-80 40], '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
scatter(observed_centring, null_mean_per_fly, 20, [0.22 0.42 0.69], ...
    'filled', 'MarkerFaceAlpha', 0.5);

xlabel('Observed centring (mm)', 'FontSize', 14);
ylabel('Mean null centring (mm)', 'FontSize', 14);
title('Per-fly: observed vs shuffled', 'FontSize', 14);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
axis equal;

sgtitle(sprintf('Heading-Shuffle Null Model (N=%d flies, %d shuffles)', ...
    n_flies, N_SHUF), 'FontSize', 16);

fprintf('\n=== Done ===\n');


%% ===== LOCAL HELPER FUNCTION =====

function [x_traj, y_traj, dist_traj] = reconstruct_trajectory_shuffled( ...
        x0, y0, theta0, dtheta_shuffled, speeds, CX, CY, ARENA_R)
% RECONSTRUCT_TRAJECTORY_SHUFFLED  Replay trajectory with shuffled heading changes.
%
%   Given a starting position, heading, shuffled heading changes, and speeds,
%   reconstruct the trajectory with boundary reflection at the arena wall.
%
%   Inputs:
%     x0, y0      - starting position (mm, arena-centered coordinates)
%     theta0       - starting heading (radians)
%     dtheta_shuffled - [1 × N] shuffled heading changes (radians)
%     speeds       - [1 × N] displacement per frame (mm)
%     CX, CY       - arena center (mm)
%     ARENA_R      - arena radius (mm)
%
%   Outputs:
%     x_traj, y_traj - [1 × N+1] reconstructed positions (mm)
%     dist_traj      - [1 × N+1] distance from arena center (mm)

    n = length(dtheta_shuffled);

    x_traj = zeros(1, n + 1);
    y_traj = zeros(1, n + 1);
    dist_traj = zeros(1, n + 1);

    x = x0;
    y = y0;
    theta = theta0;

    x_traj(1) = x;
    y_traj(1) = y;
    dist_traj(1) = sqrt((x - CX)^2 + (y - CY)^2);

    for i = 1:n
        % Update heading
        theta = theta + dtheta_shuffled(i);

        % Step forward
        spd = speeds(i);
        if isnan(spd), spd = 0; end

        x_new = x + spd * cos(theta);
        y_new = y + spd * sin(theta);

        % Boundary reflection: stay inside arena
        dist_from_center = sqrt((x_new - CX)^2 + (y_new - CY)^2);
        if dist_from_center >= ARENA_R
            % Reflect heading and stay at current position
            theta = theta + pi;
            x_new = x;
            y_new = y;
            dist_from_center = sqrt((x_new - CX)^2 + (y_new - CY)^2);
        end

        x = x_new;
        y = y_new;

        x_traj(i + 1) = x;
        y_traj(i + 1) = y;
        dist_traj(i + 1) = dist_from_center;
    end
end
