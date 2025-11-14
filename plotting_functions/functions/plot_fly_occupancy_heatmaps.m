function hFig = plot_fly_occupancy_heatmaps(DATA, entryIdx, frameRange, nbins, varargin)
% PLOT_FLY_OCCUPANCY_HEATMAPS_FIXED
% 2D occupancy heatmaps for R1+R2 in conditions 1, 11, and 9 over frames
% 1000:1200 by default. Overlays arena circle using FIXED center/radius.
%
% Uses:
%   Center_px = [528, 516];
%   Radius_px = 496;
%   pxPerMM   = 4.1691;  % only used if Units = 'mm'
%
% USAGE:
%   hFig = plot_fly_occupancy_heatmaps_fixed(DATA)
%   hFig = plot_fly_occupancy_heatmaps_fixed(DATA, 1000:1200, 120)
%   hFig = plot_fly_occupancy_heatmaps_fixed(DATA, [], [], 'Units','mm')
%
% Name-Value options:
%   'Units'           : 'px' (default) or 'mm'  (for axes & circle overlay)
%   'CircleColor'     : [r g b] for overlay (default [1 1 1])
%   'CircleLineWidth' : scalar (default 0.75)
%
% OUTPUT:
%   hFig : figure handle

% -------- Fixed arena parameters (user provided) --------
PPM   = 4.1691;
Center_px = [528, 516]/PPM;
Radius_px = 496/PPM;

if nargin < 3 || isempty(frameRange), frameRange = 1100:1200; end
if nargin < 4 || isempty(nbins),      nbins = 15;            end

% Options
p = inputParser;
p.addParameter('CircleColor',[0 0 0], @(v) isnumeric(v) && numel(v)==3);
p.addParameter('CircleLineWidth',0.75, @(v) isscalar(v) && v>0);
p.parse(varargin{:});
ccolor = p.Results.CircleColor;
clw    = p.Results.CircleLineWidth;
pctCLim  = 99;
crossLW = 0.75;

% Conditions to plot (R1+R2 per panel)
% condList = {'condition_1','condition_3','condition_5'};

% P 35
% 30 deg
% condList = {'condition_2','condition_7','condition_8'};
% 60 deg
condList = {'condition_1','condition_9','condition_10'};

% ---------- Gather all data to make consistent bin edges ----------
allX = []; allY = [];
panelXY = cell(numel(condList),1);
for i = 1:numel(condList)
    cond = condList{i};
    [x1,y1] = fetch_xy(DATA, entryIdx, 'R1', cond, frameRange);
    [x2,y2] = fetch_xy(DATA, entryIdx, 'R2', cond, frameRange);
    x = [x1(:); x2(:)];
    y = [y1(:); y2(:)];
    good = isfinite(x) & isfinite(y);
    x = x(good); y = y(good);
    panelXY{i} = [x y];
    allX = [allX; x]; %#ok<AGROW>
    allY = [allY; y]; %#ok<AGROW>
end
if isempty(allX)
    error('No valid (x,y) samples found in the requested frame range.');
end

% Build pooled arrays post-conversion (for edges and CLim)
allX = cell2mat(cellfun(@(A) A(:,1), panelXY, 'UniformOutput', false));
allY = cell2mat(cellfun(@(A) A(:,2), panelXY, 'UniformOutput', false));

% Bin edges (consistent across panels)
xmin = min(allX); xmax = max(allX);
ymin = min(allY); ymax = max(allY);
padx = 1e-9 * max(1, xmax - xmin);
pady = 1e-9 * max(1, ymax - ymin);
xedges = linspace(xmin - padx, xmax + padx, nbins+1);
yedges = linspace(ymin - pady, ymax + pady, nbins+1);

% Precompute histograms for all panels
Hcells = cell(numel(condList),1);
for i = 1:numel(condList)
    xy = panelXY{i};
    Hcells{i} = histcounts2(xy(:,1), xy(:,2), xedges, yedges);
end

% Choose a sensible shared CLim using pooled counts
allCounts = cat(3, Hcells{:});
% upper limit as a robust percentile across all panels
cmax = prctile(allCounts(:), pctCLim);
if cmax <= 0
    cmax = max(allCounts(:)); % fallback
end
CL = [0, max(eps, cmax)];

Center = Center_px;
Radius = Radius_px;
xlab = 'x (px)'; ylab = 'y (px)';

% Bin edges
xmin = min(allX); xmax = max(allX);
ymin = min(allY); ymax = max(allY);
padx = 1e-9 * max(1, xmax - xmin);
pady = 1e-9 * max(1, ymax - ymin);
xedges = linspace(xmin - padx, xmax + padx, nbins+1);
yedges = linspace(ymin - pady, ymax + pady, nbins+1);

% ---------- Figure ----------
hFig = figure('Color','w','Name','Fly occupancy heatmaps');
tiledlayout(hFig,1,3,'TileSpacing','compact','Padding','compact');

