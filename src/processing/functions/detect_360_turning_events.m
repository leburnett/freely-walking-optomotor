function events = detect_360_turning_events(heading_data, av_data, fps, opts)
% DETECT_360_TURNING_EVENTS  Find 360-degree turning events gated by angular velocity.
%
%   events = DETECT_360_TURNING_EVENTS(heading_data, av_data, fps, opts)
%
%   Detects discrete turning events defined as periods during which a fly
%   is actively turning (|AV| above threshold) and accumulates 360 degrees
%   of net heading change.
%
%   Algorithm:
%     1. Find frames where |AV| exceeds av_threshold
%     2. Group consecutive above-threshold frames into turning bouts
%        (bouts separated by <= merge_gap frames are merged)
%     3. Discard bouts shorter than min_bout_frames
%     4. Within each bout, accumulate signed heading change. When the net
%        cumulative heading reaches ±heading_target degrees, record an event
%        and reset the accumulator for the next event within that bout.
%     5. Discard events whose duration exceeds max_duration_s (removes
%        long meandering bouts that happen to accumulate 360 degrees)
%
%   INPUTS:
%     heading_data - [n_flies x n_frames] UNWRAPPED heading (degrees).
%     av_data      - [n_flies x n_frames] angular velocity (deg/s).
%     fps          - scalar, frames per second (for duration computation)
%     opts         - (optional) struct with fields:
%       .av_threshold    - |AV| threshold in deg/s (default: 75)
%       .merge_gap       - max gap frames to merge adjacent bouts (default: 3)
%       .min_bout_frames - minimum frames in a bout to consider (default: 3)
%       .heading_target  - cumulative heading for one "turn" (default: 360)
%       .max_duration_s  - maximum event duration in seconds (default: 5)
%
%   OUTPUT:
%     events - struct array of size [n_flies x 1], each element with:
%       .start_frame   - [1 x n_events] frame where each turn begins
%       .end_frame     - [1 x n_events] frame where cumulative crosses target
%       .direction     - [1 x n_events] +1 (CCW) or -1 (CW)
%       .duration_s    - [1 x n_events] duration of each event in seconds
%       .peak_av       - [1 x n_events] peak |AV| during each event (deg/s)
%       .mean_av       - [1 x n_events] mean |AV| during each event (deg/s)
%       .cum_heading   - [1 x n_events] total heading change (may exceed target)
%       .n_events      - scalar, total number of turning events for this fly
%       .av_threshold  - scalar, threshold used (for reference)
%
%   EXAMPLE:
%     opts.av_threshold = 90;
%     opts.max_duration_s = 5;
%     events = detect_360_turning_events(heading(:,300:750), av(:,300:750), 30, opts);
%     fprintf('Fly 1 made %d turns\n', events(1).n_events);
%
% See also: compute_turning_event_geometry

%% Parse options
if nargin < 4 || isempty(opts), opts = struct(); end
av_threshold    = get_opt(opts, 'av_threshold', 75);
merge_gap       = get_opt(opts, 'merge_gap', 3);
min_bout_frames = get_opt(opts, 'min_bout_frames', 3);
heading_target  = get_opt(opts, 'heading_target', 360);
max_duration_s  = get_opt(opts, 'max_duration_s', 5);

max_duration_frames = round(max_duration_s * fps);

n_flies = size(heading_data, 1);
events = struct('start_frame', {}, 'end_frame', {}, 'direction', {}, ...
                'duration_s', {}, 'peak_av', {}, 'mean_av', {}, ...
                'cum_heading', {}, 'n_events', {}, 'av_threshold', {});

for f = 1:n_flies
    heading_f = heading_data(f, :);
    av_f      = av_data(f, :);
    n_frames  = numel(heading_f);

    %% Step 1: Identify above-threshold frames
    above = abs(av_f) > av_threshold;
    above(isnan(av_f) | isnan(heading_f)) = false;

    %% Step 2: Find contiguous bouts and merge small gaps
    d = diff([0, above, 0]);
    bout_starts = find(d == 1);
    bout_ends   = find(d == -1) - 1;

    % Merge bouts separated by <= merge_gap frames
    if numel(bout_starts) > 1
        merged_starts = bout_starts(1);
        merged_ends   = bout_ends(1);
        for b = 2:numel(bout_starts)
            gap = bout_starts(b) - merged_ends(end);
            if gap <= merge_gap
                merged_ends(end) = bout_ends(b);
            else
                merged_starts(end+1) = bout_starts(b); %#ok<AGROW>
                merged_ends(end+1)   = bout_ends(b);   %#ok<AGROW>
            end
        end
        bout_starts = merged_starts;
        bout_ends   = merged_ends;
    end

    %% Step 3: Within each bout, accumulate heading and find 360-degree crossings
    start_frames = [];
    end_frames   = [];
    directions   = [];
    peak_avs     = [];
    mean_avs     = [];
    cum_headings = [];

    for b = 1:numel(bout_starts)
        bs = bout_starts(b);
        be = bout_ends(b);

        % Skip short bouts
        if (be - bs + 1) < min_bout_frames
            continue;
        end

        % Frame-to-frame heading changes within this bout
        heading_bout = heading_f(bs:be);
        delta_h = diff(heading_bout);

        % Walk through the bout accumulating signed heading change.
        % No direction-reversal reset — small counter-wobbles are normal
        % during a genuine turn. The AV threshold already ensures the fly
        % is actively turning; the net heading accumulation captures the
        % dominant rotation direction.
        cumulative = 0;
        event_start = bs;  % in full-timeseries frame indices

        for i = 1:numel(delta_h)
            if isnan(delta_h(i))
                % Reset on NaN
                cumulative = 0;
                event_start = bs + i;
                continue;
            end

            cumulative = cumulative + delta_h(i);

            if abs(cumulative) >= heading_target
                event_end = bs + i;  % +1 offset from diff

                % Compute stats for this event
                seg_range = event_start:min(event_end, be);
                av_seg = abs(av_f(seg_range));

                start_frames(end+1) = event_start;       %#ok<AGROW>
                end_frames(end+1)   = event_end;          %#ok<AGROW>
                directions(end+1)   = sign(cumulative);   %#ok<AGROW>
                peak_avs(end+1)     = max(av_seg);        %#ok<AGROW>
                mean_avs(end+1)     = nanmean(av_seg);    %#ok<AGROW>
                cum_headings(end+1) = cumulative;         %#ok<AGROW>

                % Reset for next event within this bout
                cumulative = 0;
                event_start = event_end;
            end
        end
    end

    %% Step 4: Filter by maximum duration
    if ~isempty(start_frames)
        durations_frames = end_frames - start_frames;
        keep = durations_frames <= max_duration_frames;

        start_frames = start_frames(keep);
        end_frames   = end_frames(keep);
        directions   = directions(keep);
        peak_avs     = peak_avs(keep);
        mean_avs     = mean_avs(keep);
        cum_headings = cum_headings(keep);
    end

    %% Package results for this fly
    events(f).start_frame  = start_frames;
    events(f).end_frame    = end_frames;
    events(f).direction    = directions;
    events(f).duration_s   = (end_frames - start_frames) / fps;
    events(f).peak_av      = peak_avs;
    events(f).mean_av      = mean_avs;
    events(f).cum_heading  = cum_headings;
    events(f).n_events     = numel(start_frames);
    events(f).av_threshold = av_threshold;
end

end

%% Helper
function val = get_opt(s, field, default)
    if isfield(s, field)
        val = s.(field);
    else
        val = default;
    end
end
