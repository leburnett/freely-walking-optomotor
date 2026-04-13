%% P31_SPEED_TUNING_CENTRING — Speed tuning of centring + turning across strains
%
% SCRIPT CONTENTS:
%   - Section 1: Load Protocol 31 DATA
%   - Section 2: Extract tuning values for all strains × conditions
%   - Section 3: Plot 2×2 figure (turning + centring × 60deg + 15deg)
%   - Section 4: Print summary tables and statistics
%   - Local helper: extract_tuning_values
%
% DESCRIPTION:
%   Speed tuning curves for centring (dist_data_delta) and turning (av_data)
%   across all P31 strains. Protocol 31 tests 60-degree and 15-degree
%   gratings at 4 speeds (60, 120, 240, 480 deg/s) plus flicker.
%
% PROTOCOL 31 CONDITIONS:
%   Conds 1-5: 60deg gratings at 60/120/240/480 deg/s + flicker
%   Conds 6-10: 15deg gratings at 60/120/240/480 deg/s + flicker
%
% REQUIREMENTS:
%   - Results folder: results/protocol_31/
%   - Functions: comb_data_across_cohorts_cond, combine_timeseries_across_exp,
%     check_and_average_across_reps
%
% See also: analyse_p31_diff_speeds, plot_errorbar_tuning_diff_speeds,
%           cross_strain_condition_heatmaps

%% 1 — Load P31 DATA

if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_31');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
    fprintf('Loaded P31 DATA from %s\n', protocol_dir);
end

cfg = get_config();

save_figs = false;
save_folder = fullfile(cfg.figures, 'FIGS');

%% 2 — Extract tuning values for all strains

% Strain list — order: control first, then experimental
all_strains = fieldnames(DATA);

% Exclude strains
exclude_strains = {'csw1118', 'ss02360_Dm4_shibire_kir', 'ss2344_T4_shibire_kir'};

ctrl_name = 'jfrc100_es_shibire_kir';
other_strains = setdiff(all_strains, [{ctrl_name}; exclude_strains(:)]);
other_strains = sort(other_strains);
strain_order = [{ctrl_name}; other_strains];

% Remove any strains that don't exist in DATA
strain_order = strain_order(cellfun(@(s) isfield(DATA, s), strain_order));
n_strains = numel(strain_order);

% Clean labels for display
strain_labels = strrep(strain_order, '_', '-');
strain_labels = strrep(strain_labels, '-shibire-kir', '');

% Speed mapping: conditions → angular speed in deg/s
% 60deg: conds 1-5, 15deg: conds 6-10
speed_labels = {'0', '60', '120', '240', '480', 'Fl'};
speed_vals = [0, 60, 120, 240, 480, NaN];  % NaN for flicker

% Color scheme: control = grey, experimental = categorical palette
strain_colors = zeros(n_strains, 3);
strain_colors(1, :) = [0.7 0.7 0.7];  % control = grey

% Categorical palette for experimental strains (from CLAUDE.md)
cat_palette = [
    0.894 0.102 0.110;   % red
    0.216 0.494 0.722;   % blue
    0.302 0.686 0.290;   % green
    0.596 0.306 0.639;   % purple
    1.000 0.498 0.000;   % orange
];
for s = 2:n_strains
    ci = mod(s - 2, size(cat_palette, 1)) + 1;
    strain_colors(s, :) = cat_palette(ci, :);
end

% Preallocate: [n_strains × 6] for each metric (baseline + 5 conditions)
turning_vals60  = NaN(n_strains, 6);
turning_sem60   = NaN(n_strains, 6);
centring_vals60 = NaN(n_strains, 6);
centring_sem60  = NaN(n_strains, 6);
turning_vals15  = NaN(n_strains, 6);
turning_sem15   = NaN(n_strains, 6);
centring_vals15 = NaN(n_strains, 6);
centring_sem15  = NaN(n_strains, 6);
n_flies_per_strain = NaN(n_strains, 1);

