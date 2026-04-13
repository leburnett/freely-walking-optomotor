%% figS2 — NorpA rescue experiment violin plots (Protocol 27 Norp)
%
% Loads data from protocol_27_Norp results and generates violin plots for
% each standard metric across all strains for condition 1.
%
% Strains include NorpA mutant/rescue lines, ES control, T4T5, and L1L4.
%
% REQUIREMENTS:
%   - Protocol 27 Norp results in oaky_cokey project folder
%   - Functions: comb_data_across_cohorts_cond, combine_timeseries_across_exp,
%     plot_violin, get_ylb_from_data_type
%
% See also: figS1, fig4

%% 1 — Configuration & data loading

protocol_dir_norp = '/Users/burnettl/Documents/Projects/oaky_cokey/results/protocol_27_Norp';

if ~exist('DATA_NORP', 'var') || isempty(fieldnames(DATA_NORP))
    fprintf('Loading Protocol 27 Norp data from: %s\n', protocol_dir_norp);
    DATA_NORP = comb_data_across_cohorts_cond(protocol_dir_norp);
end

sex = 'F';
cond_idx = 1;

%% 2 — Strain ordering & colours

% Order strains: controls, then NorpA/NorpAw paired by Rh driver
strain_order_norp = { ...
    'jfrc100_es_shibire_kir', ...
    'l1l4_jfrc100_shibire_kir', ...
    'NorpA_plus_plus', ...
    'NorpA_UAS_Norp_plus', ...
    'NorpA_UAS_Norp_Rh1_Gal4', ...
    'NorpAw_UAS_Norp_Rh1_Gal4', ...
    'NorpA_UAS_Norp_Rh2_Gal4', ...
    'NorpAw_UAS_Norp_Rh2_Gal4', ...
    'NorpA_UAS_Norp_Rh5_Rh6_Gal4', ...
    'NorpAw_UAS_Norp_Rh5_Rh6_Gal4', ...
};

% Check which strains are actually in the data and adjust
available_strains = fieldnames(DATA_NORP);
% Map folder names (with hyphens) to field names (with underscores)
strain_order_valid = {};
for i = 1:numel(strain_order_norp)
    s = strain_order_norp{i};
    % Try exact match first, then try with hyphen-to-underscore
    if ismember(s, available_strains)
        strain_order_valid{end+1} = s; %#ok<AGROW>
    else
        s_alt = strrep(s, '_', '-');  % won't be a valid field name
        % Check all available strains for a match after normalising
        found = false;
        for j = 1:numel(available_strains)
            if strcmp(strrep(available_strains{j}, '-', '_'), s)
                strain_order_valid{end+1} = available_strains{j}; %#ok<AGROW>
                found = true;
                break;
            end
        end
        if ~found
            fprintf('Warning: strain %s not found in DATA_NORP, skipping.\n', s);
        end
    end
end

n_strains = numel(strain_order_valid);
fprintf('Plotting %d strains.\n', n_strains);

% Custom colourmap (from cmap_config)
cmaps = cmap_config();
violin_colors = cmaps.norpa_rescue.colors;

% Display labels
display_labels = strrep(strain_order_valid, '_', '-');

%% 3 — Standard metrics (same 6 as fig4 heatmap)

% --- Hard-coded y-limits for each violin plot ---
% Edit these values to ensure median text labels are visible.
% Set to [] to use auto-limits.
violin_ylims = { ...
    [];   % Metric 1: Avg FV during stimulus
    [];   % Metric 2: FV change at onset
    [];   % Metric 3: Avg turning during stimulus
    [];   % Metric 4: Early turning (first 5s CW)
    [];   % Metric 5: Centring at end of stimulus
    [];   % Metric 6: Centring after 10s
};

metric_spec = { ...
    "fv_data",    0,  300:1200,   'Avg FV during stimulus'; ...
    "av_data",  0,  300:1200,   'Avg AV during stimulus'; ...
    "curv_data",  0,  300:1200,   'Avg turning during stimulus'; ...
    "dist_data",  1,  1170:1200,  'Centring at end of stimulus'; ...
};
n_metrics = size(metric_spec, 1);

%% 4 — Generate violin plots

