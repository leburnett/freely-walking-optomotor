%% MULTI_STRAIN_LOOP_LMM - Cross-strain LMM analysis of loop metrics vs distance
%
%  Fits a separate LMM per strain for 4 loop metrics as a function of
%  distance from the arena centre. Compares per-fly slope distributions
%  across strains and tests for significant differences from control.
%
%  Figures (18):
%    Fig 1-6:   Per-strain LMM subplots (area, duration, |heading|, aspect,
%               ang_diff, dist_from_prev)
%    Fig 7-12:  Overlay of all strains' population trend lines
%    Fig 13-18: Violin plots of per-fly slopes with statistical tests
%
%  Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 27).
%  Requires Statistics and Machine Learning Toolbox (fitlme, signrank, ranksum).

%% ================================================================
%  SECTION 1: Data loading across all strains
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
N_METRICS = 6;

control_strain = "jfrc100_es_shibire_kir";

metric_labels = {'Bbox area (mm^2)', 'Duration (s)', '|Heading change| (deg)', ...
                 'Aspect ratio', 'Mean |ang diff| (deg)', 'Dist from prev loop (mm)'};
metric_short  = {'area', 'duration', '|heading|', 'aspect', 'ang_diff', 'dist_prev'};

loop_opts.lookahead_frames = 75;
loop_opts.min_loop_frames  = 10;
loop_opts.fps              = FPS;
loop_opts.arena_center     = ARENA_CENTER;
loop_opts.arena_radius     = ARENA_R;

data_types = {'heading_data', 'x_data', 'y_data', 'dist_data', 'vel_data'};

% Discover strains, put control first
all_strain_names = fieldnames(DATA);
is_ctrl = strcmp(all_strain_names, control_strain);
strain_order = [all_strain_names(is_ctrl); sort(all_strain_names(~is_ctrl))];
n_strains = numel(strain_order);

fprintf('=== Multi-strain loop LMM analysis: %d strains ===\n', n_strains);

% Colour palette: control = grey, others from strain palette
strain_palette = [
    0.216 0.494 0.722;   % blue
    0.894 0.102 0.110;   % red
    0.302 0.686 0.290;   % green
    0.596 0.306 0.639;   % purple
    1.000 0.498 0.000;   % orange
    0.651 0.337 0.157;   % brown
    0.122 0.694 0.827;   % cyan
    0.890 0.467 0.761;   % pink
    0.737 0.741 0.133;   % olive
    0.090 0.745 0.812;   % teal
    0.682 0.780 0.910;   % light blue
    0.400 0.761 0.647;   % mint
    0.988 0.553 0.384;   % salmon
    0.553 0.627 0.796;   % slate blue
    0.906 0.541 0.765;   % orchid
    0.651 0.847 0.329;   % lime
    0.463 0.380 0.482;   % plum
    0.361 0.729 0.510;   % jade
    0.784 0.553 0.200];  % amber
n_pal = size(strain_palette, 1);

strain_colors = zeros(n_strains, 3);
col_idx = 0;
for si = 1:n_strains
    if strcmp(strain_order{si}, control_strain)
        strain_colors(si, :) = [0.7 0.7 0.7];
    else
        col_idx = col_idx + 1;
        strain_colors(si, :) = strain_palette(mod(col_idx-1, n_pal)+1, :);
    end
end

% Short display labels (remove _shibire_kir suffix)
strain_labels = cell(n_strains, 1);
for si = 1:n_strains
    strain_labels{si} = strrep(strain_order{si}, '_shibire_kir', '');
end

% --- Loop detection per strain ---
% Store per-strain: flat tables, per-fly slopes, LMM tables
stim_range = STIM_ON:STIM_OFF;

% Per-strain storage
strain_flat    = cell(n_strains, 1);   % each: struct with fly_id, dist, area, dur, hdg, aspect
strain_slopes  = cell(n_strains, 1);   % each: [n_flies x N_METRICS] per-fly OLS slopes
strain_n_flies = zeros(n_strains, 1);
strain_n_loops = zeros(n_strains, 1);

