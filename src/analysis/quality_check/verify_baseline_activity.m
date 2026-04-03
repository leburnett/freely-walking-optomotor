%% VERIFY_BASELINE_ACTIVITY - Assess whether baseline locomotor activity
% predicts QC rejection rates across strains
%
% Determines whether the 8 high-rejection strains (>20% QC rejection in
% stimulus conditions) have genuinely different baseline locomotor activity
% during the pre-stimulus acclimation periods.
%
% Acclimation periods analysed:
%   acclim_off1 — Dark period before any light stimulation (~300s, last 20s used)
%   acclim_patt — Short period with full-field flashes before stimuli begin
%
% QC thresholds (applied per-fly, per-condition, per-rep during stimulus):
%   1. mean(fv) < 3 mm/s  — fly not walking
%   2. min(dist) > 110 mm — fly stuck near edge
%
% NOTE: QC is NOT applied during acclimation. This script examines whether
% acclimation behaviour predicts which strains will fail QC during stimuli.
%
% OUTPUTS:
%   - Multi-panel figure comparing baseline activity across strain groups
%   - Statistical test results (Kruskal-Wallis, pairwise rank-sum)
%   - Summary table linking baseline stats to rejection rates
%   - CSV export: baseline_vs_rejection_summary.csv
%
% USAGE:
%   Run after setup_path.m. Requires Protocol 27 data.
%   If DATA is already in the workspace it will be reused (saves time).
%
% See also: verify_qc_thresholds, plot_fv_acclim, check_and_average_across_reps

%% 1 - Configuration

FV_THRESHOLD  = 3;      % mm/s — matches check_and_average_across_reps line 43
DIST_THRESHOLD = 110;   % mm   — matches check_and_average_across_reps line 43
N_FRAMES = 600;         % Pad/truncate acclimation data to 600 frames (20s at 30fps)
FPS = 30;
N_CONDITIONS = 12;      % Protocol 27 has 12 conditions
CONTROL_STRAIN = 'jfrc100_es_shibire_kir';
sex = 'F';

cfg = get_config();
protocol_dir = fullfile(cfg.results, 'protocol_27');
assert(isfolder(protocol_dir), ...
    'Protocol 27 directory not found: %s\nCheck cfg.project_root in get_config.m', protocol_dir);

% Load DATA (reuse from workspace if available)
if exist('DATA', 'var') && isstruct(DATA) && ~isempty(fieldnames(DATA))
    fprintf('Using existing DATA variable from workspace.\n');
else
    fprintf('Loading Protocol 27 data from: %s\n', protocol_dir);
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end
assert(~isempty(fieldnames(DATA)), 'DATA is empty');

strain_names = fieldnames(DATA);
n_strains = numel(strain_names);

save_folder = fullfile(cfg.figures, 'FIGS');
if ~isfolder(save_folder); mkdir(save_folder); end

%% 2 - Extract acclimation data for all strains

fprintf('Extracting baseline acclimation data...\n');
baseline = struct();

