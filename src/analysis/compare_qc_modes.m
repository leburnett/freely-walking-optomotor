%% compare_qc_modes — Compare rejection rates across QC modes
%
% Generates bar charts comparing rep rejection rates under three QC modes:
%   1. 'quiescence' — reject if vel < 0.5 mm/s for >75% of frames OR
%                      min(dist_data) > 110 mm
% %   2. 'distance'   — reject if min(dist_data) > 110 mm only
%   3. 'none'       — no rejection
%
% Produces two figures (condition 1 only, matching figS1 Figure 4 layout):
%   Figure 1 (1x3): Reps rejected (count) per strain under each QC mode
%   Figure 2 (1x3): Proportion rejected per strain under each QC mode
%
% REQUIREMENTS:
%   - Protocol 27 data via comb_data_across_cohorts_cond
%   - Functions: get_config, cmap_config, comb_data_across_cohorts_cond
%
% See also: figS1, combine_timeseries_across_exp, check_and_average_across_reps

%% 1 — Configuration & data loading

cfg = get_config();
protocol_dir = fullfile(cfg.results, 'protocol_27');

if ~exist('DATA', 'var') || isempty(fieldnames(DATA))
    fprintf('Loading Protocol 27 data from: %s\n', protocol_dir);
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

save_figs = false;
save_folder = fullfile(cfg.figures, 'FIGS');

%% 2 — Strain ordering & color palette (same as figS1)

strain_order = { ...
    'ss2575_LPC1_shibire_kir', ...
    'ss1209_DCH_VCH_shibire_kir', ...
    'ss34318_Am1_shibire_kir', ...
    'ss01027_H2_shibire_kir', ...
    'ss26283_H1_shibire_kir', ...
    'ss02594_TmY5a_shibire_kir', ...
    'ss03722_Tm5Y_shibire_kir', ...
    'ss00395_TmY3_shibire_kir', ...
    'ss00326_Pm2ab_shibire_kir', ...
    'ss00297_Dm4_shibire_kir', ...
    'ss2603_TmY20_shibire_kir', ...
    'ss2571_T5_shibire_kir', ...
    'ss2344_T4_shibire_kir', ...
    'ss324_t4t5_shibire_kir', ...
    'ss00316_Mi4_shibire_kir', ...
    'l1l4_jfrc100_shibire_kir', ...
    'jfrc100_es_shibire_kir'};

control_strain = 'jfrc100_es_shibire_kir';
n_strains = numel(strain_order);

cmaps = cmap_config();
strain_colours = cmaps.strains.colors;

bar_colors = zeros(n_strains, 3);
n_exp_strains = sum(~strcmp(strain_order, control_strain));
exp_idx = 0;
for i = 1:n_strains
    if strcmp(strain_order{i}, control_strain)
        bar_colors(i, :) = strain_colours(18, :);
    else
        exp_idx = exp_idx + 1;
        bar_colors(i, :) = strain_colours(n_exp_strains - exp_idx + 1, :);
    end
end

display_labels = strrep(strain_order, '_shibire_kir', '');
display_labels = strrep(display_labels, '_', '-');

%% 3 — QC thresholds

VEL_THRESHOLD   = 0.5;    % mm/s
QUIESCENCE_FRAC = 0.75;   % fraction of frames stationary to reject
DIST_THRESHOLD  = 110;    % mm — fly stuck near edge
sex = 'F';
CONDITION = 1;

%% 4 — Compute per-rep rejection under each QC mode

all_strain_names = fieldnames(DATA);

% Preallocate per-strain counters
n_total       = zeros(n_strains, 1);
n_rej_quiesc  = zeros(n_strains, 1);
n_rej_dist    = zeros(n_strains, 1);
n_rej_none    = zeros(n_strains, 1); %#ok<NASGU> — always zero

for si = 1:n_strains
    strain = strain_order{si};
    if ~ismember(strain, all_strain_names); continue; end
    if ~isfield(DATA.(strain), sex); continue; end

    data = DATA.(strain).(sex);
    n_exp = length(data);

    for exp_idx_loop = 1:n_exp
        for rep = 1:2
            rep_str = sprintf('R%d_condition_%d', rep, CONDITION);
            if ~isfield(data(exp_idx_loop), rep_str); continue; end
            rep_data = data(exp_idx_loop).(rep_str);
            if isempty(rep_data); continue; end

            vel  = rep_data.vel_data;
            dist = rep_data.dist_data;
            n_flies  = size(vel, 1);
            n_frames = size(vel, 2);

            for fly = 1:n_flies
                n_total(si) = n_total(si) + 1;

                % Distance check
                mdist = min(dist(fly, :), [], 'omitnan');
                fail_dist = mdist > DIST_THRESHOLD;

                % Quiescence check
                n_stationary = sum(vel(fly, :) < VEL_THRESHOLD, 'omitnan');
                frac_stat = n_stationary / n_frames;
                fail_quiesc = frac_stat > QUIESCENCE_FRAC;

                % Quiescence mode: distance OR quiescence
                if fail_dist || fail_quiesc
                    n_rej_quiesc(si) = n_rej_quiesc(si) + 1;
                end

                % Distance mode: distance only
                if fail_dist
                    n_rej_dist(si) = n_rej_dist(si) + 1;
                end

                % None mode: no rejection (n_rej_none stays 0)
            end
        end
    end
