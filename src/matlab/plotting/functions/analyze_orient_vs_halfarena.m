function analyze_orient_vs_halfarena(DATA, arenaCenter_mm, bar_mm, varargin)
% Analyze whether flies orient more toward the bar when in the half of the arena
% nearer the bar vs the far half, using a geometric half-plane split.
%
% Usage:
%   analyze_orient_vs_halfarena(DATA, [Cx Cy], [Bx By], 'ConeDeg', 30, 'UseAllEntries', true)
%
% Inputs:
%   DATA            : struct array with .R1_condition_12/.R2_condition_12
%                     containing fields x_data, y_data, heading_wrap (deg), and/or heading_rel_ref (deg).
%   arenaCenter_mm  : [Cx, Cy] coordinates of arena center in mm.
%   bar_mm          : [Bx, By] coordinates of bar in mm (e.g., [29.7426, 52.5293]).
%
% Name-Value options:
%   'ConeDeg'       : Half-angle (deg) for "in-cone" towardness (default 30).
%   'UseAllEntries' : true to pool all cohorts (default true); false → just DATA(1).
%   'Conditions'    : cellstr of condition names (default {'R1_condition_12','R2_condition_12'})
%   'FPS'           : frames per second (optional; not required here)
%
% What it does:
%   - Classifies each frame as NEAR or FAR half by sign((P-C)·(B-C)).
%   - Computes towardness = cosd(heading_rel_ref) per frame.
%   - Per fly: averages towardness in NEAR and FAR halves separately.
%   - (Optional) Per fly: computes fraction of frames with |theta| <= ConeDeg (in-cone).
%   - Across flies: paired tests (NEAR vs FAR) and a bar plot with mean±SEM.
%
% Notes:
%   - If heading_rel_ref is missing, it is computed from x/y and heading_wrap.
%   - Per-fly summaries avoid pseudo-replication across frames.
%   - Frames with NaNs are ignored; if a fly has no samples in a half, it’s skipped.

p = inputParser;
addParameter(p,'ConeDeg',30,@(x)isnumeric(x)&&isscalar(x));
addParameter(p,'UseAllEntries',true,@islogical);
addParameter(p,'Conditions',{'R1_condition_12','R2_condition_12'},@(x)iscellstr(x));
addParameter(p,'FPS',[],@(x)isempty(x)||(isnumeric(x)&&isscalar(x)));
parse(p,varargin{:});
coneDeg = p.Results.ConeDeg;
useAll  = p.Results.UseAllEntries;
conds   = p.Results.Conditions;

% Constants
R_arena = 120; % mm (from diameter 240), used only if you want to mask to the arena
C = arenaCenter_mm(:)';  % 1x2
B = bar_mm(:)';          % 1x2
vCB = B - C;             % direction from center to bar

% Collect per-fly summaries
perFly_near_meanTow = [];
perFly_far_meanTow  = [];
perFly_near_inCone  = [];
perFly_far_inCone   = [];

entryRange = 1:numel(DATA);
if ~useAll, entryRange = 1; end

for e = entryRange
    for c = 1:numel(conds)
        if ~isfield(DATA(e), conds{c}), continue; end
        S = DATA(e).(conds{c});

        % Ensure heading_rel_ref exists (deg, −180..180)
        if ~isfield(S,'heading_rel_ref') || isempty(S.heading_rel_ref)
            if ~isfield(S,'x_data') || ~isfield(S,'y_data') || ~isfield(S,'heading_wrap')
                warning('Missing x/y/heading_wrap in entry %d, %s. Skipping.', e, conds{c});
                continue;
            end
            dx = B(1) - S.x_data;
            dy = B(2) - S.y_data;
            bearing_to_ref = atan2d(dy, dx); % 0°=east, +90°=south (image coords)
            S.heading_rel_ref = mod(bearing_to_ref - S.heading_wrap + 180, 360) - 180;
        end

        % Positions
        X = S.x_data;    % [flies x frames], mm
        Y = S.y_data;
        if isempty(X) || isempty(Y), continue; end

        % Towardness and angle
        theta = S.heading_rel_ref;     % deg
        toward = cosd(theta);          % [-1,1]

        % Classify NEAR vs FAR half by sign of dot((P-C),(B-C))
        % Compute dot for all frames vectorized:
        PX = X - C(1);
        PY = Y - C(2);
        dotPC_CB = PX * vCB(1) + PY * vCB(2); % (flies x frames) ⊙ scalar
        isNear = dotPC_CB > 0;  % near-half if true

        % OPTIONAL: mask to physical arena if needed (distance from center ≤ R_arena)
        % rFromCenter = hypot(PX, PY);
        % inArena = rFromCenter <= R_arena + 1e-6;
        % validMask = inArena;  % or combine with speed filters, etc.
        validMask = ~isnan(toward); % minimal validity: towardness exists

        % Per-fly summaries
        nFlies = size(X,1);
        for f = 1:nFlies
            nearVals = toward(f, isNear(f,:) & validMask(f,:));
            farVals  = toward(f, ~isNear(f,:) & validMask(f,:));

            if ~isempty(nearVals) && ~isempty(farVals)
                perFly_near_meanTow(end+1,1) = mean(nearVals,'omitnan'); %#ok<AGROW>
                perFly_far_meanTow(end+1,1)  = mean(farVals,'omitnan');  %#ok<AGROW>

                % In-cone proportions (optional)
                perFly_near_inCone(end+1,1) = mean(abs(theta(f, isNear(f,:) & validMask(f,:))) <= coneDeg, 'omitnan'); %#ok<AGROW>
                perFly_far_inCone(end+1,1)  = mean(abs(theta(f, ~isNear(f,:) & validMask(f,:))) <= coneDeg, 'omitnan'); %#ok<AGROW>
            end
        end
    end
