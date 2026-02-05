% PHOTOTAXIS_TEST_CODE - Analyze phototaxis heading orientation behavior
%
% SCRIPT CONTENTS:
%   - Section 1: Calculate distance and bearing to phototaxis bar reference
%   - Section 2: Add heading_rel_ref (heading relative to reference point)
%   - Section 3: Plot fly positions and reference point
%   - Section 4: Visualize heading angles for single fly/frame
%   - Section 5: Generate polar histograms comparing pre- vs during-stimulus
%
% DESCRIPTION:
%   This is the current analysis script for phototaxis experiments. It computes
%   the heading direction of flies relative to a visual bar stimulus (reference
%   point) and generates polar histograms to visualize orientation preferences.
%   The script adds several computed fields to the DATA struct:
%   - d2bar: Euclidean distance from each fly to the bar (mm)
%   - bearing_to_ref: absolute bearing angle to reference point (degrees)
%   - heading_rel_ref: heading angle relative to reference (degrees, [-180,180])
%
% COORDINATE CONVENTIONS:
%   - 0 degrees = east (right), +90 degrees = south (down)
%   - Heading_rel_ref: 0 = pointing directly at bar, +/-180 = pointing away
%
% ARENA/BAR PARAMETERS:
%   - Pixels per mm (PPM): 4.1691
%   - Reference point (bar center): [29.7426, 52.5293] mm
%
% REQUIREMENTS:
%   - DATA struct with phototaxis condition data (R1_condition_12, R2_condition_12)
%   - Fields needed: x_data, y_data, heading_wrap
%
% See also: analyse_phototaxis, analyse_phototaxis_polar

% Extract JUST the empty split data:
DATA2 = DATA.jfrc100_es_shibire_kir.F;

% Now "DATA2" has meta / R1_condition_3 etc. 
% Condition 12 = phototaxis condition. 
% x and y data in DATA is in "mm"

% Multiply the x and y values by this to get the pixel number. 
PPM = 4.1691;

centre_bar = [124, 219]; % Values in pixels. 
centre_bar_mm = centre_bar / PPM;

% Reference point in mm
ref_mm = [29.7426, 52.5293];

%% Add new data of the distance of the flies from the centre of the phototaxis bar:

conds = {'R1_condition_12','R2_condition_12'};

for i = 1:numel(DATA)
    for c = 1:numel(conds)
        if isfield(DATA(i), conds{c}) && isstruct(DATA(i).(conds{c}))
            S = DATA(i).(conds{c});
            if isfield(S,'x_data') && isfield(S,'y_data')


                x = S.x_data;   % 15 x 2256 (mm)
                y = S.y_data;   % 15 x 2256 (mm)

                % Euclidean distance in mm to [29.7426, 52.5293]
                d_mm = hypot(x - ref_mm(1), y - ref_mm(2));

                % Store distance of fly from centre of the bar:
                DATA(i).(conds{c}).d2bar = d_mm;   % 15 x 2256 (mm)


                % Vector from fly to reference (image coords: +y is down)
                dx = ref_mm(1) - x;
                dy = ref_mm(2) - y;

                % Bearing from each fly to the reference point (deg)
                % Convention: 0°=east, +90°=south, ±180°=west, −90°=north
                bearing_to_ref = atan2d(dy, dx);

                % Store absolute bearing
                DATA(i).(conds{c}).bearing_to_ref = bearing_to_ref;

                % If headings are available, compute relative heading (error)
                if isfield(S,'heading_wrap')
                    hw = S.heading_wrap; % same size as x/y, deg

                    % Wrap to [-180, 180] without requiring Mapping Toolbox
                    heading_rel_ref = mod(bearing_to_ref - hw + 180, 360) - 180;

                    DATA(i).(conds{c}).heading_rel_ref = heading_rel_ref;
                end
            end
        end
    end
end



%% Plot the position of the flies during the first frame and the position of the centre of the phototaxis bar. 

% Extract data for first condition and frame
S = DATA(1).R1_condition_12;

% First frame positions (in mm)
x = S.x_data(:, 1);
y = S.y_data(:, 1);

% Reference position (in mm)
ref_mm = [29.7426, 52.5293];

% Create figure
figure;
hold on;

% Plot each fly’s position as a small red dot
plot(x, -1*y, 'r.', 'MarkerSize', 15);

% Plot the reference position as a blue cross
plot(ref_mm(1), -1*ref_mm(2), 'bx', 'MarkerSize', 12, 'LineWidth', 2);

% Add text labels for each fly above their point
for i = 1:numel(x)
    text(x(i), -1*y(i) + 5, sprintf('%d', i), ... % label with fly index
        'Color', 'k', 'FontSize', 8, 'HorizontalAlignment', 'center');
end

% Add labels and formatting
xlabel('X position (mm)');
ylabel('Y position (mm)');
title('Fly positions at first frame (R1\_condition\_12)');
axis equal; % preserve spatial aspect ratio
grid on;
legend({'Fly positions', 'Reference position'}, 'Location', 'best');

hold off;




%% Plot the angles of a single fly from the reference point on a single frame. 

%% --- Config ---
entryIdx  = 1;                 % which DATA2 entry
condName  = 'R1_condition_12'; % 'R1_condition_12' or 'R2_condition_12'
flyIdx    = 15;                 % which fly (row)
frameIdx  = 1;                 % which frame (column)

