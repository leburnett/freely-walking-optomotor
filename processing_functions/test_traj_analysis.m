% Trajectory curvature

% strain = 't4t5_RNAi_control';
% strain = 't4t5_ttl_RNAi';
strain = 't4t5_mmd_RNAi';
sex = 'F';
cond_idx = 1;

% Combine the timeseries data over experiments adn extract the x and y 
% positions of each fly over the frames of the condition:
data_type = 'x_data';
cond_data_x = combine_timeseries_data_per_cond(DATA, strain, sex, data_type, cond_idx);
data_type = 'y_data';
cond_data_y = combine_timeseries_data_per_cond(DATA, strain, sex, data_type, cond_idx);

% Add a check to make sure cond_data_x and cond_data_y are the same size:
cond_data_curv = zeros(size(cond_data_x));

n_flies = size(cond_data_x, 1);

for fly_id = 1:n_flies

    x = cond_data_x(fly_id, :);
    x = movmean(x, 30);
    y = cond_data_y(fly_id, :);
    y = movmean(y, 30);

    % Assume x and y are vectors containing the position data per frame
    dx = gradient(x);
    dy = gradient(y);
    
    ddx = gradient(dx);
    ddy = gradient(dy);
    
    % Compute curvature
    curvature = (dx .* ddy - dy .* ddx) ./ (dx.^2 + dy.^2).^(3/2);
    
    % Handle potential NaN or Inf values (due to division by zero)
    curvature(isnan(curvature) | isinf(curvature)) = 0;
    
    cond_data_curv(fly_id, :) = curvature;

    clear curvature

end 
%If the motion is along a straight line, the curvature will be close to zero.
% If the motion is highly curved, the curvature values will be larger.

a = mean(cond_data_curv);
figure; plot(a)


%%

data_type = "heading_wrap";
cond_data_heading = combine_timeseries_data_per_cond(DATA, strain, sex, data_type, cond_idx);


a = unwrap(cond_data_heading(1, :));
b = diff(a);

figure; plot(b)

%% Plot trajectory - find "straight" and "loopy" trajectories. 

for fly_id = [2,3,9]
% fly_id = 3; % 2,3,9
    x = cond_data_x(fly_id, :);
    y = cond_data_y(fly_id, :);
    plot_trajectory_xy(x, y, fly_id)
end 


%%

curvature_min = -30; % Minimum reasonable curvature (e.g., very large turns)
curvature_max = 30; % Maximum reasonable curvature (e.g., very sharp turns)

figure; 
for fly_id = 2
    for r = 1:4 
         switch r
            case 1 % Before stimulus starts
                rng = 1:300; 
                col = [0.75 0.75 0.75];
            case 2 % Stimulus turning in one direction
                rng = 301:750;
                col = [1 0.7 0.7];
            case 3 
                rng = 751:1200;
                col = [0.7 0.7 1];
            case 4 
                rng = 1201:1808; 
                col = [0.75 0.75 0.75];
        end 
    x = cond_data_x(fly_id, rng);
    x = movmean(x, 30);
    y = cond_data_y(fly_id, rng);
    y = movmean(y, 30);

    % Assume x and y are vectors containing the position data per frame
    dx = gradient(x);
    dy = gradient(y);
    
    ddx = gradient(dx);
    ddy = gradient(dy);
    
    % Compute curvature
    curvature = (dx .* ddy - dy .* ddx) ./ (dx.^2 + dy.^2).^(3/2);
    
    % Handle potential NaN or Inf values (due to division by zero)
    curvature(isnan(curvature) | isinf(curvature)) = NaN;
    curvature_filtered = curvature;
    curvature_filtered(abs(curvature_filtered) > 15) = NaN;
    
    subplot(4,1,r)
    plot(abs(curvature_filtered), 'Color', col, 'LineWidth', 1.5);
    curv_str = string(nanmean(abs(curvature_filtered)));
    title(curv_str)
    disp(curv_str)
    end 
    % cond_data_curv(fly_id, :) = curvature;
    % 
    % clear curvature

end 

%% TURNING RATE
sex = 'F';
cond_idx = 2;
data_type = "curv_data"; %deg mm -1
rng = [0 120];

