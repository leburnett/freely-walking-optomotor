%% AV_THRESHOLD_GUI - Interactive GUI for exploring AV threshold on trajectories
%
% Layout:
%   Top row:  AV-coloured trajectory (left) | Heading playback (right)
%   Middle:   |AV| timeseries (full width)
%   Bottom:   Sliders (AV threshold, t_window, time) + navigation buttons
%
% AV is computed from Gaussian-smoothed heading using vel_estimate() with
% the 'line_fit' method. The Gaussian matches the smoothing applied to x,y
% in the pipeline, so AV peaks align with trajectory curves. The t_window
% slider controls the vel_estimate window (default 4, since the Gaussian
% has already done most of the smoothing).
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

% Load unwrapped heading (degrees). We'll apply gaussian_conv to match the
% smoothing applied to x,y in the pipeline, then compute AV from that.
data_types = {'x_data', 'y_data', 'dist_data', 'heading_data'};
[rep_data, n_flies] = load_per_rep_data(DATA, control_strain, sex, key_condition, data_types);

% Use half 1 only
h1_range = STIM_ON:STIM_MID;
x_all       = rep_data.x_data(:, h1_range);
y_all       = rep_data.y_data(:, h1_range);
heading_all = rep_data.heading_data(:, h1_range);  % unwrapped, degrees

% Apply the SAME gaussian_conv smoothing to heading that was applied to x,y
% in the pipeline. This brings AV into temporal alignment with the smoothed
% trajectory positions. We smooth the unwrapped heading (continuous signal,
% no wrapping issues), then convert to radians for vel_estimate.
heading_smooth_deg = NaN(size(heading_all));
for fi = 1:n_flies
    heading_smooth_deg(fi,:) = gaussian_conv(heading_all(fi,:));
end
heading_smooth_rad = deg2rad(heading_smooth_deg);

n_total_frames = size(x_all, 2);
MIN_GAP = 15;

% Precompute AV with a small t_window — the Gaussian has already done
% most of the smoothing, so vel_estimate just needs to take the derivative.
DEFAULT_TWIN = 4;
fprintf('Precomputing AV (Gaussian-smoothed heading, t_window=%d) for %d flies...', DEFAULT_TWIN, n_flies);
av_all = NaN(n_flies, n_total_frames);
samp_rate = 1/FPS;
for fi = 1:n_flies
    av_rad = vel_estimate(heading_smooth_rad(fi,:), samp_rate, 'line_fit', DEFAULT_TWIN, []);
    av_all(fi,:) = abs(rad2deg(av_rad));
end
fprintf(' done.\n');

%% Build the GUI

fig = uifigure('Name', 'AV Threshold Explorer', 'Position', [30 30 1300 900]);

% ===================== TOP ROW: two trajectory plots side by side =====================
traj_w = 420;
traj_h = 420;
traj_y = 430;