for si = 1:n_strains
    s_name = strain_order{si};

    % Check strain has female data for condition 1
    if ~isfield(DATA.(s_name), 'F')
        fprintf('  %s: no female data, skipping\n', s_name);
        continue;
    end
    rep1_field = 'R1_condition_1';
    if ~isfield(DATA.(s_name).F, rep1_field)
        fprintf('  %s: no condition 1, skipping\n', s_name);
        continue;
    end

    [rep_data, n_flies] = load_per_rep_data(DATA, s_name, 'F', 1, data_types);

    if n_flies == 0
        fprintf('  %s: 0 valid flies, skipping\n', s_name);
        continue;
    end

    % NaN-mask reversal window
    rep_data.x_data(:, MASK_START:MASK_END)       = NaN;
    rep_data.y_data(:, MASK_START:MASK_END)       = NaN;
    rep_data.heading_data(:, MASK_START:MASK_END) = NaN;

    x_stim       = rep_data.x_data(:, stim_range);
    y_stim       = rep_data.y_data(:, stim_range);
    heading_stim = rep_data.heading_data(:, stim_range);
    vel_stim     = rep_data.vel_data(:, stim_range);

    % Detect loops per fly
    f_fly_id = []; f_dist = []; f_area = []; f_dur = [];
    f_hdg = []; f_aspect = []; f_ang_diff = []; f_dist_prev = [];

    for f = 1:n_flies
        loop_opts.vel = vel_stim(f,:);
        loops = find_trajectory_loops( ...
            x_stim(f,:), y_stim(f,:), heading_stim(f,:), loop_opts);
        if loops.n_loops > 0
            nl = loops.n_loops;
            f_fly_id    = [f_fly_id;    repmat(f, nl, 1)];
            f_dist      = [f_dist;      loops.bbox_dist_center(:)];
            f_area      = [f_area;      loops.bbox_area(:)];
            f_dur       = [f_dur;       loops.duration_s(:)];
            f_hdg       = [f_hdg;       loops.cum_heading(:)];
            f_aspect    = [f_aspect;    loops.bbox_aspect(:)];
            f_ang_diff  = [f_ang_diff;  loops.mean_ang_diff(:)];
            f_dist_prev = [f_dist_prev; loops.dist_from_prev(:)];
        end
    end

    flat.fly_id    = f_fly_id;
    flat.dist      = f_dist;
    flat.area      = f_area;
    flat.dur       = f_dur;
    flat.hdg       = f_hdg;
    flat.aspect    = f_aspect;
    flat.ang_diff  = f_ang_diff;
    flat.dist_prev = f_dist_prev;
    strain_flat{si} = flat;

    % Per-fly OLS slopes
    metric_data = {f_area, f_dur, abs(f_hdg), f_aspect, f_ang_diff, f_dist_prev};
    slopes = NaN(n_flies, N_METRICS);
    for mi = 1:N_METRICS
        for f = 1:n_flies
            idx = (f_fly_id == f);
            d_f = f_dist(idx);
            m_f = metric_data{mi}(idx);
            v = ~isnan(d_f) & ~isnan(m_f);
            if sum(v) >= MIN_LOOPS_FOR_FIT
                p_f = polyfit(d_f(v), m_f(v), 1);
                slopes(f, mi) = p_f(1);
            end
        end
    end
    strain_slopes{si} = slopes;
    strain_n_flies(si) = n_flies;
    strain_n_loops(si) = numel(f_area);

    fprintf('  %s: %d flies, %d loops\n', s_name, n_flies, numel(f_area));
end

% Identify control index
ctrl_idx = find(strcmp(strain_order, control_strain));

%% ================================================================
%  SECTION 2: Per-strain LMM subplot figures (Figures 1-4)
%  ================================================================
%
%  For each metric: one figure with a subplot per strain.
%  Each subplot shows per-fly OLS lines (strain colour) and the LMM
%  population trend line (black).

fprintf('\n=== Fitting per-strain LMMs and plotting ===\n');

% Store LMM results for later sections
lmm_fe_slope = NaN(n_strains, N_METRICS);
lmm_fe_ci    = NaN(n_strains, N_METRICS, 2);  % lower, upper
lmm_fe_pval  = NaN(n_strains, N_METRICS);
lmm_fe_int   = NaN(n_strains, N_METRICS);     % intercept

lmm_vars = {'area', 'dur', 'abs_hdg', 'aspect'};

x_fit = linspace(0, ARENA_R, 100);

% Compute consistent y-limits per metric (98th percentile across all strains)
y_upper = NaN(1, N_METRICS);
for mi = 1:N_METRICS
    all_vals = [];
    for si = 1:n_strains
        if isempty(strain_flat{si}), continue; end
        switch mi
            case 1, vals = strain_flat{si}.area;
            case 2, vals = strain_flat{si}.dur;
            case 3, vals = abs(strain_flat{si}.hdg);
            case 4, vals = strain_flat{si}.aspect;
            case 5, vals = strain_flat{si}.ang_diff;
            case 6, vals = strain_flat{si}.dist_prev;
        end
        all_vals = [all_vals; vals(~isnan(vals))];
    end
    if ~isempty(all_vals)
        y_upper(mi) = prctile(all_vals, 98);
    else
        y_upper(mi) = 1;
    end
