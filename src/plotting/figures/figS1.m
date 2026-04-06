%% figS1 — Supplementary Figure S1: Dataset Composition & QC Summary
%
% Generates four figures summarising the dataset and quality control:
%   Figure 1 (2x2): Vials, flies, tracking removal per strain
%   Figure 2: Fraction-stationary histograms per strain (condition 1)
%   Figure 3: Rejection-rate heatmap (strain x condition)
%   Figure 4 (1x2): Condition 1 QC rejection counts and proportions
%
% REQUIREMENTS:
%   - Protocol 27 data via comb_data_across_cohorts_cond
%   - Functions: generate_exp_data_struct, get_config, comb_data_across_cohorts_cond
%
% See also: generate_fly_n_bar_charts, VERIFY_QC_THRESHOLDS

%% 1 — Configuration & data loading

cfg = get_config();
protocol_dir = fullfile(cfg.results, 'protocol_27');

if ~exist('DATA', 'var') || isempty(fieldnames(DATA))
    fprintf('Loading Protocol 27 data from: %s\n', protocol_dir);
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

exp_data = generate_exp_data_struct(DATA);

save_figs = false;
save_folder = fullfile(cfg.figures, 'FIGS');

%% 2 — Strain ordering & color palette

% Heatmap strain order (from constants.py) + control last
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

% Strain colours (matches plot_boxchart_metrics_xstrains)
% Rows 1-16 = experimental strains in heatmap order, 17 = control (dark grey),
% 18 = spare (light grey)
strain_colours = [[220,  40,  30]; ...  % muted red
    [220,  85,  30]; ...
    [220, 130,  35]; ...
    [220, 175,  40]; ...
    [220, 210,  50]; ...  % soft yellow
    [190, 170,  60]; ...  % yellow-green
    [164, 182, 120]; ...  % light green
    [134, 187, 139]; ...  % green-cyan
    [104, 185, 158]; ...  % cyan
    [ 82, 176, 176]; ...  % teal
    [ 72, 160, 192]; ...  % blue-cyan
    [ 74, 138, 202]; ...  % blue
    [ 86, 114, 204]; ...  % blue-indigo
    [108,  92, 198]; ...  % indigo
    [132,  74, 186]; ...  % violet
    [154,  60, 168]; ...  % deep violet
    [ 40,  40,  40]; ...
    [180, 180, 180]] ./ 255;

% Assign colors: reverse mapping so l1l4=red(1), LPC1=purple(16), control=light grey
bar_colors = zeros(n_strains, 3);
n_exp_strains = sum(~strcmp(strain_order, control_strain));
exp_idx = 0;
for i = 1:n_strains
    if strcmp(strain_order{i}, control_strain)
        bar_colors(i, :) = strain_colours(18, :);  % light grey
    else
        exp_idx = exp_idx + 1;
        bar_colors(i, :) = strain_colours(n_exp_strains - exp_idx + 1, :);
    end
end

% Display labels: remove _shibire_kir suffix, replace _ with -
display_labels = strrep(strain_order, '_shibire_kir', '');
display_labels = strrep(display_labels, '_', '-');

%% 3 — Extract per-strain summary metrics from exp_data

n_vials_arr = zeros(n_strains, 1);
n_flies_arr = zeros(n_strains, 1);
n_rm_arr    = zeros(n_strains, 1);
n_arena_arr = zeros(n_strains, 1);

for i = 1:n_strains
    s = strain_order{i};
    n_vials_arr(i) = exp_data.(s).n_vials;
    n_flies_arr(i) = sum(exp_data.(s).n_flies);
    n_rm_arr(i)    = sum(exp_data.(s).n_rm);
    n_arena_arr(i) = sum(exp_data.(s).n_arena);
end

prop_rm_arr = n_rm_arr ./ n_arena_arr;

%% 4 — Figure 1: 2x2 bar charts (dataset composition)

% Flip order for bar charts so strain_order{1} appears on the right
flip_idx = flip(1:n_strains);
bar_colors_f   = bar_colors(flip_idx, :);
display_labels_f = display_labels(flip_idx);
strain_order_f = strain_order(flip_idx);
n_vials_f  = n_vials_arr(flip_idx);
n_flies_f  = n_flies_arr(flip_idx);
n_rm_f     = n_rm_arr(flip_idx);
prop_rm_f  = prop_rm_arr(flip_idx);

