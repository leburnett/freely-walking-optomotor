%% VERIFY_QC_THRESHOLDS - Assess QC filtering impact across strains and conditions
%
% Analyses how the two QC thresholds in check_and_average_across_reps.m
% affect data retention:
%   1. mean(fv) < 3 mm/s  — fly not walking
%   2. min(dist) > 110 mm — fly stuck near edge
%
% QC is applied per-fly, per-condition, per-rep. This means a fly can
% pass QC for one condition (e.g., gratings) but fail for another
% (e.g., static/flicker) within the same experiment.
%
% OUTPUTS:
%   - Per-strain summary table: total flies, rejected flies, % rejected
%   - Per-condition rejection rates across all strains
%   - Distribution plots of mean fv and min dist relative to thresholds
%   - Flags strains with >20% rejection rate
%
% USAGE:
%   Run after setup_path.m. Requires Protocol 27 data.
%
% See also: check_and_average_across_reps, generate_strain_metadata_table

%% 1 - Configuration

FV_THRESHOLD = 3.0;     % mm/s — same as check_and_average_across_reps line 43
DIST_THRESHOLD = 110;   % mm — same as check_and_average_across_reps line 43
N_CONDITIONS = 12;       % Protocol 27 has 12 conditions

cfg = get_config();
protocol_dir = fullfile(cfg.results, 'protocol_27');
assert(isfolder(protocol_dir), ...
    'Protocol 27 directory not found: %s\nCheck cfg.project_root in get_config.m', protocol_dir);

fprintf('Loading Protocol 27 data from: %s\n', protocol_dir);
DATA = comb_data_across_cohorts_cond(protocol_dir);
assert(~isempty(fieldnames(DATA)), 'DATA is empty');

%% 2 - Extract QC metrics for every fly x condition x rep

strain_names = fieldnames(DATA);
n_strains = numel(strain_names);
sex = 'F';

% Collect all QC metrics into a big table
all_rows = {};

for s = 1:n_strains
    strain = strain_names{s};
    if ~isfield(DATA.(strain), sex); continue; end
    data = DATA.(strain).(sex);
    n_exp = length(data);

    for exp_idx = 1:n_exp
        for cond = 1:N_CONDITIONS
            for rep = 1:2
                if rep == 1
                    rep_str = strcat('R1_condition_', string(cond));
                else
                    rep_str = strcat('R2_condition_', string(cond));
                end

                if ~isfield(data(exp_idx), rep_str); continue; end
                rep_data = data(exp_idx).(rep_str);
                if isempty(rep_data); continue; end

                fv = rep_data.fv_data;       % [n_flies x n_frames]
                dist = rep_data.dist_data;   % [n_flies x n_frames]
                n_flies = size(fv, 1);

                for fly = 1:n_flies
                    mean_fv = mean(fv(fly, :), 'omitnan');
                    min_dist = min(dist(fly, :), [], 'omitnan');

                    fail_fv = mean_fv < FV_THRESHOLD;
                    fail_dist = min_dist > DIST_THRESHOLD;
                    rejected = fail_fv || fail_dist;

                    all_rows{end+1, 1} = {strain, cond, rep, exp_idx, fly, ...
                        mean_fv, min_dist, fail_fv, fail_dist, rejected}; %#ok<SAGROW>
                end
            end
        end
    end
end

% Flatten into a table
all_data = vertcat(all_rows{:});
qc_table = cell2table(all_data, 'VariableNames', ...
    {'Strain', 'Condition', 'Rep', 'Cohort', 'Fly', ...
     'MeanFV', 'MinDist', 'FailFV', 'FailDist', 'Rejected'});

% Convert to proper types
qc_table.MeanFV = cell2mat(qc_table.MeanFV);
qc_table.MinDist = cell2mat(qc_table.MinDist);
qc_table.FailFV = cell2mat(qc_table.FailFV);
qc_table.FailDist = cell2mat(qc_table.FailDist);
qc_table.Rejected = cell2mat(qc_table.Rejected);
qc_table.Condition = cell2mat(qc_table.Condition);
qc_table.Rep = cell2mat(qc_table.Rep);
qc_table.Cohort = cell2mat(qc_table.Cohort);
qc_table.Fly = cell2mat(qc_table.Fly);

