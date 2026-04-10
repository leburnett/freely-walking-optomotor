%% fig5 — ES vs T4T5 speed tuning comparison (Protocol 31)
%
% Generates:
%   1. Time series: ES + T4T5 responding to 60deg 4Hz gratings (1 figure)
%   2. Time series: ES + T4T5 responding to 15deg 16Hz gratings (1 figure)
%   3. Violin plots: ES + T4T5 across 4 speeds, 60deg (4 figures, 1 per metric)
%   4. Violin plots: ES + T4T5 across 4 speeds, 15deg (4 figures, 1 per metric)
%   5. Errorbar tuning curves: turning rate vs stimulus speed for both strains
%      (2 figures: 60deg and 15deg)
%
% REQUIREMENTS:
%   - Protocol 31 data via comb_data_across_cohorts_cond
%   - Functions: plot_xcond_per_strain_p31, plot_violin,
%     combine_timeseries_across_exp_check, combine_timeseries_across_exp,
%     check_and_average_across_reps, get_ylb_from_data_type
%
% See also: fig2, ANALYSE_P31_DIFF_SPEEDS, p31_speed_tuning_centring

%% 1 — Configuration & data loading

cfg = get_config();
protocol_dir = fullfile(cfg.results, 'protocol_31');

if ~exist('DATA_31', 'var') || isempty(fieldnames(DATA_31))
    fprintf('Loading Protocol 31 data from: %s\n', protocol_dir);
    DATA_31 = comb_data_across_cohorts_cond(protocol_dir);
end

sex = 'F';

strain_es   = 'jfrc100_es_shibire_kir';
strain_t4t5 = 'ss324_t4t5_shibire_kir';

% Colours per spatial frequency (from cmap_config)
cmaps = cmap_config();
col_es_60   = cmaps.es_vs_t4t5.colors(1,:);  % dark grey
col_t4t5_60 = cmaps.es_vs_t4t5.colors(2,:);  % orange
col_es_15   = cmaps.es_vs_t4t5.colors(3,:);  % light grey
col_t4t5_15 = cmaps.es_vs_t4t5.colors(4,:);  % yellow

%% 2 — Condition setup

% 60deg gratings: conds 1-4 (1Hz, 2Hz, 4Hz, 8Hz)
cond_60 = [1, 2, 3, 4];
labels_60 = {'1 Hz', '2 Hz', '4 Hz', '8 Hz'};
speeds_60 = [60, 120, 240, 480];  % deg/s

% 15deg gratings: conds 6-9 (4Hz, 8Hz, 16Hz, 32Hz)
cond_15 = [6, 7, 8, 9];
labels_15 = {'4 Hz', '8 Hz', '16 Hz', '32 Hz'};
speeds_15 = [60, 120, 240, 480];  % deg/s (matched angular speed)

% Speed colourmap (from cmap_config)
col_12 = cmaps.conditions_p31.colors;

% Metrics
metrics = { ...
    "fv_data",    0,  300:1200,   'Forward velocity (stimulus)'; ...
    "av_data",    0,  300:1200,   'Angular velocity (stimulus)'; ...
    "curv_data",  0,  300:1200,   'Turning rate (stimulus)'; ...
    "dist_data",  1,  1170:1200,  'Centring at end of stimulus'; ...
};
n_metrics = size(metrics, 1);

ts_params.save_figs    = 0;
ts_params.plot_sem     = 1;
ts_params.plot_sd      = 0;
ts_params.plot_individ = 0;
ts_params.shaded_areas = 0;

%% 3 — Time series: ES (grey) + T4T5 (orange) responding to 60deg 4Hz (cond 3)

ts_strains = {strain_es, strain_t4t5};
xmax = 1800;

% 60deg: dark grey ES + orange T4T5
ts_cols_60 = {col_es_60, col_t4t5_60};

for mi = 1:n_metrics
    dt = metrics{mi, 1};
    delta = metrics{mi, 2};
    m_title = metrics{mi, 4};

    [dt_resolved, delta_resolved] = resolve_delta_data_type(dt);
    if delta_resolved > 0, delta = delta_resolved; end

    figure('Name', sprintf('TS 60deg 4Hz: %s', m_title), 'Position', [233 511 641 460]);
    hold on;
    plot_strain_ts(DATA_31, ts_strains, ts_cols_60, sex, 3, dt_resolved, delta, xmax);
    ylabel(get_ylb_from_data_type(dt_resolved, delta), 'FontSize', 16);
    % title(sprintf('60deg 4Hz — %s', m_title), 'FontSize', 14);
