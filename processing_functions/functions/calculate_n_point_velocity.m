function v = calculate_n_point_velocity(x, y, n_points)
% This function calculates the n-point velocity/displacement over time.
% The velocity is computed using central differences where possible,
% and forward/backward differences at the boundaries.
% 
% Inputs:
%   x, y - 1D vectors of the x and y positions of the fly over time.
%   n_points - Number of points to use for velocity calculation (must be odd).
% 
% Output:
%   v - Velocity magnitude over time.

FPS = 30;
dt = 1 / FPS;

n = length(x);
mid = floor(n_points / 2);

% Preallocate velocity arrays
vx = zeros(size(x));
vy = zeros(size(y));

% Forward difference for the first mid points
for i = 1:mid
    vx(i) = (x(i + mid) - x(i)) / (mid * dt);
    vy(i) = (y(i + mid) - y(i)) / (mid * dt);
end

% Central difference for intermediate points
for i = mid+1:n-mid
    vx(i) = (x(i + mid) - x(i - mid)) / (2 * mid * dt);
    vy(i) = (y(i + mid) - y(i - mid)) / (2 * mid * dt);
end

% Backward difference for the last mid points
for i = n-mid+1:n
    vx(i) = (x(i) - x(i - mid)) / (mid * dt);
    vy(i) = (y(i) - y(i - mid)) / (mid * dt);
end

% Compute velocity magnitude (speed)
v = sqrt(vx.^2 + vy.^2);

end
