% ANALYSE_PHOTOTAXIS_POLAR - Polar histogram analysis of phototaxis orientation
%
% SCRIPT CONTENTS:
%   - Section 1: Pool heading angles across all cohorts, flies, and reps
%   - Section 2: Generate polar histograms (pre vs during stimulus)
%   - Section 3: Statistical testing with per-fly circular means
%   - Section 4: V-test and Watson-Williams test
%   - Section 5: Individual fly polar plots per cohort
%   - Section 6: Speed-filtered analysis (both reps)
%   - Section 7: Distance-to-bar analysis over time
%   - Section 8: Towardness vs distance analysis (binned)
%   - Section 9: Half-arena analysis (near vs far from bar)
%
% DESCRIPTION:
%   This script performs comprehensive polar histogram analysis of fly
%   heading orientation relative to a bright bar stimulus. It computes
%   heading_rel_ref (heading relative to reference) where 0 degrees means
%   pointing directly at the bar, and +/-180 degrees means pointing away.
%
% STATISTICAL APPROACH:
%   1. Compute per-fly circular mean headings for pre and stim windows
%   2. V-test: tests if post-stim headings cluster around 0 (toward bar)
%   3. Watson-Williams: paired test comparing pre vs post distributions
%
% TIME WINDOWS (at 30fps):
%   - Pre: frames 135-285 (5s before stimulus, 0.5s buffer)
%   - Stim: frames 315-465 (first 5s of stimulus, 0.5s buffer)
%
% TOWARDNESS METRIC:
%   <cos(theta)> where theta = heading_rel_ref
%   - +1: pointing directly at bar
%   -  0: perpendicular to bar
%   - -1: pointing away from bar
%
% REQUIREMENTS:
%   - DATA struct with x_data, y_data, heading_wrap, d2bar fields
%   - Circular Statistics Toolbox (circ_vtest, circ_wwtest)
%   - Functions: polar_hist_all_flies, plot_polar_hist_subplot_one_cohort
%
% DATA FILE:
%   "/Users/burnettl/Documents/Projects/oaky_cokey/results/2025_10_30_DATA_phototaxis_with_angles.mat"
%
% See also: phototaxis_test_code, phototaxis_speed_filtered, circ_vtest, circ_wwtest

%% Make polarplots - phototaxis conditions.
% Requires DATA.
% "/Users/burnettl/Documents/Projects/oaky_cokey/results/2025_10_30_DATA_phototaxis_with_angles.mat"

%% PLOT ALL FLIES - ALL COHORTS - BOTH REPS
% Just one subplot with the pre versus post polar plots plotted on top.

%% ---- Settings ----

framesA = 135:285;    % 5s pre-stimulus - up to 0.5s before stimulus onset.
% framesA = 1700:1850;    % 5s post-stimulus
framesB = 315:465;    % 5s stimulus - 0.5s after stimulus onset. 
numBins  = 24;             % 15° bins
normMode = 'probability';  % 'count' or 'probability'
ref_mm   = [29.7426, 52.5293];
condNames = {'R1_condition_12','R2_condition_12'};  % both reps

%% ---- Collect angles across ALL entries, ALL flies, BOTH reps ----
angA_cells = {};   % will store column vectors (deg) per entry/rep
angB_cells = {};

for entryIdx = 1:numel(DATA)
    for c = 1:numel(condNames)
        if ~isfield(DATA(entryIdx), condNames{c}), continue; end
        S = DATA(entryIdx).(condNames{c});

        % Ensure heading_rel_ref exists (deg, [-180, 180])
        if ~isfield(S,'heading_rel_ref') || isempty(S.heading_rel_ref)
            dx = ref_mm(1) - S.x_data;
            dy = ref_mm(2) - S.y_data;
            bearing_to_ref = atan2d(dy, dx);            % 0°=east, +90°=south
            hw = S.heading_wrap;                         % same convention
            S.heading_rel_ref = mod(bearing_to_ref - hw + 180, 360) - 180;
        end

        nFrames = size(S.heading_rel_ref, 2);
        if nFrames == 0, continue; end

        % Clamp the requested frames to valid range for THIS entry
        idxA = framesA(framesA >= 1 & framesA <= nFrames);
        idxB = framesB(framesB >= 1 & framesB <= nFrames);

        if ~isempty(idxA)
            angA_cells{end+1} = reshape(S.heading_rel_ref(:, idxA), [], 1); 
        end
        if ~isempty(idxB)
            angB_cells{end+1} = reshape(S.heading_rel_ref(:, idxB), [], 1);
        end
    end
end

