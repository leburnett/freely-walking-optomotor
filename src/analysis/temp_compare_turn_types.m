%% TEMP_COMPARE_TURN_TYPES - Compare methods for detecting pinwheel vs loop turns
%
% Tests three detection approaches side-by-side on the same flies:
%   Method 1: "Pinwheel detector"  — high AV threshold, short max duration
%   Method 2: "Loop detector"      — lower AV threshold, sustained turning,
%                                     longer duration allowed
%   Method 3: "Combined"           — single low-threshold pass, then
%                                     classify post-hoc by bbox area + duration
%
% For each method, plots individual event trajectories with bounding boxes
% and annotated metric values (peak AV, mean AV, duration, bbox area,
% aspect ratio) so you can visually judge which method best captures the
% two turn types.
%
% Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 27).

%% Setup

if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

PPM = 4.1691;
ARENA_CENTER = [528, 520] / PPM;
ARENA_R = 120;
FPS = 30;

control_strain = "jfrc100_es_shibire_kir";
key_condition = 1;
sex = 'F';

STIM_ON  = 300;
STIM_MID = 750;

%% Load per-rep data

data_types = {'heading_data', 'x_data', 'y_data', 'dist_data', 'av_data'};
[rep_data, n_flies_rep] = load_per_rep_data(DATA, control_strain, sex, key_condition, data_types);

heading_rep = rep_data.heading_data;
av_rep      = rep_data.av_data;
x_rep       = rep_data.x_data;
y_rep       = rep_data.y_data;

% Use half 1 only
h1_range = STIM_ON:STIM_MID;
heading_h1 = heading_rep(:, h1_range);
av_h1      = av_rep(:, h1_range);
x_h1       = x_rep(:, h1_range);
y_h1       = y_rep(:, h1_range);

fprintf('Loaded %d fly-rep observations (half 1: %d frames)\n', n_flies_rep, numel(h1_range));

%% Define three detection methods

% --- Method 1: Pinwheel detector ---
% High AV threshold catches only fast, tight turns.
% Short max duration excludes anything that takes too long.
method1.name         = 'Pinwheel (high AV, short)';
method1.short_name   = 'Pinwheel';
method1.opts.av_threshold    = 90;   % high — only fast spinning
method1.opts.merge_gap       = 3;    % small gap merge
method1.opts.min_bout_frames = 3;
method1.opts.heading_target  = 360;
method1.opts.max_duration_s  = 2.0;  % pinwheels should be fast
method1.color = [0.894 0.102 0.110]; % red

% --- Method 2: Loop detector ---
% Lower AV threshold to catch sustained moderate turning.
% Longer duration allowed — loops take time.
% Minimum bout duration ensures the turning is sustained, not a brief blip.
method2.name         = 'Loop (moderate AV, sustained)';
method2.short_name   = 'Loop';
method2.opts.av_threshold    = 40;   % lower — catch moderate turning
method2.opts.merge_gap       = 5;    % allow brief wobbles
method2.opts.min_bout_frames = 10;   % must be sustained (~0.3s minimum)
method2.opts.heading_target  = 360;
method2.opts.max_duration_s  = 5.0;  % loops can be slow
method2.color = [0.216 0.494 0.722]; % blue

% --- Method 3: Combined (detect broadly, classify post-hoc) ---
% Very permissive detection — catch everything that turns 360 degrees.
% Then classify each event as pinwheel or loop afterwards.
method3.name         = 'Combined (low AV, classify post-hoc)';
method3.short_name   = 'Combined';
method3.opts.av_threshold    = 30;   % very permissive
method3.opts.merge_gap       = 3;
method3.opts.min_bout_frames = 1;
method3.opts.heading_target  = 360;
method3.opts.max_duration_s  = 6.0;
method3.color = [0.302 0.686 0.290]; % green

