% Functions to analyse the behaviour of strains across all experiments

strain_data_folder = '/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_v1/JFRC49_ES';
cd(strain_data_folder)

data_files = dir('*.mat');
n_files = length(data_files);

all_velocity_data = []; 

for i = 1:n_files
    load(data_files(i).name);
    vel_data = feat.data(:, :, 1);

    [rowsall, colsall] = size(all_velocity_data);
    [rowsdata, colsdata]  = size(vel_data);

    n_cols_diff = colsall-colsdata;
    if n_cols_diff >=0 
        vel_data = [vel_data, NaN(rowsdata, n_cols_diff)];
    elseif n_cols_diff < 0 
        all_velocity_data = [all_velocity_data, NaN(rowsall, n_cols_diff*-1)];
    end 

    all_velocity_data = vertcat(all_velocity_data, vel_data);

end 

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


%% distance to wall data 

all_distance_data = []; 

for i = 1:n_files
    load(data_files(i).name);
    dist_data = 120-feat.data(:, :, 9);

    [rowsall, colsall] = size(all_distance_data);
    [rowsdata, colsdata]  = size(dist_data);

    n_cols_diff = colsall-colsdata;
    if n_cols_diff >0 
        dist_data = [dist_data, NaN(rowsdata, n_cols_diff)];
    elseif n_cols_diff < 0 
        all_distance_data = [all_distance_data, NaN(rowsall, n_cols_diff*-1)];
    end 

    all_distance_data = vertcat(all_distance_data, dist_data);

end 

%% Plots

figure; plot(median(all_distance_data))

figure; plot(median(all_distance_data))

% Histogram of velocity over experiments
figure; histogram(all_distance_data, 'BinEdges', [0:2:50])


% Histogram of velocity over acclim for all exp
figure; histogram(all_distance_data(:, 1:900), 'BinEdges', [0:2:50])

















