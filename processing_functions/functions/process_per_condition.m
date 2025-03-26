%% Process per-condition

% Extract data per fly from DATA - combined data for one protocol.
% Which strain, sex and condition; 
protocol = 'protocol_24';
strain = 'jfrc100_es_shibire_kir';
sex = 'F';
cond_idx = 0;

% Set the speed of the stimulus for the condition.
switch cond_idx
    case 0 
        stim_speed = 0;
    case 1 
        stim_speed = 240;
    case 2 
        stim_speed = 480;
end 

% Extract metrics that are already saved:
Va = combine_timeseries_data_per_cond(DATA, strain, sex, 'av_data', cond_idx);
x = combine_timeseries_data_per_cond(DATA, strain, sex, 'x_data', cond_idx);
y = combine_timeseries_data_per_cond(DATA, strain, sex, 'y_data', cond_idx);
vd = combine_timeseries_data_per_cond(DATA, strain, sex, 'view_dist', cond_idx);
dist_d = combine_timeseries_data_per_cond(DATA, strain, sex, 'dist_data', cond_idx);
dist_t = combine_timeseries_data_per_cond(DATA, strain, sex, 'dist_trav', cond_idx);

n_flies = height(x);

% Calculate new metrics:
Vf = nan(size(x));
Rc = nan(size(x));
Ac = nan(size(x));
Ac_arena = nan(size(x));
g = nan(size(x));

for flyId = 1:n_flies

    % x and y coordinates of the individual fly per frame.
    x_fly = x(flyId, :);
    y_fly = y(flyId, :);

    % Calculate 3 point velocity
    v_fly = calculate_n_point_velocity(x_fly,y_fly, 3);
    Vf(flyId, :) = v_fly;

    % Calculate path curvature
    r_curvature = get_curvature_from_x_y(x_fly, y_fly);
    Rc(flyId, 3:end-2) = r_curvature;

    % Calculate the centripetal acceleration using the three point velocity
    % and the curvature of the path as 'r'.
    a_c = v_fly(3:end-2).^2 ./ abs(r_curvature); 
    Ac(flyId, 3:end-2) = a_c;

    % Calculate the centripetal acceleration using the three point velocity
    % and the distance from the centre of the arena as 'r'.
    a_c_arena = v_fly(2:end-1).^2 ./ dist_d(flyId, 2:end-1);
    Ac_arena(flyId, 2:end-1) = a_c_arena;

    % Calculate the gain - turning versus speed of stim
    gain = abs(Va(flyId, :))/stim_speed;
    g(flyId, :) = gain;

    plot_summary_fig_one_cond_one_fly(v_fly, abs(Va), r_curvature, dist_d, a_c, a_c_arena, gain, flyId)
    sgtitle(strcat("Fly - ", string(flyId)))

end 

%% Bin the data across the grating stimulus presentation. 

% Make absolute - avoid problems with sign when binning.
Va = abs(Va);
Rc = abs(Rc);

% Define parameters
window_size = 15;  % Number of frames per bin - 15 frames = 0.5s
step_size = 7;     % Step size for shifting the window

% Set window during which to analyse. Compare to pre/post stimulus.
start_frame = 300; % First frame to consider
end_frame = 1200;  % Last frame to consider

% List of variable names to be binned
var_names = {'Va', 'Vf', 'x', 'y', 'vd', 'dist_d', 'dist_t', 'Rc', 'Ac', 'Ac_arena', 'g'};

% Initialize a struct to store the binned data
binned_data = struct();

% Loop through each variable, bin the data, and store it in the struct
for i = 1:length(var_names)
    var_name = var_names{i};  % Get the variable name as a string
    binned_data.(var_name) = bin_data(eval(var_name), window_size, step_size, start_frame, end_frame);
end

binned_data.window_size = window_size;
binned_data.step_size = step_size;
binned_data.start_frame = start_frame;
binned_data.end_frame = end_frame;
binned_data.protocol = protocol;
binned_data.strain = strain;
binned_data.sex = sex;
binned_data.cond_idx = cond_idx;

% Create greyscale cmap going from white to black for the number of bins.
col_bin = nan(n_bins, 3);
col = [1 1 1];
for i = 1:n_bins
    col_bin(i, :) = col;
    col = col - (1/n_bins);
end

%% Generate subplots of Vf versus Va and the trajectory during gratings per fly. 

fig_save_folder = '/Users/burnettl/Documents/Projects/oaky_cokey/figures/trajectories/p24/acclim_vf/';

if ~isfolder(fig_save_folder)
    mkdir(fig_save_folder);
end 

for flyId = 100:n_flies

    % Generate colourscale to use.
    % turning_rate = Va_bin(flyId, :)./Vf_bin(flyId, :);
    cmap_array = get_cmap_from_data(binned_data.Vf(flyId, :));

    % Generate subplot with scatter and trajectory.
    generate_scatter_traj_subplot(binned_data, cmap_array, flyId, fig_save_folder)
    close
end 
