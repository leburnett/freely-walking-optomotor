%% VIEWDIST_SEGMENT_METRICS_GUI - Compare view-dist segment metrics across strains
%
%  Shows 4 plots of segment metrics vs distance from centre (binned means
%  with SEM shading), segmented using the view-dist peak method:
%    - Bbox area, Aspect ratio, Tortuosity, Duration
%
%  The control strain (jfrc100_es_shibire_kir) is always shown in black.
%  Checkboxes allow toggling other strains on/off for comparison.
%
%  Segmentation parameters: 10-frame smoothing, 5 mm prominence.
%  Data: condition 1, stimulus period (frames 300-1200), females only.
%
%  Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 27).

%% Setup

if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_27');
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
condition = 1;

control_strain = "jfrc100_es_shibire_kir";

n_dist_bins = 10;
bin_edges = linspace(0, MAX_DIST_CENTER, n_dist_bins + 1);
bin_centres = (bin_edges(1:end-1) + bin_edges(2:end)) / 2;

%% Pre-compute segment metrics for all strains

all_strain_names = fieldnames(DATA);
fprintf('=== Pre-computing view-dist segment metrics for all strains ===\n');

% Strain order and colours (from cmap_config)
cmaps_gui = cmap_config();
figS1_colours = cmaps_gui.strains.colors;

figS1_strain_order = { ...
    'ss2575_LPC1_shibire_kir', ...
    'ss1209_DCH_VCH_shibire_kir', ...
    'ss34318_Am1_shibire_kir', ...
    'ss01027_H2_shibire_kir', ...
    'ss26283_H1_shibire_kir', ...
    'ss02594_TmY5a_shibire_kir', ...
    'ss03722_Tm5Y_shibire_kir', ...
    'ss00395_TmY3_shibire_kir', ...
    'ss00326_Pm2ab_shibire_kir', ...
    'ss00297_Dm4_shibire_kir', ...
    'ss2603_TmY20_shibire_kir', ...
    'ss2571_T5_shibire_kir', ...
    'ss2344_T4_shibire_kir', ...
    'ss324_t4t5_shibire_kir', ...
    'ss00316_Mi4_shibire_kir', ...
    'l1l4_jfrc100_shibire_kir', ...
    'jfrc100_es_shibire_kir'};

% Assign colours using the same reverse mapping as figS1.m:
% last experimental strain gets colour row 1, first gets row 16, control gets row 18
n_exp = numel(figS1_strain_order) - 1;  % exclude control
figS1_color_map = containers.Map();
exp_counter = 0;
for i = 1:numel(figS1_strain_order)
    s = figS1_strain_order{i};
    if strcmp(s, control_strain)
        figS1_color_map(s) = figS1_colours(18, :);  % light grey for control
    else
        exp_counter = exp_counter + 1;
        figS1_color_map(s) = figS1_colours(n_exp - exp_counter + 1, :);
    end
end

% Process strains in figS1 order, control last (will be moved to first later)
strain_list = {};
strain_bins = struct();
strain_colors = [];
strain_n_segs = [];

for si = 1:numel(figS1_strain_order)
    strain = figS1_strain_order{si};
    if ~isfield(DATA, strain), continue; end
    if ~isfield(DATA.(strain), sex), continue; end

    rep1_str = strcat('R1_condition_', string(condition));
    if ~isfield(DATA.(strain).(sex), rep1_str), continue; end

    try
        data_types = {'x_data', 'y_data', 'dist_data', 'vel_data', 'view_dist'};
        [rep_data, n_flies] = load_per_rep_data(DATA, strain, sex, condition, data_types);
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

    % Bin the metrics
    fld_names = {'area', 'aspect', 'tort', 'dur'};
    bins = struct();
    for fi_idx = 1:4
        fld = fld_names{fi_idx};
        m = flat.(fld);
        d = flat.dist;
        bm = NaN(1, n_dist_bins);
        bs = NaN(1, n_dist_bins);
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

    col = figS1_color_map(strain);

    strain_list{end+1} = strain;
    strain_bins.(strain) = bins;
    strain_colors = [strain_colors; col];
    strain_n_segs = [strain_n_segs; n_segs];

    fprintf('  %s: %d segments\n', strain, n_segs);
end

n_strains = numel(strain_list);
fprintf('  %d strains with sufficient data\n', n_strains);

% Put control first in the list
ctrl_idx = find(strcmp(strain_list, control_strain));
other_idx = setdiff(1:n_strains, ctrl_idx, 'stable');
reorder = [ctrl_idx, other_idx];
strain_list   = strain_list(reorder);
strain_colors = strain_colors(reorder, :);
strain_n_segs = strain_n_segs(reorder);

