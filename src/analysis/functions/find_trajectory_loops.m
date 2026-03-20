function loops = find_trajectory_loops(x, y, heading, opts)
% FIND_TRAJECTORY_LOOPS  Segment a fly trajectory into loops using self-intersections.
%
%   loops = FIND_TRAJECTORY_LOOPS(x, y, heading)
%   loops = FIND_TRAJECTORY_LOOPS(x, y, heading, opts)
%
%   Walks along the trajectory looking for self-intersections (where the
%   path crosses itself). After each intersection is found, the next
%   intersection is suppressed until the fly's cumulative heading change
%   has reached 360 degrees. This segments the trajectory into loops
%   corresponding to full turns.
%
%   INPUTS:
%     x       - [1 x N] x-position (mm)
%     y       - [1 x N] y-position (mm)
%     heading - [1 x N] unwrapped heading (degrees)
%     opts    - (optional) struct with fields:
%       .heading_threshold  - cumulative heading change required before
%                             allowing the next intersection (default: 360)
%       .min_loop_frames    - minimum frames in a loop segment (default: 10)
%       .lookback_limit     - max frames to look back for intersections.
%                             Reduces computation for long trajectories.
%                             (default: Inf = check all previous segments)
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
%     1. Walk frame by frame along the trajectory
%     2. For each segment (frame i to i+1), check if it intersects any
%        previous segment (frame j to j+1, j < i)
%     3. When an intersection is found, record it as a loop boundary
%     4. After recording, require |cumulative heading change| >= 360 deg
%        from this frame before allowing the next intersection
%     5. This prevents tiny crossings from fragmenting the trajectory
%
%   See also: temp_loop_segmentation_gui

%% Parse options
if nargin < 4, opts = struct(); end
heading_thr    = get_opt(opts, 'heading_threshold', 360);
min_loop_fr    = get_opt(opts, 'min_loop_frames', 10);
lookback_limit = get_opt(opts, 'lookback_limit', Inf);
fps            = get_opt(opts, 'fps', 30);

N = numel(x);

%% Find intersection-based loop boundaries
boundaries = [];      % frame indices where intersections occur
intersect_xy = [];    % [n x 2] intersection coordinates

% State machine
searching = true;         % true = looking for intersections
cum_heading_since = 0;    % cumulative heading change since last intersection
last_boundary_frame = 1;  % frame of the last intersection

for i = 2:(N-1)
    % Skip NaN frames
    if isnan(x(i)) || isnan(x(i+1)) || isnan(y(i)) || isnan(y(i+1))
        continue;
    end

    if ~searching
        % Accumulate heading change until we reach the threshold
        if ~isnan(heading(i)) && ~isnan(heading(i-1))
            cum_heading_since = cum_heading_since + abs(heading(i) - heading(i-1));
        end
        if cum_heading_since >= heading_thr
            searching = true;
        else
            continue;
        end
    end

    % Current segment: (x(i), y(i)) -> (x(i+1), y(i+1))
    % Check against previous segments for intersection
    j_start = max(1, i - lookback_limit);
    % Don't check the immediately adjacent segment (shares an endpoint)
    j_end = i - 2;

    % Also don't check segments before the last boundary (we only care
    % about the current "open" path crossing itself)
    j_start = max(j_start, last_boundary_frame);

    found = false;
    for j = j_end:-1:j_start
        if isnan(x(j)) || isnan(x(j+1)) || isnan(y(j)) || isnan(y(j+1))
            continue;
        end

        [does_intersect, px, py] = segment_intersect( ...
            x(j), y(j), x(j+1), y(j+1), ...
            x(i), y(i), x(i+1), y(i+1));

        if does_intersect
            % Record this intersection as a boundary
            boundaries(end+1) = i; %#ok<AGROW>
            intersect_xy(end+1, :) = [px, py]; %#ok<AGROW>

            % Reset state: stop searching until heading threshold met
            searching = false;
            cum_heading_since = 0;
            last_boundary_frame = i;
            found = true;
            break;  % only need the first (most recent) intersection
        end
    end
end

%% Build loop segments from consecutive boundaries
n_boundaries = numel(boundaries);

if n_boundaries < 2
    % Not enough intersections to form a loop
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

% Each loop is the segment between consecutive intersection points
start_frames = boundaries(1:end-1);
end_frames   = boundaries(2:end);
n_raw = numel(start_frames);

% Filter by minimum duration
keep = (end_frames - start_frames) >= min_loop_fr;
start_frames = start_frames(keep);
end_frames   = end_frames(keep);
int_x = intersect_xy(find(keep), 1)'; %#ok — start intersection
int_y = intersect_xy(find(keep), 2)';

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
