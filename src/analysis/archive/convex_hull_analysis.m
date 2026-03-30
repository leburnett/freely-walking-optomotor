% CONVEX_HULL_ANALYSIS - Analyze collective fly positioning using convex hulls
%
% SCRIPT CONTENTS:
%   - Section 1: Generate spatial probability heatmaps for each experiment
%   - Section 2: Calculate convex hull area and centroid per frame
%   - Section 3: Plot trajectory of convex hull centroid over time
%   - Section 4: Plot convex hull area timeseries
%
% DESCRIPTION:
%   This script analyzes the collective spatial distribution of flies in the
%   arena by computing the convex hull of valid fly positions at each frame.
%   Flies too close to the arena edge (within 10mm buffer) are excluded.
%   The convex hull area and centroid position are tracked over time to
%   assess group cohesion and collective movement patterns.
%
% REQUIREMENTS:
%   - DATA struct with position data (x_data, y_data)
%   - make_spatial_prob_heatmap function
%
% ARENA PARAMETERS:
%   - Arena center: [125.682, 125.682] mm
%   - Arena radius: 118.97 mm
%   - Edge buffer: 10 mm (flies within this distance from edge are excluded)
%
% OUTPUTS:
%   - hull_area: convex hull area per frame
%   - hull_x, hull_y: centroid coordinates of convex hull per frame
%   - Trajectory and area plots
%
% See also: make_spatial_prob_heatmap, convhull, polyarea

for i = 1:21
    make_spatial_prob_heatmap(DATA, strain, i, condition)
    sgtitle(strcat("Exp ", string(i)));
end 


% Arena parameters
arena_center = [125.682, 125.682]; % center in mm
arena_radius = 118.9701; % radius in mm
edge_buffer = 10; % mm from edge to exclude flies

strain = "jfrc100_es_shibire_kir";
sex = "F";

data = DATA.(strain).(sex);
n_exp = length(data);

%% 1 - Find the positions of all of the flies in the arena
for exp_id = 1:5 %n_exp

    data_exp = data(exp_id).R1_condition_11;

    % This is the position of all flies from this vial across the entire condition.  
    x_all = data_exp.x_data;
    y_all = data_exp.y_data;

    n_frames = size(x_all, 2);

    hull_area = zeros(1, n_frames);
    hull_x = zeros(1, n_frames);
    hull_y = zeros(1, n_frames);
    
    for frame_id = 1:n_frames

        x_positions = x_all(:, frame_id);
        y_positions = y_all(:, frame_id);
        
        % Step 1: Compute distances from each fly to the arena center
        distances = sqrt((x_positions - arena_center(1)).^2 + (y_positions - arena_center(2)).^2);
        
        % Step 2: Identify flies farther than 10 mm from the edge
        valid_indices = distances < (arena_radius - edge_buffer);
        
        % Filter positions
        x_valid = x_positions(valid_indices);
        y_valid = y_positions(valid_indices);
        
        % Check if there are at least 3 points to compute convex hull
        if numel(x_valid) < 3
            error('Not enough valid points to compute a convex hull.');
        end
        
        % Step 3: Compute convex hull
        k = convhull(x_valid, y_valid);
        
        % Step 4: Compute area of the convex hull
        hull_area(1, frame_id) = polyarea(x_valid(k), y_valid(k));
        
        % Step 5: Compute centroid of the convex hull
        hull_x(1, frame_id) = mean(x_valid(k));
        hull_y(1, frame_id) = mean(y_valid(k));
        
    end


    %% Plot the trajectory of the centre of the convex hull across the experiment:

    figure; 
    for i = 1:numel(hull_x)-1
        if i < 300
            col = [0.8 0.8 0.8];
        elseif i > 300 && i < 1200
            col = [0.2 0.2 0.2];
        elseif i >= 1200 
            col = [0.8 0.8 0.8];
        end 
        x1 = hull_x(i);
        x2 = hull_x(i+1);
        y1 = hull_y(i);
        y2 = hull_y(i+1);
        plot([x1, x2], [y1 y2], 'Color', col, 'LineWidth', 1)
        hold on 
    end

    plot(mean(hull_x(1:1200)), mean(hull_y(1:300)), 'c.', 'MarkerSize', 20)
    plot(mean(hull_x(300:1200)), mean(hull_y(300:1200)), 'r.', 'MarkerSize', 20)
    plot(mean(hull_x(1200:end)), mean(hull_y(1200:end)), 'b.', 'MarkerSize', 20)

    xlim([0 245])
    ylim([0 245])
    viscircles([125, 125], 120, 'Color', [0.7 0.7 0.7])
    axis off
    axis equal


    figure; plot(hull_area);

end 
    


   
