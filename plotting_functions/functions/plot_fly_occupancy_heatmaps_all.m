function hFig = plot_fly_occupancy_heatmaps_all(DATA, frameRange, nbins, varargin)
% PLOT_FLY_OCCUPANCY_HEATMAPS
% 2D occupancy heatmaps (R1+R2) for conditions 1, 11, and 9 over a frame
% range (default 1100:1200), combining data from ALL entries in DATA.
%
% Fixed arena (in px -> converted to mm internally):
%   Center_px = [528, 516];
%   Radius_px = 496;
%   PPM       = 4.1691;  % pixels per mm
%
% USAGE:
%   hFig = plot_fly_occupancy_heatmaps(DATA)
%   hFig = plot_fly_occupancy_heatmaps(DATA, 1100:1200, 35)
%
% Name-Value options:
%   'CircleColor'      : [r g b] for overlay (default [0 0 0], black)
%   'CircleLineWidth'  : scalar (default 0.75)
%
% OUTPUT:
%   hFig : figure handle

% -------- Fixed arena parameters (user provided) --------
PPM        = 4.1691;
Centre_mm  = [528, 516] / PPM;
Radius_mm  = 496 / PPM;

if nargin < 2 || isempty(frameRange), frameRange = 1110:1200; end
if nargin < 3 || isempty(nbins),      nbins      = 25;       end

% Options
p = inputParser;
p.addParameter('CircleColor',[0 0 0], @(v) isnumeric(v) && numel(v)==3);
p.addParameter('CircleLineWidth',0.75, @(v) isscalar(v) && v>0);
p.parse(varargin{:});
ccolor = p.Results.CircleColor;
clw    = p.Results.CircleLineWidth;

% Display/overlay styling
pctCLim   = 99;                % robust upper color limit (percentile)
crossLW   = 2.5;               % cross line width
markerSz  = 20;                % cross size (same for all crosses)
maxOccCol = [0.3 0.7 1.0];     % light-blue cross for top-25% centroid
topFrac   = 0.5;              % <-- fraction of total probability mass to define the "highly occupied" blob

% Conditions to plot (R1+R2 per panel)
condList = {'condition_1','condition_11','condition_9'};

% ---------- Gather ALL entries' data for consistent binning & shared CLim ----------
panelXY = cell(numel(condList),1);
allX = []; allY = [];
for i = 1:numel(condList)
    cond = condList{i};
    [xR1,yR1] = fetch_xy_all(DATA, 'R1', cond, frameRange);
    [xR2,yR2] = fetch_xy_all(DATA, 'R2', cond, frameRange);

    % Combine R1+R2
    x = [xR1; xR2];
    y = [yR1; yR2];

    % Store and append for pooled edges/CLim
    panelXY{i} = [x y];
    allX = [allX; x];
    allY = [allY; y];
end
if isempty(allX)
    error('No valid (x,y) samples found across DATA in the requested frame range.');
end

% Bin edges (consistent across panels; same units as your x/y)
xmin = min(allX); xmax = max(allX);
ymin = min(allY); ymax = max(allY);
padx = 1e-9 * max(1, xmax - xmin);
pady = 1e-9 * max(1, ymax - ymin);
xedges = linspace(xmin - padx, xmax + padx, nbins+1);
yedges = linspace(ymin - pady, ymax + pady, nbins+1);

% Precompute histograms for all panels, then convert to PROBABILITIES
Pcells = cell(numel(condList),1);
for i = 1:numel(condList)
    xy = panelXY{i};
    H  = histcounts2(xy(:,1), xy(:,2), xedges, yedges);
    P  = H / max(1, sum(H(:)));        % <-- probability heatmap (sums to 1)
    Pcells{i} = P;
end

% Shared color scale via robust percentile on probabilities
allProbs = cat(3, Pcells{:});
cmax = prctile(allProbs(:), pctCLim);
if cmax <= 0, cmax = max(allProbs(:)); end
CL = [0, max(eps, cmax)];

% ---------- Figure ----------
hFig = figure('Color','w','Name','Fly occupancy heatmaps (all entries combined, probability)');
tiledlayout(hFig,1,3,'TileSpacing','compact','Padding','compact');

% Precompute circle (in mm)
th  = linspace(0, 2*pi, 512);
xc  = Centre_mm(1) + Radius_mm * cos(th);
yc  = Centre_mm(2) + Radius_mm * sin(th);

