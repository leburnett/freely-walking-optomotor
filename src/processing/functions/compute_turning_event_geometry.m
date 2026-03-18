function geom = compute_turning_event_geometry(events, x_data, y_data, arena_radius)
% COMPUTE_TURNING_EVENT_GEOMETRY  Bounding box and spatial metrics for turning events.
%
%   geom = COMPUTE_TURNING_EVENT_GEOMETRY(events, x_data, y_data, arena_radius)
%
%   For each detected 360-degree turning event, computes the bounding box
%   of the trajectory segment, its area, aspect ratio, centre of mass, and
%   the distance of that centre from the arena wall.
%
%   INPUTS:
%     events       - struct from detect_360_turning_events for ONE fly,
%                    with fields: start_frame, end_frame, n_events
%     x_data       - [1 x n_frames] x position (mm) for this fly
%     y_data       - [1 x n_frames] y position (mm) for this fly
%     arena_radius - scalar, arena radius in mm
%
%   OUTPUT:
%     geom - struct with fields, each [1 x n_events]:
%       .bbox_width       - bounding box width (mm)
%       .bbox_height      - bounding box height (mm)
%       .bbox_area        - bounding box area (mm^2)
%       .bbox_aspect      - aspect ratio (max_side / min_side), >= 1
%       .bbox_center_x    - x coordinate of bounding box centre (mm)
%       .bbox_center_y    - y coordinate of bounding box centre (mm)
%       .wall_dist_center - distance from bbox centre to wall (mm)
%       .path_length      - total path length during the turn (mm)
%
%   EXAMPLE:
%     geom = compute_turning_event_geometry(events(1), x(1,:), y(1,:), 119);
%
% See also: detect_360_turning_events

n_events = events.n_events;

% Pre-allocate
geom.bbox_width       = NaN(1, n_events);
geom.bbox_height      = NaN(1, n_events);
geom.bbox_area        = NaN(1, n_events);
geom.bbox_aspect      = NaN(1, n_events);
geom.bbox_center_x    = NaN(1, n_events);
geom.bbox_center_y    = NaN(1, n_events);
geom.wall_dist_center = NaN(1, n_events);
geom.path_length      = NaN(1, n_events);

for e = 1:n_events
    sf = events.start_frame(e);
    ef = events.end_frame(e);

    % Clamp to data bounds
    sf = max(sf, 1);
    ef = min(ef, numel(x_data));

    x_seg = x_data(sf:ef);
    y_seg = y_data(sf:ef);

    % Remove NaN frames within segment
    valid = ~isnan(x_seg) & ~isnan(y_seg);
    x_seg = x_seg(valid);
    y_seg = y_seg(valid);

    if numel(x_seg) < 3
        continue;
    end

    % Bounding box
    x_min = min(x_seg);
    x_max = max(x_seg);
    y_min = min(y_seg);
    y_max = max(y_seg);

    w = x_max - x_min;
    h = y_max - y_min;

    geom.bbox_width(e)  = w;
    geom.bbox_height(e) = h;
    geom.bbox_area(e)   = w * h;

    % Aspect ratio (max / min, always >= 1)
    sides = sort([w, h]);
    if sides(1) > 1e-3
        geom.bbox_aspect(e) = sides(2) / sides(1);
    else
        geom.bbox_aspect(e) = NaN;  % degenerate (nearly 1D path)
    end

    % Centre of bounding box
    cx = (x_min + x_max) / 2;
    cy = (y_min + y_max) / 2;
    geom.bbox_center_x(e) = cx;
    geom.bbox_center_y(e) = cy;

    % Distance from bbox centre to wall (arena center at origin)
    dist_from_center = sqrt(cx^2 + cy^2);
    geom.wall_dist_center(e) = arena_radius - dist_from_center;

    % Path length
    dx = diff(x_seg);
    dy = diff(y_seg);
    geom.path_length(e) = sum(sqrt(dx.^2 + dy.^2));
end

end
