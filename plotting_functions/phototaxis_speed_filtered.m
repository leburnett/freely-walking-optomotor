% Orientation to bright bar - Condition 12 - Speed-filtered data

%% PLOT 


%% ---- Settings ----
framesA = 135:285;               % pre window
framesB = 315:465;               % stimulus window
numBins  = 24;                   % 15° bins
normMode = 'probability';        % 'count' or 'probability'
ref_mm   = [29.7426, 52.5293];   % bar position in mm
condNames = {'R1_condition_12','R2_condition_12'};  % both reps
distThresh = 150;                % mm

%% ---- First pass: determine which flies qualify per cohort (any rep) ----
qualByEntry = struct('mask', {}, 'nFliesEntry', {});
nTotalFlies = 0;

for entryIdx = 1:numel(DATA)
    % Count flies per available rep
    nFliesEach = [];
    for c = 1:numel(condNames)
        if isfield(DATA(entryIdx), condNames{c}) && ...
           isfield(DATA(entryIdx).(condNames{c}), 'd2bar') && ...
           ~isempty(DATA(entryIdx).(condNames{c}).d2bar)
            nFliesEach(end+1) = size(DATA(entryIdx).(condNames{c}).d2bar, 1);
        end
    end
    if isempty(nFliesEach), continue; end

    nFliesEntry = min(nFliesEach);   % assume same ordering across reps
    if nFliesEntry == 0, continue; end
    nTotalFlies = nTotalFlies + nFliesEntry;

    qual = false(nFliesEntry,1);

    for c = 1:numel(condNames)
        if ~isfield(DATA(entryIdx), condNames{c}), continue; end
        S = DATA(entryIdx).(condNames{c});
        if ~isfield(S,'d2bar') || isempty(S.d2bar), continue; end

        nFrames = size(S.d2bar,2);
        idxB = framesB(framesB >= 1 & framesB <= nFrames);
        if isempty(idxB), continue; end

        dB = S.d2bar(1:nFliesEntry, idxB);
        % Mark a fly as qualifying if it ever gets within threshold in framesB in THIS rep
        qual = qual | any(dB <= distThresh, 2);
    end

    qualByEntry(entryIdx).mask = qual;
    qualByEntry(entryIdx).nFliesEntry = nFliesEntry;

    % Optional diagnostics per entry:
    fprintf('Entry %d: flies=%d, qualify=%d, not=%d\n', ...
        entryIdx, nFliesEntry, nnz(qual), nFliesEntry - nnz(qual));
end

%% ---- Second pass: collect angles using only qualifying flies ----
angA_cells = {};
angB_cells = {};

for entryIdx = 1:numel(DATA)
    if entryIdx > numel(qualByEntry), continue; end
    if isempty(qualByEntry(entryIdx).mask), continue; end
    qual = qualByEntry(entryIdx).mask;
    nFliesEntry = qualByEntry(entryIdx).nFliesEntry;

    for c = 1:numel(condNames)
        if ~isfield(DATA(entryIdx), condNames{c}), continue; end
        S = DATA(entryIdx).(condNames{c});

        % Ensure headings present/compute if needed
        if ~isfield(S,'heading_rel_ref') || isempty(S.heading_rel_ref)
            if ~isfield(S,'x_data') || ~isfield(S,'y_data') || ~isfield(S,'heading_wrap')
                continue; % not enough to compute
            end
            dx = ref_mm(1) - S.x_data;
            dy = ref_mm(2) - S.y_data;
            bearing_to_ref = atan2d(dy, dx); % 0°=east, +90°=south
            hw = S.heading_wrap;
            S.heading_rel_ref = mod(bearing_to_ref - hw + 180, 360) - 180;
        end

        nFrames = size(S.heading_rel_ref, 2);
        if nFrames == 0, continue; end

        idxA = framesA(framesA >= 1 & framesA <= nFrames);
        idxB = framesB(framesB >= 1 & framesB <= nFrames);

        if isempty(idxA) && isempty(idxB), continue; end

        % Align to available flies in this rep
        nFliesRep = min(nFliesEntry, size(S.heading_rel_ref,1));
        qmask = qual(1:nFliesRep);
        if ~any(qmask), continue; end

        if ~isempty(idxA)
            A = S.heading_rel_ref(1:nFliesRep, idxA);
            angA_cells{end+1} = deg2rad(mod(A(qmask, :), 360)); 
        end
        if ~isempty(idxB)
            B = S.heading_rel_ref(1:nFliesRep, idxB);
            angB_cells{end+1} = deg2rad(mod(B(qmask, :), 360));
        end
    end
