function plot_polar_all_speedfiltered_bothreps(DATA, framesA, framesB, velThresh, fps, varargin)
% plot_polar_all_speedfiltered_bothreps
%
% Keeps only flies with mean speed >= velThresh mm/s in BOTH framesA & framesB,
% and in BOTH R1_condition_12 and R2_condition_12 for the same cohort.
% Then pools all qualifying flies across cohorts to make overlaid polar plots.
%
% Usage:
%   plot_polar_all_speedfiltered_bothreps(DATA, 135:285, 315:465, 5, 30);
%
% Optional Name-Value pairs:
%   'RefMM'   : [x y] bar position (default [29.7426 52.5293])
%   'NumBins' : number of bins (default 24)
%   'Norm'    : 'probability' (default) or 'count'
%
% Author: ChatGPT, 2025

p = inputParser;
addParameter(p,'RefMM',[29.7426 52.5293],@(x)isnumeric(x)&&numel(x)==2);
addParameter(p,'NumBins',24,@(x)isnumeric(x)&&isscalar(x));
addParameter(p,'Norm','probability',@(x)ischar(x)||isstring(x));
parse(p,varargin{:});
ref_mm   = p.Results.RefMM;
numBins  = p.Results.NumBins;
normMode = p.Results.Norm;

condNames = {'R1_condition_12','R2_condition_12'};

%% ---- First pass: decide which flies qualify per cohort ----
qualByEntry = struct('mask',{},'nFliesEntry',{});
nTotalFlies = 0;

for entryIdx = 1:numel(DATA)
    % find number of flies per rep
    nFliesEach = [];
    for c = 1:numel(condNames)
        if isfield(DATA(entryIdx), condNames{c}) && ...
           isfield(DATA(entryIdx).(condNames{c}), 'd2bar') && ...
           ~isempty(DATA(entryIdx).(condNames{c}).d2bar)
            nFliesEach(end+1) = size(DATA(entryIdx).(condNames{c}).d2bar,1); %#ok<AGROW>
        end
    end
    if numel(nFliesEach) < 2, continue; end   % need both reps
    nFliesEntry = min(nFliesEach);
    nTotalFlies = nTotalFlies + nFliesEntry;

    speedOK_reps = false(nFliesEntry, numel(condNames));

    % loop through reps
    for c = 1:numel(condNames)
        S = DATA(entryIdx).(condNames{c});
        nFrames = size(S.d2bar,2);
        if nFrames==0, continue; end

        idxA = framesA(framesA>=1 & framesA<=nFrames);
        idxB = framesB(framesB>=1 & framesB<=nFrames);
        if isempty(idxA) || isempty(idxB), continue; end

        % compute velocity
        if isfield(S,'vel_data') && ~isempty(S.vel_data)
            v = S.vel_data(1:nFliesEntry,:); % mm/s
        else
            if isfield(S,'x_data') && isfield(S,'y_data')
                dx = diff(S.x_data(1:nFliesEntry,:),1,2);
                dy = diff(S.y_data(1:nFliesEntry,:),1,2);
                sp = hypot(dx,dy) * fps;      % mm/s
                v  = [sp(:,1), sp];           % pad to frame count
            else
                v = NaN(nFliesEntry,nFrames);
            end
        end

        meanA = mean(v(:,idxA),2,'omitnan');
        meanB = mean(v(:,idxB),2,'omitnan');
        speedOK_reps(:,c) = (meanA >= velThresh) & (meanB >= velThresh);
    end

    % Must pass BOTH reps (logical AND across columns)
    if size(speedOK_reps,2)==2
        qual = all(speedOK_reps,2);
    else
        qual = false(nFliesEntry,1); % if one rep missing, disqualify
    end

    qualByEntry(entryIdx).mask = qual;
    qualByEntry(entryIdx).nFliesEntry = nFliesEntry;

    fprintf('Entry %d: flies=%d, qualify=%d, not=%d (speed>=%.1f mm/s in both windows & both reps)\n', ...
        entryIdx, nFliesEntry, nnz(qual), nFliesEntry-nnz(qual), velThresh);
end

%% ---- Second pass: gather angles only from qualifying flies ----
angA_cells = {}; angB_cells = {};