for s = 1:n_strains
    strain = strain_names{s};
    if ~isfield(DATA.(strain), sex); continue; end
    data = DATA.(strain).(sex);
    n_exp = length(data);

    fv_off1_all  = [];
    dist_off1_all = [];
    fv_patt_all  = [];
    dist_patt_all = [];

    for exp_idx = 1:n_exp
        % --- acclim_off1 ---
        if isfield(data(exp_idx), 'acclim_off1') && ~isempty(data(exp_idx).acclim_off1)
            raw_fv = data(exp_idx).acclim_off1.fv_data;
            raw_dist = data(exp_idx).acclim_off1.dist_data;
            fv_off1_all  = vertcat(fv_off1_all,  pad_or_truncate(raw_fv, N_FRAMES));
            dist_off1_all = vertcat(dist_off1_all, pad_or_truncate(raw_dist, N_FRAMES));
        end

        % --- acclim_patt ---
        if isfield(data(exp_idx), 'acclim_patt') && ~isempty(data(exp_idx).acclim_patt)
            raw_fv = data(exp_idx).acclim_patt.fv_data;
            raw_dist = data(exp_idx).acclim_patt.dist_data;
            fv_patt_all  = vertcat(fv_patt_all,  pad_or_truncate(raw_fv, N_FRAMES));
            dist_patt_all = vertcat(dist_patt_all, pad_or_truncate(raw_dist, N_FRAMES));
        end
    end

    % Store timeseries
    baseline.(strain).fv_off1  = fv_off1_all;
    baseline.(strain).dist_off1 = dist_off1_all;
    baseline.(strain).fv_patt  = fv_patt_all;
    baseline.(strain).dist_patt = dist_patt_all;

    % Per-fly summary stats (from acclim_off1)
    baseline.(strain).mean_fv_per_fly  = nanmean(fv_off1_all, 2);
    baseline.(strain).mean_dist_per_fly = nanmean(dist_off1_all, 2);
    baseline.(strain).n_flies = size(fv_off1_all, 1);
    baseline.(strain).pct_below_fv = 100 * mean(nanmean(fv_off1_all, 2) < FV_THRESHOLD);
    baseline.(strain).pct_above_dist = 100 * mean(nanmin(dist_off1_all, [], 2) > DIST_THRESHOLD);
end

fprintf('Baseline data extracted for %d strains.\n', n_strains);

%% 3 - Compute rejection rates inline (self-contained)

fprintf('Computing per-strain QC rejection rates from stimulus conditions...\n');
reject_rates = nan(n_strains, 1);

for s = 1:n_strains
    strain = strain_names{s};
    if ~isfield(DATA.(strain), sex); continue; end
    data = DATA.(strain).(sex);
    n_exp = length(data);
    n_total = 0;
    n_rejected = 0;

    for exp_idx = 1:n_exp
        for cond = 1:N_CONDITIONS
            for rep = 1:2
                rep_str = strcat('R', string(rep), '_condition_', string(cond));
                if ~isfield(data(exp_idx), rep_str); continue; end
                rep_data = data(exp_idx).(rep_str);
                if isempty(rep_data); continue; end

                fv = rep_data.fv_data;
                dist = rep_data.dist_data;
                for fly = 1:size(fv, 1)
                    n_total = n_total + 1;
                    mfv = mean(fv(fly, :), 'omitnan');
                    mdist = min(dist(fly, :), [], 'omitnan');
                    if mfv < FV_THRESHOLD || mdist > DIST_THRESHOLD
                        n_rejected = n_rejected + 1;
                    end
                end
            end
        end
    end
    if n_total > 0
        reject_rates(s) = 100 * n_rejected / n_total;
    end
end

%% 4 - Build combined summary table

row_strain = {};
row_nflies = [];
row_mean_fv = [];
row_median_fv = [];
row_mean_dist = [];
row_pct_below_fv = [];
row_pct_above_dist = [];
row_reject_rate = [];
row_group = {};

for s = 1:n_strains
    strain = strain_names{s};
    if ~isfield(baseline, strain); continue; end

    row_strain{end+1, 1} = strain;
    row_nflies(end+1, 1) = baseline.(strain).n_flies;
    row_mean_fv(end+1, 1) = round(nanmean(baseline.(strain).mean_fv_per_fly), 2);
    row_median_fv(end+1, 1) = round(nanmedian(baseline.(strain).mean_fv_per_fly), 2);
    row_mean_dist(end+1, 1) = round(nanmean(baseline.(strain).mean_dist_per_fly), 1);
    row_pct_below_fv(end+1, 1) = round(baseline.(strain).pct_below_fv, 1);
    row_pct_above_dist(end+1, 1) = round(baseline.(strain).pct_above_dist, 1);
    row_reject_rate(end+1, 1) = round(reject_rates(s), 1);

    if strcmp(strain, CONTROL_STRAIN)
        row_group{end+1, 1} = 'control';
    elseif reject_rates(s) > 20
        row_group{end+1, 1} = 'high_reject';
    else
        row_group{end+1, 1} = 'other';
    end
