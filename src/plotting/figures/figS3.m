%% figS3 — Group vs solo fly comparison (bootstrapped)
%
% Compares behavioral responses of ES control flies tested in groups (~15
% per arena) versus tested individually (solo). Uses bootstrapping on the
% grouped data to match the solo sample size for fair comparison.
%
% Generates:
%   - 4 time series figures: mean +/- 95% CI for group (bootstrapped) and solo
%   - 4 violin plots: per-fly metric distributions for group and solo
%
% DATA source: DATA_ES_Shibire_Kir_group_vs_solo.mat
%   Strains: 'jfrc100_es_shibire_kir' (group), 'jfrc100_es_shibire_kir_solo' (solo)
%
% REQUIREMENTS:
%   - Functions: combine_timeseries_data_per_cond, resolve_delta_data_type,
%     get_ylb_from_data_type, plot_violin
%
% See also: p25_single_lady_analysis, figS2

%% 1 — Configuration & data loading

cfg = get_config();

if ~exist('DATA_GS', 'var')
    fprintf('Loading group vs solo data...\n');
    tmp = load(fullfile(cfg.results, 'DATA_ES_Shibire_Kir_group_vs_solo.mat'), 'DATA');
    DATA_GS = tmp.DATA;
    clear tmp;
end

sex = 'F';
cond_idx = 1;  % condition 1: 60deg gratings 4Hz

strain_grp  = 'jfrc100_es_shibire_kir';
strain_solo = 'jfrc100_es_shibire_kir_solo';

% Colours
col_grp  = [0.4 0.4 0.4];     % dark grey for grouped
col_solo = [0.46 0.15 0.30];  % burgundy for solo

% Bootstrap parameters
N_BOOT = 1000;
CI_PRCT = [2.5 97.5];

% Trim all data to this many frames (consistent length)
MAX_FRAMES = 1807;

%% 2 — Metrics

metrics = { ...
    "fv_data",    0,  300:1200,   'Forward velocity (stimulus)'; ...
    "av_data",    0,  300:1200,   'Angular velocity (stimulus)'; ...
    "curv_data",  0,  300:1200,   'Turning rate (stimulus)'; ...
    "dist_data",  1,  1170:1200,  'Centring at end of stimulus'; ...
};
n_metrics = size(metrics, 1);

xmax = MAX_FRAMES;

%% 3 — Time series plots (bootstrapped group vs solo)

