%% LOOP_SEGMENTATION_GUI - Trajectory segmentation with two methods
%
%  Two segmentation modes (selectable via dropdown):
%    "Self-intersection" — finds self-intersection loops using
%       find_trajectory_loops (the original method)
%    "View dist peaks"   — segments the trajectory between peaks in the
%       view_dist signal (distance to wall along heading). Peaks correspond
%       to moments when the fly is looking furthest ahead (toward the centre).
%       Each peak-to-peak segment captures one "turn cycle".
%
%  The GUI shows the trajectory with coloured segments, plus a lower axes
%  showing the view_dist timeseries with detected peaks or loop boundaries.
%
%  Controls:
%    Strain dropdown   — select strain
%    Method dropdown   — Self-intersection / View dist peaks
%    Arrow buttons     — cycle through flies
%    Smoothing slider  — controls view_dist smoothing window (peak method only)
%    Min prominence    — minimum peak prominence for findpeaks
%
%  Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 27).
%
%  See also: find_trajectory_loops, findpeaks

%% Setup

if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

PPM = 4.1691;
ARENA_CENTER = [528, 520] / PPM;
ARENA_R = 120;
FPS = 30;

key_condition = 1;
sex = 'F';

STIM_ON  = 300;
STIM_OFF = 1200;
stim_range = STIM_ON:STIM_OFF;

%% Loop detection options (self-intersection method)

loop_opts.lookahead_frames = 75;
loop_opts.min_loop_frames  = 5;
loop_opts.fps              = FPS;
loop_opts.arena_center     = ARENA_CENTER;
loop_opts.arena_radius     = ARENA_R;

%% Iterate over ALL strains — load trajectories, detect loops, store view_dist

all_strain_names = fieldnames(DATA);
fprintf('=== Loading data across %d strains ===\n', numel(all_strain_names));

gui_data = struct();

for si = 1:numel(all_strain_names)
    strain = all_strain_names{si};
    if ~isfield(DATA.(strain), sex), continue; end

    data_strain = DATA.(strain).(sex);
    n_exp = length(data_strain);
    rep1_str = strcat('R1_condition_', string(key_condition));
    rep2_str = strcat('R2_condition_', string(key_condition));
    if ~isfield(data_strain, rep1_str), continue; end

    x_cell       = {};
    y_cell       = {};
    heading_cell = {};
    loop_cell    = {};
    vdist_cell   = {};   % view_dist timeseries per fly

    n_loops_strain = 0;
    n_flies_strain = 0;

    for exp_idx = 1:n_exp
        for rep_idx = 1:2
            if rep_idx == 1
                rep_data = data_strain(exp_idx).(rep1_str);
            else
                rep_data = data_strain(exp_idx).(rep2_str);
            end
            if isempty(rep_data), continue; end

            % Check view_dist is available
            has_vdist = isfield(rep_data, 'view_dist');

            n_flies = size(rep_data.x_data, 1);
            n_frames_avail = size(rep_data.x_data, 2);
            sr_end = min(STIM_OFF, n_frames_avail);
            sr = STIM_ON:sr_end;

            vel_rep  = rep_data.vel_data(:, 1:n_frames_avail);
            dist_rep = rep_data.dist_data(:, 1:n_frames_avail);

            for f = 1:n_flies
                % QC checks
                n_stat = sum(vel_rep(f,:) < 0.5);
                if n_stat / n_frames_avail > 0.75, continue; end
                if min(dist_rep(f,:)) > 110, continue; end

                x_fly = rep_data.x_data(f, sr);
                y_fly = rep_data.y_data(f, sr);
                h_fly = rep_data.heading_data(f, sr);

                % Self-intersection loops
                loops = find_trajectory_loops(x_fly, y_fly, h_fly, loop_opts);
                n_loops_strain = n_loops_strain + loops.n_loops;
                n_flies_strain = n_flies_strain + 1;

                % View distance
                if has_vdist
                    vd_fly = rep_data.view_dist(f, sr);
                else
                    vd_fly = NaN(1, numel(sr));
                end

                x_cell{end+1}       = x_fly;
                y_cell{end+1}       = y_fly;
                heading_cell{end+1} = h_fly;
                loop_cell{end+1}    = loops;
                vdist_cell{end+1}   = vd_fly;
            end
        end
    end

    gui_data.(strain).x_cell       = x_cell;
    gui_data.(strain).y_cell       = y_cell;
    gui_data.(strain).heading_cell = heading_cell;
    gui_data.(strain).loop_cell    = loop_cell;
    gui_data.(strain).vdist_cell   = vdist_cell;

    if n_flies_strain > 0
        fprintf('  %s: %d flies, %d self-intersection loops\n', ...
            strain, n_flies_strain, n_loops_strain);
    end
