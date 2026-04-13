%% fig2_combined_speeds — 60deg gratings: static to 8Hz (P27 + P31 combined)
%
% Combines P27 condition 10 (static gratings) with P31 conditions 1-5
% (1Hz, 2Hz, 4Hz, 8Hz, flicker) to show the full 60-degree speed range.
%
% Violin order: Static, Flicker, 1Hz, 2Hz, 4Hz, 8Hz
%   Static  = P27 condition 10 (white fill, light grey outline)
%   Flicker = P31 condition 5  (light grey fill, dark grey outline)
%   1-8Hz   = P31 conditions 1-4 (blue speed gradient)
%
% Generates:
%   - 4 time series figures (one per metric, 6 conditions overlaid)
%   - 4 violin plots (one per metric, 6 violins)
%
% REQUIREMENTS:
%   - Protocol 27 and 31 data via comb_data_across_cohorts_cond
%   - Functions: plot_violin, combine_timeseries_across_exp,
%     combine_timeseries_across_exp, get_ylb_from_data_type
%
% See also: fig2, fig_different_speeds

%% 1 — Configuration & data loading

cfg = get_config();

% Protocol 27
protocol_dir_27 = fullfile(cfg.results, 'protocol_27');
if ~exist('DATA_27', 'var') || isempty(fieldnames(DATA_27))
    fprintf('Loading Protocol 27 data from: %s\n', protocol_dir_27);
    DATA_27 = comb_data_across_cohorts_cond(protocol_dir_27);
end

% Protocol 31
protocol_dir_31 = fullfile(cfg.results, 'protocol_31');
if ~exist('DATA_31', 'var') || isempty(fieldnames(DATA_31))
    fprintf('Loading Protocol 31 data from: %s\n', protocol_dir_31);
    DATA_31 = comb_data_across_cohorts_cond(protocol_dir_31);
end

control_strain = 'jfrc100_es_shibire_kir';
sex = 'F';

%% 2 — Condition mapping and colours (from cmap_config)

cmaps = cmap_config();
cs_cols = cmaps.combined_speeds.colors;

% 6 conditions in display order: Static, Flicker, 1Hz, 2Hz, 4Hz, 8Hz
% Each entry: {DATA source, condition number, label, colour, edge colour}
cond_spec = { ...
    DATA_27,  10,  'Static',   cs_cols(1,:),  [0.6 0.6 0.6];  ...
    DATA_31,   5,  'Flicker',  cs_cols(2,:),  [0.3 0.3 0.3];  ...
    DATA_31,   1,  '1 Hz',     cs_cols(3,:),  'none';  ...
    DATA_31,   2,  '2 Hz',     cs_cols(4,:),  'none';  ...
    DATA_31,   3,  '4 Hz',     cs_cols(5,:),  'none';  ...
    DATA_31,   4,  '8 Hz',     cs_cols(6,:),  'none';  ...
};

n_conds = size(cond_spec, 1);
cond_labels = cond_spec(:, 3);
cond_colors = cell2mat(cond_spec(:, 4));

% Metrics
metrics = { ...
    "fv_data",    0,  300:1200,   'Forward velocity (stimulus)'; ...
    "curv_data",  0,  300:1200,   'Turning rate (stimulus)'; ...
    "av_data",    0,  300:1200,   'Angular velocity (stimulus)'; ...
    "dist_data",  1,  1170:1200,  'Centring at end of stimulus'; ...
};
n_metrics = size(metrics, 1);

%% 3 — Time series plots (one figure per metric, 6 conditions overlaid)

xmax = 1800;

