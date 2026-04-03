%% QC_SENSITIVITY_ANALYSIS - Test whether manuscript conclusions are robust to QC threshold choice
%
% Sweeps the quiescence_frac parameter (fraction of stationary frames to
% trigger rejection) across a range of values and re-runs key statistical
% comparisons at each threshold. Also sweeps vel_threshold as a secondary
% analysis.
%
% For each threshold, computes:
%   - N flies retained per strain
%   - Mean centring magnitude (dist_data_delta at stimulus end)
%   - Mean turning magnitude (curv_data during stimulus)
%   - Welch's t-test p-value vs control
%   - Cohen's d effect size vs control
%
% KEY CONCLUSIONS TESTED:
%   1. Control flies centre (dist_data_delta < 0)
%   2. T4/T5 has reduced turning (cond 1)
%   3. T4/T5 still centres to narrow gratings (cond 3)
%   4. Dm4 has reduced centring (cond 1)
%   5. Tm5Y has enhanced centring (cond 1)
%
% OUTPUT:
%   - 2x2 figure: rejection rates, metric values, p-values, effect sizes
%   - Console summary of conclusion robustness
%   - CSV with full sweep results
%
% See also: combine_timeseries_across_exp_check, check_and_average_across_reps

%% 1 - Configuration

cfg = get_config();
protocol_dir = fullfile(cfg.results, 'protocol_27');

% Load DATA (reuse from workspace if available)
if ~exist('DATA', 'var') || isempty(fieldnames(DATA))
    fprintf('Loading Protocol 27 data...\n');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
    fprintf('Done.\n');
end

% Save folder
save_folder = fullfile(cfg.figures, 'FIGS');
if ~isfolder(save_folder), mkdir(save_folder); end

% --- Sweep parameters ---
% Primary sweep: vary quiescence_frac with vel_threshold fixed
qf_values = [0.50, 0.75, 0.90, 1.00];  % 1.0 = no activity QC
VEL_THRESHOLD_FIXED = 0.5;  % mm/s

% Secondary sweep: vary vel_threshold with quiescence_frac fixed
vt_values = [0.3, 0.5, 1.0];  % mm/s
QF_FIXED = 0.75;

DIST_THRESHOLD = 110;  % mm — always applied

% --- Key strains and conditions ---
key_strains = {'ss324_t4t5_shibire_kir', 'ss00297_Dm4_shibire_kir', ...
               'ss03722_Tm5Y_shibire_kir', 'ss34318_Am1_shibire_kir'};
key_strain_labels = {'T4/T5', 'Dm4', 'Tm5Y', 'Am1'};
control_strain = 'jfrc100_es_shibire_kir';

key_conditions = [1, 3, 9, 10];
key_cond_labels = {'60deg 4Hz', 'narrow ON 4Hz', 'flicker', 'static'};

sex = 'F';

% Frame ranges for metrics
RNG_STIM_END = 1170:1200;  % last 1s of stimulus
RNG_STIM = 300:1200;       % entire stimulus
FRAME_BASELINE = 300;       % stimulus onset frame

%% 2 - Primary sweep: quiescence_frac

fprintf('\n=== PRIMARY SWEEP: quiescence_frac ===\n');
fprintf('vel_threshold = %.1f mm/s (fixed), dist_threshold = %d mm\n\n', VEL_THRESHOLD_FIXED, DIST_THRESHOLD);

n_qf = numel(qf_values);
n_strains = numel(key_strains);
n_conds = numel(key_conditions);

% Preallocate results: [n_qf x n_strains x n_conds]
results_n = zeros(n_qf, n_strains + 1, n_conds);       % +1 for control
results_centring = NaN(n_qf, n_strains + 1, n_conds);   % mean dist_data_delta at end
results_turning = NaN(n_qf, n_strains + 1, n_conds);    % mean curv during stim
results_p_centring = NaN(n_qf, n_strains, n_conds);     % p vs control
results_p_turning = NaN(n_qf, n_strains, n_conds);
results_d_centring = NaN(n_qf, n_strains, n_conds);     % Cohen's d
results_d_turning = NaN(n_qf, n_strains, n_conds);