fig1 = figure('Position', [50 50 1200 900]);

% Panel A: Number of vials per strain (with axis break for control)
subplot(2, 2, 1);
draw_broken_bar_chart(gca, n_vials_f, bar_colors_f, display_labels_f, ...
    'Number of vials', 'A — Vials per strain', control_strain, strain_order_f);
set(gca, 'XTickLabel', []);

% Panel B: Total flies per strain (with axis break for control)
subplot(2, 2, 2);
draw_broken_bar_chart(gca, n_flies_f, bar_colors_f, display_labels_f, ...
    'Number of flies', 'B — Flies per strain (post-tracking)', control_strain, strain_order_f);
set(gca, 'XTickLabel', []);

% Panel C: Flies removed per strain
subplot(2, 2, 3);
draw_standard_bar_chart(gca, n_rm_f, bar_colors_f, display_labels_f, ...
    'Flies removed', 'C — Flies removed (poor tracking)');

% Panel D: Proportion removed per strain
subplot(2, 2, 4);
draw_standard_bar_chart(gca, prop_rm_f, bar_colors_f, display_labels_f, ...
    'Proportion removed', 'D — Proportion of flies removed');

f1 = gcf;
f1.Position = [193         278        1066         677];

if save_figs
    if ~isfolder(save_folder); mkdir(save_folder); end
    exportgraphics(fig1, fullfile(save_folder, 'figS1_dataset_composition.pdf'), ...
        'ContentType', 'vector');
end

%% 5 — Extract QC metrics (reuse VERIFY_QC_THRESHOLDS logic)

VEL_THRESHOLD   = 0.5;    % mm/s
QUIESCENCE_FRAC = 0.75;   % fraction of frames stationary to reject
DIST_THRESHOLD  = 110;    % mm — fly stuck near edge
N_CONDITIONS    = 12;
sex = 'F';

all_strain_names = fieldnames(DATA);

row_strain = {};
row_cond   = [];
row_frac_stationary = [];
row_rejected = [];

for s = 1:numel(all_strain_names)
    strain = all_strain_names{s};
    if ~isfield(DATA.(strain), sex); continue; end
    data = DATA.(strain).(sex);
    n_exp = length(data);

    for exp_idx = 1:n_exp
        for cond = 1:N_CONDITIONS
            for rep = 1:2
                rep_str = sprintf('R%d_condition_%d', rep, cond);
                if ~isfield(data(exp_idx), rep_str); continue; end
                rep_data = data(exp_idx).(rep_str);
                if isempty(rep_data); continue; end

                vel  = rep_data.vel_data;
                dist = rep_data.dist_data;
                n_flies  = size(vel, 1);
                n_frames = size(vel, 2);

                for fly = 1:n_flies
                    n_stationary = sum(vel(fly, :) < VEL_THRESHOLD, 'omitnan');
                    frac_stat = n_stationary / n_frames;
                    mdist = min(dist(fly, :), [], 'omitnan');

                    fq = frac_stat > QUIESCENCE_FRAC;
                    fdist = mdist > DIST_THRESHOLD;

                    row_strain{end+1, 1} = strain; %#ok<SAGROW>
                    row_cond(end+1, 1)   = cond; %#ok<SAGROW>
                    row_frac_stationary(end+1, 1) = frac_stat; %#ok<SAGROW>
                    row_rejected(end+1, 1) = fq || fdist; %#ok<SAGROW>
                end
            end
        end
    end
end

qc_table = table(row_strain, row_cond, row_frac_stationary, row_rejected, ...
    'VariableNames', {'Strain', 'Condition', 'FracStationary', 'Rejected'});

fprintf('Total rep-level observations for QC: %d\n', height(qc_table));

%% 6 — Figure 2: Fraction stationary histograms (condition 1 only)

n_rows = 9;
n_cols = 2;
fig2 = figure('Name', 'Fraction Stationary — Condition 1', 'Position', [50 50 1200 1000]);

% Plot in reverse order so that strain_order{1} is at the bottom
plot_order = flip(1:n_strains);

