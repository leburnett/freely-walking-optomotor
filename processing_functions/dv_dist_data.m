

strain = "jfrc100_es_shibire_kir";
sex= "F";

data = DATA.(strain).(sex); 
n_exp = length(data); % Number of experiments run for this strain / sex.

idx2 = 1;

data_type = "dist_data";

rep1_str = strcat('R1_condition_', string(idx2));   
rep2_str = strcat('R2_condition_', string(idx2));  

% contains one row per fly and rep - combines data across all flies and all reps.
cond_data = []; 
nf_comb = size(cond_data, 2);

for idx = 1:n_exp
    % disp(idx)

    rep1_data = data(idx).(rep1_str);

    if ~isempty(rep1_data) % check that the row is not empty.

        % Extract the relevant data
        rep1_data = rep1_data.(data_type);
        rep2_data = data(idx).(rep2_str).(data_type);

        % Number of frames in each rep
        nf1 = size(rep1_data, 2);
        nf2 = size(rep2_data, 2);

        if nf1>nf2
            nf = nf2;
        elseif nf2>nf1
            nf = nf1;
        else 
            nf = nf1;
        end 

        % Trim data to same length
        rep1_data = rep1_data(:, 1:nf);
        rep2_data = rep2_data(:, 1:nf);

        % Initialise empty array:
        rep_data = zeros(size(rep1_data));

        nf_comb = size(cond_data, 2);

        if idx == 1 || nf_comb == 0 % 

            for rr = 1:size(rep1_data, 1)
                rep_data(rr, :) = mean(vertcat(rep1_data(rr, :), rep2_data(rr, :)));
            end 

        else
            if nf>nf_comb % trim incoming data
                rep1_data = rep1_data(:, 1:nf_comb);
                rep2_data = rep2_data(:, 1:nf_comb);
            elseif nf_comb>nf % Add NaNs to end
                diff_f = nf_comb-nf+1;
                n_flies = size(rep1_data, 1);
                rep1_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
                rep2_data(:, nf:nf_comb) = NaN(n_flies, diff_f);
            end 
            rep_data = zeros(size(rep1_data));
            % For 'cond_data' have one row per fly - mean of 2
            % reps - not one row per rep. 
            for rr = 1:size(rep1_data, 1)
                rep_data(rr, :) = mean(vertcat(rep1_data(rr, :), rep2_data(rr, :)));
            end 
        end
        % disp(height(rep_data))
        cond_data = vertcat(cond_data, rep_data);

    end 

end 












% Relationship between the position of the fly at the beginning of the
% stimulus versus the amount the fly moves towards the centre. 

% Use only condition 1 - 4Hz 60deg gratings - protocol 24 - ES flies.

n_flies = height(cond_data);

figure
for idx = 1:n_flies
    d = cond_data(idx, :);
    d_start = mean(d(285:315)); % 30 frames - 1s
    % d_stim = mean(d(735:765)); % 30 frames - 1s - midway through stimulus
    d_stim = mean(d(885:915)); % 30 frames - 1s
    plot(d_start, d_stim, 'ko');
    hold on
end

xlim([0 120])
ylim([0 120])
axis square
hold on 
% plot([0 120], [100 100], 'k', 'LineWidth', 0.3)
% plot([100 100], [0 120], 'k', 'LineWidth', 0.3)
plot([0 120], [0 120], 'k', 'LineWidth', 0.3)

xlabel('Distance from centre at start (mm)')
ylabel('Distance from centre at end of gratings (mm)')

%% During the grating stimulus - find when the fly is moving the fastest towards the centre. 
% 1 - WHEN was this during the stimulus? Early? Late?
% 2 - WHERE was the fly - distance from the edge - when this happened?

n_flies = height(cond_data);

time_peak = zeros(1, n_flies);
val_peak = zeros(1, n_flies);
dist_peak = zeros(1, n_flies);

figure
for idx = 1:n_flies
    d = movmean(cond_data(idx, :), 10);
    dv = diff(d);
    time_peak(1,idx) = find(dv(300:1200)==min(dv(300:1200)));
    val_peak(1,idx) = min(dv(300:1200));
    dist_peak(1,idx) = d(time_peak(1, idx)+300);

    subplot(1,2,1)
    plot(time_peak(idx), val_peak(idx), 'ko');
    hold on
    subplot(1,2,2)
    plot(dist_peak(idx),val_peak(idx), 'ko');
    hold on
end


figure; histogram(time_peak)
figure; histogram(val_peak)
figure; histogram(dist_peak)

%% Whether the extent of centring behaviour is related to the fly's distance from the centre.
% Compare the maximum centring of a fly to the location where this maximum
% centring happened.

% Define bin edges (0 to max distance, in 10mm increments)
bin_edges = 0:10:120;

% Assign each value to a bin
[~, ~, bin_idx] = histcounts(dist_peak, bin_edges);

% Compute mean val_peak per bin
bin_means = accumarray(bin_idx(bin_idx > 0)', abs(val_peak(bin_idx > 0))', [], @median, NaN);

% Create X-axis labels (bin centers)
bin_centers = bin_edges(1:end-1) + diff(bin_edges)/2;

