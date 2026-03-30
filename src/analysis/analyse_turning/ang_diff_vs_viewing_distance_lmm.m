%% ANG_DIFF_VS_VIEWING_DISTANCE_LMM - Frame-level angular difference vs distance
%
%  Analyses how the angular difference between heading and travelling
%  direction varies with the fly's distance from the arena centre, using
%  frame-level data from within detected loops.
%
%  Unlike the loop-level analysis (which uses one bbox_dist_center per loop),
%  this uses every frame within each loop, giving the fly's actual distance
%  from centre at each time point paired with the 5-frame smoothed |angular
%  difference| at that frame. Only moving frames (speed >= 0.5 mm/s) are
%  included, since travel direction is undefined when the fly is stationary.
%
%  Fits a separate LMM per strain:
%    smoothed_ang_diff ~ distance + (1 + distance | fly_id)
%
%  Figures:
%    Fig 1: Per-strain LMM subplots (per-fly OLS lines + population trend)
%    Fig 2: Overlay of all strains' population trend lines
%    Fig 3: Violin plot of per-fly OLS slopes with statistical tests
%
%  Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 27).
%  Requires Statistics and Machine Learning Toolbox (fitlme, signrank, ranksum).

%% ================================================================
%  SECTION 1: Data loading, angular diff computation, loop extraction
%  ================================================================

if ~exist('DATA', 'var')
    cfg = get_config();
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

ARENA_CENTER = [528, 520] / 4.1691;
ARENA_R  = 120;
FPS      = 30;
STIM_ON  = 300;
STIM_OFF = 1200;
MASK_START = 750;
MASK_END   = 850;
MIN_LOOPS_FOR_FIT = 5;
SPEED_THRESHOLD = 0.5;   % mm/s — exclude stationary frames
SMOOTH_WIN = 5;           % frames for angular diff moving average

control_strain = "jfrc100_es_shibire_kir";

data_types = {'heading_data', 'x_data', 'y_data', 'dist_data', 'vel_data', 'view_dist'};

loop_opts.lookahead_frames = 75;
loop_opts.min_loop_frames  = 10;
loop_opts.fps              = FPS;
loop_opts.arena_center     = ARENA_CENTER;
loop_opts.arena_radius     = ARENA_R;

stim_range = STIM_ON:STIM_OFF;

% Discover strains, put control first
all_strain_names = fieldnames(DATA);
is_ctrl = strcmp(all_strain_names, control_strain);
strain_order = [all_strain_names(is_ctrl); sort(all_strain_names(~is_ctrl))];
n_strains = numel(strain_order);

% Colour palette
strain_palette = [
    0.216 0.494 0.722;  0.894 0.102 0.110;  0.302 0.686 0.290;
    0.596 0.306 0.639;  1.000 0.498 0.000;  0.651 0.337 0.157;
    0.122 0.694 0.827;  0.890 0.467 0.761;  0.737 0.741 0.133;
    0.090 0.745 0.812;  0.682 0.780 0.910;  0.400 0.761 0.647;
    0.988 0.553 0.384;  0.553 0.627 0.796;  0.906 0.541 0.765;
    0.651 0.847 0.329;  0.463 0.380 0.482;  0.361 0.729 0.510;
    0.784 0.553 0.200];
n_pal = size(strain_palette, 1);

strain_colors = zeros(n_strains, 3);
col_idx = 0;
for si = 1:n_strains
    if strcmp(strain_order{si}, control_strain)
        strain_colors(si,:) = [0.7 0.7 0.7];
    else
        col_idx = col_idx + 1;
        strain_colors(si,:) = strain_palette(mod(col_idx-1, n_pal)+1, :);
    end
end

strain_labels = cellfun(@(s) strrep(s, '_shibire_kir', ''), strain_order, 'UniformOutput', false);

ctrl_idx = find(strcmp(strain_order, control_strain));

