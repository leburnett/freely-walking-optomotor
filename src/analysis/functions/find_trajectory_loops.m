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
%       .max_dist_center    - exclude loops with bbox centre > this distance
%                             from the arena centre in mm (default: 110)
%       .min_bbox_area      - exclude loops with bbox area < this in mm²
%                             (default: 2). Removes tiny jitter crossings.
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
%       .duration_s       - [1 x n_loops] duration in seconds
%       .bbox_area        - [1 x n_loops] bounding box area (mm²)
%       .bbox_aspect      - [1 x n_loops] bounding box aspect ratio (max/min side)
%       .bbox_center_x    - [1 x n_loops] x-coord of bounding box centre (mm)
%       .bbox_center_y    - [1 x n_loops] y-coord of bounding box centre (mm)
%       .bbox_dist_center - [1 x n_loops] distance of bbox centre from arena centre (mm)
%       .bbox_wall_dist   - [1 x n_loops] distance of bbox centre from arena wall (mm)
%       .mean_ang_diff    - [1 x n_loops] mean |angular difference| between heading
%                           and travelling direction within the loop (degrees, 0-180).
%                           Only computed over moving frames (speed > speed_threshold).
%                           Requires opts.vel to be provided; NaN otherwise.
%       .dist_from_prev   - [1 x n_loops] Euclidean distance between this loop's
%                           bbox centre and the previous loop's bbox centre (mm).
%                           NaN for the first loop in a trajectory.
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
lookahead_frames = get_opt(opts, 'lookahead_frames', 90);
min_loop_fr      = get_opt(opts, 'min_loop_frames', 5);
fps              = get_opt(opts, 'fps', 30);
arena_center     = get_opt(opts, 'arena_center', [528, 520] / 4.1691);
arena_radius     = get_opt(opts, 'arena_radius', 120);
max_dist_center  = get_opt(opts, 'max_dist_center', 110);  % exclude loops with centre > this from arena centre
min_bbox_area    = get_opt(opts, 'min_bbox_area', 0.2);       % exclude loops with area < this (mm²)
vel              = get_opt(opts, 'vel', []);                 % [1 x N] speed (mm/s); needed for angular_diff
speed_threshold  = get_opt(opts, 'speed_threshold', 0.5);   % mm/s; frames below this excluded from angular_diff
has_vel          = ~isempty(vel);

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
            loop_starts(end+1) = i; 
            loop_ends(end+1)   = j; 
            intersect_xy(end+1, :) = [px, py];

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
    loops.bbox_area = [];
    loops.bbox_aspect = [];
    loops.bbox_center_x = [];
    loops.bbox_center_y = [];
    loops.bbox_dist_center = [];
    loops.bbox_wall_dist = [];
    loops.mean_ang_diff = [];
    loops.dist_from_prev = [];
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
cum_hdg       = NaN(1, n_loops);
bbox_area     = NaN(1, n_loops);
bbox_aspect   = NaN(1, n_loops);
bbox_cx       = NaN(1, n_loops);
bbox_cy       = NaN(1, n_loops);
bbox_dist_ctr = NaN(1, n_loops);
bbox_wall     = NaN(1, n_loops);
mean_ang_diff = NaN(1, n_loops);

% Pre-compute travel direction from x, y using central differences
% (needed for angular_diff). Only computed if vel is provided.
if has_vel
    dt = 1 / fps;
    N_pts = numel(x);
    vx = NaN(1, N_pts);
    vy = NaN(1, N_pts);
    % Forward difference at first frame
    vx(1) = (x(2) - x(1)) / dt;
    vy(1) = (y(2) - y(1)) / dt;
    % Central difference for interior frames
    vx(2:N_pts-1) = (x(3:N_pts) - x(1:N_pts-2)) / (2 * dt);
    vy(2:N_pts-1) = (y(3:N_pts) - y(1:N_pts-2)) / (2 * dt);
    % Backward difference at last frame
    vx(N_pts) = (x(N_pts) - x(N_pts-1)) / dt;
    vy(N_pts) = (y(N_pts) - y(N_pts-1)) / dt;
    % Travel direction in degrees
    travel_dir = atan2d(vy, vx);
    % Heading wrapped to [0, 360)
    heading_wrap = mod(heading, 360);
