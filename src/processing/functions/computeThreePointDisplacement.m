function [pathLength3pt, minEuclideanDist, straightness] = computeThreePointDisplacement(x, y, rng)
    % Inputs:
    % x, y - vectors of timeseries data for position
    % rng  - vector indicating the frame range, e.g., 100:500

    % Ensure x and y are column vectors
    x = x(:);
    y = y(:);

    % Extract x and y positions for the specified frame range
    x_rng = x(rng);
    y_rng = y(rng);

    % Calculate three-point displacement (from i to i+2)
    dx = x_rng(3:end) - x_rng(1:end-2);
    dy = y_rng(3:end) - y_rng(1:end-2);
    displacement = sqrt(dx.^2 + dy.^2);

    % Average over two-frame steps to get total displacement (adjusted for spacing)
    % Since each displacement spans two frames, normalize appropriately
    pathLength3pt = sum(displacement) * 0.5;

    % Calculate minimum (Euclidean) distance between start and end points
    startPos = [x_rng(1), y_rng(1)];
    endPos = [x_rng(end), y_rng(end)];
    minEuclideanDist = norm(endPos - startPos);

    straightness = minEuclideanDist/pathLength3pt;

    if isinf(straightness)
        straightness = NaN;
    elseif pathLength3pt < 0.1
        straightness = NaN;
    % elseif straightness > 1
    %     straightness = 1;
    end 
end