end

combined_table = table(row_strain, row_nflies, row_mean_fv, row_median_fv, ...
    row_mean_dist, row_pct_below_fv, row_pct_above_dist, row_reject_rate, row_group, ...
    'VariableNames', {'Strain', 'N_Flies', 'MeanFV', 'MedianFV', 'MeanDist', ...
     'PctBelowFV', 'PctAboveDist', 'PctRejected', 'Group'});

combined_table = sortrows(combined_table, 'PctRejected', 'descend');

disp('=== Baseline Activity vs QC Rejection Summary ===');
disp(combined_table);

%% 5 - Statistical tests

fprintf('\n=== Statistical Tests ===\n');

% 5A: Kruskal-Wallis across all strains (omnibus)
all_fv_vals = [];
all_fv_labels = {};
all_dist_vals = [];
all_dist_labels = {};

for s = 1:n_strains
    strain = strain_names{s};
    if ~isfield(baseline, strain); continue; end
    vals_fv = baseline.(strain).mean_fv_per_fly;
    vals_dist = baseline.(strain).mean_dist_per_fly;
    all_fv_vals = [all_fv_vals; vals_fv];
    all_fv_labels = [all_fv_labels; repmat({strain}, numel(vals_fv), 1)];
    all_dist_vals = [all_dist_vals; vals_dist];
    all_dist_labels = [all_dist_labels; repmat({strain}, numel(vals_dist), 1)];
end

[p_kw_fv, ~, stats_kw_fv] = kruskalwallis(all_fv_vals, all_fv_labels, 'off');
[p_kw_dist, ~, stats_kw_dist] = kruskalwallis(all_dist_vals, all_dist_labels, 'off');

fprintf('Kruskal-Wallis (baseline FV across strains):   p = %.4g\n', p_kw_fv);
fprintf('Kruskal-Wallis (baseline dist across strains): p = %.4g\n', p_kw_dist);

% 5B: Pairwise rank-sum tests (each strain vs control) + effect sizes
control_fv = baseline.(CONTROL_STRAIN).mean_fv_per_fly;
control_dist = baseline.(CONTROL_STRAIN).mean_dist_per_fly;

pvals_fv = nan(n_strains, 1);
pvals_dist = nan(n_strains, 1);
cohens_d_fv = nan(n_strains, 1);
cohens_d_dist = nan(n_strains, 1);

for s = 1:n_strains
    strain = strain_names{s};
    if strcmp(strain, CONTROL_STRAIN); continue; end
    if ~isfield(baseline, strain); continue; end

    test_fv = baseline.(strain).mean_fv_per_fly;
    test_dist = baseline.(strain).mean_dist_per_fly;

    pvals_fv(s) = ranksum(test_fv, control_fv);
    pvals_dist(s) = ranksum(test_dist, control_dist);

    % Cohen's d (pooled SD)
    cohens_d_fv(s) = compute_cohens_d(test_fv, control_fv);
    cohens_d_dist(s) = compute_cohens_d(test_dist, control_dist);
end

% FDR correction
valid_idx = find(~isnan(pvals_fv));
[h_fv, ~, adj_p_fv] = fdr_bh(pvals_fv(valid_idx), 0.05, 'pdep');
[h_dist, ~, adj_p_dist] = fdr_bh(pvals_dist(valid_idx), 0.05, 'pdep');

% Map adjusted p-values back
adj_pvals_fv = nan(n_strains, 1);
adj_pvals_dist = nan(n_strains, 1);
sig_fv = false(n_strains, 1);
sig_dist = false(n_strains, 1);
adj_pvals_fv(valid_idx) = adj_p_fv;
adj_pvals_dist(valid_idx) = adj_p_dist;
sig_fv(valid_idx) = h_fv;
sig_dist(valid_idx) = h_dist;

