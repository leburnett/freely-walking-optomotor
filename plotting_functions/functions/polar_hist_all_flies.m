function polar_hist_all_flies(ax, S, framesA, framesB, opts)
%POLAR_HIST_ALL_FLIES Overlaid polar hist of heading_rel_ref aggregated across all flies.
%   polar_hist_all_flies(ax, S, framesA, framesB, opts)
%     ax      : target polaraxes (must be a PolarAxes; see driver below)
%     S       : condition struct with x_data, y_data, heading_wrap, (optional) heading_rel_ref
%     framesA : frame indices for interval A (e.g., 1:300)
%     framesB : frame indices for interval B (e.g., 300:600)
%     opts    : optional struct:
%                  .numBins (default 24)
%                  .Normalization ('count' or 'probability'; default 'count')
%                  .ref_mm (used only if heading_rel_ref missing; default [29.7426 52.5293])
%                  .titleStr (default '')

    if nargin < 5, opts = struct; end
    if ~isfield(opts,'numBins'), opts.numBins = 24; end
    if ~isfield(opts,'Normalization'), opts.Normalization = 'count'; end
    if ~isfield(opts,'ref_mm'), opts.ref_mm = [29.7426, 52.5293]; end
    if ~isfield(opts,'titleStr'), opts.titleStr = ''; end

    % Ensure heading_rel_ref exists (compute if missing)
    if ~isfield(S,'heading_rel_ref') || isempty(S.heading_rel_ref)
        dx = opts.ref_mm(1) - S.x_data;
        dy = opts.ref_mm(2) - S.y_data;
        bearing_to_ref = atan2d(dy, dx);                      % deg, 0°=east, +90°=south
        hw = S.heading_wrap;                                   % deg
        S.heading_rel_ref = mod(bearing_to_ref - hw + 180, 360) - 180; % [-180,180]
    end

    % Clamp requested frames to available range
    nFrames = size(S.heading_rel_ref, 2);
    framesA = framesA(framesA >= 1 & framesA <= nFrames);
    framesB = framesB(framesB >= 1 & framesB <= nFrames);

    % Aggregate across ALL flies (rows)
    angA_deg = S.heading_rel_ref(:, framesA);
    angB_deg = S.heading_rel_ref(:, framesB);

    % Convert to radians in [0, 2π)
    angA = deg2rad(mod(angA_deg(:), 360));
    angB = deg2rad(mod(angB_deg(:), 360));

    % Configure polar axes (0° at North, clockwise)
    ax.ThetaZeroLocation = 'top';
    ax.ThetaDir = 'clockwise';
    ax.ThetaTick = 0:30:330;

    % Bins and plot
    binEdges = linspace(0, 2*pi, opts.numBins+1);
    hold(ax, 'on');
    polarhistogram(ax, angA, binEdges, 'EdgeColor', [0.7 0.7 0.7], 'LineWidth', 1.6, 'FaceColor', [0.7 0.7 0.7], 'FaceAlpha', 0.5, 'Normalization', opts.Normalization);
    polarhistogram(ax, angB, binEdges, 'EdgeColor', [1 0.6 1], 'LineWidth', 1.8, 'FaceColor', [1 0.6 1], 'FaceAlpha', 0.4,'Normalization', opts.Normalization);

    if ~isempty(opts.titleStr)
        title(ax, opts.titleStr);
    end
end
