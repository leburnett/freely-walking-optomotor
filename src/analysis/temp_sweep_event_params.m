%% TEMP_SWEEP_EVENT_PARAMS - Sweep turning event detection parameters
%
% Runs detect_360_turning_events with different combinations of event_opts
% and plots trajectories with bounding boxes for visual comparison.
% Uses the same data as analyse_turning_behaviour Section 6.
%
% Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 27).

%% Setup — reuse constants from main script

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
STIM_OFF = 1200;

%% Load per-rep data

data_types = {'heading_data', 'x_data', 'y_data', 'dist_data', 'av_data'};
[rep_data, n_flies_rep] = load_per_rep_data(DATA, control_strain, sex, key_condition, data_types);

heading_rep = rep_data.heading_data;
av_rep      = rep_data.av_data;
x_rep       = rep_data.x_data;
y_rep       = rep_data.y_data;

% Use half 1 only (simpler — single stimulus direction)
h1_range = STIM_ON:STIM_MID;

%% Define parameter grid to sweep
%
% Each row is one parameter set. Vary one parameter at a time from a
% "baseline" so you can see the effect of each in isolation.

baseline.av_threshold    = 50;
baseline.merge_gap       = 10;
baseline.min_bout_frames = 5;
baseline.heading_target  = 360;
baseline.max_duration_s  = 5;

% Build sweep: struct array where each entry has a label + opts
sweep = struct('label', {}, 'opts', {});

% --- Vary av_threshold ---
for av_thr = [30, 50, 75, 100, 150]
    s = baseline;
    s.av_threshold = av_thr;
    sweep(end+1).label = sprintf('AV=%d', av_thr);
    sweep(end).opts = s;
end

% --- Vary max_duration_s ---
for max_dur = [2, 3, 5, 8]
    s = baseline;
    s.max_duration_s = max_dur;
    sweep(end+1).label = sprintf('maxDur=%.0fs', max_dur);
    sweep(end).opts = s;
end

% --- Vary merge_gap ---
for mg = [0, 5, 10, 20]
    s = baseline;
    s.merge_gap = mg;
    sweep(end+1).label = sprintf('mergeGap=%d', mg);
    sweep(end).opts = s;
end

% --- Vary min_bout_frames ---
for mbf = [1, 3, 5, 10]
    s = baseline;
    s.min_bout_frames = mbf;
    sweep(end+1).label = sprintf('minBout=%d', mbf);
    sweep(end).opts = s;
end

n_configs = numel(sweep);
fprintf('Sweeping %d parameter configurations across %d flies (half 1)\n', ...
    n_configs, n_flies_rep);

%% Pick a few example flies to plot (flies with most events at baseline)

baseline_events = detect_360_turning_events( ...
    heading_rep(:, h1_range), av_rep(:, h1_range), FPS, baseline);
n_events_baseline = [baseline_events.n_events];
[~, fly_rank] = sort(n_events_baseline, 'descend');
n_example_flies = min(5, n_flies_rep);
example_idx = round(linspace(1, numel(fly_rank), n_example_flies));
example_flies = fly_rank(example_idx);

fprintf('Example flies (by baseline event count): ');
fprintf('%d (%d events)  ', [example_flies; n_events_baseline(example_flies)]);
fprintf('\n');

%% Run sweep and plot

