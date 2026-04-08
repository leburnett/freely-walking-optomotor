%% fig4_scatter_all_conditions — Centring vs turning scatter for all 12 conditions
%
% Generates:
%   1. 12 scatter plots (one per condition): each marker = one strain
%   2. 1 scatter plot (ES only): each marker = one condition
%
% REQUIREMENTS:
%   - Protocol 27 data via comb_data_across_cohorts_cond
%   - strain_names2.mat in results folder
%   - Functions: combine_timeseries_across_exp_check, get_config
%
% See also: fig4, cross_strain_condition_heatmaps

%% 1 — Configuration & data loading

cfg = get_config();
protocol_dir = fullfile(cfg.results, 'protocol_27');

if ~exist('DATA', 'var') || isempty(fieldnames(DATA))
    fprintf('Loading Protocol 27 data from: %s\n', protocol_dir);
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

save_figs = false;
save_folder = fullfile(cfg.figures, 'FIGS');

%% 2 — Strain setup

control_strain = 'jfrc100_es_shibire_kir';
sex = 'F';

strain_ids = 1:17;

% Strain colours (matches plot_boxchart_metrics_xstrains)
strain_colours = [[220,  40,  30]; ...
    [220,  85,  30]; ...
    [220, 130,  35]; ...
    [220, 175,  40]; ...
    [220, 210,  50]; ...
    [190, 170,  60]; ...
    [164, 182, 120]; ...
    [134, 187, 139]; ...
    [104, 185, 158]; ...
    [ 82, 176, 176]; ...
    [ 72, 160, 192]; ...
    [ 74, 138, 202]; ...
    [ 86, 114, 204]; ...
    [108,  92, 198]; ...
    [132,  74, 186]; ...
    [154,  60, 168]; ...
    [ 40,  40,  40]; ...
    [180, 180, 180]] ./ 255;

% Load strain names
strain_names_s = load(fullfile(cfg.results, 'strain_names2.mat'));
strain_names_list = strain_names_s.strain_names;
strain_names_list{end+1} = 'jfrc100_es_shibire_kir';
strain_names_list{end+1} = 'csw1118';

n_plot_strains = numel(strain_ids);

% Cell-type labels
cell_labels = cell(n_plot_strains, 1);
for k = 1:n_plot_strains
    sname = strain_names_list{strain_ids(k)};
    if strcmp(sname, 'jfrc100_es_shibire_kir')
        cell_labels{k} = 'ES';
    elseif startsWith(sname, 'l1l4_')
        cell_labels{k} = 'L1-L4';
    else
        lbl = regexprep(sname, '^ss\d+_', '');
        lbl = strrep(lbl, '_shibire_kir', '');
        cell_labels{k} = lbl;
    end
end
cell_labels = strrep(cell_labels, 't4t5', 'T4-T5');
cell_labels = strrep(cell_labels, 'DCH_VCH', 'DCH-VCH');
cell_labels = strrep(cell_labels, 'Pm2ab', 'Pm2a-b');

ctrl_k = find(strain_ids == 17);

%% 3 — Condition setup

N_CONDITIONS = 12;
cond_titles = {'60deg 4Hz', '60deg 8Hz', 'ON bars', 'OFF bars', ...
    'ON curt.', 'OFF curt.', 'RevPhi 2Hz', 'RevPhi 4Hz', ...
    'Flicker', 'Static', 'Offset CoR', 'Bar fix.'};

% Condition colours (rainbow for 12 conditions)
cond_colors = [ ...
    31 120 180; ...   % 1: blue
    31 120 180; ...   % 2: blue
    178 223 138; ...  % 3: green
    47 141 41; ...    % 4: dark green
    251 154 153; ...  % 5: light red
    227  26  28; ...  % 6: red
    253 191 111; ...  % 7: orange
    255 127   0; ...  % 8: dark orange
    166 206 227; ...  % 9: light blue
    200 200 200; ...  % 10: grey
    255 224  41; ...  % 11: yellow
    187  75  12; ...  % 12: brown
] ./ 255;

%% 4 — Scatter plots: one per condition, markers = strains