% Plot heatmap
figure;
heatmap(bin_centers, 1, bin_means', 'Colormap', sky);
xlabel('Distance Bins (mm)');
ylabel('');
title('Median centring val per distance bin');
colorbar;
caxis([0.6 0.79])

%% Whether the extent of centring behaviour is related to how long the stimulus has been on. 
% Compare the maximum centring of a fly to the time during the grating stimulus when this maximum
% centring happened.

% Define bin edges (0 to max distance, in 10mm increments)
bin_edges = 0:120:900;

% Assign each value to a bin
[~, ~, bin_idx] = histcounts(time_peak, bin_edges);

% Compute mean val_peak per bin
bin_means = accumarray(bin_idx(bin_idx > 0)', abs(val_peak(bin_idx > 0))', [], @median, NaN);

% Create X-axis labels (bin centers)
bin_centers = bin_edges(1:end-1) + diff(bin_edges)/2;

% Plot heatmap
figure;
heatmap(bin_centers, 1, bin_means', 'Colormap', sky);
xlabel('Time Bins (frames)');
ylabel('');
title('Median centring val per time bin');
colorbar;
caxis([0.54 0.76])


% Histogram
figure; histogram(time_peak, 'BinEdges', bin_edges)
ylabel('No. of flies')
xlim([0 900])
ylim([0 25])











%%
d_start = zeros(1, n_flies);
d_stim = zeros(1, n_flies);
d_delta = zeros(1, n_flies);

figure
for idx = 1:n_flies
    d = cond_data(idx, :);
    d_start(1,idx) = mean(d(295:305));
    % d_stim(1, idx) = mean(d(850:900)); % end of stim
    d_stim(1, idx) = mean(d(1185:1215)); % end of stim
    % d_stim(1, idx) = mean(d(735:765)); % middle of stim
    d_delta(1, idx) = d_stim(1, idx) - d_start(1, idx);
    plot(d_start(1, idx), d_delta(1, idx), 'ko');
    hold on
end

xlim([0 120])
ylim([-80 20])
axis square
hold on 
% plot([0 120], [100 100], 'k', 'LineWidth', 0.3)
% plot([100 100], [0 120], 'k', 'LineWidth', 0.3)
plot([0 120], [0 0], 'k', 'LineWidth', 0.3)

xlabel('Distance from centre at start (mm)')
ylabel('Distance moved towards centre during gratings (mm)')


%% 
scatterhist(d_start, d_delta)

%%  diff(dist_data) versus dist_data

figure
for idx_fly = 1:15
    d = cond_data(idx_fly, :);
    plot(d); hold on
end 

figure; plot(movmean(d, 5))
dv = diff(movmean(d, 5));
figure; 
plot(dv)
hold on
plot([0, 1800], [0,0], 'k', 'LineWidth', 0.3)
plot([0, 1800], [0.4,0.4], 'k', 'LineWidth', 0.3)
plot([0, 1800], [-0.4,-0.4], 'k', 'LineWidth', 0.3)

plot([300, 300], [-1,1], 'r', 'LineWidth', 1)
plot([1200, 1200], [-1,1], 'r', 'LineWidth', 1)
ylim([-1 1])

% 
dv = zeros(n_flies, 1807);
d = zeros(n_flies, 1808);

figure
for idx_fly = 1:15
    d(idx_fly, :) = movmean(cond_data(idx_fly, :), 10);
    dv(idx_fly, :) = diff(d(idx_fly, :));
    plot(dv(idx_fly, :)); hold on
end

dv_mean = mean(dv);
plot(dv_mean, 'k', 'LineWidth', 2)


%%

idx_fly = 3;

% 
figure; 
subplot(5,1,1)
plot(d(idx_fly, :));
hold on;
plot([300, 300], [0,120], 'r', 'LineWidth', 1)
plot([1200, 1200], [0,120], 'r', 'LineWidth', 1)
ylim([0 120])
xlim([0 1800])

subplot(5,1,2)
plot(dv(idx_fly, :)); hold on;
plot([0, 1800], [0,0], 'k', 'LineWidth', 0.3)
plot([300, 300], [-1,1], 'r', 'LineWidth', 1)
plot([1200, 1200], [-1,1], 'r', 'LineWidth', 1)
ylim([-1 1])
xlim([0 1800])

% dv versus dist from centre. 
subplot(5,1,3)
plot(d(idx_fly, 1:300), dv(idx_fly, 1:300), 'k'); hold on;
plot(d(idx_fly, 301:1200), dv(idx_fly, 301:1200), 'r')
plot(d(idx_fly, 1201:1807), dv(idx_fly, 1201:1807), 'k')
plot([0, 120], [0,0], 'k', 'LineWidth', 0.3)

subplot(5,1,4)
plot(av(idx_fly, :));
hold on;
plot([300, 300], [-350,350], 'r', 'LineWidth', 1)
plot([1200, 1200], [-350,350], 'r', 'LineWidth', 1)
ylim([-350 350])
xlim([0 1800])

subplot(5,1,5)
plot(dv_av(idx_fly, :)); hold on;
plot([0, 1800], [0,0], 'k', 'LineWidth', 0.3)
plot([300, 300], [-30,30], 'r', 'LineWidth', 1)
plot([1200, 1200], [-30,30], 'r', 'LineWidth', 1)
ylim([-30 30])
xlim([0 1800])

f2 = gcf;
f2.Position = [272   380   835   548];


% Add angular velocity to this!!!! 

% Moving towards centre - if dist_data decreases. 

% difference in distance towards the centre
a = dv(idx_fly, 300:1200);
a = dv(idx_fly, 1200:end);


a_pos = a(a>=0);
a_neg = a(a<0);

sum(abs(a_pos))
sum(abs(a_neg))

%% Find out when the rate of change of distance to the centre is highest. 
% Where was the fly - distance to centre - when the speed was highest? 
% 

% Add angular velocity. 
% av = zeros(n_flies, 1808);
% dv_av = zeros(n_flies, 1807);
% for idx_fly = 1:15
%     av(idx_fly, :) = movmean(cond_data(idx_fly, :), 10);
%     dv_av(idx_fly, :) = diff(av(idx_fly, :));
% end


















