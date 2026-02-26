function plot_distance_to_bar_allcohorts_mean(DATA, fps, stimFrames)
%PLOT_DISTANCE_TO_BAR_ALLCOHORTS_MEAN
% Compute per-fly average across R1 & R2 for every cohort, then plot ONLY
% the grand mean ± SEM across all flies (seconds on x-axis) with stim lines.
%
%   plot_distance_to_bar_allcohorts_mean(DATA, fps, stimFrames)
%
% Inputs:
%   DATA       : struct array with .R1_condition_12/.R2_condition_12.d2bar
%   fps        : frames per second (default 30)
%   stimFrames : [on off] frame indices for vertical markers (default [300 1650])
%
% Notes:
%   - If only one rep exists in a cohort, that rep is used.
%   - If reps have different #flies, the min(#flies) is used for that cohort.
%   - Frames are NaN-padded to align within cohorts and across cohorts.
%   - Mean/SEM use 'omitnan' so unequal lengths don’t bias results.

    if nargin < 2 || isempty(fps), fps = 30; end
    if nargin < 3 || isempty(stimFrames), stimFrames = [300 1650]; end

    condNames = {'R1_condition_12','R2_condition_12'};

    % ---- Collect per-fly averages (across reps) for every cohort ----
    perFlyAvgs = {};    % each cell: [nFlies x nFrames_cohort]
    maxFramesGlobal = 0;

    for entryIdx = 1:numel(DATA)
        reps = struct('name', {}, 'd', {});
        for c = 1:numel(condNames)
            if isfield(DATA(entryIdx), condNames{c}) ...
               && isfield(DATA(entryIdx).(condNames{c}), 'd2bar') ...
               && ~isempty(DATA(entryIdx).(condNames{c}).d2bar)
                reps(end+1).name = condNames{c}; %#ok<AGROW>
                reps(end).d = DATA(entryIdx).(condNames{c}).d2bar; % [nFlies x nFrames]
            end
        end
        if isempty(reps), continue; end

        % Harmonize #flies across reps for this cohort
        nFlies_each  = arrayfun(@(r) size(r.d,1), reps);
        nFlies_cohort = min(nFlies_each);
        for k = 1:numel(reps)
            reps(k).d = reps(k).d(1:nFlies_cohort, :);
        end

        % Pad frames to the max across reps (within this cohort)
        nFrames_each = arrayfun(@(r) size(r.d,2), reps);
        maxFramesCohort = max(nFrames_each);
        for k = 1:numel(reps)
            A = reps(k).d;
            if size(A,2) < maxFramesCohort
                Apad = NaN(nFlies_cohort, maxFramesCohort);
                Apad(:,1:size(A,2)) = A;
                reps(k).d = Apad;
            end
        end

        % Per-fly average across available reps (omit NaNs)
        if numel(reps) == 1
            perFlyAvg = reps(1).d; % [nFlies x maxFramesCohort]
        else
            D = cat(3, reps.d);                % [nFlies x maxFramesCohort x nReps]
            perFlyAvg = mean(D, 3, 'omitnan'); % average across reps
        end

        perFlyAvgs{end+1} = perFlyAvg; %#ok<AGROW>
        maxFramesGlobal = max(maxFramesGlobal, size(perFlyAvg,2));
    end

    if isempty(perFlyAvgs)
        error('No d2bar data found in any cohort for R1/R2.');
    end

    % ---- Pad each cohort block to the global max #frames and stack rows ----
    for i = 1:numel(perFlyAvgs)
        A = perFlyAvgs{i};
        if size(A,2) < maxFramesGlobal
            Apad = NaN(size(A,1), maxFramesGlobal);
            Apad(:,1:size(A,2)) = A;
            perFlyAvgs{i} = Apad;
        end
    end
    ALL = vertcat(perFlyAvgs{:});  % [nAllFlies x maxFramesGlobal]

    % ---- Grand mean ± SEM across all flies ----
    grandMean = mean(ALL, 1, 'omitnan');
    grandSEM  = std(ALL, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(ALL),1));

    % ---- Time axis (seconds) ----
    t = (0:maxFramesGlobal-1) / fps;

    % ---- Plot ONLY mean ± SEM + stim lines ----
    figure('Color','w'); hold on;

    % SEM band
    fill([t, fliplr(t)], ...
         [grandMean - grandSEM, fliplr(grandMean + grandSEM)], ...
         [0.9 0.9 0.9], 'EdgeColor','none', 'FaceAlpha', 0.5);

    % Mean line
    plot(t, grandMean, 'k-', 'LineWidth', 2);

    % Stimulus markers
    for sf = stimFrames(:)'
        xline(sf / fps, '-', 'Color', [1 0.7 0.7], 'LineWidth', 1.5);
    end

    xlabel('Time (s)');
    ylabel('Distance to bar (mm)');
    title('All cohorts — per-fly avg across R1 & R2: Mean \pm SEM');
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
