function fig = plot_strain_scatter(DATA, strain_ids, cond_idx, x_metric, y_metric, opts)
% PLOT_STRAIN_SCATTER  Scatter plot of one behavioural metric vs another across strains.
%
%   fig = PLOT_STRAIN_SCATTER(DATA, strain_ids, cond_idx, x_metric, y_metric)
%   fig = PLOT_STRAIN_SCATTER(DATA, strain_ids, cond_idx, x_metric, y_metric, opts)
%
%   Each strain contributes one marker (the mean across flies). The ES
%   control is shown in light grey with a 1-SD ellipse behind it.
%
%   INPUTS:
%     DATA       - struct from comb_data_across_cohorts_cond
%     strain_ids - vector of strain indices (into strain_names2.mat order,
%                  with 17 = ES control)
%     cond_idx   - scalar condition number
%     x_metric   - struct defining the x-axis metric:
%                    .data_type  - string, e.g. "curv_data", "dist_data"
%                    .frames     - frame range to average, e.g. 300:1200
%                    .delta      - 0=raw, 1=relative to frame 300, 2=relative to frame 1200
%                    .flip_ccw   - logical, if true flip sign of frames 750:1200
%                                  (for AV/curv to make CW and CCW additive)
%                    .label      - string for axis label
%     y_metric   - same struct format for y-axis
%     opts       - (optional) struct:
%                    .show_labels - logical, show strain labels (default: true)
%                    .show_sd     - logical, show 1-SD ellipse (default: true)
%                    .title_str   - title string (default: auto)
%
%   OUTPUT:
%     fig - figure handle
%
%   EXAMPLE:
%     x_met.data_type = "curv_data";
%     x_met.frames = 300:1200;
%     x_met.delta = 0;
%     x_met.flip_ccw = true;
%     x_met.label = 'Mean turning rate (deg/mm)';
%
%     y_met.data_type = "dist_data";
%     y_met.frames = 1170:1200;
%     y_met.delta = 1;
%     y_met.flip_ccw = false;
%     y_met.label = 'Centring at end of stimulus (mm)';
%
%     fig = plot_strain_scatter(DATA, 1:17, 1, x_met, y_met);
%
%   See also: combine_timeseries_across_exp, cmap_config

if nargin < 6, opts = struct(); end
show_labels = get_opt(opts, 'show_labels', true);
show_sd     = get_opt(opts, 'show_sd', true);
title_str   = get_opt(opts, 'title_str', '');

%% Load strain names and colours
cfg = get_config();
strain_names_s = load(fullfile(cfg.results, 'strain_names2.mat'));
strain_names_list = strain_names_s.strain_names;
strain_names_list{end+1} = 'jfrc100_es_shibire_kir';
strain_names_list{end+1} = 'csw1118';

cmaps = cmap_config();
strain_colours = cmaps.strains.colors;

sex = 'F';
control_strain = 'jfrc100_es_shibire_kir';

n_strains = numel(strain_ids);

%% Extract per-strain means and SDs for both metrics
x_means = NaN(n_strains, 1);
y_means = NaN(n_strains, 1);
x_sds   = NaN(n_strains, 1);
y_sds   = NaN(n_strains, 1);

for k = 1:n_strains
    sname = strain_names_list{strain_ids(k)};
    if ~isfield(DATA, sname), continue; end
    data = DATA.(sname).(sex);

    per_fly_x = extract_metric(data, cond_idx, x_metric);
    per_fly_y = extract_metric(data, cond_idx, y_metric);

    x_means(k) = nanmean(per_fly_x); %#ok<NANMEAN>
    y_means(k) = nanmean(per_fly_y); %#ok<NANMEAN>
    x_sds(k)   = nanstd(per_fly_x);  %#ok<NANSTD>
    y_sds(k)   = nanstd(per_fly_y);   %#ok<NANSTD>
end

%% Build cell-type labels
cell_labels = cell(n_strains, 1);
for k = 1:n_strains
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