for mi = 1:n_metrics
    dt    = metrics{mi, 1};
    delta = metrics{mi, 2};
    m_title = metrics{mi, 4};

    [dt_resolved, delta_resolved] = resolve_delta_data_type(dt);
    if delta_resolved > 0, delta = delta_resolved; end

    % Extract data
    cond_data_grp  = combine_timeseries_data_per_cond(DATA_GS, strain_grp, sex, dt_resolved, cond_idx);
    cond_data_solo = combine_timeseries_data_per_cond(DATA_GS, strain_solo, sex, dt_resolved, cond_idx);

    % Trim to consistent length
    cond_data_grp  = cond_data_grp(:, 1:min(MAX_FRAMES, size(cond_data_grp, 2)));
    cond_data_solo = cond_data_solo(:, 1:min(MAX_FRAMES, size(cond_data_solo, 2)));

    % Baseline correction
    if delta
        cond_data_grp  = cond_data_grp  - cond_data_grp(:, 300);
        cond_data_solo = cond_data_solo - cond_data_solo(:, 300);
        % Flip sign so positive = moved towards centre
        cond_data_grp  = cond_data_grp * -1;
        cond_data_solo = cond_data_solo * -1;
    end

    n_solo = size(cond_data_solo, 1);
    n_grp  = size(cond_data_grp, 1);
    T      = size(cond_data_solo, 2);

    fprintf('%s: %d group flies, %d solo flies\n', m_title, n_grp, n_solo);

    % --- Bootstrap the grouped data ---
    boot_means = zeros(N_BOOT, T);
    for b = 1:N_BOOT
        idx = randperm(n_grp, n_solo);
        boot_means(b, :) = nanmean(cond_data_grp(idx, :), 1); %#ok<NANMEAN>
    end

    group_mean = nanmean(boot_means, 1); %#ok<NANMEAN>
    group_ci   = prctile(boot_means, CI_PRCT, 1);  % [2 x T]

    % Solo: mean +/- 95% CI via SEM
    solo_mean = nanmean(cond_data_solo, 1); %#ok<NANMEAN>
    solo_sem  = nanstd(cond_data_solo, 0, 1) / sqrt(n_solo); %#ok<NANSTD>
    solo_ci   = [solo_mean - 1.96 * solo_sem; solo_mean + 1.96 * solo_sem];

    % --- Plot ---
    t = 1:T;

    figure('Name', sprintf('TS Group vs Solo: %s', m_title), 'Position', [284 752 475 260]);
    hold on;

    % Group (bootstrapped): grey shading + dark grey line
    fill([t, fliplr(t)], [group_ci(1,:), fliplr(group_ci(2,:))], ...
        col_grp, 'EdgeColor', 'none', 'FaceAlpha', 0.25);
    plot(t, group_mean, 'Color', col_grp, 'LineWidth', 2);

    % Solo: burgundy shading + burgundy line
    fill([t, fliplr(t)], [solo_ci(1,:), fliplr(solo_ci(2,:))], ...
        col_solo, 'EdgeColor', 'none', 'FaceAlpha', 0.2);
    plot(t, solo_mean, 'Color', col_solo, 'LineWidth', 2);

    ylb = get_ylb_from_data_type(dt_resolved, delta);
    ylabel(ylb, 'FontSize', 14);
    xlabel('Time (s)', 'FontSize', 14);
    xticks([0, 300, 600, 900, 1200, 1500, 1800]);
    xticklabels({'-10', '0', '10', '20', '30', '40', '50'});
    xlim([0 xmax]);
    set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

    % Stimulus annotation rectangles at top
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

    % Reference lines (drawn last so they span the final y-limits)
    yl_final = ylim;
    plot([300 300], yl_final, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
    plot([750 750], yl_final, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
    plot([1200 1200], yl_final, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
    plot([0 xmax], [0 0], 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
end

%% 4 — Violin plots (group vs solo, per metric)

for mi = 1:n_metrics
    dt      = metrics{mi, 1};
    delta   = metrics{mi, 2};
    frm_rng = metrics{mi, 3};
    m_title = metrics{mi, 4};

    [dt_resolved, delta_resolved] = resolve_delta_data_type(dt);
    if delta_resolved > 0, delta = delta_resolved; end

    % Extract data
    cond_data_grp  = combine_timeseries_data_per_cond(DATA_GS, strain_grp, sex, dt_resolved, cond_idx);
    cond_data_solo = combine_timeseries_data_per_cond(DATA_GS, strain_solo, sex, dt_resolved, cond_idx);
    cond_data_grp  = cond_data_grp(:, 1:min(MAX_FRAMES, size(cond_data_grp, 2)));
    cond_data_solo = cond_data_solo(:, 1:min(MAX_FRAMES, size(cond_data_solo, 2)));

    if delta
        cond_data_grp  = cond_data_grp  - cond_data_grp(:, 300);
        cond_data_solo = cond_data_solo - cond_data_solo(:, 300);
        % Flip sign so positive = moved towards centre
        cond_data_grp  = cond_data_grp * -1;
        cond_data_solo = cond_data_solo * -1;
    end

    if dt_resolved == "av_data" || dt_resolved == "curv_data"
        cond_data_grp(:, 750:1200)  = cond_data_grp(:, 750:1200) * -1;
        cond_data_solo(:, 750:1200) = cond_data_solo(:, 750:1200) * -1;
    end

    % Per-fly means over the metric window
    grp_vals  = nanmean(cond_data_grp(:, frm_rng), 2); %#ok<NANMEAN>
    solo_vals = nanmean(cond_data_solo(:, frm_rng), 2); %#ok<NANMEAN>

    n_grp_flies  = numel(grp_vals);
    n_solo_flies = numel(solo_vals);

    % --- Bootstrap the group violin data ---
    % Resample to match solo N, take per-fly means from each bootstrap sample
    boot_fly_means = NaN(N_BOOT * n_solo_flies, 1);
    for b = 1:N_BOOT
        idx = randperm(n_grp_flies, n_solo_flies);
        boot_fly_means((b-1)*n_solo_flies + (1:n_solo_flies)) = grp_vals(idx);
    end

    group_data = {boot_fly_means, solo_vals};
    group_labels = { ...
        sprintf('Group (n=%d, boot)', n_grp_flies), ...
        sprintf('Solo (n=%d)', n_solo_flies)};

    ylb = get_ylb_from_data_type(dt_resolved, delta);
    opts = struct();
    opts.colors       = [col_grp; col_solo];
    opts.ylabel_str   = ylb;
    opts.marker_size  = 10;
    opts.marker_alpha = 0.15;
    opts.violin_alpha = 0.35;
    opts.show_median  = true;
    opts.violin_width = 0.35;

    plot_violin(group_data, group_labels, opts);
    % title(m_title, 'FontSize', 14);
    yl = ylim; ylim([yl(1), yl(2) + diff(yl) * 0.15]);
    hold on; yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5); hold off;
    ax = gca; ax.FontSize = 14;
    f = gcf; f.Position = [50 100 220 400];
end
