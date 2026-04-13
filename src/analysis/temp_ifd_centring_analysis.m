%% temp_ifd_centring_analysis — Does inter-fly distance predict centring?
%
% Tests whether flies closer to a neighbour centre more, using three
% complementary approaches:
%
%   Approach 2: Time-lagged within-fly analysis — at each (subsampled)
%               timepoint, record IFD and the subsequent change in distance
%               from centre over the next 2s.
%
%   Approach 3: Binned visualisation — bin timepoints by IFD quartile
%               and plot mean centring rate in each bin.
%
%   LMM:        delta_dist ~ IFD + dist_from_centre + (1 + IFD | fly_id)
%               Tests the IFD effect while controlling for position.
%
% TEMPORARY SCRIPT — safe to delete.
%
% Requires: DATA (Protocol 27), Statistics and Machine Learning Toolbox (fitlme)

%% 1 — Configuration & data loading

cfg = get_config();
protocol_dir = fullfile(cfg.results, 'protocol_27');

if ~exist('DATA', 'var') || isempty(fieldnames(DATA))
    fprintf('Loading Protocol 27 data from: %s\n', protocol_dir);
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

control_strain = 'jfrc100_es_shibire_kir';
sex = 'F';
cond_idx = 1;  % 60deg gratings 4Hz

FPS = 30;
ARENA_R = 120;

%% 2 — Extract QC-filtered data

fprintf('Extracting data for %s, condition %d...\n', control_strain, cond_idx);

data_ctrl = DATA.(control_strain).(sex);

ifd_all  = combine_timeseries_across_exp(data_ctrl, cond_idx, 'IFD_data');
dist_all = combine_timeseries_across_exp(data_ctrl, cond_idx, 'dist_data');
vel_all  = combine_timeseries_across_exp(data_ctrl, cond_idx, 'vel_data');

[n_flies, n_frames] = size(dist_all);
fprintf('  %d flies, %d frames\n', n_flies, n_frames);

%% 3 — Build time-lagged observation table
%
% At each subsampled timepoint t during the stimulus, record:
%   - fly_id
%   - IFD at time t
%   - dist from centre at time t
%   - delta_dist over the next LOOK_AHEAD seconds (positive = moved inward)
%   - velocity at time t (to exclude stationary moments)

STIM_ON  = 300;
STIM_OFF = 1200;
LOOK_AHEAD_FRAMES = 60;    % 2s at 30fps
SUBSAMPLE_STEP    = 30;    % sample every 1s to reduce autocorrelation
MIN_VEL           = 0.5;   % mm/s — exclude stationary timepoints

% Timepoints to sample: stimulus period, leaving room for look-ahead
t_samples = STIM_ON:SUBSAMPLE_STEP:(STIM_OFF - LOOK_AHEAD_FRAMES);
n_t = numel(t_samples);

fprintf('Building observation table: %d flies x %d timepoints...\n', n_flies, n_t);

% Preallocate
max_obs = n_flies * n_t;
obs_fly_id = zeros(max_obs, 1);
obs_ifd    = zeros(max_obs, 1);
obs_dist   = zeros(max_obs, 1);
obs_ddist  = zeros(max_obs, 1);
obs_vel    = zeros(max_obs, 1);
obs_t      = zeros(max_obs, 1);
obs_count  = 0;

for f = 1:n_flies
    for ti = 1:n_t
        t = t_samples(ti);
        t_end = t + LOOK_AHEAD_FRAMES;

        ifd_t  = ifd_all(f, t);
        dist_t = dist_all(f, t);
        vel_t  = vel_all(f, t);

        if isnan(ifd_t) || isnan(dist_t) || isnan(vel_t); continue; end
        if vel_t < MIN_VEL; continue; end  % skip stationary moments

        dist_future = nanmean(dist_all(f, t_end-5:t_end)); %#ok<NANMEAN>
        if isnan(dist_future); continue; end

        delta_dist = dist_t - dist_future;  % positive = moved towards centre

        obs_count = obs_count + 1;
        obs_fly_id(obs_count) = f;
        obs_ifd(obs_count)    = ifd_t;
        obs_dist(obs_count)   = dist_t;
        obs_ddist(obs_count)  = delta_dist;
        obs_vel(obs_count)    = vel_t;
        obs_t(obs_count)      = t;
    end