% Concatenate and convert to radians on [0, 2π)
angA_deg = vertcat(angA_cells{:});
angB_deg = vertcat(angB_cells{:});
angA = deg2rad(mod(angA_deg(~isnan(angA_deg)), 360));
angB = deg2rad(mod(angB_deg(~isnan(angB_deg)), 360));

%% ---- Single figure with ONE polar subplot (overlaid histograms) ----
fig = figure('Name','All entries + both reps — Polar histogram','Color','w');
t = tiledlayout(1,1,'TileSpacing','compact','Padding','compact');
sgtitle(t, 'Heading relative to reference (0°=N, CW)');

ax = polaraxes(t);
ax.Layout.Tile = 1;
ax.ThetaZeroLocation = 'top';     % 0° = North
ax.ThetaDir = 'clockwise';        % compass style
ax.ThetaTick = 0:30:330;

binEdges = linspace(0, 2*pi, numBins+1);
hold(ax, 'on');

% Frames A (int): light gray
polarhistogram(ax, angA, binEdges, 'Normalization', normMode, 'FaceColor',[0.7 0.7 0.7], 'FaceAlpha',0.5, 'EdgeColor',[0.7 0.7 0.7]);

% Frames B (stim): magenta
polarhistogram(ax, angB, binEdges, 'Normalization', normMode, 'FaceColor',[1 0.6 1], 'FaceAlpha',0.4, 'EdgeColor',[1 0.6 1]);

legend(ax, {sprintf('%d–%d', framesA(1), framesA(end)), sprintf('%d–%d', framesB(1), framesB(end))}, 'Location','southoutside');
title(ax, 'All flies • All cohorts • Both reps');








%% Statistical testing - data from all flies - all cohorts - both reps
% COMPUTE PER FLY MEANS FIRST THEN DO STATISTICS.

% Configuration % % % % %

% Stimulus starts at fram 300.
framesA = 135:285;    % 5s pre-stimulus - up to 0.5s before stimulus onset.
% framesA = 1700:1850;    % 5s post-stimulus
framesB = 315:465;    % 5s stimulus - 0.5s after stimulus onset.
ref_mm = [29.7426, 52.5293];
condNames = {'R1_condition_12','R2_condition_12'};  % optional

%% Collect per-fly summary stats - - - this is very useful.

perFly = [];

for entryIdx = 1:numel(DATA)
    for c = 1:numel(condNames)
        if ~isfield(DATA(entryIdx), condNames{c}), continue; end
        S = DATA(entryIdx).(condNames{c});

        % Compute heading_rel_ref if missing
        if ~isfield(S,'heading_rel_ref') || isempty(S.heading_rel_ref)
            dx = ref_mm(1) - S.x_data;
            dy = ref_mm(2) - S.y_data;
            bearing_to_ref = atan2d(dy, dx);
            hw = S.heading_wrap;
            S.heading_rel_ref = mod(bearing_to_ref - hw + 180, 360) - 180;
        end

        nFlies = size(S.heading_rel_ref,1);
        nFrames = size(S.heading_rel_ref,2);

        idxA = framesA(framesA>=1 & framesA<=nFrames);
        idxB = framesB(framesB>=1 & framesB<=nFrames);

        for f = 1:nFlies
            angA = deg2rad(S.heading_rel_ref(f, idxA));
            angB = deg2rad(S.heading_rel_ref(f, idxB));
            angA = angA(~isnan(angA)); angB = angB(~isnan(angB));
            if isempty(angA) || isempty(angB), continue; end

            % Per-fly circular means
            muA = atan2(mean(sin(angA)), mean(cos(angA)));
            muB = atan2(mean(sin(angB)), mean(cos(angB)));

            % Resultant lengths (measure of concentration)
            rA = abs(mean(exp(1i*angA)));
            rB = abs(mean(exp(1i*angB)));

            % Store
            perFly = [perFly; table(entryIdx, c, f, muA, muB, rA, rB)];
        end
    end
end

%% Test across flies
muAs = perFly.muA;
muBs = perFly.muB;
diffs = atan2(sin(muBs - muAs), cos(muBs - muAs)); % circular paired difference

% --- Test 1: Are post-stim angles clustered around 0 (V-test)?
[pV_B, ~] = circ_vtest(muBs, 0);

% --- Test 2: Paired circular test (Watson–Williams or permutation)
pWW = circ_wwtest(muAs, muBs);

fprintf('V-test toward landmark (post-stim means): p = %.3g\n', pV_B);
fprintf('Watson–Williams (paired across flies): p = %.3g\n', pWW);

% Compute and display per-fly Δmean
fprintf('Mean change (post - pre): %.1f°\n', rad2deg(mean(diffs)));

