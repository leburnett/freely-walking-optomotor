function make_plots_per_strain(strain_data_folder)
% Generate pdf with a number of different plots using the combined data
% from all experiments from a particular fly strain and for a particular
% protocol. 

% Inputs
% - - - - 

% strain_data_folder : Path (e.g.
% '/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_v1/JFRC49_ES')

% Information about the strain / protocol. 
subfolders = split(strain_data_folder, '/');
strain = subfolders{end};
protocol = subfolders{end-1};

%% Generate combined velocity data 

combined_data = combine_data_across_exp(strain_data_folder);

%% Plots

figure; plot(median(all_velocity_data))

figure; plot(median(all_velocity_data))

% Histogram of velocity over experiments
figure; histogram(all_velocity_data, 'BinEdges', [0:2:50])

% Histogram of prop of exp spend < 2mms-1 per fly
n_flies = numel(all_velocity_data(:,1));
for j = 1:n_flies
    data_fly = all_velocity_data(j, :);
    frames_slow = find(data_fly<2);
    frames_all = data_fly(~isnan(data_fly));
    p_slow(j) = numel(frames_slow)/numel(frames_all);
end

figure; histogram(p_slow, 'BinEdges', [0:0.05:1])

% Histogram of velocity over acclim for all exp
figure; histogram(all_velocity_data(:, 1:900), 'BinEdges', [0:2:50])


%% Generate combined distance from centre data 

all_distance_data = ombine_data_across_exp(strain_data_folder, "dist");

%% Plots

figure; plot(median(all_distance_data))

figure; plot(median(all_distance_data))

% Histogram of velocity over experiments
figure; histogram(all_distance_data, 'BinEdges', [0:2:50])


% Histogram of velocity over acclim for all exp
figure; histogram(all_distance_data(:, 1:900), 'BinEdges', [0:2:50])



end 













