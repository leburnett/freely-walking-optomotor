%% ANALYSE_PHOTOTAXIS - Comprehensive phototaxis orientation and occupancy analysis
%
% Analyses the orientation behaviour of freely-walking flies relative to a
% bright visual bar stimulus. Combines heading-angle computation, polar
% histogram visualisation, circular statistics, speed-filtered analysis,
% distance-to-bar tracking, towardness binning, half-arena analysis, and
% spatial occupancy heatmaps into a single cohesive script.
%
% SECTIONS:
%   1.  Configuration and arena/bar parameters
%   2.  Compute derived fields (d2bar, bearing_to_ref, heading_rel_ref)
%   3.  Diagnostic: single-fly angle visualisation
%   4.  Pooled polar histograms (all flies, all cohorts, both reps)
%   5.  Per-fly circular statistics (V-test, Watson-Williams)
%   6.  Per-cohort individual fly polar plots
%   7.  Per-cohort polar plots (one plot per rep)
%   8.  Speed-filtered polar analysis (both reps required)
%   9.  Distance-to-bar time series
%   10. Towardness vs distance from bar (pooled binned analysis)
%   11. Half-arena orientation analysis (near vs far from bar)
%   12. Spatial occupancy heatmaps and differential occupancy
%
% COORDINATE CONVENTIONS:
%   - 0 deg = east (right), +90 deg = south (down)
%   - heading_rel_ref: 0 deg = pointing directly at bar, +/-180 deg = away
%   - Towardness: <cos(theta)> where theta = heading_rel_ref
%       +1 = toward bar, 0 = perpendicular, -1 = away from bar
%
% REQUIREMENTS:
%   - DATA struct from phototaxis experiments (struct array, one per cohort)
%     Fields needed: x_data, y_data, heading_wrap (per condition)
%   - Circular Statistics Toolbox (circ_vtest, circ_wwtest)
%   - Helper functions (in src/analysis/functions/):
%       polar_hist_all_flies
%       plot_polar_hist_subplot_one_cohort
%       plot_polar_all_speedfiltered_bothreps
%       plot_distance_to_bar_from_DATA
%       plot_distance_to_bar_both_reps_from_DATA
%       plot_distance_to_bar_allcohorts_mean
%       analyze_orient_vs_halfarena
%       plot_fly_occupancy_quadrants_phototaxis
%       plot_fly_occupancy_quadrants_diff_phototaxis
%       plot_fly_occupancy_quadrants_diff_avg_phototaxis
%
% See also: circ_vtest, circ_wwtest, polar_hist_all_flies

%% ================================================================
%  1 — CONFIGURATION AND ARENA / BAR PARAMETERS
%  ================================================================
%
%  All shared constants are defined here so that downstream sections
%  are consistent. Edit this section to change time windows, thresholds,
%  or bar position.

PPM = 4.1691;                              % pixels per mm (calibration)
ARENA_CENTER_PX = [528, 516];              % arena centre in pixels
ARENA_CENTER_MM = ARENA_CENTER_PX / PPM;   % arena centre in mm

% Bar position in pixels and mm
BAR_CENTER_PX = [124, 219];
BAR_CENTER_MM = BAR_CENTER_PX / PPM;       % [29.7426, 52.5293]
ref_mm = BAR_CENTER_MM;                    % shorthand used throughout

FPS = 30;

% Condition names (phototaxis = condition 12, repeated in R1 and R2)
condNames = {'R1_condition_12', 'R2_condition_12'};

% Time windows (in frames at 30 fps)
% Stimulus onset is at frame 300. These windows allow a 0.5 s buffer.
framesA = 135:285;     % 5 s pre-stimulus (up to 0.5 s before onset)
framesB = 315:465;     % 5 s during stimulus (0.5 s after onset)

% Polar histogram settings
numBins  = 24;                 % 15 deg per bin
normMode = 'probability';      % 'count' or 'probability'

% Speed and distance thresholds (used in speed-filtered analysis)
velThresh  = 5;      % mm/s — minimum mean speed in both windows
distThresh = 150;    % mm — fly must come within this of bar during stim

