function events = detect_360_turning_events(heading_data, fps)
% DETECT_360_TURNING_EVENTS  Find 360-degree turning events in heading timeseries.
%
%   events = DETECT_360_TURNING_EVENTS(heading_data, fps)
%
%   Detects discrete turning events defined as periods during which a fly
%   accumulates 360 degrees of heading change. Uses unwrapped heading data
%   to avoid artefacts from the 0/360 boundary.
%
%   Algorithm:
%     1. Compute frame-to-frame heading changes (diff)
%     2. Track cumulative heading change from a reset point
%     3. When |cumulative| >= 360, record one turning event and reset
%     4. The direction of the event is the sign of the cumulative change
%
%   INPUTS:
%     heading_data - [n_flies x n_frames] UNWRAPPED heading (degrees).
%                    Use heading_data (not heading_wrap) from the DATA struct.
%     fps          - scalar, frames per second (for duration computation)
%
%   OUTPUT:
%     events - struct array of size [n_flies x 1], each element with:
%       .start_frame - [1 x n_events] frame index where each turn begins
%       .end_frame   - [1 x n_events] frame index where cumulative crosses 360
%       .direction   - [1 x n_events] +1 for CCW heading increase, -1 for CW
%       .duration_s  - [1 x n_events] duration of each event in seconds
%       .n_events    - scalar, total number of turning events for this fly
%
%   EXAMPLE:
%     events = detect_360_turning_events(heading_data(:, 300:750), 30);
%     fprintf('Fly 1 made %d turns\n', events(1).n_events);
%
% See also: compute_turning_event_geometry

n_flies = size(heading_data, 1);
events = struct('start_frame', {}, 'end_frame', {}, 'direction', {}, ...
                'duration_s', {}, 'n_events', {});

for f = 1:n_flies
    heading_f = heading_data(f, :);
    n_frames = numel(heading_f);

    % Frame-to-frame heading change (using unwrapped heading, so no wrap correction needed)
    delta_h = diff(heading_f);

    % Track cumulative heading and detect 360-degree crossings
    start_frames = [];
    end_frames   = [];
    directions   = [];

    cumulative = 0;
    reset_frame = 1;

    for i = 1:numel(delta_h)
        % Skip NaN frames
        if isnan(delta_h(i))
            % Reset on NaN gap
            cumulative = 0;
            reset_frame = i + 1;
            continue;
        end

        cumulative = cumulative + delta_h(i);

        if abs(cumulative) >= 360
            % Record event
            start_frames(end+1) = reset_frame; %#ok<AGROW>
            end_frames(end+1)   = i + 1;       %#ok<AGROW>  (+1 because delta is offset by 1)
            directions(end+1)   = sign(cumulative); %#ok<AGROW>

            % Reset for next event
            cumulative = 0;
            reset_frame = i + 1;
        end
    end

    % Package results for this fly
    events(f).start_frame = start_frames;
    events(f).end_frame   = end_frames;
    events(f).direction   = directions;
    events(f).duration_s  = (end_frames - start_frames) / fps;
    events(f).n_events    = numel(start_frames);
end

end
