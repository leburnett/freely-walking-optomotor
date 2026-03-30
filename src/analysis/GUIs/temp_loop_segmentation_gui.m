%% TEMP_LOOP_SEGMENTATION_GUI - Trajectory loop segmentation across all strains
%
% Loads ALL strains from DATA, finds trajectory self-intersection loops for
% each fly during the FULL 30s stimulus (frames 300-1200), and stores
% results in a nested struct mirroring the DATA hierarchy:
%
%   all_loops.(strain).(sex)(cohort_idx).R1_condition_N.loops(fly_idx) = struct
%
% Each loop struct contains per-loop metric arrays (bbox_area, duration_s, etc).
%
% GUI: strain dropdown + fly arrows. Scatter plot: one subplot per strain,
% bbox area vs distance from centre with trend line.
%
% Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 27).

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

% Full stimulus period (30 seconds)
STIM_ON  = 300;
STIM_OFF = 1200;
stim_range = STIM_ON:STIM_OFF;

%% Loop detection options

loop_opts.lookahead_frames = 75;
loop_opts.min_loop_frames  = 10;
loop_opts.fps              = FPS;
loop_opts.arena_center     = ARENA_CENTER;
loop_opts.arena_radius     = ARENA_R;

%% Iterate over ALL strains — build nested all_loops mirroring DATA

all_strain_names = fieldnames(DATA);
fprintf('=== Finding trajectory loops across %d strains (full 30s stimulus) ===\n', ...
    numel(all_strain_names));

all_loops = struct();

% Also build a flat table for easy plotting
flat_strain = {};
flat_area = [];
flat_dist = [];
flat_aspect = [];
flat_dur = [];
flat_hdg = [];
flat_wall = [];

% Per-fly trajectory storage for GUI (keyed by strain → list of fly structs)
gui_data = struct();  % gui_data.(strain).x_cell, .y_cell, .heading_cell, .loop_cell

for si = 1:numel(all_strain_names)
    strain = all_strain_names{si};

    if ~isfield(DATA.(strain), sex)
        continue;
    end

    data_strain = DATA.(strain).(sex);
    n_exp = length(data_strain);

    rep1_str = strcat('R1_condition_', string(key_condition));
    rep2_str = strcat('R2_condition_', string(key_condition));

    if ~isfield(data_strain, rep1_str)
        continue;
    end

    % Initialise all_loops for this strain/sex
    all_loops.(strain).(sex) = [];

    n_loops_strain = 0;
    n_flies_strain = 0;

    % GUI trajectory storage
    x_cell = {};
    y_cell = {};
    heading_cell = {};
    loop_cell = {};

    for exp_idx = 1:n_exp
        rep1_data = data_strain(exp_idx).(rep1_str);
        if isempty(rep1_data)
            continue;
        end
        rep2_data = data_strain(exp_idx).(rep2_str);

        % Copy the cohort structure shell from DATA
        all_loops.(strain).(sex)(exp_idx).meta = data_strain(exp_idx).meta;

        for rep_idx = 1:2
            if rep_idx == 1
                rep_data = rep1_data;
                rep_str = rep1_str;
            else
                rep_data = rep2_data;
                rep_str = rep2_str;
            end

            if isempty(rep_data)
                all_loops.(strain).(sex)(exp_idx).(rep_str) = struct('loops', []);
                continue;
            end

            n_flies = size(rep_data.x_data, 1);
            n_frames_avail = size(rep_data.x_data, 2);
            sr_end = min(STIM_OFF, n_frames_avail);
            sr = STIM_ON:sr_end;

            % QC: same thresholds as load_per_rep_data
            vel_rep = rep_data.vel_data(:, 1:n_frames_avail);
            dist_rep = rep_data.dist_data(:, 1:n_frames_avail);

            fly_loops_arr = [];  % struct array, one per fly

            for f = 1:n_flies
                % Quiescence check
                n_stat = sum(vel_rep(f,:) < 0.5);
                if n_stat / n_frames_avail > 0.75
                    % Store empty loops for this fly to keep indexing consistent
                    empty_l = make_empty_loop_struct();
                    if isempty(fly_loops_arr)
                        fly_loops_arr = empty_l;
                    else
                        fly_loops_arr(f) = empty_l;
                    end
                    continue;
                end

                % Edge-stuck check
                if min(dist_rep(f,:)) > 110
                    empty_l = make_empty_loop_struct();
                    if isempty(fly_loops_arr)
                        fly_loops_arr = empty_l;
                    else
                        fly_loops_arr(f) = empty_l;
                    end
                    continue;
                end

                x_fly = rep_data.x_data(f, sr);
                y_fly = rep_data.y_data(f, sr);
                h_fly = rep_data.heading_data(f, sr);  % unwrapped, degrees

                loops = find_trajectory_loops(x_fly, y_fly, h_fly, loop_opts);

                if isempty(fly_loops_arr)
                    fly_loops_arr = loops;
                else
                    fly_loops_arr(f) = loops;
                end

                n_loops_strain = n_loops_strain + loops.n_loops;
                n_flies_strain = n_flies_strain + 1;

                % Accumulate into flat table
                if loops.n_loops > 0
                    flat_strain = [flat_strain; repmat({strain}, loops.n_loops, 1)];
                    flat_area   = [flat_area;   loops.bbox_area(:)];                
                    flat_dist   = [flat_dist;   loops.bbox_dist_center(:)];          
                    flat_aspect = [flat_aspect;  loops.bbox_aspect(:)];              
                    flat_dur    = [flat_dur;     loops.duration_s(:)];               
                    flat_hdg    = [flat_hdg;     loops.cum_heading(:)];              
                    flat_wall   = [flat_wall;    loops.bbox_wall_dist(:)];          
                end

                % Store for GUI
                x_cell{end+1}       = x_fly;
                y_cell{end+1}       = y_fly;
                heading_cell{end+1} = h_fly;
                loop_cell{end+1}    = loops;
            end

            all_loops.(strain).(sex)(exp_idx).(rep_str).loops = fly_loops_arr;
        end
    end

    if n_flies_strain > 0
        fprintf('  %s: %d flies, %d loops (%.1f per fly)\n', ...
            strain, n_flies_strain, n_loops_strain, n_loops_strain / n_flies_strain);
    end

    gui_data.(strain).x_cell       = x_cell;
    gui_data.(strain).y_cell       = y_cell;
    gui_data.(strain).heading_cell = heading_cell;
    gui_data.(strain).loop_cell    = loop_cell;