end

n_cols = ceil(sqrt(n_strains));
n_rows = ceil(n_strains / n_cols);

for mi = 1:N_METRICS
    figure('Position', [20+mi*15, 20+mi*15, n_cols*250, n_rows*220], ...
        'Name', sprintf('Fig %d: LMM subplots — %s', mi, metric_short{mi}));
    sgtitle(sprintf('Per-strain LMM: %s vs distance', metric_labels{mi}), 'FontSize', 18);

    for si = 1:n_strains
        subplot(n_rows, n_cols, si);
        hold on;

        flat = strain_flat{si};
        if isempty(flat) || isempty(flat.fly_id)
            title(sprintf('%s\n(no data)', strrep(strain_labels{si},'_','\_')), ...
                'FontSize', 9);
            set(gca, 'FontSize', 8, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 0.8);
            continue;
        end

        % Get metric values
        switch mi
            case 1, m_vals = flat.area;
            case 2, m_vals = flat.dur;
            case 3, m_vals = abs(flat.hdg);
            case 4, m_vals = flat.aspect;
            case 5, m_vals = flat.ang_diff;
            case 6, m_vals = flat.dist_prev;
        end

        col = strain_colors(si, :);
        slopes_si = strain_slopes{si};

        % Plot per-fly OLS lines
        has_fit = ~isnan(slopes_si(:, mi));
        n_flies_si = strain_n_flies(si);
        for f = find(has_fit)'
            idx = (flat.fly_id == f);
            d_f = flat.dist(idx);
            mf = m_vals(idx);
            v = ~isnan(d_f) & ~isnan(mf);
            if sum(v) >= MIN_LOOPS_FOR_FIT
                pf = polyfit(d_f(v), mf(v), 1);
                yf = pf(2) + pf(1) * x_fit;
                plot(x_fit, yf, '-', 'Color', [col 0.2], 'LineWidth', 0.8);
            end
        end

        % Fit LMM for this strain
        valid = ~isnan(m_vals) & ~isnan(flat.dist);
        n_valid = sum(valid);
        n_unique_flies = numel(unique(flat.fly_id(valid)));

        if n_valid >= 10 && n_unique_flies >= 3
            tbl_si = table( ...
                categorical(flat.fly_id(valid)), ...
                flat.dist(valid), ...
                m_vals(valid), ...
                'VariableNames', {'fly_id', 'distance', 'y'});

            % Try random slope model; fall back to random intercept if it fails
            try
                mdl = fitlme(tbl_si, 'y ~ 1 + distance + (1 + distance | fly_id)');
            catch
                try
                    mdl = fitlme(tbl_si, 'y ~ 1 + distance + (1 | fly_id)');
                catch
                    mdl = [];
                end
            end

            if ~isempty(mdl)
                fe = fixedEffects(mdl);
                [~, ~, fe_stats] = fixedEffects(mdl, 'DFMethod', 'satterthwaite');

                lmm_fe_int(si, mi)     = fe(1);
                lmm_fe_slope(si, mi)   = fe_stats.Estimate(2);
                lmm_fe_ci(si, mi, :)   = [fe_stats.Lower(2), fe_stats.Upper(2)];
                lmm_fe_pval(si, mi)    = fe_stats.pValue(2);

                % Population trend line (black)
                y_pop = fe(1) + fe(2) * x_fit;
                plot(x_fit, y_pop, '-k', 'LineWidth', 2.5);
            end
        end

        xlim([0 ARENA_R+5]);
        ylim([0 y_upper(mi)]);

        % Title with stats
        if ~isnan(lmm_fe_slope(si, mi))
            title(sprintf('%s (n=%d)\nslope=%.3f, p=%.1e', ...
                strrep(strain_labels{si},'_','\_'), strain_n_loops(si), ...
                lmm_fe_slope(si,mi), lmm_fe_pval(si,mi)), 'FontSize', 8);
        else
            title(sprintf('%s (n=%d)', ...
                strrep(strain_labels{si},'_','\_'), strain_n_loops(si)), 'FontSize', 8);
        end

        set(gca, 'FontSize', 8, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 0.8);
        if mod(si-1, n_cols) == 0
            ylabel(metric_labels{mi}, 'FontSize', 9);
        end
        if si > (n_rows-1)*n_cols
            xlabel('Dist (mm)', 'FontSize', 9);
        end
    end
end