%% ================================================================
%  2 — COMPUTE DERIVED FIELDS: d2bar, bearing_to_ref, heading_rel_ref
%  ================================================================
%
%  For every cohort and rep, compute:
%    d2bar          — Euclidean distance from each fly to the bar (mm)
%    bearing_to_ref — absolute bearing angle from fly to bar (deg)
%    heading_rel_ref — heading relative to bar direction (deg, [-180,180])
%                      0 = pointing at bar, +/-180 = pointing away
%
%  These are stored directly in DATA so that downstream sections and
%  helper functions can access them.

fprintf('\n=== Computing derived fields (d2bar, heading_rel_ref) ===\n');

for i = 1:numel(DATA)
    for c = 1:numel(condNames)
        if ~isfield(DATA(i), condNames{c}) || ~isstruct(DATA(i).(condNames{c}))
            continue;
        end
        S = DATA(i).(condNames{c});
        if ~isfield(S, 'x_data') || ~isfield(S, 'y_data')
            continue;
        end

        x = S.x_data;   % [n_flies x n_frames] in mm
        y = S.y_data;

        % Distance to bar (mm)
        DATA(i).(condNames{c}).d2bar = hypot(x - ref_mm(1), y - ref_mm(2));

        % Bearing from fly toward the reference point (deg)
        % Convention: 0 = east, +90 = south (image coordinates)
        dx = ref_mm(1) - x;
        dy = ref_mm(2) - y;
        bearing = atan2d(dy, dx);
        DATA(i).(condNames{c}).bearing_to_ref = bearing;

        % Heading relative to reference: wrap to [-180, 180]
        if isfield(S, 'heading_wrap')
            hw = S.heading_wrap;
            DATA(i).(condNames{c}).heading_rel_ref = mod(bearing - hw + 180, 360) - 180;
        end
    end
end

fprintf('  Done. Fields added to DATA for all cohorts/reps.\n');

%% ================================================================
%  3 — DIAGNOSTIC: SINGLE-FLY ANGLE VISUALISATION
%  ================================================================
%
%  Plots one fly in one frame showing:
%    - Fly position and reference point
%    - Heading arrow (quiver) and bearing-to-bar arrow
%    - Arc showing the angular difference (heading_rel_ref)
%
%  Useful for verifying that the angle computations are correct.

entryIdx_diag = 1;
condName_diag = 'R1_condition_12';
flyIdx_diag   = 15;
frameIdx_diag = 1;
vecLen = 10;   % arrow length (mm)
arcR   = 8;    % arc radius (mm)

S_diag  = DATA(entryIdx_diag).(condName_diag);
x0 = S_diag.x_data(flyIdx_diag, frameIdx_diag);
y0 = S_diag.y_data(flyIdx_diag, frameIdx_diag);
hw = S_diag.heading_wrap(flyIdx_diag, frameIdx_diag);

% Bearing and relative angle for this single frame
dx0 = ref_mm(1) - x0;
dy0 = ref_mm(2) - y0;
bearing0 = atan2d(dy0, dx0);
rel0 = mod(bearing0 - hw + 180, 360) - 180;

figure('Name', 'Diagnostic: Single-fly angle'); hold on; grid on;
set(gca, 'YDir', 'reverse');
axis equal;

