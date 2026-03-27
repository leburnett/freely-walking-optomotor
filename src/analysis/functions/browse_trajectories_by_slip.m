function browse_trajectories_by_slip(rep_data, travel_dir, abs_ang_diff, ...
    speed_mask, stim_on, stim_off, arena_center, arena_r, speed_thresh)
% BROWSE_TRAJECTORIES_BY_SLIP  Interactive browser for fly trajectories
%   coloured by the angular difference between heading and travelling direction.
%
%   browse_trajectories_by_slip(rep_data, travel_dir, abs_ang_diff,
%       speed_mask, stim_on, stim_off, arena_center, arena_r, speed_thresh)
%
%   Displays one fly trajectory at a time during the stimulus period,
%   coloured by |heading - travelling direction|. Navigate between flies
%   using buttons or arrow keys.
%
%   INPUTS:
%     rep_data      - struct with fields x_data, y_data [n_flies x n_frames]
%     travel_dir    - [n_flies x n_frames] travelling direction (deg)
%     abs_ang_diff  - [n_flies x n_frames] |heading - travel dir| (deg)
%     speed_mask    - [n_flies x n_frames] logical, true where speed > threshold
%     stim_on       - scalar, stimulus onset frame index
%     stim_off      - scalar, stimulus offset frame index
%     arena_center  - [cx, cy] arena centre in mm
%     arena_r       - arena radius in mm
%     speed_thresh  - speed threshold used (for display only)
%
%   KEYBOARD:
%     Left arrow  — previous fly
%     Right arrow — next fly
%
% See also: travelling_direction_analysis, plot_trajectory_colormapped

    %% Extract stimulus period
    stim_range = stim_on:stim_off;
    x_stim = rep_data.x_data(:, stim_range);
    y_stim = rep_data.y_data(:, stim_range);
    abs_diff_stim = abs_ang_diff(:, stim_range);
    speed_stim = speed_mask(:, stim_range);

    n_flies = size(x_stim, 1);
    n_stim_frames = numel(stim_range);

    % NaN out frames below speed threshold (these become gaps in trajectory)
    x_plot = x_stim;
    y_plot = y_stim;
    diff_plot = abs_diff_stim;
    x_plot(~speed_stim) = NaN;
    y_plot(~speed_stim) = NaN;
    diff_plot(~speed_stim) = NaN;

    % Precompute per-fly summary stats
    fly_mean_diff = NaN(n_flies, 1);
    fly_sideways_frac = NaN(n_flies, 1);
    for f = 1:n_flies
        vals = abs_diff_stim(f, speed_stim(f, :));
        if ~isempty(vals)
            fly_mean_diff(f) = mean(vals, 'omitnan');
            fly_sideways_frac(f) = sum(vals >= 75 & vals <= 105) / numel(vals);
        end
    end

    %% Colormap: hot (0° = black/dark red -> 180° = white/yellow)
    cmap_div = hot(256);

    %% Create figure
    fig = figure('Name', 'Trajectory Browser — Heading vs Travel Direction', ...
        'NumberTitle', 'off', ...
        'Units', 'normalized', ...
        'Position', [0.15 0.1 0.5 0.75], ...
        'KeyPressFcn', @key_press_cb);

    % Main axes
    ax = axes('Parent', fig, 'Units', 'normalized', ...
        'Position', [0.08 0.15 0.82 0.78]);

    % Control panel
    ctrl_y = 0.02;
    ctrl_h = 0.06;

    uicontrol('Parent', fig, 'Style', 'pushbutton', 'String', '<< Prev', ...
        'Units', 'normalized', 'Position', [0.10 ctrl_y 0.12 ctrl_h], ...
        'FontSize', 12, 'Callback', @(~,~) step_fly(-1));

    uicontrol('Parent', fig, 'Style', 'pushbutton', 'String', 'Next >>', ...
        'Units', 'normalized', 'Position', [0.24 ctrl_y 0.12 ctrl_h], ...
        'FontSize', 12, 'Callback', @(~,~) step_fly(1));

    uicontrol('Parent', fig, 'Style', 'text', 'String', 'Fly:', ...
        'Units', 'normalized', 'Position', [0.40 ctrl_y 0.06 ctrl_h], ...
        'FontSize', 12, 'HorizontalAlignment', 'right');

    h_edit = uicontrol('Parent', fig, 'Style', 'edit', 'String', '1', ...
        'Units', 'normalized', 'Position', [0.47 ctrl_y 0.08 ctrl_h], ...
        'FontSize', 12, 'Callback', @edit_fly_cb);

    h_label = uicontrol('Parent', fig, 'Style', 'text', ...
        'String', sprintf('/ %d', n_flies), ...
        'Units', 'normalized', 'Position', [0.56 ctrl_y 0.10 ctrl_h], ...
        'FontSize', 12, 'HorizontalAlignment', 'left');

    h_info = uicontrol('Parent', fig, 'Style', 'text', 'String', '', ...
        'Units', 'normalized', 'Position', [0.68 ctrl_y 0.30 ctrl_h], ...
        'FontSize', 11, 'HorizontalAlignment', 'left');

    %% State
    current_fly = 1;

    % Draw first fly
    draw_fly();

    %% --- Nested functions ---

    function draw_fly()
        cla(ax);
        hold(ax, 'on');

        % Arena boundary
        theta = linspace(0, 2*pi, 200);
        plot(ax, arena_center(1) + arena_r * cos(theta), ...
            arena_center(2) + arena_r * sin(theta), '-', ...
            'Color', [0.7 0.7 0.7], 'LineWidth', 1);

        % Get this fly's data
        xf = x_plot(current_fly, :);
        yf = y_plot(current_fly, :);
        cf = diff_plot(current_fly, :);

        % Plot trajectory using patch trick (contiguous valid segments)
        valid_f = ~isnan(xf) & ~isnan(yf) & ~isnan(cf);
        d_valid = diff([0, valid_f, 0]);
        seg_starts = find(d_valid == 1);
        seg_ends = find(d_valid == -1) - 1;

        for s = 1:numel(seg_starts)
            idx = seg_starts(s):seg_ends(s);
            if numel(idx) < 2, continue; end
            patch(ax, [xf(idx) NaN], [yf(idx) NaN], 0, ...
                'EdgeColor', 'interp', 'FaceColor', 'none', ...
                'CData', [cf(idx) NaN], 'LineWidth', 1.5);
        end

        % Start/end markers
        if any(valid_f)
            first_v = find(valid_f, 1, 'first');
            last_v = find(valid_f, 1, 'last');
            plot(ax, xf(first_v), yf(first_v), 'o', ...
                'MarkerSize', 10, 'MarkerFaceColor', [0.2 0.7 0.2], ...
                'MarkerEdgeColor', 'none');
            plot(ax, xf(last_v), yf(last_v), 'o', ...
                'MarkerSize', 10, 'MarkerFaceColor', [0.8 0.2 0.2], ...
                'MarkerEdgeColor', 'none');
        end

        % Formatting
        colormap(ax, cmap_div);
        clim(ax, [0 180]);
        cb = colorbar(ax);
        cb.Label.String = '|Heading − Travel Dir| (deg)';
        cb.Label.FontSize = 12;

        axis(ax, 'equal');
        xlim(ax, [arena_center(1) - arena_r - 5, arena_center(1) + arena_r + 5]);
        ylim(ax, [arena_center(2) - arena_r - 5, arena_center(2) + arena_r + 5]);
        xlabel(ax, 'x (mm)', 'FontSize', 14);
        ylabel(ax, 'y (mm)', 'FontSize', 14);
        title(ax, sprintf('Fly %d / %d — mean |diff| = %.1f°, sideways = %.1f%%', ...
            current_fly, n_flies, fly_mean_diff(current_fly), ...
            100 * fly_sideways_frac(current_fly)), 'FontSize', 16);
        set(ax, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

        % Update controls
        set(h_edit, 'String', num2str(current_fly));
        set(h_info, 'String', sprintf('speed > %g mm/s', speed_thresh));
    end

    function step_fly(delta)
        new_fly = current_fly + delta;
        if new_fly >= 1 && new_fly <= n_flies
            current_fly = new_fly;
            draw_fly();
        end
    end

    function key_press_cb(~, evt)
        switch evt.Key
            case 'rightarrow'
                step_fly(1);
            case 'leftarrow'
                step_fly(-1);
        end
    end

    function edit_fly_cb(src, ~)
        val = round(str2double(get(src, 'String')));
        if ~isnan(val) && val >= 1 && val <= n_flies
            current_fly = val;
            draw_fly();
        else
            set(src, 'String', num2str(current_fly));
        end
    end

end