for qi = 1:n_qf
    qf = qf_values(qi);
    fprintf('quiescence_frac = %.2f\n', qf);

    for ci = 1:n_conds
        cond = key_conditions(ci);

        % --- Control data ---
        ctrl_dist = combine_timeseries_across_exp_check(DATA.(control_strain).(sex), cond, 'dist_data', ...
            'vel_threshold', VEL_THRESHOLD_FIXED, 'quiescence_frac', qf);
        ctrl_curv = combine_timeseries_across_exp_check(DATA.(control_strain).(sex), cond, 'curv_data', ...
            'vel_threshold', VEL_THRESHOLD_FIXED, 'quiescence_frac', qf);

        % Baseline distance
        ctrl_dist_delta = ctrl_dist - ctrl_dist(:, FRAME_BASELINE);
        ctrl_centring_vals = nanmean(ctrl_dist_delta(:, RNG_STIM_END), 2);  % per fly
        ctrl_turning_vals = nanmean(ctrl_curv(:, RNG_STIM), 2);

        results_n(qi, n_strains + 1, ci) = sum(~isnan(ctrl_centring_vals));
        results_centring(qi, n_strains + 1, ci) = nanmean(ctrl_centring_vals);
        results_turning(qi, n_strains + 1, ci) = nanmean(ctrl_turning_vals);

        for si = 1:n_strains
            strain = key_strains{si};

            % --- Strain data ---
            strain_dist = combine_timeseries_across_exp_check(DATA.(strain).(sex), cond, 'dist_data', ...
                'vel_threshold', VEL_THRESHOLD_FIXED, 'quiescence_frac', qf);
            strain_curv = combine_timeseries_across_exp_check(DATA.(strain).(sex), cond, 'curv_data', ...
                'vel_threshold', VEL_THRESHOLD_FIXED, 'quiescence_frac', qf);

            % Baseline distance
            strain_dist_delta = strain_dist - strain_dist(:, FRAME_BASELINE);
            strain_centring_vals = nanmean(strain_dist_delta(:, RNG_STIM_END), 2);
            strain_turning_vals = nanmean(strain_curv(:, RNG_STIM), 2);

            n_valid = sum(~isnan(strain_centring_vals));
            results_n(qi, si, ci) = n_valid;
            results_centring(qi, si, ci) = nanmean(strain_centring_vals);
            results_turning(qi, si, ci) = nanmean(strain_turning_vals);

            % --- Welch's t-test vs control ---
            s_vals = strain_centring_vals(~isnan(strain_centring_vals));
            c_vals = ctrl_centring_vals(~isnan(ctrl_centring_vals));
            if numel(s_vals) >= 3 && numel(c_vals) >= 3
                [~, results_p_centring(qi, si, ci)] = ttest2(s_vals, c_vals, 'Vartype', 'unequal');
                % Cohen's d
                pooled_sd = sqrt(((numel(s_vals)-1)*var(s_vals) + (numel(c_vals)-1)*var(c_vals)) / ...
                    (numel(s_vals) + numel(c_vals) - 2));
                if pooled_sd > 0
                    results_d_centring(qi, si, ci) = (mean(s_vals) - mean(c_vals)) / pooled_sd;
                end
            end

            s_vals_t = strain_turning_vals(~isnan(strain_turning_vals));
            c_vals_t = ctrl_turning_vals(~isnan(ctrl_turning_vals));
            if numel(s_vals_t) >= 3 && numel(c_vals_t) >= 3
                [~, results_p_turning(qi, si, ci)] = ttest2(s_vals_t, c_vals_t, 'Vartype', 'unequal');
                pooled_sd_t = sqrt(((numel(s_vals_t)-1)*var(s_vals_t) + (numel(c_vals_t)-1)*var(c_vals_t)) / ...
                    (numel(s_vals_t) + numel(c_vals_t) - 2));
                if pooled_sd_t > 0
                    results_d_turning(qi, si, ci) = (mean(s_vals_t) - mean(c_vals_t)) / pooled_sd_t;
                end
            end
        end
    end
end

%% 3 - Results table

fprintf('\n=== SUMMARY TABLE ===\n');
fprintf('%-12s %-8s %-12s %8s %12s %12s %10s %10s\n', ...
    'Strain', 'QF', 'Condition', 'N', 'Centring', 'Turning', 'p_centr', 'Cohen_d');