plot(x0, y0, 'r.', 'MarkerSize', 18);
plot(ref_mm(1), ref_mm(2), 'bx', 'MarkerSize', 12, 'LineWidth', 2);
plot([x0 ref_mm(1)], [y0 ref_mm(2)], ':', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

% Heading arrow
quiver(x0, y0, vecLen*cosd(hw), vecLen*sind(hw), 0, 'LineWidth', 2);
% Bearing arrow
quiver(x0, y0, vecLen*cosd(bearing0), vecLen*sind(bearing0), 0, 'LineWidth', 2);

% Angle arc
t_arc = linspace(hw, hw + rel0, 100);
plot(x0 + arcR*cosd(t_arc), y0 + arcR*sind(t_arc), 'k-', 'LineWidth', 1.5);
midAng = (hw + hw + rel0) / 2;
text(x0 + (arcR+1)*cosd(midAng), y0 + (arcR+1)*sind(midAng), ...
    sprintf('%.1f^\\circ', rel0), 'HorizontalAlignment', 'center', 'FontSize', 9);

xlabel('X (mm)'); ylabel('Y (mm)');
legend({'Fly', 'Reference', 'Fly-Ref line', 'Heading', 'Bearing to ref'}, 'Location', 'best');
title(sprintf('%s | Fly %d, Frame %d\nHeading=%.1f°, Bearing=%.1f°, Δ=%.1f°', ...
    strrep(condName_diag, '_', '-'), flyIdx_diag, frameIdx_diag, hw, bearing0, rel0));
pad = 15;
xlim([min([x0, ref_mm(1)])-pad, max([x0, ref_mm(1)])+pad]);
ylim([min([y0, ref_mm(2)])-pad, max([y0, ref_mm(2)])+pad]);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

%% ================================================================
%  4 — POOLED POLAR HISTOGRAMS (all flies, all cohorts, both reps)
%  ================================================================
%
%  Pools heading_rel_ref across every cohort, fly, and rep to produce
%  a single overlaid polar histogram: pre-stimulus (grey) vs during
%  stimulus (magenta). This gives the broadest overview of whether
%  flies orient toward the bar (0 deg) during stimulation.

fprintf('\n=== Pooled polar histogram (all cohorts, both reps) ===\n');

angA_cells = {};
angB_cells = {};

for ei = 1:numel(DATA)
    for c = 1:numel(condNames)
        if ~isfield(DATA(ei), condNames{c}), continue; end
        S = DATA(ei).(condNames{c});
        if ~isfield(S, 'heading_rel_ref') || isempty(S.heading_rel_ref), continue; end

        nFrames = size(S.heading_rel_ref, 2);
        idxA = framesA(framesA >= 1 & framesA <= nFrames);
        idxB = framesB(framesB >= 1 & framesB <= nFrames);

        if ~isempty(idxA)
            angA_cells{end+1} = reshape(S.heading_rel_ref(:, idxA), [], 1); %#ok<SAGROW>
        end
        if ~isempty(idxB)
            angB_cells{end+1} = reshape(S.heading_rel_ref(:, idxB), [], 1); %#ok<SAGROW>
        end
    end
end

angA_deg = vertcat(angA_cells{:});
angB_deg = vertcat(angB_cells{:});
angA_rad = deg2rad(mod(angA_deg(~isnan(angA_deg)), 360));
angB_rad = deg2rad(mod(angB_deg(~isnan(angB_deg)), 360));

binEdges = linspace(0, 2*pi, numBins + 1);

figure('Name', 'Pooled Polar Histogram', 'Color', 'w');
ax_pol = polaraxes;
ax_pol.ThetaZeroLocation = 'top';
ax_pol.ThetaDir = 'clockwise';
ax_pol.ThetaTick = 0:30:330;
hold(ax_pol, 'on');

polarhistogram(ax_pol, angA_rad, binEdges, 'Normalization', normMode, ...
    'FaceColor', [0.7 0.7 0.7], 'FaceAlpha', 0.5, 'EdgeColor', [0.7 0.7 0.7]);
polarhistogram(ax_pol, angB_rad, binEdges, 'Normalization', normMode, ...
    'FaceColor', [1 0.6 1], 'FaceAlpha', 0.4, 'EdgeColor', [1 0.6 1]);

legend(ax_pol, {sprintf('Pre %d-%d', framesA(1), framesA(end)), ...
                sprintf('Stim %d-%d', framesB(1), framesB(end))}, ...
    'Location', 'southoutside');
title(ax_pol, 'All flies - All cohorts - Both reps');

%% ================================================================
%  5 — PER-FLY CIRCULAR STATISTICS (V-test, Watson-Williams)
%  ================================================================
%
%  Computes one circular mean heading per fly in each time window
%  (pre and stim). This respects the non-independence of frames within
%  a fly. Statistical tests:
%
%    V-test on post-stimulus means: tests whether heading clusters
%      around 0 deg (i.e., toward the bar). This is a one-sample test
%      for a specified mean direction.
%
%    Watson-Williams test: a circular analogue of the paired t-test.
%      Tests whether the population of per-fly mean headings differs
%      between pre and stim windows.

fprintf('\n=== Per-fly circular statistics ===\n');

perFly = [];

for ei = 1:numel(DATA)
    for c = 1:numel(condNames)
        if ~isfield(DATA(ei), condNames{c}), continue; end
        S = DATA(ei).(condNames{c});
        if ~isfield(S, 'heading_rel_ref') || isempty(S.heading_rel_ref), continue; end

        nFlies  = size(S.heading_rel_ref, 1);
        nFrames = size(S.heading_rel_ref, 2);
        idxA = framesA(framesA >= 1 & framesA <= nFrames);
        idxB = framesB(framesB >= 1 & framesB <= nFrames);

        for f = 1:nFlies
            aA = deg2rad(S.heading_rel_ref(f, idxA));
            aB = deg2rad(S.heading_rel_ref(f, idxB));
            aA = aA(~isnan(aA));
            aB = aB(~isnan(aB));
            if isempty(aA) || isempty(aB), continue; end

            muA = atan2(mean(sin(aA)), mean(cos(aA)));
            muB = atan2(mean(sin(aB)), mean(cos(aB)));
            rA  = abs(mean(exp(1i * aA)));
            rB  = abs(mean(exp(1i * aB)));

            perFly = [perFly; table(ei, c, f, muA, muB, rA, rB)]; %#ok<AGROW>
        end
    end
end

muAs = perFly.muA;
muBs = perFly.muB;
diffs = atan2(sin(muBs - muAs), cos(muBs - muAs));

% V-test: do post-stimulus headings cluster toward 0 (bar direction)?
[pV_B, ~] = circ_vtest(muBs, 0);

% Watson-Williams: do pre and post distributions differ?
pWW = circ_wwtest(muAs, muBs);

fprintf('  Total per-fly observations: %d\n', height(perFly));
fprintf('  V-test toward bar (post-stim means):     p = %.3g\n', pV_B);
fprintf('  Watson-Williams (pre vs post):            p = %.3g\n', pWW);
fprintf('  Mean circular change (post - pre):        %.1f deg\n', ...
    rad2deg(atan2(mean(sin(diffs)), mean(cos(diffs)))));

%% ================================================================
%  6 — PER-COHORT INDIVIDUAL FLY POLAR PLOTS
%  ================================================================
%
%  For selected cohorts, generates a subplot grid with one polar
%  histogram per fly per rep. This reveals individual variability and
%  helps identify cohorts with strong or weak orientation responses.

fprintf('\n=== Per-cohort individual fly polar plots ===\n');

cohorts_to_plot = [28, 29, 30];   % edit to select cohorts of interest
for ei = cohorts_to_plot
    if ei <= numel(DATA)
        plot_polar_hist_subplot_one_cohort(DATA, ei);
    end
end

%% ================================================================
%  7 — PER-COHORT POLAR PLOTS (one plot per rep, all flies pooled)
%  ================================================================
%
%  For a single cohort, plots one polar histogram per rep with all
%  flies pooled together. Useful for checking rep-to-rep consistency.

fprintf('\n=== Per-cohort polar plots (pooled per rep) ===\n');

cohort_single = 1;   % edit to select cohort

if cohort_single <= numel(DATA)
    conds_rep = {'R1_condition_12', 'R2_condition_12'};

    fig_rep = figure('Name', 'Cohort Polar — Per Rep', 'Color', 'w');
    tl_rep = tiledlayout(1, numel(conds_rep), 'TileSpacing', 'compact', 'Padding', 'compact');

    try
        dtStr = string(DATA(cohort_single).meta.date);
        tmStr = string(DATA(cohort_single).meta.time);
        sgtitle(tl_rep, sprintf('Heading rel. ref (0=N, CW) — %s %s', ...
            strrep(dtStr, '_', '-'), tmStr));
    catch
        sgtitle(tl_rep, 'Heading relative to reference (0=N, CW)');
    end

    for ci = 1:numel(conds_rep)
        if ~isfield(DATA(cohort_single), conds_rep{ci}), continue; end
        S_rep = DATA(cohort_single).(conds_rep{ci});
        ax_rep = polaraxes(tl_rep);
        ax_rep.Layout.Tile = ci;
        polar_hist_all_flies(ax_rep, S_rep, framesA, framesB, struct( ...
            'numBins', numBins, 'Normalization', normMode, ...
            'titleStr', strrep(conds_rep{ci}, '_', '-')));
    end
    legend(ax_rep, {sprintf('%d-%d', framesA(1), framesA(end)), ...
                    sprintf('%d-%d', framesB(1), framesB(end))}, ...
        'Location', 'southoutside');
end

%% ================================================================
%  8 — SPEED-FILTERED POLAR ANALYSIS (both reps required)
%  ================================================================
%
%  Only includes flies that meet a mean-speed threshold (velThresh) in
%  BOTH time windows (pre and stim) AND in BOTH experimental reps.
%  This ensures that heading estimates come from actively walking flies
%  where the heading signal is reliable.
%
%  Also computes per-fly circular means (averaged across reps) and
%  performs V-test and Watson-Williams test on the combined estimates.

fprintf('\n=== Speed-filtered analysis (vel >= %.0f mm/s, both reps) ===\n', velThresh);

% --- Pass 1: build speed-qualification mask per cohort ---
qualByEntry = struct('mask', {}, 'nFliesEntry', {});
nTotalFlies = 0;

for ei = 1:numel(DATA)
    hasRep = false(1, numel(condNames));
    nFliesEach = nan(1, numel(condNames));
    for c = 1:numel(condNames)
        hasRep(c) = isfield(DATA(ei), condNames{c}) && ...
                    isfield(DATA(ei).(condNames{c}), 'd2bar') && ...
                    ~isempty(DATA(ei).(condNames{c}).d2bar);
        if hasRep(c)
            nFliesEach(c) = size(DATA(ei).(condNames{c}).d2bar, 1);
        end
    end
    if ~all(hasRep), continue; end

    nfe = min(nFliesEach);
    if nfe == 0, continue; end
    nTotalFlies = nTotalFlies + nfe;

    speedOK_reps = false(nfe, numel(condNames));

    for c = 1:numel(condNames)
        S = DATA(ei).(condNames{c});
        nF = size(S.d2bar, 2);
        idxA = framesA(framesA >= 1 & framesA <= nF);
        idxB = framesB(framesB >= 1 & framesB <= nF);
        if isempty(idxA) || isempty(idxB), continue; end

        % Compute speed if vel_data is missing
        if isfield(S, 'vel_data') && ~isempty(S.vel_data)
            v = S.vel_data(1:nfe, :);
        elseif isfield(S, 'x_data') && isfield(S, 'y_data')
            dxv = diff(S.x_data(1:nfe, :), 1, 2);
            dyv = diff(S.y_data(1:nfe, :), 1, 2);
            sp = hypot(dxv, dyv) * FPS;
            v = [sp(:,1), sp];
        else
            v = NaN(nfe, nF);
        end

        meanA = mean(v(:, idxA), 2, 'omitnan');
        meanB = mean(v(:, idxB), 2, 'omitnan');
        speedOK_reps(:, c) = (meanA >= velThresh) & (meanB >= velThresh);
    end

    qual = all(speedOK_reps, 2);
    qualByEntry(ei).mask = qual;
    qualByEntry(ei).nFliesEntry = nfe;

    fprintf('  Entry %d: %d flies, %d qualify\n', ei, nfe, nnz(qual));
end

% --- Pass 2: per-fly circular means across reps ---
perFly_sf = table();

for ei = 1:numel(DATA)
    if ei > numel(qualByEntry) || isempty(qualByEntry(ei).mask), continue; end
    qual = qualByEntry(ei).mask;
    nfe  = qualByEntry(ei).nFliesEntry;
    if ~any(qual), continue; end

    muA_rep = nan(nfe, numel(condNames));
    muB_rep = nan(nfe, numel(condNames));
    rA_rep  = nan(nfe, numel(condNames));
    rB_rep  = nan(nfe, numel(condNames));

    for c = 1:numel(condNames)
        if ~isfield(DATA(ei), condNames{c}), continue; end
        S = DATA(ei).(condNames{c});
        if ~isfield(S, 'heading_rel_ref') || isempty(S.heading_rel_ref), continue; end

        nF = size(S.heading_rel_ref, 2);
        idxA = framesA(framesA >= 1 & framesA <= nF);
        idxB = framesB(framesB >= 1 & framesB <= nF);
        if isempty(idxA) || isempty(idxB), continue; end

        for f = 1:nfe
            if ~qual(f), continue; end
            aA = deg2rad(S.heading_rel_ref(f, idxA));
            aB = deg2rad(S.heading_rel_ref(f, idxB));
            aA = aA(~isnan(aA));
            aB = aB(~isnan(aB));
            if isempty(aA) || isempty(aB), continue; end

            muA_rep(f, c) = atan2(mean(sin(aA)), mean(cos(aA)));
            muB_rep(f, c) = atan2(mean(sin(aB)), mean(cos(aB)));
            rA_rep(f, c)  = abs(mean(exp(1i * aA)));
            rB_rep(f, c)  = abs(mean(exp(1i * aB)));
        end
    end

    % Combine across reps (circular mean of angles, arithmetic mean of r)
    for f = 1:nfe
        if ~qual(f), continue; end
        mA = muA_rep(f, :); mA = mA(~isnan(mA));
        mB = muB_rep(f, :); mB = mB(~isnan(mB));
        rAl = rA_rep(f, :); rAl = rAl(~isnan(rAl));
        rBl = rB_rep(f, :); rBl = rBl(~isnan(rBl));
        if numel(mA) < 2 || numel(mB) < 2, continue; end

        muA_comb = atan2(mean(sin(mA)), mean(cos(mA)));
        muB_comb = atan2(mean(sin(mB)), mean(cos(mB)));
        rA_comb  = mean(rAl);
        rB_comb  = mean(rBl);

        perFly_sf = [perFly_sf; table(ei, f, muA_comb, muB_comb, rA_comb, rB_comb, ...
            'VariableNames', {'entryIdx', 'fly', 'muA', 'muB', 'rA', 'rB'})]; %#ok<AGROW>
    end
end

% --- Statistics ---
if ~isempty(perFly_sf)
    muAs_sf = perFly_sf.muA;
    muBs_sf = perFly_sf.muB;
    diffs_sf = atan2(sin(muBs_sf - muAs_sf), cos(muBs_sf - muAs_sf));

    pV_B_sf   = circ_vtest(muBs_sf, 0);
    pV_diff_sf = circ_vtest(diffs_sf, 0);
    if exist('circ_wwtest', 'file')
        pWW_sf = circ_wwtest(muAs_sf, muBs_sf);
    else
        pWW_sf = NaN;
    end

    nUsed = height(perFly_sf);
    fprintf('  Qualified flies (speed >= %.0f, both reps): %d / %d\n', velThresh, nUsed, nTotalFlies);
    fprintf('  V-test toward bar (post means):          p = %.3g\n', pV_B_sf);
    fprintf('  V-test on paired diffs:                  p = %.3g\n', pV_diff_sf);
    fprintf('  Watson-Williams:                         p = %.3g\n', pWW_sf);
    fprintf('  Mean circular change (post - pre):       %.1f deg\n', ...
        rad2deg(atan2(mean(sin(diffs_sf)), mean(cos(diffs_sf)))));
else
    warning('No flies qualified for speed-filtered analysis.');
end

% --- Speed-filtered polar plot using helper function ---
plot_polar_all_speedfiltered_bothreps(DATA, framesA, framesB, velThresh);

%% ================================================================
%  9 — DISTANCE-TO-BAR TIME SERIES
%  ================================================================
%
%  Plots the Euclidean distance from each fly to the bar over time.
%  Three views:
%    a) Per-cohort, single rep (individual fly traces)
%    b) Per-cohort, both reps overlaid
%    c) Pooled across all cohorts (mean +/- SEM)
%
%  If flies are attracted to the bar during stimulation, distance
%  should decrease after stimulus onset (frame 300).

