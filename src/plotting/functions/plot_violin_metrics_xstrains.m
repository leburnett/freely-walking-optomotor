function plot_violin_metrics_xstrains(DATA, strain_ids, cond_idx, data_type, rng, delta)
%% Violin plots — plot metric values for different strains next to each other.
%
% Drop-in replacement for plot_boxchart_metrics_xstrains using violin plots
% (kernel density estimate + jittered data points) instead of boxcharts.
%
% INPUTS:
%   DATA       - struct from comb_data_across_cohorts_cond
%   strain_ids - [1 x ns] indices into strain_names2 ordering
%   cond_idx   - condition number (scalar)
%   data_type  - string, e.g. "fv_data", "dist_data", "fv_data_delta"
%   rng        - frame indices over which to calculate the metric
%   delta      - 0 = absolute, 1 = relative to frame 300, 2 = relative to frame 1200
%
% See also: plot_boxchart_metrics_xstrains, plot_violin,
%           combine_timeseries_across_exp

% Resolve delta data types (e.g., 'fv_data_delta' -> 'fv_data' + delta=1)
[data_type, resolved_delta] = resolve_delta_data_type(data_type);
if resolved_delta > 0, delta = resolved_delta; end

% Fixed strain_colours colormap (matches plot_boxchart_metrics_xstrains)
strain_colours = [[220,  40,  30]; ...  % muted red
    [220,  85,  30]; ...
    [220, 130,  35]; ...
    [220, 175,  40]; ...
    [220, 210,  50]; ...  % soft yellow
    [190, 170,  60]; ...  % yellow-green
    [164, 182, 120]; ...  % light green
    [134, 187, 139]; ...  % green-cyan
    [104, 185, 158]; ...  % cyan
    [ 82, 176, 176]; ...  % teal
    [ 72, 160, 192]; ...  % blue-cyan
    [ 74, 138, 202]; ...  % blue
    [ 86, 114, 204]; ...  % blue-indigo
    [108,  92, 198]; ...  % indigo
    [132,  74, 186]; ...  % violet
    [154,  60, 168]; ...  % deep violet
    [ 40,  40,  40]; ...
    [180, 180, 180]] ./ 255;

violin_colours = strain_colours(strain_ids, :);

cfg = get_config();
strain_names = load(fullfile(cfg.results, 'strain_names2.mat'));
strain_names = strain_names.strain_names;
n_strains = height(strain_names);
strain_names{n_strains+1} = 'jfrc100_es_shibire_kir';
% strain_names{n_strains+2} = 'csw1118';

sex = 'F';
ns = numel(strain_ids);

group_data   = cell(ns, 1);
group_labels = cell(ns, 1);

for strain_id = 1:ns

    strain = strain_names{strain_ids(strain_id)};
    disp(strain)

    condition_n = cond_idx;
    data = DATA.(strain).(sex);

    % Matrix of timeseries data (quiescence QC applied, averaged across reps)
    cond_data = combine_timeseries_across_exp(data, condition_n, data_type);

    if delta == 1
        cond_data = (cond_data - cond_data(:, 300)) * -1;  % relative to frame 300
    end

    if delta == 2
        cond_data = (cond_data - cond_data(:, 1200)) * -1;  % relative to frame 1200
    end

    if data_type == "av_data" || data_type == "curv_data"
        cond_data(:, 750:1200) = cond_data(:, 750:1200) * -1;
    end

    % Extract only the frames of interest
    cond_data = cond_data(:, rng);

    % Mean within this range per fly — one data point per fly
    mean_data = nanmean(cond_data, 2); %#ok<NANMEAN>

    group_data{strain_id}   = mean_data;
    group_labels{strain_id} = strrep(strain, '_', '-');
end

% Plot violins
ylb = get_ylb_from_data_type(data_type, delta);

opts = struct();
opts.colors       = violin_colours;
opts.ylabel_str   = ylb;
opts.marker_size  = 15;
opts.marker_alpha = 0.4;
opts.violin_alpha = 0.35;
opts.show_median  = true;
opts.show_mean    = false;
opts.violin_width = 0.35;
opts.plot_ES_median = true;

if data_type == "av_data" || data_type == "curv_data"
    opts.med_text_sz = 14;
else
    opts.med_text_sz = 14;
end

[~, ax] = plot_violin(group_data, group_labels, opts);

% Remove x-tick labels (matches boxchart version)
set(ax, 'XTickLabel', {});

f = gcf;
f.Position = [783   493   284   356];

end