end

n_rej_none = zeros(n_strains, 1);

prop_rej_quiesc = n_rej_quiesc ./ n_total;
prop_rej_dist   = n_rej_dist ./ n_total;
prop_rej_none   = n_rej_none ./ n_total;

%% 5 — Print summary

fprintf('\n=== QC Mode Comparison (Condition %d) ===\n', CONDITION);
fprintf('%-35s  %6s  %10s  %10s  %10s\n', 'Strain', 'Total', 'Quiescence', 'Distance', 'None');
for si = 1:n_strains
    fprintf('%-35s  %6d  %6d (%4.1f%%)  %6d (%4.1f%%)  %6d (%4.1f%%)\n', ...
        strain_order{si}, n_total(si), ...
        n_rej_quiesc(si), 100*prop_rej_quiesc(si), ...
        n_rej_dist(si), 100*prop_rej_dist(si), ...
        n_rej_none(si), 100*prop_rej_none(si));
end

%% 6 — Figure 1: Reps rejected (count) — 1x3 panels

flip_idx = flip(1:n_strains);
bar_colors_f     = bar_colors(flip_idx, :);
display_labels_f = display_labels(flip_idx);

n_rej_quiesc_f = n_rej_quiesc(flip_idx);
n_rej_dist_f   = n_rej_dist(flip_idx);
n_rej_none_f   = n_rej_none(flip_idx);

fig1 = figure('Position', [50 50 1600 450]);

subplot(1, 3, 1);
draw_standard_bar_chart(gca, n_rej_quiesc_f, bar_colors_f, display_labels_f, ...
    'Reps rejected', 'A — Reps rejected (quiescence QC)');

subplot(1, 3, 2);
draw_standard_bar_chart(gca, n_rej_dist_f, bar_colors_f, display_labels_f, ...
    'Reps rejected', 'B — Reps rejected (distance QC)');

subplot(1, 3, 3);
draw_standard_bar_chart(gca, n_rej_none_f, bar_colors_f, display_labels_f, ...
    'Reps rejected', 'C — Reps rejected (no QC)');

% sgtitle(sprintf('Reps Rejected — Condition %d', CONDITION), 'FontSize', 18);

if save_figs
    if ~isfolder(save_folder); mkdir(save_folder); end
    exportgraphics(fig1, fullfile(save_folder, 'qc_comparison_counts.pdf'), ...
        'ContentType', 'vector');
end

%% 7 — Figure 2: Proportion rejected — 1x3 panels

prop_rej_quiesc_f = prop_rej_quiesc(flip_idx);
prop_rej_dist_f   = prop_rej_dist(flip_idx);
prop_rej_none_f   = prop_rej_none(flip_idx);

fig2 = figure('Position', [50 550 1600 450]);

subplot(1, 3, 1);
draw_standard_bar_chart(gca, prop_rej_quiesc_f, bar_colors_f, display_labels_f, ...
    'Proportion rejected', 'A — Proportion rejected (quiescence QC)');

subplot(1, 3, 2);
draw_standard_bar_chart(gca, prop_rej_dist_f, bar_colors_f, display_labels_f, ...
    'Proportion rejected', 'B — Proportion rejected (distance QC)');

subplot(1, 3, 3);
draw_standard_bar_chart(gca, prop_rej_none_f, bar_colors_f, display_labels_f, ...
    'Proportion rejected', 'C — Proportion rejected (no QC)');

% sgtitle(sprintf('Proportion Rejected — Condition %d', CONDITION), 'FontSize', 18);

if save_figs
    if ~isfolder(save_folder); mkdir(save_folder); end
    exportgraphics(fig2, fullfile(save_folder, 'qc_comparison_proportions.pdf'), ...
        'ContentType', 'vector');
end

%% ===== Local functions =====

function draw_standard_bar_chart(ax, values, colors, labels, ylabel_str, title_str)
%DRAW_STANDARD_BAR_CHART  Simple colored bar chart.
    axes(ax); %#ok<LAXES>
    n = numel(values);

    b = bar(1:n, values, 'FaceColor', 'flat', 'EdgeColor', [0 0 0], 'LineWidth', 0.5);
    b.CData = colors;
    hold on;

    y_max = max(values) * 1.15;
    if y_max == 0; y_max = 1; end

    for i = 1:n
        text(i, values(i) + y_max * 0.02, num2str(round(values(i), 2)), ...
            'HorizontalAlignment', 'center', 'FontSize', 9);
    end

    ylim([0 y_max]);
    set(gca, 'XTick', 1:n, 'XTickLabel', labels, 'FontSize', 10, ...
        'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
    xtickangle(45);
    ylabel(ylabel_str, 'FontSize', 14);
    title(title_str, 'FontSize', 14);
    hold off;
end