% Precompute circle and cross
th = linspace(0, 2*pi, 512);
xc = Center(1) + Radius * cos(th);
yc = Center(2) + Radius * sin(th);

for i = 1:numel(condList)
    cond = condList{i};

    % Fetch data for this panel
    [x1,y1] = fetch_xy(DATA, entryIdx, 'R1', cond, frameRange);
    [x2,y2] = fetch_xy(DATA, entryIdx, 'R2', cond, frameRange);
    x = [x1(:); x2(:)];
    y = [y1(:); y2(:)];
    good = isfinite(x) & isfinite(y);
    x = x(good); y = y(good);

    % 2D histogram
    H = histcounts2(x, y, xedges, yedges); % , 'Normalization', 'probability'

    % Plot heatmap
    ax = nexttile;

    % --- Draw black square background covering full arena ---
    Cx = 528/PPM;
    Cy = 516/PPM;
    R  = 520/PPM;
    
    % Define square corners: (center ± radius)
    x_min = Cx - R;
    x_max = Cx + R;
    y_min = Cy - R;
    y_max = Cy + R;
    
    % Draw solid black rectangle behind everything
    fill(ax, ...
    [x_min x_max x_max x_min], ...
    [y_min y_min y_max y_max], ...
    'w', 'EdgeColor', 'none');
    hold on
    imagesc(ax, ...
        (xedges(1:end-1)+xedges(2:end))/2, ...
        (yedges(1:end-1)+yedges(2:end))/2, ...
        H');    % transpose so y increases upward
    axis(ax,'image');
    set(ax,'YDir','normal');
    colormap(ax, flipud(bone));
    clim(ax, CL);
    if i == numel(condList)
        colorbar(ax);
    end 
    xlabel(ax, xlab); ylabel(ax, ylab);
    title(ax, strrep(sprintf('R1+R2 %s (frames %d:%d)', cond, frameRange(1), frameRange(end)), '_', '-'));

    % Arena circle overlay (thin white line)
    hold(ax,'on');
    plot(ax, xc, yc, '-', 'Color', ccolor, 'LineWidth', clw, 'HitTest','off');
    % Red cross for centre of the arena
    plot(ax, Center(1), Center(2), '+', 'Color', [0.8 0 0], 'LineWidth', crossLW, 'MarkerSize', 20, 'LineWidth', 2.5);
    % Blue cross for shifted centre of rotation.
    if cond == "condition_10" || cond == "condition_8" 
        plot(ax, 113.397, 212.914, '+', 'Color', [1 0.4 0.8], 'LineWidth', crossLW, 'MarkerSize', 20, 'LineWidth', 2.5);
    elseif cond == "condition_9" || cond == "condition_7"
        plot(ax, 141.61, 31.8534, '+', 'Color', [1 0.4 0.8], 'LineWidth', crossLW, 'MarkerSize', 20, 'LineWidth', 2.5);
    end 
    axis(ax,'off');
    box(ax,'off');
end

end % main


% ======================= Helper: fetch_xy =======================
function [x,y] = fetch_xy(DATA, entryIdx, rigPrefix, condName, frameRange)
% Get x/y vectors for one rep/condition over requested frames.
% Filters out coordinates outside [0, 250] in both x and y.

fieldName = sprintf('%s_%s', rigPrefix, condName);
if ~isfield(DATA(entryIdx), fieldName)
    warning('Missing field: DATA(%d).%s', entryIdx, fieldName);
    x = []; y = []; return;
end

S = DATA(entryIdx).(fieldName);
if ~isfield(S, 'x_data') || ~isfield(S, 'y_data')
    warning('Fields x_data/y_data missing in DATA(%d).%s', entryIdx, fieldName);
    x = []; y = []; return;
end

x_raw = S.x_data;  
y_raw = S.y_data;

if ~isnumeric(x_raw) || ~isnumeric(y_raw)
    warning('Non-numeric x_data/y_data in DATA(%d).%s', entryIdx, fieldName);
    x = []; y = []; return;
end

% Make them time-by-N
if isvector(x_raw), x_raw = x_raw(:); end
if isvector(y_raw), y_raw = y_raw(:); end
[~, xTimeDim] = max(size(x_raw));
[~, yTimeDim] = max(size(y_raw));
if xTimeDim==2, x_raw = x_raw.'; end
if yTimeDim==2, y_raw = y_raw.'; end

% Clip frame range
T = min(size(x_raw,1), size(y_raw,1));
fr = frameRange(frameRange >= 1 & frameRange <= T);
if isempty(fr)
    x = []; y = []; return;
end

x = x_raw(fr, :);
y = y_raw(fr, :);

% Flatten
x = x(:);
y = y(:);

% ---- NEW FILTER: Remove any points outside [0, 250] ----
valid = x >= 0 & x <= 250 & y >= 0 & y <= 250;
x = x(valid);
y = y(valid);

end
