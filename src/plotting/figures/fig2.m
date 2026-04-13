%% fig2 — Protocol 31: Speed tuning time series and violin plots
%
% Generates figures for ES control flies across 4 temporal frequencies at
% two spatial frequencies (60deg and 15deg gratings):
%   - 10 time series figures: 5 metrics x 2 spatial frequencies
%   - 10 violin plots: 5 metrics x 2 spatial frequencies (4 speeds each)
%
% Condition mapping (Protocol 31):
%   60deg: Cond 1=1Hz, 2=2Hz, 3=4Hz, 4=8Hz, (5=flicker)
%   15deg: Cond 6=4Hz, 7=8Hz, 8=16Hz, 9=32Hz, (10=flicker)
%
% REQUIREMENTS:
%   - Protocol 31 data via comb_data_across_cohorts_cond
%   - Functions: plot_xcond_per_strain_p31, plot_violin,
%     combine_timeseries_across_exp, get_ylb_from_data_type
%
% See also: fig_different_speeds, p31_speed_tuning_centring

%% 1 — Configuration & data loading

cfg = get_config();
protocol_dir = fullfile(cfg.results, 'protocol_31');

if ~exist('DATA_31', 'var') || isempty(fieldnames(DATA_31))
    fprintf('Loading Protocol 31 data from: %s\n', protocol_dir);
    DATA_31 = comb_data_across_cohorts_cond(protocol_dir);
end

control_strain = 'jfrc100_es_shibire_kir';
sex = 'F';

%% 2 — Condition and colour setup

% 60deg gratings: conditions 1-4 (1Hz, 2Hz, 4Hz, 8Hz)
cond_60 = [1, 2, 3, 4];
labels_60 = {'1 Hz', '2 Hz', '4 Hz', '8 Hz'};

% 15deg gratings: conditions 6-9 (4Hz, 8Hz, 16Hz, 32Hz)
cond_15 = [6, 7, 8, 9];
labels_15 = {'4 Hz', '8 Hz', '16 Hz', '32 Hz'};

% Speed colourmap (from cmap_config)
cmaps = cmap_config();
col_12 = cmaps.conditions_p31.colors;

% 5 metrics to plot
metrics = { ...
    "fv_data",         0,  300:1200,   'Forward velocity (stimulus)'; ...
    "av_data",         0,  300:1200,   'Angular velocity (stimulus)'; ...
    "curv_data",       0,  300:1200,   'Turning rate (stimulus)'; ...
    "dist_data",       1,  1170:1200,  'Centring at end of stimulus'; ...
};
n_metrics = size(metrics, 1);

% Time series params
ts_params.save_figs    = 0;
ts_params.plot_sem     = 1;
ts_params.plot_sd      = 0;
ts_params.plot_individ = 0;
ts_params.shaded_areas = 0;

%% 3 — Time series: 60deg gratings (5 metrics)

for mi = 1:n_metrics
    dt    = metrics{mi, 1};
    delta = metrics{mi, 2};
    m_title = metrics{mi, 4};

    if delta == 1
        dt_str = dt + "_delta";
    else
        dt_str = dt;
    end

    figure('Name', sprintf('TS 60deg: %s', m_title));
    plot_xcond_per_strain_p31('protocol_31', dt_str, cond_60, ...
        {control_strain}, ts_params, DATA_31);
    % title(sprintf('60deg gratings — %s', m_title), 'FontSize', 14);
end

%% 4 — Time series: 15deg gratings (5 metrics)

for mi = 1:n_metrics
    dt    = metrics{mi, 1};
    delta = metrics{mi, 2};
    m_title = metrics{mi, 4};

    if delta == 1
        dt_str = dt + "_delta";
    else
        dt_str = dt;
    end

    figure('Name', sprintf('TS 15deg: %s', m_title));
    plot_xcond_per_strain_p31('protocol_31', dt_str, cond_15, ...
        {control_strain}, ts_params, DATA_31);
    % title(sprintf('15deg gratings — %s', m_title), 'FontSize', 14);
end

%% 5 — Violin plots: 60deg gratings (5 metrics, 4 speeds each)

data_ctrl = DATA_31.(control_strain).(sex);