for i = 1:numel(condList)
    cond = condList{i};
    P    = Pcells{i};

    % Bin centers (for plotting & locating centroid)
    xcent = (xedges(1:end-1) + xedges(2:end)) / 2;
    ycent = (yedges(1:end-1) + yedges(2:end)) / 2;

    % ---- Robust "center of highly occupied region" + contour of top 25% mass ----
    % Smooth the probability a touch to reduce single-bin spikes
    K  = [1 2 1; 2 4 2; 1 2 1]; K = K / sum(K(:));
    Ps = conv2(P, K, 'same');

    % Threshold to capture ~topFrac of the mass
    v = Ps(:);
    v = v(v > 0);
    if isempty(v)
        % Fallback to global max-bin in probability (degenerate case)
        [~, idxMax] = max(P(:));
        [ixm, iym]  = ind2sub(size(P), idxMax);
        xBlue = xcent(ixm);
        yBlue = ycent(iym);
        M = P > 0;  % trivial mask
    else
        [vsort, order] = sort(v, 'descend');
        csum = cumsum(vsort);
        total = csum(end);
        k = find(csum >= topFrac * total, 1, 'first');
        thr = vsort(k);

        % Binary mask for the top-mass region
        M = Ps >= thr;

        % Weighted centroid of this region using ORIGINAL probabilities
        [Xc, Yc] = ndgrid(xcent, ycent);  % P is (numel(xcent) x numel(ycent))
        W = P .* M;
        Wsum = sum(W(:));
        if Wsum > 0
            xBlue = sum(W(:) .* Xc(:)) / Wsum;
            yBlue = sum(W(:) .* Yc(:)) / Wsum;
        else
            % Fallback if mask is empty (shouldn't happen)
            [~, idxMax] = max(P(:));
            [ixm, iym]  = ind2sub(size(P), idxMax);
            xBlue = xcent(ixm);
            yBlue = ycent(iym);
        end
    end

    % Plot
    ax = nexttile;
    hold(ax,'on');

    % --- Draw white square background covering full arena ---
    R  = 520/PPM;
    x_min = Centre_mm(1) - R;
    x_max = Centre_mm(1) + R;
    y_min = Centre_mm(2) - R;
    y_max = Centre_mm(2) + R;
    fill(ax, [x_min x_max x_max x_min], [y_min y_min y_max y_max], ...
         'w', 'EdgeColor', 'none');

    % Probability heatmap
    imagesc(ax, xcent, ycent, P');      % transpose so y increases upward
    axis(ax,'image');
    set(ax,'YDir','normal');
    colormap(ax, flipud(bone));         % inverted bone (light for low prob)
    clim(ax, CL*0.95);
    if i == numel(condList), colorbar(ax); end
    title(ax, strrep(sprintf('R1+R2 %s (frames %d:%d)', ...
        cond, frameRange(1), frameRange(end)), '_','-'));

    % Arena circle
    plot(ax, xc, yc, '-', 'Color', ccolor, 'LineWidth', clw, 'HitTest','off');

    % Red cross = arena center
    plot(ax, Centre_mm(1), Centre_mm(2), '+', 'Color', [0.8 0 0], ...
        'LineWidth', crossLW, 'MarkerSize', markerSz);

    % Pink cross = shifted center of rotation (mm if your data are mm)
    shifted_px = [141.61, 31.8534];      % << your numbers (px) if needed
    shifted_mm = shifted_px;             % keep as-is if your data are already in same units as x/y
    plot(ax, shifted_mm(1), shifted_mm(2), '+', 'Color', [1 0.4 0.8], ...
        'LineWidth', crossLW, 'MarkerSize', markerSz);

    % Light-blue cross = centroid of the top-25%-mass region
    plot(ax, xBlue, yBlue, '+', 'Color', maxOccCol, ...
        'LineWidth', crossLW, 'MarkerSize', markerSz);

    % Contour outline of the top-25%-mass region
    % Use the binary mask M; contour at 0.5 draws the boundary of the blob.
    contour(ax, xcent, ycent, M', [0.5 0.5], ...
        'LineWidth', 2.5, 'LineColor', maxOccCol);

    % Clean look
    axis(ax,'off'); box(ax,'off'); hold(ax,'off');
end

end % main


% ======================= Helper: fetch_xy_all =======================
function [x_all, y_all] = fetch_xy_all(DATA, rigPrefix, condName, frameRange)
% Concatenate x/y across ALL entries in DATA for one rig+condition.
x_all = []; y_all = [];
for k = 1:numel(DATA)
    [xk, yk] = fetch_xy_one(DATA, k, rigPrefix, condName, frameRange);
    if ~isempty(xk)
        x_all = [x_all; xk];
        y_all = [y_all; yk];
    end
end
end


% ======================= Helper: fetch_xy_one =======================
function [x,y] = fetch_xy_one(DATA, entryIdx, rigPrefix, condName, frameRange)
% Get x/y vectors for one entry and one rig/condition; filters to [0,250].
fieldName = sprintf('%s_%s', rigPrefix, condName);
if ~isfield(DATA(entryIdx), fieldName)
    x = []; y = []; return;
end

S = DATA(entryIdx).(fieldName);
if ~isfield(S, 'x_data') || ~isfield(S, 'y_data')
    x = []; y = []; return;
end

x_raw = S.x_data;  y_raw = S.y_data;
if ~isnumeric(x_raw) || ~isnumeric(y_raw)
    x = []; y = []; return;
end

% Make time-by-N
if isvector(x_raw), x_raw = x_raw(:); end
if isvector(y_raw), y_raw = y_raw(:); end
[~, xTimeDim] = max(size(x_raw));
[~, yTimeDim] = max(size(y_raw));
if xTimeDim==2, x_raw = x_raw.'; end
if yTimeDim==2, y_raw = y_raw.'; end

% Clip frame range
T = min(size(x_raw,1), size(y_raw,1));
fr = frameRange(frameRange >= 1 & frameRange <= T);
if isempty(fr), x = []; y = []; return; end

x = x_raw(fr, :);  y = y_raw(fr, :);
x = x(:);          y = y(:);

% Filter to [0,250] on both axes
valid = x >= 0 & x <= 250 & y >= 0 & y <= 250;
x = x(valid);
y = y(valid);
end
