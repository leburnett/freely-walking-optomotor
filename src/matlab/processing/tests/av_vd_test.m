
% Viewing distance and turning rate. 

fps = 30; 
sex = "F";
strain = "jfrc100_es_shibire_kir";
data = DATA.(strain).(sex);
cond_n = 1; 

n_exp = length(data); % Number of experiments run for this strain / sex.

exp_n = 1;

av_data = data(exp_n).R1_condition_1.av_data;
curv_data = data(exp_n).R1_condition_1.curv_data;
view_dist = data(exp_n).R1_condition_1.view_dist;
dist_data = data(exp_n).R1_condition_1.dist_data;
fv_data =  data(exp_n).R1_condition_1.fv_data;


fly_id = 1;

distt = dist_data(fly_id, :);
vd = view_dist(fly_id, :);
av = av_data(fly_id, :);
fv = fv_data(fly_id, :);

figure; 
subplot(1,3, 1); plot(distt)
subplot(1,3,2); scatter(distt(rngg), abs(av(rngg)), 60, fv(rngg), 'o');
colorbar
rngg = 300:800;
subplot(1,3,3); scatter(vd(rngg), abs(av(rngg)), 60, fv(rngg), 'o');
colorbar

av_data   = data(exp_n).R1_condition_1.av_data;
curv_data = data(exp_n).R1_condition_1.curv_data;
view_dist = data(exp_n).R1_condition_1.view_dist;
dist_data = data(exp_n).R1_condition_1.dist_data;
fv_data   = data(exp_n).R1_condition_1.fv_data;


%%

fly_id = 4;

distt = dist_data(fly_id, :);
vd    = view_dist(fly_id, :);
av    = av_data(fly_id, :);
fv    = fv_data(fly_id, :);

rngg = 300:1200;

% figure;

subplot(1,4,1);
plot(distt);
title('distt');

subplot(1,4,2);
scatter(distt(rngg), abs(av(rngg)), 60, fv(rngg), 'filled');
colorbar;
title('distt vs |av| colored by fv');

subplot(1,4,3);
scatter(vd(rngg), abs(av(rngg)), 60, fv(rngg), 'filled');
colorbar;
title('vd vs |av| colored by fv');

% ---- 4th subplot: Binned data over 15 timepoints ----
binSize = 15;

% Extract the relevant section
vd_sel = vd(rngg);
av_sel = abs(av(rngg));
fv_sel = fv(rngg);

% Number of bins
nBins = floor(length(vd_sel) / binSize);

% Preallocate bin means
vd_bin = zeros(1, nBins);
av_bin = zeros(1, nBins);
fv_bin = zeros(1, nBins);

% Compute bin averages
for i = 1:nBins
    idx = (i-1)*binSize + (1:binSize);
    vd_bin(i) = mean(vd_sel(idx));
    av_bin(i) = mean(av_sel(idx));
    fv_bin(i) = mean(fv_sel(idx));
end

subplot(1,4,4);
scatter(vd_bin, av_bin, 60, fv_bin, 'filled');
title('Binned (15pt) vd vs |av| colored by fv');
xlabel('vd (binned)');
ylabel('|av| (binned)');

f = gcf;
f.Position = [1938  439   2647  385];




%%

figure

for j = 1:30

    exp_n = j;

    av_data = data(exp_n).R1_condition_1.av_data;
    curv_data = data(exp_n).R1_condition_1.curv_data;
    view_dist = data(exp_n).R1_condition_1.view_dist;
    dist_data = data(exp_n).R1_condition_1.dist_data;
    fv_data =  data(exp_n).R1_condition_1.fv_data;

    n_flies = height(fv_data);

    for i = 1:n_flies
    
    fly_id = i;
    
    distt = dist_data(fly_id, :);
    vd    = view_dist(fly_id, :);
    av    = av_data(fly_id, :);
    fv    = fv_data(fly_id, :);
    
    rngg = 300:1200;
    
    binSize = 6;
    
    % Extract the relevant section
    vd_sel = vd(rngg);
    av_sel = abs(av(rngg));
    fv_sel = fv(rngg);
    dd_sel = distt(rngg);
    
    % Number of bins
    nBins = floor(length(vd_sel) / binSize);
    
    % Preallocate bin means
    vd_bin = zeros(1, nBins);
    av_bin = zeros(1, nBins);
    fv_bin = zeros(1, nBins);
    dd_bin = zeros(1, nBins);
    
    % Compute bin averages
    for ii = 1:nBins
        idx = (ii-1)*binSize + (1:binSize);
        vd_bin(ii) = mean(vd_sel(idx));
        av_bin(ii) = mean(av_sel(idx));
        fv_bin(ii) = mean(fv_sel(idx));
        dd_bin(ii) = mean(dd_sel(idx));
    end

    idx_0 = find(av_bin < 0.5);
    vd_bin(idx_0) = [];
    av_bin(idx_0) = []; 
    dd_bin(idx_0) = [];
    fv_bin(idx_0) = [];

    idx_1 = find(fv_bin < 5);
    vd_bin(idx_1) = [];
    av_bin(idx_1) = []; 
    dd_bin(idx_1) = [];
    fv_bin(idx_1) = [];
    
    hold on;
    scatter(vd_bin, av_bin, 10, dd_bin, 'filled');
    
    end 

