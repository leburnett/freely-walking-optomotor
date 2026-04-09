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
%  Plots metric vs distance from centre with binned means and SEM shading.
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

%% ================================================================
%  SECTION 2: Segment extraction
%  ================================================================

fprintf('=== View-dist peak segmentation ===\n');
fprintf('  Smoothing: %d frames, Min prominence: %d mm, Max dist: %d mm\n', ...
    SMOOTH_WIN, MIN_PROMINENCE, MAX_DIST_CENTER);

data_types = {'heading_data', 'x_data', 'y_data', 'dist_data', 'vel_data', 'view_dist'};
[rep_data, n_flies] = load_per_rep_data(DATA, control_strain, sex, 1, data_types);
fprintf('  Loaded %d fly-rep observations\n', n_flies);

stim_range = STIM_ON:STIM_OFF;
x_all    = rep_data.x_data(:, stim_range);
y_all    = rep_data.y_data(:, stim_range);
vd_all   = rep_data.view_dist(:, stim_range);

% Accumulators
flat_fly_id   = [];
flat_area     = [];   % bounding box area (mm^2)
flat_aspect   = [];   % aspect ratio (longest / shortest edge)
flat_tort     = [];   % tortuosity (path length / displacement)
flat_dist     = [];   % distance of bbox midpoint from arena centre (mm)
flat_dur      = [];   % duration (seconds)

n_total_segs = 0;
n_excluded   = 0;

for f = 1:n_flies
    vd = vd_all(f, :);
    x_fly = x_all(f, :);
    y_fly = y_all(f, :);

    % Smooth the view_dist signal
    vd_clean = vd;
    vd_clean(isnan(vd_clean)) = 0;
    vd_smooth = movmean(vd_clean, SMOOTH_WIN, 'omitnan');
    vd_smooth(isnan(vd)) = NaN;

    % Find peaks
    [~, pk_locs] = findpeaks(vd_smooth, ...
        'MinPeakProminence', MIN_PROMINENCE, ...
        'MinPeakDistance', 5);

    if numel(pk_locs) < 2, continue; end

    % Extract peak-to-peak segments
    for k = 1:(numel(pk_locs) - 1)
        sf = pk_locs(k);
        ef = pk_locs(k+1);

        if ef - sf + 1 < MIN_SEG_FRAMES, continue; end

        x_seg = x_fly(sf:ef);
        y_seg = y_fly(sf:ef);
        valid = ~isnan(x_seg) & ~isnan(y_seg);
        x_v = x_seg(valid);
        y_v = y_seg(valid);

        if numel(x_v) < MIN_SEG_FRAMES, continue; end

        % --- Bounding box metrics ---
        x_min = min(x_v);  x_max = max(x_v);
        y_min = min(y_v);  y_max = max(y_v);
        w = x_max - x_min;
        h = y_max - y_min;

        bbox_area = w * h;
        longest_edge = max(w, h);
        shortest_edge = min(w, h);
        aspect = longest_edge / max(shortest_edge, 0.01);

        % Bounding box midpoint -> distance from arena centre
        mid_x = (x_min + x_max) / 2;
        mid_y = (y_min + y_max) / 2;
        dist_center = sqrt((mid_x - ARENA_CENTER(1))^2 + (mid_y - ARENA_CENTER(2))^2);

        % Exclude segments too close to the wall
        if dist_center > MAX_DIST_CENTER
            n_excluded = n_excluded + 1;
            continue;
        end

        % --- Tortuosity ---
        dx = diff(x_v);
        dy = diff(y_v);
        path_length = sum(sqrt(dx.^2 + dy.^2));
        displacement = sqrt((x_v(end) - x_v(1))^2 + (y_v(end) - y_v(1))^2);

        if displacement > 0.5
            tortuosity = path_length / displacement;
        else
            tortuosity = NaN;
        end

        % Duration
        dur_s = (ef - sf) / FPS;

        % Store
        flat_fly_id   = [flat_fly_id; f];
        flat_area     = [flat_area; bbox_area];
        flat_aspect   = [flat_aspect; aspect];
        flat_tort     = [flat_tort; tortuosity];
        flat_dist     = [flat_dist; dist_center];
        flat_dur      = [flat_dur; dur_s];
        n_total_segs  = n_total_segs + 1;
    end
end

n_flies_with = numel(unique(flat_fly_id));
fprintf('\n=== Segmentation Summary ===\n');
fprintf('  Total segments: %d from %d flies (%d excluded, dist > %d mm)\n', ...
    n_total_segs, n_flies_with, n_excluded, MAX_DIST_CENTER);
fprintf('  Area:       %.0f mean, %.0f median mm^2\n', mean(flat_area,'omitnan'), median(flat_area,'omitnan'));
fprintf('  Aspect:     %.2f mean, %.2f median\n', mean(flat_aspect,'omitnan'), median(flat_aspect,'omitnan'));
fprintf('  Tortuosity: %.2f mean, %.2f median\n', mean(flat_tort,'omitnan'), median(flat_tort,'omitnan'));
fprintf('  Duration:   %.2f mean, %.2f median s\n', mean(flat_dur,'omitnan'), median(flat_dur,'omitnan'));
fprintf('  Dist centre: %.1f mean, %.1f median mm\n', mean(flat_dist,'omitnan'), median(flat_dist,'omitnan'));

