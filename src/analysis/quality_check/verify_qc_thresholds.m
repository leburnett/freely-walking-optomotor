%% VERIFY_QC_THRESHOLDS - Assess quiescence-based QC filtering across strains and conditions
%
% Analyses how the two QC thresholds in check_and_average_across_reps.m
% affect data retention:
%   1. vel < 0.5 mm/s for >75% of frames — fly truly stationary/dead
%   2. min(dist) > 110 mm — fly stuck near edge
%
% QC is applied per-fly, per-condition, per-rep. This means a fly can
% pass QC for one condition (e.g., gratings) but fail for another
% (e.g., static/flicker) within the same experiment.
%
% The quiescence method uses total velocity (vel_data, direction-independent)
% rather than forward velocity (fv_data). A fly spinning in tight coils
% has low fv but non-zero vel — the quiescence method retains these flies.
%
% OUTPUTS:
%   - Per-strain summary table: total flies, rejected flies, % rejected
%   - Per-condition rejection rates across all strains
%   - Distribution plots of fraction stationary and min dist relative to thresholds
%   - Flags strains with >20% rejection rate
%
% USAGE:
%   Run after setup_path.m. Requires Protocol 27 data.
%
% See also: check_and_average_across_reps, generate_strain_metadata_table

%% 1 - Configuration

VEL_THRESHOLD = 0.5;     % mm/s — total velocity below this = stationary frame
QUIESCENCE_FRAC = 0.75;   % fraction of frames stationary to reject fly
DIST_THRESHOLD = 110;    % mm — fly stuck near edge
N_CONDITIONS = 12;       % Protocol 27 has 12 conditions

cfg = get_config();
protocol_dir = fullfile(cfg.results, 'protocol_27');
assert(isfolder(protocol_dir), ...
    'Protocol 27 directory not found: %s\nCheck cfg.project_root in get_config.m', protocol_dir);

if exist('DATA', 'var') && ~isempty(fieldnames(DATA))
    fprintf('Using existing DATA variable from workspace.\n');
else
    fprintf('Loading Protocol 27 data from: %s\n', protocol_dir);
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end
assert(~isempty(fieldnames(DATA)), 'DATA is empty');

%% 2 - Extract QC metrics for every fly x condition x rep

strain_names = fieldnames(DATA);
n_strains = numel(strain_names);
sex = 'F';

% Collect all QC metrics using parallel arrays
row_strain = {};
row_cond   = [];
row_rep    = [];
row_cohort = [];
row_fly    = [];
row_frac_stationary = [];
row_dist   = [];
row_fail_quiescence = [];
row_fail_dist = [];
row_rejected  = [];

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

                vel = rep_data.vel_data;     % [n_flies x n_frames] total velocity
                dist = rep_data.dist_data;   % [n_flies x n_frames]
                n_flies = size(vel, 1);
                n_frames = size(vel, 2);

                for fly = 1:n_flies
                    % Quiescence: fraction of frames where fly is stationary
                    n_stationary = sum(vel(fly, :) < VEL_THRESHOLD, 'omitnan');
                    frac_stat = n_stationary / n_frames;
                    mdist = min(dist(fly, :), [], 'omitnan');

                    fq = frac_stat > QUIESCENCE_FRAC;
                    fdist = mdist > DIST_THRESHOLD;

                    row_strain{end+1, 1} = strain; %#ok<SAGROW>
                    row_cond(end+1, 1)   = cond; %#ok<SAGROW>
                    row_rep(end+1, 1)    = rep; %#ok<SAGROW>
                    row_cohort(end+1, 1) = exp_idx; %#ok<SAGROW>
                    row_fly(end+1, 1)    = fly; %#ok<SAGROW>
                    row_frac_stationary(end+1, 1) = frac_stat; %#ok<SAGROW>
                    row_dist(end+1, 1)   = mdist; %#ok<SAGROW>
                    row_fail_quiescence(end+1, 1) = fq; %#ok<SAGROW>
                    row_fail_dist(end+1, 1) = fdist; %#ok<SAGROW>
                    row_rejected(end+1, 1)  = fq || fdist; %#ok<SAGROW>
                end
            end
        end
    end