% 5C: Spearman correlation — baseline metrics vs rejection rate
strain_mean_fv_vec = nan(n_strains, 1);
strain_mean_dist_vec = nan(n_strains, 1);
for s = 1:n_strains
    strain = strain_names{s};
    if ~isfield(baseline, strain); continue; end
    strain_mean_fv_vec(s) = nanmean(baseline.(strain).mean_fv_per_fly);
    strain_mean_dist_vec(s) = nanmean(baseline.(strain).mean_dist_per_fly);
end

valid_corr = ~isnan(reject_rates) & ~isnan(strain_mean_fv_vec);
[rho_fv, p_rho_fv] = corr(strain_mean_fv_vec(valid_corr), reject_rates(valid_corr), 'Type', 'Spearman');
[rho_dist, p_rho_dist] = corr(strain_mean_dist_vec(valid_corr), reject_rates(valid_corr), 'Type', 'Spearman');

fprintf('\nSpearman correlation (baseline FV vs rejection):   rho = %.3f, p = %.4g\n', rho_fv, p_rho_fv);
fprintf('Spearman correlation (baseline dist vs rejection): rho = %.3f, p = %.4g\n', rho_dist, p_rho_dist);

% 5D: Print per-strain pairwise results
fprintf('\n=== Pairwise Tests vs Control (FDR-corrected) ===\n');
fprintf('%-35s  %6s  %8s  %8s  %6s  %8s  %8s  %8s\n', ...
    'Strain', 'N', 'FV_p', 'FV_padj', 'FV_d', 'Dist_p', 'Dist_padj', 'Dist_d');
fprintf('%s\n', repmat('-', 1, 105));

for s = 1:n_strains
    strain = strain_names{s};
    if strcmp(strain, CONTROL_STRAIN); continue; end
    if ~isfield(baseline, strain); continue; end

    sig_marker_fv = '';
    sig_marker_dist = '';
    if sig_fv(s); sig_marker_fv = ' *'; end
    if sig_dist(s); sig_marker_dist = ' *'; end

    fprintf('%-35s  %6d  %8.4f  %8.4f%s  %+6.2f  %8.4f  %8.4f%s  %+6.2f\n', ...
        strain, baseline.(strain).n_flies, ...
        pvals_fv(s), adj_pvals_fv(s), sig_marker_fv, cohens_d_fv(s), ...
        pvals_dist(s), adj_pvals_dist(s), sig_marker_dist, cohens_d_dist(s));
end
fprintf('* = significant after FDR correction (q < 0.05)\n');

% 5E: Interpretation
fprintf('\n=== Interpretation ===\n');
high_reject_mask = reject_rates > 20 & ~strcmp(strain_names, CONTROL_STRAIN);
n_high_sig_fv = sum(sig_fv & high_reject_mask);
n_high_sig_dist = sum(sig_dist & high_reject_mask);
n_high = sum(high_reject_mask);

fprintf('%d of %d high-rejection strains have significantly different baseline FV\n', n_high_sig_fv, n_high);
fprintf('%d of %d high-rejection strains have significantly different baseline distance\n', n_high_sig_dist, n_high);

if abs(rho_fv) > 0.5 && p_rho_fv < 0.05
    fprintf('>> STRONG correlation between baseline FV and rejection rate.\n');
    fprintf('   Suggests QC rejections partly reflect intrinsic locomotor differences.\n');
    fprintf('   Consider: within-fly normalization (delta from baseline) for downstream analyses.\n');
elseif p_rho_fv < 0.05
    fprintf('>> MODERATE correlation between baseline FV and rejection rate.\n');
    fprintf('   Some strains may have lower baseline activity contributing to rejections.\n');
else
    fprintf('>> NO significant correlation between baseline FV and rejection rate.\n');
    fprintf('   Rejections are likely stimulus-specific, not due to intrinsic locomotor deficits.\n');
end

%% 6 - Plots

figure('Name', 'Baseline Activity vs QC Rejection', 'Position', [50 50 1600 1000]);