end

%% 4 — Time series: ES (light grey) + T4T5 (yellow) responding to 15deg 16Hz (cond 8)

ts_cols_15 = {col_es_15, col_t4t5_15};

for mi = 1:n_metrics
    dt = metrics{mi, 1};
    delta = metrics{mi, 2};
    m_title = metrics{mi, 4};

    [dt_resolved, delta_resolved] = resolve_delta_data_type(dt);
    if delta_resolved > 0, delta = delta_resolved; end

    figure('Name', sprintf('TS 15deg 16Hz: %s', m_title), 'Position', [233 511 641 460]);
    hold on;
    plot_strain_ts(DATA_31, ts_strains, ts_cols_15, sex, 8, dt_resolved, delta, xmax);
    ylabel(get_ylb_from_data_type(dt_resolved, delta), 'FontSize', 16);
    % title(sprintf('15deg 16Hz — %s', m_title), 'FontSize', 14);
end

%% 5 — Violin plots: ES + T4T5, 60deg, 4 speeds

data_es   = DATA_31.(strain_es).(sex);
data_t4t5 = DATA_31.(strain_t4t5).(sex);

for mi = 1:n_metrics
    dt      = metrics{mi, 1};
    delta   = metrics{mi, 2};
    frm_rng = metrics{mi, 3};
    m_title = metrics{mi, 4};

    % 8 violins: ES@1Hz, T4T5@1Hz, ES@2Hz, T4T5@2Hz, ...
    n_violins = numel(cond_60) * 2;
    group_data   = cell(n_violins, 1);
    group_labels = cell(n_violins, 1);
    group_colors = zeros(n_violins, 3);

    for ci = 1:numel(cond_60)
        % ES
        vi_es = (ci - 1) * 2 + 1;
        cond_data = combine_timeseries_across_exp_check(data_es, cond_60(ci), dt);
        if delta == 1; cond_data = (cond_data - cond_data(:, 300)) * -1; end
        if dt == "av_data" || dt == "curv_data"
            cond_data(:, 750:1200) = cond_data(:, 750:1200) * -1;
        end
        group_data{vi_es} = nanmean(cond_data(:, frm_rng), 2); %#ok<NANMEAN>
        group_labels{vi_es} = sprintf('ES %s', labels_60{ci});
        group_colors(vi_es, :) = col_es_60;

        % T4T5
        vi_t4 = vi_es + 1;
        cond_data = combine_timeseries_across_exp_check(data_t4t5, cond_60(ci), dt);
        if delta == 1; cond_data = (cond_data - cond_data(:, 300)) * -1; end
        if dt == "av_data" || dt == "curv_data"
            cond_data(:, 750:1200) = cond_data(:, 750:1200) * -1;
        end
        group_data{vi_t4} = nanmean(cond_data(:, frm_rng), 2); %#ok<NANMEAN>
        group_labels{vi_t4} = sprintf('T4T5 %s', labels_60{ci});
        group_colors(vi_t4, :) = col_t4t5_60;
    end

    opts = struct();
    opts.colors       = group_colors;
    opts.ylabel_str   = get_ylb_from_data_type(dt, delta);
    opts.marker_size  = 15;
    opts.marker_alpha = 0.4;
    opts.violin_alpha = 0.35;
    opts.show_median  = true;
    opts.violin_width = 0.35;

    plot_violin(group_data, group_labels, opts);
    % title(sprintf('60deg — %s', m_title), 'FontSize', 14);
    yl = ylim; ylim([yl(1), yl(2) + diff(yl) * 0.15]);
    hold on; yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5); hold off;
    ax = gca; ax.FontSize = 16;
    f = gcf; f.Position = [50 100 375 400];
end

%% 6 — Violin plots: ES + T4T5, 15deg, 4 speeds

