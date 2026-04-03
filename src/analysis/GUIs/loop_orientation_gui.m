%% LOOP_ORIENTATION_GUI - Visualise PCA-based loop orientations on trajectories
%
%  Interactive GUI that overlays orientation arrows on detected trajectory
%  loops. Each arrow shows the direction of the loop's long axis (first
%  principal component), oriented away from the self-intersection point
%  toward the "bulge" of the loop.
%
%  Arrow colours encode the orientation relative to the radial direction:
%    Red  = loop points radially outward (away from arena centre)
%    Blue = loop points radially inward (toward arena centre)
%
%  Controls:
%    Strain dropdown — select strain to visualise
%    Arrow buttons   — cycle through flies within strain
%    Aspect slider   — adjust minimum aspect ratio threshold (loops below
%                      this are too circular for meaningful orientation)
%
%  Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 27).
%
%  See also: compute_loop_orientation, find_trajectory_loops, loop_segmentation_gui

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
MASK_START = 750;
MASK_END   = 850;

%% Loop detection + orientation computation (all strains)

loop_opts.lookahead_frames = 75;
loop_opts.min_loop_frames  = 10;
loop_opts.fps              = FPS;
loop_opts.arena_center     = ARENA_CENTER;
loop_opts.arena_radius     = ARENA_R;

