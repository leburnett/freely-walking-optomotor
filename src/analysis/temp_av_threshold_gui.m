%% TEMP_AV_THRESHOLD_GUI - Interactive GUI for exploring AV threshold on trajectories
%
% Left column:
%   Top    — trajectory coloured by pipeline |AV| with threshold markers
%   Bottom — grey trajectory with ellipsoid fly marker + heading line
%            controlled by a time slider
%
% Right column (top to bottom):
%   1. |AV| (pipeline)      — with threshold line + supra-threshold shading
%   2. d|AV|/dt             — rate of change of angular velocity
%   3. Heading (unwrapped)  — raw heading in degrees
%   4. dHeading/dt          — frame-to-frame heading change (signed)
%   5. Forward velocity     — mm/s
%
% All timeseries panels show a vertical cursor at the time slider position.
%
% Sliders: AV threshold, lag shift, time position
% Buttons: prev/next fly
%
% Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 27).

%% Setup — load data

if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

PPM = 4.1691;
ARENA_CENTER = [528, 520] / PPM;
ARENA_R = 120;
FPS = 30;

control_strain = "jfrc100_es_shibire_kir";
key_condition = 1;
sex = 'F';

STIM_ON  = 300;
STIM_MID = 750;

data_types = {'x_data', 'y_data', 'dist_data', 'av_data', 'heading_data'};
[rep_data, n_flies] = load_per_rep_data(DATA, control_strain, sex, key_condition, data_types);

% Use half 1 only
h1_range = STIM_ON:STIM_MID;
x_all       = rep_data.x_data(:, h1_range);
y_all       = rep_data.y_data(:, h1_range);
av_all      = abs(rep_data.av_data(:, h1_range));
heading_all = rep_data.heading_data(:, h1_range);

n_total_frames = size(x_all, 2);
MIN_GAP = 15;

%% Build the GUI

fig = uifigure('Name', 'AV Threshold Explorer', 'Position', [30 30 1400 1000]);

% ===================== LEFT COLUMN =====================
left_w = 480;