end

%% Flat table for plotting

flat_table.strain           = flat_strain;
flat_table.bbox_area        = flat_area;
flat_table.bbox_dist_center = flat_dist;
flat_table.bbox_aspect      = flat_aspect;
flat_table.duration_s       = flat_dur;
flat_table.cum_heading      = flat_hdg;
flat_table.bbox_wall_dist   = flat_wall;

n_total_loops = numel(flat_table.bbox_area);
fprintf('\n=== Total: %d loops ===\n', n_total_loops);

%% Per-strain summary

unique_strains = unique(flat_table.strain);
fprintf('\nPer-strain summary:\n');
for si = 1:numel(unique_strains)
    idx = strcmp(flat_table.strain, unique_strains{si});
    fprintf('  %s: %d loops, median area %.0f mm², median dist %.1f mm\n', ...
        unique_strains{si}, sum(idx), ...
        median(flat_table.bbox_area(idx), 'omitnan'), ...
        median(flat_table.bbox_dist_center(idx), 'omitnan'));
end

%% Scatter plot: one subplot per strain, with trend line

fig_scatter = plot_bbox_area_vs_distance(flat_table);

%% ======================== GUI ========================

% Get strains that have GUI data
gui_strains = fieldnames(gui_data);
gui_strain_list = {};
for si = 1:numel(gui_strains)
    if ~isempty(gui_data.(gui_strains{si}).x_cell)
        gui_strain_list{end+1} = gui_strains{si};
    end
end

% Colour palette for loops
loop_colors = [
    0.216 0.494 0.722;   % blue
    0.894 0.102 0.110;   % red
    0.302 0.686 0.290;   % green
    0.596 0.306 0.639;   % purple
    1.000 0.498 0.000;   % orange
    0.651 0.337 0.157;   % brown
    0.122 0.694 0.827;   % cyan
    0.890 0.467 0.761;   % pink
    0.498 0.498 0.498;   % grey
    0.737 0.741 0.133;   % olive
    0.090 0.745 0.812;   % teal
    0.682 0.780 0.910;   % light blue
];
n_colors = size(loop_colors, 1);

fig = uifigure('Name', 'Trajectory Loop Segmentation', 'Position', [50 50 850 850]);

