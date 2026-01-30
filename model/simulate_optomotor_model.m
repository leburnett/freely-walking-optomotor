function [trajectory, params] = simulate_optomotor_model(params)
% SIMULATE_OPTOMOTOR_MODEL Simulates fly walking in circular arena with
% optomotor response modulated by viewing distance.
%
% This model simulates a fly's movement in a cylindrical arena where moving
% gratings are presented. The key mechanism is:
%   - The fly exhibits an optomotor response (turning with the gratings)
%   - This turning response is stronger when the fly is closer to the arena
%     wall (shorter viewing distance) due to higher perceived angular velocity
%   - This distance-dependent turning creates a statistical bias towards the
%     arena centre: wall-approaching trajectories are cut short by increased
%     turning, while centre-approaching trajectories persist longer.
%
% USAGE:
%   [trajectory, params] = simulate_optomotor_model()          % Use defaults
%   [trajectory, params] = simulate_optomotor_model(params)    % Custom params
%
% INPUT:
%   params (struct, optional) - Simulation parameters. Missing fields use
%                               defaults. Fields:
%
%     Timing:
%       .T              - Duration in seconds (default: 30)
%       .fps            - Frames per second (default: 30)
%
%     Arena:
%       .arena_radius   - Arena radius in mm (default: 120.5)
%
%     Initial conditions:
%       .x0             - Initial x position, or 'random' (default: -90)
%       .y0             - Initial y position, or 'random' (default: 'random')
%       .y0_range       - Range for random y0: [min, max] (default: [-60, 60])
%       .theta0         - Initial heading in rad, or 'random' (default: 'random')
%       .seed           - Random seed for reproducibility (default: [], no seed)
%
%     Optomotor response:
%       .base_bias      - Base turning bias from grating motion (default: 0.1)
%                         This represents the strength of the optomotor response
%                         and would correspond to grating speed in experiments.
%       .grating_dir    - Grating direction: 1 (CW) or -1 (CCW) (default: 1)
%
%     Distance-dependent modulation:
%       .k_dist         - Gain for distance-dependent turning (default: 2.0)
%       .d0             - Distance at half-maximal turning in mm (default: 90)
%       .b              - Sigmoid slope/steepness (default: 0.02)
%       .min_dist       - Minimum viewing distance for turning (default: 20)
%
%     Movement:
%       .v_max          - Maximum forward speed in mm/s (default: 20)
%       .alpha          - Speed sensitivity to turning (default: 7)
%       .brownian_amp   - Brownian noise amplitude divisor (default: 1.2)
%                         Higher values = less noise
%
% OUTPUT:
%   trajectory (struct) - Simulation results with fields:
%       .time_s         - Time vector in seconds
%       .x_mm           - X position trajectory in mm
%       .y_mm           - Y position trajectory in mm
%       .heading_rad    - Heading angle trajectory in radians [-pi, pi]
%       .speed_mm_s     - Instantaneous speed in mm/s
%       .gain           - Distance-dependent gain value
%       .viewing_dist_mm- Viewing distance to arena wall in mm
%
%   params (struct) - Complete parameters used (with defaults filled in)
%
% EXAMPLE:
%   % Run with default parameters
%   [traj, p] = simulate_optomotor_model();
%   plot(traj.x_mm, traj.y_mm);
%
%   % Compare CW vs CCW gratings
%   p1 = struct('grating_dir', 1, 'seed', 42);
%   p2 = struct('grating_dir', -1, 'seed', 42);
%   [traj1, ~] = simulate_optomotor_model(p1);
%   [traj2, ~] = simulate_optomotor_model(p2);
%
% See also: simulate_walking_viewdist_gain (legacy function)

    %% Set default parameters
    defaults = struct( ...
        'T', 30, ...
        'fps', 30, ...
        'arena_radius', 120.5, ...
        'x0', -90, ...
        'y0', 'random', ...
        'y0_range', [-60, 60], ...
        'theta0', 'random', ...
        'seed', [], ...
        'base_bias', 0.1, ...
        'grating_dir', 1, ...
        'k_dist', 2.0, ...
        'd0', 90, ...
        'b', 0.02, ...
        'min_dist', 20, ...
        'v_max', 20, ...
        'alpha', 7, ...
        'brownian_amp', 1.2 ...
    );

    % Merge user params with defaults
    if nargin < 1 || isempty(params)
        params = defaults;
    else
        fnames = fieldnames(defaults);
        for i = 1:length(fnames)
            if ~isfield(params, fnames{i})
                params.(fnames{i}) = defaults.(fnames{i});
            end
        end
    end

    %% Set random seed if specified
    if ~isempty(params.seed)
        rng(params.seed);
    end

    %% Initialize time and arrays
    dt = 1 / params.fps;
    time_steps = 0:dt:params.T;
    n_steps = length(time_steps);

    % Preallocate trajectory arrays
    x_traj = zeros(1, n_steps);
    y_traj = zeros(1, n_steps);
    theta_traj = zeros(1, n_steps);
    v_traj = zeros(1, n_steps);
    g_traj = zeros(1, n_steps);
    vd_traj = zeros(1, n_steps);

    %% Set initial conditions
    if ischar(params.x0) && strcmp(params.x0, 'random')
        x = (rand() * 2 - 1) * params.arena_radius * 0.8;  % Random within 80% of radius
    else
        x = params.x0;
    end

    if ischar(params.y0) && strcmp(params.y0, 'random')
        y = params.y0_range(1) + rand() * (params.y0_range(2) - params.y0_range(1));
    else
        y = params.y0;
    end

    if ischar(params.theta0) && strcmp(params.theta0, 'random')
        theta = rand() * 2 * pi;
    else
        theta = params.theta0;
    end

    % Save initial state
    x_traj(1) = x;
    y_traj(1) = y;
    theta_traj(1) = mod(theta + pi, 2*pi) - pi;
    v_traj(1) = 0;
    g_traj(1) = 0;
    vd_traj(1) = compute_viewing_distance(x, y, theta, params.arena_radius);

    %% Main simulation loop
    for i = 2:n_steps
        % Compute viewing distance along current heading
        viewing_dist = compute_viewing_distance(x, y, theta, params.arena_radius);

        % Compute turning components

        % 1. Base optomotor response (constant direction based on grating)
        if viewing_dist >= params.min_dist
            bias_term = params.grating_dir * params.base_bias * dt;
        else
            bias_term = 0;  % Suppress optomotor response when too close to wall
        end

        % 2. Brownian noise (always present)
        brownian_turn = randn() / params.brownian_amp * sqrt(dt);

        % 3. Distance-dependent gain (sigmoid function)
        % view_factor approaches 1 when close to wall, 0 when far
        view_factor = 1 / (1 + exp(params.b * (viewing_dist - params.d0)));
        gain_turn = params.grating_dir * params.k_dist * view_factor * dt;

        % Combine turning components
        if viewing_dist < params.min_dist
            dtheta = brownian_turn;  % Only random walk when very close to wall
        else
            dtheta = bias_term + brownian_turn + gain_turn;
        end

        theta = theta + dtheta;

        % Compute speed (inverse relationship with turning)
        v_inst = params.v_max / (1 + params.alpha * abs(dtheta));

        % Update position
        x_new = x + v_inst * dt * cos(theta);
        y_new = y + v_inst * dt * sin(theta);

        % Boundary check: reflect heading if hitting wall
        if sqrt(x_new^2 + y_new^2) >= params.arena_radius
            theta = theta + pi;
            x_new = x;
            y_new = y;
        end

        % Update state
        x = x_new;
        y = y_new;

        % Save trajectory
        x_traj(i) = x;
        y_traj(i) = y;
        theta_traj(i) = mod(theta + pi, 2*pi) - pi;
        v_traj(i) = v_inst;
        g_traj(i) = gain_turn;
        vd_traj(i) = viewing_dist;
    end

    %% Package output
    trajectory = struct( ...
        'time_s', time_steps, ...
        'x_mm', x_traj, ...
        'y_mm', y_traj, ...
        'heading_rad', theta_traj, ...
        'speed_mm_s', v_traj, ...
        'gain', g_traj, ...
        'viewing_dist_mm', vd_traj ...
    );
end

%% Helper function: compute viewing distance via ray-circle intersection
function viewing_dist = compute_viewing_distance(x, y, theta, arena_radius)
    % Ray direction
    dx = cos(theta);
    dy = sin(theta);

    % Solve quadratic for intersection: (x + t*dx)^2 + (y + t*dy)^2 = R^2
    A = dx^2 + dy^2;
    B = 2 * (x*dx + y*dy);
    C = x^2 + y^2 - arena_radius^2;
    discriminant = B^2 - 4*A*C;

    if discriminant < 0
        viewing_dist = 0;  % No intersection (should not happen inside arena)
    else
        t1 = (-B + sqrt(discriminant)) / (2*A);
        t2 = (-B - sqrt(discriminant)) / (2*A);
        % Take smallest positive t (forward view)
        t_candidates = [t1, t2];
        t_candidates(t_candidates < 0) = inf;
        viewing_dist = min(t_candidates);
    end
end