fprintf('\n=== Distance to bar time series ===\n');

% (a) Single-rep per cohort
condName_d2b = "R1_condition_12";
for ei = 1:min(5, numel(DATA))   % first 5 cohorts as examples
    plot_distance_to_bar_from_DATA(DATA, ei, condName_d2b);
end

% (b) Both reps per cohort
for ei = 1:min(5, numel(DATA))
    plot_distance_to_bar_both_reps_from_DATA(DATA, ei);
end

% (c) Pooled across all cohorts (mean +/- SEM)
plot_distance_to_bar_allcohorts_mean(DATA);
ylim([0 240]);

%% ================================================================
%  10 — TOWARDNESS VS DISTANCE FROM BAR (pooled binned analysis)
%  ================================================================
%
%  "Towardness" is defined as <cos(heading_rel_ref)>:
%    +1 = heading directly toward the bar
%     0 = heading perpendicular to the bar
%    -1 = heading directly away from the bar
%
%  We bin all frame-level observations by distance-to-bar and compute
%  the mean towardness in each bin. Separate lines for pre-stimulus
%  and stimulus windows. If flies orient toward the bar during stim,
%  the stimulus curve should be above the baseline at distances where
%  the bar is visible.

fprintf('\n=== Towardness vs distance from bar ===\n');

