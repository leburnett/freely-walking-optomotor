function plot_fly_occupancy_quadrants_phototaxis(DATA, entryIdx, frameRange, varargin)
% Circular quadrant occupancy heatmap for phototaxis,
% rendered so the BAR direction is at the TOP (12 o'clock).
%
% Arena (px, provided by user):
%   Center_px    = [528, 516];
%   BarCenter_px = [124, 219];   % used to infer bar direction
%   Radius_px    = 496;
%   pxPerMM      = 4.1691;

% -------- Fixed arena parameters (user provided) --------
pxPerMM      = 4.1691;
Center_px    = [528, 516];
BarCenter_px = [124, 219];
Radius_px    = 496;

% Convert to same units as DATA (DATA coords ~0–250)
C = Center_px   ./ pxPerMM;   % [mm]
B = BarCenter_px./ pxPerMM;
R = Radius_px   ./ pxPerMM;

if nargin < 3 || isempty(frameRange), frameRange = 1100:1200; end

% Options
p = inputParser;
p.addParameter('CircleColor',[0 0 0], @(v) isnumeric(v) && numel(v)==3);
p.addParameter('CircleLineWidth',0.75, @(v) isscalar(v) && v>0);
p.parse(varargin{:});
ccolor = p.Results.CircleColor;
clw    = p.Results.CircleLineWidth;

% Conditions to plot
condList = {'condition_12'};

% ---------- Angles ----------
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

% Precompute the "top" bar point in the DRAWN frame
bar_pt_draw = C + R*[cos(pi/2), sin(pi/2)];  % 12 o'clock

% ---------- Figure ----------
% hFig = figure();
% tiledlayout(hFig,1,numel(condList),'TileSpacing','compact','Padding','compact');

for i = 1:numel(condList)
    cond = condList{i};

    % Fetch data
    [x1,y1] = fetch_xy(DATA, entryIdx, 'R1', cond, frameRange);
    [x2,y2] = fetch_xy(DATA, entryIdx, 'R2', cond, frameRange);
    x = [x1(:); x2(:)];
    y = [y1(:); y2(:)];
    good = isfinite(x) & isfinite(y);
    x = x(good); y = y(good);

    % Keep only samples inside arena
    r2 = (x - C(1)).^2 + (y - C(2)).^2;
    inside = r2 <= (R.^2);
    x = x(inside); y = y(inside);

    % ---- Quadrant classification in DATA frame (bar-centered) ----
    if isempty(x)
        warning('No valid samples inside arena for %s; setting zeros.', cond);
        Q = [0 0; 0 0];
    else
        dx = x - C(1);  dy = y - C(2);
        s1 = dx*u_data(1) + dy*u_data(2);
        s2 = dx*v_data(1) + dy*v_data(2);

        % Spatial grid (same as before):
        % [ Q2  Q1
        %   Q3  Q4 ]   with Q1 centered on the bar direction
        Q11 = sum((s2>=0) & (s1<0));    % Q2 (top-left)
        Q12 = sum((s2>=0) & (s1>=0));   % Q1 (top-right)
        Q21 = sum((s2<0)  & (s1<0));    % Q3 (bottom-left)
        Q22 = sum((s2<0)  & (s1>=0));   % Q4 (bottom-right)
        Q = [Q11, Q12; Q21, Q22];
        if any(Q(:)), Q = Q / sum(Q(:)); end
    end

    % Map to wedge values in ANGULAR order for DRAWING:
    % Wedge 1: [phi_draw, phi_draw+pi/2]   -> Q1
    % Wedge 2: [phi_draw+pi/2, phi_draw+pi] -> Q2
    % Wedge 3: [phi_draw+pi, phi_draw+3*pi/2] -> Q3
    % Wedge 4: [phi_draw+3*pi/2, phi_draw+2*pi] -> Q4
    vals = [Q(1,2), Q(1,1), Q(2,1), Q(2,2)];  % [Q1 Q2 Q3 Q4]

    % ---------- Plot circular heatmap (filled wedges) ----------
    ax = gca; hold(ax,'on'); axis(ax,'off'); %  axis(ax,'equal');
    colormap(ax, gray);
    cmax = max(vals); if cmax <= 0, cmax = 1; end
    clim(ax, [0 cmax]);

    nArc = 128;
    for k = 1:4
        a0 = phi_draw + (k-1)*pi/2;
        a1 = phi_draw + k*pi/2;
        a  = linspace(a0, a1, nArc);
        xv = [C(1), C(1)+R*cos(a), C(1)];
        yv = [C(2), C(2)+R*sin(a), C(2)];
        cd = vals(k)*ones(numel(xv),1);
        patch('XData',xv,'YData',yv,'FaceColor','interp', ...
              'FaceVertexCData',cd, 'EdgeColor','k','LineWidth',0.5, 'Parent',ax);
    end

    % Arena outline and divider lines (use DRAW frame so bar is vertical)
    plot(ax, xc, yc, '-', 'Color', ccolor, 'LineWidth', clw);
    L = 1.001*R;
    plot(ax, [C(1)-L*u_draw(1), C(1)+L*u_draw(1)], [C(2)-L*u_draw(2), C(2)+L*u_draw(2)], '-', 'Color', [0 0 0], 'LineWidth', clw);
    plot(ax, [C(1)-L*v_draw(1), C(1)+L*v_draw(1)], [C(2)-L*v_draw(2), C(2)+L*v_draw(2)], '-', 'Color', [0 0 0], 'LineWidth', clw);

    % ===== Bar schematic at TOP (12 o'clock) in the DRAWN view =====
    plot(ax, [C(1) bar_pt_draw(1)], [C(2) bar_pt_draw(2)], '-', 'Color', [0.2 0.6 1], 'LineWidth', 1.6);
    plot(ax,  bar_pt_draw(1),        bar_pt_draw(2), 'o', 'MarkerSize', 5, ...
         'MarkerFaceColor',[0.2 0.6 1], 'MarkerEdgeColor','none');

    % title(ax, sprintf('R1+R2 %s (frames %d:%d) - Cohort %d', strrep(cond,'_','-'), frameRange(1), frameRange(end), entryIdx), 'FontSize', 16);
    title(ax, sprintf('frames %d:%d', frameRange(1), frameRange(end)));
    % cb = colorbar(ax); cb.Label.String = 'Occupancy (fraction)'; cb.FontSize = 12; cb.Ticks = [0, 0.1, 0.2, 0.3, 0.4]; cb.Location = 'southoutside';
end


% ======================= Helper: fetch_xy (unchanged) =======================
function [x,y] = fetch_xy(DATA, entryIdx, rigPrefix, condName, frameRange)
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
x_raw = S.x_data;  y_raw = S.y_data;
if ~isnumeric(x_raw) || ~isnumeric(y_raw)
    warning('Non-numeric x_data/y_data in DATA(%d).%s', entryIdx, fieldName);
    x = []; y = []; return;
end
if isvector(x_raw), x_raw = x_raw(:); end
if isvector(y_raw), y_raw = y_raw(:); end
[~, xTimeDim] = max(size(x_raw));
[~, yTimeDim] = max(size(y_raw));
if xTimeDim==2, x_raw = x_raw.'; end
if yTimeDim==2, y_raw = y_raw.'; end
T = min(size(x_raw,1), size(y_raw,1));
fr = frameRange(frameRange >= 1 & frameRange <= T);
if isempty(fr), x = []; y = []; return; end
x = x_raw(fr, :);  y = y_raw(fr, :);
x = x(:); y = y(:);
valid = x >= 0 & x <= 250 & y >= 0 & y <= 250;
x = x(valid); y = y(valid);
end

end 
