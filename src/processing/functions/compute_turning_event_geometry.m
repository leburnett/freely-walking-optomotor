function geom = compute_turning_event_geometry(events, x_data, y_data, arena_radius, arena_center)
% COMPUTE_TURNING_EVENT_GEOMETRY  Bounding box and spatial metrics for turning events.
%
%   geom = COMPUTE_TURNING_EVENT_GEOMETRY(events, x_data, y_data, arena_radius, arena_center)
%
%   For each detected 360-degree turning event, computes the bounding box
%   of the trajectory segment, its area, aspect ratio, centre of mass, and
%   the distance of that centre from the arena centre.
%
%   INPUTS:
%     events       - struct from detect_360_turning_events for ONE fly,
%                    with fields: start_frame, end_frame, n_events
%     x_data       - [1 x n_frames] x position (mm) for this fly
%     y_data       - [1 x n_frames] y position (mm) for this fly
%     arena_radius - scalar, arena radius in mm
%     arena_center - [1 x 2] arena centre in mm (default: [528, 520]/4.1691)
%
%   OUTPUT:
%     geom - struct with fields, each [1 x n_events]:
%       .bbox_width       - bounding box width (mm)
%       .bbox_height      - bounding box height (mm)
%       .bbox_area        - bounding box area (mm^2)
%       .bbox_aspect      - aspect ratio (max_side / min_side), >= 1
%       .bbox_center_x    - x coordinate of bounding box centre (mm)
%       .bbox_center_y    - y coordinate of bounding box centre (mm)
%       .centre_dist      - distance from bbox centre to arena centre (mm)
%       .path_length      - total path length during the turn (mm)
%       .mean_x           - mean x position (trajectory centroid, mm)
%       .mean_y           - mean y position (trajectory centroid, mm)
%       .compactness      - path_length / bbox_perimeter (higher = more compact turn)
%
%   EXAMPLE:
%     geom = compute_turning_event_geometry(events(1), x(1,:), y(1,:), 120, [126.6, 124.7]);
%
% See also: detect_360_turning_events

if nargin < 5 || isempty(arena_center)
    arena_center = [528, 520] / 4.1691;
end

n_events = events.n_events;

% Pre-allocate
field_names = {'bbox_width', 'bbox_height', 'bbox_area', 'bbox_aspect', ...
    'bbox_center_x', 'bbox_center_y', 'centre_dist', 'path_length', ...
    'mean_x', 'mean_y', 'compactness'};
for fn = 1:numel(field_names)
    geom.(field_names{fn}) = NaN(1, n_events);
end

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
    if sides(1) > 0.5  % at least 0.5 mm on shortest side
        geom.bbox_aspect(e) = sides(2) / sides(1);
    else
        geom.bbox_aspect(e) = NaN;  % degenerate (nearly 1D path)
    end

    % Centre of bounding box
    cx = (x_min + x_max) / 2;
    cy = (y_min + y_max) / 2;
    geom.bbox_center_x(e) = cx;
    geom.bbox_center_y(e) = cy;

    % Trajectory centroid (mean position)
    geom.mean_x(e) = mean(x_seg);
    geom.mean_y(e) = mean(y_seg);

    % Distance from bbox centre to arena centre
    geom.centre_dist(e) = sqrt((cx - arena_center(1))^2 + (cy - arena_center(2))^2);

    % Path length
    dx = diff(x_seg);
    dy = diff(y_seg);
    geom.path_length(e) = sum(sqrt(dx.^2 + dy.^2));

    % Compactness: path_length / bbox_perimeter
    % A tight circle will have compactness >> 1 (long path, small box)
    % A long arc will have compactness ~ 1 (path ~ perimeter)
    bbox_perim = 2 * (w + h);
    if bbox_perim > 1e-3
        geom.compactness(e) = geom.path_length(e) / bbox_perim;
    end
end

end
