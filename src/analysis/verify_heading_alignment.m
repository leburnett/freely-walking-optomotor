function verify_heading_alignment(video_path, mat_path)
% VERIFY_HEADING_ALIGNMENT  Frame-by-frame viewer for checking FlyTracker
%   heading/position alignment on raw ufmf video.
%
%   verify_heading_alignment(VIDEO_PATH, MAT_PATH)
%   verify_heading_alignment()  % opens file dialogs
%
%   Overlays fly body ellipses, heading lines, velocity vectors, trajectory
%   tails, and fly IDs on raw ufmf video frames. Toggle between raw trx
%   (FlyTracker output) and processed comb_data to compare.
%
%   Keyboard shortcuts:
%     Left/Right arrows  - step 1 frame
%     Shift+Left/Right   - step 10 frames
%     Space              - play/pause
%     e/h/v/t/i          - toggle overlays

    %% Input handling
    if nargin < 2
        % Default test data paths
        default_video = '/Users/burnettl/Documents/Projects/oaky_cokey/data/2026_03_09/protocol_27/csw1118/F/16_29_22/REC__cam_0_date_2026_03_09_time_16_29_27_v001.ufmf';
        default_mat = '/Users/burnettl/Desktop/2026-03-09_16-29-22_csw1118_protocol_27_F_data.mat';

        if nargin < 1
            if exist(default_video, 'file') && exist(default_mat, 'file')
                video_path = default_video;
                mat_path = default_mat;
            else
                [vf, vp] = uigetfile('*.ufmf', 'Select ufmf video');
                if isequal(vf, 0), return; end
                video_path = fullfile(vp, vf);
                [mf, mp] = uigetfile('*.mat', 'Select results .mat file');
                if isequal(mf, 0), return; end
                mat_path = fullfile(mp, mf);
            end
        else
            mat_path = default_mat;
        end
    end

    %% Load data
    fprintf('Loading video: %s\n', video_path);

    % Add JAABA to path for ufmf reading
    jaaba_path = '/Users/burnettl/Documents/Non-GitHub-Repos/JAABA-master';
    if exist(jaaba_path, 'dir')
        addpath(genpath(jaaba_path));
    end

    [readframe, ~, fid, ~] = get_readframe_fcn(video_path);

    fprintf('Loading results: %s\n', mat_path);
    data = load(mat_path, 'trx', 'comb_data');
    trx = data.trx;
    comb_data = data.comb_data;

    n_flies_trx = numel(trx);
    n_flies_comb = size(comb_data.x_data, 1);
    total_frames = max([trx.endframe]);
    pxpermm = trx(1).pxpermm;
    FPS = 30;

    fprintf('Loaded: %d trx flies, %d comb_data flies, %d total frames\n', ...
        n_flies_trx, n_flies_comb, total_frames);

    %% Precompute cumulative absolute heading change for each fly
    % trx: cumulative |delta theta| in degrees, per frame
    cum_heading_trx = cell(n_flies_trx, 1);
    for fly = 1:n_flies_trx
        dth = abs(diff(unwrap(trx(fly).theta)));  % radians
        dth(isnan(dth)) = 0;  % NaN frames contribute zero turning
        cum_heading_trx{fly} = [0; cumsum(rad2deg(dth(:)))];  % degrees, same length as trx data
    end

    % comb_data: cumulative |delta heading| in degrees
    n_frames_comb = size(comb_data.heading_wrap, 2);
    cum_heading_comb = zeros(n_flies_comb, n_frames_comb);
    for fly = 1:n_flies_comb
        hdg_rad = deg2rad(comb_data.heading_wrap(fly, :));
        dth = abs(diff(unwrap(hdg_rad)));
        dth(isnan(dth)) = 0;  % NaN frames contribute zero turning
        cum_heading_comb(fly, :) = [0, cumsum(rad2deg(dth))];
    end

    %% Create figure
    fig = figure('Name', 'Heading Alignment Viewer', ...
        'NumberTitle', 'off', ...
        'Units', 'normalized', ...
        'Position', [0.05 0.05 0.6 0.85], ...
        'Color', [0.15 0.15 0.15], ...
        'KeyPressFcn', @key_press_cb, ...
        'DeleteFcn', @cleanup_cb);

    % Main axes for video
    ax = axes('Parent', fig, ...
        'Units', 'normalized', ...
        'Position', [0.02 0.22 0.96 0.76]);
    ax.Color = [0 0 0];

    % Read first frame for initial display
    im1 = readframe(1);
    h_img = imagesc(ax, im1);
    colormap(ax, gray);
    axis(ax, 'image');
    hold(ax, 'on');
    set(ax, 'XTick', [], 'YTick', []);

    %% Fly color palette
    colors_trx = hsv(n_flies_trx);
    colors_comb = hsv(n_flies_comb);

    %% Build control panel

    % Row 1: Navigation
    uicontrol(fig, 'Style', 'pushbutton', 'String', '<<', ...
        'Units', 'normalized', 'Position', [0.02 0.16 0.05 0.04], ...
        'Callback', @(~,~) step_frame(-10), ...
        'FontSize', 12, 'FontWeight', 'bold');
    uicontrol(fig, 'Style', 'pushbutton', 'String', '<', ...
        'Units', 'normalized', 'Position', [0.08 0.16 0.05 0.04], ...
        'Callback', @(~,~) step_frame(-1), ...
        'FontSize', 12, 'FontWeight', 'bold');

    uicontrol(fig, 'Style', 'text', 'String', 'Frame:', ...
        'Units', 'normalized', 'Position', [0.14 0.16 0.06 0.04], ...
        'FontSize', 11, 'BackgroundColor', [0.15 0.15 0.15], ...
        'ForegroundColor', [1 1 1], 'HorizontalAlignment', 'right');
    h_frame_edit = uicontrol(fig, 'Style', 'edit', 'String', '1', ...
        'Units', 'normalized', 'Position', [0.21 0.16 0.10 0.04], ...
        'FontSize', 11, 'Callback', @frame_edit_cb);
    h_total_label = uicontrol(fig, 'Style', 'text', ...
        'String', sprintf('/ %d', total_frames), ...
        'Units', 'normalized', 'Position', [0.32 0.16 0.08 0.04], ...
        'FontSize', 11, 'BackgroundColor', [0.15 0.15 0.15], ...
        'ForegroundColor', [1 1 1], 'HorizontalAlignment', 'left');

    uicontrol(fig, 'Style', 'pushbutton', 'String', '>', ...
        'Units', 'normalized', 'Position', [0.41 0.16 0.05 0.04], ...
        'Callback', @(~,~) step_frame(1), ...
        'FontSize', 12, 'FontWeight', 'bold');
    uicontrol(fig, 'Style', 'pushbutton', 'String', '>>', ...
        'Units', 'normalized', 'Position', [0.47 0.16 0.05 0.04], ...
        'Callback', @(~,~) step_frame(10), ...
        'FontSize', 12, 'FontWeight', 'bold');

    h_play_btn = uicontrol(fig, 'Style', 'togglebutton', 'String', 'Play', ...
        'Units', 'normalized', 'Position', [0.54 0.16 0.08 0.04], ...
        'FontSize', 11, 'Callback', @play_cb);

    h_info_label = uicontrol(fig, 'Style', 'text', 'String', '', ...
        'Units', 'normalized', 'Position', [0.64 0.16 0.34 0.04], ...
        'FontSize', 11, 'BackgroundColor', [0.15 0.15 0.15], ...
        'ForegroundColor', [0.8 0.9 1], 'HorizontalAlignment', 'left');

    % Row 2: Data source toggle
    h_bg = uibuttongroup(fig, 'Title', 'Source', ...
        'Units', 'normalized', 'Position', [0.02 0.10 0.25 0.05], ...
        'FontSize', 10, 'BackgroundColor', [0.15 0.15 0.15], ...
        'ForegroundColor', [1 1 1], ...
        'SelectionChangedFcn', @source_change_cb);
    h_radio_trx = uicontrol(h_bg, 'Style', 'radiobutton', ...
        'String', 'trx (raw)', ...
        'Units', 'normalized', 'Position', [0.02 0.1 0.48 0.8], ...
        'FontSize', 10, 'BackgroundColor', [0.15 0.15 0.15], ...
        'ForegroundColor', [1 1 1]);
    h_radio_comb = uicontrol(h_bg, 'Style', 'radiobutton', ...
        'String', 'comb_data', ...
        'Units', 'normalized', 'Position', [0.52 0.1 0.48 0.8], ...
        'FontSize', 10, 'BackgroundColor', [0.15 0.15 0.15], ...
        'ForegroundColor', [1 1 1]);
    h_bg.SelectedObject = h_radio_trx;

    % Row 3: Overlay toggles
    h_chk_ellipse = uicontrol(fig, 'Style', 'checkbox', 'String', 'Ellipses', ...
        'Value', 1, 'Units', 'normalized', 'Position', [0.02 0.04 0.10 0.04], ...
        'FontSize', 10, 'BackgroundColor', [0.15 0.15 0.15], ...
        'ForegroundColor', [1 1 1], 'Callback', @(~,~) draw_frame());
    h_chk_heading = uicontrol(fig, 'Style', 'checkbox', 'String', 'Heading', ...
        'Value', 1, 'Units', 'normalized', 'Position', [0.13 0.04 0.10 0.04], ...
        'FontSize', 10, 'BackgroundColor', [0.15 0.15 0.15], ...
        'ForegroundColor', [1 1 1], 'Callback', @(~,~) draw_frame());
    h_chk_velocity = uicontrol(fig, 'Style', 'checkbox', 'String', 'Velocity', ...
        'Value', 1, 'Units', 'normalized', 'Position', [0.24 0.04 0.10 0.04], ...
        'FontSize', 10, 'BackgroundColor', [0.15 0.15 0.15], ...
        'ForegroundColor', [1 1 1], 'Callback', @(~,~) draw_frame());
    h_chk_trails = uicontrol(fig, 'Style', 'checkbox', 'String', 'Trails', ...
        'Value', 1, 'Units', 'normalized', 'Position', [0.35 0.04 0.10 0.04], ...
        'FontSize', 10, 'BackgroundColor', [0.15 0.15 0.15], ...
        'ForegroundColor', [1 1 1], 'Callback', @(~,~) draw_frame());
    h_chk_ids = uicontrol(fig, 'Style', 'checkbox', 'String', 'Fly IDs', ...
        'Value', 1, 'Units', 'normalized', 'Position', [0.46 0.04 0.10 0.04], ...
        'FontSize', 10, 'BackgroundColor', [0.15 0.15 0.15], ...
        'ForegroundColor', [1 1 1], 'Callback', @(~,~) draw_frame());
    h_chk_gauge = uicontrol(fig, 'Style', 'checkbox', 'String', 'Turn gauge', ...
        'Value', 1, 'Units', 'normalized', 'Position', [0.57 0.04 0.11 0.04], ...
        'FontSize', 10, 'BackgroundColor', [0.15 0.15 0.15], ...
        'ForegroundColor', [1 1 1], 'Callback', @(~,~) draw_frame());

    uicontrol(fig, 'Style', 'pushbutton', 'String', 'Reset gauge', ...
        'Units', 'normalized', 'Position', [0.69 0.04 0.09 0.04], ...
        'FontSize', 10, 'Callback', @reset_gauge_cb);

    uicontrol(fig, 'Style', 'text', 'String', 'Trail frames:', ...
        'Units', 'normalized', 'Position', [0.79 0.04 0.10 0.04], ...
        'FontSize', 10, 'BackgroundColor', [0.15 0.15 0.15], ...
        'ForegroundColor', [1 1 1], 'HorizontalAlignment', 'right');
    h_trail_edit = uicontrol(fig, 'Style', 'edit', 'String', '30', ...
        'Units', 'normalized', 'Position', [0.90 0.04 0.06 0.04], ...
        'FontSize', 10, 'Callback', @(~,~) draw_frame());

    % Legend label
    uicontrol(fig, 'Style', 'text', ...
        'String', 'Solid = heading | Dashed red = velocity | Pie = cumulative turn (resets each 360)', ...
        'Units', 'normalized', 'Position', [0.30 0.10 0.68 0.04], ...
        'FontSize', 10, 'BackgroundColor', [0.15 0.15 0.15], ...
        'ForegroundColor', [0.7 0.7 0.7], 'HorizontalAlignment', 'left');

    %% State
    current_frame = 1;
    overlay_handles = [];
    use_trx = true;  % true = trx, false = comb_data
    timer_obj = [];
    gauge_reset_frame = 1;  % frame from which cumulative heading is measured

    %% Initial draw
    draw_frame();

    %% --- Nested functions ---

    function draw_frame()
        % Read video frame
        try
            im = readframe(current_frame);
        catch
            return;
        end
        set(h_img, 'CData', im);

        % Delete old overlays
        if ~isempty(overlay_handles)
            delete(overlay_handles(isvalid(overlay_handles)));
        end
        overlay_handles = gobjects(0);

        % Get toggle states
        show_ellipses = h_chk_ellipse.Value;
        show_heading  = h_chk_heading.Value;
        show_velocity = h_chk_velocity.Value;
        show_trails   = h_chk_trails.Value;
        show_ids      = h_chk_ids.Value;
        show_gauge    = h_chk_gauge.Value;
        trail_length  = str2double(h_trail_edit.String);
        if isnan(trail_length) || trail_length < 1
            trail_length = 30;
        end

        n_visible = 0;

        if use_trx
            % --- trx mode: pixel coords ---
            for fly = 1:n_flies_trx
                if current_frame < trx(fly).firstframe || current_frame > trx(fly).endframe
                    continue;
                end
                fi = current_frame + trx(fly).off;
                cx = trx(fly).x(fi);
                cy = trx(fly).y(fi);
                if isnan(cx) || isnan(cy), continue; end

                th = trx(fly).theta(fi);
                sa = trx(fly).a(fi);
                sb = trx(fly).b(fi);
                col = colors_trx(fly, :);
                n_visible = n_visible + 1;

                % Ellipse
                if show_ellipses
                    t_e = linspace(0, 2*pi, 60);
                    ex = sa * cos(t_e);
                    ey = sb * sin(t_e);
                    rx = ex * cos(th) - ey * sin(th) + cx;
                    ry = ex * sin(th) + ey * cos(th) + cy;
                    h_ov = plot(ax, rx, ry, '-', 'Color', col, 'LineWidth', 1.5);
                    overlay_handles(end+1) = h_ov;
                end

                % Heading line
                if show_heading
                    line_len = 2.5 * sa;
                    hx = [cx, cx + line_len * cos(th)];
                    hy = [cy, cy + line_len * sin(th)];
                    h_ov = plot(ax, hx, hy, '-', 'Color', col, 'LineWidth', 2);
                    overlay_handles(end+1) = h_ov;
                end

                % Velocity vector
                if show_velocity && fi > 1
                    dx = trx(fly).x(fi) - trx(fly).x(fi-1);
                    dy = trx(fly).y(fi) - trx(fly).y(fi-1);
                    vel_angle = atan2(dy, dx);
                    vel_mag = sqrt(dx^2 + dy^2);
                    vel_len = max(vel_mag * 3, 5);
                    h_ov = plot(ax, [cx, cx + vel_len * cos(vel_angle)], ...
                        [cy, cy + vel_len * sin(vel_angle)], ...
                        '--', 'Color', [1 0.3 0.3], 'LineWidth', 1.5);
                    overlay_handles(end+1) = h_ov;
                end

                % Trail
                if show_trails
                    trail_start = max(1, fi - trail_length);
                    tx = trx(fly).x(trail_start:fi);
                    ty = trx(fly).y(trail_start:fi);
                    h_ov = plot(ax, tx, ty, '-', 'Color', [col 0.4], 'LineWidth', 1);
                    overlay_handles(end+1) = h_ov;
                end

                % Fly ID
                if show_ids
                    h_ov = text(ax, cx + sa + 3, cy - sb - 3, sprintf('%d', fly), ...
                        'Color', col, 'FontSize', 9, 'FontWeight', 'bold');
                    overlay_handles(end+1) = h_ov;
                end

                % Cumulative turning gauge
                if show_gauge
                    reset_fi = max(1, min(gauge_reset_frame + trx(fly).off, numel(cum_heading_trx{fly})));
                    cum_deg = cum_heading_trx{fly}(fi) - cum_heading_trx{fly}(reset_fi);
                    frac = mod(cum_deg, 360) / 360;  % 0-1 fill fraction
                    gauge_r = 8;  % radius in pixels
                    gauge_cx = cx + sa + 18;
                    gauge_cy = cy - sb - 3;
                    overlay_handles = draw_pie_gauge(ax, gauge_cx, gauge_cy, ...
                        gauge_r, frac, col, overlay_handles);
                end
            end
            source_str = 'trx (raw)';

        else
            % --- comb_data mode: mm coords converted to pixels ---
            for fly = 1:n_flies_comb
                if current_frame > size(comb_data.x_data, 2), continue; end
                x_mm = comb_data.x_data(fly, current_frame);
                y_mm = comb_data.y_data(fly, current_frame);
                if isnan(x_mm) || isnan(y_mm), continue; end

                cx = x_mm * pxpermm;
                cy = y_mm * pxpermm;
                hdg_deg = comb_data.heading_wrap(fly, current_frame);
                th = deg2rad(hdg_deg);
                sa = 10;  % fixed circle radius in pixels
                sb = 10;
                col = colors_comb(fly, :);
                n_visible = n_visible + 1;

                % Circle (no a/b in comb_data)
                if show_ellipses
                    t_e = linspace(0, 2*pi, 60);
                    rx = sa * cos(t_e) + cx;
                    ry = sb * sin(t_e) + cy;
                    h_ov = plot(ax, rx, ry, '-', 'Color', col, 'LineWidth', 1.5);
                    overlay_handles(end+1) = h_ov;
                end

                % Heading line
                if show_heading
                    line_len = 25;
                    hx = [cx, cx + line_len * cos(th)];
                    hy = [cy, cy + line_len * sin(th)];
                    h_ov = plot(ax, hx, hy, '-', 'Color', col, 'LineWidth', 2);
                    overlay_handles(end+1) = h_ov;
                end

                % Velocity vector
                if show_velocity && current_frame > 1
                    x_prev = comb_data.x_data(fly, current_frame-1) * pxpermm;
                    y_prev = comb_data.y_data(fly, current_frame-1) * pxpermm;
                    if ~isnan(x_prev) && ~isnan(y_prev)
                        dx = cx - x_prev;
                        dy = cy - y_prev;
                        vel_angle = atan2(dy, dx);
                        vel_mag = sqrt(dx^2 + dy^2);
                        vel_len = max(vel_mag * 3, 5);
                        h_ov = plot(ax, [cx, cx + vel_len * cos(vel_angle)], ...
                            [cy, cy + vel_len * sin(vel_angle)], ...
                            '--', 'Color', [1 0.3 0.3], 'LineWidth', 1.5);
                        overlay_handles(end+1) = h_ov;
                    end
                end

                % Trail
                if show_trails
                    t_start = max(1, current_frame - trail_length);
                    tx = comb_data.x_data(fly, t_start:current_frame) * pxpermm;
                    ty = comb_data.y_data(fly, t_start:current_frame) * pxpermm;
                    h_ov = plot(ax, tx, ty, '-', 'Color', [col 0.4], 'LineWidth', 1);
                    overlay_handles(end+1) = h_ov;
                end

                % Fly ID
                if show_ids
                    h_ov = text(ax, cx + 12, cy - 12, sprintf('%d', fly), ...
                        'Color', col, 'FontSize', 9, 'FontWeight', 'bold');
                    overlay_handles(end+1) = h_ov;
                end

                % Cumulative turning gauge
                if show_gauge
                    reset_col = max(1, min(gauge_reset_frame, n_frames_comb));
                    cum_deg = cum_heading_comb(fly, current_frame) - cum_heading_comb(fly, reset_col);
                    frac = mod(cum_deg, 360) / 360;
                    gauge_r = 8;
                    gauge_cx = cx + 26;
                    gauge_cy = cy - 12;
                    overlay_handles = draw_pie_gauge(ax, gauge_cx, gauge_cy, ...
                        gauge_r, frac, col, overlay_handles);
                end
            end
            source_str = 'comb\_data';
        end

        % Update UI labels
        set(h_frame_edit, 'String', num2str(current_frame));
        set(h_info_label, 'String', sprintf('Time: %.2fs  |  %d flies visible  |  Source: %s', ...
            current_frame / FPS, n_visible, source_str));

        if ~isempty(timer_obj) && isvalid(timer_obj) && strcmp(timer_obj.Running, 'on')
            drawnow limitrate;
        else
            drawnow;
        end
    end

    function step_frame(delta)
        current_frame = max(1, min(total_frames, current_frame + delta));
        draw_frame();
    end

    function frame_edit_cb(src, ~)
        val = round(str2double(src.String));
        if isnan(val), return; end
        current_frame = max(1, min(total_frames, val));
        draw_frame();
    end

    function key_press_cb(~, evt)
        shift = any(strcmp(evt.Modifier, 'shift'));
        switch evt.Key
            case 'rightarrow'
                if shift, step_frame(10); else, step_frame(1); end
            case 'leftarrow'
                if shift, step_frame(-10); else, step_frame(-1); end
            case 'space'
                h_play_btn.Value = ~h_play_btn.Value;
                play_cb(h_play_btn, []);
            case 'e'
                h_chk_ellipse.Value = ~h_chk_ellipse.Value;
                draw_frame();
            case 'h'
                h_chk_heading.Value = ~h_chk_heading.Value;
                draw_frame();
            case 'v'
                h_chk_velocity.Value = ~h_chk_velocity.Value;
                draw_frame();
            case 't'
                h_chk_trails.Value = ~h_chk_trails.Value;
                draw_frame();
            case 'i'
                h_chk_ids.Value = ~h_chk_ids.Value;
                draw_frame();
            case 'g'
                h_chk_gauge.Value = ~h_chk_gauge.Value;
                draw_frame();
            case 'r'
                reset_gauge_cb([], []);
        end
    end

    function source_change_cb(~, evt)
        use_trx = (evt.NewValue == h_radio_trx);
        draw_frame();
    end

    function play_cb(src, ~)
        if src.Value
            src.String = 'Pause';
            timer_obj = timer('ExecutionMode', 'fixedRate', ...
                'Period', round(1/FPS, 3), ...
                'TimerFcn', @(~,~) advance_playback());
            start(timer_obj);
        else
            src.String = 'Play';
            if ~isempty(timer_obj) && isvalid(timer_obj)
                stop(timer_obj);
                delete(timer_obj);
                timer_obj = [];
            end
        end
    end

    function advance_playback()
        if current_frame >= total_frames
            h_play_btn.Value = 0;
            play_cb(h_play_btn, []);
            return;
        end
        current_frame = current_frame + 1;
        draw_frame();
    end

    function reset_gauge_cb(~, ~)
        gauge_reset_frame = current_frame;
        fprintf('Gauge reset at frame %d (%.2fs)\n', current_frame, current_frame/FPS);
        draw_frame();
    end

    function handles = draw_pie_gauge(target_ax, cx, cy, r, frac, col, handles)
        % Draw a pie-chart gauge: open circle outline + filled wedge.
        % frac = 0..1 (fraction of 360 degrees filled).
        n_pts = 40;

        % Open circle outline
        t_c = linspace(0, 2*pi, 60);
        h_ov = plot(target_ax, cx + r*cos(t_c), cy + r*sin(t_c), ...
            '-', 'Color', col, 'LineWidth', 1);
        handles(end+1) = h_ov;

        % Filled wedge (if any turning accumulated)
        if frac > 0.005
            arc_angle = frac * 2 * pi;
            t_arc = linspace(-pi/2, -pi/2 + arc_angle, n_pts);  % start from top
            wedge_x = [cx, cx + r*cos(t_arc), cx];
            wedge_y = [cy, cy + r*sin(t_arc), cy];
            h_ov = fill(target_ax, wedge_x, wedge_y, col, ...
                'EdgeColor', 'none', 'FaceAlpha', 0.7);
            handles(end+1) = h_ov;
        end
    end

    function cleanup_cb(~, ~)
        if ~isempty(timer_obj) && isvalid(timer_obj)
            stop(timer_obj);
            delete(timer_obj);
        end
        try
            fclose(fid);
        catch
        end
    end

end