for mi = 1:n_metrics
    dt       = metrics{mi, 1};
    delta    = metrics{mi, 2};
    frm_rng  = metrics{mi, 3};
    m_title  = metrics{mi, 4};

    group_data   = cell(numel(cond_60), 1);
    for ci = 1:numel(cond_60)
        cond_data = combine_timeseries_across_exp(data_ctrl, cond_60(ci), dt);
        if delta == 1
            cond_data = (cond_data - cond_data(:, 300)) * -1;
        end
        if dt == "av_data" || dt == "curv_data"
            cond_data(:, 750:1200) = cond_data(:, 750:1200) * -1;
        end
        group_data{ci} = nanmean(cond_data(:, frm_rng), 2); %#ok<NANMEAN>
    end

    ylb = get_ylb_from_data_type(dt, delta);
    opts = struct();
    opts.colors       = col_12(cond_60, :);
    opts.ylabel_str   = ylb;
    opts.marker_size  = 15;
    opts.marker_alpha = 0.4;
    opts.violin_alpha = 0.35;
    opts.show_median  = true;
    opts.violin_width = 0.35;

    % figure('Name', sprintf('Violin 60deg: %s', m_title));
    plot_violin(group_data, labels_60, opts);
    % title(sprintf('60deg gratings — %s', m_title), 'FontSize', 14);
    yl = ylim; ylim([yl(1), yl(2) + diff(yl) * 0.15]);
    f = gcf; f.Position = [1260   84  255  456];
    ax = gca; ax.FontSize = 14;
    hold on; yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5); hold off;

end

%% 6 — Violin plots: 15deg gratings (5 metrics, 4 speeds each)

for mi = 1:n_metrics
    dt       = metrics{mi, 1};
    delta    = metrics{mi, 2};
    frm_rng  = metrics{mi, 3};
    m_title  = metrics{mi, 4};

    group_data   = cell(numel(cond_15), 1);
    for ci = 1:numel(cond_15)
        cond_data = combine_timeseries_across_exp(data_ctrl, cond_15(ci), dt);
        if delta == 1
            cond_data = (cond_data - cond_data(:, 300)) * -1;
        end
        if dt == "av_data" || dt == "curv_data"
            cond_data(:, 750:1200) = cond_data(:, 750:1200) * -1;
        end
        group_data{ci} = nanmean(cond_data(:, frm_rng), 2); %#ok<NANMEAN>
    end

    ylb = get_ylb_from_data_type(dt, delta);
    opts = struct();
    opts.colors       = col_12(cond_15, :);
    opts.ylabel_str   = ylb;
    opts.marker_size  = 15;
    opts.marker_alpha = 0.4;
    opts.violin_alpha = 0.35;
    opts.show_median  = true;
    opts.violin_width = 0.35;

    % figure('Name', sprintf('Violin 15deg: %s', m_title));
    plot_violin(group_data, labels_15, opts);
    % title(sprintf('15deg gratings — %s', m_title), 'FontSize', 14);
    yl = ylim; ylim([yl(1), yl(2) + diff(yl) * 0.15]);
    f = gcf; f.Position = [1260   84  255  456];
    ax = gca; ax.FontSize = 14;
    hold on; yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5); hold off;

end

%% 7 — Errorbar tuning curves: metric vs stimulus speed (ES control)
%
% For each metric, 60deg (blue) and 15deg (pink) on the same axes.

speeds = [60, 120, 240, 480];