% Post-hoc classification thresholds for Method 3
classify.bbox_area_threshold = 800;  % mm² — below = pinwheel, above = loop
classify.duration_threshold  = 1.5;  % seconds — below = pinwheel, above = loop
classify.peak_av_threshold   = 150;  % deg/s — above = likely pinwheel

methods = {method1, method2, method3};
n_methods = numel(methods);

%% Run all three methods on all flies

for mi = 1:n_methods
    m = methods{mi};
    fprintf('\nRunning: %s\n', m.name);

    events = detect_360_turning_events(heading_h1, av_h1, FPS, m.opts);

    % Compute geometry for each fly
    for f = 1:n_flies_rep
        geom(f) = compute_turning_event_geometry(events(f), ...
            x_h1(f,:), y_h1(f,:), ARENA_R, ARENA_CENTER); %#ok<SAGROW>
    end

    methods{mi}.events = events;
    methods{mi}.geom   = geom;

    total_events = sum([events.n_events]);
    flies_with   = sum([events.n_events] > 0);
    fprintf('  %d total events across %d/%d flies\n', total_events, flies_with, n_flies_rep);

    clear geom;
end

%% Select flies for visualisation
% Pick 5 flies evenly spaced by total event count (Method 3 = most permissive)

combined_counts = [methods{3}.events.n_events];
[~, rank_idx] = sort(combined_counts, 'descend');
n_diag = min(5, n_flies_rep);
pick_positions = round(linspace(1, sum(combined_counts > 0), n_diag));
pick_positions = unique(min(pick_positions, numel(rank_idx)));  % safety
diag_flies = rank_idx(pick_positions);

fprintf('\nSelected flies for visualisation (by combined event count):\n');
for di = 1:numel(diag_flies)
    f = diag_flies(di);
    fprintf('  Fly %d: M1=%d, M2=%d, M3=%d events\n', f, ...
        methods{1}.events(f).n_events, ...
        methods{2}.events(f).n_events, ...
        methods{3}.events(f).n_events);
end

%% Figure 1: Method comparison — full trajectories with bounding boxes
% One row per fly, one column per method

n_vis = numel(diag_flies);

fig1 = figure('Position', [20 20 1800 n_vis * 340], 'Name', 'Method Comparison — Trajectories');
tl = tiledlayout(n_vis, n_methods, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl, 'Turn Detection: Method Comparison', 'FontSize', 18);

theta_circ = linspace(0, 2*pi, 200);

