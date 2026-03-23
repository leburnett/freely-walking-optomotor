%% TEMP_LOOP_METRICS_PLOTS - Violin and scatter plots for trajectory loop metrics
%
% Requires all_loops and flat_table in workspace (from temp_loop_segmentation_gui).
%
% Generates:
%   1. Violin plots (per-fly metrics by strain):
%      - Bounding box area (median per fly)
%      - Number of loops per fly
%      - Loop duration (median per fly)
%
%   2. Multi-subplot scatter plots + slope bar charts:
%      - Bbox area vs distance from centre (already exists, included for completeness)
%      - Duration vs distance from centre
%      - Aspect ratio vs distance from centre
%
% Functions used:
%   plot_violin.m
%   plot_metric_vs_distance_subplots.m

%% Check workspace

if ~exist('flat_table', 'var') || ~exist('all_loops', 'var')
    error(['flat_table and all_loops not found in workspace. ', ...
           'Run temp_loop_segmentation_gui first.']);
end

control_strain = "jfrc100_es_shibire_kir";

%% ============================================================
%  PART 1: Per-fly summary for violin plots
%  ============================================================
%
%  The flat_table has one row per LOOP. For violin plots we want one
%  data point per FLY. So we aggregate: median bbox_area per fly,
%  count of loops per fly, median duration per fly.

fprintf('=== Aggregating per-fly metrics from flat_table ===\n');

% Each unique fly is identified by strain + a within-strain fly index.
% Build a unique fly key from the flat_table.
% We need to reconstruct per-fly identity. The easiest way: iterate over
% all_loops (nested struct) which preserves fly indexing.

all_strain_names = fieldnames(all_loops);
sex = 'F';

% Accumulators
fly_strain_acc    = {};
fly_n_loops_acc   = [];
fly_med_area_acc  = [];
fly_med_dur_acc   = [];

for si = 1:numel(all_strain_names)
    strain = all_strain_names{si};
    if ~isfield(all_loops.(strain), sex)
        continue;
    end
    data_strain = all_loops.(strain).(sex);

    for exp_idx = 1:numel(data_strain)
        % Check both reps
        rep_strs = fieldnames(data_strain(exp_idx));
        for ri = 1:numel(rep_strs)
            rs = rep_strs{ri};
            if ~startsWith(rs, 'R'), continue; end  % skip 'meta'
            if ~isfield(data_strain(exp_idx).(rs), 'loops'), continue; end

            fly_loops = data_strain(exp_idx).(rs).loops;
            if isempty(fly_loops), continue; end

            for f = 1:numel(fly_loops)
                fl = fly_loops(f);
                fly_strain_acc{end+1}    = strain;
                fly_n_loops_acc(end+1)   = fl.n_loops;

                if fl.n_loops > 0
                    fly_med_area_acc(end+1) = median(fl.bbox_area, 'omitnan');
                    fly_med_dur_acc(end+1)  = median(fl.duration_s, 'omitnan');
                else
                    fly_med_area_acc(end+1) = NaN;
                    fly_med_dur_acc(end+1)  = NaN;
                end
            end
        end
    end
end

fly_strain_acc    = fly_strain_acc(:);
fly_n_loops_acc   = fly_n_loops_acc(:);
fly_med_area_acc  = fly_med_area_acc(:);
fly_med_dur_acc   = fly_med_dur_acc(:);

fprintf('  Total fly-rep observations: %d\n', numel(fly_strain_acc));

%% Organise data by strain for violin plots

unique_strains = unique(fly_strain_acc);
% Put control first
is_ctrl = strcmp(unique_strains, control_strain);
strain_order = [unique_strains(is_ctrl); unique_strains(~is_ctrl)];
n_strains = numel(strain_order);

% Build short labels
strain_labels = cell(n_strains, 1);
for si = 1:n_strains
    strain_labels{si} = strrep(strain_order{si}, '_shibire_kir', '');
    strain_labels{si} = strrep(strain_labels{si}, '_', '\_');
end

% Build per-group cell arrays
area_groups    = cell(n_strains, 1);
n_loops_groups = cell(n_strains, 1);
dur_groups     = cell(n_strains, 1);

for si = 1:n_strains
    idx = strcmp(fly_strain_acc, strain_order{si});
    area_groups{si}    = fly_med_area_acc(idx);
    n_loops_groups{si} = fly_n_loops_acc(idx);
    dur_groups{si}     = fly_med_dur_acc(idx);
end

%% Assign colours: control = grey, rest from strain palette

strain_palette = [
    0.7   0.7   0.7;     % control (grey)
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
    0.784 0.553 0.200;   % amber
];

% Assign: first entry is control (grey), rest cycle through palette(2:end)
violin_colors = zeros(n_strains, 3);
colour_idx = 1;  % start at 2 to skip the grey for non-control
for si = 1:n_strains
    if strcmp(strain_order{si}, control_strain)
        violin_colors(si, :) = strain_palette(1, :);  % grey
    else
        colour_idx = colour_idx + 1;
        violin_colors(si, :) = strain_palette(mod(colour_idx - 1, size(strain_palette,1)) + 1, :);
    end
end

%% ============================================================
%  PART 2: Violin plots
%  ============================================================

fprintf('\n=== Generating violin plots ===\n');

vopts.colors = violin_colors;
vopts.show_median = true;
vopts.show_mean = true;

% --- Violin 1: Bounding box area (median per fly) ---
vopts.ylabel_str = 'Median bbox area (mm²)';
vopts.title_str  = 'Loop bounding box area by strain (per fly)';
[fig_v1, ~] = plot_violin(area_groups, strain_labels, vopts);

% --- Violin 2: Number of loops per fly ---
vopts.ylabel_str = 'Number of loops';
vopts.title_str  = 'Number of trajectory loops by strain (per fly)';
[fig_v2, ~] = plot_violin(n_loops_groups, strain_labels, vopts);

% --- Violin 3: Duration (median per fly) ---
vopts.ylabel_str = 'Median loop duration (s)';
vopts.title_str  = 'Loop duration by strain (per fly)';
[fig_v3, ~] = plot_violin(dur_groups, strain_labels, vopts);

%% ============================================================
%  PART 3: Scatter subplots + slope bar charts
%  ============================================================

fprintf('\n=== Generating scatter plots + slope bar charts ===\n');

% --- Scatter 1: Bbox area vs distance ---
scatter_opts.ylabel_str = 'Bbox area (mm²)';
scatter_opts.title_str  = 'Loop bounding box area vs distance from centre';
[fig_s1, fig_b1] = plot_metric_vs_distance_subplots(flat_table, 'bbox_area', scatter_opts);

% --- Scatter 2: Duration vs distance ---
scatter_opts.ylabel_str = 'Duration (s)';
scatter_opts.title_str  = 'Loop duration vs distance from centre';
[fig_s2, fig_b2] = plot_metric_vs_distance_subplots(flat_table, 'duration_s', scatter_opts);

% --- Scatter 3: Aspect ratio vs distance ---
scatter_opts.ylabel_str = 'Aspect ratio';
scatter_opts.title_str  = 'Loop bbox aspect ratio vs distance from centre';
[fig_s3, fig_b3] = plot_metric_vs_distance_subplots(flat_table, 'bbox_aspect', scatter_opts);

fprintf('\n=== All plots generated ===\n');
fprintf('  3 violin plots (fig_v1, fig_v2, fig_v3)\n');
fprintf('  3 scatter subplot grids (fig_s1, fig_s2, fig_s3)\n');
fprintf('  3 slope bar charts (fig_b1, fig_b2, fig_b3)\n');