%% ================================================================
%  SECTION 3: Metric vs distance from centre (Figure 1)
%  ================================================================
%
%  Binned means with SEM shading for each metric vs the bounding box
%  midpoint distance from the arena centre.

n_dist_bins = 10;
bin_edges = linspace(0, MAX_DIST_CENTER, n_dist_bins + 1);
bin_centres = (bin_edges(1:end-1) + bin_edges(2:end)) / 2;

metric_data   = {flat_area, flat_aspect, flat_tort, flat_dur};
metric_labels = {'Bbox area (mm^2)', 'Aspect ratio', ...
                 'Tortuosity (path/displacement)', 'Duration (s)'};
metric_short  = {'area', 'aspect', 'tortuosity', 'duration'};

figure('Position', [50 50 1200 900], 'Name', 'View-dist segments: Metrics vs Distance');
sgtitle(sprintf('View-dist peak segments — metric vs distance from centre\n(smooth=%d fr, prom=%d mm, n=%d segments)', ...
    SMOOTH_WIN, MIN_PROMINENCE, n_total_segs), 'FontSize', 16);

for mi = 1:4
    subplot(2, 2, mi);
    hold on;

    m_vals = metric_data{mi};

    % Binned means
    bin_mean = NaN(1, n_dist_bins);
    bin_sem  = NaN(1, n_dist_bins);
    bin_n    = zeros(1, n_dist_bins);
    for bi = 1:n_dist_bins
        in_b = flat_dist >= bin_edges(bi) & flat_dist < bin_edges(bi+1) & ~isnan(m_vals);
        bin_n(bi) = sum(in_b);
        if bin_n(bi) >= 5
            bin_mean(bi) = mean(m_vals(in_b));
            bin_sem(bi)  = std(m_vals(in_b)) / sqrt(bin_n(bi));
        end
    end

    % SEM shading
    valid_bins = ~isnan(bin_mean);
    fill([bin_centres(valid_bins), fliplr(bin_centres(valid_bins))], ...
        [bin_mean(valid_bins) + bin_sem(valid_bins), ...
         fliplr(bin_mean(valid_bins) - bin_sem(valid_bins))], ...
        [0.216 0.494 0.722], 'FaceAlpha', 0.2, 'EdgeColor', 'none');

    % Mean line with markers
    plot(bin_centres(valid_bins), bin_mean(valid_bins), '-ok', 'LineWidth', 2, ...
        'MarkerFaceColor', 'k', 'MarkerSize', 6);

    xlabel('Distance from centre (mm)', 'FontSize', 12);
    ylabel(metric_labels{mi}, 'FontSize', 12);
    title(metric_labels{mi}, 'FontSize', 14);
    xlim([0 MAX_DIST_CENTER + 5]);
    set(gca, 'FontSize', 11, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
end

%% ================================================================
%  RESULTS
%  ================================================================

fprintf('\n======================================================================\n');
fprintf('  VIEW-DIST PEAK SEGMENTATION — RESULTS\n');
fprintf('======================================================================\n');
fprintf('  Parameters: smooth=%d frames, prominence=%d mm, max dist=%d mm\n', ...
    SMOOTH_WIN, MIN_PROMINENCE, MAX_DIST_CENTER);
fprintf('  Total segments: %d from %d/%d flies (%d excluded)\n', ...
    n_total_segs, n_flies_with, n_flies, n_excluded);
fprintf('  Segments per fly: %.1f mean, %.0f median\n', ...
    n_total_segs/n_flies_with, median(accumarray(flat_fly_id, 1)));
fprintf('\n  %-20s %-10s %-10s %-10s\n', 'Metric', 'Mean', 'Median', 'SD');
for mi = 1:4
    d = metric_data{mi};
    d = d(~isnan(d));
    fprintf('  %-20s %-10.2f %-10.2f %-10.2f\n', metric_short{mi}, mean(d), median(d), std(d));
end

fprintf('\n--- Binned means: metric vs distance from centre ---\n');
fprintf('  %-12s', 'Bin');
for mi = 1:4
    fprintf(' %-12s', metric_short{mi});
end
fprintf('\n');
for bi = 1:n_dist_bins
    fprintf('  %-12s', sprintf('%.0f-%.0f mm', bin_edges(bi), bin_edges(bi+1)));
    for mi = 1:4
        in_b = flat_dist >= bin_edges(bi) & flat_dist < bin_edges(bi+1) & ~isnan(metric_data{mi});
        if sum(in_b) >= 5
            fprintf(' %-12.2f', mean(metric_data{mi}(in_b)));
        else
            fprintf(' %-12s', '--');
        end
    end
    fprintf('\n');
end

fprintf('\n======================================================================\n');
fprintf('  1 figure generated\n');
fprintf('======================================================================\n');
