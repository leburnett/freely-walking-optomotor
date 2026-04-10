%% fig4 — Screen summary: heatmap, violins, time series, scatter
%
% Generates figures for the main screen results (condition 1):
%   1. P-value heatmap (strains x 6 metrics) + colour bar
%   2. Six violin plots (one per heatmap metric column)
%   3. Six ES control time series (2x3 grid) with shaded metric windows
%   4. Centring vs turning scatter (one marker per strain)
%
% REQUIREMENTS:
%   - Protocol 27 data via comb_data_across_cohorts_cond
%   - strain_names2.mat in results folder
%   - Functions: make_summary_heat_maps_p27, plot_colour_bar_for_summary_plot,
%     plot_violin_metrics_xstrains, plot_violin, plot_xcond_per_strain2,
%     combine_timeseries_across_exp_check, combine_timeseries_across_exp
%
% See also: cross_strain_condition_heatmaps, figS1

%% 1 — Configuration & data loading

cfg = get_config();
protocol_dir = fullfile(cfg.results, 'protocol_27');

if ~exist('DATA', 'var') || isempty(fieldnames(DATA))
    fprintf('Loading Protocol 27 data from: %s\n', protocol_dir);
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

save_figs = false;
save_folder = fullfile(cfg.figures, 'FIGS');

%% 2 — Strain ordering & colours

control_strain = 'jfrc100_es_shibire_kir';
sex = 'F';
cond_idx = 1;  % condition 1: 60deg gratings 4Hz

% strain_ids: 1:16 = experimental, 17 = ES control (matches strain_names2.mat)
strain_ids = 1:17;

% Strain colours (from cmap_config)
cmaps = cmap_config();
strain_colours = cmaps.strains.colors;

% Load strain names for labelling
strain_names_s = load(fullfile(cfg.results, 'strain_names2.mat'));
strain_names_list = strain_names_s.strain_names;
strain_names_list{end+1} = 'jfrc100_es_shibire_kir';
strain_names_list{end+1} = 'csw1118';

%% 3 — Heatmap + colour bar

make_summary_heat_maps_p27(DATA);
plot_colour_bar_for_summary_plot();
f = gcf; f.Position = [118   469   257   466];

%% 4 — Violin plots (6 figures, one per heatmap metric column)

% --- Hard-coded y-limits for each violin plot ---
% Edit these values to ensure median text labels are visible.
% Format: [ymin, ymax] or [] to use auto-limits.
violin_ylims = { ...
    [-10 38];      % Metric 1: Avg FV during stimulus
    [-35 35];    % Metric 2: FV change at onset
    [-75 310];   % Metric 3: Avg turning during stimulus
    [-300 750];   % Metric 4: Early turning (first 5s CW)
    [-150 160];   % Metric 5: Centring at end of stimulus
    [-110 170];   % Metric 6: Centring after 10s
};

% Metric 1: Avg FV during stimulus (frames 300:1200)
plot_violin_metrics_xstrains(DATA, strain_ids, cond_idx, "fv_data", 300:1200, 0);
title('Metric 1: Avg FV during stimulus', 'FontSize', 14);
hold on; yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5); hold off;
if ~isempty(violin_ylims{1}); ylim(violin_ylims{1}); end
f = gcf; f.Position = [376   335   765   257];

% Metric 2: FV change at stimulus onset (mean 300:390 minus mean 210:300)
% This requires custom computation — cannot use plot_violin_metrics_xstrains
rng_before = 210:300;
rng_after  = 300:390;
group_data_m2   = cell(numel(strain_ids), 1);
group_labels_m2 = cell(numel(strain_ids), 1);

for k = 1:numel(strain_ids)
    strain = strain_names_list{strain_ids(k)};
    data = DATA.(strain).(sex);
    cond_data = combine_timeseries_across_exp_check(data, cond_idx, "fv_data");
    fv_before = nanmean(cond_data(:, rng_before), 2); %#ok<NANMEAN>
    fv_after  = nanmean(cond_data(:, rng_after), 2); %#ok<NANMEAN>
    group_data_m2{k} = fv_after - fv_before;
    group_labels_m2{k} = strrep(strain, '_', '-');
end

opts_m2 = struct();
opts_m2.colors       = strain_colours(strain_ids, :);
opts_m2.ylabel_str   = '\DeltaFV (mm/s)';
opts_m2.marker_size  = 15;
opts_m2.marker_alpha = 0.4;
opts_m2.violin_alpha = 0.35;
opts_m2.show_median  = true;
opts_m2.violin_width = 0.35;
plot_violin(group_data_m2, group_labels_m2, opts_m2);
set(gca, 'XTickLabel', {});
title('Metric 2: FV change at onset (\pm3s)', 'FontSize', 14);
hold on; yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5); hold off;
if ~isempty(violin_ylims{2}); ylim(violin_ylims{2}); end
f = gcf; f.Position = [376   335   765   257];

