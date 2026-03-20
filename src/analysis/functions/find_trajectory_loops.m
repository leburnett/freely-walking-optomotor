function loops = find_trajectory_loops(x, y, heading, opts)
% FIND_TRAJECTORY_LOOPS  Segment a fly trajectory into loops using self-intersections.
%
%   loops = FIND_TRAJECTORY_LOOPS(x, y, heading)
%   loops = FIND_TRAJECTORY_LOOPS(x, y, heading, opts)
%
%   For each segment of the trajectory, looks FORWARD up to a specified
%   number of frames to find where the fly's future path crosses the
%   current segment. When an intersection is found, the trajectory from
%   the current frame to the crossing frame forms a closed loop. After
%   recording a loop, the search skips past it to avoid overlaps.
%
%   INPUTS:
%     x       - [1 x N] x-position (mm)
%     y       - [1 x N] y-position (mm)
%     heading - [1 x N] unwrapped heading (degrees)
%     opts    - (optional) struct with fields:
%       .lookahead_frames   - max frames to look ahead for a crossing
%                             (default: 75, i.e. 2.5s at 30fps)
%       .min_loop_frames    - minimum frames in a loop segment (default: 10)
%
%   OUTPUT:
%     loops - struct with fields:
%       .n_loops          - scalar, number of loops found
%       .start_frame      - [1 x n_loops] frame index of loop start (intersection)
%       .end_frame        - [1 x n_loops] frame index of loop end (next intersection)
%       .intersect_x      - [1 x n_loops] x-coordinate of the intersection point
%       .intersect_y      - [1 x n_loops] y-coordinate of the intersection point
%       .cum_heading      - [1 x n_loops] cumulative heading change within loop (degrees)
%       .duration_frames  - [1 x n_loops] number of frames in each loop
%       .duration_s       - [1 x n_loops] duration in seconds (assumes 30 fps)
%
%   ALGORITHM:
%     1. For each segment i→i+1, check if any future segment j→j+1
%        (where j is in [i+2, i+lookahead_frames]) crosses it
%     2. If a crossing is found, record the loop from frame i to frame j
%     3. Skip past frame j to avoid overlapping loop detections
%     4. Continue searching from frame j+1
%
%   See also: temp_loop_segmentation_gui

%% Parse options
if nargin < 4, opts = struct(); end
lookahead_frames = get_opt(opts, 'lookahead_frames', 75);
min_loop_fr      = get_opt(opts, 'min_loop_frames', 10);
fps              = get_opt(opts, 'fps', 30);

N = numel(x);

%% Find loops by looking FORWARD for self-intersections
%
% For each segment i→i+1, check if any future segment j→j+1 (within
% lookahead_frames) crosses it. If so, the trajectory from frame i to
% frame j forms a closed loop. After finding a loop, skip past frame j
% to avoid overlapping detections.

loop_starts = [];
loop_ends   = [];
intersect_xy = [];    % [n x 2] intersection coordinates

i = 1;
while i <= (N - 2)
    % Skip NaN frames
    if isnan(x(i)) || isnan(x(i+1)) || isnan(y(i)) || isnan(y(i+1))
        i = i + 1;
        continue;
    end

    % Look forward: check if any future segment crosses segment i→i+1
    j_end = min(N - 1, i + lookahead_frames);
    % Skip adjacent segment (shares endpoint at i+1)
    j_start = i + 2;

    found = false;
    for j = j_start:j_end
        if isnan(x(j)) || isnan(x(j+1)) || isnan(y(j)) || isnan(y(j+1))
            continue;
        end

        [does_intersect, px, py] = segment_intersect( ...
            x(i), y(i), x(i+1), y(i+1), ...
            x(j), y(j), x(j+1), y(j+1));

        if does_intersect
            % Loop found: trajectory from frame i to frame j
            loop_starts(end+1) = i; %#ok<AGROW>
            loop_ends(end+1)   = j; %#ok<AGROW>
            intersect_xy(end+1, :) = [px, py]; %#ok<AGROW>

            % Skip past this loop to avoid overlapping detections
            i = j + 1;
            found = true;
            break;
        end
    end

    if ~found
        i = i + 1;
    end
end

%% Package loops
n_raw = numel(loop_starts);

if n_raw == 0
    loops.n_loops = 0;
    loops.start_frame = [];
    loops.end_frame = [];
    loops.intersect_x = [];
    loops.intersect_y = [];
    loops.cum_heading = [];
    loops.duration_frames = [];
    loops.duration_s = [];
    return;
end

% Filter by minimum duration
dur_raw = loop_ends - loop_starts;
keep = dur_raw >= min_loop_fr;
start_frames = loop_starts(keep);
end_frames   = loop_ends(keep);
int_x = intersect_xy(keep, 1)';
int_y = intersect_xy(keep, 2)';

n_loops = numel(start_frames);

% Compute per-loop metrics
cum_hdg = NaN(1, n_loops);
for k = 1:n_loops
    sf = start_frames(k);
    ef = end_frames(k);
    h_seg = heading(sf:ef);
    h_valid = h_seg(~isnan(h_seg));
    if numel(h_valid) >= 2
        cum_hdg(k) = h_valid(end) - h_valid(1);
    end
end

dur_frames = end_frames - start_frames;
dur_s = dur_frames / fps;

%% Package output
loops.n_loops         = n_loops;
loops.start_frame     = start_frames;
loops.end_frame       = end_frames;
loops.intersect_x     = int_x;
loops.intersect_y     = int_y;
loops.cum_heading     = cum_hdg;
loops.duration_frames = dur_frames;
loops.duration_s      = dur_s;

end

%% ===== Helper: line segment intersection =====
function [does_intersect, px, py] = segment_intersect(x1, y1, x2, y2, x3, y3, x4, y4)
% Check if segment (x1,y1)-(x2,y2) intersects segment (x3,y3)-(x4,y4).
% Returns the intersection point (px, py) if found.
% Uses the parametric method: find t and u such that
%   P = (x1,y1) + t*(x2-x1, y2-y1)
%   P = (x3,y3) + u*(x4-x3, y4-y3)
% Intersection exists iff 0 <= t <= 1 and 0 <= u <= 1.

does_intersect = false;
px = NaN; py = NaN;

dx1 = x2 - x1;  dy1 = y2 - y1;
dx2 = x4 - x3;  dy2 = y4 - y3;

denom = dx1 * dy2 - dy1 * dx2;
if abs(denom) < 1e-12
    return;  % parallel or coincident
end

t = ((x3 - x1) * dy2 - (y3 - y1) * dx2) / denom;
u = ((x3 - x1) * dy1 - (y3 - y1) * dx1) / denom;

if t >= 0 && t <= 1 && u >= 0 && u <= 1
    does_intersect = true;
    px = x1 + t * dx1;
    py = y1 + t * dy1;
end

end

%% ===== Helper: option parsing =====
function val = get_opt(s, field, default)
if isfield(s, field)
    val = s.(field);
else
    val = default;
end
end