for mi = 1:n_metrics
    dt      = metrics{mi, 1};
    delta   = metrics{mi, 2};
    frm_rng = metrics{mi, 3};
    m_title = metrics{mi, 4};

    n_violins = numel(cond_15) * 2;
    group_data   = cell(n_violins, 1);
    group_labels = cell(n_violins, 1);
    group_colors = zeros(n_violins, 3);

    for ci = 1:numel(cond_15)
        vi_es = (ci - 1) * 2 + 1;
        cond_data = combine_timeseries_across_exp_check(data_es, cond_15(ci), dt);
        if delta == 1; cond_data = (cond_data - cond_data(:, 300)) * -1; end
        if dt == "av_data" || dt == "curv_data"
            cond_data(:, 750:1200) = cond_data(:, 750:1200) * -1;
        end
        group_data{vi_es} = nanmean(cond_data(:, frm_rng), 2); %#ok<NANMEAN>
        group_labels{vi_es} = sprintf('ES %s', labels_15{ci});
        group_colors(vi_es, :) = col_es_15;

        vi_t4 = vi_es + 1;
        cond_data = combine_timeseries_across_exp_check(data_t4t5, cond_15(ci), dt);
        if delta == 1; cond_data = (cond_data - cond_data(:, 300)) * -1; end
        if dt == "av_data" || dt == "curv_data"
            cond_data(:, 750:1200) = cond_data(:, 750:1200) * -1;
        end
        group_data{vi_t4} = nanmean(cond_data(:, frm_rng), 2); %#ok<NANMEAN>
        group_labels{vi_t4} = sprintf('T4T5 %s', labels_15{ci});
        group_colors(vi_t4, :) = col_t4t5_15;
    end

    opts = struct();
    opts.colors       = group_colors;
    opts.ylabel_str   = get_ylb_from_data_type(dt, delta);
    opts.marker_size  = 15;
    opts.marker_alpha = 0.4;
    opts.violin_alpha = 0.35;
    opts.show_median  = true;
    opts.violin_width = 0.35;

    plot_violin(group_data, group_labels, opts);
    % title(sprintf('15deg — %s', m_title), 'FontSize', 14);
    yl = ylim; ylim([yl(1), yl(2) + diff(yl) * 0.15]);
    hold on; yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5); hold off;
    ax = gca; ax.FontSize = 16;
    f = gcf; f.Position = [50 100 375 400];
end

%% 7 — Errorbar tuning curves: metric vs stimulus speed
%
% For each metric and spatial frequency, compute the mean metric value at
% each speed for both strains. Baseline from acclimation period.

strains_eb = {strain_es, strain_t4t5};
strain_labels = {'ES', 'T4T5'};
strain_cols_60_eb = {col_es_60, col_t4t5_60};
strain_cols_15_eb = {col_es_15, col_t4t5_15};

eb_metrics = { ...
    "fv_data",   0,  300:1200,  'Forward velocity (mm/s)'; ...
    "av_data",   0,  300:1200,  'Angular velocity (deg/s)'; ...
    "curv_data", 0,  300:1200,  'Turning rate (deg/mm)'; ...
    "dist_data", 1,  1170:1200, 'Centring at end (mm)'; ...
};
n_eb_metrics = size(eb_metrics, 1);

