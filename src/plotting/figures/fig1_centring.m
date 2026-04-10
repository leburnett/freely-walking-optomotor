%% FIG1_CENTRING — Figure 1: Experimental System & the Centring Phenomenon
%
% PANELS:
%   A — Arena schematic (PLACEHOLDER for Illustrator artwork)
%   B — Example fly trajectories (pre/during/post colored)
%   C — Baseline-subtracted centring timeseries (inverted, + = towards centre)
%   D — Violin plot of per-fly centring at stimulus offset
%   E — Spatial occupancy heatmaps (pre-stimulus vs during-stimulus)
%
% LAYOUT: 3x3 subplot grid
%   Row 1: A(1:2),  B(3)
%   Row 2: C(4:5),  D(6)
%   Row 3: E(7:9) — two heatmaps with horizontal colorbar below
%
% REQUIREMENTS:
%   - Results folder: results/protocol_27/
%   - Functions: comb_data_across_cohorts_cond, combine_timeseries_across_exp,
%     combine_timeseries_across_exp_check
%
% See also: fig1_plots, plot_traj_pre_post, plot_fly_occupancy_heatmaps_all

%% 1 — Configuration & data loading

if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
    fprintf('Loaded P27 DATA from %s\n', protocol_dir);
end

cfg = get_config();

% --- Constants ---
strain = 'jfrc100_es_shibire_kir';
cond_n = 1;         % 60deg gratings, 4Hz
fps = 30;

% Arena geometry (mm)
cx = 122.8079;
cy = 124.7267;
PPM = 4.1691;
Centre_mm = [528, 516] / PPM;
Radius_mm = 496 / PPM;

% Frame ranges
STIM_ON  = 300;   % frame
STIM_OFF = 1200;  % frame
pre_frames  = 150:STIM_ON;
stim_frames = (STIM_ON+1):STIM_OFF;
post_frames = (STIM_OFF+1):1350;

% Colors (from cmap_config)
cmaps = cmap_config();
col_stim = cmaps.centring.colors(1,:);   % blue
col_grey = cmaps.centring.colors(2,:);   % pre/post & reference lines

% Control data
data = DATA.(strain).F;

%% 2 — Extract data

% Trajectories (x, y) — no QC needed
cond_x = combine_timeseries_across_exp(data, cond_n, 'x_data');
cond_y = combine_timeseries_across_exp(data, cond_n, 'y_data');

% Distance from centre — with quiescence QC
cond_dist = combine_timeseries_across_exp_check(data, cond_n, 'dist_data');

% Baseline-subtracted distance
cond_dist_delta = cond_dist - cond_dist(:, STIM_ON);

% Invert: positive = moved towards centre
cond_centring = -cond_dist_delta;

n_flies  = size(cond_dist, 1);
n_frames = size(cond_dist, 2);
time_s   = (1:n_frames) / fps;

fprintf('Control flies (QC-filtered): %d\n', n_flies);
fprintf('Total trajectory flies (no QC): %d\n', size(cond_x, 1));

%% 3 — Create figure

hFig = figure('Color', 'w', 'Position', [50 50 1400 1050], ...
    'Name', 'Figure 1 — Centring Phenomenon');

%% 4 — Panel A: Placeholder

subplot(3, 3, [1, 2]);
text(0.5, 0.5, {'Panel A', 'Arena Schematic', '(Illustrator)'}, ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
    'FontSize', 14, 'Color', [0.5 0.5 0.5]);
xlim([0 1]); ylim([0 1]);
axis off;
text(-0.05, 1.05, 'A', 'Units', 'normalized', 'FontSize', 18, 'FontWeight', 'bold');

%% 5 — Panel B: Example trajectories (pre / during / post)

subplot(3, 3, 3);
hold on;

% Draw arena background
rectangle('Position', [0.25, 2.5, 245, 245], 'Curvature', [1, 1], ...
    'FaceColor', [0.95 0.95 0.95], 'EdgeColor', 'none');
viscircles([cx, cy], 121, 'Color', [0.8 0.8 0.8], 'LineStyle', '-', 'LineWidth', 1);

% Centre cross
plot(cx, cy, '+', 'Color', [0.8 0 0], 'MarkerSize', 12, 'LineWidth', 1.5);

% Select representative flies (curated from fig1_plots.m)
fly_ids = [807, 802, 791];
fly_ids = fly_ids(fly_ids <= size(cond_x, 1));  % bounds check