for s = 1:3

    if s ==1 
        strain = 't4t5_RNAi_control';
        col = 'k';
    elseif s ==2
        strain = 't4t5_ttl_RNAi';
        col = [0.9, 0.5, 0];
    elseif s == 3
        strain = 't4t5_mmd_RNAi';
        col = [0.8, 0, 0];
    end 

    cond_data_curv = combine_timeseries_data_per_cond(DATA, strain, sex, data_type, cond_idx);
    
    % dataa = abs(cond_data_curv(3, :));
    % dataa(abs(dataa)>1000)=NaN;
    % dataa = fillmissing(dataa', 'previous')';
    
    cond_data_curv_binned = zeros(39, 234);
    
    time_data = 0:1/30:70.4333;
    bin_size = 0.3;
    
    for fly_id = 1:39
        [binned_time, binned_turning_rate] = binTurningRate(time_data', cond_data_curv(fly_id, :)', bin_size);
        cond_data_curv_binned(fly_id, :) = abs(binned_turning_rate);
    end 
    
    mean_data = nanmean(cond_data_curv_binned);

    %% PLOT
   
    if s == 1
        figure; 
    end 
    % Add SEM
    sem_data = nanstd(cond_data_curv_binned)/sqrt(size(cond_data_curv_binned,1));
    y1 = mean_data+sem_data;
    y2 = mean_data-sem_data;
    nf_comb = size(mean_data, 2);
    x = 1:1:nf_comb;
    
    plot(x, y1, 'w', 'LineWidth', 1)
    hold on;
    plot(x, y2, 'w', 'LineWidth', 1)
    patch([x fliplr(x)], [y1 fliplr(y2)], col, 'FaceAlpha', 0.1, 'EdgeColor', 'none')
    
    % Add lines for when the stimulus starts / end 
    st_stim = 10/bin_size;
    chng_stim = 25/bin_size; 
    end_stim = 40/bin_size;
    hold on; plot([st_stim st_stim], rng, 'Color', [0.8 0.8 0.8], 'LineWidth', 1)
    plot([chng_stim chng_stim], rng, 'Color', [0.8 0.8 0.8], 'LineWidth', 1)
    plot([end_stim end_stim], rng, 'Color', [0.8 0.8 0.8], 'LineWidth', 1)
    plot([0 234], [0 0], 'Color', [0.8 0.8 0.8])
    
    plot(mean_data, 'Color', col, 'LineWidth', 1.2);
    
    if s == 3
        xlim([0 234])
        ylim(rng)
        box off
        ax = gca;
        ax.TickDir = 'out';
        ylabel('Turning rate (deg mm^-^1)')
        xticks([])
    end 

end 
%%


















%% 
% Get data from 210:1290 - 3s before to 3s after stim starts 
% 3s bins


data_rng = 120:1380;
time_data = 4:1/30:46;
c_data = cond_data_curv(3, data_rng);
bin_size =3;

[binned_time, binned_turning_rate] = binTurningRate(time_data', c_data', bin_size);

figure; plot(binned_turning_rate, 'k.-')
hold on 
plot([2.5 2.5], [-200 100], 'Color', [0.7 0.7 0.7])
plot([7.5 7.5], [-200 100], 'Color', [0.7 0.7 0.7])
plot([12.5 12.5], [-200 100], 'Color', [0.7 0.7 0.7])

plot([0 15], [0 0], 'Color', [0.2 0.2 0.2])

% ABSOLUTE TURNING RATE

figure; plot(abs(binned_turning_rate), 'k.-')
hold on 
plot([2.5 2.5], [0 200], 'Color', [0.7 0.7 0.7])
plot([7.5 7.5], [0 200], 'Color', [0.7 0.7 0.7])
plot([12.5 12.5], [0 200], 'Color', [0.7 0.7 0.7])

plot([0 15], [0 0], 'Color', [0.2 0.2 0.2])



%% 
data_type = "dist_data";
cond_data_dist = combine_timeseries_data_per_cond(DATA, strain, sex, data_type, cond_idx);

dd_data = cond_data_dist(3, :);


figure; scatter(dd_data, dataa)


%% Plot the mean across all flies

figure; plot(nanmean(cond_data_curv))
hold on 

%%  Find for each fly - the mean/ max turning rate for each fly and plot against it's starting position. 

% look at the TIME when the fly's turning rate > X deg mm-1
% How LONG does it take for the fly to start responding to the stimulus? I
% assume this would depend on where in the arena the fly is / where it's
% looking. 
% At what distance does the fly start responding? 

% When does the fly's turning rate exceed a certain threshold? 
time_to_turn = 

figure
for fly_id = 1:n_flies
    plot(cond_data_curv(fly_id, :)); hold on;
end 

% Gratings are moving at 120 degrees per second. 
% 4 degrees per frame = would match the stimulus


%% How I currently calculate turning rate:

    % c_data = [];
    % c_data = av_data(idx, :)./fv_data(idx, :);
    % vals_fv_zero = abs(fv_data(idx, :))<0.1;
    % c_data(abs(c_data)==Inf)=NaN;
    % c_data(vals_fv_zero) = NaN;
    % c_data = fillmissing(c_data', 'previous')';
    % curv_data(idx, :) = c_data;

















%% SCATTER PLOTS - AV vs FV

strain = 'jfrc100_es_shibire_kir';
sex = 'F';
cond_idx = 1;

% Combine the timeseries data over experiments adn extract the x and y 
% positions of each fly over the frames of the condition:
data_type = 'av_data';
Va = combine_timeseries_data_per_cond(DATA, strain, sex, data_type, cond_idx);
% data_type = 'fv_data';
% Vf = combine_timeseries_data_per_cond(DATA, strain, sex, data_type, cond_idx);

data_type = 'x_data';
x = combine_timeseries_data_per_cond(DATA, strain, sex, data_type, cond_idx);
data_type = 'y_data';
y = combine_timeseries_data_per_cond(DATA, strain, sex, data_type, cond_idx);

% Calculate the forward velocity as the three point velocity from the x,y
% position of the fly in each frame. 
n_flies = height(x);

Vf = nan(size(x));

for flyId = 1:n_flies
    x_fly = x(flyId, :);
    y_fly = y(flyId, :);
    v_fly = calculate_n_point_velocity(x_fly,y_fly, 3);
    Vf(flyId, :) = v_fly;
end 

% 10 frame time bin = ~300ms
% move by 5 frames - bin over 10

%% Bin the data across 300ms time windows during the grating stimulus presentation. 

Va = abs(Va);

% Define parameters
window_size = 15;  % Number of frames per bin
step_size = 7;     % Step size for shifting the window
start_frame = 300; % First frame to consider
end_frame = 1200;  % Last frame to consider

% start_frame = 1200; % First frame to consider
% end_frame = 1800;  % Last frame to consider

% Compute the number of bins within the specified range
n_bins = floor((end_frame - start_frame - window_size) / step_size) + 1;
step_col = 1/n_bins;

% Preallocate the binned matrices
Va_bin = nan(n_flies, n_bins);
Vf_bin = nan(n_flies, n_bins);
x_bin = nan(n_flies, n_bins);
y_bin = nan(n_flies, n_bins);
col_bin = nan(n_bins, 3);

col = [1 1 1];

% Loop through each bin within the specified frame range
for i = 1:n_bins

    start_idx = start_frame + (i-1) * step_size;  % Start of the window
    end_idx = start_idx + window_size - 1;        % End of the window
    
    % Compute mean within the window
    Va_bin(:, i) = mean(Va(:, start_idx:end_idx), 2);
    Vf_bin(:, i) = mean(Vf(:, start_idx:end_idx), 2);
    x_bin(:, i) = mean(x(:, start_idx:end_idx), 2);
    y_bin(:, i) = mean(y(:, start_idx:end_idx), 2);

    col_bin(i, :) = col;
    col = col - step_col;
end

%% Generate subplots of Vf versus Va and the trajectory during gratings per fly. 

fig_save_folder = '/Users/burnettl/Documents/Projects/oaky_cokey/figures/trajectories/p24/turning_rate_hot/';

for flyId = 1:n_flies

    turning_rate = Va_bin(flyId, :)./Vf_bin(flyId, :);

    % Normalize col_bin to range [0,1] for colormap scaling
    col_bin = turning_rate(:); % Ensure column vector
    col_bin_norm = (col_bin - min(col_bin)) / (max(col_bin) - min(col_bin));
    
    % Define the colormap (e.g., 'parula', 'jet', 'viridis', etc.)
    cmap = hot(256); % Change colormap if needed
    
    % Map col_bin_norm to actual RGB values
    color_indices = round(col_bin_norm * (size(cmap, 1) - 1)) + 1;
    scatter_colors = cmap(color_indices, :);

    figure;
    % Top subplot = Scatter plot of forward velocity versus rotational
    % velocity. Colorscale = time. 
    subplot(1,2,1)
    plot_Vf_Va_scatter(Vf_bin, Va_bin, scatter_colors, 1, flyId)
    
    % Bottom subplot = trajectory of the fly during the grating stimulus. 
    % Coloscale = time.
    subplot(1,2,2)
    plot_coloured_trajectory(x_bin, y_bin, scatter_colors, flyId)
    axis tight
    
    f = gcf;
    f.Position = [178   480   960   397]; % [620   546   486   421];
    sgtitle(strcat("Fly ", string(flyId)))

    save_str = strcat("Fly_", string(flyId), ".pdf");

    fname = fullfile(fig_save_folder, save_str);
    exportgraphics(f ...
        , fname ...
        , 'ContentType', 'vector' ...
        , 'BackgroundColor', 'none' ...
        ); 

    close
end 



