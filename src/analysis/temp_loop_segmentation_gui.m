%% TEMP_LOOP_SEGMENTATION_GUI - Visualise trajectory loop segmentation
%
% Displays a fly's trajectory segmented by self-intersections. Each loop
% (segment between consecutive intersection points) is coloured differently.
% Non-loop segments are drawn in light grey.
%
% The intersection search requires 360 degrees of cumulative heading change
% between consecutive intersection points, so only genuine turning loops
% are segmented.
%
% Arrow buttons step through flies. No sliders.
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

data_types = {'x_data', 'y_data', 'heading_data'};
[rep_data, n_flies] = load_per_rep_data(DATA, control_strain, sex, key_condition, data_types);

% Use half 1 only (stimulus onset to direction change)
h1_range = STIM_ON:STIM_MID;
x_all       = rep_data.x_data(:, h1_range);
y_all       = rep_data.y_data(:, h1_range);
heading_all = rep_data.heading_data(:, h1_range);  % unwrapped, degrees

n_total_frames = size(x_all, 2);

%% Precompute loops for all flies

fprintf('Finding trajectory loops for %d flies...', n_flies);
loop_opts.lookahead_frames  = 75;   % look 2.5s ahead for crossings
loop_opts.min_loop_frames   = 10;
loop_opts.fps               = FPS;

all_loops = cell(n_flies, 1);
for fi = 1:n_flies
    all_loops{fi} = find_trajectory_loops( ...
        x_all(fi,:), y_all(fi,:), heading_all(fi,:), loop_opts);
end
fprintf(' done.\n');

total_loops = sum(cellfun(@(L) L.n_loops, all_loops));
fprintf('Total loops found: %d across %d flies (mean %.1f per fly)\n', ...
    total_loops, n_flies, total_loops / n_flies);

%% Colour palette for loops

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

%% Build the GUI

fig = uifigure('Name', 'Trajectory Loop Segmentation', 'Position', [50 50 800 800]);

% Trajectory axes
ax = uiaxes(fig, 'Position', [40 120 720 640]);
hold(ax, 'on'); axis(ax, 'equal');
set(ax, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
xlabel(ax, 'x (mm)', 'FontSize', 14);
ylabel(ax, 'y (mm)', 'FontSize', 14);

% Navigation buttons
btn_prev = uibutton(fig, 'push', 'Text', char(9664), ...
    'Position', [40 50 80 40], 'FontSize', 20);
btn_next = uibutton(fig, 'push', 'Text', char(9654), ...
    'Position', [130 50 80 40], 'FontSize', 20);
lbl_fly = uilabel(fig, 'Position', [230 50 250 40], 'Text', '', ...
    'FontSize', 15, 'FontWeight', 'bold');
lbl_info = uilabel(fig, 'Position', [490 50 280 40], 'Text', '', ...
    'FontSize', 12);

% State
state.fly_idx = 1;
state.x_all = x_all;
state.y_all = y_all;
state.heading_all = heading_all;
state.all_loops = all_loops;
state.n_flies = n_flies;
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

        x = s.x_all(fi, :);
        y = s.y_all(fi, :);
        loops = s.all_loops{fi};
        cols = s.loop_colors;
        nc = s.n_colors;

        cla(ax_h); hold(ax_h, 'on');

        % Arena circle
        theta = linspace(0, 2*pi, 200);
        plot(ax_h, ac(1)+ar*cos(theta), ac(2)+ar*sin(theta), '-', ...
            'Color', [0.7 0.7 0.7], 'LineWidth', 1);

        % Full trajectory in light grey
        plot(ax_h, x, y, '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 0.8);

        % Overlay each loop segment in a distinct colour
        if loops.n_loops > 0
            for k = 1:loops.n_loops
                sf = loops.start_frame(k);
                ef = loops.end_frame(k);
                col = cols(mod(k-1, nc) + 1, :);

                plot(ax_h, x(sf:ef), y(sf:ef), '-', ...
                    'Color', col, 'LineWidth', 2.5);

                % Mark intersection points
                plot(ax_h, x(sf), y(sf), 'o', 'MarkerSize', 8, ...
                    'MarkerFaceColor', col, 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
                plot(ax_h, x(ef), y(ef), 's', 'MarkerSize', 8, ...
                    'MarkerFaceColor', col, 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);

                % Label with loop number and duration
                mid_frame = round((sf + ef) / 2);
                text(ax_h, x(mid_frame) + 1, y(mid_frame) + 1, ...
                    sprintf('%d (%.1fs)', k, loops.duration_s(k)), ...
                    'FontSize', 9, 'Color', col, 'FontWeight', 'bold');
            end
        end

        % Start/end of full trajectory
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

        % Axis limits
        xlim(ax_h, [ac(1)-ar-5, ac(1)+ar+5]);
        ylim(ax_h, [ac(2)-ar-5, ac(2)+ar+5]);

        % Title and labels
        title(ax_h, sprintf('Fly %d / %d — %d loops found', ...
            fi, s.n_flies, loops.n_loops), 'FontSize', 16);

        s.lbl_fly.Text = sprintf('Fly %d / %d', fi, s.n_flies);

        if loops.n_loops > 0
            mean_dur = mean(loops.duration_s);
            total_heading = sum(abs(loops.cum_heading));
            s.lbl_info.Text = sprintf('%d loops | mean %.1fs | total %.0f° heading', ...
                loops.n_loops, mean_dur, total_heading);
        else
            s.lbl_info.Text = 'No loops found';
        end
    end

% --- Callbacks ---
btn_prev.ButtonPushedFcn = @(~,~) cb_prev(fig);
btn_next.ButtonPushedFcn = @(~,~) cb_next(fig);

    function cb_prev(fh)
        s = fh.UserData;
        s.fly_idx = max(s.fly_idx - 1, 1);
        fh.UserData = s;
        draw(fh);
    end

    function cb_next(fh)
        s = fh.UserData;
        s.fly_idx = min(s.fly_idx + 1, s.n_flies);
        fh.UserData = s;
        draw(fh);
    end

% Initial draw
draw(fig);

fprintf('GUI ready.\n');
fprintf('  Arrow buttons cycle through flies\n');
fprintf('  Each coloured segment is a loop between self-intersections\n');
fprintf('  Circles = loop start, squares = loop end\n');
fprintf('  Green star = trajectory start, red star = trajectory end\n');
