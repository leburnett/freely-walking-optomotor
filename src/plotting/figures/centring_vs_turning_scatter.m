%% CENTRING_VS_TURNING_SCATTER — Mean centring vs mean turning per strain
%
% Scatter plot where each point is a strain (condition 1, 60deg 4Hz).
%   X-axis: mean turning rate during stimulus (deg/s)
%   Y-axis: mean centring (relative distance at end of stimulus, mm)
%
% Points off the main cloud reveal centring-turning dissociations:
%   - Tm5Y: high centring, normal turning
%   - TmY20/H1: high turning, low centring
%   - T4/T5, L1/L4: both low (motion-blind)
%
% REQUIREMENTS:
%   - DATA struct from comb_data_across_cohorts_cond (Protocol 27)
%   - strain_names2.mat in results folder
%   - Functions: make_pvalue_heatmap_across_strains
%
% See also: cross_strain_condition_heatmaps, turning_rate_analysis

%% 1 — Load DATA

if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
    fprintf('Loaded DATA from %s\n', protocol_dir);
end

cfg = get_config();

save_figs = false;
save_folder = fullfile(cfg.figures, 'FIGS');

%% 2 — Compute per-strain means for condition 1

condition_n = 1;  % 60deg gratings 4Hz

% Metric column indices (same as cross_strain_condition_heatmaps)
CENTRING_COL = 6;  % Dist-rel-end
TURNING_COL  = 3;  % Turning-stim

[pvals, target_means, ctrl_means, strain_names_raw] = ...
    make_pvalue_heatmap_across_strains(DATA, condition_n);

centring_vals = target_means(:, CENTRING_COL);  % mm (negative = more centring)
turning_vals  = target_means(:, TURNING_COL);   % deg/s
ctrl_centring = ctrl_means(1, CENTRING_COL);    % same for all rows
ctrl_turning  = ctrl_means(1, TURNING_COL);

% Clean strain labels
strain_labels = strrep(strain_names_raw, '_', '-');
strain_labels = strrep(strain_labels, '-shibire-kir', '');

n_strains = numel(strain_labels);

%% 3 — Plot scatter

fig = figure('Position', [100 100 700 550]);
hold on;

% Reference lines at control values
xline(ctrl_turning, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
yline(ctrl_centring, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

% Plot control point
scatter(ctrl_turning, ctrl_centring, 80, [0.7 0.7 0.7], 'filled', ...
    'MarkerEdgeColor', 'k', 'LineWidth', 1);
text(ctrl_turning + 1.5, ctrl_centring + 1, 'ES control', ...
    'FontSize', 9, 'Color', [0.4 0.4 0.4]);

% Plot each strain
for s = 1:n_strains
    scatter(turning_vals(s), centring_vals(s), 50, 'k', 'filled', ...
        'MarkerFaceAlpha', 0.7);
    text(turning_vals(s) + 1.5, centring_vals(s), strain_labels{s}, ...
        'FontSize', 8, 'Interpreter', 'none');
end

% Axis labels
xlabel('Mean turning rate during stimulus (deg/s)', 'FontSize', 14);
ylabel('Centring: relative distance at end (mm)', 'FontSize', 14);
title('Centring vs Turning — Condition 1 (60deg 4Hz)', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Flip y-axis so MORE centring (more negative) is UP
set(gca, 'YDir', 'reverse');

if save_figs
    exportgraphics(fig, fullfile(save_folder, 'centring_vs_turning_scatter.pdf'), ...
        'ContentType', 'vector');
    close(fig);
end

%% 4 — Print summary table

fprintf('\n=== Centring vs Turning — Condition %d ===\n', condition_n);
fprintf('%-25s  %10s  %10s\n', 'Strain', 'Turning', 'Centring');
fprintf('%s\n', repmat('-', 1, 50));
fprintf('%-25s  %10.1f  %10.1f  (control)\n', 'ES control', ctrl_turning, ctrl_centring);
fprintf('%s\n', repmat('-', 1, 50));
for s = 1:n_strains
    fprintf('%-25s  %10.1f  %10.1f\n', strain_labels{s}, turning_vals(s), centring_vals(s));
end

% Correlation
[r, p_corr] = corr(turning_vals, centring_vals, 'Type', 'Spearman');
fprintf('\nSpearman correlation (turning vs centring): rho = %.3f, p = %.3e\n', r, p_corr);
fprintf('  (negative rho = more turning associated with more centring)\n');

fprintf('\n=== Done ===\n');