fprintf('Total rep-level observations: %d\n', height(qc_table));

%% 3 - Per-strain summary (averaged across conditions)

strain_summary = table();
for s = 1:n_strains
    strain = strain_names{s};
    mask = strcmp(qc_table.Strain, strain);
    sub = qc_table(mask, :);
    if isempty(sub); continue; end

    n_total = height(sub);
    n_rejected = sum(sub.Rejected);
    n_fail_fv = sum(sub.FailFV & ~sub.FailDist);
    n_fail_dist = sum(~sub.FailFV & sub.FailDist);
    n_fail_both = sum(sub.FailFV & sub.FailDist);

    row = {strain, n_total, n_rejected, ...
           round(100 * n_rejected / n_total, 1), ...
           n_fail_fv, n_fail_dist, n_fail_both, ...
           round(mean(sub.MeanFV), 1), ...
           round(mean(sub.MinDist), 1)};
    strain_summary = [strain_summary; cell2table(row, 'VariableNames', ...
        {'Strain', 'N_Reps', 'N_Rejected', 'PctRejected', ...
         'FailFV_Only', 'FailDist_Only', 'FailBoth', ...
         'MeanFV_Avg', 'MinDist_Avg'})]; %#ok<AGROW>
end

% Sort by rejection rate (highest first)
strain_summary = sortrows(strain_summary, 'PctRejected', 'descend');

disp('=== Per-Strain QC Summary (all conditions, both reps) ===');
disp(strain_summary);

% Flag strains with high rejection
high_reject = strain_summary(strain_summary.PctRejected > 20, :);
if ~isempty(high_reject)
    fprintf('\n*** WARNING: %d strain(s) with >20%% rejection rate:\n', height(high_reject));
    for r = 1:height(high_reject)
        fprintf('   %s: %.1f%% rejected (%d/%d reps)\n', ...
            high_reject.Strain{r}, high_reject.PctRejected(r), ...
            high_reject.N_Rejected(r), high_reject.N_Reps(r));
    end
end

%% 4 - Per-condition rejection rates (averaged across strains)

cond_titles = {"60deg-gratings-4Hz", "60deg-gratings-8Hz", ...
    "narrow-ON-bars-4Hz", "narrow-OFF-bars-4Hz", ...
    "ON-curtains-8Hz", "OFF-curtains-8Hz", ...
    "reverse-phi-2Hz", "reverse-phi-4Hz", ...
    "60deg-flicker-4Hz", "60deg-gratings-static", ...
    "60deg-gratings-0-8-offset", "32px-ON-single-bar"};

cond_summary = table();
for c = 1:N_CONDITIONS
    mask = qc_table.Condition == c;
    sub = qc_table(mask, :);
    n_total = height(sub);
    n_rejected = sum(sub.Rejected);
    row = {c, cond_titles{c}, n_total, n_rejected, ...
           round(100 * n_rejected / n_total, 1)};
    cond_summary = [cond_summary; cell2table(row, 'VariableNames', ...
        {'Condition', 'Name', 'N_Reps', 'N_Rejected', 'PctRejected'})]; %#ok<AGROW>
end

cond_summary = sortrows(cond_summary, 'PctRejected', 'descend');

fprintf('\n=== Per-Condition QC Summary (all strains) ===\n');
disp(cond_summary);

%% 5 - Per-strain x per-condition rejection matrix

reject_matrix = zeros(n_strains, N_CONDITIONS);
for s = 1:n_strains
    strain = strain_names{s};
    for c = 1:N_CONDITIONS
        mask = strcmp(qc_table.Strain, strain) & qc_table.Condition == c;
        sub = qc_table(mask, :);
        if isempty(sub)
            reject_matrix(s, c) = NaN;
        else
            reject_matrix(s, c) = 100 * sum(sub.Rejected) / height(sub);
        end
    end
end

%% 6 - Plots

figure('Name', 'QC Threshold Verification', 'Position', [50 50 1400 900]);

