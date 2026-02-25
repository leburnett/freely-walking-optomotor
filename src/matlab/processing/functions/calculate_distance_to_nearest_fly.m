function [IFD_data, IFA_data] = calculate_distance_to_nearest_fly(x_data, y_data, heading_data)

    num_flies = size(x_data, 1);
    n_frames = size(x_data, 2);
    nearest_distances = zeros(num_flies, 1);
    nearest_angles = zeros(num_flies, 1);

    IFD_data = zeros(size(x_data));
    IFA_data = zeros(size(x_data));
    
    for f = 1:n_frames

        % Loop over each fly
        for i = 1:num_flies
            % Get the position of the current fly
            x_center = x_data(i, f);
            y_center = y_data(i, f);
    
            % Compute distances from the current fly to all other flies
            distances = sqrt((x_data(:, f) - x_center).^2 + ...
                             (y_data(:, f) - y_center).^2);
            
            distances(i) = NaN;
            [nearest_distances(i), nearest_idx] = min(distances);
    
            dx = x_data(nearest_idx, f) - x_center;
            dy = y_data(nearest_idx, f) - y_center;
            angle_to_nearest = rad2deg(atan2(dy, dx)); % Convert radians to degrees
    
            relative_angle = angle_to_nearest - heading_data(i, f);
    
            nearest_angles(i) = mod(relative_angle + 180, 360) - 180;
        end

        IFD_data(:, f) = nearest_distances;
        IFA_data(:, f) = nearest_angles;

    end 

end 