end 

ax = gca;
ax.TickDir = "out";
ax.LineWidth = 1.2;
ax.FontSize = 14;
xlabel("Viewing distance (mm)")
ylabel("Angular velocity (^o s^-^1)")
% ylabel("Forward velocity (mm s^-^1)")
% ylabel("Turning rate (^o mm^-^1)")

   % 
   % vd_sel = vd(rngg(1:end-binSize));
   %  av_sel = abs(av(rngg(1+binSize:end)));
   %  fv_sel = fv(rngg(1:end-binSize));
   %  dd_sel = distt(rngg(1:end-binSize));
   % 

%% Box and whisker plot

figure

% Collect all binned data across experiments & flies
all_vd = [];   % viewing distances (per time bin)
all_av = [];   % angular velocities (per time bin)

for j = 1:30

    exp_n = j;

    av_data   = data(exp_n).R1_condition_1.curv_data;
    curv_data = data(exp_n).R1_condition_1.curv_data;
    view_dist = data(exp_n).R1_condition_1.view_dist;
    dist_data = data(exp_n).R1_condition_1.dist_data;
    fv_data   = data(exp_n).R1_condition_1.fv_data;

    n_flies = height(fv_data);

    for i = 1:n_flies

        fly_id = i;

        distt = dist_data(fly_id, :);
        vd    = view_dist(fly_id, :);
        av    = av_data(fly_id, :);
        fv    = fv_data(fly_id, :);

        rngg = 350:800;
        binSize = 6;

        % Extract the relevant section
        vd_sel = vd(rngg);
        av_sel = abs(av(rngg));
        fv_sel = fv(rngg);
        dd_sel = distt(rngg);

        % Number of bins (time-bins over rngg)
        nBins = floor(length(vd_sel) / binSize);

        % Preallocate bin means
        vd_bin = zeros(1, nBins);
        av_bin = zeros(1, nBins);
        fv_bin = zeros(1, nBins);
        dd_bin = zeros(1, nBins);

        % Compute bin averages
        for ii = 1:nBins
            idx = (ii-1)*binSize + (1:binSize);
            vd_bin(ii) = mean(vd_sel(idx));
            av_bin(ii) = mean(av_sel(idx));
            fv_bin(ii) = mean(fv_sel(idx));
            dd_bin(ii) = mean(dd_sel(idx));
        end

        % Apply your filters
        idx_0 = find(av_bin < 0.5);
        vd_bin(idx_0) = [];
        av_bin(idx_0) = [];
        dd_bin(idx_0) = [];
        fv_bin(idx_0) = [];

        idx_1 = find(fv_bin < 5);
        vd_bin(idx_1) = [];
        av_bin(idx_1) = [];
        dd_bin(idx_1) = [];
        fv_bin(idx_1) = [];

        % Collect into pooled arrays for boxplotting
        all_vd = [all_vd, vd_bin];
        all_av = [all_av, av_bin];

    end
end

%% Make box & whisker plot of av vs binned vd
figure;

% Choose bin width in vd units (e.g. 20 mm)
binWidth = 20;

% Define edges based on pooled vd range
minVd = floor(min(all_vd) / binWidth) * binWidth;
maxVd = ceil(max(all_vd) / binWidth) * binWidth;
edges = minVd:binWidth:maxVd;

% Assign each vd to a bin
[~, ~, binIdx] = histcounts(all_vd, edges);

% Only keep points that fall into a defined bin
valid = binIdx > 0;
binIdx = binIdx(valid);
av_for_plot = all_av(valid);

% Optional: create human-readable labels like "0–20", "20–40", etc.
binLabels = arrayfun(@(a,b) sprintf('%d–%d', a, b), ...
                     edges(1:end-1), edges(2:end), 'UniformOutput', false);

% Make the boxplot: group by bin index
boxplot(av_for_plot, binIdx, 'Labels', binLabels);

ax = gca;
ax.TickDir = "out";
ax.LineWidth = 1.2;
ax.FontSize = 14;

xlabel('Viewing distance (mm)')
ylabel('Angular velocity (^\circ s^{-1})')  % uses TeX interpreter by default
title(sprintf('Angular velocity across viewing distance bins (%d mm)', binWidth))



%% Box and whisker per fly


figure

% ---------- USER-SETTABLE PARAMETERS ----------
binWidth = 20;          % width of viewing distance bins (mm)
vd_min   = 0;           % minimum viewing distance for binning
vd_max   = 300;         % maximum viewing distance for binning
edges    = vd_min:binWidth:vd_max;   % bin edges for viewing distance
% ---------------------------------------------

nVdBins = numel(edges) - 1;

% These will hold mean av per fly per vd-bin
all_av_fly   = [];   % one value per (fly, vd-bin) that has data
all_bin_idx  = [];   % which vd-bin that value belongs to