% Settings for this section (can override the global windows)
pre_tow  = 1:300;
post_tow = 300:600;

edges_tow   = [0:15:250, Inf];
centers_tow = (edges_tow(1:end-1) + edges_tow(2:end)) / 2;
centers_tow(end) = edges_tow(end-1) + 7.5;  % replace Inf midpoint

tow_pre_all  = [];  dist_pre_all  = [];
tow_post_all = [];  dist_post_all = [];

for ei = 1:numel(DATA)
    for c = 1:numel(condNames)
        if ~isfield(DATA(ei), condNames{c}), continue; end
        S = DATA(ei).(condNames{c});
        if ~isfield(S, 'd2bar') || isempty(S.d2bar), continue; end
        if ~isfield(S, 'heading_rel_ref') || isempty(S.heading_rel_ref), continue; end

        nF = size(S.d2bar, 2);
        idx_pre  = pre_tow(pre_tow >= 1 & pre_tow <= nF);
        idx_post = post_tow(post_tow >= 1 & post_tow <= nF);

        if ~isempty(idx_pre)
            theta_p = S.heading_rel_ref(:, idx_pre);
            d_p     = S.d2bar(:, idx_pre);
            tow_pre_all  = [tow_pre_all;  cosd(theta_p(:))]; %#ok<AGROW>
            dist_pre_all = [dist_pre_all;  d_p(:)];           %#ok<AGROW>
        end
        if ~isempty(idx_post)
            theta_s = S.heading_rel_ref(:, idx_post);
            d_s     = S.d2bar(:, idx_post);
            tow_post_all  = [tow_post_all;  cosd(theta_s(:))]; %#ok<AGROW>
            dist_post_all = [dist_post_all; d_s(:)];            %#ok<AGROW>
        end
    end
