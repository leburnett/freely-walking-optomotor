%% VIEWDIST_SEGMENT_METRICS_P31_GUI - View-dist segment metrics across conditions (protocol 31)
%
%  Shows 4 plots of segment metrics vs distance from centre (binned means
%  with SEM shading), segmented using the view-dist peak method.
%
%  Two strains with checkboxes per condition:
%    jfrc100_es_shibire_kir (control): blue (60°) / pink (15°)
%    ss324_t4t5_shibire_kir:           green (60°) / orange (15°)
%
%  Conditions:
%    1-4:  60-deg gratings at 1, 2, 4, 8 Hz
%    5:    60-deg flicker control
%    6-9:  15-deg gratings at 4, 8, 16, 32 Hz
%    10:   15-deg flicker control
%
%  Segmentation: 10-frame smoothing, 5 mm prominence.
%
%  Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 31).

%% Setup

if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_31');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

ARENA_CENTER = [528, 520] / 4.1691;
FPS = 30;
STIM_ON  = 300;
STIM_OFF = 1200;

SMOOTH_WIN      = 10;
MIN_PROMINENCE  = 5;
MIN_SEG_FRAMES  = 5;
MAX_DIST_CENTER = 110;

sex = 'F';

n_dist_bins = 10;
bin_edges = linspace(0, MAX_DIST_CENTER, n_dist_bins + 1);
bin_centres = (bin_edges(1:end-1) + bin_edges(2:end)) / 2;

%% Strain and condition definitions

strains = {"jfrc100_es_shibire_kir", "ss324_t4t5_shibire_kir"};
strain_short = {"es (control)", "T4/T5"};
n_strains = 2;

cond_labels = { ...
    '60° 1Hz', '60° 2Hz', '60° 4Hz', '60° 8Hz', '60° flicker', ...
    '15° 4Hz', '15° 8Hz', '15° 16Hz', '15° 32Hz', '15° flicker'};
n_conditions = 10;

% Colours: strain 1 = blue/pink (control), strain 2 = green/orange (T4/T5)
% Each is [n_conditions x 3]
colors_ctrl = [ ...
    173, 216, 230;   % cond 1 — light blue
     82, 173, 227;   % cond 2
     31, 120, 180;   % cond 3
     61,  82, 159;   % cond 4 — dark blue
    231, 158, 190;   % cond 5 — 60° flicker
    243, 207, 226;   % cond 6 — pale pink
    231, 158, 190;   % cond 7
    223, 113, 167;   % cond 8
    215,  48, 139;   % cond 9 — dark magenta
    200, 200, 200]./ 255;   % cond 10 — grey

colors_t4t5 = [ ...
    190, 230, 170;   % cond 1 — light green
    130, 200, 100;   % cond 2
     60, 160,  60;   % cond 3
     30, 110,  30;   % cond 4 — dark green
    180, 210, 140;   % cond 5 — 60° flicker (muted green)
    255, 225, 150;   % cond 6 — pale yellow
    255, 195, 100;   % cond 7 — light orange
    240, 150,  50;   % cond 8 — orange
    220, 100,  20;   % cond 9 — dark orange
    180, 180, 180]./ 255;   % cond 10 — grey

all_colors = cat(3, colors_ctrl, colors_t4t5);  % [10 x 3 x 2]

%% Pre-compute segment metrics for both strains, all conditions

fprintf('=== Pre-computing view-dist segment metrics (protocol 31) ===\n');

fld_names = {'area', 'aspect', 'tort', 'dur'};

% Store as all_bins{strain_idx, cond_idx} = bins struct
all_bins = cell(n_strains, n_conditions);
all_n_segs = zeros(n_strains, n_conditions);

for si = 1:n_strains
    s_name = strains{si};
    if ~isfield(DATA, s_name), continue; end
    if ~isfield(DATA.(s_name), sex), continue; end

    fprintf('\n  %s:\n', s_name);

    for ci = 1:n_conditions
        rep1_str = strcat('R1_condition_', string(ci));
        if ~isfield(DATA.(s_name).(sex), rep1_str), continue; end

        try
            data_types = {'x_data', 'y_data', 'dist_data', 'vel_data', 'view_dist'};
            [rep_data, n_flies] = load_per_rep_data(DATA, s_name, sex, ci, data_types);
        catch
            continue;
        end
        if n_flies < 3, continue; end

        stim_range = STIM_ON:min(STIM_OFF, size(rep_data.x_data, 2));
        x_s  = rep_data.x_data(:, stim_range);
        y_s  = rep_data.y_data(:, stim_range);
        vd_s = rep_data.view_dist(:, stim_range);

        [flat, n_segs, ~] = segment_viewdist_peaks( ...
            x_s, y_s, vd_s, ARENA_CENTER, FPS, ...
            SMOOTH_WIN, MIN_PROMINENCE, MIN_SEG_FRAMES, MAX_DIST_CENTER);

        if n_segs < 10, continue; end

        all_n_segs(si, ci) = n_segs;

        bins = struct();
        for fi_idx = 1:4
            fld = fld_names{fi_idx};
            m = flat.(fld);  d = flat.dist;
            bm = NaN(1, n_dist_bins);  bs = NaN(1, n_dist_bins);
            for bi = 1:n_dist_bins
                in_b = d >= bin_edges(bi) & d < bin_edges(bi+1) & ~isnan(m);
                if sum(in_b) >= 5
                    bm(bi) = mean(m(in_b));
                    bs(bi) = std(m(in_b)) / sqrt(sum(in_b));
                end
            end
            bins.([fld '_mean']) = bm;
            bins.([fld '_sem'])  = bs;
        end

        all_bins{si, ci} = bins;
        fprintf('    Cond %d (%s): %d segs\n', ci, cond_labels{ci}, n_segs);
    end