for ci = 1:n_conds
    for si = 1:n_strains
        for qi = 1:n_qf
            fprintf('%-12s %-8.2f %-12s %8d %12.2f %12.4f %10.4f %10.2f\n', ...
                key_strain_labels{si}, qf_values(qi), key_cond_labels{ci}, ...
                results_n(qi, si, ci), results_centring(qi, si, ci), ...
                results_turning(qi, si, ci), results_p_centring(qi, si, ci), ...
                results_d_centring(qi, si, ci));
        end
        fprintf('\n');
    end
end

% Control N and centring for reference
fprintf('\n--- Control reference ---\n');
for ci = 1:n_conds
    for qi = 1:n_qf
        fprintf('Control  QF=%.2f  %-12s  N=%d  centring=%.2f\n', ...
            qf_values(qi), key_cond_labels{ci}, ...
            results_n(qi, n_strains+1, ci), results_centring(qi, n_strains+1, ci));
    end
end

%% 4 - Figures (2x2) — Primary sweep (quiescence_frac), condition 1

cond_idx = 1;  % Condition 1: 60deg gratings 4Hz

% Colors for strains
colors = lines(n_strains + 1);
ctrl_color = [0.5 0.5 0.5];

figure('Name', 'QC Sensitivity Analysis — Primary Sweep', 'Position', [50 50 1000 800]);
tl = tiledlayout(2, 2, 'TileSpacing', 'loose', 'Padding', 'compact');

% --- Panel A: N flies retained vs threshold ---
nexttile;
hold on;
for si = 1:n_strains
    plot(qf_values, results_n(:, si, cond_idx), '-o', 'LineWidth', 1.5, ...
        'Color', colors(si, :), 'MarkerSize', 6, 'MarkerFaceColor', colors(si, :));
end
plot(qf_values, results_n(:, n_strains+1, cond_idx), '-o', 'LineWidth', 1.5, ...
    'Color', ctrl_color, 'MarkerSize', 6, 'MarkerFaceColor', ctrl_color);
