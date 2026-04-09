%% TEMP_VIEWDIST_SEGMENTATION - Segment trajectories using view_dist peaks
%
%  Segments fly trajectories by finding peaks in the smoothed view_dist
%  signal and extracting peak-to-peak segments. Each segment represents
%  one "turn cycle" — the trajectory between two moments when the fly
%  is looking furthest ahead.
%
%  For each segment, computes bounding box metrics (area, aspect ratio,
%  tortuosity, duration) and the segment's distance from the arena centre
%  (midpoint of the bounding box). Segments with bbox centre > 110 mm
%  from the arena centre are excluded (too close to the wall).
%
%  Compares stimulus period (condition 1) with a 30s window from the
%  pre-stimulus acclimation period (acclim_off1, dark, no gratings).
%
%  Parameters: 10-frame smoothing, 5 mm minimum peak prominence.
%
%  Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 27).

%% ================================================================
%  SECTION 1: Setup
%  ================================================================

if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

ARENA_CENTER = [528, 520] / 4.1691;
ARENA_R  = 120;
FPS      = 30;
STIM_ON  = 300;
STIM_OFF = 1200;

control_strain = "jfrc100_es_shibire_kir";
sex = 'F';

% Segmentation parameters
SMOOTH_WIN     = 10;   % frames for moving average
MIN_PROMINENCE = 5;    % mm — minimum peak prominence in view_dist
MIN_SEG_FRAMES = 5;    % minimum frames in a segment
MAX_DIST_CENTER = 110; % mm — exclude segments with bbox centre beyond this

ACCLIM_FRAMES = 900;   % 30s at 30fps — window to extract from acclim_off1

%% ================================================================
%  SECTION 2: Segment extraction — stimulus period
%  ================================================================

fprintf('=== View-dist peak segmentation ===\n');
fprintf('  Smoothing: %d frames, Min prominence: %d mm, Max dist: %d mm\n', ...
    SMOOTH_WIN, MIN_PROMINENCE, MAX_DIST_CENTER);

data_types = {'heading_data', 'x_data', 'y_data', 'dist_data', 'vel_data', 'view_dist'};
[rep_data, n_flies] = load_per_rep_data(DATA, control_strain, sex, 1, data_types);
fprintf('  Loaded %d fly-rep observations\n', n_flies);

stim_range = STIM_ON:STIM_OFF;
x_stim   = rep_data.x_data(:, stim_range);
y_stim   = rep_data.y_data(:, stim_range);
vd_stim  = rep_data.view_dist(:, stim_range);

[flat_stim, n_stim, n_excl_stim] = segment_viewdist_peaks( ...
    x_stim, y_stim, vd_stim, ARENA_CENTER, FPS, ...
    SMOOTH_WIN, MIN_PROMINENCE, MIN_SEG_FRAMES, MAX_DIST_CENTER);

fprintf('\n--- Stimulus (condition 1) ---\n');
fprintf('  %d segments from %d flies (%d excluded, dist > %d mm)\n', ...
    n_stim, numel(unique(flat_stim.fly_id)), n_excl_stim, MAX_DIST_CENTER);

%% ================================================================
%  SECTION 3: Segment extraction — acclimation (dark, no gratings)
%  ================================================================
%
%  acclim_off1 is not condition-based, so we iterate over cohorts directly
%  rather than using load_per_rep_data. We apply the same QC thresholds
%  (quiescence and edge-stuck checks) and extract the last ACCLIM_FRAMES
%  frames to get a 30s window comparable to the stimulus period.

fprintf('\n--- Acclimation (acclim_off1, last %d frames = %.0fs) ---\n', ...
    ACCLIM_FRAMES, ACCLIM_FRAMES/FPS);

data_strain = DATA.(control_strain).(sex);
n_exp = length(data_strain);

x_acc_all  = [];
y_acc_all  = [];
vd_acc_all = [];

for exp_idx = 1:n_exp
    acc = data_strain(exp_idx).acclim_off1;
    if isempty(acc), continue; end
    if ~isfield(acc, 'view_dist'), continue; end

    n_flies_acc = size(acc.x_data, 1);
    n_frames_acc = size(acc.x_data, 2);

    if n_frames_acc < ACCLIM_FRAMES
        acc_range = 1:n_frames_acc;
    else
        acc_range = (n_frames_acc - ACCLIM_FRAMES + 1):n_frames_acc;
    end

    vel_acc  = acc.vel_data;
    dist_acc = acc.dist_data;

    for f = 1:n_flies_acc
        % QC: same thresholds as load_per_rep_data
        if sum(vel_acc(f,:) < 0.5) / n_frames_acc > 0.75, continue; end
        if min(dist_acc(f,:)) > 110, continue; end

        x_acc_all  = [x_acc_all;  acc.x_data(f, acc_range)];
        y_acc_all  = [y_acc_all;  acc.y_data(f, acc_range)];
        vd_acc_all = [vd_acc_all; acc.view_dist(f, acc_range)];
    end