end

%% Paired tests across flies (near vs far)
% Towardness means
[dTow, p_tow, stats_tow] = paired_test(perFly_near_meanTow, perFly_far_meanTow);
% In-cone proportions
[dCone, p_cone, stats_cone] = paired_test(perFly_near_inCone, perFly_far_inCone);

%% Report
fprintf('N flies (with data in both halves): %d\n', numel(perFly_near_meanTow));
fprintf('Towardness (mean±SEM): NEAR = %.3f ± %.3f, FAR = %.3f ± %.3f, Δ=%.3f, p=%.3g (%s)\n', ...
    mean(perFly_near_meanTow), sem(perFly_near_meanTow), ...
    mean(perFly_far_meanTow),  sem(perFly_far_meanTow), ...
    dTow, p_tow, stats_tow);
fprintf('In-cone |θ|≤%d°:       NEAR = %.3f ± %.3f, FAR = %.3f ± %.3f, Δ=%.3f, p=%.3g (%s)\n', ...
    coneDeg, ...
    mean(perFly_near_inCone), sem(perFly_near_inCone), ...
    mean(perFly_far_inCone),  sem(perFly_far_inCone), ...
    dCone, p_cone, stats_cone);

%% Plot (mean ± SEM across flies)
figure('Color','w'); hold on;
M = [mean(perFly_near_meanTow), mean(perFly_far_meanTow)];
S = [sem(perFly_near_meanTow),  sem(perFly_far_meanTow)];
bar(1:2, M, 'FaceColor',[0.85 0.85 0.85]); 
errorbar(1:2, M, S, 'k.', 'LineWidth',1.5);
set(gca,'XTick',1:2,'XTickLabel',{'Near half','Far half'});
ylabel('<cos \theta> (towardness)'); grid on; box on;
title(sprintf('Orientation vs half-arena (cone=%d°)  N=%d flies', coneDeg, numel(perFly_near_meanTow)));
f = gcf;
f.Position = [620   372   413   595];

%% Plot (mean ± SEM across flies)
figure('Color','w'); hold on;
M = [mean(perFly_near_inCone), mean(perFly_far_inCone)];
S = [sem(perFly_near_inCone),  sem(perFly_far_inCone)];
bar(1:2, M, 'FaceColor',[0.85 0.85 0.85]); 
errorbar(1:2, M, S, 'k.', 'LineWidth',1.5);
set(gca,'XTick',1:2,'XTickLabel',{'Near half','Far half'});
ylabel('<cos \theta> (towardness)'); grid on; box on;
title(sprintf('Orientation vs half-arena (cone=%d°)  N=%d flies', coneDeg, numel(perFly_far_inCone)));
f = gcf;
f.Position = [620   372   413   595];

% Optional: add paired scatter with lines
% xJ = 0.07;
% for i=1:numel(perFly_near_meanTow)
%     plot([1-xJ, 2+xJ], [perFly_near_meanTow(i), perFly_far_meanTow(i)], '-', 'Color',[0.7 0.7 0.7]);
% end
% scatter(ones(size(perFly_near_meanTow))-xJ, perFly_near_meanTow, 10, 'k', 'filled');
% scatter(2*ones(size(perFly_far_meanTow))+xJ, perFly_far_meanTow, 10, 'k', 'filled');

%% Helper subfunctions
function s = sem(x), s = std(x,0,'omitnan')/sqrt(sum(~isnan(x))); end

function [d, p, method] = paired_test(x,y)
    % Returns mean difference (near - far), p-value, and method string
    dif = x - y;
    d = mean(dif,'omitnan');
    % Try parametric; fallback to nonparametric if needed
    try
        [~,p,~,~] = ttest(x,y); method = 'paired t-test';
    catch
        p = NaN; method = 'paired t-test (failed)';
    end
    if isnan(p) || isinf(p)
        p = signrank(x,y); method = 'Wilcoxon signed-rank';
    end
end

end
