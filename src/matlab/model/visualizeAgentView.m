function visualizeAgentView(pattern, agentPos, headingDeg)
% VISUALIZEAGENTVIEW Visualize how a circular LED arena looks to an agent's two eyes.
%
%   visualizeAgentView(pattern, agentPos, headingDeg)
%
%   Inputs:
%     pattern    : [nRows x nCols] binary array of LED states on the arena.
%                  Columns correspond to physical LED columns around an arc.
%     agentPos   : [x y] position of the agent in arena coordinates (mm).
%     headingDeg : Scalar heading of the agent in DEGREES.
%                  0 degrees = along +X axis, increasing CCW.
%
%   The function produces a 1x4 figure:
%     (1) Top-down view of circular arena, agent position, and heading.
%     (2) Pattern wrapped around the physical circular arena (top-down).
%     (3) Left eye view (retinocentric, depends on agentPos and heading).
%     (4) Right eye view (retinocentric, depends on agentPos and heading).
%
%   Arena / display geometry (your arena):
%     - Arena diameter: 240 mm  → radius = 120 mm
%     - 24 pixels high
%     - 96 pixels around circumference
%     - Each column subtends 1.875 deg at the arena center → total span = 180 deg.

    if nargin < 3
        error('Usage: visualizeAgentView(pattern, agentPos, headingDeg)');
    end

    % Basic checks
    if ~islogical(pattern)
        pattern = pattern ~= 0; % force binary/logical
    end
    if numel(agentPos) ~= 2
        error('agentPos must be a 2-element vector [x y].');
    end

    [nRows, nCols] = size(pattern);

    % --- Physical arena parameters ---
    arenaDiameter    = 240;                  % mm
    arenaRadius      = arenaDiameter/2;      % 120 mm
    anglePerColDeg   = 360/nCols;                % deg per LED column
    anglePerColRad   = deg2rad(anglePerColDeg);
    arenaSpanDeg     = nCols * anglePerColDeg;      % 180 deg
    arenaSpanRad     = deg2rad(arenaSpanDeg);       % radians
    thetaMin         = -arenaSpanRad/2;             % left edge (rad)
    thetaMax         = +arenaSpanRad/2;             % right edge (rad)

    % Column centers at arena center (rad)
    thetaCenters = linspace(thetaMin + anglePerColRad/2, ...
                            thetaMax - anglePerColRad/2, nCols);

    % Column edges at arena center (rad) – length nCols+1
    thetaEdges = linspace(thetaMin, thetaMax, nCols+1);

    % For radial mapping of the 24 rows (for the wall visualization)
    rOuter          = arenaRadius*1.4;          % outer radius
    rInner          = arenaRadius;    % inner radius of LED region

    % --- Eye model parameters (can tweak) ---
    eyeSeparationDeg = 120;   % angle between centers of left/right eyes
    eyeFOVDeg        = 120;   % field of view per eye
    nEyeCols         = 80;    % horizontal resolution for each eye's view

    leftCenterRelDeg  = +eyeSeparationDeg/2;   % left eye center relative to heading
    rightCenterRelDeg = -eyeSeparationDeg/2;   % right eye center relative to heading

    % Relative angles within each eye's FOV
    relGrid = linspace(-eyeFOVDeg/2, +eyeFOVDeg/2, nEyeCols);

    % World angles (deg) of each sample direction for each eye
    leftAnglesDeg  = headingDeg + leftCenterRelDeg  + relGrid;
    rightAnglesDeg = headingDeg + rightCenterRelDeg + relGrid;

    % Convert to radians
    leftAnglesRad  = deg2rad(leftAnglesDeg);
    rightAnglesRad = deg2rad(rightAnglesDeg);

    % --- Ray casting for each eye ---
    leftView  = castEye(pattern, agentPos, leftAnglesRad, ...
                        thetaEdges, thetaMin, thetaMax, arenaRadius);
    rightView = castEye(pattern, agentPos, rightAnglesRad, ...
                        thetaEdges, thetaMin, thetaMax, arenaRadius);

    % --- Plotting ---
    figure('Color','w','Name','Agent View in Circular Arena');

    % 1) Arena top-down view
    subplot(1,3, 1); hold on; axis equal;
    title('Arena + agent');

    % Draw circular arena (physical size)
    thetaPlot = linspace(0, 2*pi, 360);
    plot(arenaRadius*cos(thetaPlot), arenaRadius*sin(thetaPlot), 'k-');

    % Plot agent position
    plot(agentPos(1), agentPos(2), 'ro', 'MarkerFaceColor','r');

    % Heading vector
    headLen = 0.5 * arenaRadius;
    hx = agentPos(1) + headLen*cosd(headingDeg);
    hy = agentPos(2) + headLen*sind(headingDeg);
    plot([agentPos(1), hx], [agentPos(2), hy], 'r-', 'LineWidth', 2);

    % Arena outline
    plot(arenaRadius*cos(thetaPlot), arenaRadius*sin(thetaPlot), 'k-');

    % Map each LED (row, col) to a position on the circular wall band
    [colIdx, rowIdx] = meshgrid(1:nCols, 1:nRows);

    % Azimuth at the center for each column (rad)
    thetaC = thetaCenters(colIdx);

    % Radius for each row: row 1 near the wall, row nRows toward center
    rRow = rInner + (nRows - rowIdx + 0.5) / nRows * (rOuter - rInner);

    X = rRow .* cos(thetaC);
    Y = rRow .* sin(thetaC);

    % Flatten for scatter plotting
    Xv = X(:);
    Yv = Y(:);
    Pv = pattern(:);

    % Plot ON LEDs as filled squares
    scatter(Xv(Pv), Yv(Pv), 20, 'k', 'filled', 's');

    axis equal;
    axis(arenaRadius * [-1.1 1.1 -1.1 1.1]);
    set(gca,'YDir','normal');
    grid on;

    % 3) Left eye view
    subplot(1,3,2);
    imagesc(relGrid, 1:nRows, leftView);
    colormap(gray);
    title('Left eye view');
    xlabel('Angle relative to eye center (deg)');
    ylabel('Vertical LED index');
    set(gca,'YDir','normal');

    % 4) Right eye view
    subplot(1,3,3);
    imagesc(relGrid, 1:nRows, rightView);
    colormap(gray);
    title('Right eye view');
    xlabel('Angle relative to eye center (deg)');
    ylabel('Vertical LED index');
    set(gca,'YDir','normal');