% Top-left: AV-coloured trajectory
ax_traj = uiaxes(fig, 'Position', [40 traj_y traj_w traj_h]);
hold(ax_traj, 'on'); axis(ax_traj, 'equal');
set(ax_traj, 'FontSize', 11, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
xlabel(ax_traj, 'x (mm)', 'FontSize', 12);
ylabel(ax_traj, 'y (mm)', 'FontSize', 12);

% Top-right: Heading playback trajectory
ax_play = uiaxes(fig, 'Position', [40 + traj_w + 40, traj_y, traj_w, traj_h]);
hold(ax_play, 'on'); axis(ax_play, 'equal');
set(ax_play, 'FontSize', 11, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
xlabel(ax_play, 'x (mm)', 'FontSize', 12);
ylabel(ax_play, 'y (mm)', 'FontSize', 12);

% Link the two trajectory axes so zooming one updates the other
linkaxes([ax_traj, ax_play], 'xy');

% ===================== MIDDLE: AV timeseries (full width) =====================
ts_left = 40;
ts_width = 2*traj_w + 40;
ts_height = 200;
ts_y = 200;

ax_av = uiaxes(fig, 'Position', [ts_left ts_y ts_width ts_height]);
set(ax_av, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1);

% ===================== BOTTOM: sliders + nav =====================
% Row 1: AV threshold + t_window
row1_y = 140;
uilabel(fig, 'Position', [40 row1_y 100 22], 'Text', 'AV threshold:', ...
    'FontSize', 12, 'FontWeight', 'bold');
slider_thr = uislider(fig, 'Position', [145 row1_y+10 300 3], ...
    'Limits', [10 300], 'Value', 90, 'MajorTicks', 10:30:300);
lbl_val = uilabel(fig, 'Position', [460 row1_y 90 22], 'Text', '90 deg/s', ...
    'FontSize', 12, 'FontWeight', 'bold');

uilabel(fig, 'Position', [560 row1_y 80 22], 'Text', 't_window:', ...
    'FontSize', 12, 'FontWeight', 'bold');
slider_twin = uislider(fig, 'Position', [645 row1_y+10 300 3], ...
    'Limits', [4 60], 'Value', DEFAULT_TWIN, 'MajorTicks', 4:4:60);
lbl_twin = uilabel(fig, 'Position', [960 row1_y 180 22], ...
    'Text', sprintf('%d frames (%.0f ms)', DEFAULT_TWIN, DEFAULT_TWIN/FPS*1000), ...
    'FontSize', 12, 'FontWeight', 'bold');

% Row 2: Time slider
row2_y = 95;
uilabel(fig, 'Position', [40 row2_y 50 22], 'Text', 'Time:', ...
    'FontSize', 12, 'FontWeight', 'bold');
slider_time = uislider(fig, 'Position', [95 row2_y+10 800 3], ...
    'Limits', [1 n_total_frames], 'Value', 1, ...
    'MajorTicks', round(linspace(1, n_total_frames, 15)));
lbl_time = uilabel(fig, 'Position', [910 row2_y 180 22], 'Text', 'Frame 1', ...
    'FontSize', 12, 'FontWeight', 'bold');

% Row 3: Navigation buttons + fly label
row3_y = 40;
btn_prev = uibutton(fig, 'push', 'Text', char(9664), ...
    'Position', [40 row3_y 70 35], 'FontSize', 18);
btn_next = uibutton(fig, 'push', 'Text', char(9654), ...
    'Position', [120 row3_y 70 35], 'FontSize', 18);
lbl_fly = uilabel(fig, 'Position', [200 row3_y 250 35], 'Text', '', ...
    'FontSize', 14, 'FontWeight', 'bold');
lbl_count = uilabel(fig, 'Position', [460 row3_y 400 35], 'Text', '', ...
    'FontSize', 12);

% ===================== STATE =====================
state.fly_idx = 1;
state.av_threshold = 90;
state.t_window = DEFAULT_TWIN;
state.time_frame = 1;
state.x_all = x_all;
state.y_all = y_all;
state.heading_all = heading_all;         % unwrapped, degrees (for display + playback)
state.heading_smooth_rad = heading_smooth_rad; % Gaussian-smoothed unwrapped heading, radians (for vel_estimate)
state.av_all = av_all;                    % current |AV| for all flies
state.n_flies = n_flies;
state.n_frames = n_total_frames;
state.ARENA_CENTER = ARENA_CENTER;
state.ARENA_R = ARENA_R;
state.MIN_GAP = MIN_GAP;
state.FPS = FPS;
state.ax_traj = ax_traj;
state.ax_play = ax_play;
state.ax_av = ax_av;
state.lbl_fly = lbl_fly;
state.lbl_val = lbl_val;
state.lbl_twin = lbl_twin;
state.lbl_time = lbl_time;
state.lbl_count = lbl_count;
fig.UserData = state;

% ===================== DRAW (full redraw) =====================
    function draw(fig_handle)
        s = fig_handle.UserData;
        fi = s.fly_idx;
        thr = s.av_threshold;
        ac = s.ARENA_CENTER;
        ar = s.ARENA_R;
        mg = s.MIN_GAP;
        nf = s.n_flies;
        fps = s.FPS;
        tf = max(1, min(round(s.time_frame), s.n_frames));
        tw = s.t_window;

        x = s.x_all(fi, :);
        y = s.y_all(fi, :);
        av_raw = s.av_all(fi, :);
        heading = s.heading_all(fi, :);
        nfr = numel(x);
        t_s = (1:nfr) / fps;
        t_cursor = tf / fps;

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

        thr_col = [0.7 0.7 0.7];
        marker_col = [0.894 0.102 0.110];
        cursor_col = [0.894 0.102 0.110];

        %% ---- Top-left: AV-coloured trajectory ----
        ax1 = s.ax_traj;
        prev_xlim = xlim(ax1);
        prev_ylim = ylim(ax1);
        has_zoom = isfield(s, 'last_fly') && s.last_fly == fi;

        cla(ax1); hold(ax1, 'on');

        theta = linspace(0, 2*pi, 200);
        plot(ax1, ac(1)+ar*cos(theta), ac(2)+ar*sin(theta), '-', ...
            'Color', thr_col, 'LineWidth', 1);

        valid = ~isnan(x) & ~isnan(y) & ~isnan(av_raw);
        d_valid = diff([0, valid, 0]);
        ss = find(d_valid == 1);
        se = find(d_valid == -1) - 1;
        for si = 1:numel(ss)
            idx = ss(si):se(si);
            if numel(idx) < 2, continue; end
            patch(ax1, [x(idx) NaN], [y(idx) NaN], 0, ...
                'EdgeColor', 'interp', 'FaceColor', 'none', ...
                'CData', [av_raw(idx) NaN], 'LineWidth', 1.5);
        end

        colormap(ax1, 'parula');
        av_valid = av_raw(valid);
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

        title(ax1, sprintf('Fly %d/%d | thr=%.0f°/s | t_w=%d (%.0fms) | %d markers', ...
            fi, nf, thr, tw, tw/fps*1000, numel(marker_frames)), 'FontSize', 12);

        %% ---- Top-right: Heading playback trajectory ----
        ax2 = s.ax_play;
        cla(ax2); hold(ax2, 'on');

        plot(ax2, ac(1)+ar*cos(theta), ac(2)+ar*sin(theta), '-', ...
            'Color', thr_col, 'LineWidth', 1);
        plot(ax2, x, y, '-', 'Color', [0.8 0.8 0.8], 'LineWidth', 0.8);

        % Fly marker at current time
        if ~isnan(x(tf)) && ~isnan(y(tf))
            fx = x(tf); fy = y(tf);
            h_rad = deg2rad(heading(tf));

            % Ellipsoid body
            body_len = 3; body_wid = 1;
            ell_t = linspace(0, 2*pi, 60);
            ex = body_len * cos(ell_t);
            ey = body_wid * sin(ell_t);
            rx = ex * cos(h_rad) - ey * sin(h_rad) + fx;
            ry = ex * sin(h_rad) + ey * cos(h_rad) + fy;
            fill(ax2, rx, ry, [0.216 0.494 0.722], ...
                'EdgeColor', 'k', 'LineWidth', 1, 'FaceAlpha', 0.8);

            % Heading line
            line_len = 6;
            plot(ax2, [fx, fx + line_len*cos(h_rad)], ...
                      [fy, fy + line_len*sin(h_rad)], '-', ...
                'Color', cursor_col, 'LineWidth', 2);

            % Trail: last 30 frames
            trail_start = max(1, tf - 30);
            plot(ax2, x(trail_start:tf), y(trail_start:tf), '-', ...
                'Color', [0.216 0.494 0.722], 'LineWidth', 2);
        end

        title(ax2, sprintf('Playback — Frame %d / %d  (%.2f s)', tf, nfr, t_cursor), ...
            'FontSize', 12);

        %% ---- Middle: |AV| timeseries ----
        cla(s.ax_av); hold(s.ax_av, 'on');
        plot(s.ax_av, t_s, av_raw, '-k', 'LineWidth', 1);
        yline(s.ax_av, thr, '-', 'Color', thr_col, 'LineWidth', 1.5);

        % Shade supra-threshold regions
        above_mask = av_raw > thr;
        if any(above_mask)
            av_shade = NaN(size(av_raw));
            av_shade(above_mask) = av_raw(above_mask);
            area(s.ax_av, t_s, av_shade, 'BaseValue', 0, ...
                'FaceColor', [1 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
        end

        % Marker ticks
        if ~isempty(marker_frames)
            plot(s.ax_av, t_s(marker_frames), av_raw(marker_frames), 'v', ...
                'MarkerSize', 5, 'MarkerFaceColor', marker_col, 'MarkerEdgeColor', 'none');
        end

        % Time cursor
        xline(s.ax_av, t_cursor, '-', 'Color', cursor_col, ...
            'LineWidth', 1.5, 'Alpha', 0.8);

        xlim(s.ax_av, [t_s(1) t_s(end)]);
        set(s.ax_av, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1);
        ylabel(s.ax_av, '|AV| (°/s)', 'FontSize', 11);
        xlabel(s.ax_av, 'Time (s)', 'FontSize', 11);
        title(s.ax_av, sprintf('|Angular velocity| via vel\\_estimate (t\\_window = %d, %.0f ms)', ...
            tw, tw/fps*1000), 'FontSize', 11);

        %% ---- Labels ----
        s.last_fly = fi;
        fig_handle.UserData = s;

        s.lbl_fly.Text = sprintf('Fly %d / %d', fi, nf);
        s.lbl_val.Text = sprintf('%.0f deg/s', thr);
        s.lbl_twin.Text = sprintf('%d frames (%.0f ms)', tw, tw/fps*1000);
        s.lbl_time.Text = sprintf('Frame %d (%.2fs)', tf, t_cursor);
        s.lbl_count.Text = sprintf('%d supra-threshold markers', numel(marker_frames));
    end

% ===================== TIME-ONLY UPDATE =====================
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

        title(ax2, sprintf('Playback — Frame %d / %d  (%.2f s)', tf, nfr, t_cursor), ...
            'FontSize', 12);

        % Update cursor on AV timeseries (delete old, add new)
        old = findobj(s.ax_av, 'Tag', 'time_cursor');
        delete(old);
        xline(s.ax_av, t_cursor, '-', 'Color', cursor_col, ...
            'LineWidth', 1.5, 'Alpha', 0.8, 'Tag', 'time_cursor');

        s.lbl_time.Text = sprintf('Frame %d (%.2fs)', tf, t_cursor);
    end

% ===================== RECOMPUTE AV =====================
    function recompute_av(fig_handle)
        s = fig_handle.UserData;
        tw = s.t_window;
        sr = 1 / s.FPS;
        nf = s.n_flies;

        fprintf('Recomputing AV (Gaussian-smoothed heading, t_window=%d) for %d flies...', tw, nf);
        new_av = NaN(nf, s.n_frames);
        for f = 1:nf
            av_rad = vel_estimate(s.heading_smooth_rad(f,:), sr, 'line_fit', tw, []);
            new_av(f,:) = abs(rad2deg(av_rad));
        end
        fprintf(' done.\n');

        s.av_all = new_av;
        fig_handle.UserData = s;
    end

% ===================== CALLBACKS =====================
slider_thr.ValueChangedFcn = @(src, ~) cb_thr(src, fig);
slider_twin.ValueChangedFcn = @(src, ~) cb_twin(src, fig);
slider_time.ValueChangedFcn = @(src, ~) cb_time(src, fig);
btn_prev.ButtonPushedFcn = @(~, ~) cb_prev(fig);
btn_next.ButtonPushedFcn = @(~, ~) cb_next(fig);

    function cb_thr(src, fh)
        fh.UserData.av_threshold = round(src.Value);
        draw(fh);
    end

    function cb_twin(src, fh)
        val = round(src.Value);
        % Force even for symmetric padding in vel_estimate
        if mod(val, 2) ~= 0, val = val + 1; end
        val = max(val, 4);
        src.Value = val;
        fh.UserData.t_window = val;
        recompute_av(fh);
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
fprintf('  AV threshold — controls markers + shading on |AV| panel\n');
fprintf('  t_window — recomputes AV via vel_estimate for ALL flies (takes a few seconds)\n');
fprintf('  Time — moves fly marker on playback panel + cursor on timeseries\n');
fprintf('  Arrow buttons — cycle through flies\n');
fprintf('  Note: changing t_window recomputes AV for all %d flies, so expect a brief pause.\n', n_flies);
