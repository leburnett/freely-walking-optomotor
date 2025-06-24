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

    T = 30;
    arena_radius = 12.5;
    dt = 1/30;
    time_steps = 0:dt:T;
    n_steps = length(time_steps);

    % Initialize arrays
    x_traj = zeros(1, n_steps);
    y_traj = zeros(1, n_steps);
    theta_traj = zeros(1, n_steps);
    v_traj = zeros(1, n_steps);
    g_traj = zeros(1, n_steps);
    vd_traj = zeros(1, n_steps);

    % Start at center with random heading
    x = -9; %randi([-5 5], 1);
    y = randi([-5 5], 1);
    theta = rand() * 2 * pi;

    for i = 2:n_steps
        % --- Compute viewing distance along current heading ---
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

        % --- Update heading based on Brownian motion and viewing distance ---
        bias_term = k * base_bias * dt;
        brwn_val = 1.5; % decrease for increased randomness.
        brownian_turn = randn()/brwn_val * sqrt(dt);  % Brownian noise
 
        d0 = 12;
        b = 0.6;
        view_factor = 1 / (1 + exp(b * (viewing_dist - d0)));  % ranges from 0 to 1
        gain_turn = k * view_factor * dt;

        % dtheta = brownian_turn + gain_turn * (2*rand()-1);  % random direction for gain
        dtheta = bias_term + brownian_turn + gain_turn;
        theta = theta + dtheta;

        % --- Inverse relationship: speed drops as turning increases ---
        alpha = 10;          % sensitivity of speed to turning (tune as needed)
        v_max = 2.5;         % max possible speed (when not turning)
        v_inst = v_max / (1 + alpha * abs(dtheta));

        % --- Move forward ---
        x_new = x + v_inst * dt * cos(theta);
        y_new = y + v_inst * dt * sin(theta);

        % --- Check bounds: stay inside arena ---
        if sqrt(x_new^2 + y_new^2) >= arena_radius
            % Reflect heading
            theta = theta + pi;
            % Stay at same position
            x_new = x;
            y_new = y;
        end

        % Save state
        x = x_new;
        y = y_new;
        x_traj(i) = x;
        y_traj(i) = y;
        theta_traj(i) = mod(theta + pi, 2*pi) - pi;  % wrap to [-pi, pi]
        v_traj(i) = v_inst;
        g_traj(i) = gain_turn;
        vd_traj(i) = viewing_dist;
   
    end

    x_traj = x_traj(2:end);
    y_traj = y_traj(2:end);
    theta_traj = theta_traj(2:end);
    v_traj = v_traj(2:end);
    g_traj = g_traj(2:end);
    vd_traj = vd_traj(2:end);

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