end

% Trim
obs_fly_id = obs_fly_id(1:obs_count);
obs_ifd    = obs_ifd(1:obs_count);
obs_dist   = obs_dist(1:obs_count);
obs_ddist  = obs_ddist(1:obs_count);
obs_vel    = obs_vel(1:obs_count);
obs_t      = obs_t(1:obs_count);

fprintf('  %d valid observations from %d flies\n', obs_count, numel(unique(obs_fly_id)));

%% 4 — Approach 3: Binned visualisation

% Bin by IFD quartiles
n_bins = 4;
edges = quantile(obs_ifd, linspace(0, 1, n_bins + 1));
edges(1) = edges(1) - 1;  % ensure all values included
edges(end) = edges(end) + 1;

bin_labels = cell(n_bins, 1);
bin_means  = NaN(n_bins, 1);
bin_sems   = NaN(n_bins, 1);
bin_centres = NaN(n_bins, 1);
bin_n       = zeros(n_bins, 1);

for bi = 1:n_bins
    in_bin = obs_ifd >= edges(bi) & obs_ifd < edges(bi+1);
    vals = obs_ddist(in_bin);
    bin_n(bi)       = numel(vals);
    bin_means(bi)   = mean(vals, 'omitnan');
    bin_sems(bi)    = std(vals, 'omitnan') / sqrt(bin_n(bi));
    bin_centres(bi) = mean([edges(bi), edges(bi+1)]);
    bin_labels{bi}  = sprintf('%.0f–%.0f mm\n(n=%d)', edges(bi), edges(bi+1), bin_n(bi));
end

% --- Figure 1: Binned centring by IFD quartile ---
figure('Position', [50 50 500 400], 'Name', 'Binned: Centring by IFD quartile');
hold on;
bar(1:n_bins, bin_means, 'FaceColor', [0.216 0.494 0.722], 'EdgeColor', [0.6 0.6 0.6], ...
    'LineWidth', 0.5, 'FaceAlpha', 0.6);
errorbar(1:n_bins, bin_means, bin_sems, 'k.', 'LineWidth', 1.5, 'CapSize', 6);
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
xticks(1:n_bins);
xticklabels(bin_labels);
xlabel('IFD bin (distance to nearest fly)', 'FontSize', 14);
ylabel('\Deltadist from centre (mm, +ve = inward)', 'FontSize', 14);
title(sprintf('Centring over next 2s by IFD quartile (n=%d obs)', obs_count), 'FontSize', 14);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% --- Figure 2: Scatter of delta_dist vs IFD, coloured by distance from centre ---
figure('Position', [50 50 600 450], 'Name', 'Scatter: delta_dist vs IFD');
scatter(obs_ifd, obs_ddist, 8, obs_dist, 'filled', 'MarkerFaceAlpha', 0.15);
colormap(gca, parula);
cb = colorbar;
cb.Label.String = 'Distance from centre (mm)';
cb.Label.FontSize = 12;
hold on;
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);

% Add binned mean trend
plot(bin_centres, bin_means, '-o', 'Color', [0.8 0.1 0.1], 'LineWidth', 2, ...
    'MarkerFaceColor', [0.8 0.1 0.1], 'MarkerSize', 6);

xlabel('IFD — distance to nearest fly (mm)', 'FontSize', 14);
ylabel('\Deltadist from centre over next 2s (mm)', 'FontSize', 14);
title('Centring vs IFD (coloured by position)', 'FontSize', 14);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% --- Figure 3: Binned centring by IFD, split by distance-from-centre tertile ---
dist_tertiles = quantile(obs_dist, [1/3, 2/3]);
dist_labels = {'Inner', 'Middle', 'Outer'};
dist_colors = [0.302 0.686 0.290; 0.216 0.494 0.722; 0.894 0.102 0.110];