end

% Bin means and SEMs
bin_pre_tow  = discretize(dist_pre_all, edges_tow);
bin_post_tow = discretize(dist_post_all, edges_tow);
nBins_tow = numel(edges_tow) - 1;

m_pre_tow  = accumarray(bin_pre_tow(~isnan(bin_pre_tow)),   tow_pre_all(~isnan(bin_pre_tow)),  [nBins_tow 1], @(x) mean(x,'omitnan'), NaN);
m_post_tow = accumarray(bin_post_tow(~isnan(bin_post_tow)), tow_post_all(~isnan(bin_post_tow)), [nBins_tow 1], @(x) mean(x,'omitnan'), NaN);

sem_pre_tow  = accumarray(bin_pre_tow(~isnan(bin_pre_tow)),   tow_pre_all(~isnan(bin_pre_tow)),  [nBins_tow 1], @(x) std(x,0,'omitnan')/sqrt(numel(x)), NaN);
sem_post_tow = accumarray(bin_post_tow(~isnan(bin_post_tow)), tow_post_all(~isnan(bin_post_tow)), [nBins_tow 1], @(x) std(x,0,'omitnan')/sqrt(numel(x)), NaN);

figure('Name', 'Towardness vs Distance', 'Color', 'w'); hold on;
plot(centers_tow, m_pre_tow,  '-', 'LineWidth', 1.8, 'Color', [0.35 0.35 0.35]);
plot(centers_tow, m_post_tow, '-', 'LineWidth', 2.0, 'Color', [1 0 1]);
yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);
xlabel('Distance to bar (mm)', 'FontSize', 14);
ylabel('<cos \theta> (towardness)', 'FontSize', 14);
legend({sprintf('Pre %d-%d', pre_tow(1), pre_tow(end)), ...
        sprintf('Stim %d-%d', post_tow(1), post_tow(end))}, 'Location', 'best');