% Trajectory axes
ax = uiaxes(fig, 'Position', [40 160 770 640]);
hold(ax, 'on'); axis(ax, 'equal');
set(ax, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
xlabel(ax, 'x (mm)', 'FontSize', 14);
ylabel(ax, 'y (mm)', 'FontSize', 14);

% Strain dropdown
uilabel(fig, 'Position', [40 120 50 22], 'Text', 'Strain:', ...
    'FontSize', 13, 'FontWeight', 'bold');
dd_strain = uidropdown(fig, 'Position', [95 118 350 26], ...
    'Items', gui_strain_list, 'Value', gui_strain_list{1}, 'FontSize', 11);

% Navigation buttons
btn_prev = uibutton(fig, 'push', 'Text', char(9664), ...
    'Position', [40 60 80 40], 'FontSize', 20);
btn_next = uibutton(fig, 'push', 'Text', char(9654), ...
    'Position', [130 60 80 40], 'FontSize', 20);
lbl_fly = uilabel(fig, 'Position', [230 60 250 40], 'Text', '', ...
    'FontSize', 15, 'FontWeight', 'bold');
lbl_info = uilabel(fig, 'Position', [490 60 340 40], 'Text', '', ...
    'FontSize', 12);

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
state.loop_colors = loop_colors;
state.n_colors = n_colors;
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
        loops = gd.loop_cell{fi};

        cla(ax_h); hold(ax_h, 'on');

        % Arena circle
        theta = linspace(0, 2*pi, 200);
        plot(ax_h, ac(1)+ar*cos(theta), ac(2)+ar*sin(theta), '-', ...
            'Color', [0.7 0.7 0.7], 'LineWidth', 1);

        % Full trajectory in light grey
        plot(ax_h, x, y, '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 0.8);

        % Overlay each loop
        if loops.n_loops > 0
            for k = 1:loops.n_loops
                sf = loops.start_frame(k);
                ef = loops.end_frame(k);
                col = cols(mod(k-1, nc) + 1, :);

                plot(ax_h, x(sf:ef), y(sf:ef), '-', 'Color', col, 'LineWidth', 2.5);

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
                    plot(ax_h, loops.bbox_center_x(k), loops.bbox_center_y(k), ...
                        'x', 'MarkerSize', 8, 'Color', col, 'LineWidth', 1.5);
                end

                mid_frame = round((sf + ef) / 2);
                lbl_str = sprintf('#%d  %.1fs  %.0fmm²  %.0f°', ...
                    k, loops.duration_s(k), loops.bbox_area(k), loops.cum_heading(k));
                text(ax_h, x(mid_frame) + 1, y(mid_frame) + 1, ...
                    lbl_str, 'FontSize', 8, 'Color', col, 'FontWeight', 'bold');
            end
        end

        % Start/end markers
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

        title(ax_h, sprintf('%s — Fly %d / %d — %d loops', ...
            strrep(str_name, '_', '\_'), fi, n_flies_this, loops.n_loops), 'FontSize', 14);

        s.lbl_fly.Text = sprintf('Fly %d / %d', fi, n_flies_this);

        if loops.n_loops > 0
            s.lbl_info.Text = sprintf('%s | %d loops | mean %.1fs', ...
                strrep(str_name, '_', '\_'), loops.n_loops, mean(loops.duration_s));
        else
            s.lbl_info.Text = sprintf('%s | No loops found', strrep(str_name, '_', '\_'));
        end
    end

% --- Callbacks ---
dd_strain.ValueChangedFcn = @(src, ~) cb_strain(src, fig);
btn_prev.ButtonPushedFcn = @(~,~) cb_prev(fig);
btn_next.ButtonPushedFcn = @(~,~) cb_next(fig);

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

% Initial draw
draw(fig);

fprintf('\nGUI ready.\n');
fprintf('  Dropdown: select strain\n');
fprintf('  Arrow buttons: cycle through flies within strain\n');
fprintf('  all_loops nested struct available in workspace\n');
fprintf('  flat_table struct available for easy plotting/filtering\n');

%% ======================== Helper ========================

function s = make_empty_loop_struct()
    s.n_loops         = 0;
    s.start_frame     = [];
    s.end_frame       = [];
    s.intersect_x     = [];
    s.intersect_y     = [];
    s.cum_heading     = [];
    s.duration_frames = [];
    s.duration_s      = [];
    s.bbox_area       = [];
    s.bbox_aspect     = [];
    s.bbox_center_x   = [];
    s.bbox_center_y   = [];
    s.bbox_dist_center = [];
    s.bbox_wall_dist  = [];
    s.mean_ang_diff   = [];
    s.dist_from_prev  = [];
end