end

% ---------- Helper: ray casting for one eye ----------

function viewEye = castEye(pattern, agentPos, sampleAnglesRad, ...
                           thetaEdges, thetaMin, thetaMax, arenaRadius)
% CASTEYE
%   For each sample angle (world angle from agent), cast a ray to the
%   arena circle and find which LED column is hit based on thetaEdges.
%
%   pattern        : [nRows x nCols] binary
%   agentPos       : [xA, yA] (mm)
%   sampleAnglesRad: 1 x nEyeCols (rad), world angles for this eye's samples
%   thetaEdges     : 1 x (nCols+1) LED bin edges at arena center (rad)
%   thetaMin/Max   : min/max supported LED angles at center (rad)
%   arenaRadius    : circle radius (mm)
%
%   viewEye        : [nRows x nEyeCols] binary eye view

    [nRows, nCols] = size(pattern);
    nEyeCols = numel(sampleAnglesRad);
    viewEye = false(nRows, nEyeCols);

    xA = agentPos(1);
    yA = agentPos(2);

    % Precompute some constants
    thetaSpan = thetaMax - thetaMin;         % should be arenaSpanRad
    dTheta    = thetaEdges(2) - thetaEdges(1);

    for k = 1:nEyeCols
        ang = sampleAnglesRad(k);  % world angle for this sample

        % Ray direction
        ux = cos(ang);
        uy = sin(ang);

        % Solve |agentPos + t*u|^2 = arenaRadius^2 for t > 0
        % (xA + t*ux)^2 + (yA + t*uy)^2 = R^2
        a = ux*ux + uy*uy;          % should be 1
        b = 2*(xA*ux + yA*uy);
        c = xA^2 + yA^2 - arenaRadius^2;

        disc = b^2 - 4*a*c;
        if disc <= 0
            % No real intersection (should not happen if agent inside arena)
            continue;
        end
        t = (-b + sqrt(disc)) / (2*a);
        if t <= 0
            % Intersection behind agent; take other root if positive
            t2 = (-b - sqrt(disc)) / (2*a);
            if t2 <= 0
                continue;
            else
                t = t2;
            end
        end

        % Intersection point on circle
        xHit = xA + t*ux;
        yHit = yA + t*uy;

        % Arena-center angle of hit point
        thetaHit = atan2(yHit, xHit);   % in [-pi, pi]

        % If hit angle is outside LED-covered span, no LED for this ray
        if thetaHit < thetaMin || thetaHit >= thetaMax
            continue;
        end

        % Map thetaHit to column index via binning
        colIdx = floor((thetaHit - thetaMin) / dTheta) + 1;  % 1-based
        if colIdx < 1 || colIdx > nCols
            continue;
        end

        % Copy that column's vertical pattern into this eye column
        viewEye(:, k) = pattern(:, colIdx);
    end