% Strain ordering: sorted by rejection rate (highest first)
[~, sort_idx] = sortrows(reject_rates, 'descend');
sorted_strains = strain_names(sort_idx);
sorted_reject = reject_rates(sort_idx);

% Assign colors: red = high-reject, black = control, gray = other
strain_colors = zeros(n_strains, 3);
for s = 1:n_strains
    strain = sorted_strains{s};
    if strcmp(strain, CONTROL_STRAIN)
        strain_colors(s, :) = [0.2 0.6 0.2];  % green for control
    elseif sorted_reject(s) > 20
        strain_colors(s, :) = [0.8 0.2 0.2];  % red for high-reject
    else
        strain_colors(s, :) = [0.5 0.5 0.5];  % gray for others
    end
end

% --- Panel A: Box plots of per-fly mean FV during acclim_off1 ---
subplot(2, 3, 1);
hold on;
for s = 1:n_strains
    strain = sorted_strains{s};
    if ~isfield(baseline, strain); continue; end
    vals = baseline.(strain).mean_fv_per_fly;
    x_jitter = s + 0.15 * (rand(numel(vals), 1) - 0.5);
    scatter(x_jitter, vals, 6, strain_colors(s, :), 'filled', 'MarkerFaceAlpha', 0.3);

    % Box plot elements (median, quartiles)
    q25 = prctile(vals, 25);
    q75 = prctile(vals, 75);
    med = nanmedian(vals);
    plot([s-0.2 s+0.2], [med med], '-', 'Color', strain_colors(s, :), 'LineWidth', 2);
    plot([s s], [q25 q75], '-', 'Color', strain_colors(s, :), 'LineWidth', 1.5);
end
yline(FV_THRESHOLD, 'r--', 'QC threshold', 'LineWidth', 1, 'LabelHorizontalAlignment', 'left');
xticks(1:n_strains);
xticklabels(strrep(sorted_strains, '_', ' '));
xtickangle(60);
ylabel('Mean forward velocity (mm/s)');
title('Baseline FV (acclim\_off1)');
set(gca, 'FontSize', 7, 'TickDir', 'out');
box off;
hold off;

% --- Panel B: Box plots of per-fly mean distance during acclim_off1 ---
subplot(2, 3, 2);
hold on;
for s = 1:n_strains
    strain = sorted_strains{s};
    if ~isfield(baseline, strain); continue; end
    vals = baseline.(strain).mean_dist_per_fly;
    x_jitter = s + 0.15 * (rand(numel(vals), 1) - 0.5);
    scatter(x_jitter, vals, 6, strain_colors(s, :), 'filled', 'MarkerFaceAlpha', 0.3);

    q25 = prctile(vals, 25);
    q75 = prctile(vals, 75);
    med = nanmedian(vals);
    plot([s-0.2 s+0.2], [med med], '-', 'Color', strain_colors(s, :), 'LineWidth', 2);
    plot([s s], [q25 q75], '-', 'Color', strain_colors(s, :), 'LineWidth', 1.5);
end
yline(DIST_THRESHOLD, 'r--', 'QC threshold', 'LineWidth', 1, 'LabelHorizontalAlignment', 'left');
xticks(1:n_strains);
xticklabels(strrep(sorted_strains, '_', ' '));
xtickangle(60);
ylabel('Mean distance from centre (mm)');
title('Baseline distance (acclim\_off1)');
set(gca, 'FontSize', 7, 'TickDir', 'out');
box off;
hold off;

% --- Panel C: Scatter — baseline FV vs rejection rate ---
subplot(2, 3, 3);
hold on;
for s = 1:n_strains
    strain = sorted_strains{s};
    if ~isfield(baseline, strain); continue; end
    x_val = nanmean(baseline.(strain).mean_fv_per_fly);
    y_val = sorted_reject(s);
    scatter(x_val, y_val, 50, strain_colors(s, :), 'filled');
