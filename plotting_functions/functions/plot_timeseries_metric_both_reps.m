function plot_timeseries_metric_both_reps(DATA, metric, condIdx, entryIdx, col, plot_indiv, fps, stimFrames)
%PLOT_DISTANCE_TO_BAR_AVG_REPS
% Plot distance-to-bar with per-fly traces averaged across R1 & R2, and cohort mean.
%
%   plot_distance_to_bar_avg_reps(DATA, entryIdx, fps, stimFrames)
%
% Inputs:
%   DATA       : main struct array
%   metric     : string of the data type to plot
%   condIdx    : which condition to plot for
%   entryIdx   : which cohort (row in DATA), e.g., 8
%   col        : colour to plot mean
%   plot_indiv : boolean. Set to 1 to plot the traces for each individual
%                fly.
%   fps        : frames per second (default 30)
%   stimFrames : [on off] frame indices for vertical markers (default [300 1650])
%
% Behavior:
%   - Loads metric from R1_condition_12 and R2_condition_12 (if present).
%   - NaN-pads each rep to the same #frames.
%   - Averages time series per fly across the two reps (omit NaNs).
%   - Plots per-fly averaged traces (light gray).
%   - Plots cohort mean (black) with optional SEM shading.
%   - X-axis in seconds; vertical lines at stimFrames (light red).
%
% Notes:
%   - If only one rep exists, it just uses that rep.
%   - If #flies differs between reps, it uses the minimum and warns.

    if nargin < 7 || isempty(fps), fps = 30; end
    if nargin < 8 || isempty(stimFrames), stimFrames = [300 1200]; end

    % condNames = {strcat('R1_condition_', string(condIdx)), strcat('R2_condition_', string(condIdx))};
    condNames = {strcat('R2_condition_', string(condIdx))};

    % --- Extract available reps for this cohort ---
    reps = struct('name', {}, 'd', {});
    for c = 1:numel(condNames)
        if isfield(DATA(entryIdx), condNames{c}) ...
                && isfield(DATA(entryIdx).(condNames{c}), string(metric)) ...
                && ~isempty(DATA(entryIdx).(condNames{c}).(metric))
            reps(end+1).name = condNames{c}; %#ok<AGROW>
            reps(end).d = DATA(entryIdx).(condNames{c}).(metric);   % [nFlies x nFrames]
        end
    end

    if isempty(reps)
        error('No metric data found in %s or %s for entryIdx=%d.', condNames{1}, condNames{2}, entryIdx);
    end

    % --- Harmonize #flies (rows) if they differ ---
    nFlies_each = arrayfun(@(r) size(r.d,1), reps);
    if numel(unique(nFlies_each)) > 1
        warning('Different #flies across reps for entryIdx=%d. Using min=%d flies.', ...
            entryIdx, min(nFlies_each));
        nFlies = min(nFlies_each);
        for k = 1:numel(reps)
            reps(k).d = reps(k).d(1:nFlies, :);
        end
    else
        nFlies = nFlies_each(1);
    end

    % --- Pad frames to the same length across reps ---
    nFrames_each = arrayfun(@(r) size(r.d,2), reps);
    maxFrames = max(nFrames_each);
    for k = 1:numel(reps)
        A = reps(k).d;
        if size(A,2) < maxFrames
            Apad = NaN(nFlies, maxFrames);
            Apad(:,1:size(A,2)) = A;
            reps(k).d = Apad;
        end
    end

    % --- Stack reps along 3rd dim and average across reps per fly ---
    % shape: [nFlies x maxFrames x nReps]
    D = cat(3, reps.d);
    perFlyAvg = mean(D, 3, 'omitnan');   % [nFlies x maxFrames]

    % --- Cohort mean and SEM across flies ---
    cohortMean = mean(perFlyAvg, 1, 'omitnan');                           % [1 x maxFrames]
    cohortSEM  = std(perFlyAvg, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(perFlyAvg),1));

    % --- X axis in seconds ---
    t = (0:maxFrames-1) / fps;

    % --- Plot ---
    
    hold on;

    if plot_indiv
        % Light gray per-fly lines
        plot(t, perFlyAvg', 'Color', [0.8 0.8 0.8], 'LineWidth', 0.6);
    end 

    % Mean ± SEM shaded area (subtle)
    fill([t, fliplr(t)], ...
         [cohortMean - cohortSEM, fliplr(cohortMean + cohortSEM)], ...
         [0.9 0.9 0.9], 'EdgeColor','none', 'FaceAlpha', 0.5);

    % Cohort mean (black)
    plot(t, cohortMean, '-', 'Color', col, 'LineWidth', 1.8);

    % Stimulus markers
    for sf = stimFrames(:)'
        xline(sf / fps, '-', 'Color', [1 0.7 0.7], 'LineWidth', 1.5);
    end

    xlabel('Time (s)');
    ylabel('Distance (mm)');
    % title(sprintf('Cohort %d — per-fly avg across R1 & R2 (n=%d flies)', entryIdx, nFlies));
    title(sprintf('Condition %d', condIdx));

    xlim([0, max(t)]);
    legend off
    grid off
    box off

    ax = gca;
    ax.TickDir = "out";
    ax.TickLength = [0.02 0.02];
    ax.LineWidth = 1.2;
    ax.FontSize = 15;

    f = gcf;
    f.Position = [416   649   508   319];

end













