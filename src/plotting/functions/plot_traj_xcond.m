function plot_traj_xcond(DATA, strain, cond_ids, fly_idx)

figure;

n_conditions = numel(cond_ids);

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
    200 200 200; ... % 106 61 154; ...166 206 227;
    255 224 41; ...
    187 75 12; ...
    ]./255;

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

for c = 1:n_conditions

    if c == 1
        traj_only = 0;
    else
        traj_only = 1;
    end

    condition_n = cond_ids(c);
    line_colour = col_12(condition_n, :);
    cond_name = cond_titles{condition_n};

    % Plot trajectories of the different strains and different conditions
    data = DATA.(strain).F;
    
    data_type = "x_data"; 
    cond_data_x = combine_timeseries_across_exp(data, condition_n, data_type);
    
    data_type = "y_data"; 
    cond_data_y = combine_timeseries_across_exp(data, condition_n, data_type);
    
    x_data = cond_data_x(fly_idx, :);
    y_data = cond_data_y(fly_idx, :);    

    x = x_data(frame_rng_stim); % x position over time (1 x n)
    y = y_data(frame_rng_stim); % y position over time (1 x n)
    
    plot_trajectory_condition(x, y, cx, cy, line_colour, cond_name, traj_only)
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