for mi = 1:n_metrics
    dt       = metric_spec{mi, 1};
    delta    = metric_spec{mi, 2};
    frm_rng  = metric_spec{mi, 3};
    m_title  = metric_spec{mi, 4};

    group_data   = cell(n_strains, 1);

    for si = 1:n_strains
        strain = strain_order_valid{si};
        if ~isfield(DATA_NORP.(strain), sex); continue; end
        data_s = DATA_NORP.(strain).(sex);

        cond_data = combine_timeseries_across_exp(data_s, cond_idx, dt);

        if delta == 1
            cond_data = (cond_data - cond_data(:, 300)) * -1;
        end

        if dt == "av_data" || dt == "curv_data"
            cond_data(:, 750:1200) = cond_data(:, 750:1200) * -1;
        end

        % Metric 2 is special: difference between two frame ranges
        if iscell(frm_rng)
            rng_before = frm_rng{1};
            rng_after  = frm_rng{2};
            val_before = nanmean(cond_data(:, rng_before), 2); %#ok<NANMEAN>
            val_after  = nanmean(cond_data(:, rng_after), 2); %#ok<NANMEAN>
            group_data{si} = val_after - val_before;
        else
            group_data{si} = nanmean(cond_data(:, frm_rng), 2); %#ok<NANMEAN>
        end
    end

    ylb = get_ylb_from_data_type(dt, delta);

    opts = struct();
    opts.colors       = violin_colors;
    opts.ylabel_str   = ylb;
    opts.marker_size  = 15;
    opts.marker_alpha = 0.4;
    opts.violin_alpha = 0.35;
    opts.show_median  = true;
    opts.violin_width = 0.35;
    opts.plot_ES_median = false;
    opts.med_text_sz = 14;

    plot_violin(group_data, display_labels, opts);
    title(m_title, 'FontSize', 14);

    if ~isempty(violin_ylims{mi})
        ylim(violin_ylims{mi});
    else
        yl = ylim; ylim([yl(1), yl(2) + diff(yl) * 0.15]);
    end

    hold on; yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5); hold off;

    ax = gca; ax.FontSize = 14;
    f = gcf; f.Position = [90   101   394   400];
end

%% 5 — Time series plots (4 strain groups x 4 metrics)
%
% Each group includes ES control + 2 NorpA lines, plotted as mean +/- SEM.
% Colours match the violin plot assignments.

% Build colour lookup: strain name → RGB from violin_colors
strain_color_map = containers.Map();
for i = 1:numel(strain_order_norp)
    strain_color_map(strain_order_norp{i}) = violin_colors(i, :);
end

% Define the 4 strain groups (each includes ES as first entry)
ts_groups = { ...
    {'NorpA_plus_plus', 'NorpA_UAS_Norp_plus'}, ...
        'NorpA controls'; ...
    {'NorpA_UAS_Norp_Rh1_Gal4', 'NorpAw_UAS_Norp_Rh1_Gal4'}, ...
        'Rh1 rescue'; ...
    {'NorpA_UAS_Norp_Rh2_Gal4', 'NorpAw_UAS_Norp_Rh2_Gal4'}, ...
        'Rh2 rescue'; ...
    {'NorpA_UAS_Norp_Rh5_Rh6_Gal4', 'NorpAw_UAS_Norp_Rh5_Rh6_Gal4'}, ...
        'Rh5/Rh6 rescue'; ...
};
n_groups = size(ts_groups, 1);

xmax = 1800;