xline(0.75, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xlabel('Quiescence fraction threshold', 'FontSize', 14);
ylabel('N flies retained', 'FontSize', 14);
title('A. Sample size vs threshold', 'FontSize', 16);
legend([key_strain_labels, {'Control'}], 'Location', 'best', 'FontSize', 9);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
hold off;

% --- Panel B: Centring magnitude vs threshold ---
nexttile;
hold on;
for si = 1:n_strains
    plot(qf_values, results_centring(:, si, cond_idx), '-o', 'LineWidth', 1.5, ...
        'Color', colors(si, :), 'MarkerSize', 6, 'MarkerFaceColor', colors(si, :));
end
plot(qf_values, results_centring(:, n_strains+1, cond_idx), '-o', 'LineWidth', 1.5, ...
    'Color', ctrl_color, 'MarkerSize', 6, 'MarkerFaceColor', ctrl_color);
xline(0.75, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xlabel('Quiescence fraction threshold', 'FontSize', 14);
ylabel('Mean dist\_data\_delta (mm)', 'FontSize', 14);
title('B. Centring magnitude vs threshold', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
hold off;

% --- Panel C: p-value vs threshold ---
nexttile;
hold on;
for si = 1:n_strains
    plot(qf_values, results_p_centring(:, si, cond_idx), '-o', 'LineWidth', 1.5, ...
        'Color', colors(si, :), 'MarkerSize', 6, 'MarkerFaceColor', colors(si, :));
end
xline(0.75, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
yline(0.05, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xlabel('Quiescence fraction threshold', 'FontSize', 14);
ylabel('p-value (vs control)', 'FontSize', 14);
title('C. Centring p-value vs threshold', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2, 'YScale', 'log');
hold off;

% --- Panel D: Cohen's d vs threshold ---
nexttile;
hold on;
for si = 1:n_strains
    plot(qf_values, results_d_centring(:, si, cond_idx), '-o', 'LineWidth', 1.5, ...
        'Color', colors(si, :), 'MarkerSize', 6, 'MarkerFaceColor', colors(si, :));
end
xline(0.75, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xlabel('Quiescence fraction threshold', 'FontSize', 14);
ylabel('Cohen''s d (vs control)', 'FontSize', 14);
title('D. Effect size vs threshold', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
hold off;

title(tl, 'QC Sensitivity: Condition 1 (60deg gratings 4Hz)', 'FontSize', 18);

%% 5 - Conclusion robustness check

fprintf('\n=== CONCLUSION ROBUSTNESS ===\n\n');

% Conclusion 1: Control flies centre (cond 1)
fprintf('1. Control flies centre (dist_data_delta < 0, cond 1):\n');
for qi = 1:n_qf
    ctrl_vals_check = results_centring(qi, n_strains+1, 1);
    status = 'PASS';
    if ctrl_vals_check >= 0, status = '** FAIL **'; end
    fprintf('   QF=%.2f: centring = %.2f mm  [%s]\n', qf_values(qi), ctrl_vals_check, status);
end

% Conclusion 2: T4/T5 has reduced turning (cond 1)
fprintf('\n2. T4/T5 reduced turning (cond 1):\n');
si_t4t5 = 1;
for qi = 1:n_qf
    p = results_p_turning(qi, si_t4t5, 1);
    status = 'PASS'; if isnan(p) || p >= 0.05, status = '** FAIL **'; end
    fprintf('   QF=%.2f: p=%.4f  [%s]\n', qf_values(qi), p, status);
end

% Conclusion 3: T4/T5 still centres to narrow gratings (cond 3)
fprintf('\n3. T4/T5 still centres to narrow gratings (cond 3, p > 0.05 = not different from control):\n');
ci_narrow = find(key_conditions == 3);
for qi = 1:n_qf
    p = results_p_centring(qi, si_t4t5, ci_narrow);
    strain_val = results_centring(qi, si_t4t5, ci_narrow);
    status = 'PASS'; if ~isnan(p) && p < 0.05, status = '** FAIL ** (significantly different)'; end
    fprintf('   QF=%.2f: centring=%.2f, p=%.4f  [%s]\n', qf_values(qi), strain_val, p, status);
end

% Conclusion 4: Dm4 has reduced centring (cond 1)
fprintf('\n4. Dm4 reduced centring (cond 1):\n');
si_dm4 = 2;
for qi = 1:n_qf
    p = results_p_centring(qi, si_dm4, 1);
    d = results_d_centring(qi, si_dm4, 1);
    status = 'PASS'; if isnan(p) || p >= 0.05, status = '** FAIL **'; end
    fprintf('   QF=%.2f: p=%.4f, d=%.2f  [%s]\n', qf_values(qi), p, d, status);
end

% Conclusion 5: Tm5Y enhanced centring (cond 1)
fprintf('\n5. Tm5Y enhanced centring (cond 1, more negative than control):\n');
si_tm5y = 3;
for qi = 1:n_qf
    p = results_p_centring(qi, si_tm5y, 1);
    strain_val = results_centring(qi, si_tm5y, 1);
    ctrl_val = results_centring(qi, n_strains+1, 1);
    more_neg = strain_val < ctrl_val;
    status = 'PASS';
    if isnan(p) || p >= 0.05 || ~more_neg, status = '** FAIL **'; end
    fprintf('   QF=%.2f: strain=%.2f, ctrl=%.2f, p=%.4f  [%s]\n', ...
        qf_values(qi), strain_val, ctrl_val, p, status);
end

%% 6 - Secondary sweep: vel_threshold

fprintf('\n\n=== SECONDARY SWEEP: vel_threshold ===\n');
fprintf('quiescence_frac = %.2f (fixed)\n\n', QF_FIXED);

n_vt = numel(vt_values);
results_vt_n = zeros(n_vt, n_strains + 1);
results_vt_centring = NaN(n_vt, n_strains + 1);
results_vt_p = NaN(n_vt, n_strains);
results_vt_d = NaN(n_vt, n_strains);

cond_for_vt = 1;  % Condition 1

for vi = 1:n_vt
    vt = vt_values(vi);

    % Control
    ctrl_dist = combine_timeseries_across_exp_check(DATA.(control_strain).(sex), cond_for_vt, 'dist_data', ...
        'vel_threshold', vt, 'quiescence_frac', QF_FIXED);
    ctrl_dist_delta = ctrl_dist - ctrl_dist(:, FRAME_BASELINE);
    ctrl_vals = nanmean(ctrl_dist_delta(:, RNG_STIM_END), 2);
    ctrl_vals_clean = ctrl_vals(~isnan(ctrl_vals));
    results_vt_n(vi, n_strains + 1) = numel(ctrl_vals_clean);
    results_vt_centring(vi, n_strains + 1) = mean(ctrl_vals_clean);

    for si = 1:n_strains
        strain = key_strains{si};
        strain_dist = combine_timeseries_across_exp_check(DATA.(strain).(sex), cond_for_vt, 'dist_data', ...
            'vel_threshold', vt, 'quiescence_frac', QF_FIXED);
        strain_dist_delta = strain_dist - strain_dist(:, FRAME_BASELINE);
        s_vals = nanmean(strain_dist_delta(:, RNG_STIM_END), 2);
        s_vals_clean = s_vals(~isnan(s_vals));

        results_vt_n(vi, si) = numel(s_vals_clean);
        results_vt_centring(vi, si) = mean(s_vals_clean);

        if numel(s_vals_clean) >= 3 && numel(ctrl_vals_clean) >= 3
            [~, results_vt_p(vi, si)] = ttest2(s_vals_clean, ctrl_vals_clean, 'Vartype', 'unequal');
            pooled_sd = sqrt(((numel(s_vals_clean)-1)*var(s_vals_clean) + ...
                (numel(ctrl_vals_clean)-1)*var(ctrl_vals_clean)) / ...
                (numel(s_vals_clean) + numel(ctrl_vals_clean) - 2));
            if pooled_sd > 0
                results_vt_d(vi, si) = (mean(s_vals_clean) - mean(ctrl_vals_clean)) / pooled_sd;
            end
        end
    end
end

fprintf('%-12s %-8s %8s %12s %10s %10s\n', 'Strain', 'VelThr', 'N', 'Centring', 'p', 'Cohen_d');
for si = 1:n_strains
    for vi = 1:n_vt
        fprintf('%-12s %-8.1f %8d %12.2f %10.4f %10.2f\n', ...
            key_strain_labels{si}, vt_values(vi), results_vt_n(vi, si), ...
            results_vt_centring(vi, si), results_vt_p(vi, si), results_vt_d(vi, si));
    end
    fprintf('\n');
end

%% 7 - Export

% Build export table for primary sweep
export_rows = {};
row_idx = 0;
for ci = 1:n_conds
    for si = 1:n_strains
        for qi = 1:n_qf
            row_idx = row_idx + 1;
            export_rows{row_idx, 1} = key_strain_labels{si};
            export_rows{row_idx, 2} = qf_values(qi);
            export_rows{row_idx, 3} = VEL_THRESHOLD_FIXED;
            export_rows{row_idx, 4} = key_cond_labels{ci};
            export_rows{row_idx, 5} = key_conditions(ci);
            export_rows{row_idx, 6} = results_n(qi, si, ci);
            export_rows{row_idx, 7} = results_centring(qi, si, ci);
            export_rows{row_idx, 8} = results_turning(qi, si, ci);
            export_rows{row_idx, 9} = results_p_centring(qi, si, ci);
            export_rows{row_idx, 10} = results_d_centring(qi, si, ci);
            export_rows{row_idx, 11} = results_p_turning(qi, si, ci);
            export_rows{row_idx, 12} = results_d_turning(qi, si, ci);
        end
    end
end

export_table = cell2table(export_rows, 'VariableNames', ...
    {'Strain', 'QuiescenceFrac', 'VelThreshold', 'ConditionLabel', 'ConditionN', ...
     'N_Flies', 'MeanCentring', 'MeanTurning', 'p_Centring', 'd_Centring', ...
     'p_Turning', 'd_Turning'});

writetable(export_table, fullfile(save_folder, 'qc_sensitivity_analysis.csv'));
fprintf('\nResults saved to: %s\n', fullfile(save_folder, 'qc_sensitivity_analysis.csv'));

% exportgraphics(gcf, fullfile(save_folder, 'qc_sensitivity_analysis.pdf'), 'ContentType', 'vector');