for eb_mi = 1:n_eb_metrics
    dt       = eb_metrics{eb_mi, 1};
    delta    = eb_metrics{eb_mi, 2};
    frm_rng  = eb_metrics{eb_mi, 3};
    eb_title = eb_metrics{eb_mi, 4};

    for sf = 1:2  % 1 = 60deg, 2 = 15deg
        if sf == 1
            conds = cond_60;  speeds = speeds_60;  sf_label = '60deg';
        else
            conds = cond_15;  speeds = speeds_15;  sf_label = '15deg';
        end

        figure('Position', [560 603 400 420], ...
            'Name', sprintf('Tuning %s: %s', sf_label, eb_title));
        hold on;

        if sf == 1
            strain_cols_eb = strain_cols_60_eb;
        else
            strain_cols_eb = strain_cols_15_eb;
        end

        for si = 1:numel(strains_eb)
            strain = strains_eb{si};
            col = strain_cols_eb{si};
            data_s = DATA_31.(strain).(sex);

            % --- Per-condition metric ---
            vals = NaN(1, numel(conds));
            sems_v = NaN(1, numel(conds));

            for ci = 1:numel(conds)
                cond_data = combine_timeseries_across_exp_check(data_s, conds(ci), dt);
                if delta == 1
                    cond_data = (cond_data - cond_data(:, 300)) * -1;
                end
                if dt == "av_data" || dt == "curv_data"
                    cond_data(:, 750:1200) = cond_data(:, 750:1200) * -1;
                end
                per_fly = nanmean(cond_data(:, frm_rng), 2); %#ok<NANMEAN>
                vals(ci)   = nanmean(per_fly); %#ok<NANMEAN>
                sems_v(ci) = nanstd(per_fly) / sqrt(numel(per_fly)); %#ok<NANSTD>
            end

            errorbar(speeds, vals, sems_v, '-o', 'Color', col, ...
                'LineWidth', 2, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', col, 'MarkerSize', 7, 'CapSize', 5);
        end

        yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
        xlabel('Stimulus speed (deg/s)', 'FontSize', 16);
        ylabel(eb_title, 'FontSize', 16);
        % title(sprintf('%s — %s vs speed', sf_label, eb_title), 'FontSize', 14);
        legend(strain_labels, 'Location', 'best', 'FontSize', 11);
        xticks(speeds);
        xticklabels({'60', '120', '240', '480'});
        set(gca, 'FontSize', 16, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
    end
end

%% ===== Local functions =====

function plot_strain_ts(DATA, strain_list, col_list, sex, cond_n, data_type, delta, xmax)
%PLOT_STRAIN_TS  Time series for multiple strains coloured by strain.
%   Plots mean +/- SEM for each strain on the current axes.

    % First pass: compute y-limits
    y_min = Inf;  y_max = -Inf;
    all_means = cell(numel(strain_list), 1);
    all_sems  = cell(numel(strain_list), 1);

    for si = 1:numel(strain_list)
        data_s = DATA.(strain_list{si}).(sex);
        cond_data = combine_timeseries_across_exp(data_s, cond_n, data_type);
        if delta
            cond_data = (cond_data - cond_data(:, 300)) * -1;
        end
        mean_data = squeeze(nanmean(reshape(cond_data, 2, [], size(cond_data, 2)), 1)); %#ok<NANMEAN>
        mean_all  = nanmean(mean_data); %#ok<NANMEAN>
        sem_all   = nanstd(mean_data) / sqrt(size(mean_data, 1)); %#ok<NANSTD>
        all_means{si} = mean_all;
        all_sems{si}  = sem_all;
        y_min = min(y_min, min(mean_all - sem_all, [], 'omitnan'));
        y_max = max(y_max, max(mean_all + sem_all, [], 'omitnan'));
    end

    y_pad = (y_max - y_min) * 0.10;
    rng_yl = [y_min - y_pad, y_max + y_pad];

    % Plot each strain
    for si = 1:numel(strain_list)
        col = col_list{si};
        mean_all = all_means{si};
        sem_all  = all_sems{si};
        nf = numel(mean_all);
        x = 1:nf;

        plot(x, mean_all + sem_all, 'w', 'LineWidth', 1);
        plot(x, mean_all - sem_all, 'w', 'LineWidth', 1);
        patch([x fliplr(x)], [mean_all + sem_all, fliplr(mean_all - sem_all)], ...
            col, 'FaceAlpha', 0.25, 'EdgeColor', 'none');
        plot(mean_all, 'Color', col, 'LineWidth', 2.5);
    end

    % Reference lines
    plot([300 300], rng_yl, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
    plot([750 750], rng_yl, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
    plot([1200 1200], rng_yl, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
    plot([0 xmax], [0 0], 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);

    xlabel('Time (s)', 'FontSize', 14);
    xticks([0, 300, 600, 900, 1200, 1500, 1800]);
    xticklabels({'-10', '0', '10', '20', '30', '40', '50'});
    ylim(rng_yl);
    xlim([0 xmax]);

    % Stimulus annotation rectangles
    yl = ylim;
    yrange = yl(2) - yl(1);
    rect_h = yrange / 20;
    ylim([yl(1) yl(2) + rect_h]);
    rect_y = yl(2);

    rectangle('Position', [0, rect_y, 300, rect_h], ...
        'FaceColor', [0.4 0.4 0.4], 'EdgeColor', 'k');
    bar_width = 15;
    x_positions = 300:bar_width:(1200 - bar_width);
    for i = 1:length(x_positions)
        if mod(i, 2) == 1, fc = 'w'; else, fc = 'k'; end
        rectangle('Position', [x_positions(i), rect_y, bar_width, rect_h], ...
            'FaceColor', fc, 'EdgeColor', 'k');
    end
    rectangle('Position', [1200, rect_y, xmax - 1200, rect_h], ...
        'FaceColor', [0.4 0.4 0.4], 'EdgeColor', 'k');

    box off;
    set(gca, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 16);
end
