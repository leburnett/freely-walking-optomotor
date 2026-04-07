%% fig2 — Protocol 31: Speed tuning time series and violin plots
%
% Generates figures for ES control flies across 4 temporal frequencies at
% two spatial frequencies (60deg and 15deg gratings):
%   - 10 time series figures: 5 metrics x 2 spatial frequencies
%   - 10 violin plots: 5 metrics x 2 spatial frequencies (4 speeds each)
%
% Condition mapping (Protocol 31):
%   60deg: Cond 1=1Hz, 2=2Hz, 3=4Hz, 4=8Hz, (5=flicker)
%   15deg: Cond 6=4Hz, 7=8Hz, 8=16Hz, 9=32Hz, (10=flicker)
%
% REQUIREMENTS:
%   - Protocol 31 data via comb_data_across_cohorts_cond
%   - Functions: plot_xcond_per_strain_p31, plot_violin,
%     combine_timeseries_across_exp_check, get_ylb_from_data_type
%
% See also: fig_different_speeds, p31_speed_tuning_centring

%% 1 — Configuration & data loading

cfg = get_config();
protocol_dir = fullfile(cfg.results, 'protocol_31');

if ~exist('DATA_31', 'var') || isempty(fieldnames(DATA_31))
    fprintf('Loading Protocol 31 data from: %s\n', protocol_dir);
    DATA_31 = comb_data_across_cohorts_cond(protocol_dir);
end

control_strain = 'jfrc100_es_shibire_kir';
sex = 'F';

%% 2 — Condition and colour setup

% 60deg gratings: conditions 1-4 (1Hz, 2Hz, 4Hz, 8Hz)
cond_60 = [1, 2, 3, 4];
labels_60 = {'1 Hz', '2 Hz', '4 Hz', '8 Hz'};

% 15deg gratings: conditions 6-9 (4Hz, 8Hz, 16Hz, 32Hz)
cond_15 = [6, 7, 8, 9];
labels_15 = {'4 Hz', '8 Hz', '16 Hz', '32 Hz'};

% Speed colourmap (same as plot_xcond_per_strain_p31)
col_12 = [173 216 230; ...  % Cond 1: light blue
           82 173 227; ...  % Cond 2
           31 120 180; ...  % Cond 3: medium blue
           61  82 159; ...  % Cond 4: dark blue
          231 158 190; ...  % Cond 5: light pink
          243 207 226; ...  % Cond 6: pale pink
          231 158 190; ...  % Cond 7
          223 113 167; ...  % Cond 8
          215  48 139; ...  % Cond 9: dark magenta
          200 200 200; ...  % Cond 10: grey
          255 224  41; ...
          187  75  12] ./ 255;

% 5 metrics to plot
metrics = { ...
    "fv_data",         0,  300:1200,   'Forward velocity (stimulus)'; ...
    "av_data",         0,  300:1200,   'Angular velocity (stimulus)'; ...
    "curv_data",       0,  300:1200,   'Turning rate (stimulus)'; ...
    "dist_data",       1,  1170:1200,  'Centring at end of stimulus'; ...
};
n_metrics = size(metrics, 1);

% Time series params
ts_params.save_figs    = 0;
ts_params.plot_sem     = 1;
ts_params.plot_sd      = 0;
ts_params.plot_individ = 0;
ts_params.shaded_areas = 0;

%% 3 — Time series: 60deg gratings (5 metrics)

for mi = 1:n_metrics
    dt    = metrics{mi, 1};
    delta = metrics{mi, 2};
    m_title = metrics{mi, 4};

    if delta == 1
        dt_str = dt + "_delta";
    else
        dt_str = dt;
    end

    figure('Name', sprintf('TS 60deg: %s', m_title));
    plot_xcond_per_strain_p31('protocol_31', dt_str, cond_60, ...
        {control_strain}, ts_params, DATA_31);
    title(sprintf('60deg gratings — %s', m_title), 'FontSize', 14);
end

