function [pathLength2pt, minEuclideanDist, straightness] = computeTwoPointDisplacement(x, y, rng)
    % Inputs:
    % x, y - vectors of timeseries data for position
    % rng  - vector indicating the frame range, e.g., 100:500

    % Ensure x and y are column vectors
    x = x(:);
    y = y(:);

    % Extract x and y positions for the specified frame range
    x_rng = x(rng);
    y_rng = y(rng);

    % Calculate two-point displacements (between consecutive frames)
    dx = diff(x_rng);
    dy = diff(y_rng);
    displacement = sqrt(dx.^2 + dy.^2);

    % Sum of all stepwise distances is the total path length
    pathLength2pt = sum(displacement);

    % Euclidean distance between start and end points
    startPos = [x_rng(1), y_rng(1)];
    endPos = [x_rng(end), y_rng(end)];
    minEuclideanDist = norm(endPos - startPos);

    % Straightness ratio
    straightness = minEuclideanDist / pathLength2pt;

    % Edge case handling
    if isinf(straightness) || pathLength2pt < 0.1
        straightness = NaN;
    % elseif straightness > 1
    %     % Clamp to 1 if rounding or numerical issues occur
    %     straightness = 1;
    end
end