% Also store per-fly values for statistics (cell arrays)
perfly_turning60  = cell(n_strains, 5);  % [strain × 5 conds]
perfly_centring60 = cell(n_strains, 5);
perfly_turning15  = cell(n_strains, 5);
perfly_centring15 = cell(n_strains, 5);

for s = 1:n_strains
    strain = strain_order{s};
    fprintf('Processing %s...\n', strain);

    % Extract turning (av_data) — 60deg conds 1-5, 15deg conds 6-10
    [tv60, ts60, tv15, ts15, nf_t, pf_t60, pf_t15] = ...
        extract_tuning_values(DATA, strain, 'av_data');
    turning_vals60(s, :) = tv60;
    turning_sem60(s, :)  = ts60;
    turning_vals15(s, :) = tv15;
    turning_sem15(s, :)  = ts15;

    % Extract centring (dist_data with delta)
    [cv60, cs60, cv15, cs15, nf_c, pf_c60, pf_c15] = ...
        extract_tuning_values(DATA, strain, 'dist_data_delta');
    centring_vals60(s, :) = cv60;
    centring_sem60(s, :)  = cs60;
    centring_vals15(s, :) = cv15;
    centring_sem15(s, :)  = cs15;

    n_flies_per_strain(s) = nf_c;

    % Store per-fly values for statistics
    perfly_turning60(s, :) = pf_t60;
    perfly_centring60(s, :) = pf_c60;
    perfly_turning15(s, :) = pf_t15;
    perfly_centring15(s, :) = pf_c15;
end

fprintf('\nExtraction complete.\n');

%% 3 — Plot 2×2 figure

fig = figure('Position', [50 50 1200 800]);

% Panel titles
panel_titles = {
    'Turning — 60\circ gratings', 'Centring — 60\circ gratings', ...
    'Turning — 15\circ gratings', 'Centring — 15\circ gratings'
};

% Data arrays for each panel
panel_vals = {turning_vals60, centring_vals60, turning_vals15, centring_vals15};
panel_sems = {turning_sem60, centring_sem60, turning_sem15, centring_sem15};
panel_ylabels = {
    'Angular velocity (deg/s)', 'Distance change (mm)', ...
    'Angular velocity (deg/s)', 'Distance change (mm)'
};

for p = 1:4
    subplot(2, 2, p);
    hold on;

    % Zero reference line
    yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

    for s = 1:n_strains
        col = strain_colors(s, :);
        lw = 1.2;
        if s == 1  % control thicker
            lw = 2.0;
        end

        vals = panel_vals{p}(s, :);
        sems = panel_sems{p}(s, :);

        errorbar(1:6, vals, sems, '-o', ...
            'Color', col, 'LineWidth', lw, ...
            'MarkerFaceColor', 'w', 'MarkerEdgeColor', col, ...
            'MarkerSize', 5, 'CapSize', 4);
    end

    xlim([0.5 6.5]);
    xticks(1:6);
    xticklabels(speed_labels);
    xlabel('Angular speed (deg/s)', 'FontSize', 14);
    ylabel(panel_ylabels{p}, 'FontSize', 14);
    title(panel_titles{p}, 'FontSize', 14);
    set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
end

sgtitle('P31 Speed Tuning — Centring & Turning', 'FontSize', 16);

% Add legend to first panel
subplot(2, 2, 1);
legend_entries = gobjects(n_strains, 1);
for s = 1:n_strains
    legend_entries(s) = plot(NaN, NaN, '-', 'Color', strain_colors(s,:), 'LineWidth', 1.5);
end
legend(legend_entries, strain_labels, ...
    'Location', 'northwest', 'FontSize', 7, 'Box', 'off');

if save_figs
    exportgraphics(fig, fullfile(save_folder, 'p31_speed_tuning.pdf'), ...
        'ContentType', 'vector');
    close(fig);
end

%% 4 — Print summary tables

% Find control index
ctrl_idx = find(strcmp(strain_order, ctrl_name));

