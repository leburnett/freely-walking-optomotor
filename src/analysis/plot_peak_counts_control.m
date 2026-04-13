%% Violin plot — number of viewing-distance peaks per fly (control)
%
% Shows the distribution of peak counts across individual fly-rep
% observations for the control strain (jfrc100_es_shibire_kir).
% Each data point is the number of viewing-distance peaks found for
% one fly in one rep during the stimulus period.
%
% Requires DATA in workspace (from comb_data_across_cohorts_cond, protocol 27).

cfg = get_config();
if ~exist('DATA', 'var')
    protocol_dir = fullfile(cfg.results, 'protocol_27');
    DATA = comb_data_across_cohorts_cond(protocol_dir);
end

%% Parameters
ARENA_CENTER    = [528, 520] / 4.1691;
FPS             = 30;
SMOOTH_WIN      = 10;
MIN_PROMINENCE  = 5;
MIN_SEG_FRAMES  = 5;
MAX_DIST_CENTER = 110;
MIN_RSQ         = 0.1;

control_strain = "jfrc100_es_shibire_kir";
sex = 'F';
stim_range = 300:1200;

%% Load per-rep data
data_types = {'x_data', 'y_data', 'view_dist'};
[rep_data, n_flies] = load_per_rep_data(DATA, control_strain, sex, 1, data_types);

x_stim  = rep_data.x_data(:, stim_range);
y_stim  = rep_data.y_data(:, stim_range);
vd_stim = rep_data.view_dist(:, stim_range);

%% Count peaks per fly
[~, ~, ~, n_peaks] = segment_viewdist_peaks( ...
    x_stim, y_stim, vd_stim, ARENA_CENTER, FPS, ...
    SMOOTH_WIN, MIN_PROMINENCE, MIN_SEG_FRAMES, MAX_DIST_CENTER, MIN_RSQ);

fprintf('Control flies: %d fly-rep observations, median %.0f peaks, range [%d, %d]\n', ...
    n_flies, median(n_peaks), min(n_peaks), max(n_peaks));

%% Violin plot
opts = struct();
opts.colors      = [0.3 0.3 0.3];
opts.ylabel_str  = 'Number of peaks';
opts.marker_size = 15;
opts.marker_alpha = 0.4;
opts.violin_alpha = 0.35;
opts.show_median = true;
opts.med_text_sz = 18;
opts.violin_width = 0.35;

[~, ax] = plot_violin({n_peaks}, {'Control'}, opts);

set(ax, 'XTickLabel', {});
f = gcf;
f.Position = [783 493 200 356];