for f = 1:numel(fly_ids)
    fi = fly_ids(f);
    xd = cond_x(fi, :);
    yd = cond_y(fi, :);

    % Pre-stimulus (grey)
    fr = pre_frames(pre_frames <= numel(xd));
    plot(xd(fr), yd(fr), '-', 'Color', col_grey, 'LineWidth', 1);

    % During stimulus (blue)
    fr = stim_frames(stim_frames <= numel(xd));
    plot(xd(fr), yd(fr), '-', 'Color', col_stim, 'LineWidth', 1.5);

    % Post-stimulus (grey)
    fr = post_frames(post_frames <= numel(xd));
    if ~isempty(fr)
        plot(xd(fr), yd(fr), '-', 'Color', col_grey, 'LineWidth', 1);
    end

    % End marker (stimulus offset) — white filled
    if STIM_OFF <= numel(xd)
        plot(xd(STIM_OFF), yd(STIM_OFF), 'o', ...
            'MarkerFaceColor', 'w', 'MarkerEdgeColor', 'k', 'MarkerSize', 6);
    end
end

axis equal; axis off;
xlim([-2 247]); ylim([0 248]);

% Legend entries (invisible dummy lines for clean legend)
h_pre  = plot(NaN, NaN, '-', 'Color', col_grey, 'LineWidth', 1.5);
h_stim = plot(NaN, NaN, '-', 'Color', col_stim, 'LineWidth', 1.5);
legend([h_pre, h_stim], {'Pre/Post', 'Stimulus'}, ...
    'Location', 'southeast', 'FontSize', 10, 'Box', 'off');

text(-0.05, 1.05, 'B', 'Units', 'normalized', 'FontSize', 18, 'FontWeight', 'bold');

%% 6 — Panel C: Centring timeseries (mean +/- SEM)

subplot(3, 3, [4, 5]);
hold on;

mu_delta  = nanmean(cond_centring, 1);
sem_delta = nanstd(cond_centring, 0, 1) ./ sqrt(sum(~isnan(cond_centring), 1));

% SEM shading
fill([time_s fliplr(time_s)], ...
    [mu_delta + sem_delta, fliplr(mu_delta - sem_delta)], ...
    col_stim, 'FaceAlpha', 0.15, 'EdgeColor', 'none');

% Mean line
plot(time_s, mu_delta, '-', 'Color', col_stim, 'LineWidth', 1.5);

% Reference lines
yline(0, '-', 'Color', col_grey, 'LineWidth', 1);
xline(STIM_ON / fps, '-', 'Color', col_grey, 'LineWidth', 1);
xline(STIM_OFF / fps, '-', 'Color', col_grey, 'LineWidth', 1);