title('Towardness vs distance — pooled across all cohorts & reps', 'FontSize', 16);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

%% ================================================================
%  11 — HALF-ARENA ORIENTATION ANALYSIS (near vs far from bar)
%  ================================================================
%
%  Splits the arena into two halves based on the fly's position
%  relative to the bar: the "near" half (closer to the bar) and the
%  "far" half. Tests whether flies in the near half show stronger
%  orientation toward the bar than flies in the far half.
%
%  Uses a cone angle to define the dividing line (default 30 deg).

fprintf('\n=== Half-arena analysis ===\n');

analyze_orient_vs_halfarena(DATA, ARENA_CENTER_MM, ref_mm, ...
    'ConeDeg', 30, 'UseAllEntries', true);

%% ================================================================
%  12 — SPATIAL OCCUPANCY HEATMAPS AND DIFFERENTIAL OCCUPANCY
%  ================================================================
%
%  Divides the arena into spatial bins (quadrants) and computes the
%  fraction of time flies occupy each region during different
%  experimental epochs. Generates:
%
%    a) Per-cohort tiled figure: 6 occupancy heatmaps (different time
%       windows) + 1 differential heatmap (later - early)
%
%    b) Averaged differential heatmap across selected cohorts
%
%  If flies are attracted to the bar, occupancy should increase in
%  the bar-containing region during stimulation.

