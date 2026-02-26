function v = calculate_three_point_velocity(x,y)
% CALCULATE_THREE_POINT_VELOCITY Compute velocity magnitude using central differences
%
%   v = CALCULATE_THREE_POINT_VELOCITY(x, y) calculates the instantaneous
%   speed at each time point using central difference approximation.
%
% INPUTS:
%   x - 1D vector of x positions (mm) over time
%   y - 1D vector of y positions (mm) over time
%
% OUTPUT:
%   v - 1D vector of velocity magnitudes (mm/s), same length as input
%
% ALGORITHM:
%   - First point: forward difference (x(2) - x(1)) / dt
%   - Intermediate points: central difference (x(i+1) - x(i-1)) / (2*dt)
%   - Last point: backward difference (x(n) - x(n-1)) / dt
%
% PARAMETERS:
%   FPS = 30 (frames per second)
%   dt = 1/30 seconds
%
% NOTES:
%   - Returns speed magnitude, not velocity components
%   - Central difference is more accurate than forward/backward difference
%   - Output length matches input length (no edge trimming)
%
% EXAMPLE:
%   v = calculate_three_point_velocity(x_data(1,:), y_data(1,:));
%   mean_speed = mean(v);  % average walking speed
%
% See also: combine_data_one_cohort, diff 

FPS = 30;
dt = 1/FPS;

n = length(x);

% Preallocate velocity arrays
vx = zeros(size(x));
vy = zeros(size(y));

% Forward difference at the first time point
vx(1) = (x(2) - x(1)) / dt;
vy(1) = (y(2) - y(1)) / dt;

% Central difference for intermediate points
vx(2:n-1) = (x(3:n) - x(1:n-2)) / (2 * dt);
vy(2:n-1) = (y(3:n) - y(1:n-2)) / (2 * dt);

% Backward difference at the last time point
vx(n) = (x(n) - x(n-1)) / dt;
vy(n) = (y(n) - y(n-1)) / dt;

% Compute velocity magnitude (speed)
v = sqrt(vx.^2 + vy.^2);

end 