for subplot_idx = 1:n_strains
    subplot(n_rows, n_cols, subplot_idx);
    s = plot_order(subplot_idx);  % strain index (reversed)

    mask = strcmp(qc_table.Strain, strain_order{s}) & qc_table.Condition == 1;
    frac_vals = qc_table.FracStationary(mask);

    histogram(frac_vals, 20, 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', 'w', ...
        'Normalization', 'count');
    hold on;

    mean_val = mean(frac_vals, 'omitnan');
    xline(mean_val, '-', 'Color', 'r', 'LineWidth', 1.5);
    xline(QUIESCENCE_FRAC, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

    xlim([0 1]);

    % Strain name as y-axis label instead of title
    short_name = strrep(strain_order{s}, '_shibire_kir', '');
    short_name = strrep(short_name, '_', ' ');
    ylabel(short_name, 'FontSize', 10);
    set(gca, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

    % X-axis tick labels and label only on bottom subplots in each column
    is_bottom = (subplot_idx + n_cols > n_strains);
    if is_bottom
        xlabel('Frac. stationary', 'FontSize', 12);
    else
        set(gca, 'XTickLabel', []);
    end

    hold off;
end

% Blank remaining subplots
for subplot_idx = (n_strains + 1):(n_rows * n_cols)
    subplot(n_rows, n_cols, subplot_idx);
    axis off;
end

% sgtitle(sprintf('Fraction Stationary (vel < %.1f mm/s) — Condition 1\nRed = strain mean, Grey = rejection threshold (%.0f%%)', ...
%     VEL_THRESHOLD, QUIESCENCE_FRAC * 100), 'FontSize', 16);

f2 = gcf;
f2.Position = [443          50         437        1002];

if save_figs
    if ~isfolder(save_folder); mkdir(save_folder); end
    exportgraphics(fig2, fullfile(save_folder, 'figS1_fraction_stationary.pdf'), ...
        'ContentType', 'vector');
end

%% 7 — Figure 3: Rejection rate heatmap (strain x condition)

reject_matrix = NaN(n_strains, N_CONDITIONS);
for s = 1:n_strains
    strain = strain_order{s};
    for c = 1:N_CONDITIONS
        mask = strcmp(qc_table.Strain, strain) & qc_table.Condition == c;
        sub = qc_table(mask, :);
        if isempty(sub); continue; end
        reject_matrix(s, c) = 100 * sum(sub.Rejected) / height(sub);
    end
end

cond_titles = {'60deg 4Hz', '60deg 8Hz', 'ON bars', 'OFF bars', ...
    'ON curt.', 'OFF curt.', 'RevPhi 2Hz', 'RevPhi 4Hz', ...
    'Flicker', 'Static', 'Offset CoR', 'Bar fix.'};

% White-to-black sequential greyscale colormap
n_colors = 256;
grey_cmap = repmat(linspace(1, 0, n_colors)', 1, 3);

% Flip rows so strain_order{1} is at the bottom
reject_matrix_f = reject_matrix(flip_idx, :);
display_labels_f_heat = display_labels(flip_idx);

fig3 = figure('Position', [50 50 1000 600]);
imagesc(reject_matrix_f);
colormap(gca, grey_cmap);
cb = colorbar;
cb.Label.String = '% reps rejected';
cb.Label.FontSize = 12;
clim([0 50]);

xticks(1:N_CONDITIONS);
xticklabels(cond_titles);
xtickangle(45);
yticks(1:n_strains);
yticklabels(display_labels_f_heat);
xlabel('Condition', 'FontSize', 14);
ylabel('Strain', 'FontSize', 14);
title('% reps rejected (quiescence QC) — strain x condition', 'FontSize', 16);
set(gca, 'FontSize', 11, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Add percentage text in each cell
for r = 1:n_strains
    for c = 1:N_CONDITIONS
        val = reject_matrix_f(r, c);
        if isnan(val); continue; end
        % Use white text on dark cells, black on light cells
        if val > 25
            txt_color = 'w';
        else
            txt_color = 'k';
        end
        text(c, r, sprintf('%.0f', val), 'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', 'FontSize', 7, 'Color', txt_color);
    end
end

f3 = gcf;
f3.Position = [77   434   539   565];

if save_figs
    if ~isfolder(save_folder); mkdir(save_folder); end
    exportgraphics(fig3, fullfile(save_folder, 'figS1_rejection_heatmap.pdf'), ...
        'ContentType', 'vector');
end

%% 8 — Figure 4: Condition 1 QC rejection bar charts

n_rejected_c1 = zeros(n_strains, 1);
n_total_c1    = zeros(n_strains, 1);

for s = 1:n_strains
    mask = strcmp(qc_table.Strain, strain_order{s}) & qc_table.Condition == 1;
    sub = qc_table(mask, :);
    n_total_c1(s)    = height(sub);
    n_rejected_c1(s) = sum(sub.Rejected);
end

prop_rejected_c1 = n_rejected_c1 ./ n_total_c1;

% Flip to match figure 1 ordering
n_rejected_c1_f    = n_rejected_c1(flip_idx);
prop_rejected_c1_f = prop_rejected_c1(flip_idx);

fig4 = figure('Position', [50 50 1200 450]);

% Panel A: Number of reps rejected (condition 1)
subplot(1, 2, 1);
draw_standard_bar_chart(gca, n_rejected_c1_f, bar_colors_f, display_labels_f, ...
    'Reps rejected', 'A — Reps rejected (condition 1, quiescence QC)');

% Remove xticklabels
ax1 = gca;
ax1.XTickLabel = {''};

% Panel B: Proportion of reps rejected (condition 1)
subplot(1, 2, 2);
draw_standard_bar_chart(gca, prop_rejected_c1_f, bar_colors_f, display_labels_f, ...
    'Proportion rejected', 'B — Proportion rejected (condition 1, quiescence QC)');
ax2 = gca;
ax2.XTickLabel = {''};

f4 = gcf;
f4.Position = [ 192         648        1067         307];

if save_figs
    if ~isfolder(save_folder); mkdir(save_folder); end
    exportgraphics(fig4, fullfile(save_folder, 'figS1_cond1_qc_rejection.pdf'), ...
        'ContentType', 'vector');
end

%% ===== Local functions =====

function draw_broken_bar_chart(ax, values, colors, labels, ylabel_str, title_str, control_strain, strain_order)
%DRAW_BROKEN_BAR_CHART  Bar chart with axis break for the control strain.
    axes(ax); %#ok<LAXES>
    n = numel(values);

    % Find control index
    ctrl_idx = find(strcmp(strain_order, control_strain));

    % Determine y-limit from non-control strains
    other_vals = values;
    other_vals(ctrl_idx) = 0;
    y_cap = max(other_vals) * 1.3;

    % If control doesn't exceed the cap, draw a normal chart
    ctrl_val = values(ctrl_idx);
    needs_break = ctrl_val > y_cap;

    if needs_break
        % Truncate control value for plotting
        plot_vals = values;
        plot_vals(ctrl_idx) = y_cap * 0.92;
    else
        plot_vals = values;
        y_cap = max(values) * 1.3;
    end

    b = bar(1:n, plot_vals, 'FaceColor', 'flat', 'EdgeColor', [0 0 0], 'LineWidth', 0.5);
    b.CData = colors;
    hold on;

    % Add count labels on top of each bar
    for i = 1:n
        if i == ctrl_idx && needs_break
            % Label above the truncated bar with the real value
            text(i, plot_vals(i) + y_cap * 0.06, num2str(ctrl_val), ...
                'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
        else
            text(i, values(i) + y_cap * 0.03, num2str(round(values(i), 2)), ...
                'HorizontalAlignment', 'center', 'FontSize', 9);
        end
    end

    % Draw break marks on the truncated bar
    if needs_break
        bar_half_width = 0.4;
        break_y = plot_vals(ctrl_idx);
        mark_h = y_cap * 0.02;
        mark_w = bar_half_width * 0.35;

        x_left  = ctrl_idx - mark_w;
        x_right = ctrl_idx + mark_w;
        plot([x_left - mark_w, x_right - mark_w], [break_y - mark_h, break_y + mark_h], ...
            'k-', 'LineWidth', 1.5);
        plot([x_left + mark_w, x_right + mark_w], [break_y - mark_h, break_y + mark_h], ...
            'k-', 'LineWidth', 1.5);
    end

    ylim([0 y_cap]);
    set(gca, 'XTick', 1:n, 'XTickLabel', labels, 'FontSize', 10, ...
        'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
    xtickangle(45);
    ylabel(ylabel_str, 'FontSize', 14);
    title(title_str, 'FontSize', 14);
    hold off;
end

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
