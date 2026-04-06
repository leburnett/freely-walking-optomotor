%% CROSS_STRAIN_CONDITION_HEATMAPS — Strains x conditions summary heatmaps
%
% Produces a 1x2 figure comparing each strain to ES control across all 12
% Protocol 27 conditions:
%   Panel A: Centring metric (relative distance at end of stimulus)
%   Panel B: Turning metric (mean turning rate during stimulus)
%
% Color scheme: red = target > control, blue = control > target.
% Intensity encodes FDR-adjusted p-value significance.
%
% REQUIREMENTS:
%   - DATA struct from comb_data_across_cohorts_cond (Protocol 27)
%   - strain_names2.mat in results folder
%   - Functions: make_pvalue_heatmap_across_strains, fdr_bh
%
% See also: make_summary_heat_maps_p27, turning_rate_analysis

%% 1 — Load DATA

if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
    fprintf('Loaded DATA from %s\n', protocol_dir);
end

cfg = get_config();

% Output config
save_figs = false;
save_folder = fullfile(cfg.figures, 'FIGS');

%% 2 — Compute metrics for all strains x conditions

% Load strain names (same list as make_pvalue_heatmap_across_strains uses)
strain_names_s = load(fullfile(cfg.results, 'strain_names2.mat'));
strain_names_heat = strain_names_s.strain_names;
n_strains = numel(strain_names_heat);

cond_titles = {'60deg 4Hz', '60deg 8Hz', 'ON bars', 'OFF bars', ...
    'ON curt.', 'OFF curt.', 'RevPhi 2Hz', 'RevPhi 4Hz', ...
    'Flicker', 'Static', 'Offset CoR', 'Bar fix.'};
n_conds = 12;

% Metric column indices from the 6-metric output of make_pvalue_heatmap_across_strains
% Layout: [FV-stim, FV-change, Turning-stim, Turning-5s, Dist-rel-10s, Dist-rel-end]
CENTRING_COL = 6;  % Dist-rel-end (relative distance at end of stimulus)
TURNING_COL  = 3;  % Turning-stim (mean turning during stimulus)

% Preallocate: [n_strains x n_conds] per metric
pvals_centring  = zeros(n_strains, n_conds);
target_centring = zeros(n_strains, n_conds);
ctrl_centring   = zeros(n_strains, n_conds);
pvals_turning   = zeros(n_strains, n_conds);
target_turning  = zeros(n_strains, n_conds);
ctrl_turning    = zeros(n_strains, n_conds);

for c = 1:n_conds
    fprintf('  Computing metrics for condition %d/%d (%s)...\n', c, n_conds, cond_titles{c});
    [pv, tm, cm] = make_pvalue_heatmap_across_strains(DATA, c);
    pvals_centring(:, c)  = pv(:, CENTRING_COL);
    target_centring(:, c) = tm(:, CENTRING_COL);
    ctrl_centring(:, c)   = cm(:, CENTRING_COL);
    pvals_turning(:, c)   = pv(:, TURNING_COL);
    target_turning(:, c)  = tm(:, TURNING_COL);
    ctrl_turning(:, c)    = cm(:, TURNING_COL);
end

%% 3 — Reorder columns: move "Offset CoR" (cond 11) to position 3

% Original order: 1..12 where 11 = Offset CoR
% New order: 1, 2, 11, 3, 4, 5, 6, 7, 8, 9, 10, 12
col_order = [1, 2, 11, 3, 4, 5, 6, 7, 8, 9, 10, 12];

pvals_centring  = pvals_centring(:, col_order);
target_centring = target_centring(:, col_order);
ctrl_centring   = ctrl_centring(:, col_order);
pvals_turning   = pvals_turning(:, col_order);
target_turning  = target_turning(:, col_order);
ctrl_turning    = ctrl_turning(:, col_order);
cond_titles     = cond_titles(col_order);

%% 4 — FDR correction