fprintf('\n========================================\n');
fprintf('  P31 SPEED TUNING — SUMMARY\n');
fprintf('========================================\n');

fprintf('\n--- Fly counts ---\n');
for s = 1:n_strains
    fprintf('  %-30s  N = %d\n', strain_labels{s}, n_flies_per_strain(s));
end

% Print 60deg results
fprintf('\n--- 60-degree gratings ---\n');
fprintf('\nTurning (deg/s):\n');
fprintf('%-25s  %8s  %8s  %8s  %8s  %8s  %8s\n', ...
    'Strain', 'Base', '60', '120', '240', '480', 'Flicker');
fprintf('%s\n', repmat('-', 1, 80));
for s = 1:n_strains
    fprintf('%-25s', strain_labels{s});
    for c = 1:6
        fprintf('  %8.1f', turning_vals60(s, c));
    end
    fprintf('\n');
end

fprintf('\nCentring (mm, delta from baseline):\n');
fprintf('%-25s  %8s  %8s  %8s  %8s  %8s  %8s\n', ...
    'Strain', 'Base', '60', '120', '240', '480', 'Flicker');
fprintf('%s\n', repmat('-', 1, 80));
for s = 1:n_strains
    fprintf('%-25s', strain_labels{s});
    for c = 1:6
        fprintf('  %8.1f', centring_vals60(s, c));
    end
    fprintf('\n');
end

% Print 15deg results
fprintf('\n--- 15-degree gratings ---\n');
fprintf('\nTurning (deg/s):\n');
fprintf('%-25s  %8s  %8s  %8s  %8s  %8s  %8s\n', ...
    'Strain', 'Base', '60', '120', '240', '480', 'Flicker');
fprintf('%s\n', repmat('-', 1, 80));
for s = 1:n_strains
    fprintf('%-25s', strain_labels{s});
    for c = 1:6
        fprintf('  %8.1f', turning_vals15(s, c));
    end
    fprintf('\n');
end

fprintf('\nCentring (mm, delta from baseline):\n');
fprintf('%-25s  %8s  %8s  %8s  %8s  %8s  %8s\n', ...
    'Strain', 'Base', '60', '120', '240', '480', 'Flicker');
fprintf('%s\n', repmat('-', 1, 80));
for s = 1:n_strains
    fprintf('%-25s', strain_labels{s});
    for c = 1:6
        fprintf('  %8.1f', centring_vals15(s, c));
    end
    fprintf('\n');
end

% Statistics: Welch's t-test at each speed, strain vs control
fprintf('\n--- Statistics: Welch t-test vs control (p-values) ---\n');
fprintf('\n60-degree Turning:\n');
fprintf('%-25s  %10s  %10s  %10s  %10s  %10s\n', ...
    'Strain', '60', '120', '240', '480', 'Flicker');
fprintf('%s\n', repmat('-', 1, 80));
for s = 2:n_strains  % skip control
    fprintf('%-25s', strain_labels{s});
    for c = 1:5  % 5 speed conditions
        if ~isempty(perfly_turning60{s, c}) && ~isempty(perfly_turning60{ctrl_idx, c})
            [~, pval] = ttest2(perfly_turning60{ctrl_idx, c}, perfly_turning60{s, c}, ...
                'Vartype', 'unequal');
            fprintf('  %10.2e', pval);
        else
            fprintf('  %10s', 'N/A');
        end
    end
    fprintf('\n');
end

fprintf('\n60-degree Centring:\n');
fprintf('%-25s  %10s  %10s  %10s  %10s  %10s\n', ...
    'Strain', '60', '120', '240', '480', 'Flicker');
fprintf('%s\n', repmat('-', 1, 80));
for s = 2:n_strains
    fprintf('%-25s', strain_labels{s});
    for c = 1:5
        if ~isempty(perfly_centring60{s, c}) && ~isempty(perfly_centring60{ctrl_idx, c})
            [~, pval] = ttest2(perfly_centring60{ctrl_idx, c}, perfly_centring60{s, c}, ...
                'Vartype', 'unequal');
            fprintf('  %10.2e', pval);
        else
            fprintf('  %10s', 'N/A');
        end
    end
    fprintf('\n');