end





% function visualizeAgentView(pattern, agentPos, headingDeg)
% % VISUALIZEAGENTVIEW Visualize how a circular LED arena looks to an agent's two eyes.
% %
% %   visualizeAgentView(pattern, agentPos, headingDeg)
% %
% %   Inputs:
% %     pattern    : [nRows x nCols] binary array of LED states on the arena.
% %                  Columns correspond to physical LED columns around the arc.
% %     agentPos   : [x y] position of the agent in arena coordinates (mm).
% %     headingDeg : Scalar heading of the agent in DEGREES.
% %                  0 degrees = along +X axis, increasing CCW.
% %
% %   The function produces a 1x4 figure:
% %     (1) Top-down view of circular arena, agent position, and heading.
% %     (2) Pattern wrapped around the physical circular arena (top-down).
% %     (3) Left eye view (retinocentric, depends on agentPos).
% %     (4) Right eye view (retinocentric, depends on agentPos).
% %
% %   Arena / display geometry (matches your description):
% %     - Arena diameter: 240 mm  → radius = 120 mm
% %     - 24 pixels high
% %     - 96 pixels around circumference
% %     - Each column subtends 1.875 deg at the *arena center* → total span = 180 deg.
% 
%     if nargin < 3
%         error('Usage: visualizeAgentView(pattern, agentPos, headingDeg)');
%     end
% 
%     % Basic checks
%     if ~islogical(pattern)
%         pattern = pattern ~= 0; % force binary/logical
%     end
%     if numel(agentPos) ~= 2
%         error('agentPos must be a 2-element vector [x y].');
%     end
% 
%     [nRows, nCols] = size(pattern);
% 
%     % --- Physical arena parameters (your numbers) ---
%     arenaDiameter   = 240;                  % mm
%     arenaRadius     = arenaDiameter/2;      % 120 mm
%     anglePerColDeg  = 1.875;                % deg per LED column
%     arenaSpanDeg    = nCols * anglePerColDeg;  % should be 180 deg
% 
%     % For radial mapping of the 24 rows (for the wall visualization)
%     rInner          = arenaRadius;    % inner radius of LED region (tweakable)
%     rOuter          = arenaRadius * 1.5;          % outer radius at wall
% 
%     % --- Eye model parameters (same as before, tweakable) ---
%     eyeSeparationDeg = 120;   % angle between centers of left/right eyes
%     eyeFOVDeg        = 120;   % field of view per eye
%     nEyeCols         = 80;    % horizontal resolution for each eye's view
% 
%     % --- "World" azimuth at the arena center for each column (just for plotting) ---
%     % Centered around 0 deg (straight ahead), spanning [-arenaSpan/2, +arenaSpan/2]
%     azAtCenter = linspace(-arenaSpanDeg/2, arenaSpanDeg/2, nCols+1);
%     azAtCenter(end) = [];  % remove duplicate endpoint
% 
%     % --- Physical LED positions on the arena wall (for each column) ---
%     % We place the columns on a circular arc at radius = arenaRadius.
%     wallThetaDeg = azAtCenter;          % same angles at the center
%     wallThetaRad = deg2rad(wallThetaDeg);
%     xWall = arenaRadius * cos(wallThetaRad);
%     yWall = arenaRadius * sin(wallThetaRad);
% 
%     % --- Azimuth of each column as seen from the AGENT position ---
%     % This is the key change: we now use these angles for the eye views.
%     dx = xWall - agentPos(1);
%     dy = yWall - agentPos(2);
%     azFromAgent = atan2d(dy, dx);       % in (-180, 180]
% 
%     % Eye centers relative to the agent's heading
%     leftCenterRel  = +eyeSeparationDeg/2;   % left eye center relative to heading
%     rightCenterRel = -eyeSeparationDeg/2;   % right eye center relative to heading
% 
%     % Desired angular samples for each eye in WORLD coordinates (agent-centric)
%     relGrid = linspace(-eyeFOVDeg/2, +eyeFOVDeg/2, nEyeCols);
%     azLeftWorld  = headingDeg + (leftCenterRel  + relGrid);
%     azRightWorld = headingDeg + (rightCenterRel + relGrid);
% 
%     % NOTE: we do NOT need to wrap to [-180, 180) for interp1, because
%     % azFromAgent spans only the physical arena (~180 deg) and is monotonic.
% 
%     % Sample the pattern for each eye using azimuths *from the agent*
%     leftView  = sampleEye(pattern, azFromAgent, azLeftWorld);
%     rightView = sampleEye(pattern, azFromAgent, azRightWorld);
% 
%     % --- Plotting ---
%     figure('Color','w','Name','Agent View in Circular Arena');
% 
%     % 1) World pattern wrapped on circular arena (as seen from above) + fly
% 
%     subplot(1,3,1); hold on; axis equal;
%     title('Arena + agent');
% 
%     % Draw circular arena (physical size)
%     theta = linspace(0, 2*pi, 360);
%     plot(arenaRadius*cos(theta), arenaRadius*sin(theta), 'k-');
% 
%     % Plot agent position
%     plot(agentPos(1), agentPos(2), 'ro', 'MarkerFaceColor','r');
% 
%     % Heading vector
%     headLen = 0.5 * arenaRadius;
%     hx = agentPos(1) + headLen*cosd(headingDeg);
%     hy = agentPos(2) + headLen*sind(headingDeg);
%     plot([agentPos(1), hx], [agentPos(2), hy], 'r-', 'LineWidth', 2);
% 
%     % Same arena outline for reference
%     plot(arenaRadius*cos(theta), arenaRadius*sin(theta), 'k-');
% 
%     % Map each LED (row, col) to a position on the circular wall band
%     [colIdx, rowIdx] = meshgrid(1:nCols, 1:nRows);
% 
%     % Azimuth at the center for each column (deg) -> rad
%     azDeg = azAtCenter(colIdx);
%     azRad = deg2rad(azDeg);
% 
%     % Radius for each row (linear from inner to outer)
%     rRow = rInner + (rowIdx + 0.5) / nRows * (rOuter - rInner);
% 
%     X = rRow .* cos(azRad);
%     Y = rRow .* sin(azRad);
% 
%     % Flatten for scatter plotting
%     Xv = X(:);
%     Yv = Y(:);
%     Pv = pattern(:);
% 
%     % Plot ON LEDs as filled squares
%     scatter(Xv(Pv), Yv(Pv), 20, 'k', 'filled', 's');
% 
%     axis equal;
%     axis(arenaRadius * [-1.1 1.1 -1.1 1.1]);
%     set(gca,'YDir','normal');
%     grid on;
% 
%     % 2) Left eye view
%     subplot(1,3,2);
%     imagesc(relGrid, 1:nRows, leftView);
%     colormap(gray);
%     title('Left eye view');
%     xlabel('Angle relative to eye center (deg)');
%     ylabel('Vertical LED index');
%     set(gca,'YDir','normal');
% 
%     % 3) Right eye view
%     subplot(1,3,3);
%     imagesc(relGrid, 1:nRows, rightView);
%     colormap(gray);
%     title('Right eye view');
%     xlabel('Angle relative to eye center (deg)');
%     ylabel('Vertical LED index');
%     set(gca,'YDir','normal');
% 
% end
% 
% % ---------- Helper functions ----------
% 
% function viewEye = sampleEye(pattern, azFromAgent, azEyeWorld)
% % SAMPLEEYE Interpolates pattern along azimuth for a given eye.
% %
% %   viewEye = sampleEye(pattern, azFromAgent, azEyeWorld)
% %
% %   pattern    : [nRows x nCols] binary array.
% %   azFromAgent: 1 x nCols, azimuth of each LED column as seen FROM the agent (deg).
% %   azEyeWorld : 1 x nEyeCols, desired azimuths (deg) in world coords for that eye.
% %
% %   viewEye    : [nRows x nEyeCols] sampled pattern in eye coordinates.
% %
% %   This uses nearest-neighbor interpolation in azimuth. Because azFromAgent
% %   depends on the agent position, the apparent width of each column can change
% %   as the agent moves: moving closer to a column increases its angular size.
% 
%     [nRows, ~] = size(pattern);
%     nEyeCols = numel(azEyeWorld);
%     viewEye = false(nRows, nEyeCols);
% 
%     % azFromAgent should be monotonic across the 180° arena span.
%     % For safety, we sort it (and the columns) before interpolating.
%     [azSorted, idx] = sort(azFromAgent);
%     patternSorted   = pattern(:, idx);
% 
%     for r = 1:nRows
%         rowData = double(patternSorted(r,:));
%         % Nearest neighbor in angle
%         interpVals = interp1(azSorted, rowData, azEyeWorld, 'nearest', 0);
%         viewEye(r,:) = interpVals > 0.5;
%     end
% end