end
yline(20, 'k--', '20%', 'LineWidth', 0.8);
xlabel('Mean baseline FV (mm/s)');
ylabel('QC rejection rate (%)');
title(sprintf('Baseline FV vs rejection (\\rho=%.2f, p=%.3f)', rho_fv, p_rho_fv));
set(gca, 'FontSize', 9, 'TickDir', 'out');
box off;

% Add regression line if significant
if p_rho_fv < 0.05
    x_all = strain_mean_fv_vec(valid_corr);
    y_all = reject_rates(valid_corr);
    p_fit = polyfit(x_all, y_all, 1);
    x_line = linspace(min(x_all), max(x_all), 100);
    plot(x_line, polyval(p_fit, x_line), 'k-', 'LineWidth', 1);
end
hold off;

% --- Panel D: Scatter — baseline distance vs rejection rate ---
subplot(2, 3, 4);
hold on;
for s = 1:n_strains
    strain = sorted_strains{s};
    if ~isfield(baseline, strain); continue; end
    x_val = nanmean(baseline.(strain).mean_dist_per_fly);
    y_val = sorted_reject(s);
    scatter(x_val, y_val, 50, strain_colors(s, :), 'filled');
end
yline(20, 'k--', '20%', 'LineWidth', 0.8);
xlabel('Mean baseline distance (mm)');
ylabel('QC rejection rate (%)');
title(sprintf('Baseline dist vs rejection (\\rho=%.2f, p=%.3f)', rho_dist, p_rho_dist));
set(gca, 'FontSize', 9, 'TickDir', 'out');
box off;

if p_rho_dist < 0.05
    x_all = strain_mean_dist_vec(valid_corr);
    y_all = reject_rates(valid_corr);
    p_fit = polyfit(x_all, y_all, 1);
    x_line = linspace(min(x_all), max(x_all), 100);
    plot(x_line, polyval(p_fit, x_line), 'k-', 'LineWidth', 1);
end
hold off;

% --- Panel E: Timeseries — FV during acclim_off1 (3 groups) ---
subplot(2, 3, 5);
hold on;
t_sec = (1:N_FRAMES) / FPS;

[mean_hr_fv, sem_hr_fv] = group_timeseries(baseline, strain_names, reject_rates, ...
    'fv_off1', 'high_reject', CONTROL_STRAIN);
[mean_ctrl_fv, sem_ctrl_fv] = group_timeseries(baseline, strain_names, reject_rates, ...
    'fv_off1', 'control', CONTROL_STRAIN);
[mean_other_fv, sem_other_fv] = group_timeseries(baseline, strain_names, reject_rates, ...
    'fv_off1', 'other', CONTROL_STRAIN);

% Smooth with moving average (matches plot_fv_acclim.m convention)
mean_hr_fv = movmean(mean_hr_fv, 5);
mean_ctrl_fv = movmean(mean_ctrl_fv, 5);
mean_other_fv = movmean(mean_other_fv, 5);

plot_shaded(t_sec, mean_other_fv, sem_other_fv, [0.7 0.7 0.7]);
plot_shaded(t_sec, mean_hr_fv, sem_hr_fv, [0.8 0.2 0.2]);
plot_shaded(t_sec, mean_ctrl_fv, sem_ctrl_fv, [0.2 0.6 0.2]);

yline(FV_THRESHOLD, 'r:', 'LineWidth', 0.8);
xlabel('Time (s)');
ylabel('Forward velocity (mm/s)');
title('FV timeseries (acclim\_off1)');
legend({'Other strains', '', '', 'High-reject', '', '', 'Control', '', ''}, ...
    'Location', 'best', 'FontSize', 7);
set(gca, 'FontSize', 9, 'TickDir', 'out');
box off;
hold off;

% --- Panel F: Timeseries — distance during acclim_off1 (3 groups) ---
subplot(2, 3, 6);
hold on;

[mean_hr_dist, sem_hr_dist] = group_timeseries(baseline, strain_names, reject_rates, ...
    'dist_off1', 'high_reject', CONTROL_STRAIN);
