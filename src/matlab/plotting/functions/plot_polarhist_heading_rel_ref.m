function plot_polarhist_heading_rel_ref(ax, S, flyIdx, rng1, rng2, opts)
% Plot overlaid polar histograms of heading_rel_ref for one fly.
%   plot_polarhist_heading_rel_ref(ax, S, flyIdx, rng1, rng2, opts)
%
%   Inputs:
%     ax       - target polaraxes (create one if empty or omitted)
%     S        - condition struct with fields x_data, y_data, heading_wrap, (optional) heading_rel_ref
%     flyIdx   - row index of the fly to plot
%     rng1  - vector of frame indices for interval 1 (e.g., 1:300)
%     rng2  - vector of frame indices for interval 2 (e.g., 300:600)
%     opts     - struct of options (all optional):
%                  .numBins (default 24)
%                  .showLegend (default false)
%                  .titleStr   (default '')
%                  .ref_mm     (default [29.7426, 52.5293]) used only if heading_rel_ref missing
%
%   The function respects the convention: 0° = North (top), +θ clockwise.

    if nargin < 1 || isempty(ax) || ~isvalid(ax)
        ax = polaraxes; 
    end

    if nargin < 6, opts = struct; end
    if ~isfield(opts, 'numBins'), opts.numBins = 24; end
    if ~isfield(opts, 'showLegend'), opts.showLegend = false; end
    if ~isfield(opts, 'titleStr'), opts.titleStr = ''; end
    if ~isfield(opts, 'ref_mm'), opts.ref_mm = [29.7426, 52.5293]; end

    % Ensure heading_rel_ref exists; if not, compute it
    if ~isfield(S, 'heading_rel_ref') || isempty(S.heading_rel_ref)
        dx = opts.ref_mm(1) - S.x_data;
        dy = opts.ref_mm(2) - S.y_data;
        bearing_to_ref = atan2d(dy, dx);                         % deg, 0°=east, +90°=south
        hw = S.heading_wrap;                                     % deg
        S.heading_rel_ref = mod(bearing_to_ref - hw + 180, 360) - 180; % [-180, 180]
    end

    % Safety: clamp frames to available range
    nFrames = size(S.heading_rel_ref, 2);
    rng1 = rng1(rng1 >= 1 & rng1 <= nFrames);
    rng2 = rng2(rng2 >= 1 & rng2 <= nFrames);

    % Extract and convert to radians on [0, 2π)
    ang1 = deg2rad(mod(S.heading_rel_ref(flyIdx, rng1), 360));
    ang2 = deg2rad(mod(S.heading_rel_ref(flyIdx, rng2), 360));

    % Bin edges and orientation
    binEdges = linspace(0, 2*pi, opts.numBins+1);
    hold(ax, 'on');
    ax.ThetaZeroLocation = 'top';      % 0° at North
    ax.ThetaDir = 'clockwise';         % compass: E=90°, S=180°, W=270°
    ax.ThetaTick = 0:30:330;
    ax.ThetaTickLabel = {''};

    % First interval: 1:300 (light gray line)
    polarhistogram(ax, ang1, binEdges, 'EdgeColor', [0.7 0.7 0.7], 'LineWidth', 1.5, 'FaceColor', [0.7 0.7 0.7], 'FaceAlpha', 0.4);
    
    % Second interval: 300:600 (magenta line)
    polarhistogram(ax, ang2, binEdges, 'EdgeColor', [1 0.6 1], 'LineWidth', 1.5, 'FaceColor', [1 0.6 1], 'FaceAlpha', 0.4);

    % Title / legend
    if ~isempty(opts.titleStr), title(ax, opts.titleStr); end
    if opts.showLegend
        legend(ax, {'F1–300: Before', 'F300–600: Stim'}, 'Location', 'southoutside');
    end
end