end

fprintf('\n15-degree Turning:\n');
fprintf('%-25s  %10s  %10s  %10s  %10s  %10s\n', ...
    'Strain', '60', '120', '240', '480', 'Flicker');
fprintf('%s\n', repmat('-', 1, 80));
for s = 2:n_strains
    fprintf('%-25s', strain_labels{s});
    for c = 1:5
        if ~isempty(perfly_turning15{s, c}) && ~isempty(perfly_turning15{ctrl_idx, c})
            [~, pval] = ttest2(perfly_turning15{ctrl_idx, c}, perfly_turning15{s, c}, ...
                'Vartype', 'unequal');
            fprintf('  %10.2e', pval);
        else
            fprintf('  %10s', 'N/A');
        end
    end
    fprintf('\n');
end

fprintf('\n15-degree Centring:\n');
fprintf('%-25s  %10s  %10s  %10s  %10s  %10s\n', ...
    'Strain', '60', '120', '240', '480', 'Flicker');
fprintf('%s\n', repmat('-', 1, 80));
for s = 2:n_strains
    fprintf('%-25s', strain_labels{s});
    for c = 1:5
        if ~isempty(perfly_centring15{s, c}) && ~isempty(perfly_centring15{ctrl_idx, c})
            [~, pval] = ttest2(perfly_centring15{ctrl_idx, c}, perfly_centring15{s, c}, ...
                'Vartype', 'unequal');
            fprintf('  %10.2e', pval);
        else
            fprintf('  %10s', 'N/A');
        end
    end
    fprintf('\n');
end

fprintf('\n=== Done ===\n');


%% ===== LOCAL HELPER FUNCTION =====

function [vals60, sem60, vals15, sem15, n_flies, perfly60, perfly15] = ...
        extract_tuning_values(DATA, strain, data_type)
