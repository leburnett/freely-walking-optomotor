function r_curvature = get_curvature_from_x_y(x_fly, y_fly)

    dt = (1/30);  % Video acquired at 30 fps. 
    n = length(x_fly);
    
    % Compute velocity using three time points (central differences)
    v_x = (x_fly(3:n) - x_fly(1:n-2)) / (2 * dt);
    v_y = (y_fly(3:n) - y_fly(1:n-2)) / (2 * dt);
    
    % Compute speed (magnitude of velocity)
    v = sqrt(v_x.^2 + v_y.^2);
    
    % Compute acceleration using central differences
    a_x = (v_x(3:end) - v_x(1:end-2)) / (2 * dt);
    a_y = (v_y(3:end) - v_y(1:end-2)) / (2 * dt);
    
    % Compute perpendicular acceleration (for radius of curvature)
    a_perp = v_x(2:end-1) .* a_y - v_y(2:end-1) .* a_x;
    
    % Compute radius of curvature
    r_curvature = v(2:end-1).^3 ./ a_perp;
    
    % Handle cases where a_perp is close to zero (to avoid division by zero)
    r_curvature(abs(a_perp) < 1) = NaN;

end 