fprintf('=== Angular diff vs viewing distance (frame-level, within loops) ===\n');
fprintf('  %d strains, smooth window = %d frames\n\n', n_strains, SMOOTH_WIN);

% --- Per-strain: extract frame-level data from within loops ---
%
% For each fly, for each detected loop:
%   1. Compute travel direction from x,y via 3-point central difference
%   2. Compute |heading - travel_dir|, apply 5-frame moving average
%   3. Extract dist_data (fly's distance from centre) at each frame
%   4. Keep only frames where speed >= threshold
%
% This gives (distance, smoothed_ang_diff) pairs at frame resolution.

strain_frame_data = cell(n_strains, 1);   % struct: fly_id, dist, ang_diff
strain_fly_slopes = cell(n_strains, 1);   % per-fly OLS slopes
strain_n_flies    = zeros(n_strains, 1);
strain_n_frames   = zeros(n_strains, 1);

for si = 1:n_strains
    s_name = strain_order{si};

    if ~isfield(DATA.(s_name), 'F'), continue; end
    if ~isfield(DATA.(s_name).F, 'R1_condition_1'), continue; end

    [rep_data, n_flies] = load_per_rep_data(DATA, s_name, 'F', 1, data_types);
    if n_flies == 0, continue; end

    % NaN-mask reversal window
    rep_data.x_data(:, MASK_START:MASK_END)       = NaN;
    rep_data.y_data(:, MASK_START:MASK_END)       = NaN;
    rep_data.heading_data(:, MASK_START:MASK_END) = NaN;

    x_stim       = rep_data.x_data(:, stim_range);
    y_stim       = rep_data.y_data(:, stim_range);
    heading_stim = rep_data.heading_data(:, stim_range);
    vel_stim     = rep_data.vel_data(:, stim_range);
    vdist_stim   = rep_data.view_dist(:, stim_range);

    n_frames_stim = size(x_stim, 2);
    dt = 1 / FPS;

    % Accumulators for frame-level data
    acc_fly_id   = [];
    acc_dist     = [];
    acc_ang_diff = [];

    for f = 1:n_flies
        % --- Compute travel direction from position ---
        xf = x_stim(f,:);
        yf = y_stim(f,:);

        vx = NaN(1, n_frames_stim);
        vy = NaN(1, n_frames_stim);
        % Forward diff at first frame
        vx(1) = (xf(2) - xf(1)) / dt;
        vy(1) = (yf(2) - yf(1)) / dt;
        % Central diff for interior
        vx(2:end-1) = (xf(3:end) - xf(1:end-2)) / (2*dt);
        vy(2:end-1) = (yf(3:end) - yf(1:end-2)) / (2*dt);
        % Backward diff at last frame
        vx(end) = (xf(end) - xf(end-1)) / dt;
        vy(end) = (yf(end) - yf(end-1)) / dt;

        travel_dir = atan2d(vy, vx);

        % Heading wrapped to [0, 360)
        heading_wrap = mod(heading_stim(f,:), 360);

        % Signed angular difference, wrapped to [-180, 180]
        ang_diff_raw = mod(heading_wrap - travel_dir + 180, 360) - 180;
        abs_ang_diff = abs(ang_diff_raw);

        % 5-frame smoothed |angular diff| (NaN out stationary frames first)
        abs_ang_smooth = abs_ang_diff;
        abs_ang_smooth(vel_stim(f,:) < SPEED_THRESHOLD) = NaN;
        abs_ang_smooth = movmean(abs_ang_smooth, SMOOTH_WIN, 'omitnan');

        % Detect loops for this fly (need loop boundaries)
        loop_opts.vel = vel_stim(f,:);
        loops = find_trajectory_loops(xf, yf, heading_stim(f,:), loop_opts);

        if loops.n_loops == 0, continue; end

        % Extract frame-level data from within each loop
        for k = 1:loops.n_loops
            sf = loops.start_frame(k);
            ef = loops.end_frame(k);
            frames = sf:ef;

            d_frames  = vdist_stim(f, frames);
            ad_frames = abs_ang_smooth(frames);
            v_frames  = vel_stim(f, frames);

            % Keep only moving, non-NaN frames
            valid = v_frames >= SPEED_THRESHOLD & ...
                    ~isnan(d_frames) & ~isnan(ad_frames);

            n_valid = sum(valid);
            if n_valid >= 2
                acc_fly_id   = [acc_fly_id;   repmat(f, n_valid, 1)];
                acc_dist     = [acc_dist;     d_frames(valid)'];
                acc_ang_diff = [acc_ang_diff; ad_frames(valid)'];
            end
        end
    end

    fdata.fly_id   = acc_fly_id;
    fdata.dist     = acc_dist;
    fdata.ang_diff = acc_ang_diff;
    strain_frame_data{si} = fdata;
    strain_n_flies(si)  = n_flies;
    strain_n_frames(si) = numel(acc_dist);

    % Per-fly OLS slopes
    slopes = NaN(n_flies, 1);
    for f = 1:n_flies
        idx = (acc_fly_id == f);
        if sum(idx) >= 20  % need reasonable frame count per fly
            d_f = acc_dist(idx);
            a_f = acc_ang_diff(idx);
            v = ~isnan(d_f) & ~isnan(a_f);
            if sum(v) >= 20
                p_f = polyfit(d_f(v), a_f(v), 1);
                slopes(f) = p_f(1);
            end
        end
    end
    strain_fly_slopes{si} = slopes;

    n_with_slopes = sum(~isnan(slopes));
    fprintf('  %s: %d flies, %d frames within loops, %d flies with slopes\n', ...
        s_name, n_flies, numel(acc_dist), n_with_slopes);
end

%% ================================================================
%  SECTION 2: Per-strain LMM subplots (Figure 1)
%  ================================================================

fprintf('\n=== Fitting per-strain LMMs (frame-level) ===\n');

lmm_fe_slope = NaN(n_strains, 1);
lmm_fe_int   = NaN(n_strains, 1);
lmm_fe_ci    = NaN(n_strains, 2);
lmm_fe_pval  = NaN(n_strains, 1);

x_fit = linspace(0, 250, 100);

n_cols = ceil(sqrt(n_strains));
n_rows = ceil(n_strains / n_cols);

figure('Position', [20, 20, n_cols*250, n_rows*220], ...
    'Name', 'Fig 1: LMM subplots — ang diff vs viewing distance');
sgtitle('|Angular diff| vs viewing distance (frame-level, within loops)', ...
    'FontSize', 16);

for si = 1:n_strains
    subplot(n_rows, n_cols, si);
    hold on;

    fdata = strain_frame_data{si};
    if isempty(fdata) || isempty(fdata.fly_id)
        title(sprintf('%s\n(no data)', strrep(strain_labels{si},'_','\_')), 'FontSize', 9);
        set(gca, 'FontSize', 8, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 0.8);
        continue;
    end

    col = strain_colors(si,:);
    slopes = strain_fly_slopes{si};
    n_flies_si = strain_n_flies(si);

    % Per-fly OLS lines
    for f = 1:n_flies_si
        if isnan(slopes(f)), continue; end
        idx = (fdata.fly_id == f);
        d_f = fdata.dist(idx);
        a_f = fdata.ang_diff(idx);
        v = ~isnan(d_f) & ~isnan(a_f);
        if sum(v) >= 20
            p_f = polyfit(d_f(v), a_f(v), 1);
            yf = p_f(2) + p_f(1) * x_fit;
            plot(x_fit, yf, '-', 'Color', [col 0.2], 'LineWidth', 0.8);
        end
    end

    % Fit LMM
    valid = ~isnan(fdata.dist) & ~isnan(fdata.ang_diff);
    n_valid = sum(valid);
    n_unique = numel(unique(fdata.fly_id(valid)));

    if n_valid >= 30 && n_unique >= 3
        tbl = table( ...
            categorical(fdata.fly_id(valid)), ...
            fdata.dist(valid), ...
            fdata.ang_diff(valid), ...
            'VariableNames', {'fly_id', 'distance', 'ang_diff'});

        try
            mdl = fitlme(tbl, 'ang_diff ~ 1 + distance + (1 + distance | fly_id)');
        catch
            try
                mdl = fitlme(tbl, 'ang_diff ~ 1 + distance + (1 | fly_id)');
            catch
                mdl = [];
            end
        end

        if ~isempty(mdl)
            fe = fixedEffects(mdl);
            [~, ~, fe_stats] = fixedEffects(mdl, 'DFMethod', 'satterthwaite');

            lmm_fe_int(si)    = fe(1);
            lmm_fe_slope(si)  = fe_stats.Estimate(2);
            lmm_fe_ci(si,:)   = [fe_stats.Lower(2), fe_stats.Upper(2)];
            lmm_fe_pval(si)   = fe_stats.pValue(2);

            y_pop = fe(1) + fe(2) * x_fit;
            plot(x_fit, y_pop, '-k', 'LineWidth', 2.5);

            fprintf('  %s: slope=%.4f [%.4f, %.4f], p=%.3e\n', ...
                strain_order{si}, fe_stats.Estimate(2), ...
                fe_stats.Lower(2), fe_stats.Upper(2), fe_stats.pValue(2));
        end
    end

    xlim([0 250]);
    ylim([0 90]);

    if ~isnan(lmm_fe_slope(si))
        title(sprintf('%s (n=%d)\nslope=%.3f, p=%.1e', ...
            strrep(strain_labels{si},'_','\_'), strain_n_frames(si), ...
            lmm_fe_slope(si), lmm_fe_pval(si)), 'FontSize', 8);
    else
        title(sprintf('%s (n=%d)', ...
            strrep(strain_labels{si},'_','\_'), strain_n_frames(si)), 'FontSize', 8);
    end

    set(gca, 'FontSize', 8, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 0.8);
    if mod(si-1, n_cols) == 0
        ylabel('|Ang diff| (deg)', 'FontSize', 9);
    end
    if si > (n_rows-1)*n_cols
        xlabel('Viewing dist (mm)', 'FontSize', 9);
    end
end

%% ================================================================
%  SECTION 3: Overlay trend lines (Figure 2)
%  ================================================================

figure('Position', [70, 70, 800, 550], ...
    'Name', 'Fig 2: Overlay — ang diff vs viewing distance');
hold on;

legend_handles = [];
legend_names   = {};
plot_order = [setdiff(1:n_strains, ctrl_idx), ctrl_idx];

for si = plot_order
    if isnan(lmm_fe_slope(si)), continue; end
    y_line = lmm_fe_int(si) + lmm_fe_slope(si) * x_fit;
    if si == ctrl_idx
        h = plot(x_fit, y_line, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 3);
    else
        h = plot(x_fit, y_line, '-', 'Color', strain_colors(si,:), 'LineWidth', 2);
    end
    legend_handles(end+1) = h;
    legend_names{end+1}   = strrep(strain_labels{si}, '_', '\_');
end

xlim([0 ARENA_R+5]);
xlabel('Viewing distance (mm)', 'FontSize', 14);
ylabel('Smoothed |angular diff| (deg)', 'FontSize', 14);
title('LMM population trend: |angular diff| vs viewing distance (within loops)', 'FontSize', 16);
legend(legend_handles, legend_names, 'Location', 'best', 'FontSize', 9);
set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);

%% ================================================================
%  SECTION 4: Violin plot of per-fly slopes (Figure 3)
%  ================================================================

n_non_ctrl = n_strains - 1;

group_data   = cell(n_strains, 1);
group_labels_v = cell(n_strains, 1);

for si = 1:n_strains
    slopes = strain_fly_slopes{si};
    if isempty(slopes)
        group_data{si} = [];
    else
        group_data{si} = slopes(~isnan(slopes));
    end
    group_labels_v{si} = strrep(strain_labels{si}, '_', '\_');
end

vopts.colors     = strain_colors;
vopts.ylabel_str = 'Slope (|ang diff| deg / mm)';
vopts.title_str  = 'Per-fly slopes: |angular diff| vs viewing distance';
vopts.show_median = true;
vopts.show_mean   = true;

[fig_v, ax_v] = plot_violin(group_data, group_labels_v, vopts);
set(fig_v, 'Name', 'Fig 3: Violin — ang diff slopes');

hold(ax_v, 'on');
yline(ax_v, 0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

ctrl_slopes = group_data{ctrl_idx};
y_lim = ylim(ax_v);
y_range = y_lim(2) - y_lim(1);

fprintf('\n--- Per-fly slope statistics: |ang diff| vs viewing distance ---\n');
fprintf('  %-30s  %6s  %10s  %10s  %12s\n', ...
    'Strain', 'n', 'mean_slope', 'p_vs_zero', 'p_adj_ctrl');

dag = char(8224);

for si = 1:n_strains
    s_slopes = group_data{si};
    n_s = numel(s_slopes);

    if n_s < 3
        fprintf('  %-30s  %6d  %10s  %10s  %12s\n', ...
            strain_order{si}, n_s, 'N/A', 'N/A', 'N/A');
        continue;
    end

    [p_zero, ~] = signrank(s_slopes);

    if si == ctrl_idx
        p_adj = NaN;
    elseif numel(ctrl_slopes) >= 3
        p_adj = min(ranksum(s_slopes, ctrl_slopes) * n_non_ctrl, 1);
    else
        p_adj = NaN;
    end

    % Stars for signed-rank (above)
    if p_zero < 0.001, star = '***';
    elseif p_zero < 0.01, star = '**';
    elseif p_zero < 0.05, star = '*';
    else, star = 'ns'; end

    text(ax_v, si, y_lim(2) - y_range*0.02, star, ...
        'HorizontalAlignment', 'center', 'FontSize', 9, ...
        'FontWeight', 'bold', 'Color', 'k');

    % Daggers for vs-control (below)
    if si ~= ctrl_idx && ~isnan(p_adj)
        if p_adj < 0.001, star_c = [dag dag dag];
        elseif p_adj < 0.01, star_c = [dag dag];
        elseif p_adj < 0.05, star_c = dag;
        else, star_c = ''; end

        if ~isempty(star_c)
            text(ax_v, si, y_lim(1) + y_range*0.02, star_c, ...
                'HorizontalAlignment', 'center', 'FontSize', 9, ...
                'Color', [0.894 0.102 0.110]);
        end
    end

    fprintf('  %-30s  %6d  %10.4f  %10.3e  %12.3e\n', ...
        strain_order{si}, n_s, mean(s_slopes), p_zero, p_adj);
end

text(ax_v, n_strains + 0.3, y_lim(2) - y_range*0.02, ...
    '* p vs 0', 'FontSize', 8, 'Color', 'k');
text(ax_v, n_strains + 0.3, y_lim(1) + y_range*0.02, ...
    [dag ' p vs ctrl'], 'FontSize', 8, 'Color', [0.894 0.102 0.110]);

%% Summary

fprintf('\n=============================================\n');
fprintf('  ANALYSIS COMPLETE\n');
fprintf('  Frame-level |angular diff| vs viewing distance\n');
fprintf('  5-frame smoothed, speed >= %.1f mm/s\n', SPEED_THRESHOLD);
fprintf('  %d strains, 3 figures generated\n', n_strains);
fprintf('=============================================\n');
