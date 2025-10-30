%% Make polarplots - phototaxis conditions. 
% Requires DATA. 


%% Plot the figure - subplots with polar plots for each individual fly - 2 reps. 

% for entryIdx = [28,29,30]
%     plot_polar_hist_subplot_one_cohort(DATA, entryIdx);
% end 


%% Plot one polar plot per rep across all flies of the cohort:

close

% Parameters
% entryIdx = 8;                    % which DATA entry to use

for entryIdx = 8:1:30
    condNames = {'R1_condition_12','R2_condition_12'};
    framesA  = 1:300;
    framesB  = 300:2200;
    numBins  = 24;                   % 15° bins
    normMode = 'probability';              % or 'probability'
    
    S1 = DATA(entryIdx).(condNames{1});
    S2 = DATA(entryIdx).(condNames{2});
    
    % Figure + tiled layout (1 row, 2 columns)
    fig = figure('Name','All Flies — Polar Histograms','Color','w');
    t = tiledlayout(1, numel(condNames), 'TileSpacing','compact','Padding','compact');
    
    % Overall title using metadata
    try
        dtStr = string(DATA(entryIdx).meta.date);
        tmStr = string(DATA(entryIdx).meta.time);
        sgtitle(t, sprintf('Heading relative to reference (0°=N, CW) — %s %s', strrep(dtStr,'_','-'), tmStr));
    catch
        sgtitle(t, 'Heading relative to reference (0°=N, CW)');
    end
    
    %% Left: R1 (all flies)
    ax1 = polaraxes(t);         % parent the polar axes to the tiledlayout
    ax1.Layout.Tile = 1;
    polar_hist_all_flies(ax1, S1, framesA, framesB, struct( ...
        'numBins', numBins, 'Normalization', normMode, 'titleStr', 'R1 — All flies'));
    
    %% Right: R2 (all flies)
    ax2 = polaraxes(t);
    ax2.Layout.Tile = 2;
    polar_hist_all_flies(ax2, S2, framesA, framesB, struct( ...
        'numBins', numBins, 'Normalization', normMode, 'titleStr', 'R2 — All flies'));
    
    % Optional legend (place once, e.g., under the second axes)
    legend(ax2, {'1-300','300-2200'}, 'Location','southoutside');
end 


%% 

% --- Configuration ---
entryIdx = 2;
condName = 'R1_condition_12';    % or 'R2_condition_12'
S = DATA(entryIdx).(condName);

winSize = 90;   % sliding window width (frames)
stepSize = 10;   % step between windows
stimFrame = 300; % stimulus onset
ref_mm = [29.7426, 52.5293];

% Compute heading_rel_ref if not present
if ~isfield(S,'heading_rel_ref') || isempty(S.heading_rel_ref)
    dx = ref_mm(1) - S.x_data;
    dy = ref_mm(2) - S.y_data;
    bearing = atan2d(dy, dx);
    hw = S.heading_wrap;
    S.heading_rel_ref = mod(bearing - hw + 180, 360) - 180;
end

% Parameters
nFrames = size(S.heading_rel_ref,2);
winStarts = 1:stepSize:(nFrames - winSize + 1);
winCenters = winStarts + winSize/2;
meanResultantLength = zeros(size(winStarts));
meanAngle = zeros(size(winStarts));

% --- Sliding window analysis ---
for k = 1:numel(winStarts)
    idx = winStarts(k):(winStarts(k)+winSize-1);
    ang = S.heading_rel_ref(:, idx);
    ang = ang(:);   % all flies together
    ang_rad = deg2rad(ang);

    % Compute circular statistics
    R = mean(exp(1i * ang_rad));    % mean resultant vector
    meanResultantLength(k) = abs(R);
    meanAngle(k) = rad2deg(angle(R));  % mean direction in degrees
end

% --- Plot: concentration over time ---
figure;
subplot(2,1,1);
plot(winCenters, meanResultantLength, 'k-', 'LineWidth', 1.5);
xlabel('Frame');
ylabel('Mean resultant length (R)');
title(sprintf('%s — Orientation strength toward landmark', strrep(condName, '_', '-')));
xline(stimFrame, 'r--', 'Stimulus on');
grid on;

% --- Plot: mean heading over time ---
subplot(2,1,2);
plot(winCenters, meanAngle, 'b-', 'LineWidth', 1.5);
xlabel('Frame');
ylabel('Mean heading (° rel. to landmark)');
xline(stimFrame, 'r--', 'Stimulus on');
ylim([-180 180]);
grid on;




%% Across all flies:

figure
for idx = 1:415
    plot(all_heading_rel(idx, :), 'Color', [0.7 0.7 0.7]); 
    hold on
end 

figure; plot(mean(all_heading_rel), 'Color', 'k', 'LineWidth', 1.5)
hold on
plot([300 300], [-15 20], 'r')
plot([0 2253], [0 0], 'r')



%%

% Collect across all entries/flies; NaN-pad to maxFrames as you did before
ALL = all_heading_rel;                 % [nTraces x nFrames], may contain NaN
A = cosd(ALL);                         % towardness in [-1,1]
Amean = mean(A,1,'omitnan');

% Smooth (choose window to taste, e.g., 21 frames)
Amean_sm = movmean(Amean, 21, 'omitnan');

% Bootstrap CI (e.g., 1000 resamples)
B = 1000; n = size(A,1);
Aboot = zeros(B, size(A,2));
for b=1:B
    idx = randi(n, n, 1);
    Aboot(b,:) = mean(A(idx,:),1,'omitnan');
end
CIlo = prctile(Aboot, 2.5, 1); CIhi = prctile(Aboot, 97.5, 1);

% Plot
figure('Color','w'); 
plot(Amean_sm,'k','LineWidth',1.5); hold on;
plot(CIlo,'--','Color',[.6 .6 .6]); plot(CIhi,'--','Color',[.6 .6 .6]);
xline(300,'r--','Stim on');
ylabel('Towardness 〈cos θ〉'); xlabel('Frame'); grid on;
title('Time-resolved towardness with bootstrap 95% CI');


%% 


win = 100; step = 10;
[nTraces, nFrames] = size(ALL);
starts = 1:step:max(1, nFrames-win+1);
Rlen = nan(size(starts)); P = nan(size(starts));

for k=1:numel(starts)
    idx = starts(k):(starts(k)+win-1);
    ang = deg2rad(ALL(:,idx)); ang = ang(:);
    ang = ang(~isnan(ang));
    if isempty(ang), continue; end
    R = abs(mean(exp(1i*ang)));
    Rlen(k) = R;
    n = numel(ang);
    z = n * R^2;
    % Rayleigh p-value (large-sample approximation)
    P(k) = exp(sqrt(1+4*n+4*(n^2 - z^2)) - (1 + 2*n)); % alt: use exp(-z)*(1 + (2*z - z^2)/(4*n) - ...)
end

figure('Color','w');
subplot(2,1,1); plot(starts+win/2, Rlen,'k','LineWidth',1.5); grid on;
xline(300,'r--'); ylabel('R (mean resultant length)'); title('Sliding Rayleigh (strength)');
subplot(2,1,2); semilogy(starts+win/2, P,'b','LineWidth',1.5); grid on;
xline(300,'r--'); ylabel('p (Rayleigh)'); xlabel('Frame');