% Top-left: AV-coloured trajectory
ax_traj = uiaxes(fig, 'Position', [40 530 left_w left_w]);
hold(ax_traj, 'on'); axis(ax_traj, 'equal');
set(ax_traj, 'FontSize', 11, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
xlabel(ax_traj, 'x (mm)', 'FontSize', 12);
ylabel(ax_traj, 'y (mm)', 'FontSize', 12);

% Bottom-left: Heading playback trajectory
ax_play = uiaxes(fig, 'Position', [40 130 left_w 360]);
hold(ax_play, 'on'); axis(ax_play, 'equal');
set(ax_play, 'FontSize', 11, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
xlabel(ax_play, 'x (mm)', 'FontSize', 12);
ylabel(ax_play, 'y (mm)', 'FontSize', 12);

% Link the two trajectory axes so zooming one updates the other
linkaxes([ax_traj, ax_play], 'xy');

% Time slider (below playback trajectory)
uilabel(fig, 'Position', [40 98 60 22], 'Text', 'Time:', ...
    'FontSize', 13, 'FontWeight', 'bold');
slider_time = uislider(fig, 'Position', [100 108 380 3], ...
    'Limits', [1 n_total_frames], 'Value', 1, ...
    'MajorTicks', round(linspace(1, n_total_frames, 10)));
lbl_time = uilabel(fig, 'Position', [490 98 120 22], 'Text', 'Frame 1', ...
    'FontSize', 12, 'FontWeight', 'bold');

% ===================== RIGHT COLUMN =====================
ts_left = 570;
ts_width = 790;
ts_height = 180;
ts_gap = 15;

% 4 panels stacked top-to-bottom, top panel starts near top of figure
ts_top = 900;  % top of the topmost panel

% Panel 1: |AV|
ax_av = uiaxes(fig, 'Position', [ts_left, ts_top - 1*ts_height - 0*ts_gap, ts_width, ts_height]);
set(ax_av, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1);

% Panel 2: d|AV|/dt
ax_dav = uiaxes(fig, 'Position', [ts_left, ts_top - 2*ts_height - 1*ts_gap, ts_width, ts_height]);
set(ax_dav, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1);

% Panel 3: Heading (unwrapped)
ax_hdg = uiaxes(fig, 'Position', [ts_left, ts_top - 3*ts_height - 2*ts_gap, ts_width, ts_height]);
set(ax_hdg, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1);

% Panel 4: dHeading/dt
ax_dh = uiaxes(fig, 'Position', [ts_left, ts_top - 4*ts_height - 3*ts_gap, ts_width, ts_height]);
set(ax_dh, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1);

% ===================== BOTTOM CONTROLS =====================
ctrl_y = 30;

% AV threshold
uilabel(fig, 'Position', [40 ctrl_y+35 100 22], 'Text', 'AV threshold:', ...
    'FontSize', 12, 'FontWeight', 'bold');
slider_thr = uislider(fig, 'Position', [145 ctrl_y+45 350 3], ...
    'Limits', [10 300], 'Value', 90, 'MajorTicks', 10:30:300);
lbl_val = uilabel(fig, 'Position', [510 ctrl_y+35 90 22], 'Text', '90 deg/s', ...
    'FontSize', 12, 'FontWeight', 'bold');

% Lag shift
uilabel(fig, 'Position', [620 ctrl_y+35 90 22], 'Text', 'AV lag:', ...
    'FontSize', 12, 'FontWeight', 'bold');
slider_lag = uislider(fig, 'Position', [715 ctrl_y+45 300 3], ...
    'Limits', [-30 30], 'Value', 0, 'MajorTicks', -30:10:30);
lbl_lag = uilabel(fig, 'Position', [1030 ctrl_y+35 140 22], 'Text', '0 frames', ...
    'FontSize', 12, 'FontWeight', 'bold');

% Navigation
btn_prev = uibutton(fig, 'push', 'Text', char(9664), ...
    'Position', [40 ctrl_y-10 70 35], 'FontSize', 18);
btn_next = uibutton(fig, 'push', 'Text', char(9654), ...
    'Position', [120 ctrl_y-10 70 35], 'FontSize', 18);
lbl_fly = uilabel(fig, 'Position', [200 ctrl_y-10 250 35], 'Text', '', ...
    'FontSize', 14, 'FontWeight', 'bold');
lbl_count = uilabel(fig, 'Position', [460 ctrl_y-10 300 35], 'Text', '', ...
    'FontSize', 12);

% ===================== STATE =====================
state.fly_idx = 1;
state.av_threshold = 90;
state.lag_shift = 0;
state.time_frame = 1;
state.x_all = x_all;
state.y_all = y_all;
state.av_all = av_all;
state.heading_all = heading_all;
state.n_flies = n_flies;
state.n_frames = n_total_frames;
state.ARENA_CENTER = ARENA_CENTER;
state.ARENA_R = ARENA_R;
state.MIN_GAP = MIN_GAP;
state.FPS = FPS;
state.ax_traj = ax_traj;
state.ax_play = ax_play;
state.ax_av = ax_av;
state.ax_dav = ax_dav;
state.ax_hdg = ax_hdg;
state.ax_dh = ax_dh;
state.lbl_fly = lbl_fly;
state.lbl_val = lbl_val;
state.lbl_lag = lbl_lag;
state.lbl_time = lbl_time;
state.lbl_count = lbl_count;
fig.UserData = state;

% ===================== DRAW =====================
    function draw(fig_handle)
        s = fig_handle.UserData;
        fi = s.fly_idx;
        thr = s.av_threshold;
        ac = s.ARENA_CENTER;
        ar = s.ARENA_R;
        mg = s.MIN_GAP;
        nf = s.n_flies;
        lag = s.lag_shift;
        fps = s.FPS;
        tf = max(1, min(round(s.time_frame), s.n_frames));

        x = s.x_all(fi, :);
        y = s.y_all(fi, :);
        av_raw = s.av_all(fi, :);
        heading = s.heading_all(fi, :);
        nfr = numel(x);
        t_s = (1:nfr) / fps;
        t_cursor = tf / fps;

        % Lag shift for colour
        if lag > 0
            av_shifted = [av_raw(1+lag:end), NaN(1, lag)];
        elseif lag < 0
            av_shifted = [NaN(1, -lag), av_raw(1:end+lag)];
        else
            av_shifted = av_raw;
        end

        % Supra-threshold markers
        valid_raw = ~isnan(x) & ~isnan(y) & ~isnan(av_raw);
        above = find(av_raw > thr & valid_raw);
        marker_frames = [];
        if ~isempty(above)
            marker_frames = above(1);
            for k = 2:numel(above)
                if above(k) - marker_frames(end) >= mg
                    marker_frames(end+1) = above(k); %#ok<AGROW>
                end
            end
        end

        % Derived signals
        d_av = [0, diff(av_raw)] * fps;
        d_heading = [0, diff(heading)] * fps;

        thr_col = [0.7 0.7 0.7];
        marker_col = [0.894 0.102 0.110];
        cursor_col = [0.894 0.102 0.110];

        %% ---- Top-left: AV trajectory ----
        ax1 = s.ax_traj;
        prev_xlim = xlim(ax1);
        prev_ylim = ylim(ax1);
        has_zoom = isfield(s, 'last_fly') && s.last_fly == fi;

        cla(ax1); hold(ax1, 'on');

        theta = linspace(0, 2*pi, 200);
        plot(ax1, ac(1)+ar*cos(theta), ac(2)+ar*sin(theta), '-', ...
            'Color', thr_col, 'LineWidth', 1);

        valid = ~isnan(x) & ~isnan(y) & ~isnan(av_shifted);
        d_valid = diff([0, valid, 0]);
        ss = find(d_valid == 1);
        se = find(d_valid == -1) - 1;
        for si = 1:numel(ss)
            idx = ss(si):se(si);
            if numel(idx) < 2, continue; end
            patch(ax1, [x(idx) NaN], [y(idx) NaN], 0, ...
                'EdgeColor', 'interp', 'FaceColor', 'none', ...
                'CData', [av_shifted(idx) NaN], 'LineWidth', 1.5);
        end

        colormap(ax1, 'parula');
        av_valid = av_shifted(valid);
        if ~isempty(av_valid)
            clim(ax1, [0 max(prctile(av_valid, 99), 10)]);
        end
        cb = colorbar(ax1);
        cb.Label.String = '|AV| (°/s)';
        cb.Label.FontSize = 10;

        if ~isempty(marker_frames)
            plot(ax1, x(marker_frames), y(marker_frames), '^', ...
                'MarkerSize', 7, 'MarkerFaceColor', marker_col, ...
                'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
        end

        fv_idx = find(valid_raw, 1, 'first');
        lv_idx = find(valid_raw, 1, 'last');
        if ~isempty(fv_idx)
            plot(ax1, x(fv_idx), y(fv_idx), 'o', 'MarkerSize', 10, ...
                'MarkerFaceColor', [0.2 0.7 0.2], 'MarkerEdgeColor', 'none');
        end
        if ~isempty(lv_idx)
            plot(ax1, x(lv_idx), y(lv_idx), 'o', 'MarkerSize', 10, ...
                'MarkerFaceColor', [0.8 0.2 0.2], 'MarkerEdgeColor', 'none');
        end

        if has_zoom
            xlim(ax1, prev_xlim); ylim(ax1, prev_ylim);
        else
            xlim(ax1, [ac(1)-ar-5 ac(1)+ar+5]);
            ylim(ax1, [ac(2)-ar-5 ac(2)+ar+5]);
        end

        lag_ms = lag / fps * 1000;
        title(ax1, sprintf('Fly %d/%d | thr=%.0f°/s | lag=%+d (%+.0fms) | %d markers', ...
            fi, nf, thr, lag, lag_ms, numel(marker_frames)), 'FontSize', 12);

        %% ---- Bottom-left: Heading playback trajectory ----
        ax2 = s.ax_play;
        cla(ax2); hold(ax2, 'on');

        % Arena
        plot(ax2, ac(1)+ar*cos(theta), ac(2)+ar*sin(theta), '-', ...
            'Color', thr_col, 'LineWidth', 1);

        % Full trajectory in grey
        plot(ax2, x, y, '-', 'Color', [0.8 0.8 0.8], 'LineWidth', 0.8);

        % Fly marker at current time
        if ~isnan(x(tf)) && ~isnan(y(tf))
            fx = x(tf);
            fy = y(tf);
            h_deg = heading(tf);

            % Ellipsoid body (elongated along heading)
            h_rad = deg2rad(h_deg);
            body_len = 3;  % mm half-length
            body_wid = 1;  % mm half-width
            ell_t = linspace(0, 2*pi, 60);
            ex = body_len * cos(ell_t);
            ey = body_wid * sin(ell_t);
            % Rotate by heading
            rx = ex * cos(h_rad) - ey * sin(h_rad) + fx;
            ry = ex * sin(h_rad) + ey * cos(h_rad) + fy;
            fill(ax2, rx, ry, [0.216 0.494 0.722], ...
                'EdgeColor', 'k', 'LineWidth', 1, 'FaceAlpha', 0.8);

            % Heading line extending from fly
            line_len = 6;  % mm
            hx = fx + line_len * cos(h_rad);
            hy = fy + line_len * sin(h_rad);
            plot(ax2, [fx hx], [fy hy], '-', 'Color', [0.894 0.102 0.110], ...
                'LineWidth', 2);

            % Trail: last 30 frames highlighted
            trail_start = max(1, tf - 30);
            trail_idx = trail_start:tf;
            plot(ax2, x(trail_idx), y(trail_idx), '-', ...
                'Color', [0.216 0.494 0.722], 'LineWidth', 2);
        end

        % (ax_play limits linked to ax_traj via linkaxes)
        title(ax2, sprintf('Playback — Frame %d / %d  (%.2f s)', tf, nfr, t_cursor), ...
            'FontSize', 12);

        %% ---- Timeseries panels (right) ----

        % Helper: draw vertical time cursor on an axes
        draw_cursor = @(a) xline(a, t_cursor, '-', 'Color', cursor_col, ...
            'LineWidth', 1.5, 'Alpha', 0.8);

        % Panel 1: |AV|
        cla(s.ax_av); hold(s.ax_av, 'on');
        plot(s.ax_av, t_s, av_raw, '-k', 'LineWidth', 1);
        yline(s.ax_av, thr, '-', 'Color', thr_col, 'LineWidth', 1.5);
        above_mask = av_raw > thr;
        if any(above_mask)
            av_shade = NaN(size(av_raw));
            av_shade(above_mask) = av_raw(above_mask);
            area(s.ax_av, t_s, av_shade, 'BaseValue', 0, ...
                'FaceColor', [1 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
        end
        if ~isempty(marker_frames)
            plot(s.ax_av, t_s(marker_frames), av_raw(marker_frames), 'v', ...
                'MarkerSize', 5, 'MarkerFaceColor', marker_col, 'MarkerEdgeColor', 'none');
        end
        draw_cursor(s.ax_av);
        xlim(s.ax_av, [t_s(1) t_s(end)]);
        set(s.ax_av, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1);
        ylabel(s.ax_av, '|AV| (°/s)', 'FontSize', 11);
        title(s.ax_av, '|Angular velocity| (pipeline)', 'FontSize', 11);

        % Panel 2: d|AV|/dt
        cla(s.ax_dav); hold(s.ax_dav, 'on');
        plot(s.ax_dav, t_s, d_av, '-', 'Color', [0.3 0.3 0.3], 'LineWidth', 0.8);
        yline(s.ax_dav, 0, '-', 'Color', thr_col, 'LineWidth', 0.8);
        draw_cursor(s.ax_dav);
        xlim(s.ax_dav, [t_s(1) t_s(end)]);
        dav_abs = abs(d_av(~isnan(d_av)));
        if ~isempty(dav_abs)
            yl = max(prctile(dav_abs, 95), 1);
            ylim(s.ax_dav, [-yl yl]);
        end
        set(s.ax_dav, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1);
        ylabel(s.ax_dav, 'd|AV|/dt', 'FontSize', 11);
        title(s.ax_dav, 'Change in |AV|', 'FontSize', 11);

        % Panel 3: Heading (wrapped to 0-360)
        heading_wrapped = mod(heading, 360);
        cla(s.ax_hdg); hold(s.ax_hdg, 'on');
        plot(s.ax_hdg, t_s, heading_wrapped, '-', 'Color', [0.4 0.2 0.6], 'LineWidth', 1);
        draw_cursor(s.ax_hdg);
        xlim(s.ax_hdg, [t_s(1) t_s(end)]);
        ylim(s.ax_hdg, [0 360]);
        set(s.ax_hdg, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1);
        ylabel(s.ax_hdg, 'Heading (°)', 'FontSize', 11);
        title(s.ax_hdg, 'Heading (wrapped 0–360°)', 'FontSize', 11);

        % Panel 4: dHeading/dt (raw signed)
        cla(s.ax_dh); hold(s.ax_dh, 'on');
        plot(s.ax_dh, t_s, d_heading, '-', 'Color', [0.2 0.4 0.7], 'LineWidth', 0.8);
        yline(s.ax_dh, 0, '-', 'Color', thr_col, 'LineWidth', 0.8);
        draw_cursor(s.ax_dh);
        xlim(s.ax_dh, [t_s(1) t_s(end)]);
        dh_abs = abs(d_heading(~isnan(d_heading)));
        if ~isempty(dh_abs)
            yl = max(prctile(dh_abs, 95), 1);
            ylim(s.ax_dh, [-yl yl]);
        end
        set(s.ax_dh, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1);
        ylabel(s.ax_dh, 'dH/dt (°/s)', 'FontSize', 11);
        title(s.ax_dh, 'Change in heading (raw, signed)', 'FontSize', 11);

        % Add x-axis label to the bottom timeseries panel
        xlabel(s.ax_dh, 'Time (s)', 'FontSize', 11);

        %% ---- Labels ----
        s.last_fly = fi;
        fig_handle.UserData = s;

        s.lbl_fly.Text = sprintf('Fly %d / %d', fi, nf);
        s.lbl_val.Text = sprintf('%.0f deg/s', thr);
        s.lbl_lag.Text = sprintf('%+d frames (%+.0f ms)', lag, lag_ms);
        s.lbl_time.Text = sprintf('Frame %d (%.2fs)', tf, t_cursor);
        s.lbl_count.Text = sprintf('%d supra-threshold markers', numel(marker_frames));
    end

% ===================== TIME-ONLY UPDATE =====================
% Lightweight redraw: only updates the playback trajectory + cursors
% without redrawing the full AV trajectory and timeseries data.
    function draw_time_only(fig_handle)
        s = fig_handle.UserData;
        fi = s.fly_idx;
        ac = s.ARENA_CENTER;
        ar = s.ARENA_R;
        fps = s.FPS;
        tf = max(1, min(round(s.time_frame), s.n_frames));

        x = s.x_all(fi, :);
        y = s.y_all(fi, :);
        heading = s.heading_all(fi, :);
        nfr = numel(x);
        t_cursor = tf / fps;

        thr_col = [0.7 0.7 0.7];
        cursor_col = [0.894 0.102 0.110];

        % Redraw playback panel
        ax2 = s.ax_play;
        cla(ax2); hold(ax2, 'on');
        theta = linspace(0, 2*pi, 200);
        plot(ax2, ac(1)+ar*cos(theta), ac(2)+ar*sin(theta), '-', ...
            'Color', thr_col, 'LineWidth', 1);
        plot(ax2, x, y, '-', 'Color', [0.8 0.8 0.8], 'LineWidth', 0.8);

        if ~isnan(x(tf)) && ~isnan(y(tf))
            fx = x(tf); fy = y(tf);
            h_rad = deg2rad(heading(tf));

            body_len = 3; body_wid = 1;
            ell_t = linspace(0, 2*pi, 60);
            ex = body_len * cos(ell_t);
            ey = body_wid * sin(ell_t);
            rx = ex * cos(h_rad) - ey * sin(h_rad) + fx;
            ry = ex * sin(h_rad) + ey * cos(h_rad) + fy;
            fill(ax2, rx, ry, [0.216 0.494 0.722], ...
                'EdgeColor', 'k', 'LineWidth', 1, 'FaceAlpha', 0.8);

            line_len = 6;
            plot(ax2, [fx, fx + line_len*cos(h_rad)], ...
                      [fy, fy + line_len*sin(h_rad)], '-', ...
                'Color', cursor_col, 'LineWidth', 2);

            trail_start = max(1, tf - 30);
            plot(ax2, x(trail_start:tf), y(trail_start:tf), '-', ...
                'Color', [0.216 0.494 0.722], 'LineWidth', 2);
        end

        % (ax_play limits linked to ax_traj via linkaxes)
        title(ax2, sprintf('Playback — Frame %d / %d  (%.2f s)', tf, nfr, t_cursor), ...
            'FontSize', 12);

        % Update cursors on timeseries (delete old, add new)
        ts_axes = [s.ax_av, s.ax_dav, s.ax_hdg, s.ax_dh];
        for ai = 1:numel(ts_axes)
            % Remove old cursor lines (tagged)
            old = findobj(ts_axes(ai), 'Tag', 'time_cursor');
            delete(old);
            xline(ts_axes(ai), t_cursor, '-', 'Color', cursor_col, ...
                'LineWidth', 1.5, 'Alpha', 0.8, 'Tag', 'time_cursor');
        end

        s.lbl_time.Text = sprintf('Frame %d (%.2fs)', tf, t_cursor);
    end

% ===================== CALLBACKS =====================
slider_thr.ValueChangedFcn = @(src, ~) cb_thr(src, fig);
slider_lag.ValueChangedFcn = @(src, ~) cb_lag(src, fig);
slider_time.ValueChangedFcn = @(src, ~) cb_time(src, fig);
btn_prev.ButtonPushedFcn = @(~, ~) cb_prev(fig);
btn_next.ButtonPushedFcn = @(~, ~) cb_next(fig);

    function cb_thr(src, fh)
        fh.UserData.av_threshold = round(src.Value);
        draw(fh);
    end

    function cb_lag(src, fh)
        fh.UserData.lag_shift = round(src.Value);
        draw(fh);
    end

    function cb_time(src, fh)
        fh.UserData.time_frame = round(src.Value);
        draw_time_only(fh);
    end

    function cb_prev(fh)
        s = fh.UserData;
        s.fly_idx = max(s.fly_idx - 1, 1);
        s.time_frame = 1;
        fh.UserData = s;
        draw(fh);
    end

    function cb_next(fh)
        s = fh.UserData;
        s.fly_idx = min(s.fly_idx + 1, s.n_flies);
        s.time_frame = 1;
        fh.UserData = s;
        draw(fh);
    end

% ===================== INITIAL DRAW =====================
draw(fig);

fprintf('GUI ready.\n');
fprintf('  AV threshold slider — controls markers + shading on |AV| panel\n');
fprintf('  Lag shift slider — shifts trajectory colour only\n');
fprintf('  Time slider — moves fly marker on playback panel + cursors on timeseries\n');
fprintf('  Arrow buttons — cycle through flies\n');
fprintf('  Left panels: AV-coloured trajectory (top), heading playback (bottom)\n');
fprintf('  Right panels: |AV|, d|AV|/dt, Heading, dHeading/dt\n');