figure('Position', [50 50 600 400], 'Name', 'Binned: Centring by IFD, split by position');
hold on;

for di = 1:3
    if di == 1
        pos_mask = obs_dist <= dist_tertiles(1);
    elseif di == 2
        pos_mask = obs_dist > dist_tertiles(1) & obs_dist <= dist_tertiles(2);
    else
        pos_mask = obs_dist > dist_tertiles(2);
    end

    bin_means_d = NaN(n_bins, 1);
    bin_sems_d  = NaN(n_bins, 1);

    for bi = 1:n_bins
        in_bin = pos_mask & obs_ifd >= edges(bi) & obs_ifd < edges(bi+1);
        vals = obs_ddist(in_bin);
        if numel(vals) >= 5
            bin_means_d(bi) = mean(vals, 'omitnan');
            bin_sems_d(bi)  = std(vals, 'omitnan') / sqrt(numel(vals));
        end
    end

    x_offset = (di - 2) * 0.2;  % slight horizontal offset for visibility
    errorbar((1:n_bins) + x_offset, bin_means_d, bin_sems_d, '-o', ...
        'Color', dist_colors(di, :), 'LineWidth', 2, ...
        'MarkerFaceColor', dist_colors(di, :), 'MarkerSize', 6, 'CapSize', 4);
end

yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
xticks(1:n_bins);
% Use IFD range only (no counts) since each line has different n
bin_range_labels = cell(n_bins, 1);
for bi = 1:n_bins
    bin_range_labels{bi} = sprintf('%.0f–%.0f mm', edges(bi), edges(bi+1));
end
xticklabels(bin_range_labels);
xlabel('IFD bin (distance to nearest fly)', 'FontSize', 14);
ylabel('\Deltadist from centre (mm, +ve = inward)', 'FontSize', 14);
title('Centring by IFD, split by distance from centre', 'FontSize', 14);
legend(dist_labels, 'Location', 'best', 'FontSize', 11);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

%% 5 — LMM: delta_dist ~ IFD + dist_from_centre + (1 + IFD | fly_id)

fprintf('\n=== Fitting LMM ===\n');

% Z-score predictors for numerical stability
ifd_z  = (obs_ifd - mean(obs_ifd)) / std(obs_ifd);
dist_z = (obs_dist - mean(obs_dist)) / std(obs_dist);

lmm_tbl = table( ...
    categorical(obs_fly_id), ...
    ifd_z, ...
    dist_z, ...
    obs_ddist, ...
    'VariableNames', {'fly_id', 'IFD', 'dist_centre', 'delta_dist'});

fprintf('  Table: %d rows, %d flies\n', height(lmm_tbl), numel(unique(obs_fly_id)));

% Full model with random intercept + slope on IFD per fly
formula_full = 'delta_dist ~ 1 + IFD + dist_centre + (1 + IFD | fly_id)';
fprintf('  Fitting: %s\n', formula_full);

mdl = fitlme(lmm_tbl, formula_full);
disp(mdl);

fe = fixedEffects(mdl);
[~, ~, fe_stats] = fixedEffects(mdl, 'DFMethod', 'satterthwaite');

fprintf('\n--- Fixed Effects (Satterthwaite df) ---\n');
fprintf('  %-15s  Estimate    SE        t        p             95%% CI\n', '');
for fi = 1:numel(fe)
    fprintf('  %-15s  %+8.4f   %7.4f   %+6.2f   %.3e   [%+.4f, %+.4f]\n', ...
        fe_stats.Name{fi}, fe_stats.Estimate(fi), fe_stats.SE(fi), ...
        fe_stats.tStat(fi), fe_stats.pValue(fi), ...
        fe_stats.Lower(fi), fe_stats.Upper(fi));
end

% Random effects
[~, ~, re_stats] = randomEffects(mdl);
re_int = re_stats.Estimate(strcmp(re_stats.Name, '(Intercept)'));
re_slp = re_stats.Estimate(strcmp(re_stats.Name, 'IFD'));
n_flies_re = numel(re_int);