% EXTRACT_TUNING_VALUES  Get speed tuning curve values for one strain.
%
%   Returns [1×6] arrays: [baseline, cond1-4, flicker] for 60deg and 15deg.
%   Also returns per-fly summary values for statistics (cell arrays).
%
%   Uses combine_timeseries_across_exp for quiescence-based QC.
%   Handles delta transformation for dist_data_delta.

    % Resolve delta data type
    [base_type, delta, ~] = resolve_delta_data_type(data_type);

    sex = 'F';
    data = DATA.(strain).(sex);

    % 60deg conditions: 1-5, 15deg conditions: 6-10
    conds_60 = 1:5;
    conds_15 = 6:10;

    vals60 = NaN(1, 6);  % [baseline, cond1-4, flicker]
    sem60  = NaN(1, 6);
    vals15 = NaN(1, 6);
    sem15  = NaN(1, 6);
    perfly60 = cell(1, 5);
    perfly15 = cell(1, 5);
    n_flies = 0;

    % --- Extract baseline (acclimation period) ---
    n_exp = length(data);
    acclim_data_all = [];

    for idx = 1:n_exp
        if isfield(data(idx), 'acclim_off1') && ~isempty(data(idx).acclim_off1)
            acclim_ts = data(idx).acclim_off1.(base_type);
            acclim_ts = acclim_ts(:, 1:min(8000, size(acclim_ts, 2)));

            % Trim to common frame count across experiments
            nf_new = size(acclim_ts, 2);
            nf_old = size(acclim_data_all, 2);
            if isempty(acclim_data_all)
                acclim_data_all = acclim_ts;
            elseif nf_new >= nf_old
                acclim_data_all = vertcat(acclim_data_all, acclim_ts(:, 1:nf_old)); %#ok<AGROW>
            else  % nf_old > nf_new — trim existing data
                acclim_data_all = acclim_data_all(:, 1:nf_new);
                acclim_data_all = vertcat(acclim_data_all, acclim_ts); %#ok<AGROW>
            end
        end
    end

    if ~isempty(acclim_data_all)
        mean_acclim = nanmean(acclim_data_all);
        if delta == 1
            vals60(1) = 0;  % delta baseline is zero by definition
            vals15(1) = 0;
        else
            vals60(1) = nanmean(mean_acclim);
            vals15(1) = nanmean(mean_acclim);
        end
        sem_acclim = nanstd(acclim_data_all) / sqrt(size(acclim_data_all, 1));
        sem60(1) = nanmean(sem_acclim);
        sem15(1) = nanmean(sem_acclim);
    end

    % --- Extract stimulus conditions ---
    for ci = 1:5  % 5 conditions per spatial frequency
        % 60deg
        cond_n = conds_60(ci);
        cond_data = combine_timeseries_across_exp(data, cond_n, base_type);

        if ~isempty(cond_data) && size(cond_data, 2) >= 1200
            if ci == 1
                n_flies = size(cond_data, 1);  % record fly count from first condition
            end

            mean_ts = nanmean(cond_data);

            % For av_data: flip second half of stimulus (direction reversal)
            if strcmp(base_type, 'av_data') || strcmp(base_type, 'curv_data')
                midpoint = 761;
                if length(mean_ts) >= midpoint
                    mean_ts = [mean_ts(1:midpoint), mean_ts(midpoint+1:end) * -1];
                end
            end

            if delta == 1
                mean_ts = mean_ts - mean_ts(300);
            end

            vals60(ci + 1) = nanmean(mean_ts(300:1200));
            sem_ts = nanstd(cond_data) / sqrt(size(cond_data, 1));
            sem60(ci + 1) = nanmean(sem_ts(300:1200));

            % Per-fly summary values for statistics
            fly_vals = NaN(size(cond_data, 1), 1);
            for f = 1:size(cond_data, 1)
                fly_ts = cond_data(f, :);
                if strcmp(base_type, 'av_data') || strcmp(base_type, 'curv_data')
                    if length(fly_ts) >= 761
                        fly_ts = [fly_ts(1:761), fly_ts(762:end) * -1];
                    end
                end
                if delta == 1
                    fly_ts = fly_ts - fly_ts(300);
                end
                fly_vals(f) = nanmean(fly_ts(300:min(1200, length(fly_ts))));
            end
            fly_vals = fly_vals(~isnan(fly_vals));
            perfly60{ci} = fly_vals;
        end

        % 15deg
        cond_n = conds_15(ci);
        cond_data = combine_timeseries_across_exp(data, cond_n, base_type);

        if ~isempty(cond_data) && size(cond_data, 2) >= 1200
            mean_ts = nanmean(cond_data);

            if strcmp(base_type, 'av_data') || strcmp(base_type, 'curv_data')
                midpoint = 761;
                if length(mean_ts) >= midpoint
                    mean_ts = [mean_ts(1:midpoint), mean_ts(midpoint+1:end) * -1];
                end
            end

            if delta == 1
                mean_ts = mean_ts - mean_ts(300);
            end

            vals15(ci + 1) = nanmean(mean_ts(300:1200));
            sem_ts = nanstd(cond_data) / sqrt(size(cond_data, 1));
            sem15(ci + 1) = nanmean(sem_ts(300:1200));

            % Per-fly summary
            fly_vals = NaN(size(cond_data, 1), 1);
            for f = 1:size(cond_data, 1)
                fly_ts = cond_data(f, :);
                if strcmp(base_type, 'av_data') || strcmp(base_type, 'curv_data')
                    if length(fly_ts) >= 761
                        fly_ts = [fly_ts(1:761), fly_ts(762:end) * -1];
                    end
                end
                if delta == 1
                    fly_ts = fly_ts - fly_ts(300);
                end
                fly_vals(f) = nanmean(fly_ts(300:min(1200, length(fly_ts))));
            end
            fly_vals = fly_vals(~isnan(fly_vals));
            perfly15{ci} = fly_vals;
        end
    end
end
