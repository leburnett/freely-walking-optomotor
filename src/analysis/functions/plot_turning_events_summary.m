function fig = plot_turning_events_summary(events_h1, geom_h1, events_h2, geom_h2, opts)
% PLOT_TURNING_EVENTS_SUMMARY  Summary plots for discrete 360-deg turning events.
%
%   fig = PLOT_TURNING_EVENTS_SUMMARY(events_h1, geom_h1, events_h2, geom_h2, opts)
%
%   Produces a 4-panel summary figure comparing turning events from the
%   first half (CW stimulus) and second half (CCW stimulus) of the trial.
%
%   INPUTS:
%     events_h1 - struct array [n_flies x 1] from detect_360_turning_events (half 1)
%     geom_h1   - struct array [n_flies x 1] from compute_turning_event_geometry (half 1)
%     events_h2 - struct array [n_flies x 1] (half 2)
%     geom_h2   - struct array [n_flies x 1] (half 2)
%     opts      - struct with optional fields:
%       .title_str  - figure super-title
%       .colors     - [2 x 3] colors for first/second half
%                     (default: blue for H1, red for H2)
%       .fps        - frames per second (default: 30)
%
%   OUTPUT:
%     fig - figure handle
%
%   PANELS:
%     A: Histogram of turns per fly (half 1 vs half 2)
%     B: Histogram of turn duration (s)
%     C: Scatter of bbox area vs wall distance (colored by half)
%     D: Histogram of bbox aspect ratio
%
% See also: detect_360_turning_events, compute_turning_event_geometry

%% Parse options
if nargin < 5, opts = struct(); end
title_str = get_field(opts, 'title_str', 'Turning Events Summary');
if isfield(opts, 'colors')
    cols = opts.colors;
else
    cols = [0.216 0.494 0.722;    % blue for half 1
            0.894 0.102 0.110];   % red for half 2
end

%% Collect per-fly counts and pooled event metrics
n_flies = numel(events_h1);

counts_h1 = zeros(n_flies, 1);
counts_h2 = zeros(n_flies, 1);

dur_h1 = []; dur_h2 = [];
area_h1 = []; area_h2 = [];
aspect_h1 = []; aspect_h2 = [];
wd_h1 = []; wd_h2 = [];

for f = 1:n_flies
    counts_h1(f) = events_h1(f).n_events;
    counts_h2(f) = events_h2(f).n_events;

    dur_h1    = [dur_h1, events_h1(f).duration_s]; %#ok<AGROW>
    dur_h2    = [dur_h2, events_h2(f).duration_s]; %#ok<AGROW>
    area_h1   = [area_h1, geom_h1(f).bbox_area]; %#ok<AGROW>
    area_h2   = [area_h2, geom_h2(f).bbox_area]; %#ok<AGROW>
    aspect_h1 = [aspect_h1, geom_h1(f).bbox_aspect]; %#ok<AGROW>
    aspect_h2 = [aspect_h2, geom_h2(f).bbox_aspect]; %#ok<AGROW>
    wd_h1     = [wd_h1, geom_h1(f).wall_dist_center]; %#ok<AGROW>
    wd_h2     = [wd_h2, geom_h2(f).wall_dist_center]; %#ok<AGROW>
end

%% Figure
fig = figure('Position', [50 50 1200 900]);
tl = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
sgtitle(tl, title_str, 'FontSize', 18);

% Panel A: Turns per fly
ax1 = nexttile(tl);
hold(ax1, 'on');
max_count = max([counts_h1; counts_h2]);
edges_count = -0.5:1:(max_count + 1.5);
histogram(ax1, counts_h1, edges_count, 'FaceColor', cols(1,:), 'FaceAlpha', 0.5, 'EdgeColor', 'none');
histogram(ax1, counts_h2, edges_count, 'FaceColor', cols(2,:), 'FaceAlpha', 0.5, 'EdgeColor', 'none');
xlabel(ax1, 'Number of 360° turns per fly', 'FontSize', 14);
ylabel(ax1, 'Count (flies)', 'FontSize', 14);
title(ax1, 'A — Turns per fly', 'FontSize', 16);
legend(ax1, {'Half 1 (CW)', 'Half 2 (CCW)'}, 'Location', 'best');
set(ax1, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Panel B: Turn duration
ax2 = nexttile(tl);
hold(ax2, 'on');
all_dur = [dur_h1, dur_h2];
if ~isempty(all_dur)
    edges_dur = linspace(0, min(max(all_dur), 15), 30);
    histogram(ax2, dur_h1, edges_dur, 'FaceColor', cols(1,:), 'FaceAlpha', 0.5, 'EdgeColor', 'none');
    histogram(ax2, dur_h2, edges_dur, 'FaceColor', cols(2,:), 'FaceAlpha', 0.5, 'EdgeColor', 'none');
end
xlabel(ax2, 'Turn duration (s)', 'FontSize', 14);
ylabel(ax2, 'Count (events)', 'FontSize', 14);
title(ax2, 'B — Turn duration', 'FontSize', 16);
set(ax2, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Panel C: Bbox area vs wall distance
ax3 = nexttile(tl);
hold(ax3, 'on');
valid_h1 = ~isnan(area_h1) & ~isnan(wd_h1);
valid_h2 = ~isnan(area_h2) & ~isnan(wd_h2);
scatter(ax3, wd_h1(valid_h1), area_h1(valid_h1), 30, cols(1,:), 'filled', 'MarkerFaceAlpha', 0.5);
scatter(ax3, wd_h2(valid_h2), area_h2(valid_h2), 30, cols(2,:), 'filled', 'MarkerFaceAlpha', 0.5);
xlabel(ax3, 'Wall distance of turn centre (mm)', 'FontSize', 14);
ylabel(ax3, 'Bounding box area (mm²)', 'FontSize', 14);
title(ax3, 'C — Turn area vs wall distance', 'FontSize', 16);
set(ax3, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

% Panel D: Bbox aspect ratio
ax4 = nexttile(tl);
hold(ax4, 'on');
all_aspect = [aspect_h1, aspect_h2];
if ~isempty(all_aspect)
    edges_aspect = linspace(1, min(max(all_aspect), 20), 30);
    histogram(ax4, aspect_h1, edges_aspect, 'FaceColor', cols(1,:), 'FaceAlpha', 0.5, 'EdgeColor', 'none');
    histogram(ax4, aspect_h2, edges_aspect, 'FaceColor', cols(2,:), 'FaceAlpha', 0.5, 'EdgeColor', 'none');
end
xlabel(ax4, 'Aspect ratio (max/min)', 'FontSize', 14);
ylabel(ax4, 'Count (events)', 'FontSize', 14);
title(ax4, 'D — Bounding box aspect ratio', 'FontSize', 16);
set(ax4, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

%% Summary text
total_h1 = sum(counts_h1);
total_h2 = sum(counts_h2);
fprintf('Turning events: Half 1 = %d total (%d flies), Half 2 = %d total (%d flies)\n', ...
    total_h1, sum(counts_h1 > 0), total_h2, sum(counts_h2 > 0));
if ~isempty(dur_h1)
    fprintf('  Duration: H1 median=%.2fs, H2 median=%.2fs\n', nanmedian(dur_h1), nanmedian(dur_h2));
end

end

%% Helper
function val = get_field(s, field, default)
    if isfield(s, field)
        val = s.(field);
    else
        val = default;
    end
end
