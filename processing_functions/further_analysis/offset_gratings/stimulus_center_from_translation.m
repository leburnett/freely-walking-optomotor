function [S, info] = stimulus_center_from_translation(C, W, t, varargin)
% STIMULUS_CENTER_FROM_TRANSLATION  Compute the stimulus center of rotation in video pixels.
%
%   [S, info] = stimulus_center_from_translation(C, W, t)
%   [S, info] = stimulus_center_from_translation(C, W, t, 'Rpx', R_override, 'Plot', true)
%
% Inputs
%   C : 1x2 [Cx, Cy] arena CENTER in video pixels.
%   W : 1x2 [Wx, Wy] "narrowest wall" point in video pixels (point on the wall
%       closest to the stimulus center; typically where rings look tightest).
%   t : scalar, arena translation magnitude used when generating the pattern,
%       in arena-radius units (e.g., t = 0.8 means 80% of arena radius).
%
% Name-Value (optional)
%   'Rpx'  : arena radius in pixels. If omitted, uses norm(W - C).
%   'Plot' : logical, if true creates an overlay plot for sanity-checking (default = false).
%   'Ax'   : target axes handle for plotting (optional).
%
% Outputs
%   S    : 1x2 [Sx, Sy] stimulus center of rotation in video pixels.
%   info : struct with fields:
%            .Rpx  - arena radius used (pixels)
%            .u    - unit vector from C toward W
%            .C, .W, .t - copies of inputs
%
% Assumptions
%   - The arena was translated along the stimulus generator's +x, producing a
%     stimulus center displaced TOWARD the wall point W in the video.
%   - No additional unknown rotation between generator "x" and the C->W ray.
%     (If there is, use a vector-mode derivation with known axis mapping.)
%
% Example
%   C = [512, 384]; W = [800, 380]; t = 0.8;
%   [S, info] = stimulus_center_from_translation(C, W, t, 'Plot', true);
%
% Author: Burnett LE
% -------------------------------------------------------------------------

% Parse inputs
p = inputParser;
p.addParameter('Rpx', [], @(x) isempty(x) || (isscalar(x) && isfinite(x) && x>0));
p.addParameter('Plot', false, @(x) islogical(x) && isscalar(x));
p.addParameter('Ax', [], @(x) isempty(x) || isgraphics(x,'axes'));
p.parse(varargin{:});
R_override = p.Results.Rpx;
doPlot     = p.Results.Plot;
ax         = p.Results.Ax;

% Basic checks
validateattributes(C, {'numeric'},{'vector','numel',2,'finite','real'});
validateattributes(W, {'numeric'},{'vector','numel',2,'finite','real'});
validateattributes(t, {'numeric'},{'scalar','real','finite','>=',0,'<=',1});

C = C(:)'; W = W(:)';

% Direction from center to the narrowest wall point
CW = W - C;
Rpx_est = hypot(CW(1), CW(2));
if Rpx_est == 0
    error('C and W are identical; cannot define radius/direction.');
end
u = CW / Rpx_est; % unit vector from center toward the narrowest wall point

% Radius in pixels
if isempty(R_override)
    Rpx = Rpx_est;
else
    Rpx = R_override;
end

% Stimulus center (in pixels)
S = C + (t * Rpx) * u;

% Package info
info = struct('Rpx', Rpx, 'u', u, 'C', C, 'W', W, 't', t);

% Optional plot
if doPlot
    if isempty(ax)
        figure('Color','w'); ax = axes; hold(ax,'on'); axis(ax,'equal');
    else
        hold(ax,'on');
    end
    % Draw points
    plot(ax, C(1), -1*C(2), 'ko', 'MarkerFaceColor','k', 'DisplayName','Arena center C');
    plot(ax, W(1), -1*W(2), 'bo', 'MarkerFaceColor','b', 'DisplayName','Narrowest wall point W');
    plot(ax, S(1), -1*S(2), 'ro', 'MarkerFaceColor','r', 'DisplayName','Stimulus center S');

    % Draw circle for arena (using the chosen radius)
    th = linspace(0, 2*pi, 360);
    circ = C + Rpx * [cos(th)', sin(th)'];
    plot(ax, circ(:,1), -1*circ(:,2), 'k-', 'HandleVisibility','off');

    % Rays
    quiver(ax, C(1), -1*C(2), Rpx*u(1), -1*Rpx*u(2), 0, 'b--', 'DisplayName','C \rightarrow wall');
    quiver(ax, C(1), -1*C(2), (t*Rpx)*u(1), -1*(t*Rpx)*u(2), 0, 'r--', 'DisplayName','C \rightarrow S');

    xlabel(ax,'x (px)'); ylabel(ax,'y (px)');
    legend(ax,'Location','best'); grid off; box off;
    title(ax, sprintf('Stimulus center from translation: t = %.3f (arena radii)', t));
end
end
