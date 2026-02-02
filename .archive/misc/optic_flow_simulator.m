function optic_flow_simulator()
    % Create figure and UI
    f = figure('Name', 'Full Optic Flow Simulator', ...
        'NumberTitle', 'off', 'Position', [100, 100, 1000, 600]);

    % Axes for left and right eyes
    axLeft = subplot(1,2,1);
    axRight = subplot(1,2,2);
    axesList = [axLeft, axRight];
    for ax = axesList
        axis(ax, [-1 1 -1 1]);
        axis(ax, 'equal');
        hold(ax, 'on');
    end
    title(axLeft, 'Left Eye Optic Flow');
    title(axRight, 'Right Eye Optic Flow');

    % UI sliders
    uicontrol('Style', 'text', 'String', 'Forward Velocity (T)', ...
        'Position', [150 60 150 20]);
    sldT = uicontrol('Style', 'slider', ...
        'Min', -2, 'Max', 2, 'Value', 1, ...
        'Position', [150 40 200 20], ...
        'Callback', @(src, ~) updatePlot());

    uicontrol('Style', 'text', 'String', 'Turning Velocity (R)', ...
        'Position', [400 60 150 20]);
    sldR = uicontrol('Style', 'slider', ...
        'Min', -2, 'Max', 2, 'Value', 0.5, ...
        'Position', [400 40 200 20], ...
        'Callback', @(src, ~) updatePlot());

    uicontrol('Style', 'text', 'String', 'Lateral Velocity (L)', ...
        'Position', [650 60 150 20]);
    sldL = uicontrol('Style', 'slider', ...
        'Min', -2, 'Max', 2, 'Value', 0, ...
        'Position', [650 40 200 20], ...
        'Callback', @(src, ~) updatePlot());

    % Update plot on first run
    updatePlot();

    function updatePlot()
        % Clear previous plots
        for ax = axesList
            cla(ax);
        end

        % Read slider values
        T = sldT.Value;  % Forward translation
        R = sldR.Value;  % Yaw rotation
        L = sldL.Value;  % Lateral (sideways) translation

        % Create 2D grid of points in visual space
        [xgrid, ygrid] = meshgrid(linspace(-1, 1, 25), linspace(-1, 1, 25));
        r = sqrt(xgrid.^2 + ygrid.^2);
        mask = r > 0.05;  % avoid singularity at center

        x = xgrid(mask);
        y = ygrid(mask);
        theta = atan2(y, x);  % angle from center

        % Depth model: nearer points have stronger flow
        z = 1 + 0.5 * r(mask);  % depth increases with distance

        % Optic flow from forward translation
        flowT_x = -T * x ./ z;
        flowT_y = -T * y ./ z;

        % % Optic flow from lateral translation (left/right)
        % % Lateral translation creates horizontal flow perpendicular to x-axis
        % flowL_x = -L * sin(theta) ./ z;
        % flowL_y = L * cos(theta) ./ z;

        % Optic flow from lateral (sideways) translation
        % Translation vector is [-L, 0, 0] in world coordinates
        flowL_x = L ./ z;   % rightward motion if L > 0
        flowL_y = zeros(size(z));  % no vertical component


        % Optic flow from rotation (turning)
        flowR_x = -R * sin(theta);
        flowR_y = R * cos(theta);

        % Total optic flow
        flowX = flowT_x + flowL_x + flowR_x;
        flowY = flowT_y + flowL_y + flowR_y;

        % Plot for Left Eye (left side of visual field)
        leftIdx = x < 0;
        quiver(axLeft, x(leftIdx), y(leftIdx), 0.1 * flowX(leftIdx), 0.1 * flowY(leftIdx), 0, ...
               'Color', 'b', 'LineWidth', 1);

        % Plot for Right Eye (right side of visual field)
        rightIdx = x >= 0;
        quiver(axRight, x(rightIdx), y(rightIdx), 0.1 * flowX(rightIdx), 0.1 * flowY(rightIdx), 0, ...
               'Color', 'r', 'LineWidth', 1);

        % Titles
        title(axLeft, sprintf('Left Eye | T=%.2f, R=%.2f, L=%.2f', T, R, L));
        title(axRight, sprintf('Right Eye | T=%.2f, R=%.2f, L=%.2f', T, R, L));
    end
end