% Metric 3: Avg turning rate during stimulus (frames 300:1200)
plot_violin_metrics_xstrains(DATA, strain_ids, cond_idx, "curv_data", 300:1200, 0);
title('Metric 3: Avg turning during stimulus', 'FontSize', 14);
hold on; yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5); hold off;
if ~isempty(violin_ylims{3}); ylim(violin_ylims{3}); end
f = gcf; f.Position = [376   335   765   257];

% Metric 4: Early turning — first 5s CW (frames 315:450)
plot_violin_metrics_xstrains(DATA, strain_ids, cond_idx, "curv_data", 315:450, 0);
title('Metric 4: Early turning (first 5s CW)', 'FontSize', 14);
hold on; yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5); hold off;
if ~isempty(violin_ylims{4}); ylim(violin_ylims{4}); end
f = gcf; f.Position = [376   335   765   257];

% Metric 5: Relative distance at end of stimulus (frames 1170:1200, delta=1)
plot_violin_metrics_xstrains(DATA, strain_ids, cond_idx, "dist_data", 1170:1200, 1);
hold on; yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5); hold off;
title('Metric 5: Centring at end of stimulus', 'FontSize', 14);
if ~isempty(violin_ylims{5}); ylim(violin_ylims{5}); end
f = gcf; f.Position = [376   335   765   257];

% Metric 6: Relative distance after 10s (frames 570:600, delta=1)
plot_violin_metrics_xstrains(DATA, strain_ids, cond_idx, "dist_data", 570:600, 1);
hold on; yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5); hold off;
title('Metric 6: Centring after 10s', 'FontSize', 14);
if ~isempty(violin_ylims{6}); ylim(violin_ylims{6}); end
f = gcf; f.Position = [376   335   765   257];

%% 5 — Time series plots (2x3 grid, ES control only with SEM)

ts_params.save_figs    = 0;
ts_params.plot_sem     = 1;
ts_params.plot_sd      = 0;
ts_params.plot_individ = 0;
ts_params.shaded_areas = 0;  % We draw custom shading per subplot

fig_ts = figure('Position', [50 50 1600 900]);

% Define the 6 metric windows for shading
% Each row: {data_type, delta_str, shade_ranges, subplot_title}
% shade_ranges = [x_start, width; ...] pairs
% Each row: {data_type, delta, shade_ranges, shade_colors, subplot_title}
% shade_ranges = [x_start, width; ...] and shade_colors = {[r g b]; ...}
% Centring plots swapped: "after 10s" before "end of stim"
metric_ts = { ...
    "fv_data",   0,  [300, 900],          {[0.7 0.7 0.7]},                        'FV: full stimulus'; ...
    "fv_data",   0,  [210, 90; 300, 90],  {[0.7 0.7 0.7]; [0.7 0.7 0.7]},        'FV: onset \pm3s'; ...
    "curv_data", 0,  [300, 900],          {[0.7 0.7 0.7]},                        'Turning: full stimulus'; ...
    "curv_data", 0,  [315, 135],          {[0.7 0.7 0.7]},                        'Turning: first 5s CW'; ...
    "dist_data", 1,  [570, 30],           {[0.7 0.7 0.7]},                        'Centring: after 10s'; ...
    "dist_data", 1,  [1170, 30],          {[0.7 0.7 0.7]},                        'Centring: end of stim'; ...
};