end

for k = 1:n_loops
    sf = start_frames(k);
    ef = end_frames(k);

    % Cumulative heading change
    h_seg = heading(sf:ef);
    h_valid = h_seg(~isnan(h_seg));
    if numel(h_valid) >= 2
        cum_hdg(k) = h_valid(end) - h_valid(1);
    end

    % Bounding box from x, y segment
    x_seg = x(sf:ef);
    y_seg = y(sf:ef);
    x_valid = x_seg(~isnan(x_seg));
    y_valid = y_seg(~isnan(y_seg));

    if numel(x_valid) >= 2 && numel(y_valid) >= 2
        x_min = min(x_valid);  x_max = max(x_valid);
        y_min = min(y_valid);  y_max = max(y_valid);
        w = x_max - x_min;
        h = y_max - y_min;

        bbox_area(k)   = w * h;
        bbox_aspect(k) = max(w, h) / max(min(w, h), 0.01);  % avoid /0
        bbox_cx(k)     = (x_min + x_max) / 2;
        bbox_cy(k)     = (y_min + y_max) / 2;

        % Distance from arena centre
        dx = bbox_cx(k) - arena_center(1);
        dy = bbox_cy(k) - arena_center(2);
        bbox_dist_ctr(k) = sqrt(dx^2 + dy^2);
        bbox_wall(k)     = arena_radius - bbox_dist_ctr(k);
    end

    % Mean |angular difference| between heading and travel direction.
    % Only over moving frames (speed > threshold) to avoid noise when
    % the fly is stationary (travel direction is undefined at low speed).
    if has_vel
        ang_seg = mod(heading_wrap(sf:ef) - travel_dir(sf:ef) + 180, 360) - 180;
        abs_ang = abs(ang_seg);
        vel_seg = vel(sf:ef);
        moving = vel_seg >= speed_threshold & ~isnan(abs_ang);
        if sum(moving) >= 2
            mean_ang_diff(k) = mean(abs_ang(moving));
        end
    end
end

%% Quality filter: exclude loops too far from centre or too small
keep2 = (bbox_dist_ctr <= max_dist_center) & (bbox_area >= min_bbox_area);

start_frames  = start_frames(keep2);
end_frames    = end_frames(keep2);
int_x         = int_x(keep2);
int_y         = int_y(keep2);
cum_hdg       = cum_hdg(keep2);
bbox_area     = bbox_area(keep2);
bbox_aspect   = bbox_aspect(keep2);
bbox_cx       = bbox_cx(keep2);
bbox_cy       = bbox_cy(keep2);
bbox_dist_ctr = bbox_dist_ctr(keep2);
bbox_wall     = bbox_wall(keep2);
mean_ang_diff = mean_ang_diff(keep2);
n_loops       = numel(start_frames);

dur_frames = end_frames - start_frames;
dur_s = dur_frames / fps;

% Distance between consecutive loop bbox centres (NaN for the first loop)
dist_from_prev = NaN(1, n_loops);
for k = 2:n_loops
    if ~isnan(bbox_cx(k)) && ~isnan(bbox_cx(k-1))
        ddx = bbox_cx(k) - bbox_cx(k-1);
        ddy = bbox_cy(k) - bbox_cy(k-1);
        dist_from_prev(k) = sqrt(ddx^2 + ddy^2);
    end
end

%% Package output
loops.n_loops         = n_loops;
loops.start_frame     = start_frames;
loops.end_frame       = end_frames;
loops.intersect_x     = int_x;
loops.intersect_y     = int_y;
loops.cum_heading     = cum_hdg;
loops.duration_frames = dur_frames;
loops.duration_s      = dur_s;
loops.bbox_area       = bbox_area;
loops.bbox_aspect     = bbox_aspect;
loops.bbox_center_x   = bbox_cx;
loops.bbox_center_y   = bbox_cy;
loops.bbox_dist_center = bbox_dist_ctr;
loops.bbox_wall_dist  = bbox_wall;
loops.mean_ang_diff   = mean_ang_diff;
loops.dist_from_prev  = dist_from_prev;

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