% Total number of flies:
n_flies_total = size(perFly, 1);







%% Detailed analysis - look per cohort / per fly:

%% A - individual flies: 
% Plot the figure - subplots with polar plots for each individual fly - 2 reps. 
% Size = [n_reps, n_flies]

for entryIdx = [28,29,30]
    plot_polar_hist_subplot_one_cohort(DATA, entryIdx);
end 


%% B - one cohort:
% Plot one polar plot per rep across all flies of the cohort:
% Size = [1, n_reps]

close

for entryIdx = 1
    condNames = {'acclim_off1','R2_condition_12'};
    framesA = 135:285;    % 5s pre-stimulus - up to 0.5s before stimulus onset.
    framesB = 315:465;    % 5s stimulus - 0.5s after stimulus onset.
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
        'numBins', numBins, 'Normalization', normMode, 'titleStr', strrep(condNames{1}, '_', '-')));
    
    %% Right: R2 (all flies)
    ax2 = polaraxes(t);
    ax2.Layout.Tile = 2;
    polar_hist_all_flies(ax2, S2, framesA, framesB, struct( ...
        'numBins', numBins, 'Normalization', normMode, 'titleStr', strrep(condNames{2}, '_', '-')));
    
    legend(ax2, {sprintf('%d–%d', framesA(1), framesA(end)),sprintf('%d–%d', framesB(1), framesB(end))}, 'Location','southoutside');
end 



% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

% Option 1
% framesA = 135:285;
% framesB = 315:465;

% Option 2
framesA = 1650:2200;
framesB = 300:850;

velThresh = 15;

plot_polar_all_speedfiltered_bothreps(DATA, framesA, framesB, velThresh);



























% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

%% Plot the distance to the bar - one cohort - single REP

condName = "R1_condition_12";
for entryIdx = 1:30
    plot_distance_to_bar_from_DATA(DATA, entryIdx, condName)
end 

%% Plot the distance to the bar - one cohort - both REPS

for entryIdx = 1:30
    plot_distance_to_bar_both_reps_from_DATA(DATA, entryIdx)
end 


%% Plot the distance to the bar - all cohort - both REPS

plot_distance_to_bar_allcohorts_mean(DATA)
ylim([0 240])


% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

%% Assessing whether the distance from the bar affects the orienting behaviour towards the bright bar. 

% Extract data:
condNames = {'R1_condition_12','R2_condition_12'};
entryIdx = 1; 
c = 1; 
S = DATA(entryIdx).(condNames{c});

% --- Inputs per condition struct S (one cohort/rep):

% Choose windows:
pre = 135:285; post = 315:465;        % adapt as needed

edges = [0:10:250, inf];                % distance bins (mm)
centers = (edges(1:end-1)+edges(2:end))/2;

% Gather across flies:
theta_pre = S.heading_rel_ref(:, pre);  d_pre = S.d2bar(:, pre);
theta_post= S.heading_rel_ref(:, post); d_post= S.d2bar(:, post);

tow_pre  = cosd(theta_pre(:));  dist_pre  = d_pre(:);
tow_post = cosd(theta_post(:)); dist_post = d_post(:);

% Bin means
[~,~,bin_pre]  = histcounts(dist_pre,  edges);
[~,~,bin_post] = histcounts(dist_post, edges);

m_pre  = accumarray(bin_pre(bin_pre>0),  tow_pre(bin_pre>0),  [numel(edges)-1 1], @mean, NaN);
m_post = accumarray(bin_post(bin_post>0),tow_post(bin_post>0),[numel(edges)-1 1], @mean, NaN);

figure('Color','w'); hold on;
plot(centers, m_pre,  '-', 'LineWidth',1.5, 'Color',[0.6 0.6 0.6]);
plot(centers, m_post, '-', 'LineWidth',1.8, 'Color',[1 0 1]);
yline(0,'k:'); xlabel('Distance to bar (mm)'); ylabel('<cos θ>');
legend({'Pre','Post'},'Location','best'); grid on; title('Towardness vs distance');




%% Do flies orient towards the bar more when they are within the half of the arena closer to the bright bar?

arenaCentre = [528, 516];
arenaCenter_mm = arenaCentre / 4.1691;           % <<— supply your arena center in mm
bar_mm        = [29.7426, 52.5293];  % your bar position

% Analyze all cohorts & both reps:
analyze_orient_vs_halfarena(DATA, arenaCenter_mm, bar_mm, 'ConeDeg', 30, 'UseAllEntries', true);



%% PLOT - Assess orienting behaviour across all cohorts wrt distance from the bar. 

