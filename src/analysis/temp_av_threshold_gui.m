%% TEMP_AV_THRESHOLD_GUI - Interactive GUI for exploring AV threshold on trajectories
%
% Displays a single fly's trajectory coloured by raw |AV|. A slider
% controls the AV threshold; markers appear on frames where |AV| exceeds
% the threshold (with a minimum 15-frame spacing between markers).
% Left/right buttons step through flies in the dataset.
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

data_types = {'heading_data', 'x_data', 'y_data', 'dist_data', 'av_data'};
[rep_data, n_flies] = load_per_rep_data(DATA, control_strain, sex, key_condition, data_types);

% Use half 1 only
h1_range = STIM_ON:STIM_MID;
x_all       = rep_data.x_data(:, h1_range);
y_all       = rep_data.y_data(:, h1_range);
av_all      = rep_data.av_data(:, h1_range);

MIN_GAP = 15;  % minimum frames between markers

%% Build the GUI

fig = uifigure('Name', 'AV Threshold Explorer', 'Position', [100 100 900 750]);

% Main axes
ax = uiaxes(fig, 'Position', [60 160 780 540]);
hold(ax, 'on');
axis(ax, 'equal');
set(ax, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
xlabel(ax, 'x (mm)', 'FontSize', 14);
ylabel(ax, 'y (mm)', 'FontSize', 14);

% Slider for AV threshold
lbl_slider = uilabel(fig, 'Position', [60 120 120 22], 'Text', 'AV threshold:', ...
    'FontSize', 13, 'FontWeight', 'bold');
slider = uislider(fig, 'Position', [180 130 500 3], ...
    'Limits', [10 300], 'Value', 90, 'MajorTicks', 10:20:300);
lbl_val = uilabel(fig, 'Position', [700 120 80 22], 'Text', '90 deg/s', ...
    'FontSize', 13, 'FontWeight', 'bold');

% Navigation buttons
btn_prev = uibutton(fig, 'push', 'Text', char(9664), ...  % left arrow
    'Position', [60 50 80 40], 'FontSize', 20);
btn_next = uibutton(fig, 'push', 'Text', char(9654), ...  % right arrow
    'Position', [160 50 80 40], 'FontSize', 20);
lbl_fly = uilabel(fig, 'Position', [260 50 300 40], 'Text', '', ...
    'FontSize', 15, 'FontWeight', 'bold');

% Marker count display
lbl_count = uilabel(fig, 'Position', [560 50 300 40], 'Text', '', ...
    'FontSize', 13);

% Store ALL data, state, and UI handles in figure's UserData
state.fly_idx = 1;
state.av_threshold = 90;
state.x_all = x_all;
state.y_all = y_all;
state.av_all = av_all;
state.n_flies = n_flies;
state.ARENA_CENTER = ARENA_CENTER;
state.ARENA_R = ARENA_R;
state.MIN_GAP = MIN_GAP;
state.ax = ax;
state.lbl_fly = lbl_fly;
state.lbl_val = lbl_val;
state.lbl_count = lbl_count;
fig.UserData = state;

% --- Drawing function ---
    function draw(fig_handle)
        s = fig_handle.UserData;
        fi = s.fly_idx;
        thr = s.av_threshold;
        ac = s.ARENA_CENTER;
        ar = s.ARENA_R;
        mg = s.MIN_GAP;
        nf = s.n_flies;
        ax = s.ax;
        lbl_fly = s.lbl_fly;
        lbl_val = s.lbl_val;
        lbl_count = s.lbl_count;

        x = s.x_all(fi, :);
        y = s.y_all(fi, :);
        av_raw = abs(s.av_all(fi, :));
        n_frames = numel(x);

        cla(ax);
        hold(ax, 'on');

        % Arena circle
        theta = linspace(0, 2*pi, 200);
        plot(ax, ac(1) + ar*cos(theta), ...
             ac(2) + ar*sin(theta), '-', ...
             'Color', [0.7 0.7 0.7], 'LineWidth', 1);

        % Trajectory coloured by raw |AV| using patch
        valid = ~isnan(x) & ~isnan(y) & ~isnan(av_raw);
        d_valid = diff([0, valid, 0]);
        seg_starts = find(d_valid == 1);
        seg_ends   = find(d_valid == -1) - 1;

        for si = 1:numel(seg_starts)
            idx = seg_starts(si):seg_ends(si);
            if numel(idx) < 2, continue; end
            patch(ax, [x(idx) NaN], [y(idx) NaN], 0, ...
                'EdgeColor', 'interp', 'FaceColor', 'none', ...
                'CData', [av_raw(idx) NaN], 'LineWidth', 1.5);
        end

        % Colormap and limits (clip at 99th percentile)
        colormap(ax, 'parula');
        av_valid = av_raw(valid);
        if ~isempty(av_valid)
            clim_upper = prctile(av_valid, 99);
            clim_upper = max(clim_upper, 10);
            clim(ax, [0 clim_upper]);
        end
        cb = colorbar(ax);
        cb.Label.String = '|AV| (deg/s)';
        cb.Label.FontSize = 12;

        % Threshold line on colorbar
        % (visual reference — draw as a horizontal line annotation is tricky,
        %  so we mark it in the title)

        % Find supra-threshold frames with minimum gap enforcement
        above = find(av_raw > thr & valid);
        marker_frames = [];
        if ~isempty(above)
            marker_frames = above(1);
            for k = 2:numel(above)
                if above(k) - marker_frames(end) >= mg
                    marker_frames(end+1) = above(k); %#ok<AGROW>
                end
            end
        end

        % Plot markers
        if ~isempty(marker_frames)
            plot(ax, x(marker_frames), y(marker_frames), '^', ...
                'MarkerSize', 8, 'MarkerFaceColor', [0.894 0.102 0.110], ...
                'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
        end

        % Start/end markers
        first_v = find(valid, 1, 'first');
        last_v  = find(valid, 1, 'last');
        if ~isempty(first_v)
            plot(ax, x(first_v), y(first_v), 'o', 'MarkerSize', 12, ...
                'MarkerFaceColor', [0.2 0.7 0.2], 'MarkerEdgeColor', 'none');
        end
        if ~isempty(last_v)
            plot(ax, x(last_v), y(last_v), 'o', 'MarkerSize', 12, ...
                'MarkerFaceColor', [0.8 0.2 0.2], 'MarkerEdgeColor', 'none');
        end

        % Axis limits
        xlim(ax, [ac(1)-ar-5, ac(1)+ar+5]);
        ylim(ax, [ac(2)-ar-5, ac(2)+ar+5]);

        title(ax, sprintf('Fly %d / %d  |  AV threshold = %.0f deg/s  |  %d markers (min gap = %d frames)', ...
            fi, nf, thr, numel(marker_frames), mg), 'FontSize', 16);

        % Update labels
        lbl_fly.Text = sprintf('Fly %d / %d', fi, nf);
        lbl_val.Text = sprintf('%.0f deg/s', thr);
        lbl_count.Text = sprintf('%d supra-threshold markers', numel(marker_frames));
    end

% --- Callbacks ---
slider.ValueChangedFcn = @(src, ~) slider_changed(src, fig);
btn_prev.ButtonPushedFcn = @(~, ~) prev_fly(fig);
btn_next.ButtonPushedFcn = @(~, ~) next_fly(fig);

    function slider_changed(src, fig_handle)
        fig_handle.UserData.av_threshold = round(src.Value);
        draw(fig_handle);
    end

    function prev_fly(fig_handle)
        s = fig_handle.UserData;
        s.fly_idx = max(s.fly_idx - 1, 1);
        fig_handle.UserData = s;
        draw(fig_handle);
    end

    function next_fly(fig_handle)
        s = fig_handle.UserData;
        s.fly_idx = min(s.fly_idx + 1, s.n_flies);
        fig_handle.UserData = s;
        draw(fig_handle);
    end

% Initial draw
draw(fig);

fprintf('GUI ready. Use slider to adjust AV threshold, arrows to navigate flies.\n');
fprintf('  Red triangles = frames where |AV| > threshold (min %d frame gap)\n', MIN_GAP);
fprintf('  Green circle = start, red circle = end of trajectory\n');