all_strain_names = fieldnames(DATA);
fprintf('=== Loop orientation GUI: detecting loops across %d strains ===\n', ...
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
    heading_cell = {};
    loop_cell    = {};
    orient_cell  = {};

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
                % QC checks
                if sum(vel_rep(f,:) < 0.5) / n_frames_avail > 0.75, continue; end
                if min(dist_rep(f,:)) > 110, continue; end

                % Keep unmasked copies for GUI display
                x_fly = rep_data.x_data(f, sr);
                y_fly = rep_data.y_data(f, sr);
                h_fly = rep_data.heading_data(f, sr);

                % NaN-mask reversal window in COPIES for loop detection only
                x_det = x_fly;  y_det = y_fly;  h_det = h_fly;
                mask_s = max(MASK_START - STIM_ON + 1, 1);
                mask_e = min(MASK_END - STIM_ON + 1, numel(x_fly));
                x_det(mask_s:mask_e) = NaN;
                y_det(mask_s:mask_e) = NaN;
                h_det(mask_s:mask_e) = NaN;

                v_fly = vel_rep(f, sr);
                v_fly(mask_s:mask_e) = NaN;
                loop_opts.vel = v_fly;

                loops = find_trajectory_loops(x_det, y_det, h_det, loop_opts);

                % Compute orientation for each loop
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
                    x_seg = x_fly(sf:ef);
                    y_seg = y_fly(sf:ef);

                    [oa, ra, lad, mu] = compute_loop_orientation(x_seg, y_seg, ARENA_CENTER);
                    orient.orient_angle(k) = oa;
                    orient.rel_angle(k)    = ra;
                    orient.long_axis_dx(k) = lad(1);
                    orient.long_axis_dy(k) = lad(2);
                    orient.centroid_x(k)   = mu(1);
                    orient.centroid_y(k)   = mu(2);
                end

                n_loops_strain = n_loops_strain + loops.n_loops;
                x_cell{end+1}       = x_fly;
                y_cell{end+1}       = y_fly;
                heading_cell{end+1} = h_fly;
                loop_cell{end+1}    = loops;
                orient_cell{end+1}  = orient;
            end
        end
    end

    gui_data.(strain).x_cell       = x_cell;
    gui_data.(strain).y_cell       = y_cell;
    gui_data.(strain).heading_cell = heading_cell;
    gui_data.(strain).loop_cell    = loop_cell;
    gui_data.(strain).orient_cell  = orient_cell;

    if n_loops_strain > 0
        fprintf('  %s: %d flies, %d loops\n', strain, numel(x_cell), n_loops_strain);
    end
end

%% ======================== GUI ========================

% Get strains with data
gui_strains = fieldnames(gui_data);
gui_strain_list = {};
for si = 1:numel(gui_strains)
    if ~isempty(gui_data.(gui_strains{si}).x_cell)
        gui_strain_list{end+1} = gui_strains{si};
    end
end

% Loop colour palette
loop_colors = [
    0.216 0.494 0.722;   0.894 0.102 0.110;   0.302 0.686 0.290;
    0.596 0.306 0.639;   1.000 0.498 0.000;   0.651 0.337 0.157;
    0.122 0.694 0.827;   0.890 0.467 0.761;   0.498 0.498 0.498;
    0.737 0.741 0.133;   0.090 0.745 0.812;   0.682 0.780 0.910;
];
n_colors = size(loop_colors, 1);

fig = uifigure('Name', 'Loop Orientation Viewer', 'Position', [50 50 900 920]);

% Trajectory axes
ax = uiaxes(fig, 'Position', [40 220 820 650]);
hold(ax, 'on'); axis(ax, 'equal');
set(ax, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
xlabel(ax, 'x (mm)', 'FontSize', 14);
ylabel(ax, 'y (mm)', 'FontSize', 14);

% Strain dropdown
uilabel(fig, 'Position', [40 180 50 22], 'Text', 'Strain:', ...
    'FontSize', 13, 'FontWeight', 'bold');
dd_strain = uidropdown(fig, 'Position', [95 178 350 26], ...
    'Items', gui_strain_list, 'Value', gui_strain_list{1}, 'FontSize', 11);

% Aspect ratio slider
uilabel(fig, 'Position', [480 178 100 22], 'Text', 'Min aspect:', ...
    'FontSize', 12, 'FontWeight', 'bold');
sld_aspect = uislider(fig, 'Position', [585 190 200 3], ...
    'Limits', [1 5], 'Value', 1.1, 'MajorTicks', 1:5, 'MinorTicks', 1:0.25:5);
lbl_aspect_val = uilabel(fig, 'Position', [795 178 60 22], ...
    'Text', '1.10', 'FontSize', 12, 'FontWeight', 'bold');

% Navigation buttons
btn_prev = uibutton(fig, 'push', 'Text', char(9664), ...
    'Position', [40 60 80 40], 'FontSize', 20);
btn_next = uibutton(fig, 'push', 'Text', char(9654), ...
    'Position', [130 60 80 40], 'FontSize', 20);
lbl_fly = uilabel(fig, 'Position', [230 60 250 40], 'Text', '', ...
    'FontSize', 15, 'FontWeight', 'bold');
lbl_info = uilabel(fig, 'Position', [230 25 650 30], 'Text', '', ...
    'FontSize', 11);

% Legend
uilabel(fig, 'Position', [40 120 400 22], ...
    'Text', 'Arrows: red = outward, blue = inward, grey = filtered (low aspect)', ...
    'FontSize', 10, 'FontColor', [0.4 0.4 0.4]);

% State
state.fly_idx = 1;
state.current_strain = gui_strain_list{1};
state.gui_data = gui_data;
state.gui_strain_list = gui_strain_list;
state.ARENA_CENTER = ARENA_CENTER;
state.ARENA_R = ARENA_R;
state.FPS = FPS;
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

        cla(ax_h); hold(ax_h, 'on');

        % Arena circle
        theta = linspace(0, 2*pi, 200);
        plot(ax_h, ac(1)+ar*cos(theta), ac(2)+ar*sin(theta), '-', ...
            'Color', [0.7 0.7 0.7], 'LineWidth', 1);

        % Full trajectory in light grey
        plot(ax_h, x, y, '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 0.8);

        n_with_arrow = 0;

        % Overlay each loop
        if loops.n_loops > 0
            for k = 1:loops.n_loops
                sf = loops.start_frame(k);
                ef = loops.end_frame(k);
                col = cols(mod(k-1, nc) + 1, :);

                % Loop trajectory segment
                plot(ax_h, x(sf:ef), y(sf:ef), '-', 'Color', col, 'LineWidth', 2.5);

                % Start/end markers
                plot(ax_h, x(sf), y(sf), 'o', 'MarkerSize', 8, ...
                    'MarkerFaceColor', col, 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
                plot(ax_h, x(ef), y(ef), 's', 'MarkerSize', 8, ...
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

                % Orientation arrow (only if above aspect threshold)
                if loops.bbox_aspect(k) >= asp_thr && ~isnan(orient.orient_angle(k))
                    % Colour by relative angle: red (outward) → blue (inward)
                    t = abs(orient.rel_angle(k)) / 180;
                    arrow_col = (1-t) * [0.8 0.15 0.15] + t * [0.15 0.3 0.7];
                    arrow_len = 6;

                    quiver(ax_h, orient.centroid_x(k), orient.centroid_y(k), ...
                        orient.long_axis_dx(k) * arrow_len, ...
                        orient.long_axis_dy(k) * arrow_len, 0, ...
                        'Color', arrow_col, 'LineWidth', 2.5, 'MaxHeadSize', 1.5);
                    n_with_arrow = n_with_arrow + 1;

                    % Label with relative angle
                    mid_frame = round((sf + ef) / 2);
                    text(ax_h, x(mid_frame) + 1, y(mid_frame) + 1, ...
                        sprintf('#%d  ar=%.1f  rel=%.0f°', ...
                        k, loops.bbox_aspect(k), orient.rel_angle(k)), ...
                        'FontSize', 7, 'Color', col, 'FontWeight', 'bold');
                else
                    % Label without orientation
                    mid_frame = round((sf + ef) / 2);
                    text(ax_h, x(mid_frame) + 1, y(mid_frame) + 1, ...
                        sprintf('#%d  ar=%.1f', k, loops.bbox_aspect(k)), ...
                        'FontSize', 7, 'Color', [0.6 0.6 0.6]);
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

        title(ax_h, sprintf('%s — Fly %d / %d — %d loops (%d with arrows)', ...
            strrep(str_name, '_', '\_'), fi, n_flies_this, loops.n_loops, n_with_arrow), ...
            'FontSize', 14);

        s.lbl_fly.Text = sprintf('Fly %d / %d', fi, n_flies_this);

        if loops.n_loops > 0 && n_with_arrow > 0
            valid_rel = orient.rel_angle(~isnan(orient.rel_angle) & ...
                loops.bbox_aspect >= asp_thr);
            mean_rel = atan2d(mean(sind(valid_rel)), mean(cosd(valid_rel)));
            s.lbl_info.Text = sprintf('%d loops | %d arrows (aspect >= %.2f) | mean rel angle = %.0f°', ...
                loops.n_loops, n_with_arrow, asp_thr, mean_rel);
        elseif loops.n_loops > 0
            s.lbl_info.Text = sprintf('%d loops | 0 arrows (none pass aspect >= %.2f)', ...
                loops.n_loops, asp_thr);
        else
            s.lbl_info.Text = 'No loops found';
        end
    end

% --- Callbacks ---
dd_strain.ValueChangedFcn = @(src, ~) cb_strain(src, fig);
btn_prev.ButtonPushedFcn  = @(~,~) cb_prev(fig);
btn_next.ButtonPushedFcn  = @(~,~) cb_next(fig);
sld_aspect.ValueChangedFcn = @(src, ~) cb_aspect(src, fig);

    function cb_strain(src, fh)
        fh.UserData.current_strain = src.Value;
        fh.UserData.fly_idx = 1;
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
fprintf('  Dropdown: select strain\n');
fprintf('  Arrow buttons: cycle through flies\n');
fprintf('  Aspect slider: adjust minimum aspect ratio for orientation arrows\n');
fprintf('  Red arrows = outward, Blue arrows = inward\n');
