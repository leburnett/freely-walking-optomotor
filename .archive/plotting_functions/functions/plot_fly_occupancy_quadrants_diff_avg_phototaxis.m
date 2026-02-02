function hFig = plot_fly_occupancy_quadrants_diff_avg_phototaxis(DATA, entryIdxVec, varargin)
% Average circular quadrant DIFFERENCE heatmap across cohorts.
% Renders with the BAR direction at the TOP (12 o'clock).
%
% For each cohort (entryIdx in entryIdxVec):
%   - compute quadrant fractions in Early = [1:300] and Later = [300:1200]
%   - Δ = Later − Early  (per quadrant)
% Then average Δ across cohorts and plot a single circular heatmap.
%
% Arena (px, provided by user):
%   Center_px    = [528, 516];
%   BarCenter_px = [124, 219];   % orientation only
%   Radius_px    = 496;
%   pxPerMM      = 4.1691;
%
% Name-Value options:
%   'CircleColor'     : [r g b] overlay color (default [0 0 0])
%   'CircleLineWidth' : scalar (default 0.75)
%   'Epoch1'          : [start end] (default [1 300])
%   'Epoch2'          : [start end] (default [300 1200])
%   'SymmetricCLim'   : logical (default true)  -> symmetric color limits around 0
%   'CLimPct'         : scalar percentile for robust max abs (default 99)
%   'Condition'       : string condition field suffix (default 'condition_12')
%
% OUTPUT:
%   hFig : figure handle

% -------- Fixed arena parameters (user provided) --------
pxPerMM      = 4.1691;
Center_px    = [528, 516];
BarCenter_px = [124, 219];
Radius_px    = 496;

% Convert to same units as DATA (DATA coords ~0–250)
C = Center_px   ./ pxPerMM;   % [mm]
B = BarCenter_px./ pxPerMM;
R = Radius_px   ./ pxPerMM;

% Options
p = inputParser;
p.addParameter('CircleColor',[0 0 0], @(v) isnumeric(v) && numel(v)==3);
p.addParameter('CircleLineWidth',0.75, @(v) isscalar(v) && v>0);
p.addParameter('Epoch1',[1 300], @(v) isnumeric(v) && numel(v)==2 && v(1)>=1 && v(2)>=v(1));
p.addParameter('Epoch2',[300 1200], @(v) isnumeric(v) && numel(v)==2 && v(1)>=1 && v(2)>=v(1));
p.addParameter('SymmetricCLim',true, @(v) islogical(v) || ismember(v,[0 1]));
p.addParameter('CLimPct',99, @(v) isnumeric(v) && isscalar(v) && v>0 && v<=100);
p.addParameter('Condition','condition_12', @(s) ischar(s) || isstring(s));
p.parse(varargin{:});
ccolor   = p.Results.CircleColor;
clw      = p.Results.CircleLineWidth;
epoch1   = p.Results.Epoch1;
epoch2   = p.Results.Epoch2;
useSym   = logical(p.Results.SymmetricCLim);
pctMax   = p.Results.CLimPct;
condName = char(p.Results.Condition);

% ---------- Angles / frames for geometry & drawing ----------
% True bar direction in DATA coordinates:
theta_bar  = atan2(B(2)-C(2), B(1)-C(1));  % radians

% Quadrant basis for CLASSIFICATION (bar-centered Q1):
phi_data   = theta_bar - pi/4;
u_data     = [cos(phi_data);      sin(phi_data)     ];
v_data     = [cos(phi_data+pi/2); sin(phi_data+pi/2)];

% VISUAL rotation to put bar at TOP (12 o'clock = +Y = pi/2):
visual_offset = pi/2 - theta_bar;
phi_draw      = phi_data + visual_offset;
u_draw        = [cos(phi_draw);      sin(phi_draw)     ];
v_draw        = [cos(phi_draw+pi/2); sin(phi_draw+pi/2)];

% Circle for drawing
th = linspace(0, 2*pi, 512);
xc = C(1) + R*cos(th);
yc = C(2) + R*sin(th);
bar_pt_draw = C + R*[cos(pi/2), sin(pi/2)];  % 12 o'clock (visual)

% --- Helper: compute normalized quadrant occupancy (2x2) for one cohort & frames
    function Q = quadrant_fraction_for_entry(entryIdx, fr)
        [x1,y1] = fetch_xy(DATA, entryIdx, 'R1', condName, fr(1):fr(2));
        [x2,y2] = fetch_xy(DATA, entryIdx, 'R2', condName, fr(1):fr(2));
        x = [x1(:); x2(:)]; y = [y1(:); y2(:)];
        good = isfinite(x) & isfinite(y);
        x = x(good); y = y(good);
        % inside arena
        r2 = (x - C(1)).^2 + (y - C(2)).^2;
        inside = r2 <= (R.^2);
        x = x(inside); y = y(inside);
        if isempty(x)
            Q = [NaN NaN; NaN NaN]; % mark missing
            return;
        end
        dx = x - C(1);  dy = y - C(2);
        s1 = dx*u_data(1) + dy*u_data(2);
        s2 = dx*v_data(1) + dy*v_data(2);
        % [ Q2  Q1 ; Q3  Q4 ]
        Q11 = sum((s2>=0) & (s1<0));    % Q2
        Q12 = sum((s2>=0) & (s1>=0));   % Q1
        Q21 = sum((s2<0)  & (s1<0));    % Q3
        Q22 = sum((s2<0)  & (s1>=0));   % Q4
        Q = [Q11, Q12; Q21, Q22];
        if any(Q(:))
            Q = Q / nansum(Q(:));
        else
            Q(:) = NaN;
        end
    end

% --- Loop cohorts, compute Δ per cohort in wedge order (Q1..Q4)
entryIdxVec = entryIdxVec(:).';
dvals_all = [];
valid_cohorts = false(size(entryIdxVec));

for kC = 1:numel(entryIdxVec)
    ei = entryIdxVec(kC);
    Qe = quadrant_fraction_for_entry(ei, epoch1);
    Ql = quadrant_fraction_for_entry(ei, epoch2);

    if any(isnan(Qe(:))) || any(isnan(Ql(:)))
        continue; % skip cohorts with missing data
    end

    vals_early = [Qe(1,2), Qe(1,1), Qe(2,1), Qe(2,2)]; % [Q1 Q2 Q3 Q4]
    vals_late  = [Ql(1,2), Ql(1,1), Ql(2,1), Ql(2,2)];
    dvals_all(end+1, :) = vals_late - vals_early; %#ok<AGROW>
    valid_cohorts(kC) = true;
end

if isempty(dvals_all)
    error('No valid cohorts found with data in both epochs.');
end

% Mean Δ across cohorts (equal weights), also get SEM (optional)
dvals_mean = mean(dvals_all, 1, 'omitnan');
dvals_sem  = std(dvals_all, 0, 1, 'omitnan') ./ sqrt(size(dvals_all,1));

% Robust symmetric color limits around 0 using all cohort values
abs_all = abs(dvals_all(:));
amax = max(abs_all);
if ~isfinite(amax) || amax==0
    clim_pair = [-0.25, 0.25];
else
    if p.Results.SymmetricCLim
        % percentile across all abs values
        abs_sorted = sort(abs_all(~isnan(abs_all)));
        if isempty(abs_sorted)
            clim_pair = [-amax, +amax];
        else
            idx = max(1, round(pctMax/100 * numel(abs_sorted)));
            arob = max(abs_sorted(idx), amax); % conservative
            clim_pair = [-arob, +arob];
        end
    else
        clim_pair = [min(dvals_mean), max(dvals_mean)];
        if diff(clim_pair)==0, clim_pair = [-0.25, 0.25]; end
    end
end

% --- Figure: single circular heatmap for mean Δ ---
hFig = figure('Color','w','Name','Average Δ Occupancy (Later−Early) across cohorts');
ax = axes('Parent',hFig); hold(ax,'on'); axis(ax,'equal'); axis(ax,'off');

% Diverging blue–white–red colormap
n = 256; h = n/2;
cmap = [linspace(0,1,h)', linspace(0,1,h)', ones(h,1); ...   % blue -> white
        ones(h,1),        linspace(1,0,h)', linspace(1,0,h)'];% white -> red
colormap(ax, cmap); caxis(ax, clim_pair);

% Draw four wedges with mean Δ values
nArc = 128;
for k = 1:4
    a0 = phi_draw + (k-1)*pi/2;
    a1 = phi_draw + k*pi/2;
    a  = linspace(a0, a1, nArc);
    xv = [C(1), C(1)+R*cos(a), C(1)];
    yv = [C(2), C(2)+R*sin(a), C(2)];
    cd = dvals_mean(k)*ones(numel(xv),1);
    patch('XData',xv,'YData',yv,'FaceColor','interp', ...
          'FaceVertexCData',cd, 'EdgeColor','k','LineWidth',0.5, 'Parent',ax);
end

% Arena outline & dividers (bar-at-top draw frame)
plot(ax, xc, yc, '-', 'Color', ccolor, 'LineWidth', clw);
L = 1.001*R;
plot(ax, [C(1)-L*u_draw(1), C(1)+L*u_draw(1)], [C(2)-L*u_draw(2), C(2)+L*u_draw(2)], '-', 'Color', [0 0 0], 'LineWidth', clw);
plot(ax, [C(1)-L*v_draw(1), C(1)+L*v_draw(1)], [C(2)-L*v_draw(2), C(2)+L*v_draw(2)], '-', 'Color', [0 0 0], 'LineWidth', clw);

% Bar glyph at top
plot(ax, [C(1) bar_pt_draw(1)], [C(2) bar_pt_draw(2)], '-', 'Color', [0.2 0.6 1], 'LineWidth', 1.6);
plot(ax,  bar_pt_draw(1),        bar_pt_draw(2), 'o', 'MarkerSize', 5, ...
     'MarkerFaceColor',[0.2 0.6 1], 'MarkerEdgeColor','none');

% Title & colorbar
nCoh = sum(valid_cohorts);
title(ax, sprintf('Average Δ Occupancy across %d cohort(s): [%d:%d] − [%d:%d]', ...
      nCoh, epoch2(1), epoch2(2), epoch1(1), epoch1(2)));
cb = colorbar(ax);
cb.Label.String = 'Δ occupancy (fraction, later − early)';

% Optional: annotate mean ± SEM per wedge (small text near rim)
annotateSEM = false;
if annotateSEM
    r_txt = 0.8*R;
    for k = 1:4
        ang = phi_draw + (k-0.5)*pi/2;
        px = C(1) + r_txt*cos(ang);
        py = C(2) + r_txt*sin(ang);
        text(px,py, sprintf('%.3f±%.3f', dvals_mean(k), dvals_sem(k)), ...
            'HorizontalAlignment','center','VerticalAlignment','middle', ...
            'FontSize',9, 'Color',[0 0 0], 'Parent',ax);
    end
end

end  % main


% ======================= Helper: fetch_xy (unchanged) =======================
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

% ---- Keep only points within [0, 250] box ----
valid = x >= 0 & x <= 250 & y >= 0 & y <= 250;
x = x(valid);
y = y(valid);

end