xlabel('Time (s)', 'FontSize', 14);
ylabel('Distance moved towards centre (mm)', 'FontSize', 14);
title('Centring (baseline-subtracted)', 'FontSize', 16);
xlim([0 time_s(end)]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% --- Stimulus timing rectangles at top ---
yl_c = ylim;
rect_h_c = diff(yl_c) / 20;
ylim([yl_c(1), yl_c(2) + rect_h_c]);
t_on  = STIM_ON / fps;
t_off = STIM_OFF / fps;
t_end = time_s(end);
rect_y_c = yl_c(2);
% Pre-stimulus (dark grey)
rectangle('Position', [0, rect_y_c, t_on, rect_h_c], ...
    'FaceColor', [0.4 0.4 0.4], 'EdgeColor', 'k');
% Stimulus (alternating black/white bars)
bar_dur = (t_off - t_on) / 60;
for bi = 1:60
    bx = t_on + (bi - 1) * bar_dur;
    if mod(bi, 2) == 1, fc = 'w'; else, fc = 'k'; end
    rectangle('Position', [bx, rect_y_c, bar_dur, rect_h_c], ...
        'FaceColor', fc, 'EdgeColor', 'k');
end
% Post-stimulus (dark grey)
rectangle('Position', [t_off, rect_y_c, t_end - t_off, rect_h_c], ...
    'FaceColor', [0.4 0.4 0.4], 'EdgeColor', 'k');

text(-0.12, 1.05, 'C', 'Units', 'normalized', 'FontSize', 18, 'FontWeight', 'bold');

%% 7 — Panel D: Violin plot of per-fly centring at stimulus offset

subplot(3, 3, 6);
hold on;

% Per-fly centring at stimulus offset (positive = moved towards centre)
fly_centring = cond_centring(:, STIM_OFF);
fly_centring = fly_centring(~isnan(fly_centring));

% --- Kernel density estimate for violin shape ---
[f_kde, xi] = ksdensity(fly_centring, 'NumPoints', 200);
% Normalise density to a max half-width of 0.35 (centred at x=1)
f_norm = f_kde / max(f_kde) * 0.35;

% Violin body (filled, 40% opacity — dashboard style)
fill([1 - f_norm, fliplr(1 + f_norm)], [xi, fliplr(xi)], ...
    col_stim, 'FaceAlpha', 0.4, 'EdgeColor', col_stim, 'LineWidth', 1);

% --- Box plot overlay ---
q25 = prctile(fly_centring, 25);
q75 = prctile(fly_centring, 75);
med_val = nanmedian(fly_centring);
mu_val  = nanmean(fly_centring);
iqr_val = q75 - q25;
whisk_lo = max(min(fly_centring), q25 - 1.5 * iqr_val);
whisk_hi = min(max(fly_centring), q75 + 1.5 * iqr_val);

% Whiskers
plot([1 1], [whisk_lo, q25], '-', 'Color', 'k', 'LineWidth', 1.2);
plot([1 1], [q75, whisk_hi], '-', 'Color', 'k', 'LineWidth', 1.2);
% IQR box
box_hw = 0.12;
rectangle('Position', [1 - box_hw, q25, 2 * box_hw, q75 - q25], ...
    'FaceColor', 'w', 'EdgeColor', 'k', 'LineWidth', 1.2);
% Median line (solid)
plot([1 - box_hw, 1 + box_hw], [med_val, med_val], '-k', 'LineWidth', 2);
% Mean line (dashed)
plot([1 - box_hw, 1 + box_hw], [mu_val, mu_val], '--k', 'LineWidth', 1.5);

% --- Individual data points (white fill, blue border — dashboard style) ---
rng_state = rng(42);  % reproducible jitter
jitter = (rand(numel(fly_centring), 1) - 0.5) * 0.5;
scatter(1 + jitter, fly_centring, 20, ...
    'MarkerFaceColor', 'w', 'MarkerEdgeColor', col_stim, ...
    'MarkerFaceAlpha', 0.8, 'LineWidth', 0.75);
rng(rng_state);

% Reference line at zero
yline(0, '-', 'Color', col_grey, 'LineWidth', 1);

xlim([0.2 1.8]);
ylabel('Distance moved towards centre (mm)', 'FontSize', 14);
title('Per-fly centring', 'FontSize', 16);
set(gca, 'XTick', [], 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Annotation
n_pos = sum(fly_centring > 0);
text(1, min(ylim) + 0.05 * diff(ylim), ...
    sprintf('%d/%d\ncentred', n_pos, numel(fly_centring)), ...
    'FontSize', 10, 'Color', [0.4 0.4 0.4], 'HorizontalAlignment', 'center');

text(-0.12, 1.05, 'D', 'Units', 'normalized', 'FontSize', 18, 'FontWeight', 'bold');

%% 8 — Panel E: Occupancy heatmaps (pre vs during)

% Use subplot(3,3,[7,8,9]) to get the full bottom-row position, then split manually
ax_e_tmp = subplot(3, 3, [7, 8, 9]);
pos_e = get(ax_e_tmp, 'Position');
delete(ax_e_tmp);

% Collect x/y for pre and stim periods from all entries
x_pre_all  = []; y_pre_all  = [];
x_stim_all = []; y_stim_all = [];

for k = 1:numel(data)
    for rig = ["R1", "R2"]
        fld = sprintf('%s_condition_%d', rig, cond_n);
        if isfield(data(k), fld) && ~isempty(data(k).(fld))
            S = data(k).(fld);
            if ~isfield(S, 'x_data') || ~isfield(S, 'y_data'), continue; end

            xd = S.x_data;
            yd = S.y_data;
            if ~isnumeric(xd) || isempty(xd), continue; end

            % Ensure [n_frames x n_flies] orientation
            if isvector(xd), xd = xd(:); end
            if isvector(yd), yd = yd(:); end
            [~, xTimeDim] = max(size(xd));
            [~, yTimeDim] = max(size(yd));
            if xTimeDim == 2, xd = xd.'; end
            if yTimeDim == 2, yd = yd.'; end

            T = min(size(xd, 1), size(yd, 1));

            % Pre-stimulus (frames 1:300)
            fr_pre = 1:min(STIM_ON, T);
            xp = xd(fr_pre, :); yp = yd(fr_pre, :);
            valid = xp >= 0 & xp <= 250 & yp >= 0 & yp <= 250;
            x_pre_all  = [x_pre_all;  xp(valid)]; %#ok<AGROW>
            y_pre_all  = [y_pre_all;  yp(valid)]; %#ok<AGROW>

            % During stimulus (frames 301:1200)
            fr_stim = (STIM_ON+1):min(STIM_OFF, T);
            xs = xd(fr_stim, :); ys = yd(fr_stim, :);
            valid = xs >= 0 & xs <= 250 & ys >= 0 & ys <= 250;
            x_stim_all = [x_stim_all; xs(valid)]; %#ok<AGROW>
            y_stim_all = [y_stim_all; ys(valid)]; %#ok<AGROW>
        end
    end
end

% Shared bin edges
nbins = 20;
all_x = [x_pre_all; x_stim_all];
all_y = [y_pre_all; y_stim_all];
xedges = linspace(min(all_x), max(all_x), nbins + 1);
yedges = linspace(min(all_y), max(all_y), nbins + 1);
xcent = (xedges(1:end-1) + xedges(2:end)) / 2;
ycent = (yedges(1:end-1) + yedges(2:end)) / 2;

% Compute probability heatmaps
H_pre  = histcounts2(x_pre_all, y_pre_all, xedges, yedges);
P_pre  = H_pre / max(1, sum(H_pre(:)));
H_stim = histcounts2(x_stim_all, y_stim_all, xedges, yedges);
P_stim = H_stim / max(1, sum(H_stim(:)));

% Shared color limits
cmax = prctile([P_pre(:); P_stim(:)], 99);
if cmax <= 0, cmax = max([P_pre(:); P_stim(:)]); end
CL = [0, max(eps, cmax)];

% Arena circle coordinates
th = linspace(0, 2*pi, 256);
xc_circle = Centre_mm(1) + Radius_mm * cos(th);
yc_circle = Centre_mm(2) + Radius_mm * sin(th);

% --- Layout: two equal heatmaps with a shared horizontal colorbar below ---
gap = 0.02;
cb_h = 0.02;          % colorbar height
cb_gap = 0.015;       % gap between heatmaps and colorbar
heatmap_h = pos_e(4) - cb_h - cb_gap;  % remaining height for heatmaps
w_half = (pos_e(3) - gap) / 2;

% --- Pre-stimulus heatmap ---
ax_e1 = axes('Position', [pos_e(1), pos_e(2) + cb_h + cb_gap, w_half, heatmap_h]);
hold on;
imagesc(ax_e1, xcent, ycent, P_pre.');
axis(ax_e1, 'image');
set(ax_e1, 'YDir', 'normal');
colormap(ax_e1, flipud(bone));
clim(ax_e1, CL * 0.95);
plot(ax_e1, xc_circle, yc_circle, '-', 'Color', 'k', 'LineWidth', 0.75);
plot(ax_e1, Centre_mm(1), Centre_mm(2), '+', 'Color', [0.8 0 0], ...
    'LineWidth', 2, 'MarkerSize', 14);
title(ax_e1, 'Pre-stimulus', 'FontSize', 14);
axis(ax_e1, 'off');

% --- During-stimulus heatmap ---
ax_e2 = axes('Position', [pos_e(1) + w_half + gap, pos_e(2) + cb_h + cb_gap, w_half, heatmap_h]);
hold on;
imagesc(ax_e2, xcent, ycent, P_stim.');
axis(ax_e2, 'image');
set(ax_e2, 'YDir', 'normal');
colormap(ax_e2, flipud(bone));
clim(ax_e2, CL * 0.95);
plot(ax_e2, xc_circle, yc_circle, '-', 'Color', 'k', 'LineWidth', 0.75);
plot(ax_e2, Centre_mm(1), Centre_mm(2), '+', 'Color', [0.8 0 0], ...
    'LineWidth', 2, 'MarkerSize', 14);
title(ax_e2, 'During stimulus', 'FontSize', 14);
axis(ax_e2, 'off');

% --- Horizontal colorbar below both heatmaps ---
cb = colorbar(ax_e2, 'Location', 'southoutside', 'FontSize', 10);
% Centre the colorbar under both heatmaps
cb_left = pos_e(1) + pos_e(3) * 0.25;
cb_w    = pos_e(3) * 0.5;
cb.Position = [cb_left, pos_e(2), cb_w, cb_h];
cb.Label.String = 'Probability';
cb.Label.FontSize = 12;
% Restore ax_e2 position (colorbar may have shifted it)
set(ax_e2, 'Position', [pos_e(1) + w_half + gap, pos_e(2) + cb_h + cb_gap, w_half, heatmap_h]);

% Panel letter — position relative to first heatmap
text(ax_e1, -0.05, 1.05, 'E', 'Units', 'normalized', 'FontSize', 18, 'FontWeight', 'bold');

%% 9 — Save

save_folder = fullfile(cfg.figures, 'manuscript');
if ~isfolder(save_folder), mkdir(save_folder); end

print(hFig, fullfile(save_folder, 'fig1_centring'), '-dpdf', '-vector', '-bestfit');
fprintf('Saved fig1_centring.pdf to %s\n', save_folder);

n_centring = sum(fly_centring > 0);
fprintf('\n--- Figure 1 Summary ---\n');
fprintf('N flies (QC-filtered): %d\n', n_flies);
fprintf('Centring (mean at stim end): %.1f mm\n', nanmean(fly_centring));
fprintf('Flies that moved inward: %d/%d (%.0f%%)\n', ...
    n_centring, numel(fly_centring), 100 * n_centring / numel(fly_centring));
