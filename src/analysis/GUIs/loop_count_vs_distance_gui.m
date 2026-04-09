%% LOOP_COUNT_VS_DISTANCE_GUI - Self-intersection loop count vs distance across strains
%
%  Shows the mean number of self-intersection loops per fly in each
%  distance bin, with SEM shading. Control strain (jfrc100_es_shibire_kir)
%  is always shown in black. Checkboxes toggle other strains on/off.
%
%  Uses the same strain order and colour scheme as figS1.m.
%  Data: condition 1, protocol 27, females, stimulus period (frames 300-1200).
%
%  Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 27).
%
%  See also: find_trajectory_loops, viewdist_segment_metrics_gui

%% Setup

if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

ARENA_CENTER = [528, 520] / 4.1691;
ARENA_R = 120;
FPS = 30;
STIM_ON  = 300;
STIM_OFF = 1200;

sex = 'F';
condition = 1;
control_strain = 'jfrc100_es_shibire_kir';

n_dist_bins = 10;
bin_edges = linspace(0, ARENA_R, n_dist_bins + 1);
bin_centres = (bin_edges(1:end-1) + bin_edges(2:end)) / 2;

loop_opts.lookahead_frames = 75;
loop_opts.min_loop_frames  = 5;
loop_opts.fps              = FPS;
loop_opts.arena_center     = ARENA_CENTER;
loop_opts.arena_radius     = ARENA_R;

%% Strain order and colours (from figS1.m)

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

figS1_colours = [[220,  40,  30]; ...
    [220,  85,  30]; ...
    [220, 130,  35]; ...
    [220, 175,  40]; ...
    [220, 210,  50]; ...
    [190, 170,  60]; ...
    [164, 182, 120]; ...
    [134, 187, 139]; ...
    [104, 185, 158]; ...
    [ 82, 176, 176]; ...
    [ 72, 160, 192]; ...
    [ 74, 138, 202]; ...
    [ 86, 114, 204]; ...
    [108,  92, 198]; ...
    [132,  74, 186]; ...
    [154,  60, 168]; ...
    [ 40,  40,  40]; ...
    [180, 180, 180]] ./ 255;

% Build colour map (same reverse mapping as figS1.m)
n_exp = numel(figS1_strain_order) - 1;
figS1_color_map = containers.Map();
exp_counter = 0;
for i = 1:numel(figS1_strain_order)
    s = figS1_strain_order{i};
    if strcmp(s, control_strain)
        figS1_color_map(s) = figS1_colours(18, :);
    else
        exp_counter = exp_counter + 1;
        figS1_color_map(s) = figS1_colours(n_exp - exp_counter + 1, :);
    end
end

%% Pre-compute loop counts per distance bin for all strains

fprintf('=== Pre-computing self-intersection loop counts (protocol 27, cond %d) ===\n', condition);

strain_list = {};
strain_colors = [];
strain_n_flies = [];
strain_mean_count = {};   % {si} = [1 x n_dist_bins]
strain_sem_count  = {};

for si = 1:numel(figS1_strain_order)
    s_name = figS1_strain_order{si};
    if ~isfield(DATA, s_name), continue; end
    if ~isfield(DATA.(s_name), sex), continue; end

    data_strain = DATA.(s_name).(sex);
    n_exp_cohorts = length(data_strain);
    rep1_str = strcat('R1_condition_', string(condition));
    if ~isfield(data_strain, rep1_str), continue; end

    % Collect per-fly loop distances
    fly_loop_dists = {};  % cell array, one vector per fly

    for exp_idx = 1:n_exp_cohorts
        for rep_idx = 1:2
            rep_str = sprintf('R%d_condition_%d', rep_idx, condition);
            if ~isfield(data_strain(exp_idx), rep_str), continue; end
            rep_data = data_strain(exp_idx).(rep_str);
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

                x_fly = rep_data.x_data(f, sr);
                y_fly = rep_data.y_data(f, sr);
                h_fly = rep_data.heading_data(f, sr);
                v_fly = vel_rep(f, sr);
                loop_opts.vel = v_fly;

                loops = find_trajectory_loops(x_fly, y_fly, h_fly, loop_opts);
                if loops.n_loops > 0
                    fly_loop_dists{end+1} = loops.bbox_dist_center(:);
                else
                    fly_loop_dists{end+1} = [];
                end
            end
        end
    end

    n_flies_total = numel(fly_loop_dists);
    if n_flies_total < 3, continue; end

    % Bin loop counts per fly
    count_bins = zeros(n_flies_total, n_dist_bins);
    for fi = 1:n_flies_total
        dists_fi = fly_loop_dists{fi};
        for bi = 1:n_dist_bins
            count_bins(fi, bi) = sum(dists_fi >= bin_edges(bi) & dists_fi < bin_edges(bi+1));
        end
    end

    m_count = mean(count_bins, 1);
    s_count = std(count_bins, 0, 1) / sqrt(n_flies_total);

    col = figS1_color_map(s_name);

    strain_list{end+1} = s_name;
    strain_colors = [strain_colors; col];
    strain_n_flies = [strain_n_flies; n_flies_total];
    strain_mean_count{end+1} = m_count;
    strain_sem_count{end+1}  = s_count;

    total_loops = sum(cellfun(@numel, fly_loop_dists));
    fprintf('  %s: %d flies, %d loops\n', s_name, n_flies_total, total_loops);
