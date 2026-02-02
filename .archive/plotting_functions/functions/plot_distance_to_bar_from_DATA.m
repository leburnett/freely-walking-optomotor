function plot_distance_to_bar_from_DATA(DATA, entryIdx, condName, fps)
%PLOT_DISTANCE_TO_BAR  Plot per-fly and mean distance to bar stimulus (in seconds).
%
%   plot_distance_to_bar(DATA, entryIdx, condName, fps)
%
%   Inputs:
%       DATA      - main struct array
%       entryIdx  - index of cohort to plot (e.g., 8)
%       condName  - condition field name string, e.g. 'R1_condition_12'
%       fps       - frames per second (default = 30)
%
%   Behavior:
%       - Plots each fly's distance (d2bar) trace in light gray.
%       - Overlays the mean ± SEM and mean (black line).
%       - x-axis is in seconds.
%       - Adds red vertical lines at stimulus on/off frames (300 & 1650).

    if nargin < 4 || isempty(fps)
        fps = 30;  % default 30 frames per second
    end

    % --- Extract data ---
    if entryIdx > numel(DATA) || ~isfield(DATA(entryIdx), condName)
        error('Invalid entryIdx or condition name.');
    end
    S = DATA(entryIdx).(condName);

    if ~isfield(S, 'd2bar') || isempty(S.d2bar)
        error('Field "d2bar" not found for this condition.');
    end

    d = S.d2bar;       % [nFlies x nFrames]
    nFlies  = size(d,1);
    nFrames = size(d,2);
    time_s  = (0:nFrames-1) / fps;  % convert to seconds

    % --- Compute mean and SEM ---
    mean_d = mean(d, 1, 'omitnan');
    sem_d  = std(d, 0, 1, 'omitnan') ./ sqrt(sum(~isnan(d),1));

    % --- Plot ---
    figure('Color','w'); hold on;

    % Individual fly traces (light gray)
    plot(time_s, d', 'Color', [0.8 0.8 0.8], 'LineWidth', 0.5);

    % Mean ± SEM shaded area
    fill([time_s, fliplr(time_s)], ...
         [mean_d - sem_d, fliplr(mean_d + sem_d)], ...
         [0.9 0.9 0.9], 'EdgeColor','none', 'FaceAlpha', 0.4);

    % Mean line (black)
    plot(time_s, mean_d, 'k-', 'LineWidth', 1.5);

    % --- Stimulus markers (frames → seconds) ---
    stimFrames = [300, 1650];
    stimTimes  = stimFrames / fps;
    for s = stimTimes
        xline(s, '-', 'Color', [1 0.7 0.7], 'LineWidth', 1.5);
    end

    % --- Formatting ---
    xlabel('Time (s)');
    ylabel('Distance to bar (mm)');
    title(sprintf('%s — Cohort %d', strrep(condName,'_','\_'), entryIdx));
    xlim([0 max(time_s)]);

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