% Test different windows
% 1 - 
% pre  = 135:285;                                      % pre window (frames)
% post = 315:465;  % post window (frames)
% 2 - 
pre  = 1:300;                                      % pre window (frames)
post = 300:600; 

%% Settings
condNames = {'R1_condition_12','R2_condition_12'};   % both reps

edges = [0:15:250, inf];                             % distance bins (mm)
centers = (edges(1:end-1) + edges(2:end))/2;

% Bar position (mm) for computing heading_rel_ref if needed
bar_mm = [29.7426, 52.5293];

%% Collect pooled data from ALL entries + BOTH reps
tow_pre_all  = [];  dist_pre_all  = [];
tow_post_all = [];  dist_post_all = [];

for entryIdx = 1:numel(DATA)
    for c = 1:numel(condNames)
        if ~isfield(DATA(entryIdx), condNames{c}), continue; end
        S = DATA(entryIdx).(condNames{c});
        if ~isfield(S,'d2bar') || isempty(S.d2bar), continue; end

        % Ensure heading_rel_ref exists (deg in [-180, 180])
        if ~isfield(S,'heading_rel_ref') || isempty(S.heading_rel_ref)
            if ~isfield(S,'x_data') || ~isfield(S,'y_data') || ~isfield(S,'heading_wrap')
                % Cannot compute; skip this cohort/rep
                warning('Missing x/y/heading_wrap for entry %d %s. Skipping.', entryIdx, condNames{c});
                continue;
            end
            dx = bar_mm(1) - S.x_data;
            dy = bar_mm(2) - S.y_data;
            bearing_to_ref = atan2d(dy, dx);                 % 0°=east, +90°=south
            S.heading_rel_ref = mod(bearing_to_ref - S.heading_wrap + 180, 360) - 180;
        end

        % Clamp windows to available frames for this cohort/rep
        nF = size(S.d2bar, 2);
        idx_pre  = pre(pre >= 1 & pre <= nF);
        idx_post = post(post >= 1 & post <= nF);
        if isempty(idx_pre) && isempty(idx_post), continue; end

        % Extract and append (vectorized)
        if ~isempty(idx_pre)
            theta_pre = S.heading_rel_ref(:, idx_pre); 
            d_pre     = S.d2bar(:,          idx_pre);
            tow_pre_all  = [tow_pre_all;  cosd(theta_pre(:))]; %#ok<AGROW>
            dist_pre_all = [dist_pre_all;  d_pre(:)];          %#ok<AGROW>
        end
        if ~isempty(idx_post)
            theta_post = S.heading_rel_ref(:, idx_post);
            d_post     = S.d2bar(:,          idx_post);
            tow_post_all  = [tow_post_all;  cosd(theta_post(:))]; %#ok<AGROW>
            dist_post_all = [dist_post_all; d_post(:)];           %#ok<AGROW>
        end
    end
end

%% Bin means (and SEM) across all pooled samples
% Use discretize so NaNs in distance produce NaN bins (easy to mask)
bin_pre  = discretize(dist_pre_all,  edges);
bin_post = discretize(dist_post_all, edges);

% Means
m_pre  = accumarray(bin_pre(~isnan(bin_pre)),  tow_pre_all(~isnan(bin_pre)), ...
                    [numel(edges)-1 1], @(x) mean(x,'omitnan'), NaN);
m_post = accumarray(bin_post(~isnan(bin_post)), tow_post_all(~isnan(bin_post)), ...
                    [numel(edges)-1 1], @(x) mean(x,'omitnan'), NaN);

% SEMs
sem_pre  = accumarray(bin_pre(~isnan(bin_pre)),  tow_pre_all(~isnan(bin_pre)), ...
                      [numel(edges)-1 1], @(x) std(x,0,'omitnan')/sqrt(numel(x)), NaN);
sem_post = accumarray(bin_post(~isnan(bin_post)), tow_post_all(~isnan(bin_post)), ...
                      [numel(edges)-1 1], @(x) std(x,0,'omitnan')/sqrt(numel(x)), NaN);

figure('Color','w'); hold on;

% Mean lines
plot(centers, m_pre,  '-', 'LineWidth', 1.8, 'Color', [0.35 0.35 0.35]);
plot(centers, m_post, '-', 'LineWidth', 2.0, 'Color', [1 0 1]);

yline(0,'k:', 'LineWidth',2);
xlabel('Distance to bar (mm)'); 
ylabel('<cos \theta> (towardness)');
ax = gca;
legend(ax, {sprintf('%d–%d', pre(1), pre(end)), sprintf('%d–%d', post(1), post(end))}, 'Location','best');
box off
title('Towardness vs distance — pooled across all cohorts & reps');
f = gcf;
f.Position = [620   607   727   360];