end

% Concatenate pooled angles
angA = []; angB = [];
if ~isempty(angA_cells), angA = reshape(cat(1, angA_cells{:}), [], 1); end
if ~isempty(angB_cells), angB = reshape(cat(1, angB_cells{:}), [], 1); end
angA = angA(~isnan(angA)); 
angB = angB(~isnan(angB));

%% ---- Count flies used vs not used (unique by cohort fly index) ----
nUsed = 0;
for entryIdx = 1:numel(qualByEntry)
    if isempty(qualByEntry(entryIdx).mask), continue; end
    nUsed = nUsed + nnz(qualByEntry(entryIdx).mask);
end
nExcluded = nTotalFlies - nUsed;
fprintf('QUAL SUMMARY: Used (<= %.0f mm in framesB): %d | Not used: %d | Total considered: %d\n', ...
    distThresh, nUsed, nExcluded, nTotalFlies);

%% ---- Plot: ONE polar subplot with overlaid histograms ----
fig = figure('Name','All entries + both reps — Polar histogram (distance-filtered)', 'Color','w');
t = tiledlayout(1,1,'TileSpacing','compact','Padding','compact');
sgtitle(t, sprintf('Heading relative to reference (0°=N, CW) — Only flies within %.0f mm during framesB', distThresh));

ax = polaraxes(t);
ax.Layout.Tile = 1;
ax.ThetaZeroLocation = 'top';   % 0° = North
ax.ThetaDir = 'clockwise';      % compass
ax.ThetaTick = 0:30:330;

binEdges = linspace(0, 2*pi, numBins+1);
hold(ax, 'on');

if ~isempty(angA)
    polarhistogram(ax, angA, binEdges, 'Normalization', normMode, ...
        'FaceColor', [0.7 0.7 0.7], 'FaceAlpha', 0.5, 'EdgeColor', [0.7 0.7 0.7]);
end
if ~isempty(angB)
    polarhistogram(ax, angB, binEdges, 'Normalization', normMode, ...
        'FaceColor', [1 0.6 1], 'FaceAlpha', 0.4, 'EdgeColor', [1 0.6 1]);
end

legend(ax, {sprintf('Pre %d–%d', framesA(1), framesA(end)), ...
            sprintf('Stim %d–%d', framesB(1), framesB(end))}, ...
       'Location','southoutside');
title(ax, 'All flies • All cohorts • Both reps (distance-filtered)');


















%% Statistical testing with speed filtering (both windows & both reps)
% CONFIGURATION
framesA   = 135:285;                       % pre
framesB   = 315:465;                       % post
ref_mm    = [29.7426, 52.5293];
condNames = {'R1_condition_12','R2_condition_12'};  % must have both
velThresh = 5;                             % mm/s
fps       = 30;                            % used if vel_data missing

%% ---- PASS 1: Build speed-qualification mask per cohort (must pass BOTH reps & BOTH windows) ----
qualByEntry = struct('mask',{},'nFliesEntry',{});
nTotalFlies = 0;