for mi = 1:n_metrics
    dt       = metrics{mi, 1};
    delta    = metrics{mi, 2};
    frm_rng  = metrics{mi, 3};
    m_title  = metrics{mi, 4};

    figure('Position', [560 603 400 420], 'Name', sprintf('Tuning: %s', m_title));
    hold on;

    for sf = 1:2
        if sf == 1
            conds = cond_60;  sf_label = '60deg';
            eb_colors = col_12(cond_60, :);
        else
            conds = cond_15;  sf_label = '15deg';
            eb_colors = col_12(cond_15, :);
        end

        vals = NaN(1, numel(conds));
        sems_v = NaN(1, numel(conds));

        for ci = 1:numel(conds)
            cond_data = combine_timeseries_across_exp(data_ctrl, conds(ci), dt);
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

        % Coloured markers with errorbars
        for ci = 1:numel(conds)
            errorbar(speeds(ci), vals(ci), sems_v(ci), 'o', 'Color', eb_colors(ci, :), ...
                'LineWidth', 2, 'MarkerFaceColor', 'w', 'MarkerEdgeColor', eb_colors(ci, :), ...
                'MarkerSize', 7, 'CapSize', 5);
        end

        % Connecting line in darkest colour
        plot(speeds, vals, '-', 'Color', eb_colors(end, :), 'LineWidth', 1.5);
    end

    yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
    xlabel('Stimulus speed (deg/s)', 'FontSize', 14);
    ylabel(m_title, 'FontSize', 14);
    legend({'', '', '', '', '60deg', '', '', '', '', '15deg'}, ...
        'Location', 'best', 'FontSize', 11);
    xticks(speeds);
    xticklabels({'60', '120', '240', '480'});
    set(gca, 'FontSize', 14, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
end

%% 8 — Scatter plot: ES control, centring vs turning, all 8 speed conditions
%
% Each marker = one condition (4 x 60deg in blue, 4 x 15deg in pink).

all_conds   = [cond_60, cond_15];
all_labels  = [labels_60, labels_15];
all_colors  = [col_12(cond_60, :); col_12(cond_15, :)];
sf_prefix   = [repmat({'60deg'}, 1, 4), repmat({'15deg'}, 1, 4)];
n_scatter   = numel(all_conds);

turning_sc  = NaN(n_scatter, 1);
centring_sc = NaN(n_scatter, 1);

for ci = 1:n_scatter
    cond_data_av = combine_timeseries_across_exp(data_ctrl, all_conds(ci), "av_data");
    cond_data_av(:, 750:1200) = cond_data_av(:, 750:1200) * -1;
    turning_sc(ci) = nanmean(nanmean(cond_data_av(:, 300:1200), 2)); %#ok<NANMEAN>

    cond_data_dist = combine_timeseries_across_exp(data_ctrl, all_conds(ci), "dist_data");
    dist_delta = (cond_data_dist - cond_data_dist(:, 300)) * -1;
    centring_sc(ci) = nanmean(nanmean(dist_delta(:, 1170:1200), 2)); %#ok<NANMEAN>
end

figure('Position', [50 50 500 450], 'Name', 'Scatter ES: speed conditions');
hold on;

xline(0, ':', 'Color', [0 0 0], 'LineWidth', 0.5);
yline(0, ':', 'Color', [0 0 0], 'LineWidth', 0.5);

% Plot markers
for ci = 1:n_scatter
    scatter(turning_sc(ci), centring_sc(ci), 100, all_colors(ci, :), 'filled', ...
        'MarkerEdgeColor', [0.3 0.3 0.3], 'LineWidth', 0.5);
end

% Connect 60deg and 15deg points separately with lines
% plot(turning_sc(1:4), centring_sc(1:4), '-', 'Color', col_12(4, :), 'LineWidth', 1);
% plot(turning_sc(5:8), centring_sc(5:8), '-', 'Color', col_12(9, :), 'LineWidth', 1);

% Labels with anti-overlap
scatter_labels = cell(n_scatter, 1);
for ci = 1:n_scatter
    scatter_labels{ci} = sprintf('%s %s', sf_prefix{ci}, all_labels{ci});
end

x_range_sc = max(turning_sc) - min(turning_sc);
y_range_sc = max(centring_sc) - min(centring_sc);
if x_range_sc == 0; x_range_sc = 1; end
if y_range_sc == 0; y_range_sc = 1; end
x_off_sc = x_range_sc * 0.05;
y_off_sc = y_range_sc * 0.05;

txt_x_sc = turning_sc + x_off_sc;
txt_y_sc = centring_sc + y_off_sc;

min_dy_sc = y_range_sc * 0.055;
min_dx_sc = x_range_sc * 0.10;
for pass = 1:10
    [~, sort_idx] = sort(txt_y_sc);
    for i = 2:n_scatter
        a = sort_idx(i-1);
        b = sort_idx(i);
        if abs(txt_x_sc(a) - txt_x_sc(b)) < min_dx_sc && ...
                abs(txt_y_sc(a) - txt_y_sc(b)) < min_dy_sc
            mid = (txt_y_sc(a) + txt_y_sc(b)) / 2;
            txt_y_sc(a) = mid - min_dy_sc / 2;
            txt_y_sc(b) = mid + min_dy_sc / 2;
        end
    end
end

for ci = 1:n_scatter
    plot([turning_sc(ci), txt_x_sc(ci)], [centring_sc(ci), txt_y_sc(ci)], ...
        '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.5);
    text(txt_x_sc(ci), txt_y_sc(ci), scatter_labels{ci}, 'FontSize', 8, ...
        'VerticalAlignment', 'middle');
end

xlabel('Mean angular velocity during stimulus (deg/s)', 'FontSize', 14);
ylabel('Centring (relative distance at end)', 'FontSize', 14);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
f = gcf; f.Position = [50    50   314   259];