end

fprintf('  %d flies passed QC\n', size(x_acc_all, 1));

[flat_acc, n_acc, n_excl_acc] = segment_viewdist_peaks( ...
    x_acc_all, y_acc_all, vd_acc_all, ARENA_CENTER, FPS, ...
    SMOOTH_WIN, MIN_PROMINENCE, MIN_SEG_FRAMES, MAX_DIST_CENTER);

fprintf('  %d segments (%d excluded, dist > %d mm)\n', ...
    n_acc, n_excl_acc, MAX_DIST_CENTER);

%% ================================================================
%  SECTION 4: Print summaries
%  ================================================================

fprintf('\n=== Segmentation Summary ===\n');
fprintf('  %-25s %-15s %-15s\n', '', 'Stimulus', 'Acclimation');
fprintf('  %-25s %-15d %-15d\n', 'Total segments', n_stim, n_acc);

metric_fields = {'area', 'aspect', 'tort', 'dur'};
metric_names_print = {'Area (mm^2)', 'Aspect ratio', 'Tortuosity', 'Duration (s)'};
for mi = 1:4
    s_vals = flat_stim.(metric_fields{mi});
    a_vals = flat_acc.(metric_fields{mi});
    fprintf('  %-25s %-7.1f / %-5.1f  %-7.1f / %-5.1f\n', ...
        [metric_names_print{mi} ' (mean/med)'], ...
        mean(s_vals,'omitnan'), median(s_vals,'omitnan'), ...
        mean(a_vals,'omitnan'), median(a_vals,'omitnan'));
end

%% ================================================================
%  SECTION 5: Metric vs distance from centre (Figure 1)
%  ================================================================
%
%  Binned means with SEM shading for stimulus (black) and acclimation
%  (light grey) overlaid.

n_dist_bins = 10;
bin_edges = linspace(0, MAX_DIST_CENTER, n_dist_bins + 1);
bin_centres = (bin_edges(1:end-1) + bin_edges(2:end)) / 2;

metric_data_stim = {flat_stim.area, flat_stim.aspect, flat_stim.tort, flat_stim.dur};
metric_data_acc  = {flat_acc.area,  flat_acc.aspect,  flat_acc.tort,  flat_acc.dur};
metric_labels = {'Bbox area (mm^2)', 'Aspect ratio', ...
                 'Tortuosity (path/displacement)', 'Duration (s)'};
metric_short  = {'area', 'aspect', 'tortuosity', 'duration'};

col_stim = [0.1 0.1 0.1];
col_acc  = [0.75 0.75 0.75];

% figure('Position', [50 50 1200 900], 'Name', 'View-dist segments: Stim vs Acclim');
% sgtitle(sprintf(['View-dist peak segments — metric vs distance from centre\n' ...
    % 'Black = stimulus (n=%d), Grey = acclimation (n=%d)'], n_stim, n_acc), 'FontSize', 16);

