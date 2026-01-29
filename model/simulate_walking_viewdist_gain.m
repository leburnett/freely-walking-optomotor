function [x_traj, y_traj, theta_traj, v_traj, g_traj, vd_traj] = simulate_walking_viewdist_gain(k, base_bias, disp_params)
    % Simulates agent walking in circular arena with Brownian motion
    % and turning modulated by viewing distance.

    % Inputs:
    % ------
    % k (float) - gain for turning based on viewing distance.

    % base_bias (float) - base turning bias of the agent. This would correspond to
    % the speed of the grating stimulus.

    % disp_params (bool) - if True then print parameter values.

    % Returns
    % -------

    % x_traj (array) - x position for 1:n_timepoints.

    % y_traj (array) - y position for 1:n_timepoints.

    % theta_traj (array) - heading for 1:n_timepoints.

    % v_traj (array) - speed for 1:n_timepoints.

    % g_traj (array) - gain value for 1:n_timepoints.

    % vd_traj (array) - viewing distance for 1:n_timepoints.

    T = 30; % 30 s
    arena_radius = 120.5;
    dt = 1/30; % 30 fps equivalent.
    time_steps = 0:dt:T;
    n_steps = length(time_steps);

    % Initialize arrays
    x_traj = zeros(1, n_steps);
    y_traj = zeros(1, n_steps);
    theta_traj = zeros(1, n_steps);
    v_traj = zeros(1, n_steps);
    g_traj = zeros(1, n_steps);
    vd_traj = zeros(1, n_steps);

    % Start at left side of arena with random y and random heading
    x = -90; %randi([-5 5], 1);
    y = randi([-60 60], 1);
    theta = rand() * 2 * pi;

    % Save initial state
    x_traj(1) = x;
    y_traj(1) = y;
    theta_traj(1) = mod(theta + pi, 2*pi) - pi;  % wrap to [-pi, pi]
    v_traj(1) = 0;  % No velocity at t=0
    g_traj(1) = 0;  % No gain at t=0
    vd_traj(1) = 0; % Will be computed on first step

    for i = 2:n_steps
        % Compute viewing distance along current heading
        % Ray-circle intersection from point (x,y) along heading theta
        dx = cos(theta);
        dy = sin(theta);

        % Solve quadratic for intersection: (x + t*dx)^2 + (y + t*dy)^2 = R^2
        A = dx^2 + dy^2;
        B = 2 * (x*dx + y*dy);
        C = x^2 + y^2 - arena_radius^2;
        discriminant = B^2 - 4*A*C;

        if discriminant < 0
            viewing_dist = 0;  % no intersection (should not happen)
        else
            t1 = (-B + sqrt(discriminant)) / (2*A);
            t2 = (-B - sqrt(discriminant)) / (2*A);
            % We take the smallest positive t (forward view)
            t_candidates = [t1, t2];
            t_candidates(t_candidates < 0) = inf;
            viewing_dist = min(t_candidates);
        end

        % Update heading based on Brownian motion and viewing distance

        % Remove turning bias if the viewing distance is too small. 
        if viewing_dist < 20
            bb = 0;
        else 
            bb = base_bias;
        end 
        bias_term = k * bb * dt; % gain * base turning bias * time step.
        brwn_val = 1.2; % increase to decrease randomness (divides randn).
        brownian_turn = randn()/brwn_val * sqrt(dt);  % Brownian noise
 
        d0 = 90; % distance at which turning is half maximal
        b = 0.02; % slope of sigmoid - steepness of transition with distance.
        view_factor = 1 / (1 + exp(b * (viewing_dist - d0)));  % ranges from 0 to 1
        gain_turn = k * view_factor * dt;

        % dtheta = brownian_turn + gain_turn * (2*rand()-1);  % random direction for gain
        if viewing_dist < 20
            dtheta = brownian_turn; % If too close to the edge, just random walk.
        else
            dtheta = bias_term + brownian_turn + gain_turn;
        end 
        theta = theta + dtheta;

        % Inverse relationship: speed drops as turning increases
        alpha = 7;          % sensitivity of speed to turning (tune as needed)
        v_max = 20;         % max possible speed (when not turning)
        v_inst = v_max / (1 + alpha * abs(dtheta));

        % Move forward
        x_new = x + v_inst * dt * cos(theta);
        y_new = y + v_inst * dt * sin(theta);

        % Check bounds: stay inside arena
        if sqrt(x_new^2 + y_new^2) >= arena_radius
            % Reflect heading
            theta = theta + pi;
            % Stay at same position
            x_new = x;
            y_new = y;
        end

        % Update x and y position
        x = x_new;
        y = y_new;

        % Save state
        x_traj(i) = x;
        y_traj(i) = y;
        theta_traj(i) = mod(theta + pi, 2*pi) - pi;  % wrap to [-pi, pi]
        v_traj(i) = v_inst;
        g_traj(i) = gain_turn;
        vd_traj(i) = viewing_dist;
   
    end

    % Note: Initial values are now saved at index 1, so all trajectories
    % include the starting state.

    if disp_params
        % display the parameters used
        disp(strcat("T = ", string(T)))
        disp(strcat("x = ", string(x)))
        disp(strcat("y = ", string(y)))
        disp(strcat("k = ", string(k)))
        disp(strcat("base_bias = ", string(base_bias)))
        disp(strcat("d0 = ", string(d0)))
        disp(strcat("b = ", string(b)))
        disp(strcat("alpha = ", string(alpha)))
        disp(strcat("v_max = ", string(v_max)))
        disp(strcat("brwn_val = ", string(brwn_val)))
    end 
end