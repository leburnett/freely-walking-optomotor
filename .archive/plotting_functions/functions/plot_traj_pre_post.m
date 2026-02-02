function plot_traj_pre_post(DATA, strain, cond_idx, fly_ids)
% Plot the trajectory of a fly
% The colour of the trajectory is determined by "col_12" during the
% stimulus and is grey for 3s before and 3s after the stimulus.
seconds_pre_post = 5;

figure;

n_flies = numel(fly_ids);

% Colours across conditions
col_12 = [31 120 180; ... %50 50 50; ...% 166 206 227; 106 61 154; ...
    31 120 180; ...
    178 223 138; ...
    47 141 41; ...
    251 154 153; ...
    227 26 28; ...
    253 191 111; ...
    255 127 0; ...
    166 206 227; ...%202 178 214; ...
    100 100 100; ... %200 200 200; ... % 106 61 154; ...166 206 227;
    255 224 41; ...
    187 75 12; ...
    ]./255;

line_colour_pre_post = [0.7 0.7 0.7];

cond_titles = {'4Hz',...
    '8Hz', ...
    '4Hz-narrow-ON', ...
    '4Hz-narrow-OFF', ...
    'ON-Edge', ...
    'OFF-Edge', ... 
    'RevPhi-4Hz', ...
    'RevPhi-8Hz', ...
    '4Hz-Flicker', ...
    'Static', ...
    '4Hz-offset', ...
    'Phototaxis'};

% Define the center of the arena
cx = 122.8079; %calib.centroids(1)/calib.PPM; 
cy = 124.7267; %calib.centroids(2)/calib.PPM;
frame_rng_stim = 300:1200;
frame_rng_before = 300-(30*seconds_pre_post):300;
frame_rng_after = 1200:1200+(30*seconds_pre_post);

for f = 1:n_flies

    fly_idx = fly_ids(f);

    if f == 1
        traj_only = 0;
    else
        traj_only = 1;
    end

    line_colour = col_12(cond_idx, :);
    cond_name = cond_titles{cond_idx};

    % Plot trajectories of the different strains and different conditions
    data = DATA.(strain).F;
    
    data_type = "x_data"; 
    cond_data_x = combine_timeseries_across_exp(data, cond_idx, data_type);
    
    data_type = "y_data"; 
    cond_data_y = combine_timeseries_across_exp(data, cond_idx, data_type);
    
    x_data = cond_data_x(fly_idx, :);
    y_data = cond_data_y(fly_idx, :);   

    % Trajectory plotting % % % % 

    % Plot before the stimulus 

    x = x_data(frame_rng_before); % x position over time (1 x n)
    y = y_data(frame_rng_before); % y position over time (1 x n)
    
    plot_trajectory_condition(x, y, cx, cy, line_colour_pre_post, cond_name, 0, 1)

    % Plot during stimulus 

    x = x_data(frame_rng_stim); % x position over time (1 x n)
    y = y_data(frame_rng_stim); % y position over time (1 x n)
    
    plot_trajectory_condition(x, y, cx, cy, line_colour, cond_name, 1, 0)

    % Plot before the stimulus 

    x = x_data(frame_rng_after); % x position over time (1 x n)
    y = y_data(frame_rng_after); % y position over time (1 x n)
    
    plot_trajectory_condition(x, y, cx, cy, line_colour_pre_post, cond_name, 1, 2)

    % % % % % %

    axis off
    hold on 
end 

title(string(fly_idx))  
lgd = legend;
lgd.Position = [0.8178    0.6857    0.1554    0.2821];

% Save the figure:
% f_name = fullfile(save_folder, strcat("Traj_fig", string(p),"_", strain, "_Condition", string(condition_n), ".pdf"));

% exportgraphics(f ...
%         , f_name ...
%         , 'BackgroundColor', 'none' ...
%         , 'Resolution', 90 ...
%         );
% %                % , 'ContentType', 'vector' ... % Use if you want
% %                to generate high quality figures.
% close

end 