for entryIdx = 1:numel(DATA)
    if entryIdx>numel(qualByEntry), continue; end
    if isempty(qualByEntry(entryIdx).mask), continue; end
    qual = qualByEntry(entryIdx).mask;
    nFliesEntry = qualByEntry(entryIdx).nFliesEntry;

    for c = 1:numel(condNames)
        if ~isfield(DATA(entryIdx), condNames{c}), continue; end
        S = DATA(entryIdx).(condNames{c});
        % ensure heading_rel_ref exists
        if ~isfield(S,'heading_rel_ref') || isempty(S.heading_rel_ref)
            if isfield(S,'x_data') && isfield(S,'y_data') && isfield(S,'heading_wrap')
                dx = ref_mm(1) - S.x_data;
                dy = ref_mm(2) - S.y_data;
                bearing_to_ref = atan2d(dy,dx);
                hw = S.heading_wrap;
                S.heading_rel_ref = mod(bearing_to_ref - hw + 180,360) - 180;
            else
                continue;
            end
        end

        nFrames = size(S.heading_rel_ref,2);
        if nFrames==0, continue; end

        idxA = framesA(framesA>=1 & framesA<=nFrames);
        idxB = framesB(framesB>=1 & framesB<=nFrames);
        if isempty(idxA) && isempty(idxB), continue; end

        nFliesRep = min(nFliesEntry, size(S.heading_rel_ref,1));
        qmask = qual(1:nFliesRep);
        if ~any(qmask), continue; end

        if ~isempty(idxA)
            A = S.heading_rel_ref(1:nFliesRep, idxA);
            angA_cells{end+1} = deg2rad(mod(A(qmask,:),360)); %#ok<AGROW>
        end
        if ~isempty(idxB)
            B = S.heading_rel_ref(1:nFliesRep, idxB);
            angB_cells{end+1} = deg2rad(mod(B(qmask,:),360)); %#ok<AGROW>
        end
    end
end

% concatenate pooled angles
angA = []; angB = [];
if ~isempty(angA_cells), angA = reshape(cat(1,angA_cells{:}),[],1); end
if ~isempty(angB_cells), angB = reshape(cat(1,angB_cells{:}),[],1); end
angA = angA(~isnan(angA)); angB = angB(~isnan(angB));

% summary counts
nUsed = 0;
for e = 1:numel(qualByEntry)
    if isempty(qualByEntry(e).mask), continue; end
    nUsed = nUsed + nnz(qualByEntry(e).mask);
end
nExcluded = nTotalFlies - nUsed;
fprintf('QUAL SUMMARY (speed ≥ %.1f mm/s in BOTH reps and BOTH windows): Used=%d | Not=%d | Total=%d\n', ...
    velThresh, nUsed, nExcluded, nTotalFlies);

%% ---- Plot: single polar with overlaid histograms ----
fig = figure('Name','All entries + both reps — Polar histogram (speed≥thresh both reps & windows)','Color','w');
t = tiledlayout(1,1,'TileSpacing','compact','Padding','compact');
sgtitle(t,sprintf('Heading rel. to ref (0°=N, CW)\nFlies with mean speed ≥ %.1f mm/s in A&B and in both reps',velThresh));

ax = polaraxes(t);
ax.Layout.Tile = 1;
ax.ThetaZeroLocation = 'top';
ax.ThetaDir = 'clockwise';
ax.ThetaTick = 0:30:330;

binEdges = linspace(0,2*pi,numBins+1);
hold(ax,'on');

if ~isempty(angA)
    polarhistogram(ax, angA, binEdges, 'Normalization', normMode, ...
        'FaceColor',[0.7 0.7 0.7],'FaceAlpha',0.5,'EdgeColor',[0.7 0.7 0.7]);
end
if ~isempty(angB)
    polarhistogram(ax, angB, binEdges, 'Normalization', normMode, ...
        'FaceColor',[1 0.6 1],'FaceAlpha',0.4,'EdgeColor',[1 0.6 1]);
end

legend(ax,{sprintf('Pre %d–%d',framesA(1),framesA(end)), ...
           sprintf('Stim %d–%d',framesB(1),framesB(end))}, ...
       'Location','southoutside');
title(ax,'All flies • All cohorts • Both reps (speed-qualified)');
end