for fi = 1:n_example_flies
    f = example_flies(fi);
    x_f = x_rep(f, h1_range);
    y_f = y_rep(f, h1_range);

    % Figure: one subplot per parameter config
    n_cols = 5;
    n_rows = ceil(n_configs / n_cols);
    fig = figure('Position', [20 20 350*n_cols 300*n_rows]);
    tl = tiledlayout(n_rows, n_cols, 'TileSpacing', 'compact', 'Padding', 'compact');
    sgtitle(tl, sprintf('Fly %d — Parameter Sweep (Half 1)', f), 'FontSize', 18);

    for ci = 1:n_configs
        ax = nexttile(tl);
        hold(ax, 'on');

        % Arena circle
        theta = linspace(0, 2*pi, 200);
        plot(ax, ARENA_CENTER(1) + ARENA_R*cos(theta), ...
             ARENA_CENTER(2) + ARENA_R*sin(theta), ...
             '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

        % Full trajectory in light grey
        plot(ax, x_f, y_f, '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 0.5);

        % Detect events with this parameter set
        ev = detect_360_turning_events( ...
            heading_rep(f, h1_range), av_rep(f, h1_range), FPS, sweep(ci).opts);

        % Compute geometry for bounding boxes
        geom = compute_turning_event_geometry(ev, x_f, y_f, ARENA_R, ARENA_CENTER);

        % Plot each event trajectory segment + bounding box
        if ev.n_events > 0
            cmap_ev = lines(min(ev.n_events, 12));
            for e = 1:ev.n_events
                sf = max(ev.start_frame(e), 1);
                ef = min(ev.end_frame(e), numel(x_f));
                col = cmap_ev(mod(e-1, 12)+1, :);

                % Trajectory segment
                plot(ax, x_f(sf:ef), y_f(sf:ef), '-', 'Color', col, 'LineWidth', 1.5);

                % Bounding box
                x_seg = x_f(sf:ef);
                y_seg = y_f(sf:ef);
                bx = [min(x_seg), max(x_seg)];
                by = [min(y_seg), max(y_seg)];
                w = diff(bx); h = diff(by);
                if w > 0 && h > 0
                    rectangle(ax, 'Position', [bx(1), by(1), w, h], ...
                        'EdgeColor', col, 'LineWidth', 1, 'LineStyle', '--');
                end
            end
        end

        % Formatting
        title(ax, sprintf('%s  (%d)', sweep(ci).label, ev.n_events), 'FontSize', 11);
        axis(ax, 'equal');
        set(ax, 'FontSize', 9, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1);
        % Centre view on arena
        xlim(ax, ARENA_CENTER(1) + [-1.1 1.1]*ARENA_R);
        ylim(ax, ARENA_CENTER(2) + [-1.1 1.1]*ARENA_R);
    end

    fprintf('Plotted fly %d\n', f);
end

%% Summary table: event counts per configuration

fprintf('\n%-20s', 'Config');
for fi = 1:n_example_flies
    fprintf('  Fly%-4d', example_flies(fi));
end
fprintf('  Mean  Median\n');
fprintf('%s\n', repmat('-', 1, 20 + 9*n_example_flies + 14));

for ci = 1:n_configs
    ev_all = detect_360_turning_events( ...
        heading_rep(:, h1_range), av_rep(:, h1_range), FPS, sweep(ci).opts);
    counts = [ev_all.n_events];

    fprintf('%-20s', sweep(ci).label);
    for fi = 1:n_example_flies
        fprintf('  %5d  ', counts(example_flies(fi)));
    end
    fprintf('  %4.1f  %4.0f\n', mean(counts), median(counts));
end

fprintf('\nDone. Check the figures to see how parameter choices affect event detection.\n');

%% Optimisation: full grid search using silenced strains as negative control
%
% The key insight: T4/T5 and L1/L4 silenced flies should NOT be performing
% optomotor turning loops. So a good parameter set should:
%   - MAXIMISE events detected in control (jfrc100_es_shibire_kir) flies
%   - MINIMISE events detected in silenced (T4/T5, L1/L4) flies
%   - Produce compact, circular bounding boxes (genuine loops, not meanders)
%
% We score using a discriminability metric (like d-prime) between the
% control and silenced event rates, combined with geometry quality.

fprintf('\n========================================\n');
fprintf('=== Grid search with negative controls ===\n');
fprintf('========================================\n');

% --- Load silenced strain data ---
silenced_strains = {"ss324_t4t5_shibire_kir", "l1l4_jfrc100_shibire_kir"};
silenced_labels  = {"T4/T5", "L1/L4"};

fprintf('Loading negative control strains...\n');
sil_heading_h1 = {};
sil_av_h1      = {};
sil_x_h1       = {};
sil_y_h1       = {};
sil_n_flies    = zeros(1, numel(silenced_strains));

for si = 1:numel(silenced_strains)
    data_types_sil = {'heading_data', 'x_data', 'y_data', 'dist_data', 'av_data'};
    [sil_data, sil_n] = load_per_rep_data(DATA, silenced_strains{si}, sex, key_condition, data_types_sil);
    sil_n_flies(si) = sil_n;

    if sil_n > 0
        sil_heading_h1{si} = sil_data.heading_data(:, h1_range);
        sil_av_h1{si}      = sil_data.av_data(:, h1_range);
        sil_x_h1{si}       = sil_data.x_data(:, h1_range);
        sil_y_h1{si}       = sil_data.y_data(:, h1_range);
    else
        sil_heading_h1{si} = [];
        sil_av_h1{si}      = [];
        sil_x_h1{si}       = [];
        sil_y_h1{si}       = [];
    end
    fprintf('  %s: %d fly-reps\n', silenced_labels{si}, sil_n);
end

% Pool all silenced flies together
sil_heading_all = vertcat(sil_heading_h1{:});
sil_av_all      = vertcat(sil_av_h1{:});
sil_x_all       = vertcat(sil_x_h1{:});
sil_y_all       = vertcat(sil_y_h1{:});
n_sil_total     = size(sil_heading_all, 1);
fprintf('  Total silenced flies: %d\n', n_sil_total);

% Pre-extract control half-1 data
heading_h1 = heading_rep(:, h1_range);
av_h1      = av_rep(:, h1_range);
x_h1       = x_rep(:, h1_range);
y_h1       = y_rep(:, h1_range);

% Parameter values to search
av_thresholds    = [30, 40, 50, 60, 75, 90, 100, 125, 150];
max_durations    = [2, 3, 4, 5, 6, 8];
merge_gaps       = [0, 3, 5, 10, 15, 20];
min_bout_vals    = [1, 3, 5, 8, 10];

n_combos = numel(av_thresholds) * numel(max_durations) * ...
           numel(merge_gaps) * numel(min_bout_vals);
fprintf('Testing %d parameter combinations across %d control + %d silenced flies...\n', ...
    n_combos, n_flies_rep, n_sil_total);

% Storage
grid_results = struct( ...
    'av_thr', [], 'max_dur', [], 'merge_g', [], 'min_bout', [], ...
    'score', [], ...
    'ctrl_mean_events', [], 'ctrl_frac_with', [], ...
    'sil_mean_events', [], 'sil_frac_with', [], ...
    'ctrl_median_bbox', [], 'ctrl_median_aspect', [], 'ctrl_median_dur', [], ...
    'dprime', [], 'rate_ratio', []);

combo_idx = 0;
tic;

for ai = 1:numel(av_thresholds)
    for di = 1:numel(max_durations)
        for mi = 1:numel(merge_gaps)
            for bi = 1:numel(min_bout_vals)
                combo_idx = combo_idx + 1;

                test_opts.av_threshold    = av_thresholds(ai);
                test_opts.max_duration_s  = max_durations(di);
                test_opts.merge_gap       = merge_gaps(mi);
                test_opts.min_bout_frames = min_bout_vals(bi);
                test_opts.heading_target  = 360;

                % --- Control flies ---
                ev_ctrl = detect_360_turning_events(heading_h1, av_h1, FPS, test_opts);
                ctrl_counts = [ev_ctrl.n_events];
                ctrl_mean   = mean(ctrl_counts);
                ctrl_frac   = mean(ctrl_counts > 0);

                % Control geometry
                ctrl_bbox_areas = [];
                ctrl_aspects    = [];
                ctrl_durations  = [];
                for f = 1:n_flies_rep
                    if ev_ctrl(f).n_events > 0
                        g = compute_turning_event_geometry( ...
                            ev_ctrl(f), x_h1(f,:), y_h1(f,:), ARENA_R, ARENA_CENTER);
                        ctrl_bbox_areas = [ctrl_bbox_areas, g.bbox_area];      %#ok<AGROW>
                        ctrl_aspects    = [ctrl_aspects, g.bbox_aspect];        %#ok<AGROW>
                        ctrl_durations  = [ctrl_durations, ev_ctrl(f).duration_s]; %#ok<AGROW>
                    end
                end

                % --- Silenced flies ---
                if n_sil_total > 0
                    ev_sil = detect_360_turning_events(sil_heading_all, sil_av_all, FPS, test_opts);
                    sil_counts = [ev_sil.n_events];
                    sil_mean   = mean(sil_counts);
                    sil_frac   = mean(sil_counts > 0);
                else
                    sil_counts = 0;
                    sil_mean = 0;
                    sil_frac = 0;
                end

                % --- Scoring ---
                % The silenced flies CAN still turn — they just lack the
                % stimulus-driven optomotor response, so we expect fewer
                % events, not zero. We want parameters that maximise the
                % *ratio* of control-to-silenced event rates (good
                % separation) while still detecting events in controls
                % and producing geometrically sensible loops.
                %
                % 1. d-prime: separation of distributions, not suppression
                ctrl_std = max(std(ctrl_counts), 0.5);
                sil_std  = max(std(sil_counts), 0.5);
                pooled_std = sqrt((ctrl_std^2 + sil_std^2) / 2);
                dprime = (ctrl_mean - sil_mean) / pooled_std;

                % 2. Event rate ratio: ctrl / sil.
                %    A ratio of 2-3x is biologically meaningful.
                %    We don't want infinity (sil=0 is unrealistic),
                %    so use (ctrl+0.5)/(sil+0.5) to avoid divide-by-zero
                %    and not over-reward total suppression.
                rate_ratio = (ctrl_mean + 0.5) / (sil_mean + 0.5);

                % 3. Control participation: most control flies should have events
                s_participation = ctrl_frac;

                % 4. Geometry quality (control events only)
                if ~isempty(ctrl_bbox_areas)
                    med_bbox   = nanmedian(ctrl_bbox_areas);
                    med_aspect = nanmedian(ctrl_aspects);
                    med_dur    = nanmedian(ctrl_durations);

                    % Compact bounding boxes (target ~500-1500 mm²)
                    bbox_target = 1000;
                    s_compact = 1 / (1 + (med_bbox / bbox_target)^2);

                    % Circular aspect ratio (target = 1)
                    s_circular = 1 / (1 + (med_aspect - 1)^2);
                else
                    med_bbox = NaN; med_aspect = NaN; med_dur = NaN;
                    s_compact = 0; s_circular = 0;
                end

                % Composite score:
                %   - d-prime (30%) — statistical separability
                %   - Rate ratio (20%) — how many more events in control
                %   - Control participation (15%) — controls should have events
                %   - Geometry quality (35%) — events should be compact loops
                %
                % d-prime: sigmoid to [0,1]
                s_dprime = 2 / (1 + exp(-dprime)) - 1;
                s_dprime = max(s_dprime, 0);

                % Rate ratio: diminishing returns via log, capped.
                % log2(2) = 1 (2x ratio), log2(4) = 2 (4x ratio)
                s_ratio = min(log2(rate_ratio), 3) / 3;  % caps at 8x
                s_ratio = max(s_ratio, 0);

                score = 0.30 * s_dprime + ...
                        0.20 * s_ratio + ...
                        0.15 * s_participation + ...
                        0.20 * s_compact + ...
                        0.15 * s_circular;

                % Store
                grid_results(combo_idx).av_thr   = av_thresholds(ai);
                grid_results(combo_idx).max_dur  = max_durations(di);
                grid_results(combo_idx).merge_g  = merge_gaps(mi);
                grid_results(combo_idx).min_bout = min_bout_vals(bi);
                grid_results(combo_idx).score             = score;
                grid_results(combo_idx).ctrl_mean_events  = ctrl_mean;
                grid_results(combo_idx).ctrl_frac_with    = ctrl_frac;
                grid_results(combo_idx).sil_mean_events   = sil_mean;
                grid_results(combo_idx).sil_frac_with     = sil_frac;
                grid_results(combo_idx).ctrl_median_bbox  = med_bbox;
                grid_results(combo_idx).ctrl_median_aspect = med_aspect;
                grid_results(combo_idx).ctrl_median_dur   = med_dur;
                grid_results(combo_idx).dprime            = dprime;
                grid_results(combo_idx).rate_ratio        = rate_ratio;
            end
        end
    end

    % Progress update
    if mod(ai, 3) == 0
        fprintf('  ... %d/%d AV thresholds done\n', ai, numel(av_thresholds));
    end
end

elapsed = toc;
fprintf('Grid search completed in %.1f seconds\n', elapsed);

%% Print top 15 parameter combinations

scores = [grid_results.score];
[~, rank] = sort(scores, 'descend');

fprintf('\n=== TOP 15 PARAMETER COMBINATIONS (control vs silenced) ===\n');
fprintf('%-4s  %-5s %-6s %-5s %-5s | %-5s %-6s %-6s | %-6s %-5s | %-6s %-5s | %-7s %-6s %-6s\n', ...
    'Rank', 'AVth', 'MaxDr', 'MrgG', 'MnBt', ...
    'Score', 'dPrim', 'Ratio', ...
    'CtlMn', 'CtlFr', ...
    'SilMn', 'SilFr', ...
    'BBoxAr', 'Aspct', 'MedDr');
fprintf('%s\n', repmat('-', 1, 110));

for ri = 1:min(15, numel(rank))
    r = grid_results(rank(ri));
    fprintf('%-4d  %-5d %-6.0f %-5d %-5d | %-5.3f %-6.2f %5.1fx | %-6.1f %-5.2f | %-5.1f %-5.2f | %-7.0f %-6.2f %-6.2f\n', ...
        ri, r.av_thr, r.max_dur, r.merge_g, r.min_bout, ...
        r.score, r.dprime, r.rate_ratio, ...
        r.ctrl_mean_events, r.ctrl_frac_with, ...
        r.sil_mean_events, r.sil_frac_with, ...
        r.ctrl_median_bbox, r.ctrl_median_aspect, r.ctrl_median_dur);
end

%% Print recommended values

best = grid_results(rank(1));
fprintf('\n========================================\n');
fprintf('  RECOMMENDED event_opts values:\n');
fprintf('========================================\n');
fprintf('  event_opts.av_threshold    = %d;\n', best.av_thr);
fprintf('  event_opts.merge_gap       = %d;\n', best.merge_g);
fprintf('  event_opts.min_bout_frames = %d;\n', best.min_bout);
fprintf('  event_opts.heading_target  = 360;\n');
fprintf('  event_opts.max_duration_s  = %.0f;\n', best.max_dur);
fprintf('========================================\n');
fprintf('  Score: %.3f  |  d'': %.2f  |  Rate ratio: %.1fx\n', ...
    best.score, best.dprime, best.rate_ratio);
fprintf('  Control:  mean %.1f events/fly, %.0f%% with events\n', ...
    best.ctrl_mean_events, best.ctrl_frac_with * 100);
fprintf('  Silenced: mean %.1f events/fly, %.0f%% with events\n', ...
    best.sil_mean_events, best.sil_frac_with * 100);
fprintf('  Median bbox: %.0f mm²  |  Aspect: %.2f  |  Duration: %.2fs\n', ...
    best.ctrl_median_bbox, best.ctrl_median_aspect, best.ctrl_median_dur);
fprintf('========================================\n');

%% Plot: best config — control vs silenced comparison

best_opts = struct( ...
    'av_threshold', best.av_thr, ...
    'max_duration_s', best.max_dur, ...
    'merge_gap', best.merge_g, ...
    'min_bout_frames', best.min_bout, ...
    'heading_target', 360);

% Pick example flies: 3 control, 2 per silenced strain
n_ctrl_ex = min(3, n_flies_rep);
ctrl_ex_idx = round(linspace(1, numel(fly_rank), n_ctrl_ex));
ctrl_ex = fly_rank(ctrl_ex_idx);

n_panels = n_ctrl_ex;
sil_ex = {};
for si = 1:numel(silenced_strains)
    n_si = sil_n_flies(si);
    if n_si > 0
        % Pick 2 evenly spaced
        sil_ev_tmp = detect_360_turning_events(sil_heading_h1{si}, sil_av_h1{si}, FPS, best_opts);
        sil_counts_tmp = [sil_ev_tmp.n_events];
        [~, sil_rank_tmp] = sort(sil_counts_tmp, 'descend');
        n_ex = min(2, n_si);
        sil_ex{si} = sil_rank_tmp(round(linspace(1, n_si, n_ex)));
        n_panels = n_panels + n_ex;
    else
        sil_ex{si} = [];
    end
end

fig_comp = figure('Position', [20 20 350*n_panels 350]);
tl_comp = tiledlayout(1, n_panels, 'TileSpacing', 'compact', 'Padding', 'compact');
sgtitle(tl_comp, sprintf('Best config: AV=%d, maxDur=%ds — Control vs Silenced', ...
    best.av_thr, best.max_dur), 'FontSize', 16);

theta_circle = linspace(0, 2*pi, 200);
panel = 0;

% Control flies
for fi = 1:n_ctrl_ex
    panel = panel + 1;
    f = ctrl_ex(fi);
    ax = nexttile(tl_comp);
    hold(ax, 'on');
    plot(ax, ARENA_CENTER(1)+ARENA_R*cos(theta_circle), ...
         ARENA_CENTER(2)+ARENA_R*sin(theta_circle), '-', 'Color', [0.7 0.7 0.7]);

    x_f = x_h1(f,:); y_f = y_h1(f,:);
    plot(ax, x_f, y_f, '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 0.5);

    ev = detect_360_turning_events(heading_h1(f,:), av_h1(f,:), FPS, best_opts);
    if ev.n_events > 0
        cmap_ev = lines(min(ev.n_events, 12));
        for e = 1:ev.n_events
            sf = max(ev.start_frame(e),1); ef = min(ev.end_frame(e), numel(x_f));
            col = cmap_ev(mod(e-1,12)+1,:);
            plot(ax, x_f(sf:ef), y_f(sf:ef), '-', 'Color', col, 'LineWidth', 1.5);
            xs = x_f(sf:ef); ys = y_f(sf:ef);
            w = max(xs)-min(xs); h = max(ys)-min(ys);
            if w>0 && h>0
                rectangle(ax, 'Position', [min(xs), min(ys), w, h], ...
                    'EdgeColor', col, 'LineWidth', 1, 'LineStyle', '--');
            end
        end
    end

    title(ax, sprintf('Control fly %d (%d)', f, ev.n_events), 'FontSize', 11);
    axis(ax, 'equal');
    xlim(ax, ARENA_CENTER(1)+[-1.1 1.1]*ARENA_R);
    ylim(ax, ARENA_CENTER(2)+[-1.1 1.1]*ARENA_R);
    set(ax, 'FontSize', 9, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1);
end

% Silenced flies
sil_colors = {[0.894 0.102 0.110], [1.000 0.498 0.000]};  % red, orange
for si = 1:numel(silenced_strains)
    if isempty(sil_ex{si}), continue; end
    for fi = 1:numel(sil_ex{si})
        panel = panel + 1;
        f = sil_ex{si}(fi);
        ax = nexttile(tl_comp);
        hold(ax, 'on');
        plot(ax, ARENA_CENTER(1)+ARENA_R*cos(theta_circle), ...
             ARENA_CENTER(2)+ARENA_R*sin(theta_circle), '-', 'Color', [0.7 0.7 0.7]);

        x_f = sil_x_h1{si}(f,:); y_f = sil_y_h1{si}(f,:);
        plot(ax, x_f, y_f, '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 0.5);

        ev = detect_360_turning_events(sil_heading_h1{si}(f,:), sil_av_h1{si}(f,:), FPS, best_opts);
        if ev.n_events > 0
            for e = 1:ev.n_events
                sf = max(ev.start_frame(e),1); ef = min(ev.end_frame(e), numel(x_f));
                plot(ax, x_f(sf:ef), y_f(sf:ef), '-', 'Color', sil_colors{si}, 'LineWidth', 1.5);
                xs = x_f(sf:ef); ys = y_f(sf:ef);
                w = max(xs)-min(xs); h = max(ys)-min(ys);
                if w>0 && h>0
                    rectangle(ax, 'Position', [min(xs), min(ys), w, h], ...
                        'EdgeColor', sil_colors{si}, 'LineWidth', 1, 'LineStyle', '--');
                end
            end
        end

        title(ax, sprintf('%s fly %d (%d)', silenced_labels{si}, f, ev.n_events), 'FontSize', 11);
        axis(ax, 'equal');
        xlim(ax, ARENA_CENTER(1)+[-1.1 1.1]*ARENA_R);
        ylim(ax, ARENA_CENTER(2)+[-1.1 1.1]*ARENA_R);
        set(ax, 'FontSize', 9, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1);
    end
end

%% Event count distributions — control vs silenced at best params

fig_dist = figure('Position', [100 100 900 400]);
tl_dist = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

% Histogram of events per fly
ax_hist = nexttile(tl_dist);
hold(ax_hist, 'on');

ev_ctrl_best = detect_360_turning_events(heading_h1, av_h1, FPS, best_opts);
ctrl_counts_best = [ev_ctrl_best.n_events];

ev_sil_best = detect_360_turning_events(sil_heading_all, sil_av_all, FPS, best_opts);
sil_counts_best = [ev_sil_best.n_events];

max_count = max([ctrl_counts_best, sil_counts_best, 1]);
edges = -0.5:1:(max_count + 0.5);

histogram(ax_hist, ctrl_counts_best, edges, 'FaceColor', [0.216 0.494 0.722], ...
    'FaceAlpha', 0.6, 'EdgeColor', 'none', 'DisplayName', 'Control');
histogram(ax_hist, sil_counts_best, edges, 'FaceColor', [0.894 0.102 0.110], ...
    'FaceAlpha', 0.6, 'EdgeColor', 'none', 'DisplayName', 'Silenced (T4T5+L1L4)');
legend(ax_hist, 'Location', 'northeast');
xlabel(ax_hist, 'Events per fly (half 1)', 'FontSize', 14);
ylabel(ax_hist, 'Number of flies', 'FontSize', 14);
title(ax_hist, 'Event count distribution', 'FontSize', 16);
set(ax_hist, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Bbox area distributions
ax_bbox = nexttile(tl_dist);
hold(ax_bbox, 'on');

ctrl_bboxes = [];
sil_bboxes  = [];
for f = 1:n_flies_rep
    if ev_ctrl_best(f).n_events > 0
        g = compute_turning_event_geometry(ev_ctrl_best(f), x_h1(f,:), y_h1(f,:), ARENA_R, ARENA_CENTER);
        ctrl_bboxes = [ctrl_bboxes, g.bbox_area]; %#ok<AGROW>
    end
end
for f = 1:n_sil_total
    if ev_sil_best(f).n_events > 0
        g = compute_turning_event_geometry(ev_sil_best(f), sil_x_all(f,:), sil_y_all(f,:), ARENA_R, ARENA_CENTER);
        sil_bboxes = [sil_bboxes, g.bbox_area]; %#ok<AGROW>
    end
end

if ~isempty(ctrl_bboxes)
    histogram(ax_bbox, ctrl_bboxes, 30, 'FaceColor', [0.216 0.494 0.722], ...
        'FaceAlpha', 0.6, 'EdgeColor', 'none', 'DisplayName', 'Control');
end
if ~isempty(sil_bboxes)
    histogram(ax_bbox, sil_bboxes, 30, 'FaceColor', [0.894 0.102 0.110], ...
        'FaceAlpha', 0.6, 'EdgeColor', 'none', 'DisplayName', 'Silenced');
end
legend(ax_bbox, 'Location', 'northeast');
xlabel(ax_bbox, 'Bounding box area (mm²)', 'FontSize', 14);
ylabel(ax_bbox, 'Number of events', 'FontSize', 14);
title(ax_bbox, 'Bbox area distribution', 'FontSize', 16);
set(ax_bbox, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

sgtitle(tl_dist, sprintf('Control vs Silenced — AV=%d, maxDur=%ds, mergeGap=%d, minBout=%d', ...
    best.av_thr, best.max_dur, best.merge_g, best.min_bout), 'FontSize', 16);

fprintf('\nOptimisation complete.\n');