fprintf('\n  Random effect SDs: intercept=%.4f, IFD slope=%.4f\n', ...
    std(re_int), std(re_slp));

%% 6 — LMM visualisation

% --- Figure 4: Per-fly LMM predicted lines + population line ---
% Plot effect of IFD (at mean dist_from_centre, i.e. dist_z=0)

x_pred_z = linspace(min(ifd_z), max(ifd_z), 100)';
x_pred_raw = x_pred_z * std(obs_ifd) + mean(obs_ifd);  % for x-axis labels

col_fly = [0.216 0.494 0.722];
col_pop = [0.10 0.25 0.54];

figure('Position', [50 50 750 550], 'Name', 'LMM: delta_dist vs IFD');
hold on;

% Per-fly lines (at mean distance, dist_z=0)
for fi = 1:n_flies_re
    y_fly = (fe(1) + re_int(fi)) + (fe(2) + re_slp(fi)) * x_pred_z;
    plot(x_pred_raw, y_fly, '-', 'Color', [col_fly 0.12], 'LineWidth', 0.8);
end

% Population line
y_pop = fe(1) + fe(2) * x_pred_z;  % dist_centre = 0 (mean)
plot(x_pred_raw, y_pop, '-', 'Color', col_pop, 'LineWidth', 3);

% 95% CI on population line
% Variance from intercept and IFD slope only (dist_centre held at 0)
cov_fe = mdl.CoefficientCovariance;
var_pred = cov_fe(1,1) + x_pred_z.^2 * cov_fe(2,2) + 2 * x_pred_z * cov_fe(1,2);
se_pred = sqrt(var_pred);
fill([x_pred_raw; flipud(x_pred_raw)], ...
    [y_pop + 1.96*se_pred; flipud(y_pop - 1.96*se_pred)], ...
    col_fly, 'FaceAlpha', 0.2, 'EdgeColor', 'none');

yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
xlim([min(x_pred_raw) max(x_pred_raw)]);
xlabel('IFD — distance to nearest fly (mm)', 'FontSize', 14);
ylabel('\Deltadist from centre over next 2s (mm)', 'FontSize', 14);
title(sprintf('LMM: centring vs IFD (controlling for position)\nIFD slope = %.4f [%.4f, %.4f], p = %.2e', ...
    fe_stats.Estimate(2), fe_stats.Lower(2), fe_stats.Upper(2), fe_stats.pValue(2)), ...
    'FontSize', 14);
text(min(x_pred_raw) + 5, max(ylim) * 0.9, ...
    sprintf('Fixed: IFD slope=%.4f (p=%.2e)\n         dist slope=%.4f (p=%.2e)\nRandom slope SD: %.4f\nn=%d obs, %d flies', ...
    fe(2), fe_stats.pValue(2), fe(3), fe_stats.pValue(3), ...
    std(re_slp), obs_count, n_flies_re), ...
    'FontSize', 10, 'FontWeight', 'bold', 'VerticalAlignment', 'top');
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% --- Figure 5: Distribution of per-fly IFD slopes ---
figure('Position', [50 50 400 350], 'Name', 'Per-fly IFD slope distribution');
histogram(re_slp, 20, 'FaceColor', [0.216 0.494 0.722], 'EdgeColor', 'w', 'FaceAlpha', 0.6);
hold on;
xline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(mean(re_slp), '-', 'Color', [0.8 0.1 0.1], 'LineWidth', 2);
xlabel('Per-fly IFD slope (random effect)', 'FontSize', 14);
ylabel('Count', 'FontSize', 14);
title('Distribution of per-fly IFD slopes', 'FontSize', 14);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

[p_wil, ~] = signrank(re_slp);
fprintf('\n  Wilcoxon signed-rank test on per-fly slopes: p = %.3e\n', p_wil);
fprintf('  Mean slope: %.4f, Median: %.4f\n', mean(re_slp), median(re_slp));
fprintf('  %d/%d flies have negative slope (more centring when IFD is smaller)\n', ...
    sum(re_slp < 0), n_flies_re);

fprintf('\n=== Analysis complete ===\n');