for di = 1:n_vis
    f = diag_flies(di);

    for mi = 1:n_methods
        ax = nexttile(tl);
        hold(ax, 'on');

        % Arena circle
        plot(ax, ARENA_CENTER(1) + ARENA_R*cos(theta_circ), ...
             ARENA_CENTER(2) + ARENA_R*sin(theta_circ), '-', ...
             'Color', [0.7 0.7 0.7], 'LineWidth', 1);

        % Full trajectory in light grey
        plot(ax, x_h1(f,:), y_h1(f,:), '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 0.5);

        ev = methods{mi}.events(f);
        gm = methods{mi}.geom(f);
        mc = methods{mi}.color;

        % Plot each event
        if ev.n_events > 0
            cmap_ev = lines(max(ev.n_events, 1));
            for e = 1:ev.n_events
                sf = max(ev.start_frame(e), 1);
                ef = min(ev.end_frame(e), size(x_h1, 2));
                x_seg = x_h1(f, sf:ef);
                y_seg = y_h1(f, sf:ef);

                col = cmap_ev(mod(e-1, size(cmap_ev,1))+1, :);
                plot(ax, x_seg, y_seg, '-', 'Color', col, 'LineWidth', 2);

                % Bounding box
                if ~isnan(gm.bbox_area(e))
                    bx = [min(x_seg), max(x_seg)];
                    by = [min(y_seg), max(y_seg)];
                    w = diff(bx); h = diff(by);
                    if w > 0 && h > 0
                        rectangle(ax, 'Position', [bx(1), by(1), w, h], ...
                            'EdgeColor', col, 'LineWidth', 1, 'LineStyle', '--');
                    end
                end

                % Start marker
                plot(ax, x_seg(1), y_seg(1), 'o', 'MarkerSize', 5, ...
                    'MarkerFaceColor', col, 'MarkerEdgeColor', 'none');
            end
        end

        axis(ax, 'equal');
        xlim(ax, [ARENA_CENTER(1)-ARENA_R-5, ARENA_CENTER(1)+ARENA_R+5]);
        ylim(ax, [ARENA_CENTER(2)-ARENA_R-5, ARENA_CENTER(2)+ARENA_R+5]);
        set(ax, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

        if di == 1
            title(ax, sprintf('%s\n(%d events)', methods{mi}.short_name, ev.n_events), 'FontSize', 14);
        else
            title(ax, sprintf('%d events', ev.n_events), 'FontSize', 12);
        end

        if mi == 1
            ylabel(ax, sprintf('Fly %d', f), 'FontSize', 14, 'FontWeight', 'bold');
        end
    end
end

%% Figure 2: Individual event detail panels (Method 3 — Combined)
% For each visualisation fly, show small multiples of each detected event
% with annotated metrics. This is the key figure for assessing turn types.

for di = 1:n_vis
    f = diag_flies(di);
    ev = methods{3}.events(f);
    gm = methods{3}.geom(f);

    if ev.n_events == 0
        continue;
    end

    n_ev = ev.n_events;
    n_cols = min(n_ev, 6);
    n_rows = ceil(n_ev / n_cols);

    fig_ev = figure('Position', [30 30 n_cols*300 n_rows*350], ...
        'Name', sprintf('Fly %d — Combined Method Events', f));
    tl_ev = tiledlayout(n_rows, n_cols, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl_ev, sprintf('Fly %d — All Detected Events (Combined Method)', f), 'FontSize', 16);

    for e = 1:n_ev
        ax = nexttile(tl_ev);
        hold(ax, 'on');

        sf = max(ev.start_frame(e), 1);
        ef = min(ev.end_frame(e), size(x_h1, 2));
        x_seg = x_h1(f, sf:ef);
        y_seg = y_h1(f, sf:ef);

        % Classify this event
        is_pinwheel = (gm.bbox_area(e) < classify.bbox_area_threshold) & ...
                      (ev.duration_s(e) < classify.duration_threshold);
        is_loop     = (gm.bbox_area(e) >= classify.bbox_area_threshold) | ...
                      (ev.duration_s(e) >= classify.duration_threshold);

        if is_pinwheel
            type_str = 'PINWHEEL';
            edge_col = [0.894 0.102 0.110];  % red
        else
            type_str = 'LOOP';
            edge_col = [0.216 0.494 0.722];  % blue
        end

        % Plot trajectory segment coloured by time
        n_pts = numel(x_seg);
        if n_pts >= 2
            for p = 1:(n_pts-1)
                frac = (p-1) / max(n_pts-2, 1);
                col = edge_col * (0.4 + 0.6*frac);  % light to full colour
                col = min(col, 1);
                plot(ax, x_seg(p:p+1), y_seg(p:p+1), '-', 'Color', col, 'LineWidth', 2);
            end
        end

        % Start/end markers
        plot(ax, x_seg(1), y_seg(1), 'o', 'MarkerSize', 8, ...
            'MarkerFaceColor', [0.2 0.7 0.2], 'MarkerEdgeColor', 'none');
        if n_pts > 1
            plot(ax, x_seg(end), y_seg(end), 's', 'MarkerSize', 8, ...
                'MarkerFaceColor', [0.8 0.2 0.2], 'MarkerEdgeColor', 'none');
        end

        % Bounding box
        if ~isnan(gm.bbox_area(e))
            bx = [min(x_seg), max(x_seg)];
            by = [min(y_seg), max(y_seg)];
            w = diff(bx); h = diff(by);
            if w > 0 && h > 0
                rectangle(ax, 'Position', [bx(1), by(1), w, h], ...
                    'EdgeColor', edge_col, 'LineWidth', 1.5, 'LineStyle', '--');
            end
        end

        axis(ax, 'equal');

        % Pad view around this event
        pad = 10;
        xlim(ax, [min(x_seg)-pad, max(x_seg)+pad]);
        ylim(ax, [min(y_seg)-pad, max(y_seg)+pad]);

        % Annotated title with metric values
        dir_str = 'CW'; if ev.direction(e) > 0, dir_str = 'CCW'; end
        title(ax, sprintf(['%s — %s (#%d)\n' ...
            'pkAV=%.0f  mnAV=%.0f deg/s\n' ...
            'dur=%.2fs  area=%.0fmm^2  AR=%.1f'], ...
            type_str, dir_str, e, ...
            ev.peak_av(e), ev.mean_av(e), ...
            ev.duration_s(e), gm.bbox_area(e), gm.bbox_aspect(e)), ...
            'FontSize', 10, 'Color', edge_col);

        set(ax, 'FontSize', 9, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1);
    end
end

%% Figure 3: Post-hoc classification scatter (Method 3 events)
% Scatter of all events in bbox_area vs duration space,
% coloured by classification. Helps tune the thresholds.

all_bbox   = [];
all_dur    = [];
all_peakav = [];
all_meanav = [];
all_aspect = [];

for f = 1:n_flies_rep
    ev = methods{3}.events(f);
    gm = methods{3}.geom(f);
    if ev.n_events > 0
        all_bbox   = [all_bbox,   gm.bbox_area];    %#ok<AGROW>
        all_dur    = [all_dur,    ev.duration_s];    %#ok<AGROW>
        all_peakav = [all_peakav, ev.peak_av];       %#ok<AGROW>
        all_meanav = [all_meanav, ev.mean_av];       %#ok<AGROW>
        all_aspect = [all_aspect, gm.bbox_aspect];   %#ok<AGROW>
    end
end

n_all = numel(all_bbox);
fprintf('\nTotal combined-method events: %d\n', n_all);

% Classify
is_pw = (all_bbox < classify.bbox_area_threshold) & (all_dur < classify.duration_threshold);
is_lp = ~is_pw;
n_pw = sum(is_pw);
n_lp = sum(is_lp);
fprintf('  Pinwheels: %d (%.0f%%)\n', n_pw, 100*n_pw/max(n_all,1));
fprintf('  Loops:     %d (%.0f%%)\n', n_lp, 100*n_lp/max(n_all,1));

fig3 = figure('Position', [50 50 1600 500], 'Name', 'Event Classification Space');
tl3 = tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
title(tl3, sprintf('Post-hoc Classification (%d events)', n_all), 'FontSize', 18);

% (1) bbox area vs duration
ax1 = nexttile(tl3);
hold(ax1, 'on');
scatter(ax1, all_dur(is_pw), all_bbox(is_pw), 30, [0.894 0.102 0.110], 'filled', 'MarkerFaceAlpha', 0.5);
scatter(ax1, all_dur(is_lp), all_bbox(is_lp), 30, [0.216 0.494 0.722], 'filled', 'MarkerFaceAlpha', 0.5);
xline(ax1, classify.duration_threshold, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
yline(ax1, classify.bbox_area_threshold, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xlabel(ax1, 'Duration (s)', 'FontSize', 14);
ylabel(ax1, 'Bounding box area (mm^2)', 'FontSize', 14);
title(ax1, 'Area vs Duration', 'FontSize', 16);
legend(ax1, sprintf('Pinwheel (n=%d)', n_pw), sprintf('Loop (n=%d)', n_lp), 'Location', 'best');
set(ax1, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% (2) peak AV vs duration
ax2 = nexttile(tl3);
hold(ax2, 'on');
scatter(ax2, all_dur(is_pw), all_peakav(is_pw), 30, [0.894 0.102 0.110], 'filled', 'MarkerFaceAlpha', 0.5);
scatter(ax2, all_dur(is_lp), all_peakav(is_lp), 30, [0.216 0.494 0.722], 'filled', 'MarkerFaceAlpha', 0.5);
xline(ax2, classify.duration_threshold, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xlabel(ax2, 'Duration (s)', 'FontSize', 14);
ylabel(ax2, 'Peak |AV| (deg/s)', 'FontSize', 14);
title(ax2, 'Peak AV vs Duration', 'FontSize', 16);
set(ax2, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% (3) bbox area vs peak AV
ax3 = nexttile(tl3);
hold(ax3, 'on');
scatter(ax3, all_peakav(is_pw), all_bbox(is_pw), 30, [0.894 0.102 0.110], 'filled', 'MarkerFaceAlpha', 0.5);
scatter(ax3, all_peakav(is_lp), all_bbox(is_lp), 30, [0.216 0.494 0.722], 'filled', 'MarkerFaceAlpha', 0.5);
yline(ax3, classify.bbox_area_threshold, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xlabel(ax3, 'Peak |AV| (deg/s)', 'FontSize', 14);
ylabel(ax3, 'Bounding box area (mm^2)', 'FontSize', 14);
title(ax3, 'Area vs Peak AV', 'FontSize', 16);
set(ax3, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

%% Figure 4: Method 1 vs Method 2 overlap analysis
% For each fly, what does Method 1 catch that Method 2 misses and vice versa?
% Shows which events are unique to each method.

fprintf('\n=== Method Overlap Analysis ===\n');
m1_only_count = 0;
m2_only_count = 0;
both_count    = 0;

for f = 1:n_flies_rep
    ev1 = methods{1}.events(f);
    ev2 = methods{2}.events(f);

    if ev1.n_events == 0 && ev2.n_events == 0, continue; end

    % Check overlap by frame range intersection
    for e1 = 1:ev1.n_events
        range1 = ev1.start_frame(e1):ev1.end_frame(e1);
        found_overlap = false;
        for e2 = 1:ev2.n_events
            range2 = ev2.start_frame(e2):ev2.end_frame(e2);
            if numel(intersect(range1, range2)) > 0.3 * numel(range1)
                found_overlap = true;
                break;
            end
        end
        if found_overlap
            both_count = both_count + 1;
        else
            m1_only_count = m1_only_count + 1;
        end
    end

    for e2 = 1:ev2.n_events
        range2 = ev2.start_frame(e2):ev2.end_frame(e2);
        found_overlap = false;
        for e1 = 1:ev1.n_events
            range1 = ev1.start_frame(e1):ev1.end_frame(e1);
            if numel(intersect(range2, range1)) > 0.3 * numel(range2)
                found_overlap = true;
                break;
            end
        end
        if ~found_overlap
            m2_only_count = m2_only_count + 1;
        end
    end
end

fprintf('  Pinwheel-only events: %d\n', m1_only_count);
fprintf('  Loop-only events:     %d\n', m2_only_count);
fprintf('  Detected by both:     %d\n', both_count);

%% Figure 5: Side-by-side comparison for a single fly
% Shows trajectory twice — once with Method 1 events, once with Method 2,
% and a third panel with Method 3 classified events.
% Includes AV timeseries below each.

for di = 1:min(3, n_vis)
    f = diag_flies(di);

    fig5 = figure('Position', [30 30 1800 700], ...
        'Name', sprintf('Fly %d — Detailed Method Comparison', f));
    tl5 = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl5, sprintf('Fly %d — Turn Type Comparison', f), 'FontSize', 18);

    t_s = (1:numel(h1_range)) / FPS;

    for mi = 1:n_methods
        ev = methods{mi}.events(f);
        gm = methods{mi}.geom(f);

        % --- Top row: trajectory ---
        ax_traj = nexttile(tl5, mi);
        hold(ax_traj, 'on');

        % Arena
        plot(ax_traj, ARENA_CENTER(1) + ARENA_R*cos(theta_circ), ...
             ARENA_CENTER(2) + ARENA_R*sin(theta_circ), '-', ...
             'Color', [0.7 0.7 0.7], 'LineWidth', 1);

        % Full trajectory
        plot(ax_traj, x_h1(f,:), y_h1(f,:), '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 0.5);

        % Events with classification colours for Method 3
        if ev.n_events > 0
            for e = 1:ev.n_events
                sf = max(ev.start_frame(e), 1);
                ef = min(ev.end_frame(e), size(x_h1, 2));
                x_seg = x_h1(f, sf:ef);
                y_seg = y_h1(f, sf:ef);

                if mi == 3
                    % Classify
                    if gm.bbox_area(e) < classify.bbox_area_threshold && ...
                       ev.duration_s(e) < classify.duration_threshold
                        col = [0.894 0.102 0.110]; % red = pinwheel
                    else
                        col = [0.216 0.494 0.722]; % blue = loop
                    end
                else
                    col = methods{mi}.color;
                end

                plot(ax_traj, x_seg, y_seg, '-', 'Color', col, 'LineWidth', 2);

                % Bounding box
                if ~isnan(gm.bbox_area(e))
                    bx_range = [min(x_seg), max(x_seg)];
                    by_range = [min(y_seg), max(y_seg)];
                    w = diff(bx_range); h = diff(by_range);
                    if w > 0 && h > 0
                        rectangle(ax_traj, 'Position', [bx_range(1), by_range(1), w, h], ...
                            'EdgeColor', col, 'LineWidth', 1, 'LineStyle', '--');
                    end
                end
            end
        end

        axis(ax_traj, 'equal');
        xlim(ax_traj, [ARENA_CENTER(1)-ARENA_R-5, ARENA_CENTER(1)+ARENA_R+5]);
        ylim(ax_traj, [ARENA_CENTER(2)-ARENA_R-5, ARENA_CENTER(2)+ARENA_R+5]);
        title(ax_traj, sprintf('%s (%d events)', methods{mi}.short_name, ev.n_events), 'FontSize', 14);
        set(ax_traj, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

        % --- Bottom row: AV timeseries with event shading ---
        ax_av = nexttile(tl5, mi + 3);
        hold(ax_av, 'on');

        % Raw AV
        plot(ax_av, t_s, abs(av_h1(f,:)), '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 0.5);

        % Smoothed AV
        av_smooth = movmean(abs(av_h1(f,:)), round(0.5*FPS), 'omitnan');
        plot(ax_av, t_s, av_smooth, '-k', 'LineWidth', 1);

        % AV threshold line
        yline(ax_av, methods{mi}.opts.av_threshold, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

        % Shade event periods
        if ev.n_events > 0
            yl = get(ax_av, 'YLim');
            for e = 1:ev.n_events
                sf = ev.start_frame(e);
                ef = ev.end_frame(e);
                t_start = sf / FPS;
                t_end   = ef / FPS;

                if mi == 3
                    if gm.bbox_area(e) < classify.bbox_area_threshold && ...
                       ev.duration_s(e) < classify.duration_threshold
                        col = [0.894 0.102 0.110];
                    else
                        col = [0.216 0.494 0.722];
                    end
                else
                    col = methods{mi}.color;
                end

                fill(ax_av, [t_start t_end t_end t_start], ...
                    [yl(1) yl(1) yl(2) yl(2)], col, ...
                    'FaceAlpha', 0.15, 'EdgeColor', 'none');
            end
        end

        xlabel(ax_av, 'Time (s)', 'FontSize', 12);
        ylabel(ax_av, '|AV| (deg/s)', 'FontSize', 12);
        title(ax_av, sprintf('AV threshold = %d deg/s', methods{mi}.opts.av_threshold), 'FontSize', 12);
        set(ax_av, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
    end
end

%% Print summary comparison

fprintf('\n');
fprintf('=====================================================\n');
fprintf('  METHOD COMPARISON SUMMARY\n');
fprintf('=====================================================\n');
fprintf('%-28s  %8s %8s %8s\n', '', 'Pinwheel', 'Loop', 'Combined');
fprintf('%-28s  %8s %8s %8s\n', '', '--------', '----', '--------');

total_events = zeros(1, 3);
for mi = 1:3
    total_events(mi) = sum([methods{mi}.events.n_events]);
end
fprintf('%-28s  %8d %8d %8d\n', 'Total events', total_events(1), total_events(2), total_events(3));

flies_with = zeros(1, 3);
for mi = 1:3
    flies_with(mi) = sum([methods{mi}.events.n_events] > 0);
end
fprintf('%-28s  %8d %8d %8d\n', 'Flies with events', flies_with(1), flies_with(2), flies_with(3));
fprintf('%-28s  %7.1f%% %7.1f%% %7.1f%%\n', '% flies with events', ...
    100*flies_with(1)/n_flies_rep, 100*flies_with(2)/n_flies_rep, 100*flies_with(3)/n_flies_rep);

mean_events = zeros(1, 3);
for mi = 1:3
    mean_events(mi) = mean([methods{mi}.events.n_events]);
end
fprintf('%-28s  %8.1f %8.1f %8.1f\n', 'Mean events/fly', mean_events(1), mean_events(2), mean_events(3));

% Median geometry for each method
for mi = 1:3
    all_ba = []; all_as = []; all_du = [];
    for f = 1:n_flies_rep
        ev = methods{mi}.events(f);
        gm = methods{mi}.geom(f);
        if ev.n_events > 0
            all_ba = [all_ba, gm.bbox_area];      %#ok<AGROW>
            all_as = [all_as, gm.bbox_aspect];     %#ok<AGROW>
            all_du = [all_du, ev.duration_s];      %#ok<AGROW>
        end
    end
    if mi == 1
        fprintf('%-28s  %7.0f %7s %7s\n', 'Median bbox area (mm²)', nanmedian(all_ba), '', '');
        fprintf('%-28s  %8.2f %8s %8s\n', 'Median aspect ratio', nanmedian(all_as), '', '');
        fprintf('%-28s  %8.2f %8s %8s\n', 'Median duration (s)', nanmedian(all_du), '', '');
        ba1 = all_ba; as1 = all_as; du1 = all_du;
    elseif mi == 2
        fprintf('%-28s  %7s %8.0f %8s\n', '', '', nanmedian(all_ba), '');
        fprintf('%-28s  %7s %8.2f %8s\n', '', '', nanmedian(all_as), '');
        fprintf('%-28s  %7s %8.2f %8s\n', '', '', nanmedian(all_du), '');
        ba2 = all_ba; as2 = all_as; du2 = all_du;
    else
        fprintf('%-28s  %7s %8s %8.0f\n', '', '', '', nanmedian(all_ba));
        fprintf('%-28s  %7s %8s %8.2f\n', '', '', '', nanmedian(all_as));
        fprintf('%-28s  %7s %8s %8.2f\n', '', '', '', nanmedian(all_du));
    end
end

fprintf('=====================================================\n');
fprintf('\nClassification thresholds (Method 3 post-hoc):\n');
fprintf('  bbox_area < %d mm² AND duration < %.1fs => PINWHEEL\n', ...
    classify.bbox_area_threshold, classify.duration_threshold);
fprintf('  otherwise => LOOP\n');
fprintf('  Pinwheels: %d  |  Loops: %d\n', n_pw, n_lp);
fprintf('=====================================================\n');