%% ================================================================
%  SECTION 3: Overlay trend lines — all strains on one plot (Figs 7-12)
%  ================================================================

for mi = 1:N_METRICS
    figure('Position', [50+mi*20, 50+mi*20, 800, 550], ...
        'Name', sprintf('Fig %d: Overlay — %s', mi+N_METRICS, metric_short{mi}));
    hold on;

    legend_handles = [];
    legend_names   = {};

    % Plot non-control strains first, then control on top
    plot_order = [setdiff(1:n_strains, ctrl_idx), ctrl_idx];

    for si = plot_order
        if isnan(lmm_fe_slope(si, mi)), continue; end

        y_line = lmm_fe_int(si,mi) + lmm_fe_slope(si,mi) * x_fit;

        if si == ctrl_idx
            h = plot(x_fit, y_line, '-', 'Color', [0.5 0.5 0.5], 'LineWidth', 3);
        else
            h = plot(x_fit, y_line, '-', 'Color', strain_colors(si,:), 'LineWidth', 2);
        end
        legend_handles(end+1) = h;
        legend_names{end+1}   = strrep(strain_labels{si}, '_', '\_');
    end

    xlim([0 ARENA_R+5]);
    xlabel('Distance from centre (mm)', 'FontSize', 14);
    ylabel(metric_labels{mi}, 'FontSize', 14);
    title(sprintf('LMM population trend: %s vs distance', metric_labels{mi}), 'FontSize', 16);
    legend(legend_handles, legend_names, 'Location', 'best', 'FontSize', 9);
    set(gca, 'FontSize', 12, 'TickDir', 'out', 'Box', 'off', 'LineWidth', 1.2);
end

%% ================================================================
%  SECTION 4: Violin plots of per-fly slopes (Figures 9-12)
%  ================================================================
%
%  Two tests per non-control strain:
%    1. Wilcoxon signed-rank: does this strain's slopes differ from zero?
%    2. Wilcoxon rank-sum vs control: does this strain differ from control?
%  Both corrected with Bonferroni for the number of non-control strains.

n_non_ctrl = n_strains - 1;  % for Bonferroni correction

for mi = 1:N_METRICS
    % Build groups for plot_violin
    group_data   = cell(n_strains, 1);
    group_labels_v = cell(n_strains, 1);

    for si = 1:n_strains
        slopes_si = strain_slopes{si};
        if isempty(slopes_si)
            group_data{si} = [];
        else
            group_data{si} = slopes_si(~isnan(slopes_si(:,mi)), mi);
        end
        group_labels_v{si} = strrep(strain_labels{si}, '_', '\_');
    end

    % Violin plot
    vopts.colors     = strain_colors;
    vopts.ylabel_str = sprintf('Slope (%s / mm)', metric_short{mi});
    vopts.title_str  = sprintf('Per-fly OLS slopes: %s vs distance', metric_labels{mi});
    vopts.show_median = true;
    vopts.show_mean   = true;

    [fig_v, ax_v] = plot_violin(group_data, group_labels_v, vopts);
    set(fig_v, 'Name', sprintf('Fig %d: Violin — %s', mi+2*N_METRICS, metric_short{mi}));

    % Add zero reference line
    hold(ax_v, 'on');
    xline(ax_v, 0, 'YLimInclude', 'off');  % horizontal would need yline
    yline(ax_v, 0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 1);

    % Get control slopes
    ctrl_slopes = group_data{ctrl_idx};

    % Annotate statistics per strain
    y_lim = ylim(ax_v);
    y_range = y_lim(2) - y_lim(1);

    fprintf('\n--- %s: Per-fly slope statistics ---\n', metric_short{mi});
    fprintf('  %-30s  %6s  %10s  %10s  %12s  %12s\n', ...
        'Strain', 'n', 'mean_slope', 'p_vs_zero', 'p_vs_ctrl', 'p_adj_ctrl');

    for si = 1:n_strains
        s_slopes = group_data{si};
        n_s = numel(s_slopes);

        if n_s < 3
            fprintf('  %-30s  %6d  %10s  %10s  %12s  %12s\n', ...
                strain_order{si}, n_s, 'N/A', 'N/A', 'N/A', 'N/A');
            continue;
        end

        % Test 1: signed-rank — does this strain's slope differ from zero?
        [p_zero, ~] = signrank(s_slopes);

        % Test 2: rank-sum vs control (skip for control itself)
        if si == ctrl_idx
            p_vs_ctrl = NaN;
            p_adj = NaN;
        else
            if numel(ctrl_slopes) >= 3
                p_vs_ctrl = ranksum(s_slopes, ctrl_slopes);
                p_adj = min(p_vs_ctrl * n_non_ctrl, 1);  % Bonferroni
            else
                p_vs_ctrl = NaN;
                p_adj = NaN;
            end
        end

        % Significance stars for signed-rank (above violin)
        if p_zero < 0.001,     star = '***';
        elseif p_zero < 0.01,  star = '**';
        elseif p_zero < 0.05,  star = '*';
        else,                  star = 'ns'; end

        text(ax_v, si, y_lim(2) - y_range*0.02, star, ...
            'HorizontalAlignment', 'center', 'FontSize', 9, ...
            'FontWeight', 'bold', 'Color', 'k');

        % Significance marker for vs-control (below violin)
        % Use Unicode dagger (U+2020) which renders reliably in all interpreters
        if si ~= ctrl_idx && ~isnan(p_adj)
            dag = char(8224);  % Unicode dagger character
            if p_adj < 0.001,     star_c = [dag dag dag];
            elseif p_adj < 0.01,  star_c = [dag dag];
            elseif p_adj < 0.05,  star_c = dag;
            else,                 star_c = ''; end

            if ~isempty(star_c)
                text(ax_v, si, y_lim(1) + y_range*0.02, star_c, ...
                    'HorizontalAlignment', 'center', 'FontSize', 9, ...
                    'Color', [0.894 0.102 0.110]);
            end
        end

        fprintf('  %-30s  %6d  %10.4f  %10.3e  %12.3e  %12.3e\n', ...
            strain_order{si}, n_s, mean(s_slopes), p_zero, ...
            p_vs_ctrl, p_adj);
    end

    % Add legend for annotation symbols
    text(ax_v, n_strains + 0.3, y_lim(2) - y_range*0.02, ...
        '* p vs 0', 'FontSize', 8, 'Color', 'k');
    text(ax_v, n_strains + 0.3, y_lim(1) + y_range*0.02, ...
        [char(8224) ' p vs ctrl'], 'FontSize', 8, 'Color', [0.894 0.102 0.110]);
