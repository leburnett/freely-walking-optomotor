%% LOOP_ORIENTATION_GUI - Visualise loop and inter-loop segment orientations
%
%  Interactive GUI that overlays orientation arrows on detected trajectory
%  loops AND the straight-line segments between consecutive loops.
%
%  View modes (dropdown):
%    "Loops"    — shows loop segments with PCA long-axis arrows
%    "Segments" — shows inter-loop segments with start→end direction arrows
%    "Both"     — shows both overlaid
%
%  Arrow colours encode orientation relative to the radial direction:
%    Red  = points radially outward (away from arena centre)
%    Blue = points radially inward (toward arena centre)
%
%  Controls:
%    Strain dropdown  — select strain
%    View dropdown    — Loops / Segments / Both
%    Arrow buttons    — cycle through flies
%    Aspect slider    — minimum aspect ratio for loop orientation arrows
%
%  Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 27).
%
%  See also: compute_loop_orientation, find_trajectory_loops

%% Setup

if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

ARENA_CENTER = [528, 520] / 4.1691;
ARENA_R = 120;
FPS = 30;

key_condition = 1;
sex = 'F';

STIM_ON  = 300;
STIM_OFF = 1200;

MIN_SEG_FRAMES = 5;  % minimum frames for an inter-loop segment

%% Loop detection + orientation + inter-loop segments (all strains)

loop_opts.lookahead_frames = 75;
loop_opts.min_loop_frames  = 5;
loop_opts.fps              = FPS;
loop_opts.arena_center     = ARENA_CENTER;
loop_opts.arena_radius     = ARENA_R;