for sp = 1:6
    subplot(2, 3, sp);

    dt        = metric_ts{sp, 1};
    delta     = metric_ts{sp, 2};
    shades    = metric_ts{sp, 3};
    shade_col = metric_ts{sp, 4};
    sp_title  = metric_ts{sp, 5};

    % Build the data_type string for plot_xcond_per_strain2
    if delta == 1
        dt_str = dt + "_delta";
    else
        dt_str = dt;
    end

    % Plot the ES control time series
    plot_xcond_per_strain2('protocol_27', dt_str, [cond_idx], ...
        {control_strain}, ts_params, DATA);

    % Get current y-limits for shading height
    yl = ylim;

    % Draw shaded rectangles for the metric window
    % For FV onset (subplot 2): pre-stimulus is more opaque than post-stimulus
    for r = 1:size(shades, 1)
        col_idx = min(r, numel(shade_col));
        if sp == 2 && r == 1
            alpha_val = 0.6;   % pre-stimulus: more opaque
        else
            alpha_val = 0.25;
        end
        rectangle('Position', [shades(r, 1), yl(1), shades(r, 2), diff(yl)], ...
            'FaceColor', shade_col{col_idx}, 'EdgeColor', 'none', 'FaceAlpha', alpha_val);
    end

    % Bring data lines to front by reordering children
    children = get(gca, 'Children');
    set(gca, 'Children', children);

    title(sp_title, 'FontSize', 12);
    set(gca, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
    f = gcf; f.Position= [233   595   932   376];
end

%% 6 — Centring vs turning scatter (one marker per strain)

% Load strain names in heatmap order (1:16) + ES (17)
n_plot_strains = numel(strain_ids);

turning_means  = NaN(n_plot_strains, 1);
centring_means = NaN(n_plot_strains, 1);

% Extract cell-type labels from strain names
cell_labels = cell(n_plot_strains, 1);
for k = 1:n_plot_strains
    sname = strain_names_list{strain_ids(k)};
    if strcmp(sname, 'jfrc100_es_shibire_kir')
        cell_labels{k} = 'ES';
    elseif startsWith(sname, 'l1l4_')
        cell_labels{k} = 'L1-L4';
    else
        % Remove ss####_ prefix and _shibire_kir suffix
        lbl = regexprep(sname, '^ss\d+_', '');
        lbl = strrep(lbl, '_shibire_kir', '');
        cell_labels{k} = lbl;
    end
end
% Fix specific labels
cell_labels = strrep(cell_labels, 't4t5', 'T4-T5');
cell_labels = strrep(cell_labels, 'DCH_VCH', 'DCH-VCH');
cell_labels = strrep(cell_labels, 'Pm2ab', 'Pm2a-b');

for k = 1:n_plot_strains
    strain = strain_names_list{strain_ids(k)};
    data = DATA.(strain).(sex);

    % Turning: mean curv_data during stimulus (frames 300:1200)
    curv = combine_timeseries_across_exp_check(data, cond_idx, "curv_data");
    % Sign-flip CCW half (frames 750:1200) to get symmetric turning magnitude
    curv(:, 750:1200) = curv(:, 750:1200) * -1;
    turning_means(k) = nanmean(nanmean(curv(:, 300:1200), 2)); %#ok<NANMEAN>

    % Centring: relative distance at end of stimulus (delta from frame 300)
    dist = combine_timeseries_across_exp_check(data, cond_idx, "dist_data");
    dist_delta = (dist - dist(:, 300)) * -1;  % positive = moved towards centre
    centring_means(k) = nanmean(nanmean(dist_delta(:, 1170:1200), 2)); %#ok<NANMEAN>
end

% Find ES control index (17)
ctrl_k = find(strain_ids == 17);

fig_scatter = figure('Position', [50 50 700 600]);
hold on;

% Grey crosshair through ES control point
xline(turning_means(ctrl_k), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
yline(centring_means(ctrl_k), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

% Plot each strain as a coloured marker (ES in light grey)
for k = 1:n_plot_strains
    if k == ctrl_k
        mc = [0.75 0.75 0.75];  % light grey for ES
    else
        mc = strain_colours(strain_ids(k), :);
    end
    scatter(turning_means(k), centring_means(k), 80, mc, 'filled', ...
        'MarkerEdgeColor', [0.3 0.3 0.3], 'LineWidth', 0.5);
end

% Add cell-type labels with anti-overlap
x_range = max(turning_means) - min(turning_means);
y_range = max(centring_means) - min(centring_means);
x_offset = x_range * 0.05;
y_offset = y_range * 0.05;

% Initial label positions: offset right and up by default
txt_x = turning_means + x_offset;
txt_y = centring_means + y_offset;

% Per-strain direction overrides
for k = 1:n_plot_strains
    lbl = cell_labels{k};
    if strcmp(lbl, 'LPC1')
        % Southwest
        txt_x(k) = turning_means(k) - x_offset;
        txt_y(k) = centring_means(k) - y_offset;
    elseif strcmp(lbl, 'DCH-VCH')
        % Below (south)
        txt_y(k) = centring_means(k) - y_offset;
    elseif strcmp(lbl, 'T5')
        % Northwest
        txt_x(k) = turning_means(k) - x_offset;
        txt_y(k) = centring_means(k) + y_offset;
    end
end

% Iterative overlap resolution: push apart labels that are too close
min_dy = y_range * 0.05;
min_dx = x_range * 0.08;
for pass = 1:10
    [~, sort_idx] = sort(txt_y);
    for i = 2:n_plot_strains
        a = sort_idx(i-1);
        b = sort_idx(i);
        if abs(txt_x(a) - txt_x(b)) < min_dx && abs(txt_y(a) - txt_y(b)) < min_dy
            mid = (txt_y(a) + txt_y(b)) / 2;
            txt_y(a) = mid - min_dy / 2;
            txt_y(b) = mid + min_dy / 2;
        end
    end
end

% Draw labels and connector lines
for k = 1:n_plot_strains
    plot([turning_means(k), txt_x(k)], [centring_means(k), txt_y(k)], ...
        '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.5);
    % Right-align text for labels to the left of their marker
    if txt_x(k) < turning_means(k)
        h_align = 'right';
    else
        h_align = 'left';
    end
    text(txt_x(k), txt_y(k), cell_labels{k}, 'FontSize', 8, ...
        'VerticalAlignment', 'middle', 'HorizontalAlignment', h_align);
end

xlabel('Mean turning rate during stimulus (deg/mm)', 'FontSize', 14);
ylabel('Centring (relative distance at end)', 'FontSize', 14);
title('Centring vs Turning — Condition 1', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
hold off;
f = gcf; f.Position = [50    50   305   269];

if save_figs
    if ~isfolder(save_folder); mkdir(save_folder); end
    exportgraphics(fig_scatter, fullfile(save_folder, 'fig4_centring_vs_turning.pdf'), ...
        'ContentType', 'vector');
end