end

% Build table directly from parallel arrays
qc_table = table(row_strain, row_cond, row_rep, row_cohort, row_fly, ...
    row_frac_stationary, row_dist, row_fail_quiescence, row_fail_dist, row_rejected, ...
    'VariableNames', {'Strain', 'Condition', 'Rep', 'Cohort', 'Fly', ...
     'FracStationary', 'MinDist', 'FailQuiescence', 'FailDist', 'Rejected'});

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
    n_fail_quiescence = sum(sub.FailQuiescence & ~sub.FailDist);
    n_fail_dist = sum(~sub.FailQuiescence & sub.FailDist);
    n_fail_both = sum(sub.FailQuiescence & sub.FailDist);

    row = {strain, n_total, n_rejected, ...
           round(100 * n_rejected / n_total, 1), ...
           n_fail_quiescence, n_fail_dist, n_fail_both, ...
           round(mean(sub.FracStationary), 3), ...
           round(mean(sub.MinDist), 1)};
    strain_summary = [strain_summary; cell2table(row, 'VariableNames', ...
        {'Strain', 'N_Reps', 'N_Rejected', 'PctRejected', ...
         'FailQuiescence_Only', 'FailDist_Only', 'FailBoth', ...
         'MeanFracStationary', 'MinDist_Avg'})]; %#ok<AGROW>
end

% Sort by rejection rate (highest first)
strain_summary = sortrows(strain_summary, 'PctRejected', 'descend');

disp('=== Per-Strain QC Summary — Quiescence Method (all conditions, both reps) ===');
fprintf('Thresholds: vel < %.1f mm/s for >%.0f%% of frames OR min(dist) > %d mm\n\n', ...
    VEL_THRESHOLD, QUIESCENCE_FRAC * 100, DIST_THRESHOLD);
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
else
    fprintf('\nNo strains exceed 20%% rejection rate with quiescence method.\n');
end

%% 4 - Per-condition rejection rates (averaged across strains)

cond_titles = {'60deg-gratings-4Hz', '60deg-gratings-8Hz', ...
    'narrow-ON-bars-4Hz', 'narrow-OFF-bars-4Hz', ...
    'ON-curtains-8Hz', 'OFF-curtains-8Hz', ...
    'reverse-phi-2Hz', 'reverse-phi-4Hz', ...
    '60deg-flicker-4Hz', '60deg-gratings-static', ...
    '60deg-gratings-0-8-offset', '32px-ON-single-bar'};

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

fprintf('\n=== Per-Condition QC Summary — Quiescence Method (all strains) ===\n');
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

figure('Name', 'QC Threshold Verification — Quiescence Method', 'Position', [50 50 1400 1000]);
tl = tiledlayout(2, 3, 'TileSpacing', 'loose', 'Padding', 'compact');

% --- Panel A: Distribution of fraction stationary per strain ---
nexttile;
hold on;
strain_order = strain_summary.Strain;  % sorted by rejection rate
y_positions = 1:numel(strain_order);
for s = 1:numel(strain_order)
    mask = strcmp(qc_table.Strain, strain_order{s});
    frac_vals = qc_table.FracStationary(mask);
    scatter(frac_vals, repmat(y_positions(s), size(frac_vals)), 8, [0.5 0.5 0.5], 'filled', 'MarkerFaceAlpha', 0.3);