for mi = 1:4
    subplot(2, 2, mi);
    hold on;

    % Bin both datasets
    for di = 1:2
        if di == 1
            m_vals = metric_data_stim{mi};
            d_vals = flat_stim.dist;
            col = col_stim;
            col_fill = [0.2 0.2 0.2];
        else
            m_vals = metric_data_acc{mi};
            d_vals = flat_acc.dist;
            col = col_acc;
            col_fill = [0.8 0.8 0.8];
        end

        bin_mean = NaN(1, n_dist_bins);
        bin_sem  = NaN(1, n_dist_bins);
        for bi = 1:n_dist_bins
            in_b = d_vals >= bin_edges(bi) & d_vals < bin_edges(bi+1) & ~isnan(m_vals);
            if sum(in_b) >= 5
                bin_mean(bi) = mean(m_vals(in_b));
                bin_sem(bi)  = std(m_vals(in_b)) / sqrt(sum(in_b));
            end
        end

        valid_bins = ~isnan(bin_mean);
        if any(valid_bins)
            fill([bin_centres(valid_bins), fliplr(bin_centres(valid_bins))], ...
                [bin_mean(valid_bins) + bin_sem(valid_bins), ...
                 fliplr(bin_mean(valid_bins) - bin_sem(valid_bins))], ...
                col_fill, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
            plot(bin_centres(valid_bins), bin_mean(valid_bins), '-o', ...
                'Color', col, 'LineWidth', 2, 'MarkerFaceColor', col, 'MarkerSize', 5);
        end
    end

    xlabel('Distance from centre (mm)', 'FontSize', 12);
    ylabel(metric_labels{mi}, 'FontSize', 12);
    title(metric_labels{mi}, 'FontSize', 14);
    xlim([0 MAX_DIST_CENTER + 5]);
    if mi == 1
        legend('', 'Stimulus', '', 'Acclimation', 'Location', 'best', 'FontSize', 10);
    end
    set(gca, 'FontSize', 11, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
    f = gcf; f.Position =[50    50   626   538];
end

%% ================================================================
%  RESULTS
%  ================================================================

fprintf('\n======================================================================\n');
fprintf('  VIEW-DIST PEAK SEGMENTATION — RESULTS\n');
fprintf('======================================================================\n');
fprintf('  Parameters: smooth=%d frames, prominence=%d mm, max dist=%d mm\n', ...
    SMOOTH_WIN, MIN_PROMINENCE, MAX_DIST_CENTER);

fprintf('\n--- Binned means: metric vs distance from centre ---\n');

for mi = 1:4
    fprintf('\n  %s:\n', metric_labels{mi});
    fprintf('  %-12s %-12s %-12s\n', 'Bin', 'Stimulus', 'Acclim');
    for bi = 1:n_dist_bins
        in_s = flat_stim.dist >= bin_edges(bi) & flat_stim.dist < bin_edges(bi+1) & ~isnan(metric_data_stim{mi});
        in_a = flat_acc.dist >= bin_edges(bi) & flat_acc.dist < bin_edges(bi+1) & ~isnan(metric_data_acc{mi});
        s_str = '--';  a_str = '--';
        if sum(in_s) >= 5, s_str = sprintf('%.2f', mean(metric_data_stim{mi}(in_s))); end
        if sum(in_a) >= 5, a_str = sprintf('%.2f', mean(metric_data_acc{mi}(in_a))); end
        fprintf('  %-12s %-12s %-12s\n', ...
            sprintf('%.0f-%.0f mm', bin_edges(bi), bin_edges(bi+1)), s_str, a_str);
    end
end

fprintf('\n======================================================================\n');
fprintf('  1 figure generated\n');
fprintf('======================================================================\n');

%% ================================================================
%  LOCAL FUNCTION: segment_viewdist_peaks
%  ================================================================

function [flat, n_segs, n_excluded] = segment_viewdist_peaks( ...
        x_all, y_all, vd_all, arena_center, fps, ...
        smooth_win, min_prom, min_seg_frames, max_dist)
% SEGMENT_VIEWDIST_PEAKS  Extract peak-to-peak segments from view_dist.
%
%   Finds peaks in the smoothed view_dist signal for each fly and extracts
%   the trajectory between consecutive peaks. Returns a flat struct with
%   per-segment metrics.

    flat.fly_id = [];
    flat.area   = [];
    flat.aspect = [];
    flat.tort   = [];
    flat.dist   = [];
    flat.dur    = [];

    n_segs = 0;
    n_excluded = 0;
    n_flies = size(x_all, 1);

    for f = 1:n_flies
        vd = vd_all(f, :);
        x_fly = x_all(f, :);
        y_fly = y_all(f, :);

        % Smooth view_dist
        vd_clean = vd;
        vd_clean(isnan(vd_clean)) = 0;
        vd_smooth = movmean(vd_clean, smooth_win, 'omitnan');
        vd_smooth(isnan(vd)) = NaN;

        % Find peaks
        [~, pk_locs] = findpeaks(vd_smooth, ...
            'MinPeakProminence', min_prom, 'MinPeakDistance', 5);

        if numel(pk_locs) < 2, continue; end

        for k = 1:(numel(pk_locs) - 1)
            sf = pk_locs(k);
            ef = pk_locs(k+1);
            if ef - sf + 1 < min_seg_frames, continue; end

            x_seg = x_fly(sf:ef);
            y_seg = y_fly(sf:ef);
            valid = ~isnan(x_seg) & ~isnan(y_seg);
            x_v = x_seg(valid);  y_v = y_seg(valid);
            if numel(x_v) < min_seg_frames, continue; end

            % Bounding box
            x_min = min(x_v);  x_max = max(x_v);
            y_min = min(y_v);  y_max = max(y_v);
            w = x_max - x_min;
            h = y_max - y_min;
            bbox_area = w * h;
            longest = max(w, h);
            shortest = min(w, h);
            aspect = longest / max(shortest, 0.01);

            % Midpoint distance from centre
            mid_x = (x_min + x_max) / 2;
            mid_y = (y_min + y_max) / 2;
            dist_center = sqrt((mid_x - arena_center(1))^2 + (mid_y - arena_center(2))^2);

            if dist_center > max_dist
                n_excluded = n_excluded + 1;
                continue;
            end

            % Tortuosity
            dx = diff(x_v);  dy = diff(y_v);
            path_len = sum(sqrt(dx.^2 + dy.^2));
            disp_len = sqrt((x_v(end)-x_v(1))^2 + (y_v(end)-y_v(1))^2);
            if disp_len > 0.5
                tort = path_len / disp_len;
            else
                tort = NaN;
            end

            flat.fly_id = [flat.fly_id; f];
            flat.area   = [flat.area; bbox_area];
            flat.aspect = [flat.aspect; aspect];
            flat.tort   = [flat.tort; tort];
            flat.dist   = [flat.dist; dist_center];
            flat.dur    = [flat.dur; (ef - sf) / fps];
            n_segs = n_segs + 1;
        end
    end
end
