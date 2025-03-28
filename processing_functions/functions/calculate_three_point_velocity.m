function v = calculate_three_point_velocity(x,y)
% This function calculates the three point velocity/displacement over time.

% It computes the forward velocity for the first time point and the
% backwards velocity for the last time point to ensure 'v' has the same
% number of datapoints as 'x' and 'y'. 

% 'x' and 'y' are 1D vectors of the x and y position of the fly over time. 

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