end

n_strains = numel(strain_list);
fprintf('  %d strains with sufficient data\n', n_strains);

% Put control first
ctrl_idx = find(strcmp(strain_list, control_strain));
other_idx = setdiff(1:n_strains, ctrl_idx, 'stable');
reorder = [ctrl_idx, other_idx];
strain_list       = strain_list(reorder);
strain_colors     = strain_colors(reorder, :);
strain_n_flies    = strain_n_flies(reorder);
strain_mean_count = strain_mean_count(reorder);
strain_sem_count  = strain_sem_count(reorder);

%% ======================== GUI ========================

fig = uifigure('Name', 'Loop Count vs Distance — Cross-Strain', ...
    'Position', [50 50 1000 600]);

% Main axes
ax_main = uiaxes(fig, 'Position', [60 60 600 490]);
hold(ax_main, 'on');
set(ax_main, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
xlabel(ax_main, 'Distance from centre (mm)', 'FontSize', 14);
ylabel(ax_main, 'Loops per fly (mean)', 'FontSize', 14);
title(ax_main, 'Self-intersection loops vs distance from centre', 'FontSize', 15);

% Checkboxes panel
pnl = uipanel(fig, 'Position', [690 10 290 580], 'Title', 'Strains', ...
    'FontSize', 13, 'FontWeight', 'bold');

cb_handles = gobjects(n_strains, 1);
y_pos = 535;

for si = 1:n_strains
    s_name = strain_list{si};
    display_name = strrep(strrep(s_name, '_shibire_kir', ''), '_', ' ');
    n_f = strain_n_flies(si);

    if si == 1
        % Control — always visible, label only
        uilabel(pnl, 'Position', [10 y_pos 270 20], ...
            'Text', sprintf('%s (n=%d) [control]', display_name, n_f), ...
            'FontSize', 10, 'FontWeight', 'bold', 'FontColor', strain_colors(si,:));
        cb_handles(si) = uicheckbox(pnl, 'Position', [0 0 1 1], ...
            'Value', true, 'Visible', 'off');
    else
        cb_handles(si) = uicheckbox(pnl, 'Position', [10 y_pos 270 20], ...
            'Text', sprintf('%s (n=%d)', display_name, n_f), ...
            'Value', false, 'FontSize', 10, 'FontColor', strain_colors(si,:));
        cb_handles(si).ValueChangedFcn = @(~,~) redraw(fig);
    end

    y_pos = y_pos - 22;
end

% Select/clear buttons
btn_all = uibutton(pnl, 'push', 'Text', 'Select All', ...
    'Position', [10 y_pos-10 130 28], 'FontSize', 10);
btn_none = uibutton(pnl, 'push', 'Text', 'Clear All', ...
    'Position', [150 y_pos-10 130 28], 'FontSize', 10);

btn_all.ButtonPushedFcn  = @(~,~) set_all_cb(fig, true);
btn_none.ButtonPushedFcn = @(~,~) set_all_cb(fig, false);

% State
state.ax = ax_main;
state.strain_list = strain_list;
state.strain_colors = strain_colors;
state.strain_mean_count = strain_mean_count;
state.strain_sem_count  = strain_sem_count;
state.cb_handles = cb_handles;
state.bin_centres = bin_centres;
state.n_strains = n_strains;
fig.UserData = state;

% --- Draw function ---
    function redraw(fig_handle)
        s = fig_handle.UserData;
        cla(s.ax); hold(s.ax, 'on');

        % Always draw control first
        draw_strain(s.ax, s.bin_centres, s.strain_mean_count{1}, ...
            s.strain_sem_count{1}, s.strain_colors(1,:));

        % Draw checked strains
        for si_r = 2:s.n_strains
            if s.cb_handles(si_r).Value
                draw_strain(s.ax, s.bin_centres, s.strain_mean_count{si_r}, ...
                    s.strain_sem_count{si_r}, s.strain_colors(si_r,:));
            end
        end

        xlim(s.ax, [0 125]);
    end

    function draw_strain(ax_h, bc, bm, bs, col)
        valid = ~isnan(bm);
        if sum(valid) < 2, return; end
        bc_v = bc(valid);  bm_v = bm(valid);  bs_v = bs(valid);

        fill(ax_h, [bc_v, fliplr(bc_v)], ...
            [bm_v + bs_v, fliplr(bm_v - bs_v)], ...
            col, 'FaceAlpha', 0.15, 'EdgeColor', 'none');
        plot(ax_h, bc_v, bm_v, '-o', 'Color', col, ...
            'LineWidth', 1.5, 'MarkerSize', 4, 'MarkerFaceColor', col);
    end

    function set_all_cb(fig_handle, val)
        s = fig_handle.UserData;
        for si_s = 2:s.n_strains  % skip control (always on)
            s.cb_handles(si_s).Value = val;
        end
        redraw(fig_handle);
    end

% Initial draw
redraw(fig);

fprintf('\nGUI ready.\n');
fprintf('  Control strain always shown (black)\n');
fprintf('  Tick strains to overlay their loop count profiles\n');
fprintf('  Same strain order and colours as figS1\n');