for cond_idx = 1:N_CONDITIONS

    turning_means  = NaN(n_plot_strains, 1);
    centring_means = NaN(n_plot_strains, 1);

    for k = 1:n_plot_strains
        strain = strain_names_list{strain_ids(k)};
        data = DATA.(strain).(sex);

        curv = combine_timeseries_across_exp_check(data, cond_idx, "av_data");
        curv(:, 750:1200) = curv(:, 750:1200) * -1;
     
        turning_means(k) = nanmean(nanmean(curv(:, 300:1200), 2)); %#ok<NANMEAN>

        dist = combine_timeseries_across_exp_check(data, cond_idx, "dist_data");
        dist_delta = (dist - dist(:, 300)) * -1;
        centring_means(k) = nanmean(nanmean(dist_delta(:, 1170:1200), 2)); %#ok<NANMEAN>
    end

    fig_scatter = figure('Position', [50 50 700 600], ...
        'Name', sprintf('Scatter Cond %d: %s', cond_idx, cond_titles{cond_idx}));
    hold on;

    % Grey crosshair through ES control point
    xline(turning_means(ctrl_k), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    yline(centring_means(ctrl_k), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    xline(0, ':', 'Color', [0 0 0], 'LineWidth', 0.5);
    yline(0, ':', 'Color', [0 0 0], 'LineWidth', 0.5);

    % Plot markers
    for k = 1:n_plot_strains
        if k == ctrl_k
            mc = [0.75 0.75 0.75];
        else
            mc = strain_colours(strain_ids(k), :);
        end
        scatter(turning_means(k), centring_means(k), 80, mc, 'filled', ...
            'MarkerEdgeColor', [0.3 0.3 0.3], 'LineWidth', 0.5);
    end

    % Labels with anti-overlap
    x_range = max(turning_means) - min(turning_means);
    y_range = max(centring_means) - min(centring_means);
    if x_range == 0; x_range = 1; end
    if y_range == 0; y_range = 1; end
    x_offset = x_range * 0.05;
    y_offset = y_range * 0.05;

    txt_x = turning_means + x_offset;
    txt_y = centring_means + y_offset;

    for k = 1:n_plot_strains
        lbl = cell_labels{k};
        if strcmp(lbl, 'LPC1')
            txt_x(k) = turning_means(k) - x_offset;
            txt_y(k) = centring_means(k) - y_offset;
        elseif strcmp(lbl, 'DCH-VCH')
            txt_y(k) = centring_means(k) - y_offset;
        elseif strcmp(lbl, 'T5')
            txt_x(k) = turning_means(k) - x_offset;
            txt_y(k) = centring_means(k) + y_offset;
        end
    end

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

    for k = 1:n_plot_strains
        plot([turning_means(k), txt_x(k)], [centring_means(k), txt_y(k)], ...
            '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.5);
        if txt_x(k) < turning_means(k)
            h_align = 'right';
        else
            h_align = 'left';
        end
        text(txt_x(k), txt_y(k), cell_labels{k}, 'FontSize', 8, ...
            'VerticalAlignment', 'middle', 'HorizontalAlignment', h_align);
    end

    xlabel('Mean angular velocity during stimulus (deg/s)', 'FontSize', 14);
    ylabel('Centring (relative distance at end)', 'FontSize', 14);
    title(sprintf('Centring vs Turning — %s', cond_titles{cond_idx}), 'FontSize', 16);
    set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
    hold off;
    f = gcf; f.Position = [50 50 305 269];
end

%% 5 — Scatter plot: ES only, each marker = one condition

turning_es  = NaN(N_CONDITIONS, 1);
centring_es = NaN(N_CONDITIONS, 1);

data_es = DATA.(control_strain).(sex);

for c = 1:N_CONDITIONS
    curv = combine_timeseries_across_exp_check(data_es, c, "av_data");
    curv(:, 750:1200) = curv(:, 750:1200) * -1;
    turning_es(c) = nanmean(nanmean(curv(:, 300:1200), 2)); %#ok<NANMEAN>

    dist = combine_timeseries_across_exp_check(data_es, c, "dist_data");
    dist_delta = (dist - dist(:, 300)) * -1;
    centring_es(c) = nanmean(nanmean(dist_delta(:, 1170:1200), 2)); %#ok<NANMEAN>
end

figure('Position', [50 50 700 600], 'Name', 'Scatter ES: conditions');
hold on;

% Crosshair through condition 1
xline(turning_es(1), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
yline(centring_es(1), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(0, ':', 'Color', [0 0 0], 'LineWidth', 0.5);
yline(0, ':', 'Color', [0 0 0], 'LineWidth', 0.5);

% Plot each condition as a coloured marker
for c = 1:N_CONDITIONS
    scatter(turning_es(c), centring_es(c), 100, cond_colors(c, :), 'filled', ...
        'MarkerEdgeColor', [0.3 0.3 0.3], 'LineWidth', 0.5);
end

% Labels with anti-overlap
x_range_es = max(turning_es) - min(turning_es);
y_range_es = max(centring_es) - min(centring_es);
if x_range_es == 0; x_range_es = 1; end
if y_range_es == 0; y_range_es = 1; end
x_off_es = x_range_es * 0.05;
y_off_es = y_range_es * 0.05;

txt_x_es = turning_es + x_off_es;
txt_y_es = centring_es + y_off_es;

min_dy_es = y_range_es * 0.055;
min_dx_es = x_range_es * 0.10;
for pass = 1:10
    [~, sort_idx] = sort(txt_y_es);
    for i = 2:N_CONDITIONS
        a = sort_idx(i-1);
        b = sort_idx(i);
        if abs(txt_x_es(a) - txt_x_es(b)) < min_dx_es && ...
                abs(txt_y_es(a) - txt_y_es(b)) < min_dy_es
            mid = (txt_y_es(a) + txt_y_es(b)) / 2;
            txt_y_es(a) = mid - min_dy_es / 2;
            txt_y_es(b) = mid + min_dy_es / 2;
        end
    end
end

for c = 1:N_CONDITIONS
    plot([turning_es(c), txt_x_es(c)], [centring_es(c), txt_y_es(c)], ...
        '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.5);
    text(txt_x_es(c), txt_y_es(c), cond_titles{c}, 'FontSize', 8, ...
        'VerticalAlignment', 'middle');
end

xlabel('Mean angular velocity during stimulus (deg/s)', 'FontSize', 14);
ylabel('Centring (relative distance at end)', 'FontSize', 14);
% title('ES control — Centring vs Turning by condition', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
hold off;
f = gcf; f.Position = [50 50 305 269];


%% 6 — Scatter plot: Other strain only, each marker = one condition

test_strain = "ss324_t4t5_shibire_kir";

turning_test  = NaN(N_CONDITIONS, 1);
centring_test = NaN(N_CONDITIONS, 1);

data_es = DATA.(test_strain).(sex);

for c = 1:N_CONDITIONS
    curv = combine_timeseries_across_exp_check(data_es, c, "av_data");
    curv(:, 750:1200) = curv(:, 750:1200) * -1;
    turning_test(c) = nanmean(nanmean(curv(:, 300:1200), 2)); %#ok<NANMEAN>

    dist = combine_timeseries_across_exp_check(data_es, c, "dist_data");
    dist_delta = (dist - dist(:, 300)) * -1;
    centring_test(c) = nanmean(nanmean(dist_delta(:, 1170:1200), 2)); %#ok<NANMEAN>
end

figure('Position', [50 50 700 600], 'Name', 'Scatter ES: conditions');
hold on;

% Crosshair through condition 1
xline(turning_test(1), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
yline(centring_test(1), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xline(0, ':', 'Color', [0 0 0], 'LineWidth', 0.5);
yline(0, ':', 'Color', [0 0 0], 'LineWidth', 0.5);

% Plot each condition as a coloured marker
for c = 1:N_CONDITIONS
    scatter(turning_test(c), centring_test(c), 100, cond_colors(c, :), 'filled', ...
        'MarkerEdgeColor', [0.3 0.3 0.3], 'LineWidth', 0.5);
end

% Labels with anti-overlap
x_range_es = max(turning_test) - min(turning_test);
y_range_es = max(centring_test) - min(centring_test);
if x_range_es == 0; x_range_es = 1; end
if y_range_es == 0; y_range_es = 1; end
x_off_es = x_range_es * 0.05;
y_off_es = y_range_es * 0.05;

txt_x_es = turning_test + x_off_es;
txt_y_es = centring_test + y_off_es;

min_dy_es = y_range_es * 0.055;
min_dx_es = x_range_es * 0.10;
for pass = 1:10
    [~, sort_idx] = sort(txt_y_es);
    for i = 2:N_CONDITIONS
        a = sort_idx(i-1);
        b = sort_idx(i);
        if abs(txt_x_es(a) - txt_x_es(b)) < min_dx_es && ...
                abs(txt_y_es(a) - txt_y_es(b)) < min_dy_es
            mid = (txt_y_es(a) + txt_y_es(b)) / 2;
            txt_y_es(a) = mid - min_dy_es / 2;
            txt_y_es(b) = mid + min_dy_es / 2;
        end
    end
end

for c = 1:N_CONDITIONS
    plot([turning_test(c), txt_x_es(c)], [centring_test(c), txt_y_es(c)], ...
        '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.5);
    text(txt_x_es(c), txt_y_es(c), cond_titles{c}, 'FontSize', 8, ...
        'VerticalAlignment', 'middle');
end

xlabel('Mean angular velocity during stimulus (deg/s)', 'FontSize', 14);
ylabel('Centring (relative distance at end)', 'FontSize', 14);
% title('ES control — Centring vs Turning by condition', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
hold off;
f = gcf; f.Position = [50 50 305 269];