%% 4 — Time series: 15deg gratings (5 metrics)

for mi = 1:n_metrics
    dt    = metrics{mi, 1};
    delta = metrics{mi, 2};
    m_title = metrics{mi, 4};

    if delta == 1
        dt_str = dt + "_delta";
    else
        dt_str = dt;
    end

    figure('Name', sprintf('TS 15deg: %s', m_title));
    plot_xcond_per_strain_p31('protocol_31', dt_str, cond_15, ...
        {control_strain}, ts_params, DATA_31);
    title(sprintf('15deg gratings — %s', m_title), 'FontSize', 14);
end

%% 5 — Violin plots: 60deg gratings (5 metrics, 4 speeds each)

data_ctrl = DATA_31.(control_strain).(sex);

for mi = 1:n_metrics
    dt       = metrics{mi, 1};
    delta    = metrics{mi, 2};
    frm_rng  = metrics{mi, 3};
    m_title  = metrics{mi, 4};

    group_data   = cell(numel(cond_60), 1);
    for ci = 1:numel(cond_60)
        cond_data = combine_timeseries_across_exp_check(data_ctrl, cond_60(ci), dt);
        if delta == 1
            cond_data = (cond_data - cond_data(:, 300)) * -1;
        end
        if dt == "av_data" || dt == "curv_data"
            cond_data(:, 750:1200) = cond_data(:, 750:1200) * -1;
        end
        group_data{ci} = nanmean(cond_data(:, frm_rng), 2); %#ok<NANMEAN>
    end

    ylb = get_ylb_from_data_type(dt, delta);
    opts = struct();
    opts.colors       = col_12(cond_60, :);
    opts.ylabel_str   = ylb;
    opts.marker_size  = 15;
    opts.marker_alpha = 0.4;
    opts.violin_alpha = 0.35;
    opts.show_median  = true;
    opts.violin_width = 0.35;

    % figure('Name', sprintf('Violin 60deg: %s', m_title));
    plot_violin(group_data, labels_60, opts);
    % title(sprintf('60deg gratings — %s', m_title), 'FontSize', 14);
    yl = ylim; ylim([yl(1), yl(2) + diff(yl) * 0.15]);
    f = gcf; f.Position = [1260   84  255  456];
    ax = gca; ax.FontSize = 14;
    hold on; yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5); hold off;

end

%% 6 — Violin plots: 15deg gratings (5 metrics, 4 speeds each)

for mi = 1:n_metrics
    dt       = metrics{mi, 1};
    delta    = metrics{mi, 2};
    frm_rng  = metrics{mi, 3};
    m_title  = metrics{mi, 4};

    group_data   = cell(numel(cond_15), 1);
    for ci = 1:numel(cond_15)
        cond_data = combine_timeseries_across_exp_check(data_ctrl, cond_15(ci), dt);
        if delta == 1
            cond_data = (cond_data - cond_data(:, 300)) * -1;
        end
        if dt == "av_data" || dt == "curv_data"
            cond_data(:, 750:1200) = cond_data(:, 750:1200) * -1;
        end
        group_data{ci} = nanmean(cond_data(:, frm_rng), 2); %#ok<NANMEAN>
    end

    ylb = get_ylb_from_data_type(dt, delta);
    opts = struct();
    opts.colors       = col_12(cond_15, :);
    opts.ylabel_str   = ylb;
    opts.marker_size  = 15;
    opts.marker_alpha = 0.4;
    opts.violin_alpha = 0.35;
    opts.show_median  = true;
    opts.violin_width = 0.35;

    % figure('Name', sprintf('Violin 15deg: %s', m_title));
    plot_violin(group_data, labels_15, opts);
    % title(sprintf('15deg gratings — %s', m_title), 'FontSize', 14);
    yl = ylim; ylim([yl(1), yl(2) + diff(yl) * 0.15]);
    f = gcf; f.Position = [1260   84  255  456];
    ax = gca; ax.FontSize = 14;
    hold on; yline(0, '-', 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5); hold off;

end
