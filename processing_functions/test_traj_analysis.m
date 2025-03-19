% Trajectory curvature

strain = 'jfrc100_es_shibire_kir';
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


data_type = "curv_data";
cond_data_curv = combine_timeseries_data_per_cond(DATA, strain, sex, data_type, cond_idx);

dataa = cond_data_curv(3, :);
dataa(abs(dataa)>1000)=NaN;
dataa = fillmissing(dataa', 'previous')';

figure; plot((dataa)


%% How I currently calculate turning rate:

    % c_data = [];
    % c_data = av_data(idx, :)./fv_data(idx, :);
    % vals_fv_zero = abs(fv_data(idx, :))<0.1;
    % c_data(abs(c_data)==Inf)=NaN;
    % c_data(vals_fv_zero) = NaN;
    % c_data = fillmissing(c_data', 'previous')';
    % curv_data(idx, :) = c_data;


time_data = 0:1/30:60.266;
bin_size = 0.2;
[binned_time, binned_turning_rate] = binTurningRate(time_data', dataa', bin_size);

figure; plot(binned_turning_rate)


nanmean(dataa(1202:1800))

figure; plot(movmean(gradient(dataa), 10))


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





