% --- Panel A: Distribution of mean forward velocity per strain ---
subplot(2, 3, 1);
hold on;
strain_order = strain_summary.Strain;  % sorted by rejection rate
y_positions = 1:numel(strain_order);
for s = 1:numel(strain_order)
    mask = strcmp(qc_table.Strain, strain_order{s});
    fv_vals = qc_table.MeanFV(mask);
    scatter(fv_vals, repmat(y_positions(s), size(fv_vals)), 8, [0.5 0.5 0.5], 'filled', 'MarkerFaceAlpha', 0.3);
end
xline(FV_THRESHOLD, 'r--', 'LineWidth', 1.5);
yticks(y_positions);
yticklabels(strrep(strain_order, '_', ' '));
xlabel('Mean forward velocity (mm/s)');
title('FV distribution vs threshold');
set(gca, 'FontSize', 8);
xlim([0 max(qc_table.MeanFV) * 1.1]);
hold off;

% --- Panel B: Distribution of min distance per strain ---
subplot(2, 3, 2);
hold on;
for s = 1:numel(strain_order)
    mask = strcmp(qc_table.Strain, strain_order{s});
    dist_vals = qc_table.MinDist(mask);
    scatter(dist_vals, repmat(y_positions(s), size(dist_vals)), 8, [0.5 0.5 0.5], 'filled', 'MarkerFaceAlpha', 0.3);
end
xline(DIST_THRESHOLD, 'r--', 'LineWidth', 1.5);
yticks(y_positions);
yticklabels(strrep(strain_order, '_', ' '));
xlabel('Min distance from centre (mm)');
title('Distance distribution vs threshold');
set(gca, 'FontSize', 8);
hold off;

% --- Panel C: Rejection rate bar chart per strain ---
subplot(2, 3, 3);
barh(y_positions, strain_summary.PctRejected, 'FaceColor', [0.8 0.3 0.3]);
hold on;
xline(20, 'k--', '20%', 'LineWidth', 1);
yticks(y_positions);
yticklabels(strrep(strain_order, '_', ' '));
xlabel('% reps rejected');
title('Overall rejection rate');
set(gca, 'FontSize', 8);
hold off;

% --- Panel D: Rejection rate per condition (bar chart) ---
subplot(2, 3, 4);
bar(1:N_CONDITIONS, cond_summary.PctRejected(cond_summary.Condition), 'FaceColor', [0.3 0.5 0.8]);
xticks(1:N_CONDITIONS);
xticklabels(strrep(cond_titles, '-', ' '));
xtickangle(45);
ylabel('% reps rejected');
title('Rejection rate by condition');
set(gca, 'FontSize', 8);

% --- Panel E: Strain x condition rejection heatmap ---
subplot(2, 3, [5 6]);
% Reorder to match strain_summary sort order
[~, reorder] = ismember(strain_order, strain_names);
imagesc(reject_matrix(reorder, :));
colormap(gca, [1 1 1; parula(64)]);
colorbar;
caxis([0 50]);
xticks(1:N_CONDITIONS);
xticklabels(strrep(cond_titles, '-', ' '));
xtickangle(45);
yticks(1:numel(strain_order));
yticklabels(strrep(strain_order, '_', ' '));
title('% rejected (strain x condition)');
set(gca, 'FontSize', 8);

sgtitle('QC Threshold Verification — Protocol 27', 'FontSize', 14);

% --- Save figure ---
save_folder = fullfile(cfg.figures, 'FIGS');
if ~isfolder(save_folder)
    mkdir(save_folder);
end
savefig(fullfile(save_folder, 'qc_threshold_verification.fig'));
exportgraphics(gcf, fullfile(save_folder, 'qc_threshold_verification.pdf'), 'ContentType', 'vector');
fprintf('\nFigure saved to: %s\n', save_folder);

%% 7 - Export summary tables

writetable(strain_summary, fullfile(save_folder, 'qc_strain_summary.csv'));
writetable(cond_summary, fullfile(save_folder, 'qc_condition_summary.csv'));
fprintf('Summary tables saved to: %s\n', save_folder);