for entryIdx = 1:numel(DATA)
    % Need both reps present with d2bar (to infer #flies)
    hasRep = false(1, numel(condNames));
    nFliesEach = nan(1, numel(condNames));
    for c = 1:numel(condNames)
        hasRep(c) = isfield(DATA(entryIdx),condNames{c}) && ...
                    isfield(DATA(entryIdx).(condNames{c}),'d2bar') && ...
                    ~isempty(DATA(entryIdx).(condNames{c}).d2bar);
        if hasRep(c)
            nFliesEach(c) = size(DATA(entryIdx).(condNames{c}).d2bar,1);
        end
    end
    if ~all(hasRep)    % require both reps for this stricter rule
        continue;
    end

    nFliesEntry = min(nFliesEach);
    if nFliesEntry==0, continue; end
    nTotalFlies = nTotalFlies + nFliesEntry;

    speedOK_reps = false(nFliesEntry, numel(condNames));

    for c = 1:numel(condNames)
        S = DATA(entryIdx).(condNames{c});
        nFrames = size(S.d2bar,2);
        if nFrames==0, continue; end

        % clamp windows for this rep
        idxA = framesA(framesA>=1 & framesA<=nFrames);
        idxB = framesB(framesB>=1 & framesB<=nFrames);
        if isempty(idxA) || isempty(idxB)
            continue;
        end

        % velocity matrix in mm/s
        if isfield(S,'vel_data') && ~isempty(S.vel_data)
            v = S.vel_data(1:nFliesEntry,:);  % assume mm/s
        else
            if isfield(S,'x_data') && isfield(S,'y_data')
                dx = diff(S.x_data(1:nFliesEntry,:),1,2);
                dy = diff(S.y_data(1:nFliesEntry,:),1,2);
                sp = hypot(dx,dy) * fps;      % mm/s
                v  = [sp(:,1), sp];           % pad to #frames
            else
                v  = NaN(nFliesEntry, nFrames);
            end
        end

        meanA = mean(v(:,idxA),2,'omitnan');
        meanB = mean(v(:,idxB),2,'omitnan');
        speedOK_reps(:,c) = (meanA >= velThresh) & (meanB >= velThresh);
    end

    % Must pass BOTH reps
    qual = all(speedOK_reps, 2);

    qualByEntry(entryIdx).mask = qual;
    qualByEntry(entryIdx).nFliesEntry = nFliesEntry;

    fprintf('Entry %d: flies=%d, qualify=%d, not=%d (speed≥%.1f in A & B for BOTH reps)\n', ...
        entryIdx, nFliesEntry, nnz(qual), nFliesEntry-nnz(qual), velThresh);
end

%% ---- PASS 2: For qualifying flies, compute per-fly circular means (combine the two reps circularly) ----
% We’ll compute per-rep μA/μB per fly, then circular-mean across reps to get one μA and one μB per fly.
perFly = table();   % columns: entryIdx, fly, muA, muB, rA, rB

for entryIdx = 1:numel(DATA)
    if entryIdx > numel(qualByEntry) || isempty(qualByEntry(entryIdx).mask), continue; end
    qual = qualByEntry(entryIdx).mask;
    nFliesEntry = qualByEntry(entryIdx).nFliesEntry;
    if ~any(qual), continue; end

    % Collect per-rep means for this cohort
    muA_rep = nan(nFliesEntry, numel(condNames));
    muB_rep = nan(nFliesEntry, numel(condNames));
    rA_rep  = nan(nFliesEntry, numel(condNames));
    rB_rep  = nan(nFliesEntry, numel(condNames));

    for c = 1:numel(condNames)
        if ~isfield(DATA(entryIdx), condNames{c}), continue; end
        S = DATA(entryIdx).(condNames{c});

        % Ensure heading_rel_ref exists (deg, [-180,180])
        if ~isfield(S,'heading_rel_ref') || isempty(S.heading_rel_ref)
            if isfield(S,'x_data') && isfield(S,'y_data') && isfield(S,'heading_wrap')
                dx = ref_mm(1) - S.x_data;
                dy = ref_mm(2) - S.y_data;
                bearing_to_ref = atan2d(dy, dx);       % 0°=east, +90°=south
                hw = S.heading_wrap;
                S.heading_rel_ref = mod(bearing_to_ref - hw + 180, 360) - 180;
            else
                continue; % cannot compute
            end
        end

        nFrames = size(S.heading_rel_ref,2);
        idxA = framesA(framesA>=1 & framesA<=nFrames);
        idxB = framesB(framesB>=1 & framesB<=nFrames);
        if isempty(idxA) || isempty(idxB), continue; end

        % Compute per-fly circular means in this rep
        for f = 1:nFliesEntry
            if ~qual(f), continue; end  % only qualified flies

            angA = deg2rad(S.heading_rel_ref(f, idxA));
            angB = deg2rad(S.heading_rel_ref(f, idxB));
            angA = angA(~isnan(angA)); angB = angB(~isnan(angB));
            if isempty(angA) || isempty(angB), continue; end

            muA_rep(f,c) = atan2(mean(sin(angA)), mean(cos(angA)));
            muB_rep(f,c) = atan2(mean(sin(angB)), mean(cos(angB)));
            rA_rep(f,c)  = abs(mean(exp(1i*angA)));
            rB_rep(f,c)  = abs(mean(exp(1i*angB)));
        end
    end

    % Combine across reps (circular mean of angles, arithmetic mean of r)
    for f = 1:nFliesEntry
        if ~qual(f), continue; end
        muA_list = muA_rep(f, :); muA_list = muA_list(~isnan(muA_list));
        muB_list = muB_rep(f, :); muB_list = muB_list(~isnan(muB_list));
        rA_list  = rA_rep(f, :);  rA_list  = rA_list(~isnan(rA_list));
        rB_list  = rB_rep(f, :);  rB_list  = rB_list(~isnan(rB_list));
        if numel(muA_list) < 2 || numel(muB_list) < 2
            % Require both reps to have valid means
            continue;
        end

        muA_comb = atan2(mean(sin(muA_list)), mean(cos(muA_list)));
        muB_comb = atan2(mean(sin(muB_list)), mean(cos(muB_list)));
        rA_comb  = mean(rA_list);
        rB_comb  = mean(rB_list);

        perFly = [perFly; table(entryIdx, f, muA_comb, muB_comb, rA_comb, rB_comb, ...
                    'VariableNames', {'entryIdx','fly','muA','muB','rA','rB'})]; %#ok<AGROW>
    end
end

%% ---- STATS across flies (one row per fly now) ----
if isempty(perFly)
    error('No qualified flies with valid headings in both reps and both windows.');
end

muAs = perFly.muA;
muBs = perFly.muB;

% Paired circular differences (μB − μA) wrapped to [-π, π]
diffs = atan2(sin(muBs - muAs), cos(muBs - muAs));

% --- Test 1: Post-stimulus angles clustered toward 0°? (V-test on μB)
pV_B = circ_vtest(muBs, 0);           % expects radians

% --- Test 2: Paired circular shift away from 0? (V-test on diffs)
pV_diff = circ_vtest(diffs, 0);

% --- Optional: Watson–Williams (group means) for reference (not paired)
if exist('circ_wwtest','file')
    pWW = circ_wwtest(muAs, muBs);
else
    pWW = NaN;
end

fprintf('Qualified flies (both reps & both windows, speed≥%.1f): %d\n', velThresh, height(perFly));
fprintf('V-test toward landmark (post μB):         p = %.3g\n', pV_B);
fprintf('V-test on paired diffs (μB−μA ≠ 0):       p = %.3g\n', pV_diff);
if ~isnan(pWW)
    fprintf('Watson–Williams (unpaired reference):     p = %.3g\n', pWW);
end
fprintf('Mean circular change (μB−μA): %.1f°\n', rad2deg(atan2(mean(sin(diffs)), mean(cos(diffs)))));