fprintf('\n=== Spatial occupancy heatmaps ===\n');

% (a) Per-cohort occupancy across time windows
entryIdx_occ = 14;   % example cohort — edit as needed

figure('Name', sprintf('Occupancy — Cohort %d', entryIdx_occ));
tiledlayout(1, 7, 'TileSpacing', 'compact');

frameRanges = {1:300, 300:600, 300:900, 300:1200, 300:1650, 1650:2000};
frameLabels = {'Pre', '0-10s', '0-20s', '0-30s', '0-45s', 'Post'};

for i = 1:6
    nexttile;
    plot_fly_occupancy_quadrants_phototaxis(DATA, entryIdx_occ, frameRanges{i});
    title(frameLabels{i}, 'FontSize', 10);
    if i == 1
        cb = colorbar(gca);
        cb.Label.String = 'Occupancy (fraction)';
        cb.FontSize = 10;
        cb.Ticks = [0, 0.1, 0.2, 0.3, 0.4];
        cb.Location = 'southoutside';
    end
end
nexttile;
plot_fly_occupancy_quadrants_diff_phototaxis(DATA, entryIdx_occ);
cb = colorbar(gca);
cb.Label.String = '\Delta occupancy (later - early)';
cb.Location = 'southoutside';
cb.FontSize = 10;

sgtitle(sprintf('Cohort %d — Spatial Occupancy', entryIdx_occ), 'FontSize', 16);
f = gcf;
f.Position = [1 720 1796 327];

% (b) Averaged differential heatmap across selected cohorts
entryIdxVec_occ = 1:30;
entryIdxVec_occ([5, 17, 18, 20, 22, 24, 25]) = [];   % exclude problematic cohorts

plot_fly_occupancy_quadrants_diff_avg_phototaxis(DATA, entryIdxVec_occ, ...
    'Epoch1', [1 300], 'Epoch2', [300 1200], 'Condition', 'condition_12');

%% ================================================================

fprintf('\n=== Phototaxis analysis complete ===\n');