% Joint FDR correction across ALL comparisons in both heatmaps
all_pvals = [pvals_centring(:); pvals_turning(:)];
[~, ~, adj_all] = fdr_bh(all_pvals, 0.05, 'dep', 'yes');
n_total = n_strains * n_conds;
adj_centring = reshape(adj_all(1:n_total), n_strains, n_conds);
adj_turning  = reshape(adj_all(n_total+1:end), n_strains, n_conds);

%% 5 — Plot heatmaps

% Clean strain labels for display
strain_labels = strrep(strain_names_heat, '_', '-');
strain_labels = strrep(strain_labels, '-shibire-kir', '');

fig = figure('Position', [50 50 1400 600]);

% Panel A: Centring
% Swap target/control so that MORE centring (more negative dist_delta) = red
subplot(1, 2, 1);
rgb_centring = build_heatmap_rgb(adj_centring, ctrl_centring, target_centring);
image(rgb_centring);
hold on;
draw_grid_lines(n_strains, n_conds);
yticks(1:n_strains);
yticklabels(strain_labels);
xticks(1:n_conds);
xticklabels(cond_titles);
xtickangle(45);
title('A — Centring (relative distance at end of stim)', 'FontSize', 14);
set(gca, 'FontSize', 9, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
hold off;

% Panel B: Turning
subplot(1, 2, 2);
rgb_turning = build_heatmap_rgb(adj_turning, target_turning, ctrl_turning);
image(rgb_turning);
hold on;
draw_grid_lines(n_strains, n_conds);
yticks(1:n_strains);
yticklabels(strain_labels);
xticks(1:n_conds);
xticklabels(cond_titles);
xtickangle(45);
title('B — Turning (mean turning rate during stim)', 'FontSize', 14);
set(gca, 'FontSize', 9, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
hold off;

sgtitle('Cross-strain comparison vs ES control — P27 all conditions', 'FontSize', 16);

if save_figs
    exportgraphics(fig, fullfile(save_folder, 'cross_strain_condition_heatmaps.pdf'), ...
        'ContentType', 'vector');
    close(fig);
end

%% 6 — Print summary

fprintf('\n--- Heatmap summary ---\n');
fprintf('Centring: %d/%d cells significant (FDR q<0.05)\n', ...
    sum(adj_centring(:) <= 0.05), numel(adj_centring));
fprintf('Turning:  %d/%d cells significant (FDR q<0.05)\n', ...
    sum(adj_turning(:) <= 0.05), numel(adj_turning));

fprintf('\n--- Per-condition summary ---\n');
for c = 1:n_conds
    n_sig_c = sum(adj_centring(:, c) <= 0.05);
    n_sig_t = sum(adj_turning(:, c) <= 0.05);
    fprintf('  Cond %2d (%s): centring %d/%d sig, turning %d/%d sig\n', ...
        c, cond_titles{c}, n_sig_c, n_strains, n_sig_t, n_strains);
end

% Full per-strain per-condition tables
fprintf('\n\n=== CENTRING: FDR-adjusted p-values (target vs ES control) ===\n');
fprintf('  Red in Panel A = strain centres MORE than control (dist_delta more negative)\n');
fprintf('  Blue in Panel A = strain centres LESS than control\n\n');
fprintf('%-30s', 'Strain');
for c = 1:n_conds
    fprintf('  %-12s', cond_titles{c});
end
fprintf('\n');
fprintf('%s\n', repmat('-', 1, 30 + n_conds * 14));
for s = 1:n_strains
    fprintf('%-30s', strain_labels{s});
    for c = 1:n_conds
        p = adj_centring(s, c);
        diff_val = target_centring(s, c) - ctrl_centring(s, c);
        if p <= 0.05
            if diff_val < 0
                dir_str = 'R';  % red: more centring
            else
                dir_str = 'B';  % blue: less centring
            end
        else
            dir_str = ' ';
        end
        fprintf('  %s %-10.2e', dir_str, p);
    end
    fprintf('\n');
end

fprintf('\n\n=== TURNING: FDR-adjusted p-values (target vs ES control) ===\n');
fprintf('  Red in Panel B = strain turns MORE than control\n');
fprintf('  Blue in Panel B = strain turns LESS than control\n\n');
fprintf('%-30s', 'Strain');
for c = 1:n_conds
    fprintf('  %-12s', cond_titles{c});
end
fprintf('\n');
fprintf('%s\n', repmat('-', 1, 30 + n_conds * 14));
for s = 1:n_strains
    fprintf('%-30s', strain_labels{s});
    for c = 1:n_conds
        p = adj_turning(s, c);
        diff_val = target_turning(s, c) - ctrl_turning(s, c);
        if p <= 0.05
            if diff_val > 0
                dir_str = 'R';  % red: more turning
            else
                dir_str = 'B';  % blue: less turning
            end
        else
            dir_str = ' ';
        end
        fprintf('  %s %-10.2e', dir_str, p);
    end
    fprintf('\n');
end

% Also print the raw mean values for context
fprintf('\n\n=== CENTRING: Mean metric values (target | control) ===\n');
fprintf('%-30s', 'Strain');
for c = 1:n_conds
    fprintf('  %-12s', cond_titles{c});
end
fprintf('\n');
fprintf('%s\n', repmat('-', 1, 30 + n_conds * 14));
for s = 1:n_strains
    fprintf('%-30s', strain_labels{s});
    for c = 1:n_conds
        fprintf('  %+6.1f|%+5.1f', target_centring(s, c), ctrl_centring(s, c));
    end
    fprintf('\n');
end

fprintf('\n\n=== TURNING: Mean metric values (target | control) ===\n');
fprintf('%-30s', 'Strain');
for c = 1:n_conds
    fprintf('  %-12s', cond_titles{c});
end
fprintf('\n');
fprintf('%s\n', repmat('-', 1, 30 + n_conds * 14));
for s = 1:n_strains
    fprintf('%-30s', strain_labels{s});
    for c = 1:n_conds
        fprintf('  %6.1f|%5.1f', target_turning(s, c), ctrl_turning(s, c));
    end
    fprintf('\n');
end

f = gcf;
f.Position= [188   649   610   300];

fprintf('\n=== Done ===\n');

%% Helper functions

function draw_grid_lines(n_rows, n_cols)
%DRAW_GRID_LINES  Light grey grid lines between heatmap cells.
    grid_color = [0.75 0.75 0.75];
    % Horizontal lines
    for r = 0.5:(n_rows + 0.5)
        plot([0.5, n_cols + 0.5], [r, r], '-', 'Color', grid_color, 'LineWidth', 0.5);
    end
    % Vertical lines
    for c = 0.5:(n_cols + 0.5)
        plot([c, c], [0.5, n_rows + 0.5], '-', 'Color', grid_color, 'LineWidth', 0.5);
    end
end

function rgb = build_heatmap_rgb(adj_p, target_mean, ctrl_mean)
% BUILD_HEATMAP_RGB  Red/blue RGB heatmap from p-values and direction.
%   Red = target > control, Blue = control > target.
%   Intensity from p-value: p>0.05 = white, p<1e-5 = full color.
    [m, n] = size(adj_p);
    rgb = ones(m, n, 3);
    for i = 1:m
        for j = 1:n
            p = adj_p(i, j);
            if p > 0.05
                continue;
            end
            if p > 0.01,        intensity = 0.8;
            elseif p > 0.001,   intensity = 0.6;
            elseif p > 0.0001,  intensity = 0.4;
            elseif p > 0.00001, intensity = 0.2;
            else,                intensity = 0.0;
            end
            if target_mean(i, j) > ctrl_mean(i, j)
                rgb(i, j, :) = [1, intensity, intensity];       % red
            else
                rgb(i, j, :) = [intensity, intensity, 1];       % blue
            end
        end
    end
end
