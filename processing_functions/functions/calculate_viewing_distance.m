function view_dist = calculate_viewing_distance(x_data, y_data, heading_wrap)
% Inputs
% x_data (matrix, size:[n_flies, n_frames]) - x position of each fly in
% every frame. 
% y_data (matrix, size:[n_flies, n_frames]) - y position of each fly in
% every frame.  
% heading_wrap (matrix, size:[n_flies, n_frames]) - wrapped heading angle
% of every fly in every frame in radians. 

    % Fixed parameters of the arena - THIS WILL NEED TO BE UPDATED IF THE
    % ARENA CHANGES:

    PPM = 4.1691; %calib.PPM; 
    CoA = [528, 520]/PPM;
    x_c = CoA(1);
    y_c = CoA(2);
    R = 496/PPM;

    sz = size(x_data);
    
    n_flies = sz(1);
    n_frames = sz(2);
    view_dist = zeros(sz);

    for fly_id = 1:n_flies
        
        x = x_data(fly_id, :);
        y = y_data(fly_id, :);
        heading = heading_wrap(fly_id, :);
    
        for frame_id = 1:n_frames
    
            x_f = x(frame_id);
            y_f = y(frame_id);
            theta_rad = heading(frame_id); 
    
             % Compute quadratic coefficients
            A = 1; % Since cos^2 + sin^2 = 1
            B = 2 * ((x_f - x_c) * cos(theta_rad) + (y_f - y_c) * sin(theta_rad));
            C = (x_f - x_c)^2 + (y_f - y_c)^2 - R^2;
            
            % Solve quadratic equation for intersection
            D = B^2 - 4*A*C;
            if D < 0
                d_view = NaN; % No valid intersection (shouldn’t happen if always inside arena)
            else
                t1 = (-B + sqrt(D)) / (2*A);
                t2 = (-B - sqrt(D)) / (2*A);
                
                % Choose only the positive root(s)
                t_vals = [t1, t2];
                t_pos = t_vals(t_vals > 0); % keep only positive (forward) distances
            
                if isempty(t_pos)
                    d_view = NaN; % no wall in heading direction (also shouldn't happen)
                else
                    d_view = min(t_pos); % closest forward wall
                end
            end

            view_dist(fly_id, frame_id) = d_view;
        end 
    end 

end 