all_strain_names = fieldnames(DATA);
fprintf('=== Loop orientation GUI: detecting loops + segments across %d strains ===\n', ...
    numel(all_strain_names));

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
    loop_cell    = {};
    orient_cell  = {};
    seg_cell     = {};   % inter-loop segment data per fly

    n_loops_strain = 0;

    for exp_idx = 1:n_exp
        for rep_idx = 1:2
            if rep_idx == 1
                rep_data = data_strain(exp_idx).(rep1_str);
            else
                rep_data = data_strain(exp_idx).(rep2_str);
            end
            if isempty(rep_data), continue; end

            n_flies = size(rep_data.x_data, 1);
            n_frames_avail = size(rep_data.x_data, 2);
            sr_end = min(STIM_OFF, n_frames_avail);
            sr = STIM_ON:sr_end;

            vel_rep  = rep_data.vel_data(:, 1:n_frames_avail);
            dist_rep = rep_data.dist_data(:, 1:n_frames_avail);

            for f = 1:n_flies
                if sum(vel_rep(f,:) < 0.5) / n_frames_avail > 0.75, continue; end
                if min(dist_rep(f,:)) > 110, continue; end

                % Keep unmasked copies for display
                x_fly = rep_data.x_data(f, sr);
                y_fly = rep_data.y_data(f, sr);
                h_fly = rep_data.heading_data(f, sr);

                v_fly = vel_rep(f, sr);
                loop_opts.vel = v_fly;

                loops = find_trajectory_loops(x_fly, y_fly, h_fly, loop_opts);

                % --- Compute loop orientations ---
                orient = struct();
                orient.orient_angle = NaN(1, max(loops.n_loops, 0));
                orient.rel_angle    = NaN(1, max(loops.n_loops, 0));
                orient.long_axis_dx = NaN(1, max(loops.n_loops, 0));
                orient.long_axis_dy = NaN(1, max(loops.n_loops, 0));
                orient.centroid_x   = NaN(1, max(loops.n_loops, 0));
                orient.centroid_y   = NaN(1, max(loops.n_loops, 0));

                for k = 1:loops.n_loops
                    sf = loops.start_frame(k);
                    ef = loops.end_frame(k);
                    [oa, ra, lad, mu] = compute_loop_orientation( ...
                        x_fly(sf:ef), y_fly(sf:ef), ARENA_CENTER);
                    orient.orient_angle(k) = oa;
                    orient.rel_angle(k)    = ra;
                    orient.long_axis_dx(k) = lad(1);
                    orient.long_axis_dy(k) = lad(2);
                    orient.centroid_x(k)   = mu(1);
                    orient.centroid_y(k)   = mu(2);
                end

                % --- Compute inter-loop segments ---
                % Segments between consecutive loops: end of loop k → start of loop k+1
                n_segs = max(loops.n_loops - 1, 0);
                segs = struct();
                segs.n_segs      = n_segs;
                segs.start_frame = NaN(1, n_segs);
                segs.end_frame   = NaN(1, n_segs);
                segs.orient_angle = NaN(1, n_segs);
                segs.rel_angle    = NaN(1, n_segs);
                segs.dir_dx       = NaN(1, n_segs);
                segs.dir_dy       = NaN(1, n_segs);
                segs.mid_x        = NaN(1, n_segs);
                segs.mid_y        = NaN(1, n_segs);
                segs.length_mm    = NaN(1, n_segs);

                for k = 1:n_segs
                    s_start = loops.end_frame(k) + 1;
                    s_end   = loops.start_frame(k+1) - 1;
                    if s_end - s_start + 1 < MIN_SEG_FRAMES, continue; end

                    x_s = x_fly(s_start:s_end);
                    y_s = y_fly(s_start:s_end);
                    valid = ~isnan(x_s) & ~isnan(y_s);
                    x_v = x_s(valid);  y_v = y_s(valid);
                    if numel(x_v) < MIN_SEG_FRAMES, continue; end

                    dx = x_v(end) - x_v(1);
                    dy = y_v(end) - y_v(1);
                    seg_len = sqrt(dx^2 + dy^2);
                    if seg_len < 0.5, continue; end

                    % Direction (time-ordered: start → end)
                    dir_ang = atan2d(dy, dx);
                    dir_unit = [dx, dy] / seg_len;

                    % Midpoint and distance from centre
                    mx = (x_v(1) + x_v(end)) / 2;
                    my = (y_v(1) + y_v(end)) / 2;
                    radial_ang = atan2d(my - ARENA_CENTER(2), mx - ARENA_CENTER(1));
                    rel = mod(dir_ang - radial_ang + 180, 360) - 180;

                    segs.start_frame(k) = s_start;
                    segs.end_frame(k)   = s_end;
                    segs.orient_angle(k) = dir_ang;
                    segs.rel_angle(k)    = rel;
                    segs.dir_dx(k)       = dir_unit(1);
                    segs.dir_dy(k)       = dir_unit(2);
                    segs.mid_x(k)        = mx;
                    segs.mid_y(k)        = my;
                    segs.length_mm(k)    = seg_len;
                end

                n_loops_strain = n_loops_strain + loops.n_loops;
                x_cell{end+1}      = x_fly;
                y_cell{end+1}      = y_fly;
                loop_cell{end+1}   = loops;
                orient_cell{end+1} = orient;
                seg_cell{end+1}    = segs;
            end
        end
    end

    gui_data.(strain).x_cell      = x_cell;
    gui_data.(strain).y_cell      = y_cell;
    gui_data.(strain).loop_cell   = loop_cell;
    gui_data.(strain).orient_cell = orient_cell;
    gui_data.(strain).seg_cell    = seg_cell;

    if n_loops_strain > 0
        fprintf('  %s: %d flies, %d loops\n', strain, numel(x_cell), n_loops_strain);
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

fig = uifigure('Name', 'Loop & Segment Orientation Viewer', 'Position', [50 50 900 950]);

