%% Plotting visual field from both eyes. 


% Example binary pattern: 4 rows, 64 columns
nRows = 4;
nCols = 64;
pattern = false(nRows, nCols);

% Make a simple pattern: a bar covering 30 degrees around 90°
barCenterDeg = 90;
barWidthDeg  = 30;

azWorld = linspace(-180, 180, nCols+1); azWorld(end) = [];
a = azWorld;
b = barCenterDeg;
d = mod(a - b + 180, 360) - 180;
inBar = abs(d) <= barWidthDeg/2;
pattern(:, inBar) = true;

% Agent in center, heading 0 degrees (along +X)
agentPos   = [-60 -50];
headingDeg = 90;

visualizeAgentView(pattern, agentPos, headingDeg);
f = gcf;
f.Position = [134   685  1254  259];



% function test_visualizeAgentView()
% TEST_VISUALIZEAGENTVIEW
% Demonstrate three situations using visualizeAgentView.m:
%   1) Agent in the middle of the arena.
%   2) Agent very close to the bar so it nearly fills one eye's FOV.
%   3) Agent on the opposite side of the arena from the bar.

    %% Arena + pattern parameters (from your description)
    nRows         = 24;
    nCols         = 96;
    arenaDiameter = 240;              % mm
    arenaRadius   = arenaDiameter/2;  % 120 mm
    anglePerCol   = 1.875;            % deg per column
    arenaSpanDeg  = nCols * anglePerCol;  % 180 deg

    % Azimuths at arena center for each column: [-90, 90]
    azAtCenter = linspace(-arenaSpanDeg/2, arenaSpanDeg/2, nCols+1);
    azAtCenter(end) = [];

    %% Create a single-bar pattern
    pattern = false(nRows, nCols);

    % Put the bar at +60 deg (towards +X, a bit “to the left” in world view)
    barAzDeg   = 60;  % you can change this
    [~, barColIdx] = min(abs(azAtCenter - barAzDeg));

    % Make the entire column ON
    pattern(:, barColIdx) = true;

    %% 1) Agent in the middle of the arena, facing +X
    agentPos1   = [0, 0];   % center
    heading1Deg = 0;        % facing +X

    visualizeAgentView(pattern, agentPos1, heading1Deg);
    sgtitle('1) Agent in the middle, facing +X');

    %% 2) Agent very close to the bar on arena edge
    %
    % The bar is at azimuth +60 deg at the arena wall (radius 120 mm):
    barThetaRad = deg2rad(barAzDeg);
    barX = arenaRadius * cos(barThetaRad);
    barY = arenaRadius * sin(barThetaRad);

    % Place agent a bit inside from the bar along the radial line:
    % e.g. 10 mm inside the wall.
    distInside = 1;   % mm
    agentPos2 = [ (arenaRadius - distInside) * cos(barThetaRad), ...
                  (arenaRadius - distInside) * sin(barThetaRad) ];

    % Make the agent face directly toward the arena center (i.e. opposite of bar)
    % so that the bar is nearly straight behind it; then one eye might see most of it
    % depending on your chosen eye separation and FOV.
    heading2Deg = barAzDeg-30;   % facing roughly toward center, away from bar

    % For debugging / playing: sometimes it's more intuitive to make the agent
    % face the bar instead:
    % heading2Deg = barAzDeg;       % try this if you want bar in frontal view

    visualizeAgentView(pattern, agentPos2, heading2Deg);
    sgtitle('2) Agent near the bar');

    %% 3) Agent on the opposite side of the arena from the bar
    %
    % Place the agent on the other side of the circle from the bar position:
    agentPos3 = -[barX, barY];   % opposite side of arena

    % Let the agent face the bar directly:
    heading3Deg = barAzDeg;   % facing toward the bar

    visualizeAgentView(pattern, agentPos3, heading3Deg);
    sgtitle('3) Agent opposite the bar, facing it');

% end



% Parameters
nRows         = 24;
nCols         = 96;
anglePerCol   = 1.875;            % deg
arenaDiameter = 240;
arenaRadius   = arenaDiameter / 2;

% Azimuths at arena center for each column: [-90, 90]
azAtCenter = linspace(-nCols*anglePerCol/2, nCols*anglePerCol/2, nCols+1);
azAtCenter(end) = [];

% Build a single-bar pattern at barAzDeg
barAzDeg = 60;
pattern = false(nRows, nCols);
[~, barColIdx] = min(abs(azAtCenter - barAzDeg));
pattern(:, barColIdx) = true;

% Choose a pose that maximizes left-eye coverage
epsInside = 1;     % how close to the wall (mm)
agentPos = [(arenaRadius - epsInside) * cosd(barAzDeg), ...
            (arenaRadius - epsInside) * sind(barAzDeg)];

eyeSeparationDeg = 120;
leftCenterRel    = +eyeSeparationDeg/2;   % +60 deg
headingDeg       = barAzDeg - leftCenterRel;   % ~0 deg

% Visualize
visualizeAgentView(pattern, agentPos, headingDeg-240);
title(sprintf('Agent near bar (left eye maximized), heading = %.1f°', headingDeg));








%% Pattern of single pixel bar.

% Parameters
nRows         = 24;
nCols         = 192;
anglePerCol   = 1.875;            % deg
arenaDiameter = 240;
arenaRadius   = arenaDiameter / 2;

% Azimuths at arena center for each column: [-90, 90]
azAtCenter = linspace(-nCols*anglePerCol/2, nCols*anglePerCol/2, nCols+1);
azAtCenter(end) = [];

% Build a single-bar pattern at barAzDeg
barAzDeg = 60;
pattern = false(nRows, nCols);
[~, barColIdx] = min(abs(azAtCenter - barAzDeg));
pattern(:, barColIdx) = true;

% Agent very close to the bar along the radial line
epsInside = 1;   % mm inside the wall
agentPos = [(arenaRadius - epsInside) * cosd(barAzDeg), ...
            (arenaRadius - epsInside) * sind(barAzDeg)];

visualizeAgentView(pattern, [50,100], 100);
sgtitle(sprintf('Bar at %.1f°, agent near bar, heading = %.1f°', ...
    barAzDeg, headingLeftMax));
f = gcf;
f.Position = [110  589  1408  365];


%% 60 deg gratings. 

pattern = false(nRows, nCols);
grating_w = 16; % width of grating in LEDs.
pattern(:, 1:grating_w) = true;
pattern(:, (grating_w*2)+1:grating_w*3) = true;
pattern(:, (grating_w*4)+1:grating_w*5) = true;
pattern(:, (grating_w*6)+1:grating_w*7) = true;
pattern(:, (grating_w*8)+1:grating_w*9) = true;
pattern(:, (grating_w*10)+1:grating_w*11) = true;

visualizeAgentView(pattern, [0, -100], 0);
f = gcf;
f.Position = [110  589  1408  365];