ref_mm = [29.7426, 52.5293];   % reference point (mm)
vecLen = 10;                   % length (mm) of the heading/bearing arrows
arcR   = 8;                    % radius (mm) for the angle arc

%% --- Extract data ---
S  = DATA(entryIdx).(condName);
x0 = S.x_data(flyIdx, frameIdx);
y0 = S.y_data(flyIdx, frameIdx);
hw = S.heading_wrap(flyIdx, frameIdx);  % heading (deg), same convention as you described

% Bearing to reference (deg): 0°=east, +90°=south, −90°=north
dx = ref_mm(1) - x0;
dy = ref_mm(2) - y0;
bearing = atan2d(dy, dx);

% Signed angular difference (deg) wrapped to [-180, 180]
rel = mod(bearing - hw + 180, 360) - 180;

%% --- Plot ---
figure; hold on; grid on;
% Keep image coordinate feel: +y downward (south)
set(gca, 'YDir', 'reverse'); 
axis equal;

% Points
plot(x0, y0, 'r.', 'MarkerSize', 18);                      % fly point
plot(ref_mm(1), ref_mm(2), 'bx', 'MarkerSize', 12, 'LineWidth', 2);  % reference

% A line to the reference for context
plot([x0 ref_mm(1)], [y0 ref_mm(2)], ':', 'LineWidth', 1);

% Heading arrow (from fly position)
ux_h = cosd(hw); uy_h = sind(hw);
quiver(x0, y0, vecLen*ux_h, vecLen*uy_h, 0, 'LineWidth', 2); % '0' => no autoscale

% Bearing arrow (direction to reference)
ux_b = cosd(bearing); uy_b = sind(bearing);
quiver(x0, y0, vecLen*ux_b, vecLen*uy_b, 0, 'LineWidth', 2);

% Angle arc between heading (start) and bearing (end) along shortest path
startAng = hw;
endAng   = hw + rel;  % rel already shortest signed difference
t = linspace(startAng, endAng, 100);
arcX = x0 + arcR * cosd(t);
arcY = y0 + arcR * sind(t);
plot(arcX, arcY, 'k-', 'LineWidth', 1.5);

% Put angle label near the middle of the arc
midAng = (startAng + endAng)/2;
text(x0 + (arcR+1)*cosd(midAng), y0 + (arcR+1)*sind(midAng), ...
    sprintf('%.1f^\\circ', rel), 'HorizontalAlignment','center', 'FontSize', 9);

% Labels, legend, title
xlabel('X (mm)'); ylabel('Y (mm)');
legend({'Fly','Reference','Fly→Ref line','Heading','Bearing to ref'}, 'Location','best');
title(sprintf('%s | Fly %d, Frame %d\nHeading = %.1f^\\circ, Bearing = %.1f^\\circ, \\Delta = %.1f^\\circ', ...
    strrep(condName, '_', '-'), flyIdx, frameIdx, hw, bearing, rel));

% Optional: set a tidy view window
pad = 15;
xmin = min([x0, ref_mm(1)]) - pad; xmax = max([x0, ref_mm(1)]) + pad;
ymin = min([y0, ref_mm(2)]) - pad; ymax = max([y0, ref_mm(2)]) + pad;
xlim([xmin xmax]); ylim([ymin ymax]);



%% Generate a polar histogram of the 300 frames before the stimulus starts and the first 300 frames of the stimulus. 

entryIdx  = 1;                 % which DATA entry
condName  = 'R1_condition_12'; % 'R1_condition_12' or 'R2_condition_12'
flyIdx    = 11;                 % which fly (row)
frameIdx  = 1;  

S  = DATA(entryIdx).(condName);
x0 = S.x_data(flyIdx, frameIdx);
y0 = S.y_data(flyIdx, frameIdx);

% Extract angles (degrees) for the chosen fly in different time windows.
ang1_deg = S.heading_rel_ref(flyIdx, 1:300);
ang2_deg = S.heading_rel_ref(flyIdx, 300:600);

% Convert to radians on [0, 2π) to match polarhistogram
ang1 = deg2rad(mod(ang1_deg, 360));
ang2 = deg2rad(mod(ang2_deg, 360));

% Choose bins (e.g., 24 bins = 15° each)
numBins = 24;
binEdges = linspace(0, 2*pi, numBins+1);

% Plot
figure;
ax = polaraxes; hold(ax, 'on');

% Match your image-style angle convention: 0° at east, positive clockwise
ax.ThetaZeroLocation = 'top';   % 0° to the right (east)
ax.ThetaDir = 'clockwise';        % +θ goes clockwise (toward south)

% First interval: 1:300 (light gray line)
polarhistogram(ax, ang1, binEdges, 'EdgeColor', [0.7 0.7 0.7], 'LineWidth', 1.5, 'FaceColor', [0.7 0.7 0.7], 'FaceAlpha', 0.4);

% Second interval: 300:600 (magenta line)
polarhistogram(ax, ang2, binEdges, 'EdgeColor', [1 0.6 1], 'LineWidth', 1.8, 'FaceColor', [1 0.6 1], 'FaceAlpha', 0.4);

% Labels / legend
title(sprintf('%s | Fly %d — heading\\_rel\\_ref', strrep(condName, '_', '-'), flyIdx));
legend({'F1–300: Before', 'F300–600: Stim'}, 'Location', 'southoutside');

% Optional: show degree ticks every 30°
ax.ThetaTick = 0:30:330;