for mi = 1:n_metrics
    dt      = metrics{mi, 1};
    delta   = metrics{mi, 2};
    m_title = metrics{mi, 4};

    [dt_resolved, delta_resolved] = resolve_delta_data_type(dt);
    if delta_resolved > 0, delta = delta_resolved; end

    figure('Name', sprintf('TS Combined: %s', m_title), 'Position', [233 511 641 460]);
    hold on;

    % Compute data-driven y-limits first
    y_min =  Inf;
    y_max = -Inf;

    all_means = cell(n_conds, 1);
    all_sems  = cell(n_conds, 1);

    for ci = 1:n_conds
        DATA_src = cond_spec{ci, 1};
        cond_n   = cond_spec{ci, 2};

        data_ctrl = DATA_src.(control_strain).(sex);
        cond_data = combine_timeseries_across_exp(data_ctrl, cond_n, dt_resolved);
        if delta
            cond_data = (cond_data - cond_data(:, 300)) * -1;
        end

        mean_data = cond_data;
        mean_all  = nanmean(mean_data); %#ok<NANMEAN>
        sem_all   = nanstd(mean_data) / sqrt(size(mean_data, 1)); %#ok<NANSTD>

        all_means{ci} = mean_all;
        all_sems{ci}  = sem_all;

        y_min = min(y_min, min(mean_all - sem_all, [], 'omitnan'));
        y_max = max(y_max, max(mean_all + sem_all, [], 'omitnan'));
    end

    y_pad = (y_max - y_min) * 0.10;
    rng_yl = [y_min - y_pad, y_max + y_pad];

    % Plot each condition
    for ci = 1:n_conds
        col = cond_colors(ci, :);
        mean_all = all_means{ci};
        sem_all  = all_sems{ci};
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

    ylb = get_ylb_from_data_type(dt_resolved, delta);
    ylabel(ylb);
    xlabel('Time (s)');
    xticks([0, 300, 600, 900, 1200, 1500, 1800]);
    xticklabels({'-10', '0', '10', '20', '30', '40', '50'});
    ylim(rng_yl);
    xlim([0 xmax]);

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

    box off;
    set(gca, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 14);
end

%% 4 — Violin plots (one figure per metric, 6 violins)

for mi = 1:n_metrics
    dt      = metrics{mi, 1};
    delta   = metrics{mi, 2};
    frm_rng = metrics{mi, 3};
    m_title = metrics{mi, 4};

    group_data = cell(n_conds, 1);

    for ci = 1:n_conds
        DATA_src = cond_spec{ci, 1};
        cond_n   = cond_spec{ci, 2};

        data_ctrl = DATA_src.(control_strain).(sex);
        cond_data = combine_timeseries_across_exp(data_ctrl, cond_n, dt);
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
    opts.colors       = cond_colors;
    opts.ylabel_str   = ylb;
    opts.marker_size  = 15;
    opts.marker_alpha = 0.4;
    opts.violin_alpha = 0.35;
    opts.show_median  = true;
    opts.violin_width = 0.35;

    plot_violin(group_data, cond_labels, opts);
    yl = ylim; ylim([yl(1), yl(2) + diff(yl) * 0.15]);
    f = gcf; f.Position = [1260 84 300 456];
    ax = gca; ax.FontSize = 14;

    % Add y=0 line for velocity/turning metrics
    if dt == "fv_data" || dt == "av_data" || dt == "curv_data"
        hold on; yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5); hold off;
    end

    % Override edge colours for static and flicker violins
    % Find the violin fill patches and set their EdgeColor
    ax_children = ax.Children;
    for ch_idx = 1:numel(ax_children)
        if isa(ax_children(ch_idx), 'matlab.graphics.primitive.Patch')
            xd = ax_children(ch_idx).XData;
            if ~isempty(xd)
                x_center = mean(xd, 'omitnan');
                if abs(x_center - 1) < 0.6  % static (position 1)
                    ax_children(ch_idx).EdgeColor = [0.7 0.7 0.7];
                elseif abs(x_center - 2) < 0.6  % flicker (position 2)
                    ax_children(ch_idx).EdgeColor = [0.4 0.4 0.4];
                end
            end
        end
    end
end

%% 5 — Spatial frequency comparison: 60deg vs 15deg at matched speeds

% 4 conditions: 60deg 4Hz, 15deg 4Hz, 60deg 8Hz, 15deg 8Hz
% All from P31: cond 3 (60deg 4Hz), 6 (15deg 4Hz), 4 (60deg 8Hz), 7 (15deg 8Hz)
sf_spec = { ...
    DATA_31,  3,  '60deg 4Hz',  [ 31 120 180]./255;  ...   % medium blue
    DATA_31,  6,  '15deg 4Hz',  [231 158 190]./255;  ...   % light pink
    DATA_31,  4,  '60deg 8Hz',  [ 61  82 159]./255;  ...   % dark blue
    DATA_31,  7,  '15deg 8Hz',  [223 113 167]./255;  ...   % dark pink
};

n_sf_conds = size(sf_spec, 1);
sf_labels  = sf_spec(:, 3);
sf_colors  = cell2mat(sf_spec(:, 4));

%% 6 — Time series: spatial frequency comparison

