
strain = "ss00297_Dm4_shibire_kir";
exp = 3;
fly_id = 5;

% 1 - BIN DATA PER FLY FIRST THEN AVERAGE ACROSS FLIES

data = DATA.(strain).F(exp).R1_condition_2.vel_data;
d_fly = data(fly_id, :);

data2 = DATA.(strain).F(exp).R1_condition_2.fv_data;
d_fly2 = data2(fly_id, :);

data_av = DATA.(strain).F(exp).R1_condition_2.av_data;
ang_vel =data_av(fly_id, :);

data3 = DATA.(strain).F(exp).R1_condition_2.curv_data;
d_fly3 = data3(fly_id, :);

%% 
xvals = 28341:1:28341+900;

% Plot as subplots. 
figure; 
subplot(2,1,1)
yyaxis left; plot(xvals, d_fly(300:1200)); hold on; plot(xvals, d_fly2(300:1200))
yyaxis right; plot(xvals, abs(ang_vel(300:1200)));
subplot(2,1,2)
plot(xvals, abs(d_fly3(300:1200))); yscale log;


% Cycles (360 deg) per second. 
figure; plot(xvals, abs(ang_vel(300:1200))/360); 

% Plot all on one figure;
figure;
yyaxis left;
plot(xvals, d_fly(300:1200)); hold on; 
yyaxis right;
plot(xvals, abs(ang_vel(300:1200)));
plot(xvals, abs(d_fly3(300:1200))/10, 'k-');

%% Plot smooth plots

sm_w = 15;

figure; 
subplot(4,1,1)
sm_1 = movmean(d_fly, sm_w);
plot(sm_1);

subplot(4,1,2)
sm_2 = movmean(d_fly2, sm_w);
plot(sm_2);

subplot(4,1,3)
sm_3 = movmean(abs(ang_vel), sm_w);
plot(sm_3);

subplot(4,1,4)
sm_4 = movmean(abs(d_fly3), sm_w);
plot(sm_4);


%%
total_degrees_turned_during_stim = sum(sm_3(300:1200));

% Smooth the turning
turning_smoothed=movmean(abs(d_fly3(300:1200)), 15);

% Find peaks > 40 deg mm-1
[pks, locs, ~, p] = findpeaks(turning_smoothed, 'MinPeakProminence', 40);

% Mean peak prominance
mean_pp = mean(p);

% Number of peaks - i.e. sharp turns. 
num_peaks = numel(pks);

% Plot the peaks. 
figure; plot(turning_smoothed);
hold on;
text(locs+.02,pks,num2str((1:numel(pks))'))

%% During acclim period

figure;
yyaxis left;
plot(d_fly(1:300)); hold on; 
yyaxis right;
plot(abs(ang_vel(1:300)));
plot(abs(d_fly3(1:300))/10, 'k-');



%% Combine all data across the acclim period in dark - what is the average 

% Access the 21 entries
entries = DATA.jfrc100_es_shibire_kir.F;

% Preallocate a cell array to hold the [15 x 9000] matrices
fv_cells = cell(1, numel(entries));

% Loop through and extract each fv_data matrix
for i = 1:numel(entries)
    ddd = entries(i).acclim_off1.av_data;
    fv_cells{i} = ddd(:, 1:9000);
end

% Concatenate all [15 x 9000] matrices vertically to get [15*21 x 9000]
fv_all = vertcat(fv_cells{:});

% Plot histogram 
figure; histogram(abs(fv_all));
% Find mean 
mean(mean(abs(fv_all))) % % % 54.5 deg s-1


%% Straightness of path - entire stimulus time

sum(sm_1) % sum vel
sum(sm_4) % turning 

sum(sm_4)/sum(sm_1) % total turning / total displacement. 

%% Straightness of path - over 0.5s time bins. 




%%

% Assume:
% heading: [1, N] in degrees (e.g., from tracking)
% fwd_vel: [1, N] in mm/s
% dt = 1/30;  % 30 Hz

heading_data =  DATA.jfrc100_es_shibire_kir.F(12).R1_condition_2.heading_wrap;
heading = heading_data(1, :);
% Step 1a: Unwrap heading to avoid 360→0 jumps
heading_unwrapped = unwrap(deg2rad(heading));  % convert to radians and unwrap

% Step 1b: Compute change in heading (rad) per frame
delta_theta = diff(heading_unwrapped);  % radians/frame

% Step 1c: Compute distance walked per frame
delta_s = fwd_vel(1:end-1) * dt;  % mm/frame

% Step 1d: Compute curvature (rad/mm)
curvature_path = delta_theta ./ (delta_s + 1e-6);  % rad/mm

% Convert angular velocity from deg/s to rad/s for comparison
ang_vel_rad = deg2rad(ang_vel);  % rad/s
turning_rate_vel = ang_vel_rad ./ (fwd_vel + 1e-6);  % rad/mm

% Align lengths
turning_rate_vel = turning_rate_vel(1:end-1);

% Correlation or plotting
corrcoef(curvature_path, turning_rate_vel)
figure; plot(curvature_path); hold on; plot(turning_rate_vel); legend('Curvature from heading', 'Turning rate from velocity');

turning_rate_mag = abs(turning_rate);
curvature_mag = abs(curvature_path);


window_size = 15;  % 0.5 s at 30 Hz

% Unwrap heading in radians
heading_rad = unwrap(deg2rad(heading));

% Compute curvature using a sliding window
curvature_windowed = NaN(1, length(heading));  % preallocate

for i = 1:(length(heading) - window_size)
    delta_heading = heading_rad(i + window_size) - heading_rad(i);  % rad
    delta_s = sum(fwd_vel(i:i+window_size-1)) * (1/30);  % mm
    curvature_windowed(i + floor(window_size/2)) = delta_heading / (delta_s + 1e-6);  % rad/mm
end