end

%% ======================== GUI ========================

metric_fields = {'area', 'aspect', 'tort', 'dur'};
metric_labels_plot = {'Bbox area (mm^2)', 'Aspect ratio', ...
                      'Tortuosity (path/displacement)', 'Duration (s)'};

fig = uifigure('Name', 'Protocol 31 — Segment Metrics by Condition', ...
    'Position', [50 50 1300 800]);

% 2x2 axes
ax = gobjects(4, 1);
ax_positions = [50  440 430 310;
                530 440 430 310;
                50  60  430 310;
                530 60  430 310];

for mi = 1:4
    ax(mi) = uiaxes(fig, 'Position', ax_positions(mi,:));
    hold(ax(mi), 'on');
    set(ax(mi), 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
    xlabel(ax(mi), 'Distance from centre (mm)', 'FontSize', 14);
    ylabel(ax(mi), metric_labels_plot{mi}, 'FontSize', 14);
    title(ax(mi), metric_labels_plot{mi}, 'FontSize', 15);
end

% Checkboxes panel
pnl = uipanel(fig, 'Position', [980 10 300 780], 'Title', 'Conditions', ...
    'FontSize', 13, 'FontWeight', 'bold');

% Create checkboxes: 2 strains × 10 conditions
cb_handles = gobjects(n_strains, n_conditions);
y_pos = 730;

for si = 1:n_strains
    % Strain header
    if si == 1
        hdr_col = [0.1 0.3 0.6];
    else
        hdr_col = [0.15 0.45 0.15];
    end
    uilabel(pnl, 'Position', [10 y_pos 280 20], ...
        'Text', sprintf('%s', strain_short{si}), ...
        'FontSize', 12, 'FontWeight', 'bold', 'FontColor', hdr_col);
    y_pos = y_pos - 20;

    for ci = 1:n_conditions
        % Sub-header for 15-deg group
        if ci == 6
            y_pos = y_pos - 6;
        end

        n_seg = all_n_segs(si, ci);
        col = all_colors(ci, :, si);

        lbl = sprintf('%s (n=%d)', cond_labels{ci}, n_seg);
        cb_handles(si, ci) = uicheckbox(pnl, 'Position', [15 y_pos 270 18], ...
            'Text', lbl, 'Value', false, 'FontSize', 9, ...
            'FontColor', col * 0.8);
        cb_handles(si, ci).ValueChangedFcn = @(~,~) redraw(fig);

        % Disable if no data
        if n_seg == 0
            cb_handles(si, ci).Enable = 'off';
        end

        y_pos = y_pos - 18;
    end

    y_pos = y_pos - 10;  % gap between strains
end

% Select/clear buttons
btn_all = uibutton(pnl, 'push', 'Text', 'Select All', ...
    'Position', [10 y_pos-5 135 28], 'FontSize', 10);
btn_none = uibutton(pnl, 'push', 'Text', 'Clear All', ...
    'Position', [155 y_pos-5 135 28], 'FontSize', 10);

btn_all.ButtonPushedFcn = @(~,~) set_all_cb(fig, true);
btn_none.ButtonPushedFcn = @(~,~) set_all_cb(fig, false);

% State
state.ax = ax;
state.all_bins = all_bins;
state.all_colors = all_colors;
state.all_n_segs = all_n_segs;
state.cb_handles = cb_handles;
state.bin_centres = bin_centres;
state.metric_fields = metric_fields;
state.n_strains = n_strains;
state.n_conditions = n_conditions;
fig.UserData = state;

% --- Draw function ---
    function redraw(fig_handle)
        s = fig_handle.UserData;

        for mi_r = 1:4
            cla(s.ax(mi_r));
            hold(s.ax(mi_r), 'on');

            fld = s.metric_fields{mi_r};

            for si_r = 1:s.n_strains
                for ci_r = 1:s.n_conditions
                    if ~s.cb_handles(si_r, ci_r).Value, continue; end
                    bins_rc = s.all_bins{si_r, ci_r};
                    if isempty(bins_rc), continue; end

                    bm = bins_rc.([fld '_mean']);
                    bs = bins_rc.([fld '_sem']);
                    col = s.all_colors(ci_r, :, si_r);

                    valid = ~isnan(bm) & ~isnan(bs);
                    if sum(valid) < 2, continue; end
                    bc_v = s.bin_centres(valid);
                    bm_v = bm(valid);
                    bs_v = bs(valid);

                    fill(s.ax(mi_r), [bc_v, fliplr(bc_v)], ...
                        [bm_v + bs_v, fliplr(bm_v - bs_v)], ...
                        col, 'FaceAlpha', 0.15, 'EdgeColor', 'none');
                    plot(s.ax(mi_r), bc_v, bm_v, '-o', 'Color', col, ...
                        'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', col);
                end
            end

            xlim(s.ax(mi_r), [0 115]);
        end
    end

    function set_all_cb(fig_handle, val)
        s = fig_handle.UserData;
        for si_s = 1:s.n_strains
            for ci_s = 1:s.n_conditions
                if strcmp(s.cb_handles(si_s, ci_s).Enable, 'on')
                    s.cb_handles(si_s, ci_s).Value = val;
                end
            end
        end
        redraw(fig_handle);
    end

% Initial draw
redraw(fig);

fprintf('\nGUI ready.\n');
fprintf('  Control: blue (60°) / pink (15°)\n');
fprintf('  T4/T5:   green (60°) / orange (15°)\n');
fprintf('  Tick conditions to overlay, Select/Clear All at bottom\n');