for j = 1:30

    exp_n = j;

    av_data   = data(exp_n).R1_condition_1.curv_data;
    curv_data = data(exp_n).R1_condition_1.curv_data;
    view_dist = data(exp_n).R1_condition_1.view_dist;
    dist_data = data(exp_n).R1_condition_1.dist_data;
    fv_data   = data(exp_n).R1_condition_1.fv_data;

    n_flies = height(fv_data);

    for i = 1:n_flies

        fly_id = i;

        distt = dist_data(fly_id, :);
        vd    = view_dist(fly_id, :);
        av    = av_data(fly_id, :);
        fv    = fv_data(fly_id, :);

        rngg    = 300:1200;
        binSize = 6;   % time-binning size

        % Extract relevant section
        vd_sel = vd(rngg);
        av_sel = abs(av(rngg));
        fv_sel = fv(rngg);
        dd_sel = distt(rngg);

        % Number of time-bins over this window
        nBins = floor(length(vd_sel) / binSize);

        % Preallocate bin means (time-binned)
        vd_bin = zeros(1, nBins);
        av_bin = zeros(1, nBins);
        fv_bin = zeros(1, nBins);
        dd_bin = zeros(1, nBins);

        % Compute time-bin averages
        for ii = 1:nBins
            idx = (ii-1)*binSize + (1:binSize);
            vd_bin(ii) = mean(vd_sel(idx));
            av_bin(ii) = mean(av_sel(idx));
            fv_bin(ii) = mean(fv_sel(idx));
            dd_bin(ii) = mean(dd_sel(idx));
        end

        % Apply your filters
        idx_0 = (av_bin < 0.5);
        vd_bin(idx_0) = [];
        av_bin(idx_0) = [];
        dd_bin(idx_0) = [];
        fv_bin(idx_0) = [];

        idx_1 = (fv_bin < 5);
        vd_bin(idx_1) = [];
        av_bin(idx_1) = [];
        dd_bin(idx_1) = [];
        fv_bin(idx_1) = [];

        % If nothing left after filtering, skip this fly
        if isempty(vd_bin)
            continue
        end

        % ---------- PER-FLY vd-BINNING ----------
        % Assign each vd_bin (time-binned distance) to a distance bin
        [~, ~, vBinIdx] = histcounts(vd_bin, edges);

        % Loop over distance bins and compute mean av for this fly in each bin
        for b = 1:nVdBins
            mask = (vBinIdx == b);
            if any(mask)
                % mean av for THIS fly in this vd-bin
                av_mean_fly_bin = mean(av_bin(mask));

                % store the per-fly per-bin value
                all_av_fly(end+1)  = av_mean_fly_bin; 
                all_bin_idx(end+1) = b;               
            end
        end

    end
end

%% Make box & whisker plot using per-fly bin means

% Keep only valid bin indices
valid = all_bin_idx > 0;
all_av_fly  = all_av_fly(valid);
all_bin_idx = all_bin_idx(valid);

% Create labels like "0–20", "20–40", etc.
binLabels = arrayfun(@(a,b) sprintf('%d–%d', a, b), ...
                     edges(1:end-1), edges(2:end), 'UniformOutput', false);

boxplot(all_av_fly, all_bin_idx, 'Labels', binLabels);

ax = gca;
ax.TickDir   = "out";
ax.LineWidth = 1.2;
ax.FontSize  = 14;

xlabel('Viewing distance (mm)')
ylabel('Mean angular velocity per fly (^\circ s^{-1})')
title(sprintf('Per-fly mean angular velocity across viewing distance bins (%d mm)', binWidth))




%% Histogram visualization (one per vd bin)

figure;

uniqueBins = 1:(numel(edges)-1);
uniqueBins = uniqueBins(1:12);
nBins = numel(uniqueBins);

% Layout for subplots
nRows = ceil(sqrt(nBins));
nCols = ceil(nBins / nRows);

for b = uniqueBins
    subplot(nRows, nCols, b)
    
    % Pull values from this vd-bin
    vals = all_av_fly(all_bin_idx == b);
    
    if isempty(vals)
        continue
    end
    
    histogram(vals, 'Normalization', 'pdf');  % pdf = comparable height
    
    title(binLabels{b})
    xlabel('Mean AV per fly (°/s)')
    ylabel('Density')
    xlim([0 250])

    ax = gca;
    ax.TickDir = "out";
    ax.LineWidth = 1.1;
    ax.FontSize = 11;
end

sgtitle('Per-fly mean angular velocity — histogram by viewing-distance bin')


%% Overlayed histograms

figure; hold on

colors = lines(numel(edges)-1);

for b = 1:(numel(edges)-1)
    vals = all_av_fly(all_bin_idx == b);
    if isempty(vals)
        continue
    end
    
    histogram(vals, ...
        'Normalization', 'pdf', ...
        'EdgeColor', colors(b,:), ...
        'DisplayStyle', 'stairs', ...
        'LineWidth', 1.5);
end

legend(binLabels, 'Location', 'northeastoutside')
xlabel('Mean AV per fly (°/s)')
ylabel('Density')
title('Per-fly mean angular velocity — overlaid histograms')

ax = gca;
ax.TickDir = "out";
ax.LineWidth = 1.2;
ax.FontSize = 13;