%% ======================== GUI ========================

metric_fields = {'area', 'aspect', 'tort', 'dur'};
metric_labels = {'Bbox area (mm^2)', 'Aspect ratio', ...
                 'Tortuosity (path/displacement)', 'Duration (s)'};

fig = uifigure('Name', 'View-Dist Segment Metrics — Cross-Strain', ...
    'Position', [50 50 1300 750]);

% 2x2 axes for the 4 metrics
ax = gobjects(4, 1);
ax_positions = [50  410 420 290;    % top-left
                520 410 420 290;    % top-right
                50  60  420 290;    % bottom-left
                520 60  420 290];   % bottom-right

for mi = 1:4
    ax(mi) = uiaxes(fig, 'Position', ax_positions(mi,:));
    hold(ax(mi), 'on');
    set(ax(mi), 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
    xlabel(ax(mi), 'Distance from centre (mm)', 'FontSize', 14);
    ylabel(ax(mi), metric_labels{mi}, 'FontSize', 14);
    title(ax(mi), metric_labels{mi}, 'FontSize', 15);
end

% Checkboxes panel — narrow strip on the right
pnl = uipanel(fig, 'Position', [970 50 310 650], 'Title', 'Strains', ...
    'FontSize', 13, 'FontWeight', 'bold');

cb_handles = gobjects(n_strains, 1);
for si = 1:n_strains
    s_name = strain_list{si};
    display_name = strrep(strrep(s_name, '_shibire_kir', ''), '_', ' ');
    n_seg = strain_n_segs(si);

    y_pos = 620 - si * 22;
    if si == 1
        % Control — always on, no checkbox (just a label)
        uilabel(pnl, 'Position', [10 y_pos 260 20], ...
            'Text', sprintf('%s (n=%d) [control]', display_name, n_seg), ...
            'FontSize', 10, 'FontWeight', 'bold', 'FontColor', strain_colors(si,:));
        cb_handles(si) = uicheckbox(pnl, 'Position', [0 0 1 1], ...
            'Value', true, 'Visible', 'off');  % hidden, always true
    else
        cb_handles(si) = uicheckbox(pnl, 'Position', [10 y_pos 260 20], ...
            'Text', sprintf('%s (n=%d)', display_name, n_seg), ...
            'Value', false, 'FontSize', 10, 'FontColor', strain_colors(si,:));
        cb_handles(si).ValueChangedFcn = @(~,~) redraw(fig);
    end
end

% Store state
state.ax = ax;
state.strain_list = strain_list;
state.strain_bins = strain_bins;
state.strain_colors = strain_colors;
state.strain_n_segs = strain_n_segs;
state.cb_handles = cb_handles;
state.bin_centres = bin_centres;
state.metric_fields = metric_fields;
state.metric_labels = metric_labels;
fig.UserData = state;

% --- Draw function ---
    function redraw(fig_handle)
        s = fig_handle.UserData;
        n_s = numel(s.strain_list);

        for mi_r = 1:4
            cla(s.ax(mi_r));
            hold(s.ax(mi_r), 'on');

            fld = s.metric_fields{mi_r};

            % Always draw control first (index 1)
            draw_strain_line(s.ax(mi_r), s.bin_centres, ...
                s.strain_bins.(s.strain_list{1}).([fld '_mean']), ...
                s.strain_bins.(s.strain_list{1}).([fld '_sem']), ...
                s.strain_colors(1,:), 1.0);

            % Draw checked strains
            for si_r = 2:n_s
                if s.cb_handles(si_r).Value
                    draw_strain_line(s.ax(mi_r), s.bin_centres, ...
                        s.strain_bins.(s.strain_list{si_r}).([fld '_mean']), ...
                        s.strain_bins.(s.strain_list{si_r}).([fld '_sem']), ...
                        s.strain_colors(si_r,:), 0.8);
                end
            end

            xlim(s.ax(mi_r), [0 115]);
        end
    end

    function draw_strain_line(ax_h, bc, bm, bs, col, alpha_sem)
        valid = ~isnan(bm) & ~isnan(bs);
        if sum(valid) < 2, return; end
        bc_v = bc(valid);  bm_v = bm(valid);  bs_v = bs(valid);

        fill(ax_h, [bc_v, fliplr(bc_v)], ...
            [bm_v + bs_v, fliplr(bm_v - bs_v)], ...
            col, 'FaceAlpha', 0.15 * alpha_sem, 'EdgeColor', 'none');
        plot(ax_h, bc_v, bm_v, '-o', 'Color', col, ...
            'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', col);
    end

% Initial draw
redraw(fig);