end

%% ================================================================
%  SECTION 5: Console summary table
%  ================================================================

fprintf('\n\n========================================================================\n');
fprintf('  MULTI-STRAIN LMM SUMMARY\n');
fprintf('========================================================================\n\n');

for mi = 1:N_METRICS
    fprintf('--- %s ---\n', metric_labels{mi});
    fprintf('  %-28s  %5s  %5s  %9s  %22s  %10s  %10s\n', ...
        'Strain', 'Flies', 'Loops', 'LMM slope', '95% CI', 'LMM p', 'p vs ctrl');

    ctrl_slopes = strain_slopes{ctrl_idx};
    if ~isempty(ctrl_slopes)
        ctrl_slopes_v = ctrl_slopes(~isnan(ctrl_slopes(:,mi)), mi);
    else
        ctrl_slopes_v = [];
    end

    for si = 1:n_strains
        s_slopes_v = [];
        if ~isempty(strain_slopes{si})
            s_slopes_v = strain_slopes{si}(~isnan(strain_slopes{si}(:,mi)), mi);
        end

        if si == ctrl_idx
            p_vs = NaN;
        elseif numel(s_slopes_v) >= 3 && numel(ctrl_slopes_v) >= 3
            p_vs = min(ranksum(s_slopes_v, ctrl_slopes_v) * n_non_ctrl, 1);
        else
            p_vs = NaN;
        end

        if ~isnan(lmm_fe_slope(si, mi))
            ci_str = sprintf('[%.4f, %.4f]', lmm_fe_ci(si,mi,1), lmm_fe_ci(si,mi,2));
            fprintf('  %-28s  %5d  %5d  %9.4f  %22s  %10.2e  %10.2e\n', ...
                strain_order{si}, strain_n_flies(si), strain_n_loops(si), ...
                lmm_fe_slope(si,mi), ci_str, lmm_fe_pval(si,mi), p_vs);
        else
            fprintf('  %-28s  %5d  %5d  %9s  %22s  %10s  %10.2e\n', ...
                strain_order{si}, strain_n_flies(si), strain_n_loops(si), ...
                'N/A', 'N/A', 'N/A', p_vs);
        end
    end
    fprintf('\n');
end

fprintf('========================================================================\n');
fprintf('  %d strains, 18 figures generated\n', n_strains);
fprintf('  Frames 750-850 excluded (stimulus reversal)\n');
fprintf('  * = signed-rank vs zero; dagger = rank-sum vs control (Bonferroni)\n');
fprintf('========================================================================\n');
