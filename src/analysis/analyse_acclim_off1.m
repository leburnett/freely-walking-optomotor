%% analyse_acclim_off1 — Baseline acclimation heatmap (dark period)
%
% Computes mean FV, AV, distance from centre, and IFD during the dark
% acclimation period (acclim_off1) for each strain, then displays a
% heatmap of the difference from the ES control. Cell text shows the
% absolute metric value.
%
% REQUIREMENTS:
%   - Protocol 27 data via comb_data_across_cohorts_cond
%   - Functions: get_config, comb_data_across_cohorts_cond
%
% See also: figS1, verify_baseline_activity

%% 1 — Configuration & data loading

cfg = get_config();
protocol_dir = fullfile(cfg.results, 'protocol_27');

if ~exist('DATA', 'var') || isempty(fieldnames(DATA))
    fprintf('Loading Protocol 27 data from: %s\n', protocol_dir);
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

save_figs = false;
save_folder = fullfile(cfg.figures, 'FIGS');

%% 2 — Strain ordering (same as figS1 Figure 3)

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

display_labels = strrep(strain_order, '_shibire_kir', '');
display_labels = strrep(display_labels, '_', '-');

metric_names = {'FV', 'AV', 'Dist', 'IFD'};
data_fields  = {'fv_data', 'av_data', 'dist_data', 'IFD_data'};
n_metrics = numel(metric_names);
sex = 'F';

%% 3 — Compute per-strain mean metrics from acclim_off1

metrics_matrix = NaN(n_strains, n_metrics);
ctrl_sd = NaN(1, n_metrics);  % SD of per-fly means for control strain

for s = 1:n_strains
    strain = strain_order{s};
    if ~isfield(DATA, strain) || ~isfield(DATA.(strain), sex)
        warning('Strain %s not found in DATA, skipping.', strain);
        continue;
    end
    data = DATA.(strain).(sex);
    n_exp = length(data);

    % Collect per-fly means across all cohorts
    fly_means = cell(1, n_metrics);
    for m = 1:n_metrics
        fly_means{m} = [];
    end

    for exp_idx = 1:n_exp
        if ~isfield(data(exp_idx), 'acclim_off1') || isempty(data(exp_idx).acclim_off1)
            continue;
        end
        acclim = data(exp_idx).acclim_off1;

        for m = 1:n_metrics
            field = data_fields{m};
            if ~isfield(acclim, field); continue; end
            raw = acclim.(field);  % [n_flies x n_frames]
            per_fly = nanmean(raw, 2);  %#ok<NANMEAN>
            fly_means{m} = [fly_means{m}; per_fly];
        end
    end

    for m = 1:n_metrics
        if ~isempty(fly_means{m})
            metrics_matrix(s, m) = nanmean(fly_means{m});  %#ok<NANMEAN>
        end
    end

    % Store per-fly SD for the control strain
    if strcmp(strain, control_strain)
        for m = 1:n_metrics
            if ~isempty(fly_means{m})
                ctrl_sd(m) = nanstd(fly_means{m});  %#ok<NANSTD>
            end
        end
    end
end

%% 4 — Compute difference from control (in SD units)

ctrl_idx = find(strcmp(strain_order, control_strain));
ctrl_vals = metrics_matrix(ctrl_idx, :);
diff_matrix = metrics_matrix - ctrl_vals;

% Z-score: difference normalised by the control fly-to-fly SD
zscore_matrix = diff_matrix ./ ctrl_sd;

fprintf('\nControl SD per metric: FV=%.2f  AV=%.2f  Dist=%.2f  IFD=%.2f\n', ctrl_sd);

% Print summary
fprintf('\n=== Acclim_off1 mean metrics per strain ===\n');
fprintf('%-35s %8s %8s %8s %8s\n', 'Strain', metric_names{:});
fprintf('%s\n', repmat('-', 1, 67));
for s = 1:n_strains
    fprintf('%-35s %8.1f %8.1f %8.1f %8.1f\n', ...
        strain_order{s}, metrics_matrix(s, :));
end
fprintf('\nControl values: FV=%.1f  AV=%.1f  Dist=%.1f  IFD=%.1f\n', ctrl_vals);

%% 5 — Plot heatmap

% Flip row order (same as figS1 Figure 3)
flip_idx = flip(1:n_strains);
diff_matrix_f    = diff_matrix(flip_idx, :);
metrics_matrix_f = metrics_matrix(flip_idx, :);
display_labels_f = display_labels(flip_idx);

% Z-score matrix (flipped)
zscore_matrix_f = zscore_matrix(flip_idx, :);

% Blue-white-red diverging colormap
half = 128;
blue_half = [linspace(0.2, 1, half)', linspace(0.2, 1, half)', linspace(0.8, 1, half)'];
red_half  = [linspace(1, 0.8, half)', linspace(1, 0.2, half)', linspace(1, 0.2, half)'];
bwr_cmap = [blue_half; red_half];

% Symmetric clim based on the data range (columns that are all near zero
% will appear white; columns with large z-scores will be saturated)
max_z = max(abs(zscore_matrix_f(:)), [], 'omitnan');
if max_z == 0; max_z = 1; end

figure('Position', [50 50 500 600]);
imagesc(zscore_matrix_f);
colormap(gca, bwr_cmap);
clim([-max_z, max_z]);
cb = colorbar;
cb.Label.String = 'SDs from control mean';
cb.Label.FontSize = 12;

xticks(1:n_metrics);
xticklabels(metric_names);
yticks(1:n_strains);
yticklabels(display_labels_f);
xlabel('Metric', 'FontSize', 14);
ylabel('Strain', 'FontSize', 14);
title('Baseline activity (acclim\_off1) — difference from ES control', 'FontSize', 14);
set(gca, 'FontSize', 11, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Add absolute metric values as text in each cell
for r = 1:n_strains
    for m = 1:n_metrics
        val = metrics_matrix_f(r, m);
        z_val = zscore_matrix_f(r, m);
        if isnan(val); continue; end
        if abs(z_val) > max_z * 0.5
            txt_color = 'w';
        else
            txt_color = 'k';
        end
        text(m, r, sprintf('%.1f', val), 'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'middle', 'FontSize', 8, 'Color', txt_color);
    end
end

if save_figs
    if ~isfolder(save_folder); mkdir(save_folder); end
    exportgraphics(gcf, fullfile(save_folder, 'acclim_off1_baseline_heatmap.pdf'), ...
        'ContentType', 'vector');
end