end

%% ======================== GUI ========================

gui_strains = fieldnames(gui_data);
gui_strain_list = {};
for si = 1:numel(gui_strains)
    if ~isempty(gui_data.(gui_strains{si}).x_cell)
        gui_strain_list{end+1} = gui_strains{si};
    end
end

loop_colors = [
    0.216 0.494 0.722;   0.894 0.102 0.110;   0.302 0.686 0.290;
    0.596 0.306 0.639;   1.000 0.498 0.000;   0.651 0.337 0.157;
    0.122 0.694 0.827;   0.890 0.467 0.761;   0.498 0.498 0.498;
    0.737 0.741 0.133;   0.090 0.745 0.812;   0.682 0.780 0.910;
];
n_colors = size(loop_colors, 1);

fig = uifigure('Name', 'Trajectory Segmentation', 'Position', [50 50 900 950]);

% Trajectory axes (upper)
ax_traj = uiaxes(fig, 'Position', [40 370 820 540]);
hold(ax_traj, 'on'); axis(ax_traj, 'equal');
set(ax_traj, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
xlabel(ax_traj, 'x (mm)', 'FontSize', 14);
ylabel(ax_traj, 'y (mm)', 'FontSize', 14);

% View distance timeseries axes (lower)
ax_vd = uiaxes(fig, 'Position', [40 200 820 150]);
hold(ax_vd, 'on');
set(ax_vd, 'FontSize', 10, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1);
xlabel(ax_vd, 'Time (s)', 'FontSize', 12);
ylabel(ax_vd, 'View dist (mm)', 'FontSize', 12);

% --- Controls ---
% Row 1: strain + method
uilabel(fig, 'Position', [40 160 50 22], 'Text', 'Strain:', ...
    'FontSize', 12, 'FontWeight', 'bold');
dd_strain = uidropdown(fig, 'Position', [95 158 280 26], ...
    'Items', gui_strain_list, 'Value', gui_strain_list{1}, 'FontSize', 11);

uilabel(fig, 'Position', [400 160 55 22], 'Text', 'Method:', ...
    'FontSize', 12, 'FontWeight', 'bold');
dd_method = uidropdown(fig, 'Position', [460 158 180 26], ...
    'Items', {'Self-intersection', 'View dist peaks'}, ...
    'Value', 'Self-intersection', 'FontSize', 11);

% Row 2: smoothing + prominence sliders (for peak method)
uilabel(fig, 'Position', [40 120 65 22], 'Text', 'Smooth:', ...
    'FontSize', 11, 'FontWeight', 'bold');
sld_smooth = uislider(fig, 'Position', [110 133 150 3], ...
    'Limits', [1 60], 'Value', 15, 'MajorTicks', [1 15 30 45 60]);
lbl_smooth = uilabel(fig, 'Position', [265 120 55 22], ...
    'Text', '15 fr', 'FontSize', 11);

uilabel(fig, 'Position', [340 120 50 22], 'Text', 'Prom:', ...
    'FontSize', 11, 'FontWeight', 'bold');
sld_prom = uislider(fig, 'Position', [395 133 150 3], ...
    'Limits', [5 100], 'Value', 20, 'MajorTicks', [5 25 50 75 100]);
lbl_prom = uilabel(fig, 'Position', [550 120 55 22], ...
    'Text', '20 mm', 'FontSize', 11);

% Navigation
btn_prev = uibutton(fig, 'push', 'Text', char(9664), ...
    'Position', [40 30 80 40], 'FontSize', 20);
btn_next = uibutton(fig, 'push', 'Text', char(9654), ...
    'Position', [130 30 80 40], 'FontSize', 20);
lbl_fly = uilabel(fig, 'Position', [230 30 200 40], 'Text', '', ...
    'FontSize', 15, 'FontWeight', 'bold');
lbl_info = uilabel(fig, 'Position', [440 30 440 40], 'Text', '', ...
    'FontSize', 11);

% State
state.fly_idx = 1;
state.current_strain = gui_strain_list{1};
state.method = 'Self-intersection';
state.smooth_win = 15;
state.min_prominence = 20;
state.gui_data = gui_data;
state.gui_strain_list = gui_strain_list;
state.ARENA_CENTER = ARENA_CENTER;
state.ARENA_R = ARENA_R;
state.FPS = FPS;
state.ax_traj = ax_traj;
state.ax_vd = ax_vd;
state.lbl_fly = lbl_fly;
state.lbl_info = lbl_info;
state.lbl_smooth = lbl_smooth;
state.lbl_prom = lbl_prom;
state.loop_colors = loop_colors;
state.n_colors = n_colors;
fig.UserData = state;

% --- Draw function ---
    function draw(fig_handle)
        s = fig_handle.UserData;
        fi = s.fly_idx;
        ac = s.ARENA_CENTER;
        ar = s.ARENA_R;
        ax_t = s.ax_traj;
        ax_v = s.ax_vd;
        cols = s.loop_colors;
        nc = s.n_colors;
        str_name = s.current_strain;
        method = s.method;
        fps = s.FPS;

        gd = s.gui_data.(str_name);
        n_flies_this = numel(gd.x_cell);

        if n_flies_this == 0
            cla(ax_t); cla(ax_v);
            title(ax_t, sprintf('%s — No valid flies', str_name), 'FontSize', 14);
            return;
        end

        fi = max(1, min(fi, n_flies_this));
        s.fly_idx = fi;
        fig_handle.UserData = s;

        x = gd.x_cell{fi};
        y = gd.y_cell{fi};
        vd = gd.vdist_cell{fi};
        loops = gd.loop_cell{fi};
        n_frames = numel(x);
        t_s = (0:n_frames-1) / fps;

        % --- Clear both axes ---
        cla(ax_t); hold(ax_t, 'on');
        cla(ax_v); hold(ax_v, 'on');

        % Arena circle
        theta = linspace(0, 2*pi, 200);
        plot(ax_t, ac(1)+ar*cos(theta), ac(2)+ar*sin(theta), '-', ...
            'Color', [0.7 0.7 0.7], 'LineWidth', 1);

        % Full trajectory in light grey
        plot(ax_t, x, y, '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 0.8);

        % ---- Method-specific segmentation ----
        if strcmp(method, 'Self-intersection')
            % === SELF-INTERSECTION MODE ===
            n_segs = loops.n_loops;

            % View dist timeseries (grey) with loop boundaries shaded
            plot(ax_v, t_s, vd, '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.8);

            if n_segs > 0
                for k = 1:n_segs
                    sf = loops.start_frame(k);
                    ef = loops.end_frame(k);
                    col = cols(mod(k-1, nc) + 1, :);

                    % Trajectory segment
                    plot(ax_t, x(sf:ef), y(sf:ef), '-', 'Color', col, 'LineWidth', 2.5);
                    plot(ax_t, x(sf), y(sf), 'o', 'MarkerSize', 7, ...
                        'MarkerFaceColor', col, 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
                    plot(ax_t, x(ef), y(ef), 's', 'MarkerSize', 7, ...
                        'MarkerFaceColor', col, 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);

                    % Bounding box
                    x_seg = x(sf:ef);  y_seg = y(sf:ef);
                    xv = x_seg(~isnan(x_seg));  yv = y_seg(~isnan(y_seg));
                    if numel(xv) >= 2
                        bx = [min(xv), max(xv)];
                        by = [min(yv), max(yv)];
                        rectangle(ax_t, 'Position', [bx(1), by(1), diff(bx), diff(by)], ...
                            'EdgeColor', col, 'LineWidth', 1, 'LineStyle', '--');
                    end

                    mid_frame = round((sf + ef) / 2);
                    text(ax_t, x(mid_frame)+1, y(mid_frame)+1, ...
                        sprintf('#%d', k), 'FontSize', 8, 'Color', col, 'FontWeight', 'bold');

                    % Shade on timeseries
                    yl = ylim(ax_v);
                    fill(ax_v, [t_s(sf) t_s(ef) t_s(ef) t_s(sf)], ...
                        [yl(1) yl(1) yl(2) yl(2)], col, ...
                        'FaceAlpha', 0.2, 'EdgeColor', 'none');
                end
            end

            title(ax_t, sprintf('%s — Fly %d/%d — Self-intersection: %d loops', ...
                strrep(str_name,'_','\_'), fi, n_flies_this, n_segs), 'FontSize', 13);
            title(ax_v, 'View distance with loop boundaries', 'FontSize', 11);

            s.lbl_info.Text = sprintf('%d loops', n_segs);

        else
            % === VIEW DIST PEAKS MODE ===
            smooth_win = round(s.smooth_win);
            min_prom = s.min_prominence;

            % Smooth the view_dist signal
            vd_clean = vd;
            vd_clean(isnan(vd_clean)) = 0;  % temp fill for smoothing
            vd_smooth = movmean(vd_clean, smooth_win, 'omitnan');
            vd_smooth(isnan(vd)) = NaN;  % restore NaN positions

            % Find peaks
            [pk_vals, pk_locs] = findpeaks(vd_smooth, ...
                'MinPeakProminence', min_prom, ...
                'MinPeakDistance', 5);

            n_peaks = numel(pk_locs);
            n_segs = max(n_peaks - 1, 0);

            % Plot smoothed view_dist
            plot(ax_v, t_s, vd, '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 0.5);
            plot(ax_v, t_s, vd_smooth, '-k', 'LineWidth', 1.2);

            % Mark peaks
            if n_peaks > 0
                plot(ax_v, t_s(pk_locs), pk_vals, 'v', 'MarkerSize', 8, ...
                    'MarkerFaceColor', [0.894 0.102 0.110], 'MarkerEdgeColor', 'none');
            end

            % Colour peak-to-peak segments
            if n_segs > 0
                for k = 1:n_segs
                    sf = pk_locs(k);
                    ef = pk_locs(k+1);
                    col = cols(mod(k-1, nc) + 1, :);

                    % Trajectory segment
                    plot(ax_t, x(sf:ef), y(sf:ef), '-', 'Color', col, 'LineWidth', 2.5);
                    plot(ax_t, x(sf), y(sf), 'o', 'MarkerSize', 7, ...
                        'MarkerFaceColor', col, 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
                    plot(ax_t, x(ef), y(ef), 's', 'MarkerSize', 7, ...
                        'MarkerFaceColor', col, 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);

                    mid_frame = round((sf + ef) / 2);
                    text(ax_t, x(mid_frame)+1, y(mid_frame)+1, ...
                        sprintf('#%d', k), 'FontSize', 8, 'Color', col, 'FontWeight', 'bold');

                    % Shade on timeseries
                    yl = ylim(ax_v);
                    fill(ax_v, [t_s(sf) t_s(ef) t_s(ef) t_s(sf)], ...
                        [yl(1) yl(1) yl(2) yl(2)], col, ...
                        'FaceAlpha', 0.2, 'EdgeColor', 'none');
                end
            end

            title(ax_t, sprintf('%s — Fly %d/%d — View dist peaks: %d segments', ...
                strrep(str_name,'_','\_'), fi, n_flies_this, n_segs), 'FontSize', 13);
            title(ax_v, sprintf('View distance (smooth=%d fr, prom=%.0f mm, %d peaks)', ...
                smooth_win, min_prom, n_peaks), 'FontSize', 11);

            s.lbl_info.Text = sprintf('%d peaks, %d segments', n_peaks, n_segs);
        end

        % Trajectory start/end markers
        fv = find(~isnan(x), 1, 'first');
        lv = find(~isnan(x), 1, 'last');
        if ~isempty(fv)
            plot(ax_t, x(fv), y(fv), 'p', 'MarkerSize', 14, ...
                'MarkerFaceColor', [0.2 0.7 0.2], 'MarkerEdgeColor', 'none');
        end
        if ~isempty(lv)
            plot(ax_t, x(lv), y(lv), 'p', 'MarkerSize', 14, ...
                'MarkerFaceColor', [0.8 0.2 0.2], 'MarkerEdgeColor', 'none');
        end

        xlim(ax_t, [ac(1)-ar-5, ac(1)+ar+5]);
        ylim(ax_t, [ac(2)-ar-5, ac(2)+ar+5]);
        xlim(ax_v, [0 t_s(end)]);

        s.lbl_fly.Text = sprintf('Fly %d / %d', fi, n_flies_this);
    end

% --- Callbacks ---
dd_strain.ValueChangedFcn = @(src, ~) cb_strain(src, fig);
dd_method.ValueChangedFcn = @(src, ~) cb_method(src, fig);
btn_prev.ButtonPushedFcn  = @(~,~) cb_prev(fig);
btn_next.ButtonPushedFcn  = @(~,~) cb_next(fig);
sld_smooth.ValueChangedFcn = @(src, ~) cb_smooth(src, fig);
sld_prom.ValueChangedFcn   = @(src, ~) cb_prom(src, fig);

    function cb_strain(src, fh)
        fh.UserData.current_strain = src.Value;
        fh.UserData.fly_idx = 1;
        draw(fh);
    end

    function cb_method(src, fh)
        fh.UserData.method = src.Value;
        draw(fh);
    end

    function cb_prev(fh)
        s = fh.UserData;
        s.fly_idx = max(s.fly_idx - 1, 1);
        fh.UserData = s;
        draw(fh);
    end

    function cb_next(fh)
        s = fh.UserData;
        gd = s.gui_data.(s.current_strain);
        s.fly_idx = min(s.fly_idx + 1, numel(gd.x_cell));
        fh.UserData = s;
        draw(fh);
    end

    function cb_smooth(src, fh)
        fh.UserData.smooth_win = round(src.Value);
        fh.UserData.lbl_smooth.Text = sprintf('%d fr', round(src.Value));
        draw(fh);
    end

    function cb_prom(src, fh)
        fh.UserData.min_prominence = src.Value;
        fh.UserData.lbl_prom.Text = sprintf('%.0f mm', src.Value);
        draw(fh);
    end

% Initial draw
draw(fig);

fprintf('\nGUI ready.\n');
fprintf('  Strain dropdown: select strain\n');
fprintf('  Method dropdown: Self-intersection / View dist peaks\n');
fprintf('  Arrow buttons: cycle through flies\n');
fprintf('  Smooth slider: smoothing window for view_dist (peak method)\n');
fprintf('  Prom slider: minimum peak prominence in mm (peak method)\n');