[mean_ctrl_dist, sem_ctrl_dist] = group_timeseries(baseline, strain_names, reject_rates, ...
    'dist_off1', 'control', CONTROL_STRAIN);
[mean_other_dist, sem_other_dist] = group_timeseries(baseline, strain_names, reject_rates, ...
    'dist_off1', 'other', CONTROL_STRAIN);

plot_shaded(t_sec, mean_other_dist, sem_other_dist, [0.7 0.7 0.7]);
plot_shaded(t_sec, mean_hr_dist, sem_hr_dist, [0.8 0.2 0.2]);
plot_shaded(t_sec, mean_ctrl_dist, sem_ctrl_dist, [0.2 0.6 0.2]);

yline(DIST_THRESHOLD, 'r:', 'LineWidth', 0.8);
xlabel('Time (s)');
ylabel('Distance from centre (mm)');
title('Distance timeseries (acclim\_off1)');
legend({'Other strains', '', '', 'High-reject', '', '', 'Control', '', ''}, ...
    'Location', 'best', 'FontSize', 7);
set(gca, 'FontSize', 9, 'TickDir', 'out');
box off;
hold off;

sgtitle('Baseline Activity vs QC Rejection — Protocol 27', 'FontSize', 14);

%% 7 - Export

writetable(combined_table, fullfile(save_folder, 'baseline_vs_rejection_summary.csv'));
fprintf('\nSummary table saved to: %s\n', fullfile(save_folder, 'baseline_vs_rejection_summary.csv'));

% Uncomment to save figure:
% savefig(fullfile(save_folder, 'baseline_activity_verification.fig'));
% exportgraphics(gcf, fullfile(save_folder, 'baseline_activity_verification.pdf'), 'ContentType', 'vector');
% fprintf('Figure saved to: %s\n', save_folder);

%% === Local Functions ===

function out = pad_or_truncate(data, n_frames)
    % Pad with NaN or truncate to n_frames columns
    % Matches pattern from plot_fv_acclim.m lines 26-31
    if size(data, 2) < n_frames
        out = nan(size(data, 1), n_frames);
        out(:, 1:size(data, 2)) = data;
    else
        out = data(:, 1:n_frames);
    end
end

function d = compute_cohens_d(group1, group2)
    % Cohen's d with pooled standard deviation
    n1 = numel(group1);
    n2 = numel(group2);
    pooled_sd = sqrt(((n1-1)*nanvar(group1) + (n2-1)*nanvar(group2)) / (n1 + n2 - 2));
    if pooled_sd == 0
        d = 0;
    else
        d = (nanmean(group1) - nanmean(group2)) / pooled_sd;
    end
end

function [mean_ts, sem_ts] = group_timeseries(baseline, strain_names, reject_rates, field, group_type, control_strain)
    % Pool timeseries across strains belonging to a group
    % group_type: 'high_reject', 'control', or 'other'
    all_data = [];
    for s = 1:numel(strain_names)
        strain = strain_names{s};
        if ~isfield(baseline, strain); continue; end

        is_ctrl = strcmp(strain, control_strain);
        is_high = reject_rates(s) > 20 && ~is_ctrl;

        include = false;
        switch group_type
            case 'control'
                include = is_ctrl;
            case 'high_reject'
                include = is_high;
            case 'other'
                include = ~is_ctrl && ~is_high;
        end

        if include
            all_data = vertcat(all_data, baseline.(strain).(field)); %#ok<AGROW>
        end
    end

    mean_ts = nanmean(all_data, 1);
    sem_ts = nanstd(all_data, 0, 1) / sqrt(size(all_data, 1));
end

function plot_shaded(x, mean_data, sem_data, col)
    % Plot mean with SEM shading (matches plot_fv_acclim.m pattern)
    y1 = mean_data + sem_data;
    y2 = mean_data - sem_data;
    patch([x fliplr(x)], [y1 fliplr(y2)], col, 'FaceAlpha', 0.15, 'EdgeColor', 'none');
    plot(x, mean_data, 'Color', col, 'LineWidth', 1.5);
end