for mi = 1:n_metrics
    dt      = metric_spec{mi, 1};
    delta   = metric_spec{mi, 2};
    m_title = metric_spec{mi, 4};

    [dt_resolved, delta_resolved] = resolve_delta_data_type(dt);
    if delta_resolved > 0, delta = delta_resolved; end

    for gi = 1:n_groups
        grp_strains = ts_groups{gi, 1};
        grp_title   = ts_groups{gi, 2};
        n_s = numel(grp_strains);

        % First pass: compute data-driven y-limits across all strains in group
        y_min =  Inf;
        y_max = -Inf;
        grp_means = cell(n_s, 1);
        grp_sems  = cell(n_s, 1);

        for si = 1:n_s
            strain = grp_strains{si};
            % Resolve strain name to actual field name in DATA_NORP
            if isfield(DATA_NORP, strain)
                sn = strain;
            else
                sn = '';
                for j = 1:numel(available_strains)
                    if strcmp(strrep(available_strains{j}, '-', '_'), strain)
                        sn = available_strains{j};
                        break;
                    end
                end
            end
            if isempty(sn) || ~isfield(DATA_NORP.(sn), sex); continue; end

            data_s = DATA_NORP.(sn).(sex);
            cond_data = combine_timeseries_across_exp(data_s, cond_idx, dt_resolved);
            if delta
                cond_data = (cond_data - cond_data(:, 300)) * -1;
            end

            mean_data = cond_data;
            mean_all  = nanmean(mean_data); %#ok<NANMEAN>
            mean_all = movmean(mean_all, 6);
            sem_all   = nanstd(mean_data) / sqrt(size(mean_data, 1)); %#ok<NANSTD>

            grp_means{si} = mean_all;
            grp_sems{si}  = sem_all;

            y_min = min(y_min, min(mean_all - sem_all, [], 'omitnan'));
            y_max = max(y_max, max(mean_all + sem_all, [], 'omitnan'));
        end

        y_pad = (y_max - y_min) * 0.10;
        % rng_yl = [y_min - y_pad, y_max + y_pad];
        if dt == "dist_data" 
            rng_yl = [-15 27];
        elseif dt == "av_data" 
            rng_yl = [-170 170];
        elseif dt == "curv_data" 
            rng_yl = [-170 170];
        elseif dt == "fv_data" 
            rng_yl = [0 20];
        end 

        figure('Name', sprintf('TS %s: %s', grp_title, m_title), ...
            'Position', [233 511 641 460]);
        hold on;

        % Plot each strain
        for si = 1:n_s
            if isempty(grp_means{si}); continue; end
            strain = grp_strains{si};
            col = strain_color_map(strain);
            mean_all = grp_means{si};
            sem_all  = grp_sems{si};
            nf = numel(mean_all);
            x = 1:nf;

            plot(x, mean_all + sem_all, 'w', 'LineWidth', 1);
            plot(x, mean_all - sem_all, 'w', 'LineWidth', 1);
            patch([x fliplr(x)], [mean_all + sem_all, fliplr(mean_all - sem_all)], ...
                col, 'FaceAlpha', 0.25, 'EdgeColor', 'none');
            plot(mean_all, 'Color', col, 'LineWidth', 2.5);
        end

        % Reference lines
        plot([300 300], rng_yl, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
        plot([750 750], rng_yl, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
        plot([1200 1200], rng_yl, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
        plot([0 xmax], [0 0], 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);

        ylb = get_ylb_from_data_type(dt_resolved, delta);
        ylabel(ylb);
        xlabel('Time (s)');
        xticks([0, 300, 600, 900, 1200, 1500, 1800]);
        xticklabels({'-10', '0', '10', '20', '30', '40', '50'});
        ylim(rng_yl);
        xlim([0 xmax]);

        % Stimulus annotation rectangles at top
        yl = ylim;
        yrange = yl(2) - yl(1);
        rect_h = yrange / 20;
        ylim([yl(1) yl(2) + rect_h]);
        rect_y = yl(2);

        rectangle('Position', [0, rect_y, 300, rect_h], ...
            'FaceColor', [0.4 0.4 0.4], 'EdgeColor', 'k');
        bar_width = 15;
        x_positions = 300:bar_width:(1200 - bar_width);
        for i = 1:length(x_positions)
            if mod(i, 2) == 1, fc = 'w'; else, fc = 'k'; end
            rectangle('Position', [x_positions(i), rect_y, bar_width, rect_h], ...
                'FaceColor', fc, 'EdgeColor', 'k');
        end
        rectangle('Position', [1200, rect_y, xmax - 1200, rect_h], ...
            'FaceColor', [0.4 0.4 0.4], 'EdgeColor', 'k');

        box off;
        set(gca, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 16);
        f = gcf;
        f.Position = [181   549   796   402];
    end
end


%% Movement towards the edge during phototaxis condition

photo_idx = 12;
mi = 4; 

xmax = 1800;

dt      = metric_spec{mi, 1};
delta   = metric_spec{mi, 2};
m_title = metric_spec{mi, 4};

[dt_resolved, delta_resolved] = resolve_delta_data_type(dt);
if delta_resolved > 0, delta = delta_resolved; end

for gi = 1:n_groups
    grp_strains = ts_groups{gi, 1};
    grp_title   = ts_groups{gi, 2};
    n_s = numel(grp_strains);

    % First pass: compute data-driven y-limits across all strains in group
    y_min =  Inf;
    y_max = -Inf;
    grp_means = cell(n_s, 1);
    grp_sems  = cell(n_s, 1);

    for si = 1:n_s
        strain = grp_strains{si};
        % Resolve strain name to actual field name in DATA_NORP
        if isfield(DATA_NORP, strain)
            sn = strain;
        else
            sn = '';
            for j = 1:numel(available_strains)
                if strcmp(strrep(available_strains{j}, '-', '_'), strain)
                    sn = available_strains{j};
                    break;
                end
            end
        end
        if isempty(sn) || ~isfield(DATA_NORP.(sn), sex); continue; end

        data_s = DATA_NORP.(sn).(sex);
        cond_data = combine_timeseries_across_exp(data_s, photo_idx, dt_resolved);
        if delta
            cond_data = (cond_data - cond_data(:, 300)) * -1;
        end

        mean_data = cond_data;
        mean_all  = nanmean(mean_data); %#ok<NANMEAN>
        mean_all = movmean(mean_all, 6);
        sem_all   = nanstd(mean_data) / sqrt(size(mean_data, 1)); %#ok<NANSTD>

        grp_means{si} = mean_all;
        grp_sems{si}  = sem_all;

        y_min = min(y_min, min(mean_all - sem_all, [], 'omitnan'));
        y_max = max(y_max, max(mean_all + sem_all, [], 'omitnan'));
    end

    y_pad = (y_max - y_min) * 0.10;
    % rng_yl = [y_min - y_pad, y_max + y_pad];
    if dt == "dist_data" 
        rng_yl = [-15 27];
    elseif dt == "av_data" 
        rng_yl = [-170 170];
    elseif dt == "curv_data" 
        rng_yl = [-170 170];
    elseif dt == "fv_data" 
        rng_yl = [0 20];
    end 

    figure('Name', sprintf('TS %s: %s', grp_title, m_title), ...
        'Position', [233 511 641 460]);
    hold on;

    % Plot each strain
    for si = 1:n_s
        if isempty(grp_means{si}); continue; end
        strain = grp_strains{si};
        col = strain_color_map(strain);
        mean_all = grp_means{si};
        sem_all  = grp_sems{si};
        nf = numel(mean_all);
        x = 1:nf;

        plot(x, mean_all + sem_all, 'w', 'LineWidth', 1);
        plot(x, mean_all - sem_all, 'w', 'LineWidth', 1);
        patch([x fliplr(x)], [mean_all + sem_all, fliplr(mean_all - sem_all)], ...
            col, 'FaceAlpha', 0.25, 'EdgeColor', 'none');
        plot(mean_all, 'Color', col, 'LineWidth', 2.5);
    end

    % Reference lines
    plot([300 300], rng_yl, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
    plot([750 750], rng_yl, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
    plot([1200 1200], rng_yl, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
    plot([0 xmax], [0 0], 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);

    ylb = get_ylb_from_data_type(dt_resolved, delta);
    ylabel(ylb);
    xlabel('Time (s)');
    xticks([0, 300, 600, 900, 1200, 1500, 1800]);
    xticklabels({'-10', '0', '10', '20', '30', '40', '50'});
    ylim(rng_yl);
    xlim([0 xmax]);

    % Stimulus annotation rectangles at top
    yl = ylim;
    yrange = yl(2) - yl(1);
    rect_h = yrange / 20;
    ylim([yl(1) yl(2) + rect_h]);
    rect_y = yl(2);

    rectangle('Position', [0, rect_y, 300, rect_h], ...
        'FaceColor', [0.4 0.4 0.4], 'EdgeColor', 'k');
    rectangle('Position', [300, rect_y, 900, rect_h], ...
        'FaceColor', [1 1 1], 'EdgeColor', 'k');
    rectangle('Position', [1200, rect_y, xmax - 1200, rect_h], ...
        'FaceColor', [0.4 0.4 0.4], 'EdgeColor', 'k');

    box off;
    set(gca, 'TickDir', 'out', 'LineWidth', 1.2, 'FontSize', 16);
    f = gcf;
    f.Position = [181   549   796   402];
end