end
xline(QUIESCENCE_FRAC, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1.5);
yticks(y_positions);
yticklabels(strrep(strain_order, '_', ' '));
xlabel('Fraction of frames stationary', 'FontSize', 14);
title('Quiescence distribution vs threshold', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
xlim([0 1]);
hold off;

% --- Panel B: Distribution of min distance per strain ---
nexttile;
hold on;
for s = 1:numel(strain_order)
    mask = strcmp(qc_table.Strain, strain_order{s});
    dist_vals = qc_table.MinDist(mask);
    scatter(dist_vals, repmat(y_positions(s), size(dist_vals)), 8, [0.5 0.5 0.5], 'filled', 'MarkerFaceAlpha', 0.3);
end
xline(DIST_THRESHOLD, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1.5);
yticks(y_positions);
yticklabels(strrep(strain_order, '_', ' '));
xlabel('Min distance from centre (mm)', 'FontSize', 14);
title('Distance distribution vs threshold', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
hold off;

% --- Panel C: Rejection rate bar chart per strain ---
nexttile;
barh(y_positions, strain_summary.PctRejected, 'FaceColor', [0.8 0.3 0.3]);
hold on;
xline(20, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
yticks(y_positions);
yticklabels(strrep(strain_order, '_', ' '));
xlabel('% reps rejected', 'FontSize', 14);
title('Overall rejection rate (quiescence)', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
hold off;

% --- Panel D: Rejection rate per condition (bar chart) ---
nexttile;
bar(1:N_CONDITIONS, cond_summary.PctRejected(cond_summary.Condition), 'FaceColor', [0.3 0.5 0.8]);
xticks(1:N_CONDITIONS);
xticklabels(strrep(cond_titles, '-', ' '));
xtickangle(45);
ylabel('% reps rejected', 'FontSize', 14);
title('Rejection rate by condition (quiescence)', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% --- Panel E: Strain x condition rejection heatmap ---
nexttile([1 2]);
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
title('% rejected (strain x condition) — quiescence method', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

title(tl, 'QC Threshold Verification — Quiescence Method, Protocol 27', 'FontSize', 18);

% --- Save figure ---
save_folder = fullfile(cfg.figures, 'FIGS');
if ~isfolder(save_folder)
    mkdir(save_folder);
end
% savefig(fullfile(save_folder, 'qc_threshold_verification_quiescence.fig'));
% exportgraphics(gcf, fullfile(save_folder, 'qc_threshold_verification_quiescence.pdf'), 'ContentType', 'vector');
% fprintf('\nFigure saved to: %s\n', save_folder);

%% 7 - Per-strain histograms of fraction stationary (condition 1 only)

% Short display names for each strain (ordered by rejection rate)
strain_display = strrep(strain_order, '_shibire_kir', '');
strain_display = strrep(strain_display, '_', ' ');

figure('Name', 'Fraction Stationary — Condition 1 per Strain', 'Position', [50 50 1200 1000]);
n_rows = 10;
n_cols = 2;

for s = 1:numel(strain_order)
    subplot(n_rows, n_cols, s);

    % Get condition 1 data for this strain
    mask = strcmp(qc_table.Strain, strain_order{s}) & qc_table.Condition == 1;
    frac_vals = qc_table.FracStationary(mask);

    % Histogram
    histogram(frac_vals, 20, 'FaceColor', [0.4 0.6 0.8], 'EdgeColor', 'w', ...
        'Normalization', 'count');
    hold on;

    % Mean vertical line
    mean_val = mean(frac_vals, 'omitnan');
    xline(mean_val, '-', 'Color', 'r', 'LineWidth', 1.5);

    % Threshold line (light grey, solid)
    xline(QUIESCENCE_FRAC, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

    xlim([0 1]);
    title(strain_display{s}, 'FontSize', 16, 'FontWeight', 'normal');
    set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

    % Only add axis labels on edge subplots
    if s >= numel(strain_order) - 1
        xlabel('Frac. stationary', 'FontSize', 14);
    end
    if mod(s, n_cols) == 1
        ylabel('Count', 'FontSize', 14);
    end

    hold off;
end

% Fill remaining subplot(s) if fewer than 20 strains
for s = (numel(strain_order)+1):(n_rows*n_cols)
    subplot(n_rows, n_cols, s);
    axis off;
end

sgtitle(sprintf('Fraction Stationary (vel < %.1f mm/s) — Condition 1\nRed = strain mean, Grey = rejection threshold (%.0f%%)', ...
    VEL_THRESHOLD, QUIESCENCE_FRAC * 100), 'FontSize', 18);

%% 8 - Export summary tables

writetable(strain_summary, fullfile(save_folder, 'qc_strain_summary_quiescence.csv'));
writetable(cond_summary, fullfile(save_folder, 'qc_condition_summary_quiescence.csv'));
fprintf('Summary tables saved to: %s\n', save_folder);