for mi = 1:n_metrics
    dt      = metrics{mi, 1};
    delta   = metrics{mi, 2};
    m_title = metrics{mi, 4};

    [dt_resolved, delta_resolved] = resolve_delta_data_type(dt);
    if delta_resolved > 0, delta = delta_resolved; end

    figure('Name', sprintf('TS SF compare: %s', m_title), 'Position', [233 511 641 460]);
    hold on;

    % Compute data-driven y-limits
    y_min =  Inf;
    y_max = -Inf;
    all_means_sf = cell(n_sf_conds, 1);
    all_sems_sf  = cell(n_sf_conds, 1);

    for ci = 1:n_sf_conds
        DATA_src = sf_spec{ci, 1};
        cond_n   = sf_spec{ci, 2};

        data_ctrl = DATA_src.(control_strain).(sex);
        cond_data = combine_timeseries_across_exp(data_ctrl, cond_n, dt_resolved);
        if delta
            cond_data = (cond_data - cond_data(:, 300)) * -1;
        end

        mean_data = cond_data;
        mean_all  = nanmean(mean_data); %#ok<NANMEAN>
        sem_all   = nanstd(mean_data) / sqrt(size(mean_data, 1)); %#ok<NANSTD>

        all_means_sf{ci} = mean_all;
        all_sems_sf{ci}  = sem_all;

        y_min = min(y_min, min(mean_all - sem_all, [], 'omitnan'));
        y_max = max(y_max, max(mean_all + sem_all, [], 'omitnan'));
    end

    y_pad = (y_max - y_min) * 0.10;
    rng_yl = [y_min - y_pad, y_max + y_pad];

    for ci = 1:n_sf_conds
        col = sf_colors(ci, :);
        mean_all = all_means_sf{ci};
        sem_all  = all_sems_sf{ci};
        nf = numel(mean_all);
        x = 1:nf;

        plot(x, mean_all + sem_all, 'w', 'LineWidth', 1);
        plot(x, mean_all - sem_all, 'w', 'LineWidth', 1);
        patch([x fliplr(x)], [mean_all + sem_all, fliplr(mean_all - sem_all)], ...
            col, 'FaceAlpha', 0.25, 'EdgeColor', 'none');
        plot(mean_all, 'Color', col, 'LineWidth', 2.5);
    end

    plot([300 300], rng_yl, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
    plot([750 750], rng_yl, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
    plot([1200 1200], rng_yl, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
    plot([0 xmax], [0 0], 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);

    ylb = get_ylb_from_data_type(dt_resolved, delta);
    ylabel(ylb);
    xlabel('Time (s)');
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
    set(gca, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 14);
end

%% 7 — Violin plots: spatial frequency comparison

for mi = 1:n_metrics
    dt      = metrics{mi, 1};
    delta   = metrics{mi, 2};
    frm_rng = metrics{mi, 3};
    m_title = metrics{mi, 4};

    group_data_sf = cell(n_sf_conds, 1);

    for ci = 1:n_sf_conds
        DATA_src = sf_spec{ci, 1};
        cond_n   = sf_spec{ci, 2};

        data_ctrl = DATA_src.(control_strain).(sex);
        cond_data = combine_timeseries_across_exp(data_ctrl, cond_n, dt);
        if delta == 1
            cond_data = (cond_data - cond_data(:, 300)) * -1;
        end
        if dt == "av_data" || dt == "curv_data"
            cond_data(:, 750:1200) = cond_data(:, 750:1200) * -1;
        end
        group_data_sf{ci} = nanmean(cond_data(:, frm_rng), 2); %#ok<NANMEAN>
    end

    ylb = get_ylb_from_data_type(dt, delta);
    opts_sf = struct();
    opts_sf.colors       = sf_colors;
    opts_sf.ylabel_str   = ylb;
    opts_sf.marker_size  = 15;
    opts_sf.marker_alpha = 0.4;
    opts_sf.violin_alpha = 0.35;
    opts_sf.show_median  = true;
    opts_sf.violin_width = 0.35;

    plot_violin(group_data_sf, sf_labels, opts_sf);
    yl = ylim; ylim([yl(1), yl(2) + diff(yl) * 0.15]);
    f = gcf; f.Position = [1260 84 300 456];
    ax = gca; ax.FontSize = 14;

    if dt == "fv_data" || dt == "av_data" || dt == "curv_data"
        hold on; yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5); hold off;
    end
end