%% Find control index
ctrl_k = [];
for k = 1:n_strains
    if strcmp(strain_names_list{strain_ids(k)}, control_strain)
        ctrl_k = k;
        break;
    end
end

%% Print SD values
if ~isempty(ctrl_k)
    fprintf('ES control scatter (condition %d):\n', cond_idx);
    fprintf('  X (%s): mean = %.2f, SD = %.2f\n', x_metric.label, x_means(ctrl_k), x_sds(ctrl_k));
    fprintf('  Y (%s): mean = %.2f, SD = %.2f\n', y_metric.label, y_means(ctrl_k), y_sds(ctrl_k));
end

%% Plot
fig = figure('Position', [50 50 700 600]);
hold on;

% Grey crosshair through ES control
if ~isempty(ctrl_k)
    xline(x_means(ctrl_k), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
    yline(y_means(ctrl_k), '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

    % 1-SD ellipse
    if show_sd
        theta_ell = linspace(0, 2*pi, 200);
        ell_x = x_means(ctrl_k) + x_sds(ctrl_k) * cos(theta_ell);
        ell_y = y_means(ctrl_k) + y_sds(ctrl_k) * sin(theta_ell);
        fill(ell_x, ell_y, [0.85 0.85 0.85], 'FaceAlpha', 0.3, ...
            'EdgeColor', [0.7 0.7 0.7], 'LineWidth', 0.5);
    end
end

% Strain markers
for k = 1:n_strains
    if k == ctrl_k
        mc = [0.75 0.75 0.75];
    else
        mc = strain_colours(strain_ids(k), :);
    end
    scatter(x_means(k), y_means(k), 80, mc, 'filled', ...
        'MarkerEdgeColor', [0.3 0.3 0.3], 'LineWidth', 0.5);
end

% Labels — placed along the line from ES through each marker
%
% For each strain (except L1-L4 and T4-T5), the label is placed along the
% ray from the ES control marker through the strain's marker, offset
% beyond the marker. This fans labels outward radially from ES.
% L1-L4 and T4-T5 are skipped (no label drawn).
if show_labels
    xl = xlim;  yl = ylim;
    x_range = diff(xl);
    y_range = diff(yl);

    % Offset distance along the ray (in data units)
    ray_offset = 0.08;  % fraction of axis range

    if ~isempty(ctrl_k)
        es_x = x_means(ctrl_k);
        es_y = y_means(ctrl_k);
    else
        es_x = nanmean(x_means);
        es_y = nanmean(y_means);
    end

    % Strains to position manually (not along the ES ray)
    manual_labels = {'L1-L4', 'T4-T5'};

    % Approximate text dimensions in normalised axis units
    char_w  = 0.012;   % per character (fraction of x_range)
    label_h = 0.035;   % label height (fraction of y_range)

    % --- Phase 1: Compute initial label positions ---
    txt_x = NaN(n_strains, 1);
    txt_y = NaN(n_strains, 1);
    ray_dx = NaN(n_strains, 1);  % unit ray direction (normalised)
    ray_dy = NaN(n_strains, 1);

    for k = 1:n_strains
        if any(strcmp(cell_labels{k}, manual_labels))
            txt_x(k) = x_means(k) + ray_offset * x_range * 0.8;
            txt_y(k) = y_means(k);
            ray_dx(k) = 1;
            ray_dy(k) = 0;
        else
            dx_norm = (x_means(k) - es_x) / x_range;
            dy_norm = (y_means(k) - es_y) / y_range;
            rl = sqrt(dx_norm^2 + dy_norm^2);

            if rl < 1e-6
                txt_x(k) = x_means(k) + ray_offset * x_range;
                txt_y(k) = y_means(k);
                ray_dx(k) = 1;
                ray_dy(k) = 0;
            else
                ray_dx(k) = dx_norm / rl;
                ray_dy(k) = dy_norm / rl;
                txt_x(k) = x_means(k) + ray_dx(k) * ray_offset * x_range;
                txt_y(k) = y_means(k) + ray_dy(k) * ray_offset * y_range;
            end
        end
    end

    % --- Phase 2: Push overlapping labels further along their ray ---
    % Check each label against all markers and all other labels. If
    % overlapping, extend the offset along the same ray direction.
    nudge_step = 0.03;  % fraction of axis range per nudge
    max_nudges = 10;

    for k = 1:n_strains
        lbl_w_k = numel(cell_labels{k}) * char_w * x_range;
        lbl_h_k = label_h * y_range;

        for nudge = 1:max_nudges
            overlaps = false;

            % Check against all markers
            for j = 1:n_strains
                if abs(txt_x(k) - x_means(j)) < lbl_w_k * 0.6 && ...
                   abs(txt_y(k) - y_means(j)) < lbl_h_k * 0.8
                    overlaps = true;
                    break;
                end
            end

            % Check against other labels
            if ~overlaps
                for j = 1:n_strains
                    if j == k, continue; end
                    lbl_w_j = numel(cell_labels{j}) * char_w * x_range;
                    if abs(txt_x(k) - txt_x(j)) < max(lbl_w_k, lbl_w_j) * 0.8 && ...
                       abs(txt_y(k) - txt_y(j)) < lbl_h_k
                        overlaps = true;
                        break;
                    end
                end
            end

            if ~overlaps, break; end

            % Extend along the ray
            txt_x(k) = txt_x(k) + ray_dx(k) * nudge_step * x_range;
            txt_y(k) = txt_y(k) + ray_dy(k) * nudge_step * y_range;
        end
    end

    % --- Phase 3: Draw labels and connector lines ---
    % Add a small gap between the end of the line and the text
    text_gap = 0.015;  % fraction of axis range

    for k = 1:n_strains
        is_es = (k == ctrl_k);

        if is_es
            % ES label: place near marker, no connector line
            text(x_means(k) + text_gap * x_range * 2, y_means(k), ...
                cell_labels{k}, 'FontSize', 8, ...
                'VerticalAlignment', 'middle', 'HorizontalAlignment', 'left');
        else
            % Connector line from marker to label position
            plot([x_means(k), txt_x(k)], [y_means(k), txt_y(k)], ...
                '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.5);

            % Offset text slightly beyond the end of the line
            gap_x = ray_dx(k) * text_gap * x_range;
            gap_y = ray_dy(k) * text_gap * y_range;

            if txt_x(k) + gap_x < x_means(k)
                h_align = 'right';
            else
                h_align = 'left';
            end
            text(txt_x(k) + gap_x, txt_y(k) + gap_y, cell_labels{k}, ...
                'FontSize', 8, 'VerticalAlignment', 'middle', ...
                'HorizontalAlignment', h_align);
        end
    end
end

xlabel(x_metric.label, 'FontSize', 14);
ylabel(y_metric.label, 'FontSize', 14);
if ~isempty(title_str)
    title(title_str, 'FontSize', 16);
end
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
hold off;

end

%% ===== Local helpers =====

function per_fly = extract_metric(data, cond_idx, metric)
% Extract per-fly mean values for one metric specification.
    ts = combine_timeseries_across_exp(data, cond_idx, metric.data_type);

    if metric.delta == 1
        ts = (ts - ts(:, 300)) * -1;
    elseif metric.delta == 2
        ts = (ts - ts(:, 1200)) * -1;
    end

    if metric.flip_ccw
        ts(:, 750:1200) = ts(:, 750:1200) * -1;
    end

    % Reverse-phi sign convention
    if (cond_idx == 7 || cond_idx == 8) && metric.flip_ccw
        ts = ts * -1;
    end

    per_fly = nanmean(ts(:, metric.frames), 2); %#ok<NANMEAN>
end

function val = get_opt(s, field, default)
    if isfield(s, field), val = s.(field); else, val = default; end
end