% Trajectory axes
ax = uiaxes(fig, 'Position', [40 250 820 650]);
hold(ax, 'on'); axis(ax, 'equal');
set(ax, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
xlabel(ax, 'x (mm)', 'FontSize', 14);
ylabel(ax, 'y (mm)', 'FontSize', 14);

% --- Controls row 1: strain + view mode ---
uilabel(fig, 'Position', [40 210 50 22], 'Text', 'Strain:', ...
    'FontSize', 13, 'FontWeight', 'bold');
dd_strain = uidropdown(fig, 'Position', [95 208 300 26], ...
    'Items', gui_strain_list, 'Value', gui_strain_list{1}, 'FontSize', 11);

uilabel(fig, 'Position', [420 210 40 22], 'Text', 'View:', ...
    'FontSize', 13, 'FontWeight', 'bold');
dd_view = uidropdown(fig, 'Position', [465 208 150 26], ...
    'Items', {'Loops', 'Segments', 'Both'}, 'Value', 'Both', 'FontSize', 11);

% --- Controls row 2: aspect slider ---
uilabel(fig, 'Position', [640 210 85 22], 'Text', 'Min aspect:', ...
    'FontSize', 11, 'FontWeight', 'bold');
sld_aspect = uislider(fig, 'Position', [730 222 120 3], ...
    'Limits', [1 5], 'Value', 1.1, 'MajorTicks', 1:5, 'MinorTicks', 1:0.5:5);
lbl_aspect_val = uilabel(fig, 'Position', [855 210 45 22], ...
    'Text', '1.10', 'FontSize', 11, 'FontWeight', 'bold');

% --- Controls row 3: navigation ---
btn_prev = uibutton(fig, 'push', 'Text', char(9664), ...
    'Position', [40 60 80 40], 'FontSize', 20);
btn_next = uibutton(fig, 'push', 'Text', char(9654), ...
    'Position', [130 60 80 40], 'FontSize', 20);
lbl_fly = uilabel(fig, 'Position', [230 60 250 40], 'Text', '', ...
    'FontSize', 15, 'FontWeight', 'bold');
lbl_info = uilabel(fig, 'Position', [230 25 650 30], 'Text', '', ...
    'FontSize', 11);

% Legend
uilabel(fig, 'Position', [40 140 800 40], ...
    'Text', ['Arrows: red = outward, blue = inward  |  ' ...
             'Loops: coloured segments + PCA arrows  |  ' ...
             'Segments: green paths + direction arrows'], ...
    'FontSize', 10, 'FontColor', [0.4 0.4 0.4]);

% State
state.fly_idx = 1;
state.current_strain = gui_strain_list{1};
state.view_mode = 'Both';
state.gui_data = gui_data;
state.gui_strain_list = gui_strain_list;
state.ARENA_CENTER = ARENA_CENTER;
state.ARENA_R = ARENA_R;
state.ax = ax;
state.lbl_fly = lbl_fly;
state.lbl_info = lbl_info;
state.lbl_aspect_val = lbl_aspect_val;
state.loop_colors = loop_colors;
state.n_colors = n_colors;
state.aspect_threshold = 1.1;
fig.UserData = state;

% --- Draw function ---
    function draw(fig_handle)
        s = fig_handle.UserData;
        fi = s.fly_idx;
        ac = s.ARENA_CENTER;
        ar = s.ARENA_R;
        ax_h = s.ax;
        cols = s.loop_colors;
        nc = s.n_colors;
        str_name = s.current_strain;
        asp_thr = s.aspect_threshold;
        view_mode = s.view_mode;

        gd = s.gui_data.(str_name);
        n_flies_this = numel(gd.x_cell);

        if n_flies_this == 0
            cla(ax_h);
            title(ax_h, sprintf('%s — No valid flies', str_name), 'FontSize', 14);
            return;
        end

        fi = max(1, min(fi, n_flies_this));
        s.fly_idx = fi;
        fig_handle.UserData = s;

        x = gd.x_cell{fi};
        y = gd.y_cell{fi};
        loops  = gd.loop_cell{fi};
        orient = gd.orient_cell{fi};
        segs   = gd.seg_cell{fi};

        cla(ax_h); hold(ax_h, 'on');

        % Arena circle
        theta = linspace(0, 2*pi, 200);
        plot(ax_h, ac(1)+ar*cos(theta), ac(2)+ar*sin(theta), '-', ...
            'Color', [0.7 0.7 0.7], 'LineWidth', 1);

        % Full trajectory in light grey
        plot(ax_h, x, y, '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 0.8);

        show_loops = strcmp(view_mode, 'Loops') || strcmp(view_mode, 'Both');
        show_segs  = strcmp(view_mode, 'Segments') || strcmp(view_mode, 'Both');

        n_loop_arrows = 0;
        n_seg_arrows  = 0;

        % ---- Draw loops ----
        if show_loops && loops.n_loops > 0
            for k = 1:loops.n_loops
                sf = loops.start_frame(k);
                ef = loops.end_frame(k);
                col = cols(mod(k-1, nc) + 1, :);

                % Loop trajectory
                plot(ax_h, x(sf:ef), y(sf:ef), '-', 'Color', col, 'LineWidth', 2.5);

                % Start/end markers
                plot(ax_h, x(sf), y(sf), 'o', 'MarkerSize', 7, ...
                    'MarkerFaceColor', col, 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
                plot(ax_h, x(ef), y(ef), 's', 'MarkerSize', 7, ...
                    'MarkerFaceColor', col, 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);

                % Bounding box
                x_seg = x(sf:ef);  y_seg = y(sf:ef);
                xv = x_seg(~isnan(x_seg));  yv = y_seg(~isnan(y_seg));
                if numel(xv) >= 2
                    bx = [min(xv), max(xv)];
                    by = [min(yv), max(yv)];
                    rectangle(ax_h, 'Position', [bx(1), by(1), diff(bx), diff(by)], ...
                        'EdgeColor', col, 'LineWidth', 1, 'LineStyle', '--');
                end

                % Orientation arrow
                if loops.bbox_aspect(k) >= asp_thr && ~isnan(orient.orient_angle(k))
                    t = abs(orient.rel_angle(k)) / 180;
                    arrow_col = (1-t) * [0.8 0.15 0.15] + t * [0.15 0.3 0.7];
                    quiver(ax_h, orient.centroid_x(k), orient.centroid_y(k), ...
                        orient.long_axis_dx(k) * 6, orient.long_axis_dy(k) * 6, 0, ...
                        'Color', arrow_col, 'LineWidth', 2.5, 'MaxHeadSize', 1.5);
                    n_loop_arrows = n_loop_arrows + 1;

                    % mid_frame = round((sf + ef) / 2);
                    % text(ax_h, x(mid_frame) + 1, y(mid_frame) + 1, ...
                    %     sprintf('L%d %.0f°', k, orient.rel_angle(k)), ...
                    %     'FontSize', 7, 'Color', col, 'FontWeight', 'bold');
                end
            end
        end

        % ---- Draw inter-loop segments ----
        if show_segs && segs.n_segs > 0
            for k = 1:segs.n_segs
                if isnan(segs.start_frame(k)), continue; end

                ss = segs.start_frame(k);
                se = segs.end_frame(k);

                % Segment trajectory in green
                plot(ax_h, x(ss:se), y(ss:se), '-', ...
                    'Color', [0.3 0.75 0.3], 'LineWidth', 2);

                % Start/end markers for segment
                % plot(ax_h, x(ss), y(ss), '^', 'MarkerSize', 6, ...
                %     'MarkerFaceColor', [0.3 0.75 0.3], 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
                % plot(ax_h, x(se), y(se), 'v', 'MarkerSize', 6, ...
                %     'MarkerFaceColor', [0.3 0.75 0.3], 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);

                % Direction arrow at midpoint
                if ~isnan(segs.rel_angle(k))
                    t = abs(segs.rel_angle(k)) / 180;
                    arrow_col = (1-t) * [0.8 0.15 0.15] + t * [0.15 0.3 0.7];
                    quiver(ax_h, segs.mid_x(k), segs.mid_y(k), ...
                        segs.dir_dx(k) * 6, segs.dir_dy(k) * 6, 0, ...
                        'Color', arrow_col, 'LineWidth', 2, 'MaxHeadSize', 1.5);
                    n_seg_arrows = n_seg_arrows + 1;

                    % text(ax_h, segs.mid_x(k) + 1, segs.mid_y(k) - 1, ...
                    %     sprintf('S%d %.0f°', k, segs.rel_angle(k)), ...
                    %     'FontSize', 7, 'Color', [0.2 0.5 0.2], 'FontWeight', 'bold');
                end
            end
        end

        % Trajectory start/end markers
        fv = find(~isnan(x), 1, 'first');
        lv = find(~isnan(x), 1, 'last');
        if ~isempty(fv)
            plot(ax_h, x(fv), y(fv), 'p', 'MarkerSize', 14, ...
                'MarkerFaceColor', [0.2 0.7 0.2], 'MarkerEdgeColor', 'none');
        end
        if ~isempty(lv)
            plot(ax_h, x(lv), y(lv), 'p', 'MarkerSize', 14, ...
                'MarkerFaceColor', [0.8 0.2 0.2], 'MarkerEdgeColor', 'none');
        end

        xlim(ax_h, [ac(1)-ar-5, ac(1)+ar+5]);
        ylim(ax_h, [ac(2)-ar-5, ac(2)+ar+5]);

        title(ax_h, sprintf('%s — Fly %d/%d — [%s] %d loops, %d segs', ...
            strrep(str_name, '_', '\_'), fi, n_flies_this, view_mode, ...
            loops.n_loops, segs.n_segs), 'FontSize', 13);

        s.lbl_fly.Text = sprintf('Fly %d / %d', fi, n_flies_this);

        % Info text
        parts = {};
        if show_loops
            parts{end+1} = sprintf('%d loop arrows', n_loop_arrows);
        end
        if show_segs
            parts{end+1} = sprintf('%d seg arrows', n_seg_arrows);
        end
        if show_loops && loops.n_loops > 0
            vr = orient.rel_angle(~isnan(orient.rel_angle) & loops.bbox_aspect >= asp_thr);
            if ~isempty(vr)
                parts{end+1} = sprintf('loop mean=%.0f°', ...
                    atan2d(mean(sind(vr)), mean(cosd(vr))));
            end
        end
        if show_segs && segs.n_segs > 0
            vs = segs.rel_angle(~isnan(segs.rel_angle));
            if ~isempty(vs)
                parts{end+1} = sprintf('seg mean=%.0f°', ...
                    atan2d(mean(sind(vs)), mean(cosd(vs))));
            end
        end
        s.lbl_info.Text = strjoin(parts, '  |  ');
    end

% --- Callbacks ---
dd_strain.ValueChangedFcn  = @(src, ~) cb_strain(src, fig);
dd_view.ValueChangedFcn    = @(src, ~) cb_view(src, fig);
btn_prev.ButtonPushedFcn   = @(~,~) cb_prev(fig);
btn_next.ButtonPushedFcn   = @(~,~) cb_next(fig);
sld_aspect.ValueChangedFcn = @(src, ~) cb_aspect(src, fig);

    function cb_strain(src, fh)
        fh.UserData.current_strain = src.Value;
        fh.UserData.fly_idx = 1;
        draw(fh);
    end

    function cb_view(src, fh)
        fh.UserData.view_mode = src.Value;
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

    function cb_aspect(src, fh)
        fh.UserData.aspect_threshold = src.Value;
        fh.UserData.lbl_aspect_val.Text = sprintf('%.2f', src.Value);
        draw(fh);
    end

% Initial draw
draw(fig);

fprintf('\nGUI ready.\n');
fprintf('  Strain dropdown: select strain\n');
fprintf('  View dropdown: Loops / Segments / Both\n');
fprintf('  Arrow buttons: cycle through flies\n');
fprintf('  Aspect slider: min aspect ratio for loop arrows\n');
fprintf('  Labels: L# = loop, S# = segment (with rel angle)\n');
fprintf('  Red arrows = outward, Blue arrows = inward\n');
fprintf('  Green paths = inter-loop segments\n');
